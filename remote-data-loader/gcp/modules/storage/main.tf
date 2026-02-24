resource "google_storage_bucket" "cache_bucket" {
  name     = var.bucket_name
  project  = var.gcp_project
  location = var.gcp_region

  # Cache data is ephemeral, no versioning needed
  versioning {
    enabled = false
  }

  # Delete cached objects after expiration
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.cache_expiration_days
    }
  }

  # Abort incomplete multipart uploads after 7 days
  lifecycle_rule {
    action {
      type = "AbortIncompleteMultipartUpload"
    }
    condition {
      age = 7
    }
  }
}
