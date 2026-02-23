# Remote Data Loader AWS Terraform Example Templates

Use these templates to create resources for a Foxglove Remote Data Loader.

## Overview

Once the resources are created, you'll be able to deploy the Remote Data Loader Helm charts
into the created EKS cluster, using the cache S3 bucket for temporary storage.

The Helm chart's service accounts need to be configured to use the IAM roles created by
this template, allowing the services to connect to the cache bucket.

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

Before running Terraform for the first time, configure your local variables:

1. Copy `terraform.tfvars-example` to `terraform.tfvars`
2. Change the variables as needed
3. Copy `backend.tfvars-example` to `backend.tfvars`
4. Set the bucket name and region to what was created in the "Getting started" step; key can
   be any object key.
5. Run `terraform init --backend-config backend.tfvars`

You should now be able to run `terraform plan` and `terraform apply`.

## Modules

- `iam`: creates the IAM role to be used by the service accounts. Make sure to configure
  the namespace correctly for the EKS OIDC provider, otherwise the workloads won't be able
  to use the role to connect to the cache S3 bucket.

- `s3`: creates an S3 bucket with private access and automatic object expiration.
  The lifecycle rules ensure cached objects are automatically deleted after the configured
  number of days, and incomplete multipart uploads are aborted.

## Production use

This Terraform example creates all resources needed for a working Foxglove Remote Data
Loader deployment: the VPC, EKS cluster, IAM role, and cache S3 bucket. For production
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
The Fargate profile assumes that the Remote Data Loader resources will be deployed in the
configured namespace, and therefore run on Fargate.

One corner case around nodes in EKS is that if the managed node is removed from the template,
the default CoreDns service will need to be patched; see [this guide](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/deploy-coredns-on-amazon-eks-with-fargate-automatically-using-terraform-and-python.html) for details.

### Logging on Fargate

Sending logs to CloudWatch from Fargate payloads requires setting up FluentBit as per
[this guide](https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html).
