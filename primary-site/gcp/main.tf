## ----- Storage -----

module "bucket_inbox" {
  source      = "./modules/storage"
  gcp_project = var.gcp_project
  gcp_region  = var.gcp_region

  bucket_name                              = var.inbox_bucket_name
  bucket_delete_days_since_noncurrent_time = var.bucket_delete_days_since_noncurrent_time
  bucket_delete_num_newer_version          = var.bucket_delete_num_newer_version
}

module "bucket_lake" {
  source      = "./modules/storage"
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

## ----- VPC -----

module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "7.1.0"
  project_id   = var.gcp_project
  network_name = var.vpc_name
  subnets = [
    {
      subnet_name      = "subnet-01"
      subnet_ip        = "10.2.0.0/16"
      subnet_region    = var.gcp_region
      subnet_flow_logs = "true"
    }
  ]
  secondary_ranges = {
    "subnet-01" = [
      {
        range_name    = "pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = "services"
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

## ----- Autopilot cluster -----

resource "google_container_cluster" "cluster" {
  name             = var.cluster_name
  project          = var.gcp_project
  location         = var.gcp_region
  network          = module.vpc.network_self_link
  subnetwork       = element(module.vpc.subnets_self_links, 0)
  enable_autopilot = true
  ip_allocation_policy {
    cluster_secondary_range_name  = module.vpc.subnets_secondary_ranges[0][0].range_name
    services_secondary_range_name = module.vpc.subnets_secondary_ranges[0][1].range_name
  }
  dns_config { # forces replacement
    cluster_dns        = "CLOUD_DNS"
    cluster_dns_domain = "cluster.local"
    cluster_dns_scope  = "CLUSTER_SCOPE"
  }
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }
}
