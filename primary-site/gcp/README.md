# Foxglove Data Platform - GCP

1. GCP Project: Each BYOC customer should create a GCP _project_ that will house the foxglove deployed resources.

2. Owner service account keys: The customer should create a service account with _project owner_ permissions for this project. They should provide foxglove with the keys to this service account. A good name choice for the service account is `foxglove-terraform-deployer`

3. Terraform backend 

This project uses a GCS backend to store the Terraform state.

By default, Terraform stores state locally in a file named terraform.tfstate. This default configuration can make Terraform usage difficult for teams when multiple users run Terraform at the same time and each machine has its own understanding of the current infrastructure.

https://cloud.google.com/docs/terraform/resource-management/store-state


## Required environment variables

`GOOGLE_CREDENTIALS`: JSON key for the owner service account

## Modules

- `storage` 

- `pubsub`

