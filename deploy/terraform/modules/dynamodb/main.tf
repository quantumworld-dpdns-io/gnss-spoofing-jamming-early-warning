variable "name_prefix" {
  type = string
}

variable "read_capacity" {
  type = number
}

variable "write_capacity" {
  type = number
}

resource "aws_dynamodb_table" "events" {
  name         = "${var.name_prefix}-events"
  billing_mode = "PROVISIONED"
  hash_key     = "pk"
  range_key    = "sk"

  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = false
  }

  server_side_encryption {
    enabled = true
  }
}

resource "aws_dynamodb_table" "config" {
  name         = "${var.name_prefix}-config"
  billing_mode = "PROVISIONED"
  hash_key     = "pk"

  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity

  attribute {
    name = "pk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = false
  }

  server_side_encryption {
    enabled = true
  }
}

output "events_table_name" {
  value = aws_dynamodb_table.events.name
}

output "events_table_arn" {
  value = aws_dynamodb_table.events.arn
}

output "config_table_name" {
  value = aws_dynamodb_table.config.name
}

output "config_table_arn" {
  value = aws_dynamodb_table.config.arn
}
