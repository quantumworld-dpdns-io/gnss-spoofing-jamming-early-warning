variable "name_prefix" {
  type = string
}

resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"
}

resource "aws_sqs_queue" "alerts" {
  name                      = "${var.name_prefix}-alerts"
  message_retention_seconds = 86400
  visibility_timeout_seconds = 30
}

resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.alerts.arn
}

resource "aws_sqs_queue_policy" "from_sns" {
  queue_url = aws_sqs_queue.alerts.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSNS"
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.alerts.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.alerts.arn }
      }
    }]
  })
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.alerts.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.alerts.url
}
