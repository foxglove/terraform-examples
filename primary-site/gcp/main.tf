## ----- Storage -----

module "bucket_inbox" {
  source      = "../../modules/gcp/gcs-bucket"
  gcp_project = var.gcp_project
  gcp_region  = var.gcp_region

  bucket_name                              = var.inbox_bucket_name
  bucket_delete_days_since_noncurrent_time = var.bucket_delete_days_since_noncurrent_time
  bucket_delete_num_newer_version          = var.bucket_delete_num_newer_version
}

module "bucket_lake" {
  source      = "../../modules/gcp/gcs-bucket"
  gcp_project = var.gcp_project
  gcp_region  = var.gcp_region

  bucket_name                              = var.lake_bucket_name
  bucket_delete_days_since_noncurrent_time = var.bucket_delete_days_since_noncurrent_time
  bucket_delete_num_newer_version          = var.bucket_delete_num_newer_version
}

## ----- Pubsub -----

module "inbox_pubsub" {
  source      = "./modules/pubsub"
  gcp_project = var.gcp_project

  inbox_notification_endpoint = var.inbox_notification_endpoint
  bucket_name                 = module.bucket_inbox.bucket_name
}

## ----- IAM Credentials -----

module "iam" {
  source      = "./modules/iam"
  gcp_project = var.gcp_project

  iam_user_name     = var.primarysite_iam_user_name
  inbox_bucket_name = module.bucket_inbox.bucket_name
  lake_bucket_name  = module.bucket_lake.bucket_name
}

## ----- VPC & Autopilot cluster -----

module "cluster" {
  source       = "../../modules/gcp/gke-cluster"
  gcp_project  = var.gcp_project
  gcp_region   = var.gcp_region
  vpc_name     = var.vpc_name
  cluster_name = var.cluster_name
}
