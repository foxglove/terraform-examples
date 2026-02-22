output "storage_account_id" {
  value       = azurerm_storage_account.storage.id
  description = "ID of the created storage account"
}

output "storage_account_name" {
  value       = azurerm_storage_account.storage.name
  description = "Name of the created storage account (will be the same as the input variable)"
}
