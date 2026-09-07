variable "environment" {
  description = "Deployment environment (dev is the zero-cost default)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region. us-east-1 aligns with the broadest free-tier examples."
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID used in globally unique S3 names. Set from `aws sts get-caller-identity` before apply."
  type        = string
  default     = "000000000000"

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit account id."
  }
}

variable "alert_email" {
  description = "Email for AWS Budget alerts (fires when actual or forecasted spend exceeds $0)"
  type        = string
}

variable "budget_limit_usd" {
  description = "Monthly AWS Budget limit in USD. API rejects 0; 0.01 is the practical zero-cost floor."
  type        = string
  default     = "0.01"

  validation {
    condition     = tonumber(var.budget_limit_usd) > 0
    error_message = "AWS Budgets requires limit_amount > 0. Use 0.01; notifications still fire at $0 actual spend."
  }
}

variable "ingest_shared_secret" {
  description = "Shared secret for Function URL header X-Alert-Token. Empty generates one."
  type        = string
  default     = ""
  sensitive   = true
}

variable "dynamodb_read_capacity" {
  description = "Provisioned RCU (Always Free includes 25 RCU; keep far below)"
  type        = number
  default     = 5

  validation {
    condition     = var.dynamodb_read_capacity >= 1 && var.dynamodb_read_capacity <= 25
    error_message = "RCU must stay within Always Free (1-25)."
  }
}

variable "dynamodb_write_capacity" {
  description = "Provisioned WCU (Always Free includes 25 WCU; keep far below)"
  type        = number
  default     = 5

  validation {
    condition     = var.dynamodb_write_capacity >= 1 && var.dynamodb_write_capacity <= 25
    error_message = "WCU must stay within Always Free (1-25)."
  }
}

variable "lambda_memory_mb" {
  description = "Lambda memory. Cost-guard denies > 256."
  type        = number
  default     = 128

  validation {
    condition     = var.lambda_memory_mb <= 256
    error_message = "Lambda memory must be <= 256MB for the zero-cost default."
  }
}

variable "lambda_reserved_concurrency" {
  description = "Cap concurrent Lambda executions to protect the free-tier request quota"
  type        = number
  default     = 1
}

variable "log_expiration_days" {
  description = "S3 object expiration for demo lake data"
  type        = number
  default     = 14
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention (must be a valid AWS value)"
  type        = number
  default     = 7
}

variable "athena_bytes_scanned_cutoff" {
  description = "Athena per-query scan cap in bytes (default 1 GiB)"
  type        = number
  default     = 1073741824
}

variable "enable_glacier_demo" {
  description = "If true, transition objects to Glacier after expiration window. Retrieval costs money; default off."
  type        = bool
  default     = false
}
