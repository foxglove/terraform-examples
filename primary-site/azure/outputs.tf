output "tenant_id" {
  value       = module.primary_site_iam.tenant_id
  description = "The AZURE_TENANT_ID value for Foxglove cloud credentials"
}

output "client_id" {
  value       = module.primary_site_iam.client_id
  description = "The AZURE_CLIENT_ID value for Foxglove cloud credentials"
}

output "client_secret" {
  value       = module.primary_site_iam.client_secret
  description = "The AZURE_CLIENT_SECRET value for terraform cloud credentials"
  sensitive   = true
}

output "kube_config" {
  value       = azurerm_kubernetes_cluster.cluster.kube_config_raw
  sensitive   = true
  description = "Kube config for the created Kubernetes cluster"
}
