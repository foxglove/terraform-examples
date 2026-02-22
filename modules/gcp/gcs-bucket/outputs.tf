output "bucket_name" {
  value       = google_storage_bucket.bucket.name
  description = "Name of the bucket created (will be the same as the input variable)"
}
