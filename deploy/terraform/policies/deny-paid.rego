package main

paid_types := {
	"aws_eks_cluster",
	"aws_eks_node_group",
	"aws_db_instance",
	"aws_rds_cluster",
	"aws_elasticache_cluster",
	"aws_elasticache_replication_group",
	"aws_nat_gateway",
	"aws_eip",
	"aws_instance",
	"aws_launch_template",
	"aws_elasticsearch_domain",
	"aws_opensearch_domain",
	"aws_api_gateway_rest_api",
	"aws_apigatewayv2_api",
	"aws_lb",
	"aws_alb",
	"aws_eip_association",
	"google_container_cluster",
	"google_sql_database_instance",
	"google_compute_instance",
	"google_compute_address",
	"google_redis_instance",
}

deny[msg] {
	rc := input.resource_changes[_]
	paid_types[rc.type]
	not deleting(rc)
	msg := sprintf("zero-cost policy: %s (%s) is not allowed in the default stack", [rc.address, rc.type])
}

deny[msg] {
	rc := input.resource_changes[_]
	rc.type == "aws_dynamodb_table"
	rc.change.after.billing_mode == "PAY_PER_REQUEST"
	msg := sprintf("DynamoDB on-demand is not Always Free: %s", [rc.address])
}

deny[msg] {
	rc := input.resource_changes[_]
	rc.type == "aws_lambda_function"
	mem := object.get(rc.change.after, "memory_size", 128)
	mem > 256
	msg := sprintf("Lambda memory %v > 256MB: %s", [mem, rc.address])
}

deny[msg] {
	rc := input.resource_changes[_]
	rc.type == "google_cloud_run_v2_service"
	cloud_run_min(rc) > 0
	msg := sprintf("Cloud Run min_instance_count must be 0: %s", [rc.address])
}

deny[msg] {
	count(budget_resources) == 0
	count(input.resource_changes) > 0
	msg := "zero-cost policy: plan must include aws_budgets_budget or google_billing_budget"
}

budget_resources[rc] {
	rc := input.resource_changes[_]
	rc.type == "aws_budgets_budget"
	not deleting(rc)
}

budget_resources[rc] {
	rc := input.resource_changes[_]
	rc.type == "google_billing_budget"
	not deleting(rc)
}

deleting(rc) {
	rc.change.actions == ["delete"]
}

cloud_run_min(rc) = n {
	n := rc.change.after.template[0].scaling[0].min_instance_count
} else = 0
