output "iam_user_access_id" {
  value       = aws_iam_access_key.iam_user_key.id
  description = "IAM user with programmatic access to read/write S3 buckets with"
  sensitive   = true
}

output "iam_user_secret_key" {
  value       = aws_iam_access_key.iam_user_key.secret
  description = "IAM user with programmatic access to read/write S3 buckets with"
  sensitive   = true
}
