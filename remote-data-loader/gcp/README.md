# Remote Data Loader GCP Terraform Example Templates

Use these templates to create resources for a Foxglove Remote Data Loader.

## Overview

Once the resources are created, you'll be able to deploy the remote-data-loader Helm chart
into the created GKE Autopilot cluster. The service uses the GCS cache bucket for read/write
operations.

The template's IAM user is created with a private key, which can be used in the
Kubernetes cluster's `cloud-credentials` secret, allowing the service to connect to the
cache bucket.

## Getting started

### Create service account for Terraform provider

Terraform needs a GCP project and a service account with project owner permissions. See the
[primary-site GCP README](../../primary-site/gcp/README.md) for detailed instructions on
creating the Terraform service account and GCS state bucket.

### Run Terraform

1. Copy `terraform.tfvars-example` to `terraform.tfvars`
2. Update the variables as needed
3. Copy `backend.tfvars-example` to `backend.tfvars`
4. Update the backend variables
5. Run `terraform init --backend-config backend.tfvars`

You should now be able to run `terraform plan` and `terraform apply`.

## Modules

- `iam`: creates a service account with read/write access to the cache bucket and exports
  a private key for use as `GOOGLE_APPLICATION_CREDENTIALS`.

## Shared modules

This deployment uses shared modules from `../../modules/gcp/`:

- `gcs-bucket`: creates a GCS bucket with versioning and lifecycle rules, used for the cache bucket.
- `gke-cluster`: creates a VPC and GKE Autopilot cluster.
