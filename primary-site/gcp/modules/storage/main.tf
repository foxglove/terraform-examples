resource "google_storage_bucket" "bucket" {
  name     = var.bucket_name
  project  = var.gcp_project
  location = var.gcp_region

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      with_state                 = "ARCHIVED"
      days_since_noncurrent_time = var.bucket_delete_days_since_noncurrent_time
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      with_state         = "ARCHIVED"
      num_newer_versions = var.bucket_delete_num_newer_version
    }
  }

  # Deleting `tmp/` prefixed objects is required for the lake bucket only, but has
  # no impact on the inbox bucket
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      with_state     = "LIVE"
      matches_prefix = ["tmp/"]
      age            = 1
    }
  }

  # Failed imports are cleaned up in the control plane after a year, this rule will
  # remove their backing objects the following day.
  #
  # This rule is only required for the inbox bucket to the inbox bucket, but will
  # have no impact on the lake bucket.
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      with_state     = "LIVE"
      matches_prefix = ["_quarantine/"]
      age            = 366
    }
  }
}
