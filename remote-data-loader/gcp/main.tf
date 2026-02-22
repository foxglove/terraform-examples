## ----- Storage -----

module "bucket_cache" {
  source      = "../../modules/gcp/gcs-bucket"
  gcp_project = var.gcp_project
  gcp_region  = var.gcp_region

  bucket_name                              = var.cache_bucket_name
  bucket_delete_days_since_noncurrent_time = var.bucket_delete_days_since_noncurrent_time
  bucket_delete_num_newer_version          = var.bucket_delete_num_newer_version
}

## ----- IAM Credentials -----

module "iam" {
  source      = "./modules/iam"
  gcp_project = var.gcp_project

  iam_user_name     = var.iam_user_name
  cache_bucket_name = module.bucket_cache.bucket_name
}

## ----- VPC & Autopilot cluster -----

module "cluster" {
  source       = "../../modules/gcp/gke-cluster"
  gcp_project  = var.gcp_project
  gcp_region   = var.gcp_region
  vpc_name     = var.vpc_name
  cluster_name = var.cluster_name
}
