resource "aws_s3_bucket" "cache_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "cache_bucket_lifecycle" {
  bucket = aws_s3_bucket.cache_bucket.id

  # Delete cached objects after expiration
  rule {
    id     = "${var.bucket_name}-cache-expiration-rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.cache_expiration_days
    }
  }

  # Abort incomplete multipart uploads
  rule {
    id     = "${var.bucket_name}-abort-incomplete-uploads-rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }
  }
}
