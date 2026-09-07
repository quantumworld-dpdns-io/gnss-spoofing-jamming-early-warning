#!/usr/bin/env bash
# Move invalid long-lived keys off the default profile so `aws login` can run.
set -euo pipefail

AWS_DIR="${HOME}/.aws"
mkdir -p "${AWS_DIR}"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [[ -f "${AWS_DIR}/credentials" ]]; then
  mv "${AWS_DIR}/credentials" "${AWS_DIR}/credentials.invalid-${STAMP}.bak"
  echo "moved ~/.aws/credentials -> ~/.aws/credentials.invalid-${STAMP}.bak"
fi

aws configure set region us-east-1 --profile default
echo "default region=us-east-1"
echo "Next (interactive, opens a browser):"
echo "  aws login"
echo "  aws sts get-caller-identity"
echo "  make infra-apply-aws"
