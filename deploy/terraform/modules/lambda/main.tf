variable "name_prefix" {
  type = string
}

variable "filename" {
  type = string
}

variable "source_hash" {
  type = string
}

variable "memory_size" {
  type = number
}

variable "reserved_concurrency" {
  type = number
}

variable "ingest_secret" {
  type      = string
  sensitive = true
}

variable "events_table" {
  type = string
}

variable "events_table_arn" {
  type = string
}

variable "config_table" {
  type = string
}

variable "config_table_arn" {
  type = string
}

variable "lake_bucket" {
  type = string
}

variable "lake_bucket_arn" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "sqs_queue_arn" {
  type = string
}

variable "sqs_queue_url" {
  type = string
}

variable "log_retention_days" {
  type = number
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ingest" {
  name               = "${var.name_prefix}-ingest"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "ingest" {
  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.ingest.arn}:*"]
  }

  statement {
    sid       = "Dynamo"
    actions   = ["dynamodb:PutItem", "dynamodb:GetItem"]
    resources = [var.events_table_arn, var.config_table_arn]
  }

  statement {
    sid       = "S3Put"
    actions   = ["s3:PutObject"]
    resources = ["${var.lake_bucket_arn}/raw/*"]
  }

  statement {
    sid       = "Notify"
    actions   = ["sns:Publish", "sqs:SendMessage"]
    resources = [var.sns_topic_arn, var.sqs_queue_arn]
  }
}

resource "aws_iam_role_policy" "ingest" {
  name   = "ingest"
  role   = aws_iam_role.ingest.id
  policy = data.aws_iam_policy_document.ingest.json
}

resource "aws_cloudwatch_log_group" "ingest" {
  name              = "/aws/lambda/${var.name_prefix}-ingest"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "ingest" {
  function_name                  = "${var.name_prefix}-ingest"
  role                           = aws_iam_role.ingest.arn
  filename                       = var.filename
  source_code_hash               = var.source_hash
  handler                        = "handler.handler"
  runtime                        = "python3.12"
  architectures                  = ["x86_64"]
  memory_size                    = var.memory_size
  timeout                        = 10
  reserved_concurrent_executions = var.reserved_concurrency

  environment {
    variables = {
      EVENTS_TABLE  = var.events_table
      CONFIG_TABLE  = var.config_table
      LAKE_BUCKET   = var.lake_bucket
      SNS_TOPIC_ARN = var.sns_topic_arn
      SQS_QUEUE_URL = var.sqs_queue_url
      INGEST_SECRET = var.ingest_secret
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  depends_on = [aws_cloudwatch_log_group.ingest]
}

resource "aws_lambda_function_url" "ingest" {
  function_name      = aws_lambda_function.ingest.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["POST"]
    allow_headers = ["content-type", "x-alert-token"]
  }
}

resource "aws_lambda_permission" "function_url" {
  statement_id           = "FunctionURLAllow"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.ingest.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

output "function_url" {
  value = aws_lambda_function_url.ingest.function_url
}

output "function_name" {
  value = aws_lambda_function.ingest.function_name
}
