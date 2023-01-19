## ----- Storage -----

module "storage" {
  source = "./modules/storage"

  resource_group_name              = var.resource_group_name
  resource_location                = var.resource_location
  storage_account_name             = var.storage_account_name
  deleted_blob_retention_days      = var.deleted_blob_retention_days
  deleted_container_retention_days = var.deleted_container_retention_days
}
