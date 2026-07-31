# Store Terraform state in S3 (NOTE we don't use DynamoDB so there's no locking information)
terraform {
  # terraform-aws-modules/eks v21 requires Terraform >= 1.5.7 and AWS provider >= 6.52
  required_version = ">= 1.5.7"
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.57.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
