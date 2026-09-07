# Paid EKS stack (NOT the default)

This directory is the previous production-shaped Terraform: EKS (including GPU nodes),
VPC with NAT Gateway, RDS, ElastiCache, and ECR.

**Do not apply this for demos.** NAT Gateway and EKS control plane alone cost tens of
USD per month and will break the zero-cost free-tier default.

Default infrastructure lives in [`../terraform`](../terraform) (Lambda Function URL,
DynamoDB provisioned, S3, Athena scan cap, SNS/SQS, AWS Budget $0.0).

```bash
# This path is intentionally omitted from `make infra-apply`.
terraform -chdir=deploy/terraform-eks plan   # expect real AWS spend
```
