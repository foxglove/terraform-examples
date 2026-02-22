# Remote Data Loader AWS Terraform Example Templates

Use these templates to create resources for a Foxglove Remote Data Loader.

## Overview

Once the resources are created, you'll be able to deploy the remote-data-loader Helm chart
into the created EKS cluster. The service uses the S3 cache bucket for read/write operations.

The Helm chart's service account needs to be configured to use the IAM role created by
this template, allowing the service to connect to the cache bucket.

## Getting started

### Configure the AWS Terraform provider

Terraform [can derive credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
from several sources. Choose the method that's in line with your organization's policies, and ensure
Terraform has sufficient access to modify your infrastructure.

It's also best practice for the AWS provider to store the Terraform state on S3. Create an S3 bucket,
and make sure to **block all public access** (the tfstate will contain secrets).

### Run Terraform

Before running Terraform for the first time, configure your local variables.

1. Copy `terraform.tfvars-example` to `terraform.tfvars`
2. Change the variables as needed
3. Copy `backend.tfvars-example` to `backend.tfvars`
4. Set the bucket name and region for state storage
5. Run `terraform init --backend-config backend.tfvars`

You should now be able to run `terraform plan` and `terraform apply`.

## Modules

- `iam`: creates the IAM role with read/write access to the cache bucket. The role is configured
  for use with EKS service accounts (IRSA) in the `foxglove` namespace.

## Shared modules

This deployment uses shared modules from `../../modules/aws/`:

- `s3-bucket`: creates an S3 bucket with private access, used for the cache bucket.
- `eks-cluster`: creates a VPC and EKS cluster with managed node groups and optional Fargate profiles.
