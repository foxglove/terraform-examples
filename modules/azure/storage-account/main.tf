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
