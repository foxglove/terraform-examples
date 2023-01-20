output "kube_config" {
  value       = azurerm_kubernetes_cluster.cluster.kube_config_raw
  sensitive   = true
  description = "Kube config for the created Kubernetes cluster"
}
