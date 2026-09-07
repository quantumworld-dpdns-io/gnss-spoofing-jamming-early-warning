variable "name_prefix" {
  type = string
}

variable "lake_bucket" {
  type = string
}

variable "results_prefix" {
  type = string
}

variable "bytes_scanned_cutoff" {
  type = number
}

resource "aws_athena_workgroup" "demo" {
  name          = "${var.name_prefix}-demo"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false
    bytes_scanned_cutoff_per_query     = var.bytes_scanned_cutoff

    result_configuration {
      output_location = "s3://${var.lake_bucket}/${var.results_prefix}"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

resource "aws_glue_catalog_database" "demo" {
  name = replace("${var.name_prefix}_demo", "-", "_")
}

resource "aws_glue_catalog_table" "events" {
  name          = "alert_events"
  database_name = aws_glue_catalog_database.demo.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL            = "TRUE"
    "projection.enabled" = "false"
  }

  storage_descriptor {
    location      = "s3://${var.lake_bucket}/raw/alerts/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "event_id"
      type = "string"
    }
    columns {
      name = "severity"
      type = "string"
    }
    columns {
      name = "detector"
      type = "string"
    }
    columns {
      name = "received_at"
      type = "string"
    }
  }
}

output "workgroup_name" {
  value = aws_athena_workgroup.demo.name
}

output "database_name" {
  value = aws_glue_catalog_database.demo.name
}
