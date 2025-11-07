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
  depends_on = [google_service_account.iam_user]
}

resource "google_storage_bucket_iam_binding" "role_lake_admin" {
  bucket = var.lake_bucket_name
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.iam_user.email}"
  ]
  depends_on = [google_service_account.iam_user]
}

resource "google_service_account_key" "iam_user_key" {
  service_account_id = google_service_account.iam_user.name
}

resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.iam_user.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.gcp_project}.svc.id.goog[foxglove/default]"
  ]
  depends_on = [google_service_account.iam_user]
}
