# Primary Site Azure Terraform Example Templates

Use these templates to create resources for a Foxglove Primary Site.

## Overview

## Getting started

### Create resources for the Terraform provider and backend

To set up the Azure provider, you'll need an Azure subscription, a resource group and
a service principal.

It's also best practice on Azure to store the Terraform state in a storage account. This
will be used to store the `tfstate` in the cloud, rather than keeping them locally.

Before you can use Azure Storage as a backend, you need to create a storage account; Azure's
documentation describes how to [create required resources](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage).

### Use these credentials

Terraform will need to authenticate to Azure via the Azure CLI. A simple option is to use
the cli's `az login` feature, but Terraform can discover the service principal credentials
from env variables or from its provider block. See all scenarios described in the article
[Authenticate Terraform to Azure](https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure).

If your backend configuration requires special authentication, see the example configuration in
the [azurerm backend docs](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)

### Run Terraform

Configure the variables. Note that some of them you'll find on the Foxglove
[Settings page](https://app.foxglove.dev/~/settings/sites), under the Sites
tab.

1. Copy `terraform.tfvars-example` to `terraform.tfvars`
2. Use the `inbox_notification_endpoint` variable from the Foxglove site settings.
3. Change the other variables as needed
4. Copy `backend.tfvars-example` to `backend.tfvars`
5. Set the bucket name and region to what was created in the "Getting started" step; key can
   be any object key.
6. Run `terraform init --backend-config backend.tfvars`

You should now be able to run `terraform plan` and `terraform apply`.

## Storage Configuration

The template supports two modes for storage configuration:

### Default Mode (Create New Storage)
By default, the template creates a new storage account with `inbox` and `lake` containers.
Set `use_existing_storage = false` (default) and configure:
- `storage_account_name`: Name for the new storage account
- `deleted_blob_retention_days`: Retention policy for blobs
- `deleted_container_retention_days`: Retention policy for containers

### Existing Storage Mode
To use pre-existing storage account and containers, set `use_existing_storage = true` and provide:
- `existing_storage_account_name`: Name of existing storage account
- `existing_storage_account_resource_id`: Full resource ID of existing storage account
- `existing_inbox_storage_container_name`: Name of existing inbox container
- `existing_lake_storage_container_name`: Name of existing lake container

When using existing storage, the storage module is skipped entirely, and the template will only configure EventGrid and IAM permissions for the existing resources.

## Modules

- `iam`: creates an Active Directory application and a service principal with credentials that 
  can be used for the `AZURE_TENANT_ID`, `AZURE_CLIENT_ID` and `AZURE_CLIENT_SECRET` environment
  variables in the Kubernets secret, as described on the Foxglove docs website, under the
  [Configure Cloud Credentials](https://foxglove.dev/docs/data-platform/primary-sites/configure-cloud-credentials)
  section.
  This service principal has access to read/write both the `inbox` and `lake` containers.

- `eventgrid`: creates an EventGrid topic with a https subscription, and attaches it to the inbox
  container. Whenever a new object appears in the storage container, the webhook
  `inbox_notification_endpoint` will be notified.

## Shared modules

This deployment uses shared modules from `../../modules/azure/`:

- `storage-account`: creates the storage account with blob retention policies. The `inbox` and `lake`
  containers and management policies are created locally by this deployment. This module is only used
  when `use_existing_storage = false`.

- `aks-cluster`: creates a kubernetes cluster, and outputs the connection details in the `tfstate`, under
  the `kube_config_raw` key.
