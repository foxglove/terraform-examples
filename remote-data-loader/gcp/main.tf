## ----- Storage -----

module "cache_bucket" {
  source      = "./modules/storage"
  gcp_project = var.gcp_project
  gcp_region  = var.gcp_region

  bucket_name           = var.cache_bucket_name
  cache_expiration_days = var.cache_expiration_days
}

## ----- IAM Credentials -----

module "iam" {
  source      = "./modules/iam"
  gcp_project = var.gcp_project

  service_account_name = var.service_account_name
  cache_bucket_name    = module.cache_bucket.bucket_name
}

## ----- VPC -----

module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "7.1.0"
  project_id   = var.gcp_project
  network_name = var.vpc_name
  subnets = [
    {
      subnet_name      = "rdl-subnet-01"
      subnet_ip        = "10.2.0.0/16"
      subnet_region    = var.gcp_region
      subnet_flow_logs = "true"
    }
  ]
  secondary_ranges = {
    "rdl-subnet-01" = [
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
}
