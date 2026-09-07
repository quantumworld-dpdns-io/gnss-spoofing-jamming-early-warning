terraform {
  required_version = ">= 1.9"

  # Local state is the zero-cost default (apply is local-only).
  # Optional remote backend: copy backend.hcl.example and run scripts/bootstrap-state.sh

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.6"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  name_prefix = "gnss-ew-${var.environment}"
  common_tags = {
    Environment = var.environment
    Project     = "gnss-spoofing-jamming-early-warning"
    ManagedBy   = "terraform"
    CostGuard   = "zero-cost-default"
  }
}

resource "random_password" "ingest_secret" {
  length  = 32
  special = false
}

locals {
  ingest_secret = var.ingest_shared_secret != "" ? var.ingest_shared_secret : random_password.ingest_secret.result
}

data "archive_file" "ingest" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/alert-ingest"
  output_path = "${path.module}/.build/alert-ingest.zip"
  excludes    = ["*_test.py", "__pycache__", "*.pyc"]
}

module "budget" {
  source = "./modules/budget"

  name         = "${local.name_prefix}-zero-cost"
  limit_usd    = var.budget_limit_usd
  alert_email = var.alert_email
}

module "dynamodb" {
  source = "./modules/dynamodb"

  name_prefix     = local.name_prefix
  read_capacity   = var.dynamodb_read_capacity
  write_capacity  = var.dynamodb_write_capacity
}

module "s3_lake" {
  source = "./modules/s3_lake"

  name_prefix           = local.name_prefix
  account_id            = var.aws_account_id
  expiration_days       = var.log_expiration_days
  enable_glacier_demo   = var.enable_glacier_demo
}

module "messaging" {
  source = "./modules/messaging"

  name_prefix = local.name_prefix
}

module "athena" {
  source = "./modules/athena"

  name_prefix          = local.name_prefix
  lake_bucket          = module.s3_lake.bucket_id
  results_prefix       = "athena-results/"
  bytes_scanned_cutoff = var.athena_bytes_scanned_cutoff
}

module "lambda" {
  source = "./modules/lambda"

  name_prefix          = local.name_prefix
  filename             = data.archive_file.ingest.output_path
  source_hash          = data.archive_file.ingest.output_base64sha256
  memory_size          = var.lambda_memory_mb
  reserved_concurrency = var.lambda_reserved_concurrency
  ingest_secret        = local.ingest_secret
  events_table         = module.dynamodb.events_table_name
  events_table_arn     = module.dynamodb.events_table_arn
  config_table         = module.dynamodb.config_table_name
  config_table_arn     = module.dynamodb.config_table_arn
  lake_bucket          = module.s3_lake.bucket_id
  lake_bucket_arn      = module.s3_lake.bucket_arn
  sns_topic_arn        = module.messaging.sns_topic_arn
  sqs_queue_arn        = module.messaging.sqs_queue_arn
  sqs_queue_url        = module.messaging.sqs_queue_url
  log_retention_days   = var.log_retention_days
}
