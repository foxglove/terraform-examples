data "azurerm_subscription" "current" {}

data "azuread_client_config" "current" {}

resource "azuread_application" "primary_site" {
  display_name = var.application_display_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "iam_principal" {
  client_id = azuread_application.primary_site.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "iam_principal" {
  service_principal_id = azuread_service_principal.iam_principal.id
}

resource "azurerm_role_assignment" "iam_principal_lake_contributor" {
  principal_id         = azuread_service_principal.iam_principal.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.storage_account_name}/blobServices/default/containers/${var.inbox_storage_container_name}"
}

resource "azurerm_role_assignment" "iam_principal_inbox_contributor" {
  principal_id         = azuread_service_principal.iam_principal.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.storage_account_name}/blobServices/default/containers/${var.lake_storage_container_name}"
}
