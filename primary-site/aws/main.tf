## ----- S3 buckets -----

module "s3_lake" {
  source      = "./modules/s3"
  bucket_name = var.lake_bucket_name

  abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days
}

module "s3_inbox" {
  source      = "./modules/s3"
  bucket_name = var.inbox_bucket_name

  abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days
}

## ----- Pubsub -----

module "inbox_sns_notification" {
  source     = "./modules/sns"
  bucket_arn = module.s3_inbox.bucket_arn
  bucket_id  = module.s3_inbox.bucket_id
  topic_name = "${var.inbox_bucket_name}-sns-topic"

  inbox_notification_endpoint = var.inbox_notification_endpoint
}

# ----- VPC -----

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = var.vpc_name

  # EKS VPC and subnet requirements and considerations
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  cidr            = "10.0.0.0/16"
  azs = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # Fargate requirements:
  # https://docs.aws.amazon.com/eks/latest/userguide/eks-ug.pdf#page=135&zoom=100,96,764
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_vpn_gateway   = false

  # NOTE tagging for automatic subnet discovery by load balancers or ingress controllers
  # https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = 1
  }
}

## ----- EKS cluster & instance security groups -----

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name                    = var.eks_cluster_name
  cluster_version                 = var.eks_cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enable the default KMS key policy, otherwise the only role that can access
  # the key is the role that created it
  kms_key_enable_default_policy = true

  # Fargate profiles use the cluster primary security group, so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false

  eks_managed_node_group_defaults = {
    ami_type                              = "AL2_x86_64"
    attach_cluster_primary_security_group = true
    create_security_group                 = false
  }

  eks_managed_node_groups = {
    default = {
      name         = "default-node-group"
      min_size     = 0
      max_size     = 2
      desired_size = 1

      instance_types = ["t3.small"]
    }
  }

  fargate_profiles = {
    # This Fargate profile assumes that the Foxglove resources will be deployed in
    # the `foxglove` namespace. All workloads in this namespace will be run by the
    # Fargate scheduler.
    foxglove = {
      create_iam_role = true
      name            = "foxglove"
      selectors       = [{ namespace = "foxglove" }]
    }
  }
}

## ----- IAM policy & roles -----

module "iam" {
  source                 = "./modules/iam"
  lake_bucket_arn        = module.s3_lake.bucket_arn
  inbox_bucket_arn       = module.s3_inbox.bucket_arn
  eks_oidc_provider_arn  = module.eks.oidc_provider_arn
  eks_foxglove_namespace = "foxglove"
}

## ----- Kubernetes Resources -----

# Create the foxglove namespace
resource "kubernetes_namespace" "foxglove" {
  metadata {
    name = "foxglove"
  }
}

# Create the Foxglove site token secret
resource "kubernetes_secret" "foxglove_site_token" {
  metadata {
    name      = "foxglove-site-token"
    namespace = kubernetes_namespace.foxglove.metadata[0].name
  }

  data = {
    FOXGLOVE_SITE_TOKEN = var.foxglove_site_token
  }
}

# Service Accounts for each Service 
resource "kubernetes_service_account" "inbox_listener" {
  metadata {
    name      = "inbox-listener"
    namespace = kubernetes_namespace.foxglove.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam.iam_inbox_listener_role_arn
    }
  }
}

resource "kubernetes_service_account" "stream_service" {
  metadata {
    name      = "stream-service"
    namespace = kubernetes_namespace.foxglove.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam.iam_stream_service_role_arn
    }
  }
}

resource "kubernetes_service_account" "garbage_collector" {
  metadata {
    name      = "garbage-collector"
    namespace = kubernetes_namespace.foxglove.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam.iam_garbage_collector_role_arn
    }
  }
}

## ----- Helm Releases -----

# Deploy the Foxglove primary-site application
resource "helm_release" "foxglove_primary_site" {
  name       = "foxglove-primary-site"
  repository = "https://helm-charts.foxglove.dev"
  chart      = "primary-site"
  namespace  = kubernetes_namespace.foxglove.metadata[0].name
  version    = var.foxglove_chart_version

  # Use the values.yaml file with template variables
  values = [
    templatefile("${path.module}/values.yaml", {
      cluster_name    = var.eks_cluster_name
      region          = var.aws_region
      vpc_id          = module.vpc.vpc_id
      certificate_arn = var.certificate_arn
      lake_bucket     = var.lake_bucket_name
      inbox_bucket    = var.inbox_bucket_name
      inbox_listener_role_arn   = module.iam.iam_inbox_listener_role_arn
      stream_service_role_arn   = module.iam.iam_stream_service_role_arn
      garbage_collector_role_arn = module.iam.iam_garbage_collector_role_arn
    })
  ]

  depends_on = [
    kubernetes_secret.foxglove_site_token,
    kubernetes_service_account.inbox_listener,
    kubernetes_service_account.stream_service,
    kubernetes_service_account.garbage_collector,
    helm_release.aws_load_balancer_controller
  ]
}

# Deploy the AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = kubernetes_namespace.foxglove.metadata[0].name
  version    = "1.13.0"

  set {
    name  = "clusterName"
    value = var.eks_cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [
    module.iam
  ]
}