"""Unit tests for alert ingest (no AWS calls)."""

import json

import handler


def test_parse_payload_ok() -> None:
    data = handler.parse_payload('{"severity":"high","detector":"ensemble"}')
    assert data["severity"] == "high"


def test_parse_payload_empty() -> None:
    try:
        handler.parse_payload("")
        raise AssertionError("expected ValueError")
    except ValueError:
        pass


def test_build_record_generates_id() -> None:
    record = handler.build_record({"severity": "low"}, "2026-09-07T00:00:00+00:00")
    assert record["pk"].startswith("event#")
    assert record["severity"] == "low"
    assert record["sk"] == "2026-09-07T00:00:00+00:00"


def test_unauthorized_without_token(monkeypatch) -> None:
    monkeypatch.setattr(handler, "INGEST_SECRET", "s3cret")
    resp = handler.handler({"headers": {}, "body": "{}"}, None)
    assert resp["statusCode"] == 401


def test_bad_json(monkeypatch) -> None:
    monkeypatch.setattr(handler, "INGEST_SECRET", "s3cret")
    resp = handler.handler(
        {"headers": {"x-alert-token": "s3cret"}, "body": "not-json"},
        None,
    )
    assert resp["statusCode"] == 400
    assert "error" in json.loads(resp["body"])
