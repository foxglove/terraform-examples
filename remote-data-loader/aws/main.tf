## ----- S3 bucket -----

module "s3_cache" {
  source      = "../../modules/aws/s3-bucket"
  bucket_name = var.cache_bucket_name

  abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days
}

## ----- VPC & EKS cluster -----

module "cluster" {
  source = "../../modules/aws/eks-cluster"

  vpc_name        = var.vpc_name
  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  fargate_namespaces = ["foxglove"]
}

## ----- IAM policy & roles -----

module "iam" {
  source                = "./modules/iam"
  cache_bucket_arn      = module.s3_cache.bucket_arn
  eks_oidc_provider_arn = module.cluster.oidc_provider_arn
  eks_namespace         = "foxglove"
}
