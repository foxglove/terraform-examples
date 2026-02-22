output "tenant_id" {
  value       = data.azuread_client_config.current.tenant_id
  description = "Echoes back the tenant (directory) ID"
}

output "client_id" {
  value       = azuread_application.remote_data_loader.client_id
  description = "Client ID of the application"
}

output "client_secret" {
  value       = azuread_service_principal_password.iam_principal.value
  description = "Client secret of the service principal"
  sensitive   = true
}
