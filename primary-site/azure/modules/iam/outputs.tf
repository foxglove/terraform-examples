output "tenant_id" {
  value       = data.azuread_client_config.current.tenant_id
  description = "Echoes back the tenant (directory) ID"
}

output "client_id" {
  value       = azuread_application.primary_site.client_id
  description = "Echoes the `client_id` output value"
}

output "client_secret" {
  value       = azuread_service_principal_password.iam_principal.value
  description = "Echoes the `password` output value"
  sensitive   = true
}
