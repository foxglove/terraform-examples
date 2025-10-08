# Primary Site AWS Terraform Example Templates

Use these templates to create resources for a Foxglove Primary Site.

## Overview

Once the resources are created, you'll be able to deploy the Helm charts into the created
EKS cluster, and use the included S3 buckets for inbox and lake.

The Helm chart's service accounts need to be configured to use the IAM roles created by
this template, allowing the services to connect to the inbox and lake buckets.

## Prerequisites 

* a custom domain with an HTTPS certificate 
* create new inbox notification endpoint in Foxglove settings
* create new site token in Foxglove settings

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

### Test to see that everything worked

```bash
# configure kubectl to connect to your cluster
aws eks update-kubeconfig --region <your-region> --name <your-cluster-name>

# check ingress, should see a a domain that looks like this
kubectl describe ingress site -n foxglove

# find pods 
kubectl get pods

# view logs 
kubectl logs $POD -f

# restart things 
kubectl rollout restart deployment -n foxglove
kubectl rollout restart deployment aws-load-balancer-controller -n foxglove
```

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
Site deployment: the VPC, EKS cluster, IAM roles, S3 buckets, the SNS topic and the AWS Load Balancer Controller add-on. For production
use, consider the following:

### Connecting to the cluster

By default, only the creator Terraform user will be able to connect to this EKS cluster.
Read the AWS docs about [adding other IAM users and roles](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html),
or set `manage_aws_auth_configmap = true` in the eks module (will require setting up the
"kubernetes" provider).

### CoreDns on Fargate

In the example, the EKS module is set up with both a managed node and Fargate profiles.
The Fargate profile assume that the Foxglove resources will be deployed in the `foxglove`
namespace, and therefore run on Fargate.

One corner case around nodes in EKS is that if the managed node is removed from the template,
the default CoreDns service will need to be patched; see [this guide](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/deploy-coredns-on-amazon-eks-with-fargate-automatically-using-terraform-and-python.html) for details.

### Logging on Fargate

Sending logs to CloudWatch from Fargate payloads requires setting up FluentBit as per
[this guide](https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html).
