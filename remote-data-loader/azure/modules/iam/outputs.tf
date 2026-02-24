output "tenant_id" {
  value       = data.azuread_client_config.current.tenant_id
  description = "The Azure tenant (directory) ID"
}

output "client_id" {
  value       = azuread_application.remote_data_loader.client_id
  description = "The application client ID"
}

output "client_secret" {
  value       = azuread_service_principal_password.iam_principal.value
  description = "The service principal password"
  sensitive   = true
}
