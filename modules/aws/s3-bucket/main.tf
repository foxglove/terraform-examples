resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "${var.bucket_name}-delete-incomplete-uploads-rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }
  }

  # Failed imports are cleaned up in the control plane after a year, this rule will
  # remove their backing objects the following day.
  #
  # This rule is only required for the inbox bucket, but it will have no impact on
  # other buckets so it is fine here.
  rule {
    id     = "${var.bucket_name}-delete-old-quarantined-files"
    status = "Enabled"

    filter {
      prefix = "_quarantine/"
    }

    expiration {
      days = 366
    }
  }
}
