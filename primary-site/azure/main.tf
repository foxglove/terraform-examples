## ----- Storage -----

module "storage_account" {
  count  = var.use_existing_storage ? 0 : 1
  source = "../../modules/azure/storage-account"

  resource_group_name         = var.resource_group_name
  resource_location           = var.resource_location
  storage_account_name        = var.storage_account_name
  deleted_blob_retention_days      = var.deleted_blob_retention_days
  deleted_container_retention_days = var.deleted_container_retention_days
}

locals {
  quarantine_cutoff_days       = 366
  storage_account_id           = var.use_existing_storage ? var.existing_storage_account_resource_id : module.storage_account[0].storage_account_id
  storage_account_name         = var.use_existing_storage ? var.existing_storage_account_name : module.storage_account[0].storage_account_name
  inbox_storage_container_name = var.use_existing_storage ? var.existing_inbox_storage_container_name : azurerm_storage_container.inbox[0].name
  lake_storage_container_name  = var.use_existing_storage ? var.existing_lake_storage_container_name : azurerm_storage_container.lake[0].name
}

resource "azurerm_storage_container" "inbox" {
  count                 = var.use_existing_storage ? 0 : 1
  name                  = "inbox"
  storage_account_name  = module.storage_account[0].storage_account_name
  container_access_type = "private"
}

resource "azurerm_storage_container" "lake" {
  count                 = var.use_existing_storage ? 0 : 1
  name                  = "lake"
  storage_account_name  = module.storage_account[0].storage_account_name
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "storage_policy" {
  count              = var.use_existing_storage ? 0 : 1
  storage_account_id = module.storage_account[0].storage_account_id
  rule {
    name    = "deleteTmpfiles"
    enabled = true
    filters {
      prefix_match = ["lake/tmp/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 1
      }
      snapshot {
        delete_after_days_since_creation_greater_than = 1
      }
      version {
        delete_after_days_since_creation = 1
      }
    }
  }
  rule {
    name    = "deleteOldQuarantinedFiles"
    enabled = true
    filters {
      prefix_match = ["inbox/_quarantine/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = local.quarantine_cutoff_days
      }
      snapshot {
        delete_after_days_since_creation_greater_than = local.quarantine_cutoff_days
      }
      version {
        delete_after_days_since_creation = local.quarantine_cutoff_days
      }
    }
  }
}

## ----- EventGrid -----

module "inbox_notification" {
  source = "./modules/eventgrid"

  resource_group_name         = var.resource_group_name
  resource_location           = var.resource_location
  storage_account_name        = local.storage_account_name
  storage_account_resource_id = local.storage_account_id

  inbox_notification_endpoint         = var.inbox_notification_endpoint
  inbox_webhook_max_delivery_attempts = var.inbox_webhook_max_delivery_attempts
  inbox_webook_event_minutes_to_live  = var.inbox_webook_event_minutes_to_live
}

## ----- IAM -----

module "primary_site_iam" {
  source = "./modules/iam"

  resource_group_name          = var.resource_group_name
  storage_account_name         = local.storage_account_name
  application_display_name     = var.application_display_name
  inbox_storage_container_name = local.inbox_storage_container_name
  lake_storage_container_name  = local.lake_storage_container_name

  use_existing_service_principal        = var.use_existing_service_principal
  existing_service_principal_client_id  = var.existing_service_principal_client_id
  existing_service_principal_object_id  = var.existing_service_principal_object_id
  existing_service_principal_client_secret = var.existing_service_principal_client_secret
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
