"""GNSS alert ingest Lambda — DynamoDB + S3 + SNS/SQS. boto3 is in the runtime."""

from __future__ import annotations

import hmac
import json
import os
import uuid
from datetime import datetime, timezone
from typing import Any

EVENTS_TABLE = os.environ.get("EVENTS_TABLE", "")
LAKE_BUCKET = os.environ.get("LAKE_BUCKET", "")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")
SQS_QUEUE_URL = os.environ.get("SQS_QUEUE_URL", "")
INGEST_SECRET = os.environ.get("INGEST_SECRET", "")

_dynamodb = None
_s3 = None
_sns = None
_sqs = None


def _clients() -> tuple[Any, Any, Any, Any]:
    global _dynamodb, _s3, _sns, _sqs
    if _dynamodb is None:
        import boto3

        _dynamodb = boto3.resource("dynamodb")
        _s3 = boto3.client("s3")
        _sns = boto3.client("sns")
        _sqs = boto3.client("sqs")
    return _dynamodb, _s3, _sns, _sqs


def _header(event: dict[str, Any], name: str) -> str:
    headers = event.get("headers") or {}
    lower = {str(k).lower(): v for k, v in headers.items()}
    return str(lower.get(name.lower(), "") or "")


def _response(status: int, body: dict[str, Any]) -> dict[str, Any]:
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body),
    }


def parse_payload(raw: str) -> dict[str, Any]:
    if not raw:
        raise ValueError("empty body")
    data = json.loads(raw)
    if not isinstance(data, dict):
        raise ValueError("body must be a JSON object")
    return data


def build_record(payload: dict[str, Any], received_at: str) -> dict[str, Any]:
    event_id = str(payload.get("event_id") or uuid.uuid4())
    severity = str(payload.get("severity") or "info")
    detector = str(payload.get("detector") or "unknown")
    return {
        "event_id": event_id,
        "severity": severity,
        "detector": detector,
        "received_at": received_at,
        "payload": payload,
        "pk": f"event#{event_id}",
        "sk": received_at,
    }


def handler(event: dict[str, Any], _context: Any) -> dict[str, Any]:
    token = _header(event, "x-alert-token")
    expected = INGEST_SECRET
    if not expected or not token or not hmac.compare_digest(token, expected):
        return _response(401, {"error": "unauthorized"})

    try:
        payload = parse_payload(event.get("body") or "")
    except (ValueError, json.JSONDecodeError) as exc:
        return _response(400, {"error": str(exc)})

    received_at = datetime.now(timezone.utc).isoformat()
    record = build_record(payload, received_at)
    dynamodb, s3, sns, sqs = _clients()

    dynamodb.Table(EVENTS_TABLE).put_item(Item={
        "pk": record["pk"],
        "sk": record["sk"],
        "event_id": record["event_id"],
        "severity": record["severity"],
        "detector": record["detector"],
        "received_at": record["received_at"],
    })

    key = f"raw/alerts/{received_at[:10]}/{record['event_id']}.json"
    s3.put_object(
        Bucket=LAKE_BUCKET,
        Key=key,
        Body=json.dumps(record, default=str).encode("utf-8"),
        ContentType="application/json",
        ServerSideEncryption="AES256",
    )

    message = json.dumps({
        "event_id": record["event_id"],
        "severity": record["severity"],
        "s3_key": key,
    })
    sns.publish(TopicArn=SNS_TOPIC_ARN, Message=message)
    sqs.send_message(QueueUrl=SQS_QUEUE_URL, MessageBody=message)

    return _response(202, {
        "event_id": record["event_id"],
        "s3_key": key,
        "status": "accepted",
    })
