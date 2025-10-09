# Primary Site AWS Terraform Example Templates

Use these templates to create resources for a Foxglove Primary Site.

## Overview

Once the resources are created, you'll be able to deploy the Helm charts into the created
EKS cluster, and use the included S3 buckets for inbox and lake.

The Helm chart's service accounts need to be configured to use the IAM roles created by
this template, allowing the services to connect to the inbox and lake buckets.

## Prerequisites 

* a custom domain with an HTTPS certificate, certificate ARN from ACM console
* inbox notification endpoint in Foxglove settings
* site token in Foxglove settings

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

# Name:             site
# Labels:           app.kubernetes.io/managed-by=Helm
# Namespace:        foxglove
# Address:          k8s-foxglove-site-d243fa5f2c-1094290762.us-west-1.elb.amazonaws.com
# Ingress Class:    alb
# Default backend:  <default>

# find pods 
kubectl get pods -n foxglove

# view logs 
kubectl -n foxglove logs $POD -f

# restart things if changes needed
kubectl rollout restart deployment -n foxglove
```

### Configure Domain 

Create a CNAME record on the domain you want to use to access your primary site and update it to your ingress address. In the example above the CNAME value would be `k8s-foxglove-site-d243fa5f2c-1094290762.us-west-1.elb.amazonaws.com`.

### Test File 

You can watch the inbox listener logs to make sure files are being processed properly. 

```bash

# find all pods
kubectl get pods -n foxglove       

NAME                                           READY   STATUS             RESTARTS      AGE
aws-load-balancer-controller-ff4b8954f-2x5pg   1/1     Running            0             11m
aws-load-balancer-controller-ff4b8954f-62fkx   1/1     Running            0             12m
garbage-collector-29332770-xqzvx               0/1     CrashLoopBackOff   5 (25s ago)   5m40s
inbox-listener-668889fcb9-9lvbp                1/1     Running            0             19m
query-service-5ff9b5b8dc-c4lxc                 1/1     Running            0             19m
site-controller-fcb86f966-2v67l                1/1     Running            0             19

# watch inbox listener
kubectl -n foxglove logs inbox-listener-668889fcb9-9lvbp -f 
```

Once its running, upload a file to the inbox bucket in S3. You should see the file being processed and it should now show up in the recordings section in the Foxglove app.

```
{"timestamp":"2025-10-09T00:18:20.949464617Z","severity":"INFO","message":"Running in single-tenant mode for aws"}
{"timestamp":"2025-10-09T00:18:20.949952133Z","severity":"INFO","message":"starting metrics server on 0.0.0.0:6001"}
{"timestamp":"2025-10-09T00:18:20.950066913Z","severity":"INFO","message":"starting liveness server on 0.0.0.0:6002"}
{"timestamp":"2025-10-09T00:19:11.674249175Z","severity":"INFO","message":"Received notification","filename":"rosbag2_2025_10_08-23_48_06_0.mcap","org_id":"org_0dt1PzqrMVLYScLC","request_id":"b563d329d4f5a8e8c9e452ec752840b593ea1b05"}
{"timestamp":"2025-10-09T00:19:11.674388847Z","severity":"INFO","message":"Using WebIdentity credential provider","attempt_id":"ade3ea09-6413-4f48-a211-6e3701f23950","filename":"rosbag2_2025_10_08-23_48_06_0.mcap","org_id":"org_0dt1PzqrMVLYScLC","request_id":"b563d329d4f5a8e8c9e452ec752840b593ea1b05"}
{"timestamp":"2025-10-09T00:19:11.894253238Z","severity":"INFO","message":"transcoding mcap file to levlaz-aws-lake-bucket/tmp/20251009/ade3ea09-6413-4f48-a211-6e3701f23950","attempt_id":"ade3ea09-6413-4f48-a211-6e3701f23950","inbox_bucket":"levlaz-aws-inbox-bucket","lake_bucket":"levlaz-aws-lake-bucket","output_prefix":"tmp/20251009/ade3ea09-6413-4f48-a211-6e3701f23950","user_filename":"rosbag2_2025_10_08-23_48_06_0.mcap","filename":"rosbag2_2025_10_08-23_48_06_0.mcap","org_id":"org_0dt1PzqrMVLYScLC","request_id":"b563d329d4f5a8e8c9e452ec752840b593ea1b05"}
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
