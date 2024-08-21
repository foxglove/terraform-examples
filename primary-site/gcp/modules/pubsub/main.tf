module "inbox_push_notifications_dlq" {
  source     = "terraform-google-modules/pubsub/google"
  version    = "5.0.0"
  project_id = var.gcp_project
  topic      = "${var.bucket_name}-notifications-dlq"
}

module "inbox_notifications" {
  depends_on = [module.inbox_push_notifications_dlq]

  source     = "terraform-google-modules/pubsub/google"
  version    = "5.0.0"
  project_id = var.gcp_project
  topic      = "${var.bucket_name}-notifications"
  push_subscriptions = [
    {
      name                  = "${var.bucket_name}-push-sub"
      push_endpoint         = var.inbox_notification_endpoint

      # To avoid the error where the push_subscriptions "for_each" map includes keys derived
      # from resource attributes that cannot be determined until apply, we "hard-code" the dead
      # letter topic name here. This is why `depends_on` is needed above.
      dead_letter_topic     = "projects/${var.gcp_project}/topics/${var.bucket_name}-notifications-dlq"

      x-goog-version        = "v1"
      ack_deadline_seconds  = 600
      max_delivery_attempts = 5
      maximum_backoff       = "600s"
      expiration_policy     = ""
      minimum_backoff       = "300s"
    }
  ]
  topic_labels = {}
}

// Allow GCS to publish to the inbox notification pubsub
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_notification
data "google_storage_project_service_account" "gcs_account" {}

resource "google_pubsub_topic_iam_member" "storage_pubsub" {
  topic  = module.inbox_notifications.topic
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

// Storage notifications from the inbox bucket into the inbox queue
resource "google_storage_notification" "notifications" {
  bucket         = var.bucket_name
  payload_format = "JSON_API_V1"
  topic          = module.inbox_notifications.topic
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [google_pubsub_topic_iam_member.storage_pubsub]
}
