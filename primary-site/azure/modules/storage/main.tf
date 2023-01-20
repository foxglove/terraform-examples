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

resource "azurerm_storage_management_policy" "storage_policy" {
  storage_account_id = azurerm_storage_account.storage.id
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
}

resource "azurerm_storage_container" "inbox" {
  name                  = "inbox"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "lake" {
  name                  = "lake"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
