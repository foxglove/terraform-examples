# Terraform Example Templates

## Primary Site

Use the templates under `/primary-site` to create resources for a Foxglove Primary Site.

For more details, see the README for each platform:

* [Amazon AWS](./primary-site/aws/README.md)
* [Google Cloud Platform](./primary-site/gcp/README.md)
* [Microsoft Azure](./primary-site/azure/README.md)

## Remote Data Loader

Use the templates under `/remote-data-loader` to create resources for a Foxglove Remote Data Loader.

For more details, see the README for each platform:

* [Amazon AWS](./remote-data-loader/aws/README.md)
* [Google Cloud Platform](./remote-data-loader/gcp/README.md)
* [Microsoft Azure](./remote-data-loader/azure/README.md)

## Shared Modules

Reusable Terraform modules shared across deployments are located under `/modules`, organized by
cloud provider:

* `modules/aws/s3-bucket` — S3 bucket with lifecycle rules
* `modules/aws/eks-cluster` — VPC and EKS cluster
* `modules/gcp/gcs-bucket` — GCS bucket with versioning and lifecycle rules
* `modules/gcp/gke-cluster` — VPC and GKE Autopilot cluster
* `modules/azure/storage-account` — Azure storage account with blob retention policies
* `modules/azure/aks-cluster` — AKS cluster with auto-scaling
