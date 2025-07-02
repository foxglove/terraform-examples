data "azurerm_subscription" "current" {}

data "azuread_client_config" "current" {}

# Create application and service principal only if not using existing one
resource "azuread_application" "primary_site" {
  count        = var.use_existing_service_principal ? 0 : 1
  display_name = var.application_display_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "iam_principal" {
  count    = var.use_existing_service_principal ? 0 : 1
  client_id = azuread_application.primary_site[0].client_id
  owners    = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "iam_principal" {
  count                = var.use_existing_service_principal ? 0 : 1
  service_principal_id = azuread_service_principal.iam_principal[0].id
}

# Use local values to determine which service principal details to use
locals {
  service_principal_object_id = var.use_existing_service_principal ? var.existing_service_principal_object_id : azuread_service_principal.iam_principal[0].object_id
}

resource "azurerm_role_assignment" "iam_principal_lake_contributor" {
  principal_id         = local.service_principal_object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.storage_account_name}/blobServices/default/containers/${var.inbox_storage_container_name}"
}

resource "azurerm_role_assignment" "iam_principal_inbox_contributor" {
  principal_id         = local.service_principal_object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.storage_account_name}/blobServices/default/containers/${var.lake_storage_container_name}"
}
