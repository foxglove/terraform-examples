resource "azurerm_log_analytics_workspace" "log_analytics_ws" {
  name                = "${var.cluster_name}-log-analytics"
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  retention_in_days   = 365
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = var.cluster_name
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  oidc_issuer_enabled = true

  default_node_pool {
    name                = "default"
    min_count           = var.cluster_min_nodes
    max_count           = var.cluster_max_nodes
    vm_size             = var.cluster_vm_size
    enable_auto_scaling = true
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_ws.id
  }
}
