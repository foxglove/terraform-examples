output "service_account_key" {
  description = "IAM user access key to use for GOOGLE_APPLICATION_CREDENTIALS"
  sensitive   = true
  value       = base64decode(google_service_account_key.iam_user_key.private_key)
}
