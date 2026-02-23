resource "google_service_account" "service_account" {
  account_id = var.service_account_name
  project    = var.gcp_project
}

resource "google_storage_bucket_iam_binding" "cache_bucket_admin" {
  bucket = var.cache_bucket_name
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.service_account.name
}
