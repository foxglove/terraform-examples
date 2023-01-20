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

Configure the variables. Note that some of them you'll find on the Foxglove console's
[Settings page](https://console.foxglove.party/organization?tab=sites), under the Sites
tab.

1. Copy `terraform.tfvars-example` to `terraform.tfvars`
2. Use the `inbox_notification_endpoint` variable from the Foxglove Console's site settings.
3. Change the other variables as needed
4. Copy `backend.tfvars-example` to `backend.tfvars`
5. Set the bucket name and region to what was created in the "Getting started" step; key can
   be any object key.
6. Run `terraform init --backend-config backend.tfvars`

You should now be able to run `terraform plan` and `terraform apply`.

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

- `storage`: creates the storage account with the `lake` and `inbox` containers and private
  access.

- `k8s`: creates a kubernetes cluster, and outputs the connection details in the `tfstate`, under
  the `kube_config_raw` key.
