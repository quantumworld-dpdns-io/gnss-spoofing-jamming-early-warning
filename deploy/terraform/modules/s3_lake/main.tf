variable "name_prefix" {
  type = string
}

variable "account_id" {
  type = string
}

variable "expiration_days" {
  type = number
}

variable "enable_glacier_demo" {
  type = bool
}

resource "aws_s3_bucket" "lake" {
  bucket = "${var.name_prefix}-lake-${var.account_id}"
}

resource "aws_s3_bucket_public_access_block" "lake" {
  bucket                  = aws_s3_bucket.lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lake" {
  bucket = aws_s3_bucket.lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lake" {
  bucket = aws_s3_bucket.lake.id

  rule {
    id     = "expire-demo-objects"
    status = "Enabled"

    filter {
      prefix = "raw/"
    }

    dynamic "expiration" {
      for_each = var.enable_glacier_demo ? [] : [1]
      content {
        days = var.expiration_days
      }
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    dynamic "transition" {
      for_each = var.enable_glacier_demo ? [1] : []
      content {
        days          = max(var.expiration_days, 1)
        storage_class = "GLACIER"
      }
    }
  }

  rule {
    id     = "expire-athena-results"
    status = "Enabled"

    filter {
      prefix = "athena-results/"
    }

    expiration {
      days = 3
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

output "bucket_id" {
  value = aws_s3_bucket.lake.id
}

output "bucket_arn" {
  value = aws_s3_bucket.lake.arn
}
