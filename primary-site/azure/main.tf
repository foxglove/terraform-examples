## ----- Storage -----

module "storage" {
  source = "./modules/storage"

  resource_group_name              = var.resource_group_name
  resource_location                = var.resource_location
  storage_account_name             = var.storage_account_name
  deleted_blob_retention_days      = var.deleted_blob_retention_days
  deleted_container_retention_days = var.deleted_container_retention_days
}

## ----- EventGrid -----

module "inbox_notification" {
  source = "./modules/eventgrid"

  resource_group_name         = var.resource_group_name
  resource_location           = var.resource_location
  storage_account_name        = module.storage.storage_account_name
  storage_account_resource_id = module.storage.storage_account_resource_id

  inbox_notification_endpoint         = var.inbox_notification_endpoint
  inbox_webhook_max_delivery_attempts = var.inbox_webhook_max_delivery_attempts
  inbox_webook_event_minutes_to_live  = var.inbox_webook_event_minutes_to_live
}

## ----- IAM -----

module "primary_site_iam" {
  source = "./modules/iam"

  resource_group_name          = var.resource_group_name
  storage_account_name         = module.storage.storage_account_name
  application_display_name     = var.application_display_name
  inbox_storage_container_name = module.storage.inbox_storage_container_name
  lake_storage_container_name  = module.storage.lake_storage_container_name
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
