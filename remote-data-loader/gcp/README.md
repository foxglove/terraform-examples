# Remote Data Loader GCP Terraform Example Templates

Use these templates to create resources for a Foxglove Remote Data Loader.

## Overview

Once the resources are created, you'll be able to deploy the Remote Data Loader Helm charts
into the created GKE Autopilot cluster, using the cache bucket for temporary storage.

This template includes Terraform modules for:

- **IAM** - creates a service account with access to the cache bucket
- **Storage** - provisions a cache bucket with automatic expiration

The template's IAM user is created with a private key, which can be used in the
Kubernetes cluster's `cloud-credentials` secret, allowing the services to connect to the
cache bucket.

## Getting started

### Create service account for Terraform provider

Terraform needs a GCP project and a service account with project owner permissions.

**Using gcloud CLI:**

```bash
# Set your project ID (find it in GCP Console dashboard or run: gcloud projects list)
PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# Create the service account
gcloud iam service-accounts create terraform-admin \
  --display-name="Terraform Admin"

# Grant Owner role
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-admin@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/owner"

# Create and download JSON key
gcloud iam service-accounts keys create terraform-admin-key.json \
  --iam-account="terraform-admin@${PROJECT_ID}.iam.gserviceaccount.com"
```

**Using GCP Console:**

- Select `IAM & Admin` and then `Service Accounts`
- Select `Create service account`
- Give it a descriptive name (e.g., `terraform-admin` or `project-terraform-sa`)
- In `Grant this service account access to the project` select `Owner` basic role
- Open the `keys` tab, add a new key and download it as a JSON

### Create GCS bucket for Terraform state

It's best practice to store the Terraform state in GCP's cloud storage. This will be
used to store the `tfstate` in the cloud, rather than keeping them locally.

**Using gcloud CLI:**

```bash
# Bucket names must be globally unique
BUCKET_NAME="terraform-state-${PROJECT_ID}"

gcloud storage buckets create gs://${BUCKET_NAME} \
  --uniform-bucket-level-access
```

**Using GCP Console:**

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
2. Update the variables in `backend.tfvars`
3. Initialize Terraform with the backend configuration:
   ```
   terraform init --backend-config backend.tfvars
   ```

### Configure Terraform Variables

Next, configure the main Terraform variables:

1. Copy `terraform.tfvars-example` to `terraform.tfvars`
2. Update the variables in `terraform.tfvars`

### Deploy Resources

Once both configuration files are set up, you can deploy the resources:

```
terraform plan
terraform apply
```

## Modules

- `iam`: creates an IAM user with a JSON private key. The JSON will be stored base64-encoded in
  the `tfstate` as a sensitive output value. Copy the decoded content to a `credentials.json`
  file, then create a `cloud-credentials` secret for the Kubernetes cluster, as described
  in the [Configure Cloud Credentials](https://docs.foxglove.dev/docs/remote-data-loaders/deploy)
  section.
  This user has read/write access to the cache bucket.

- `storage`: creates a cache bucket with private access and automatic object expiration.
  The lifecycle rule ensures cached objects are automatically deleted after the configured
  number of days.

## Connecting to the cluster

This Terraform example creates all resources needed for a working Foxglove Remote Data
Loader deployment: the VPC, GKE Autopilot cluster, IAM user and key, and cache bucket.
The next step is to connect to the cluster, and then deploy the
[helm charts](https://helm-charts.foxglove.dev).

See how to connect to the cluster using the [gcloud CLI here](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials).
