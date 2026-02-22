output "tenant_id" {
  value       = module.iam.tenant_id
  description = "The AZURE_TENANT_ID value for Foxglove cloud credentials"
}

output "client_id" {
  value       = module.iam.client_id
  description = "The AZURE_CLIENT_ID value for Foxglove cloud credentials"
}

output "client_secret" {
  value       = module.iam.client_secret
  description = "The AZURE_CLIENT_SECRET value for Foxglove cloud credentials"
  sensitive   = true
}

output "kube_config" {
  value       = module.kubernetes_cluster.kube_config
  sensitive   = true
  description = "Kube config for the created Kubernetes cluster"
}
