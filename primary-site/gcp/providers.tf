terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.47.0"
    }
  }
  backend "gcs" {}
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}
