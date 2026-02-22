## ----- Storage -----

resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.resource_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    delete_retention_policy {
      days = var.deleted_blob_retention_days
    }
    container_delete_retention_policy {
      days = var.deleted_container_retention_days
    }
  }
}

resource "azurerm_storage_container" "cache" {
  name                  = "cache"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

## ----- IAM -----

module "iam" {
  source = "./modules/iam"

  resource_group_name      = var.resource_group_name
  storage_account_name     = azurerm_storage_account.storage.name
  application_display_name = var.application_display_name
  cache_storage_container_name = azurerm_storage_container.cache.name
}

## ----- Kubernetes cluster -----

module "kubernetes_cluster" {
  source = "../../modules/azure/aks-cluster"

  resource_group_name = var.resource_group_name
  resource_location   = var.resource_location

  cluster_name      = var.cluster_name
  cluster_min_nodes = var.cluster_min_nodes
  cluster_max_nodes = var.cluster_max_nodes
  cluster_vm_size   = var.cluster_vm_size
}
