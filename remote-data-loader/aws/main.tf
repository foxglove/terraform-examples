## ----- S3 bucket -----

module "s3_cache" {
  source      = "./modules/s3"
  bucket_name = var.cache_bucket_name

  cache_expiration_days                  = var.cache_expiration_days
  abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days
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
  azs             = data.aws_availability_zones.available.names
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
  version = "20.31.0"

  cluster_name                    = var.eks_cluster_name
  cluster_version                 = var.eks_cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # Allow the Terraform user to access the cluster
  enable_cluster_creator_admin_permissions = true

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
    ami_type = "AL2_x86_64"
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
    # This Fargate profile assumes that the Remote Data Loader resources will be deployed in
    # the configured namespace. All workloads in this namespace will be run by the
    # Fargate scheduler.
    foxglove = {
      name      = var.eks_foxglove_namespace
      selectors = [{ namespace = var.eks_foxglove_namespace }]
    }
  }
}

## ----- IAM policy & roles -----

module "iam" {
  source                 = "./modules/iam"
  cache_bucket_arn       = module.s3_cache.bucket_arn
  eks_oidc_provider_arn  = module.eks.oidc_provider_arn
  eks_foxglove_namespace = var.eks_foxglove_namespace
}
