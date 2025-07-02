output "tenant_id" {
  value       = data.azuread_client_config.current.tenant_id
  description = "Echoes back the tenant (directory) ID"
}

output "client_id" {
  value       = var.use_existing_service_principal ? var.existing_service_principal_client_id : azuread_application.primary_site[0].client_id
  description = "Echoes the `client_id` output value"
}

output "client_secret" {
  value       = var.use_existing_service_principal ? var.existing_service_principal_client_secret : azuread_service_principal_password.iam_principal[0].value
  description = "Echoes the `password` output value"
  sensitive   = true
}
