## AWS provider

### Create credentials

1.1. Terraform needs an administrator user's account ID & secret for an AWS provider. To create
IAM credentials manually, navigate to IAM:
https://us-east-1.console.aws.amazon.com/iamv2/home

And add a new user:
* Select `Access key - Programmatic access`
* Attach the `AdministratorAccess` policy directly
* Record the credentials or download them in a CSV

1.2. It's also best practice on aws to store the Terraform state on S3. This will be used to store
the tfstate rather than keeping them locally. Any S3 bucket will do:
* Block all public access; tfstate often contains secrets
* Region to match IAM user's (not a must, but makes life easier)

### Use these settings

Terraform can use these crendetials from env variables, or using the cli's configuration.
One simple option is to use [aws-cli](https://aws.amazon.com/cli/) and run `aws configure`
Read more: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

The provider in this package will pick up the default credentials automagically.

1. Copy `terraform.tfvars-example` to `terraform.tfvars`
2. Change the "changeme" text to your own username
3. Copy `backend.tfvars-example` to `backend.tfvars`
4. Set the bucket name and region to what was created above; key can be any object key.
5. Run `terraform init --backend-config backend.tfvars`

You should now be able to run `terraform plan` and `terraform apply`.


### AWS Load Balancer Controller

The [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
manages AWS Elastic Load Balancers for a Kubernetes cluster. The controller provisions an
AWS Application Load Balancer (ALB) when a Kubernetes Ingress is created. 

### A note on Fargate

There is a managed node in the EKS example, and only foxglove resources (in the `foxglove`
namespace) will run on Fargate (see the Fargate profile in the example). If the managed node
is removed from the example, the default CoreDns will need to be updated; see [this guide](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/deploy-coredns-on-amazon-eks-with-fargate-automatically-using-terraform-and-python.html).

Similarly, logging from the Fargate payloads requires setting up FluentBit as per [this guide](https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html).
