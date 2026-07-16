# Primary Site AWS Terraform Example Templates (index-in-place)

Use these templates to create resources for a Foxglove Primary Site using the
**index-in-place** storage mode.

## Overview

In index-in-place mode the site reads recordings directly from existing S3 bucket(s)
that you own, rather than an inbox and lake bucket. Foxglove indexes each file where it
sits and never modifies your objects; you manage the recording lifecycle yourself.

Once the resources are created, you'll be able to deploy the Helm charts into the created
EKS cluster, pointed at your bucket(s). The Helm chart's `indexer` and `query-service`
service accounts need to be configured to use the IAM roles created by this template.

## Getting started

### Configure the AWS Terraform provider

Terraform [can derive credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
from several sources. Choose the method that's in line with your organization's policies, and ensure
Terraform has sufficient access to modify your infrastructure.

You must configure the provider with the proper credentials before you can use it. For a quick start
with these examples, you can create a new IAM user with programmatic access on the AWS Console, and
then use the `aws configure` command in [aws-cli](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
to get started:

- On the AWS Console navigate to [IAM](https://us-east-1.console.aws.amazon.com/iamv2/home)
- Select `Access key - Programmatic access`
- Attach an appropriate policy as determined by your organization
- Record the credentials (or download them in a CSV) to be used in `aws-cli`

It's also best practice for the AWS provider to store the Terraform state on S3. This will be used
to store the `tfstate` in the cloud, rather than keeping them locally. Create an S3 bucket, and make
sure to **block all public access** (the tfstate will contain secrets).

The application does not require the use of AWS account root privileges for deployment or operation. Do not use the AWS account root user for deployment or operations.

### Run Terraform

Before running Terraform for the first time, configure your local variables. Note that some
of them you'll find on the Foxglove [Settings page](https://app.foxglove.dev/~/settings/sites),
under the Sites tab. Create the Primary Site (with index-in-place selected) before applying, so the
bucket notification endpoint exists and its subscription can confirm.

1. Copy `terraform.tfvars-example` to `terraform.tfvars`
2. Set `indexed_bucket_names` to the bucket(s) to index. Set `create_indexed_buckets = true` only
   if you want Terraform to create them.
3. Use the `bucket_notification_endpoint` variable from the Foxglove site settings.
4. Change the other variables as needed
5. Copy `backend.tfvars-example` to `backend.tfvars`
6. Set the bucket name and region to what was created in the "Getting started" step; key can
   be any object key.
7. Run `terraform init --backend-config backend.tfvars`

You should now be able to run `terraform plan` and `terraform apply`.

When deploying the Helm charts, set the index-in-place storage mode and annotate the `indexer` and
`query-service` service accounts with the `iam_indexer_role_arn` and `iam_query_service_role_arn`
outputs. See [`helm-values-index-in-place.yaml-example`](./helm-values-index-in-place.yaml-example).

## Modules

- `iam`: creates the IAM roles to be used by the service accounts. Index-in-place runs the
  `indexer` and `query-service`, both with read-only access to the indexed bucket(s).

- `s3`: creates an S3 bucket with private access. Only used when `create_indexed_buckets = true`;
  otherwise the bucket(s) are expected to already exist.

- `sns`: creates an SNS topic with a https subscription, and attaches it to an S3 bucket's
  `s3:ObjectCreated:*` events. Whenever a new object appears in the bucket, the webhook
  `bucket_notification_endpoint` will be notified. Note that this manages the bucket's entire
  notification configuration, so only one owner may configure notifications on that bucket.

## Production use

This Terraform example creates all resources that are needed for a working Foxglove Primary
Site deployment: the VPC, EKS cluster, IAM roles, S3 buckets and the SNS topic. For production
use, consider the following:

### Connecting to the cluster

By default, only the creator Terraform user will be able to connect to this EKS cluster.
Read the AWS docs about [adding other IAM users and roles](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html),
or set `manage_aws_auth_configmap = true` in the eks module (will require setting up the
"kubernetes" provider).

### AWS Load Balancer Controller

To provision an AWS Application Load Balancer (ALB) when a Kubernetes Ingress is created,
the AWS Load Balancer Controller needs to be installed in the cluster. Follow the
[AWS user guide](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
to set up this add-on.

### CoreDns on Fargate

In the example, the EKS module is set up with both a managed node and Fargate profiles.
The Fargate profile assumes that the Foxglove resources will be deployed in the `foxglove`
namespace, and therefore run on Fargate.

One corner case around nodes in EKS is that if the managed node is removed from the template,
the default CoreDns service will need to be patched; see [this guide](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/deploy-coredns-on-amazon-eks-with-fargate-automatically-using-terraform-and-python.html) for details.

### Logging on Fargate

Sending logs to CloudWatch from Fargate payloads requires setting up FluentBit as per
[this guide](https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html).

### Kubernetes version

`eks_cluster_version` defaults to a current standard-support version, and the node group uses
AL2023 AMIs (required for Kubernetes 1.33+). Check available versions with
`aws eks describe-cluster-versions`.
