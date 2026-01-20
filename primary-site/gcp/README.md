# Primary Site GCP Terraform Example Templates

Use these templates to create resources for a Foxglove Primary Site.

## Overview

Once the resources are created, you'll be able to deploy the Helm charts into the created
GKS Autopilot cluster, and use the included storage buckets for inbox and lake.

This template includes Terraform modules for:

- **IAM** – creates a service account with access to the storage buckets  
- **Storage** – provisions inbox and lake buckets  
- **Pub/Sub** – sets up notifications for new objects in the inbox  

See the [Modules](#modules) section below for more details.

The template's IAM user is created with a private key, which can be used in the
Kubernetes cluster's `cloud-credentials` secret, allowing the services to connect to the
inbox and lake buckets.

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
- Give it a descriptive name (e.g., `terraform-admin` or `project-terraform-sa`) - note that this is separate from the IAM username `primarysite_iam_user_name` you'll configure later in `terraform.tfvars`
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
2. Update the variables in `backend.tfvars`:

3. Initialize Terraform with the backend configuration:
   ```
   terraform init --backend-config backend.tfvars
   ```

   After initialization, your GCS bucket will have a structure similar to this:
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
2. Update the variables in `terraform.tfvars`:

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


## Example Configuration

Here is a minimal example of how to define global storage and ingress settings in your `values.yaml` file:

```yaml
globals:
  lake:
    storageProvider: google_cloud
    bucketName: <lake-bucket>
  inbox:
    storageProvider: google_cloud
    bucketName: <inbox-bucket>

ingress:
  enabled: true
  className: gce
  host: <your-domain>
  annotations:
    networking.gke.io/managed-certificates: ingress-cert
    kubernetes.io/ingress.class: gce
```

## Ingress Managed Certificate

On GKE, you can configure the ingress to use a **Google-managed SSL certificate**.  
This is done by creating a `ManagedCertificate` resource and referencing it in the ingress annotations (as shown above with `networking.gke.io/managed-certificates: <ingress-cert>`).

Here’s an example of a `cert.yaml` manifest:

```yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: <ingress-cert>
spec:
  domains:
    - <your-domain>
```

- Replace `<your-domain>` with the hostname specified under `ingress.host` in your `values.yaml`.
- Once applied, GKE will automatically provision and attach the managed certificate to your ingress when the domain points to the load balancer.

## Deploying with Helm

After creating your certificate and configuration files, deploy them using the following commands:

1. **Apply the managed certificate:**

   ```bash
   kubectl apply -f cert.yaml
   ```

2. **Install or upgrade the Helm release with your custom values:**

   ```bash
   helm upgrade --install foxglove-primary-site \
     oci://helm-charts.foxglove.dev/primary-site \
     -f values.yaml
   ```

   - Replace `foxglove-primary-site` with your preferred release name.
   - Ensure your cluster context is correctly set before running these commands (`kubectl config current-context`).
