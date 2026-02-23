# Remote Data Loader Azure Terraform Example Templates

Use these templates to create resources for a Foxglove Remote Data Loader.

## Overview

Once the resources are created, you'll be able to deploy the Remote Data Loader Helm charts
into the created AKS cluster, using the cache container for temporary storage.

This template includes Terraform modules for:

- **IAM** - creates a service principal with access to the cache container
- **Storage** - provisions a storage account with a cache container and lifecycle policy
- **K8s** - creates an AKS cluster with Log Analytics

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

Configure the variables:

1. Copy `terraform.tfvars-example` to `terraform.tfvars`
2. Change the variables as needed
3. Copy `backend.tfvars-example` to `backend.tfvars`
4. Set the storage account details for the Terraform state
5. Run `terraform init --backend-config backend.tfvars`

You should now be able to run `terraform plan` and `terraform apply`.

## Modules

- `iam`: creates an Active Directory application and a service principal with credentials that
  can be used for the `AZURE_TENANT_ID`, `AZURE_CLIENT_ID` and `AZURE_CLIENT_SECRET` environment
  variables in the Kubernetes secret, as described on the Foxglove docs website, under the
  [Configure Cloud Credentials](https://docs.foxglove.dev/docs/remote-data-loaders/deploy)
  section.
  This service principal has read/write access to the cache container.

- `storage`: creates the storage account with a cache container and automatic object expiration.
  The lifecycle policy ensures cached objects are automatically deleted after the configured
  number of days.

- `k8s`: creates an AKS cluster with Log Analytics, and outputs the connection details in the
  `tfstate`, under the `kube_config` key.

## Connecting to the cluster

After applying the Terraform configuration, you can connect to the AKS cluster using the
Azure CLI:

```bash
az aks get-credentials --resource-group <resource_group_name> --name <cluster_name>
```

Then deploy the [helm charts](https://helm-charts.foxglove.dev).
