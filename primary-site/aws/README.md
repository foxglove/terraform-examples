# Primary Site AWS Terraform Example Templates

Use these templates to create resources for a Foxglove Primary Site.

## Overview

Once the resources are created, you'll be able to deploy the Helm charts into the created
EKS cluster, and use the included S3 buckets for inbox and lake.

The template's IAM user is created with programmatic access, which can be used in the
Kubernetes cluster's `cloud-credentials` secret, allowing the services to connect to the inbox
and lake buckets.

## Getting started

### Create resources for the Terraform provider

Terraform needs an administrator user's account ID and account secret for its AWS provider. To
create IAM credentials manually, navigate to [IAM](https://us-east-1.console.aws.amazon.com/iamv2/home)

Add a new user:

- Select `Access key - Programmatic access`
- Attach the `AdministratorAccess` policy directly
- Record the credentials or download them in a CSV

It's also best practice on aws to store the Terraform state on S3. This will be used to store
the `tfstate` in the cloud, rather than keeping them locally. Create an S3 bucket, and make
sure to block all public access (the tfstate will contain secrets).

### Use these credentials

Terraform can use these crendetials from env variables, or using the cli's configuration.
One simple option is to use [aws-cli](https://aws.amazon.com/cli/) and run `aws configure`
Read more: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

The provider in this Terraform package will pick up the default credentials.

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

- `iam`: creates an IAM user with programmatic access. The credentials will be in `tfstate` as
  as sensitive output values. Use these for the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
  environment variables in the `cloud-credentials` secret, as described in the
  [Configure Cloud Credentials](https://foxglove.dev/docs/data-platform/primary-sites/configure-cloud-credentials)
  section.
  This user has access to read/write both the `inbox` and `lake` S3 buckets.

- `s3`: creates an S3 bucket with private access. This module is used to create the `inbox` and
  `lake` buckets.

- `sns`: creates an SNS topic with a https subscription, and attaches it to an S3 bucket's
  `s3:ObjectCreated:*` events. Whenever a new object appears in the bucket, the webhook
  `inbox_notification_endpoint` will be notified.

## Production use

This Terraform example creates all resources that are needed for a working Foxglove Primary
Site deployment: the VPC, EKS cluster, IAM user, S3 buckets and the SNS topic. For production
use, consider the following:

### Connecting to the cluster

By default, only the creator Terraform user will be able to connect to this EKS cluster.
Read the AWS docs about [adding other IAM users and roles](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html),
or set `manage_aws_auth_configmap = true` in the eks module (will require setting up the
"kubernetes" provider).

### AWS Load Balancer Controller

To provisions an AWS Application Load Balancer (ALB) when a Kubernetes Ingress is created,
the AWS Load Balancer Controller needs to be installed in the cluster. Follow the
[AWS user guide](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
to set up this add-on.

### CoreDns on Fargate

In the example, the EKS module is set up with both a managed node and Fargate profiles.
The Fargate profile assume that the Foxglove resources will be deployed in the `foxglove`
namespace, and therefore run on Fargate.

One corner case around nodes in EKS is that if the managed node is removed from the template,
the default CoreDns service will need to be patched; see [this guide](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/deploy-coredns-on-amazon-eks-with-fargate-automatically-using-terraform-and-python.html) for details.

### Logging on Fargate

Sending logs to CloudWatch from Fargate payloads requires setting up FluentBit as per
[this guide](https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html).
