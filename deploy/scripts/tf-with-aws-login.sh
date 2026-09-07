#!/usr/bin/env bash
# Terraform does not yet read `aws login` session files. Export them as env vars.
set -euo pipefail

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI missing" >&2
  exit 1
fi

export AWS_EC2_METADATA_DISABLED=true
export AWS_SDK_LOAD_CONFIG=1

if ! eval "$(aws configure export-credentials --format env 2>/dev/null)"; then
  echo "Could not export AWS credentials. Run: aws login && aws sts get-caller-identity" >&2
  exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
  echo "aws configure export-credentials produced no AWS_ACCESS_KEY_ID" >&2
  exit 1
fi

exec terraform "$@"
