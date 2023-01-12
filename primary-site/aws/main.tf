## ----- S3 buckets -----

module "s3_lake" {
  source      = "./modules/s3"
  bucket_name = var.lake_bucket_name
}

module "s3_inbox" {
  source      = "./modules/s3"
  bucket_name = var.inbox_bucket_name
}

## ----- Pubsub -----

module "inbox_sns_notification" {
  source     = "./modules/sns"
  bucket_arn = module.s3_inbox.bucket_arn
  bucket_id  = module.s3_inbox.bucket_id
  topic_name = "${var.inbox_bucket_name}-sns-topic"

  inbox_notification_endpoint = var.inbox_notification_endpoint
}

## ----- IAM Credentials -----

module "iam" {
  source           = "./modules/iam"
  lake_bucket_arn  = module.s3_lake.bucket_arn
  inbox_bucket_arn = module.s3_inbox.bucket_arn
  iam_user_name    = var.primarysite_iam_user_name
}
