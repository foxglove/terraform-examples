## ----- S3 buckets -----

module "s3_lake" {
  source      = "../../modules/aws/s3-bucket"
  bucket_name = var.lake_bucket_name

  abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days
}

module "s3_inbox" {
  source      = "../../modules/aws/s3-bucket"
  bucket_name = var.inbox_bucket_name

  abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days
}

## ----- Pubsub -----

module "inbox_sns_notification" {
  source     = "./modules/sns"
  bucket_arn = module.s3_inbox.bucket_arn
  bucket_id  = module.s3_inbox.bucket_id
  topic_name = "${var.inbox_bucket_name}-sns-topic"

  inbox_notification_endpoint = var.inbox_notification_endpoint
}

## ----- VPC & EKS cluster -----

module "cluster" {
  source = "../../modules/aws/eks-cluster"

  vpc_name        = var.vpc_name
  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  fargate_namespaces = ["foxglove"]
}

## ----- IAM policy & roles -----

module "iam" {
  source                 = "./modules/iam"
  lake_bucket_arn        = module.s3_lake.bucket_arn
  inbox_bucket_arn       = module.s3_inbox.bucket_arn
  eks_oidc_provider_arn  = module.cluster.oidc_provider_arn
  eks_foxglove_namespace = "foxglove"
}
