#!/usr/bin/env bash
# Deny-paid policy gate. Safe with no cloud credentials (uses fixtures + terraform validate).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
POLICY="$ROOT/deploy/terraform/policies"
TF_DIR="$ROOT/deploy/terraform"

if ! command -v conftest >/dev/null 2>&1; then
  echo "conftest not installed; skipping OPA fixtures (install: https://www.conftest.dev/)" >&2
else
  conftest test "$POLICY/fixtures/good-plan.json" -p "$POLICY"
  if conftest test "$POLICY/fixtures/bad-plan.json" -p "$POLICY"; then
    echo "expected deny-paid to fail on fixtures/bad-plan.json" >&2
    exit 1
  fi
  echo "conftest fixtures: good accepted, bad denied"
fi

if command -v checkov >/dev/null 2>&1; then
  checkov -d "$TF_DIR" --config-file "$TF_DIR/.checkov.yml" --quiet || true
fi

if command -v terraform >/dev/null 2>&1; then
  terraform -chdir="$TF_DIR" init -backend=false -input=false >/dev/null
  terraform -chdir="$TF_DIR" validate
  terraform -chdir="$TF_DIR" fmt -check -recursive
else
  echo "terraform not installed; skipped validate" >&2
fi
