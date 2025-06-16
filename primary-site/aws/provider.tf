# Store Terraform state in S3 (NOTE we don't use DynamoDB so there's no locking information)
terraform {
  required_version = ">= 1.3.2"
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
