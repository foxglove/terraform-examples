# Primary Site GCP Terraform Example Templates

Use these templates to create resources for a Foxglove Primary Site.

## Overview

Once the resources are created, you'll be able to deploy the Helm charts into the created
GKS Autopilot cluster, and use the included storage buckets for inbox and lake.

The template's IAM user is created with a private key, which can be used in the
Kubernetes cluster's `cloud-credentials` secret, allowing the services to connect to the
inbox and lake buckets.

## Getting started

### Create resources for the Terraform provider

Terraform needs a GCS project and a service account with project owner permissions.

To add a new service account with a private key:

- Select `IAM & Admin` and then `Service Accounts`
- Select `Create service account`
- In `Grant this service account access to the project` select `Owner` basic role
- Open the `keys` tab, add a new key and download it as a JSON

It's also best practice to store the Terraform state in GCS's cloud storage. This will be
used to store the `tfstate` in the cloud, rather than keeping them locally. Create a bucket,
and make sure to block all public access (the tfstate will contain secrets).

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
