# ADR-006: Zero-cost serverless default (AWS)

## Status
Accepted (supersedes ADR-005 for the default environment)

## Context
ADR-005 selected EKS + NAT + RDS + ElastiCache. That stack cannot run inside AWS Always Free / near-zero demo budgets. NAT Gateway and EKS control plane alone cost tens of USD per month.

## Decision
The **default** cloud path is serverless on Always Free building blocks:

| Layer | Service | Usage |
|-------|---------|--------|
| Compute | Lambda + Function URL | Alert ingest/process (no API Gateway) |
| Data | DynamoDB provisioned (≤25 WCU/RCU) | event / config |
| Object | S3 (Glacier optional, default off) | raw logs / lake |
| Analytics | Athena with `bytes_scanned_cutoff` | SQL demo |
| Decouple / observe | SNS / SQS / CloudWatch | queue / alarms / metrics |

Deliberately **not** in `deploy/terraform` (dev default): RDS/Aurora, EKS, NAT, OpenSearch, always-on EC2. The previous stack is archived at `deploy/terraform-eks/` as a paid reference.

Frontend stays off-cloud. Heavy detection (Rust / quantum) stays local; cloud only receives alert events.

Terraform apply is local. CI may plan and enforce OPA/Checkov deny-paid policies.

## Consequences
- Demo accounts stay at **$0.0** via AWS Budget alerts on any spend, plus deny-paid OPA policies
- Scale-out SaaS still possible later via the archived EKS stack
- Function URL must be protected with a shared secret (or IAM) so public scrapers cannot burn the Lambda free-tier
