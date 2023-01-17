## ----- S3 buckets -----

module "bucket_inbox" {
  source      = "./modules/storage"
  bucket_name = var.inbox_bucket_name
  gcp_project = var.gcp_project
  gcp_region  = var.gcp_region

  bucket_delete_days_since_noncurrent_time = var.bucket_delete_days_since_noncurrent_time
  bucket_delete_num_newer_version          = var.bucket_delete_num_newer_version
}

module "bucket_lake" {
  source      = "./modules/storage"
  bucket_name = var.lake_bucket_name
  gcp_project = var.gcp_project
  gcp_region  = var.gcp_region

  bucket_delete_days_since_noncurrent_time = var.bucket_delete_days_since_noncurrent_time
  bucket_delete_num_newer_version          = var.bucket_delete_num_newer_version
}

## ----- Pubsub -----

module "inbox_push_notifications_dlq" {
  source     = "terraform-google-modules/pubsub/google"
  version    = "5.0.0"
  project_id = var.gcp_project
  topic      = "${module.bucket_inbox.bucket_name}-notifications-dlq"
}

module "inbox_notifications" {
  depends_on = [module.inbox_push_notifications_dlq]

  source     = "terraform-google-modules/pubsub/google"
  version    = "5.0.0"
  project_id = var.gcp_project
  topic      = "${module.bucket_inbox.bucket_name}-notifications"
  push_subscriptions = [
    {
      name                  = "${module.bucket_inbox.bucket_name}-push-sub"
      push_endpoint         = var.inbox_notification_endpoint

      # To avoid the error where the push_subscriptions "for_each" map includes keys derived
      # from resource attributes that cannot be determined until apply, we "hard-code" the dead
      # letter topic name here. This is why `depends_on` is needed above.
      dead_letter_topic     = "projects/${var.gcp_project}/topics/${module.bucket_inbox.bucket_name}-notifications-dlq"

      x-goog-version        = "v1"
      ack_deadline_seconds  = 600
      max_delivery_attempts = 5
      maximum_backoff       = "600s"
      expiration_policy     = ""
      minimum_backoff       = "300s"
    }
  ]
}
