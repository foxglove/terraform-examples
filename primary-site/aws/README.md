# Primary Site AWS Terraform Example Templates

Use these templates to create resources for a Foxglove Primary Site.

## Overview

Once the resources are created, you'll be able to deploy the Helm charts into the created
EKS cluster, and use the included S3 buckets for inbox and lake.

The Helm chart's service accounts need to be configured to use the IAM roles created by
this template, allowing the services to connect to the inbox and lake buckets.

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
under the Sites tab.

1. Copy `terraform.tfvars-example` to `terraform.tfvars`
2. Use the `inbox_notification_endpoint` variable from the Foxglove site settings.
3. Change the other variables as needed
4. Copy `backend.tfvars-example` to `backend.tfvars`
5. Set the bucket name and region to what was created in the "Getting started" step; key can
   be any object key.
6. Run `terraform init --backend-config backend.tfvars`

You should now be able to run `terraform plan` and `terraform apply`.

## Modules

- `iam`: creates the IAM roles to be used by the service accounts. Make sure to configure
  the namespace correctly for the eks oidc provider, otherwise the workloads won't be able
  to use the roles to connect to the `lake` and `inbox` S3 buckets.

- `s3`: creates an S3 bucket with private access. This module is used to create the `inbox` and
  `lake` buckets.

- `sns`: creates an SNS topic with a https subscription, and attaches it to an S3 bucket's
  `s3:ObjectCreated:*` events. Whenever a new object appears in the bucket, the webhook
  `inbox_notification_endpoint` will be notified.

## Production use

This Terraform example creates all resources that are needed for a working Foxglove Primary
Site deployment: the VPC, EKS cluster, IAM roles, S3 buckets and the SNS topic. For production
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
3. Restart the deployments in the `foxglove` namespace so that their Fargate pods use the new
   version: `kubectl rollout restart deployment -n foxglove`.

### Upgrading an existing deployment

Earlier versions of this example used v19 of the EKS module. Before you apply this version to
an existing deployment, read the module's
[v20 upgrade guide](https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v20.37.2/docs/UPGRADE-20.0.md),
run `terraform init -upgrade --backend-config backend.tfvars`, and review the `terraform plan`
output. Do not apply if the plan replaces `module.eks.aws_eks_cluster.this[0]`.

- The cluster authentication mode changes from `CONFIG_MAP` to `API_AND_CONFIG_MAP`. You
  can't revert this change. Existing `aws-auth` ConfigMap entries keep working.
- The managed node group is replaced, because its AMI type changes to Amazon Linux 2023.
- EKS accepts the `STANDARD` upgrade policy only while the cluster runs a Kubernetes version
  in [standard support](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html).
  If your cluster is in extended support, remove `cluster_upgrade_policy` from `main.tf` and
  apply. Then upgrade the cluster one minor version at a time until it is in standard support,
  run `terraform apply` after each upgrade, and add `cluster_upgrade_policy` back.
- If the apply fails because an access entry already exists for your IAM identity, delete the
  entry that EKS created for the cluster creator, then apply again:
  `aws eks delete-access-entry --cluster-name <cluster-name> --principal-arn <principal-arn>`
- Remove `eks_cluster_version` from `terraform.tfvars`. The variable no longer exists.

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
