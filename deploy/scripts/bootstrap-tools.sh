#!/usr/bin/env bash
# Install local DevSecOps CLIs (macOS Homebrew). Idempotent.
export HOMEBREW_NO_AUTO_UPDATE=1

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required: https://brew.sh" >&2
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  brew tap hashicorp/tap
  brew install hashicorp/tap/terraform
fi
if ! command -v conftest >/dev/null 2>&1; then
  brew install conftest
fi
if ! command -v ansible >/dev/null 2>&1; then
  brew install ansible
fi
if ! command -v aws >/dev/null 2>&1; then
  brew install awscli
fi
if ! command -v checkov >/dev/null 2>&1; then
  brew install checkov || true
fi

echo "ok: terraform=$(command -v terraform) conftest=$(command -v conftest) ansible=$(command -v ansible) aws=$(command -v aws || echo MISSING)"
