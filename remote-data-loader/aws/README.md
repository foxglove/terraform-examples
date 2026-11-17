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

The example grants cluster admin to the IAM user or role that runs Terraform, through an EKS
access entry (`enable_cluster_creator_admin_permissions = true`). If a different IAM user or
role runs `terraform apply` later, the access entry moves to that principal and the previous
one loses access. To give other principals access, use the eks module's `access_entries` input,
or read the AWS docs about [granting IAM users and roles access to
Kubernetes](https://docs.aws.amazon.com/eks/latest/userguide/grant-k8s-access.html).

### EKS upgrade policy

The example sets the cluster upgrade policy to `STANDARD` and does not pin a Kubernetes
minor version. New clusters use the EKS default version at creation time, which is not always
the latest version (`aws eks describe-cluster-versions --default-only` shows it). When that
version reaches the end of standard support, EKS automatically upgrades the control plane to
the next version instead of moving the cluster into paid
[extended support](https://docs.aws.amazon.com/eks/latest/userguide/view-upgrade-policy.html).

EKS does not upgrade the nodes, add-ons, or running Fargate pods. After an automatic upgrade:

1. Run `terraform apply` to upgrade the managed node group and the `kube-proxy` and `vpc-cni`
   add-ons.
2. Update the [self-managed CoreDNS add-on](https://docs.aws.amazon.com/eks/latest/userguide/coredns-add-on-self-managed-update.html).
3. Restart the deployments in the Remote Data Loader namespace so that their Fargate pods use
   the new version: `kubectl rollout restart deployment -n <namespace>`.

### Upgrading an existing deployment

Earlier versions of this example pinned Kubernetes 1.31 and used Amazon Linux 2 nodes. Before
you apply this version to an existing deployment, review the `terraform plan` output.

- The managed node group is replaced, because its AMI type changes to Amazon Linux 2023.
- EKS accepts the `STANDARD` upgrade policy only while the cluster runs a Kubernetes version
  in [standard support](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html).
  Kubernetes 1.31 is in extended support. If your cluster is in extended support, remove
  `cluster_upgrade_policy` from `main.tf` and apply. Then upgrade the cluster one minor version
  at a time until it is in standard support, run `terraform apply` after each upgrade, and add
  `cluster_upgrade_policy` back.
- Remove `eks_cluster_version` from `terraform.tfvars`. The variable no longer exists.

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
