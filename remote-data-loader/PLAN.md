# Remote Data Loader Terraform Example — Plan

## What is a Terraform example in this repo?

Each Terraform example in this repository provisions the **cloud infrastructure** needed to deploy a specific Foxglove Helm chart into a Kubernetes cluster. The examples do **not** install the Helm chart themselves — they create the prerequisite cloud resources so that an operator can then `helm install` on top.

Concretely, each example consists of a per-cloud-provider directory (AWS, GCP, Azure) containing:

| File | Purpose |
|---|---|
| `main.tf` | Orchestrates modules and resources; the top-level composition |
| `variables.tf` | Declares all input variables with types and descriptions |
| `output.tf` / `outputs.tf` | Exposes key values (ARNs, role names, bucket names) that operators need when configuring the Helm chart |
| `provider.tf` / `providers.tf` | Configures the Terraform provider and remote backend |
| `README.md` | Step-by-step guide: prerequisites, credential setup, backend config, variables, `terraform plan/apply`, and then what to do next (Helm install) |
| `terraform.tfvars-example` | Example variable values the operator copies and fills in |
| `backend.tfvars-example` | Example remote-state backend config |
| `modules/` (optional) | Reusable sub-modules for IAM, storage, networking, etc. |

The existing `primary-site/` examples follow this pattern exactly. Each one provisions storage buckets (inbox + lake), event notifications (SNS / Pub/Sub / EventGrid), a VPC, a Kubernetes cluster (EKS / GKE / AKS), and IAM roles for three service accounts (inbox-listener, query-service, garbage-collector).

---

## What is the Remote Data Loader?

The Remote Data Loader is a Foxglove service deployed via the [`remote-data-loader` Helm chart](https://github.com/foxglove/helm-charts/tree/main/charts/remote-data-loader). It runs inside a Kubernetes cluster and serves recorded data (from cloud storage) to Foxglove clients for visualization. It is separate from the Primary Site services.

Key characteristics from the Helm chart's `values.yaml`:

- **`globals.manifestEndpoint`** (required) — the Foxglove API endpoint the loader calls to retrieve manifests.
- **Cloud storage access** — the loader reads from the data lake bucket. On AWS it uses an IAM role for service accounts (IRSA); on GCP a `gcp-cloud-credential` secret; on Azure the `cloud-credentials` secret with `AZURE_*` vars.
- **Optional cache bucket** (`globals.cache`) — an S3-compatible / AWS / GCP / Azure bucket used to cache and speed up queries.
- **Ingress** — the loader exposes an HTTP endpoint on port 8080 that Foxglove clients connect to.
- **Service account** — on AWS, annotated with `eks.amazonaws.com/role-arn` to assume an IAM role.
- **Autoscaling** — HPA based on CPU utilization.

---

## What infrastructure does the Remote Data Loader need?

Compared to the primary-site examples, the remote-data-loader needs **less** infrastructure. It does **not** need inbox buckets or event notification topics (those belong to the primary site). It needs:

| Resource | Why |
|---|---|
| **Kubernetes cluster** | The loader runs as a Deployment |
| **IAM role / permissions** | Read access to the lake bucket (and optionally cache bucket) |
| **Cache bucket** (optional) | Speeds up repeated queries |
| **Ingress / Load Balancer** | Exposes the loader to Foxglove clients |

### Design decision: standalone vs. add-on

There are two possible approaches:

1. **Standalone** — each example provisions everything from scratch (VPC, cluster, IAM, cache bucket). This mirrors how the primary-site examples work and is self-contained.

2. **Add-on** — assumes the Kubernetes cluster (and possibly the lake bucket) already exist (e.g., created by the primary-site Terraform). The example only provisions the IAM role and optional cache bucket.

**Recommendation:** Use a hybrid approach. The remote-data-loader is typically deployed into an **existing** cluster that already has a primary site. The example should:
- Accept the existing cluster and lake bucket as input variables (ARNs, names, OIDC provider, etc.)
- Provision only what's new: the remote-data-loader IAM role, the optional cache bucket, and output the values needed for the Helm chart.
- Optionally include a "full stack" variant or document how to combine with the primary-site example.

This keeps the example focused and avoids duplicating the cluster/VPC/storage setup.

---

## Proposed directory structure

```
remote-data-loader/
├── PLAN.md              ← this file
├── aws/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── README.md
│   ├── terraform.tfvars-example
│   ├── backend.tfvars-example
│   └── modules/
│       ├── iam/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── s3-cache/
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── gcp/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── README.md
│   ├── terraform.tfvars-example
│   ├── backend.tfvars-example
│   └── modules/
│       ├── iam/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── storage-cache/
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
└── azure/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── providers.tf
    ├── README.md
    ├── terraform.tfvars-example
    ├── backend.tfvars-example
    └── modules/
        ├── iam/
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        └── storage-cache/
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
```

---

## Per-cloud breakdown

### AWS

**Input variables:**
- `aws_region` — AWS region
- `eks_cluster_name` — name of the existing EKS cluster (to look up the OIDC provider)
- `eks_oidc_provider_arn` — ARN of the EKS cluster's OIDC provider (for IRSA)
- `lake_bucket_arn` — ARN of the existing lake S3 bucket (the loader reads from it)
- `eks_foxglove_namespace` — Kubernetes namespace where the Helm chart will be deployed (default: `foxglove`)
- `enable_cache` — whether to create a cache bucket
- `cache_bucket_name` — name for the cache S3 bucket

**Resources created:**
- **IAM module:**
  - IAM policy granting `s3:GetObject`, `s3:GetObjectVersion`, `s3:GetBucketLocation`, `s3:ListBucket` on the lake bucket
  - If cache is enabled: same permissions plus `s3:PutObject` on the cache bucket
  - IAM role for EKS service accounts (IRSA), bound to `<namespace>:remote-data-loader`
  - Policy attachment
- **S3 cache module** (conditional on `enable_cache`):
  - Private S3 bucket for caching

**Outputs:**
- `iam_remote_data_loader_role_arn` — the ARN to put in the Helm chart's `remoteDataLoader.deployment.serviceAccount.annotations["eks.amazonaws.com/role-arn"]`
- `cache_bucket_name` (if enabled)

### GCP

**Input variables:**
- `gcp_project`, `gcp_region`
- `lake_bucket_name` — existing lake bucket
- `iam_service_account_name` — name for the new service account
- `enable_cache`, `cache_bucket_name`

**Resources created:**
- **IAM module:**
  - GCP service account with `roles/storage.objectViewer` on the lake bucket
  - If cache is enabled: `roles/storage.objectAdmin` on the cache bucket
  - JSON key for the service account (stored in tfstate as sensitive output)
- **Storage cache module** (conditional):
  - GCS bucket for caching

**Outputs:**
- `iam_service_account_key` (sensitive) — base64-encoded JSON key for the `gcp-cloud-credential` Kubernetes secret
- `cache_bucket_name` (if enabled)

### Azure

**Input variables:**
- `resource_group_name`, `resource_location`
- `storage_account_name` — existing storage account
- `lake_storage_container_name` — existing lake container
- `application_display_name` — name for the AD app registration
- `enable_cache`, `cache_container_name`

**Resources created:**
- **IAM module:**
  - Azure AD application + service principal
  - Role assignment: `Storage Blob Data Reader` on the lake container
  - If cache is enabled: `Storage Blob Data Contributor` on the cache container
- **Storage cache module** (conditional):
  - Storage container for caching within the existing storage account

**Outputs:**
- `azure_tenant_id`, `azure_client_id`, `azure_client_secret` (sensitive) — for the `cloud-credentials` Kubernetes secret
- `cache_container_name` (if enabled)

---

## README content outline (per cloud provider)

Each README should cover:

1. **Overview** — what this example does and how it relates to the primary-site example
2. **Prerequisites** — existing cluster, lake bucket, Foxglove account with a manifest endpoint
3. **Getting started**
   - Configure cloud credentials for Terraform
   - Set up remote state backend
   - Fill in `terraform.tfvars`
   - Run `terraform init`, `plan`, `apply`
4. **Modules** — description of each module
5. **Next steps** — how to use the Terraform outputs to configure the Helm chart values and run `helm install`
6. **Production considerations** — security hardening, caching, autoscaling notes

---

## Open questions

1. **Standalone vs. add-on:** The plan above assumes the remote-data-loader is deployed into an existing cluster created by the primary-site Terraform. Should we also include a fully standalone variant that creates its own cluster? This would be useful for users who deploy the remote-data-loader in a separate cluster or region.

2. **Cache bucket:** The Helm chart supports `s3_compatible`, `aws`, `azure`, and `google_cloud` as cache storage providers. Should the examples enable caching by default, or leave it opt-in?

3. **Ingress:** The primary-site AWS example mentions the AWS Load Balancer Controller but doesn't provision it. Should the remote-data-loader example provision any ingress infrastructure, or just document the requirement?

4. **Which cloud providers to start with?** Should we implement all three (AWS, GCP, Azure) simultaneously, or start with one and iterate?

5. **Relationship to primary-site outputs:** Should the remote-data-loader examples consume outputs from the primary-site examples directly (e.g., via `terraform_remote_state` data source), or keep them decoupled with manual variable input?
