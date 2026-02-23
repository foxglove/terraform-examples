output "service_account_key" {
  description = "Service account key to use for `GOOGLE_APPLICATION_CREDENTIALS`"
  sensitive   = true
  value       = base64decode(google_service_account_key.service_account_key.private_key)
}
