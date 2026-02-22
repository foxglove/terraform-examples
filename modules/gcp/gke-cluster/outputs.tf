output "network_self_link" {
  value       = module.vpc.network_self_link
  description = "Self link of the VPC network"
}

output "cluster_name" {
  value       = google_container_cluster.cluster.name
  description = "Name of the GKE cluster"
}

output "cluster_endpoint" {
  value       = google_container_cluster.cluster.endpoint
  description = "Endpoint of the GKE cluster"
}
