## ----- Storage -----

module "storage" {
  source = "./modules/storage"

  resource_group_name   = var.resource_group_name
  resource_location     = var.resource_location
  storage_account_name  = var.storage_account_name
  cache_expiration_days = var.cache_expiration_days
}

## ----- IAM -----

module "iam" {
  source = "./modules/iam"

  resource_group_name      = var.resource_group_name
  storage_account_name     = module.storage.storage_account_name
  cache_container_name     = module.storage.cache_container_name
  application_display_name = var.application_display_name
}

## ----- Kubernetes cluster -----

module "kubernetes_cluster" {
  source = "./modules/k8s"

  resource_group_name = var.resource_group_name
  resource_location   = var.resource_location

  cluster_name      = var.cluster_name
  cluster_min_nodes = var.cluster_min_nodes
  cluster_max_nodes = var.cluster_max_nodes
  cluster_vm_size   = var.cluster_vm_size
}
