output "storage_account_resource_id" {
  value       = azurerm_storage_account.storage.id
  description = "ID of the created storage account"
}

output "storage_account_name" {
  value       = azurerm_storage_account.storage.name
  description = "Name of the created storage account (will be the same as the input variable)"
}

output "inbox_storage_container_name" {
  value       = azurerm_storage_container.inbox.name
  description = "Name of the `inbox` container"
}

output "lake_storage_container_name" {
  value       = azurerm_storage_container.lake.name
  description = "Name of the `lake` container"
}
