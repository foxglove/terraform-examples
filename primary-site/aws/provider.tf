# Store Terraform state in S3 (NOTE we don't use DynamoDB so there's no locking information)
terraform {
  required_version = ">= 1.3.2"
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Assuming AWS provider version based on modules, adjust if needed
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  # Region will be determined from AWS configuration (env vars, ~/.aws/config, etc.)
}

# Only configure the kubernetes provider after the cluster exists
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the aws CLI to be installed and configured
    args = ["eks", "get-token", "--cluster-name", "${var.prefix}-cluster"]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the aws CLI to be installed and configured
      args = ["eks", "get-token", "--cluster-name", "${var.prefix}-cluster"]
    }
  }
}
