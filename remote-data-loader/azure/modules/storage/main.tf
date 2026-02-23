resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.resource_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_management_policy" "cache_policy" {
  storage_account_id = azurerm_storage_account.storage.id

  # Delete cached objects after expiration
  rule {
    name    = "deleteCachedFiles"
    enabled = true
    filters {
      prefix_match = ["cache/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.cache_expiration_days
      }
      snapshot {
        delete_after_days_since_creation_greater_than = var.cache_expiration_days
      }
      version {
        delete_after_days_since_creation = var.cache_expiration_days
      }
    }
  }
}

resource "azurerm_storage_container" "cache" {
  name                  = "cache"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}
