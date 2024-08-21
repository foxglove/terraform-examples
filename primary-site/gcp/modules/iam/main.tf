resource "google_service_account" "iam_user" {
  account_id = var.iam_user_name
  project    = var.gcp_project
}

resource "google_storage_bucket_iam_binding" "role_inbox_admin" {
  bucket = var.inbox_bucket_name
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.iam_user.email}"
  ]
}

resource "google_service_account_iam_binding" "user_policy" {
  role               = "roles/iam.workloadIdentityUser"
  service_account_id = "projects/${var.gcp_project}/serviceAccounts/${google_service_account.iam_user.email}"
  members = [
    "serviceAccount:${var.gcp_project}.svc.id.goog[foxglove/garbage-collector]",
    "serviceAccount:${var.gcp_project}.svc.id.goog[foxglove/inbox-listener]",
    "serviceAccount:${var.gcp_project}.svc.id.goog[foxglove/stream-service]"
  ]
}

resource "google_storage_bucket_iam_binding" "role_lake_admin" {
  bucket = var.lake_bucket_name
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.iam_user.email}"
  ]
}

resource "google_service_account_key" "iam_user_key" {
  service_account_id = google_service_account.iam_user.name
}
