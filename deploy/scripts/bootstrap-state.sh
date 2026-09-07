#!/usr/bin/env bash
# Optional remote Terraform state (S3 + DynamoDB lock). Default apply uses local state.
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
BUCKET="gnss-ew-tfstate-${ACCOUNT}"
TABLE="gnss-ew-tfstate-lock"

aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
  $(if [ "$REGION" != "us-east-1" ]; then echo --create-bucket-configuration LocationConstraint="$REGION"; fi) \
  2>/dev/null || true

aws s3api put-bucket-encryption --bucket "$BUCKET" --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
  --region "$REGION" 2>/dev/null || true

echo "backend bucket=$BUCKET table=$TABLE region=$REGION"
echo "Copy deploy/terraform/backend.hcl.example → backend.hcl and terraform init -backend-config=backend.hcl"
