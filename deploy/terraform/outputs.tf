output "function_url" {
  description = "Lambda Function URL for alert ingest (send X-Alert-Token)"
  value       = module.lambda.function_url
}

output "events_table" {
  value = module.dynamodb.events_table_name
}

output "config_table" {
  value = module.dynamodb.config_table_name
}

output "lake_bucket" {
  value = module.s3_lake.bucket_id
}

output "sns_topic_arn" {
  value = module.messaging.sns_topic_arn
}

output "sqs_queue_url" {
  value = module.messaging.sqs_queue_url
}

output "athena_workgroup" {
  value = module.athena.workgroup_name
}

output "athena_database" {
  value = module.athena.database_name
}

output "ingest_secret" {
  description = "Shared secret for X-Alert-Token (store locally, never commit)"
  value       = local.ingest_secret
  sensitive   = true
}

output "budget_name" {
  value = module.budget.budget_name
}
