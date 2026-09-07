#!/usr/bin/env bash
# Deny-paid policy gate. Safe with no cloud credentials (uses fixtures + terraform validate).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
POLICY="$ROOT/deploy/terraform/policies"
TF_DIR="$ROOT/deploy/terraform"
missing=0

if ! command -v conftest >/dev/null 2>&1; then
  echo "conftest missing. From this repo run:  make bootstrap" >&2
  missing=1
fi
if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform missing. From this repo run:  make bootstrap" >&2
  missing=1
fi
if [[ "$missing" -eq 1 ]]; then
  exit 1
fi

conftest test "$POLICY/fixtures/good-plan.json" -p "$POLICY"
if conftest test "$POLICY/fixtures/bad-plan.json" -p "$POLICY" >/tmp/conftest-bad-plan.out 2>&1; then
  echo "expected deny-paid to fail on fixtures/bad-plan.json" >&2
  cat /tmp/conftest-bad-plan.out >&2
  exit 1
fi
echo "conftest fixtures: good plan accepted, paid-stack fixture correctly denied"

if command -v checkov >/dev/null 2>&1; then
  checkov -d "$TF_DIR" --config-file "$TF_DIR/.checkov.yml" --quiet || true
fi

terraform -chdir="$TF_DIR" init -backend=false -input=false >/dev/null
terraform -chdir="$TF_DIR" validate
terraform -chdir="$TF_DIR" fmt -check -recursive
echo "terraform validate + fmt: ok"
