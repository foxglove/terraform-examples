output "bucket_name" {
  value       = google_storage_bucket.cache_bucket.name
  description = "Name of the cache bucket created (will be the same as the input variable)"
}
