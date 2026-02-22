## ----- Storage -----

module "storage_account" {
  source = "../../modules/azure/storage-account"

  resource_group_name         = var.resource_group_name
  resource_location           = var.resource_location
  storage_account_name        = var.storage_account_name
  deleted_blob_retention_days      = var.deleted_blob_retention_days
  deleted_container_retention_days = var.deleted_container_retention_days
}

resource "azurerm_storage_container" "cache" {
  name                  = "cache"
  storage_account_name  = module.storage_account.storage_account_name
  container_access_type = "private"
}

## ----- IAM -----

module "iam" {
  source = "./modules/iam"

  resource_group_name          = var.resource_group_name
  storage_account_name         = module.storage_account.storage_account_name
  application_display_name     = var.application_display_name
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
