# Remote Data Loader Azure Terraform Example Templates

Use these templates to create resources for a Foxglove Remote Data Loader.

## Overview

Once the resources are created, you'll be able to deploy the remote-data-loader Helm chart
into the created AKS cluster. The service uses the Azure Blob Storage cache container for
read/write operations.

## Getting started

### Create resources for the Terraform provider and backend

To set up the Azure provider, you'll need an Azure subscription, a resource group and
a service principal.

It's also best practice on Azure to store the Terraform state in a storage account. See the
[primary-site Azure README](../../primary-site/azure/README.md) for detailed instructions.

### Run Terraform

1. Copy `terraform.tfvars-example` to `terraform.tfvars`
2. Change the variables as needed
3. Copy `backend.tfvars-example` to `backend.tfvars`
4. Update the backend variables
5. Run `terraform init --backend-config backend.tfvars`

You should now be able to run `terraform plan` and `terraform apply`.

## Modules

- `iam`: creates an Active Directory application and service principal with Storage Blob Data
  Contributor access to the cache container. The credentials can be used for the
  `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, and `AZURE_CLIENT_SECRET` environment variables.

## Shared modules

This deployment uses shared modules from `../../modules/azure/`:

- `storage-account`: creates the storage account with blob retention policies. The `cache`
  container is created locally by this deployment.
- `aks-cluster`: creates an AKS cluster with auto-scaling node pools and log analytics.
