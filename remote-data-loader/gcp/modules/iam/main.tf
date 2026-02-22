resource "google_service_account" "iam_user" {
  account_id = var.iam_user_name
  project    = var.gcp_project
}

resource "google_storage_bucket_iam_binding" "role_cache_admin" {
  bucket = var.cache_bucket_name
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.iam_user.email}"
  ]
}

resource "google_service_account_key" "iam_user_key" {
  service_account_id = google_service_account.iam_user.name
}
