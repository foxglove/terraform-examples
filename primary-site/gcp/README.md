# Primary Site GCP Terraform Example Templates

Use these templates to create resources for a Foxglove Primary Site.

## Overview

Once the resources are created, you'll be able to deploy the Helm charts into the created
GKS Autopilot cluster, and use the included storage buckets for inbox and lake.

The template's IAM user is created with a private key, which can be used in the
Kubernetes cluster's `cloud-credentials` secret, allowing the services to connect to the
inbox and lake buckets.

## Getting started

### Create service account for Terraform provider

Terraform needs a GCP project and a service account with project owner permissions.

To add a new service account with a private key:

- Select `IAM & Admin` and then `Service Accounts`
- Select `Create service account`
- Give it a descriptive name (e.g., `terraform-admin` or `project-terraform-sa`) - note that this is separate from the IAM username `primarysite_iam_user_name` you'll configure later in `terraform.tfvars`
- In `Grant this service account access to the project` select `Owner` basic role
- Open the `keys` tab, add a new key and download it as a JSON

### Create GCS bucket for Terraform state

It's best practice to store the Terraform state in GCS's cloud storage. This will be
used to store the `tfstate` in the cloud, rather than keeping them locally.

To create a state bucket:

- Go to `Cloud Storage` and create a new bucket
- Choose a unique name (e.g., `terraform-state-fg-myproject`)
- Make sure to block all public access (the tfstate will contain secrets)
- Note the bucket name - you'll need it for the `backend.tfvars` configuration

### Use these credentials

Terraform can use these credentials from the JSON key downloaded in the previous step; just
set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to the path of this file.

Another simple option is to install [gcloud](https://cloud.google.com/sdk/docs/install) CLI,
and log in with a Google account:

```
gcloud auth application-default login
```

Whichever method you choose, the provider in the Terraform package will pick up the default
credentials.

### Configure Terraform Backend

First, configure the Terraform backend to store state in GCS:

1. Copy `backend.tfvars-example` to `backend.tfvars`
2. Update the following variables in `backend.tfvars`:
   - `bucket`: The name of the GCS bucket you created in the "Create GCS bucket for Terraform state" step for storing Terraform state
   - `prefix`: The path/prefix for your Terraform state file (e.g., `primarysite/my-environment`)

3. Initialize Terraform with the backend configuration:
   ```
   terraform init --backend-config backend.tfvars
   ```

   After initialization, your GCS bucket will have the following structure:
   ```
   <bucket>
   |--primarysite (Directory)
     |--my-environment (Directory)
       |--default.tfstate (File)
   ```

### Configure Terraform Variables

Next, configure the main Terraform variables. Note that some of them you'll find on the Foxglove
[Settings page](https://app.foxglove.dev/~/settings/sites), under the Sites tab.

1. Copy `terraform.tfvars-example` to `terraform.tfvars`
2. Update the following variables in `terraform.tfvars`:
   - `gcp_project`: Your GCP project ID
   - `gcp_region`: The GCP region where resources will be created (e.g., `us-east1`)
   - `vpc_name`: Name for the VPC (e.g., `org-slug-vpc`)
   - `cluster_name`: Name for the GKE cluster (e.g., `org-slug-cluster`)
   - `inbox_bucket_name`: Name for the inbox storage bucket (e.g., `org-slug-inbox-bucket`)
   - `lake_bucket_name`: Name for the lake storage bucket (e.g., `org-slug-lake-bucket`)
   - `bucket_delete_days_since_noncurrent_time`: Days to retain non-current object versions (default: 14)
   - `bucket_delete_num_newer_version`: Number of newer versions to retain (default: 3)
   - `inbox_notification_endpoint`: Webhook endpoint from the Foxglove site settings (e.g, `https://api.foxglove.dev/endpoints/inbox-notifications?token=fox_snt_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`)
   - `primarysite_iam_user_name`: Name for the IAM service account (e.g., `org-slug-primarysite-user`)

### Deploy Resources

Once both configuration files are set up, you can deploy the resources:

```
terraform plan
terraform apply
```

## Modules

- `iam`: creates an IAM user with a JSON private key. The json will be stored base64-encoded in
  the `tfstate` as sensitive output value. Copy the decoded content in a `credentials.json`
  file, then create a `cloud-credentials` secret for the Kubernetes cluster, as described
  in the [Configure Cloud Credentials](https://foxglove.dev/docs/data-platform/primary-sites/configure-cloud-credentials)
  section.
  This user has access to read/write both the `inbox` and `lake` buckets.

- `storage`: creates a bucket with private access. This module is used to create the `inbox` and
  `lake` buckets. The lifecycle rule ensures that incomplete multipart uploads are garbage
  collected - otherwise the uploaded parts would remain in the S3 bucket, occurring charges
  forever.

- `pubsub`: creates a Pub/Sub topic and dead letter queue with a https subscription, and attaches
  it to a bucket's `OBJECT_FINALIZE` object notifications. Whenever a new object appears
  in the bucket, the webhook `inbox_notification_endpoint` will be notified.

## Connecting to the cluster

This Terraform example creates all resources that are needed for a working Foxglove Primary
Site deployment: the VPC, GKS Autopilot cluster, IAM user and key, storage buckets and the
PubSub. The next step is to connect to the cluster, and then deploy the
[helm charts](https://helm-charts.foxglove.dev).

See how to connect to the cluster using the [gcloud CLI here](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials).
