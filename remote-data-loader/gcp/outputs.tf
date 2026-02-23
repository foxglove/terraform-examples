output "cache_bucket_name" {
  value       = module.cache_bucket.bucket_name
  description = "Name of the cache bucket"
}

output "service_account_key" {
  description = "Service account key to use for `GOOGLE_APPLICATION_CREDENTIALS`"
  sensitive   = true
  value       = module.iam.service_account_key
}

output "cluster_endpoint" {
  value       = google_container_cluster.cluster.endpoint
  description = "Endpoint of the GKE cluster"
  sensitive   = true
}

output "cluster_name" {
  value       = google_container_cluster.cluster.name
  description = "Name of the GKE cluster"
}
