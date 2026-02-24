output "bucket_name" {
  value       = aws_s3_bucket.cache_bucket.bucket
  description = "Name of the S3 bucket created (will be the same as the input variable)"
}

output "bucket_id" {
  value       = aws_s3_bucket.cache_bucket.id
  description = "ID of the S3 bucket created"
}

output "bucket_arn" {
  value       = aws_s3_bucket.cache_bucket.arn
  description = "ARN of the S3 bucket created"
}
