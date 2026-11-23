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

- `cloudfront`: creates a CloudFront distribution in front of the site's ALB. Only created when
  `enable_cloudfront` is `true`.

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

To provisions an AWS Application Load Balancer (ALB) when a Kubernetes Ingress is created,
the AWS Load Balancer Controller needs to be installed in the cluster. Follow the
[AWS user guide](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
to set up this add-on.

### CloudFront

The ALB holds each client's TCP connection, and AWS doesn't let you change its congestion control.
`enable_cloudfront` puts a CloudFront distribution in front of the ALB that the primary site Helm
chart's Ingress creates, which speeds up streaming to clients far from your AWS region. Clients
connect to a nearby CloudFront edge location, and traffic reaches the ALB over the AWS network.
CloudFront uses [BBR](https://github.com/google/bbr) congestion control for connections to
clients, which keeps throughput high on high-latency links. The ALB, its certificate and the Helm
chart stay the same. CloudFront is off by default.

The distribution has caching off and forwards every header, cookie and query string. CloudFront
waits at most 120 seconds for the first byte of a response and between packets, so slower queries
fail.

1. Deploy the primary site Helm chart with an ALB Ingress that has a fixed name, and check that
   the site works. CloudFront needs an internet-facing ALB with an HTTPS listener on port 443:

   ```yaml
   ingress:
     className: alb
     host: foxglove-site.example.com
     annotations:
       alb.ingress.kubernetes.io/load-balancer-name: foxglove-primary-site
       alb.ingress.kubernetes.io/scheme: internet-facing
       alb.ingress.kubernetes.io/target-type: ip
       alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
       alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:XXXXXXXXXXXX:certificate/EXAMPLE
   ```

   The [AWS Load Balancer Controller](#aws-load-balancer-controller) creates the ALB from these
   annotations. Adding `load-balancer-name` to an existing Ingress replaces its ALB, and the new
   ALB has a different DNS name.
2. In `terraform.tfvars`, set `enable_cloudfront = true` and `site_load_balancer_name` to the same
   name. Also set `site_hostname` to the Ingress host, and `cloudfront_certificate_arn` to an ACM
   certificate in us-east-1 that covers that host. If your site is in us-east-1, the ALB's
   certificate works.
3. Run `terraform apply`.
4. Point your site's DNS record at the `cloudfront_domain_name` output.

If the Ingress is recreated, run `terraform apply` again so CloudFront picks up the new ALB. Turn
CloudFront off before removing the Ingress. Otherwise every plan fails, because Terraform can't
find the ALB.

### CoreDns on Fargate

In the example, the EKS module is set up with both a managed node and Fargate profiles.
The Fargate profile assume that the Foxglove resources will be deployed in the `foxglove`
namespace, and therefore run on Fargate.

One corner case around nodes in EKS is that if the managed node is removed from the template,
the default CoreDns service will need to be patched; see [this guide](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/deploy-coredns-on-amazon-eks-with-fargate-automatically-using-terraform-and-python.html) for details.

### Logging on Fargate

Sending logs to CloudWatch from Fargate payloads requires setting up FluentBit as per
[this guide](https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html).
