# Zero-cost default (AWS)

Lambda Function URL, provisioned DynamoDB, S3 lake, Athena with scan cap, SNS/SQS,
CloudWatch logs (7-day retention), and an AWS Budget of **$0.01** (API rejects `$0`;
notifications still fire when actual or forecasted spend exceeds `$0`).

Apply is **local only**. CI never runs `terraform apply`.

The deploy account in `envs/dev/terraform.tfvars` must be the one you `aws login` to.
Organizations **member** accounts can be blocked by SCP (S3/DynamoDB/SNS/SQS/Glue
explicit deny). Use the **management** account (`710969344403`); SCPs do not apply there.

```bash
make cost-guard
make infra-plan
make infra-apply    # ansible preflight + terraform apply
make infra-verify
make infra-destroy
```

```bash
make cost-guard
make infra-plan
make infra-apply    # ansible preflight + terraform apply
make infra-verify
make infra-destroy
```

Required tfvars before a real apply:

- `alert_email` — budget subscriber
- `aws_account_id` — 12-digit account id (`aws sts get-caller-identity`)

Do **not** apply [`../terraform-eks`](../terraform-eks). That stack has NAT/EKS/RDS.

Optional remote state: `scripts/bootstrap-state.sh` then `terraform init -backend-config=backend.hcl`.
