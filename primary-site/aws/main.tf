## ----- S3 buckets -----

module "s3_lake" {
  source      = "./modules/s3"
  bucket_name = "${var.prefix}-lake-bucket"

  abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days
}

module "s3_inbox" {
  source      = "./modules/s3"
  bucket_name = "${var.prefix}-inbox-bucket"

  abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days
}

## ----- Pubsub -----

module "inbox_sns_notification" {
  source     = "./modules/sns"
  bucket_arn = module.s3_inbox.bucket_arn
  bucket_id  = module.s3_inbox.bucket_id
  topic_name = "${var.prefix}-inbox-bucket-sns-topic"

  inbox_notification_endpoint = var.inbox_notification_endpoint
}

## ----- Data Sources -----

data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

## ----- VPC -----

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.prefix}-vpc"

  # EKS VPC and subnet requirements and considerations
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  cidr            = "10.0.0.0/16"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
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
    "kubernetes.io/cluster/${var.prefix}-cluster" = "shared"
    "kubernetes.io/role/elb"                        = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.prefix}-cluster" = "shared"
    "kubernetes.io/role/internal-elb"               = 1
  }
}

## ----- EKS cluster & instance security groups -----

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name                    = "${var.prefix}-cluster"
  cluster_version                 = "1.29"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
    aws-ebs-csi-driver = var.enable_monitoring ? {
      service_account_role_arn = module.ebs_csi_role[0].iam_role_arn
    } : null
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
      min_size     = var.eks_node_group_min_size
      max_size     = var.eks_node_group_max_size
      desired_size = var.eks_node_group_desired_size

      instance_types = var.eks_node_instance_types
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

## ----- Kubernetes Provider Data -----

## ----- IAM policy & roles -----

module "iam" {
  source                 = "./modules/iam"
  prefix                 = var.prefix
  lake_bucket_arn        = module.s3_lake.bucket_arn
  inbox_bucket_arn       = module.s3_inbox.bucket_arn
  eks_oidc_provider_arn  = module.eks.oidc_provider_arn
  eks_foxglove_namespace = "foxglove"
}

## ----- Kubernetes Resources -----

resource "kubernetes_namespace" "foxglove" {
  metadata {
    name = "foxglove"
  }

  # Ensure the namespace is created after the EKS cluster and IAM roles are ready
  depends_on = [
    module.eks,
    module.iam
  ]
}

resource "kubernetes_secret" "site_token" {
  metadata {
    name      = "foxglove-site-token"
    namespace = kubernetes_namespace.foxglove.metadata[0].name
  }

  data = {
    FOXGLOVE_SITE_TOKEN = var.site_token
  }

  depends_on = [
    kubernetes_namespace.foxglove
  ]
}

## ----- AWS Load Balancer Controller Setup -----

# Create IAM role for the AWS Load Balancer Controller
module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${var.prefix}-eks-lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# Create service account for the AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.lb_role.iam_role_arn
    }
  }

  depends_on = [
    module.eks
  ]
}

# RBAC for the wait job to check deployment status
resource "kubernetes_role" "lb_controller_waiter" {
  metadata {
    name      = "lb-controller-waiter-role"
    namespace = "kube-system"
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources = ["services", "endpoints"]
    verbs = ["get"]
  }
}

resource "kubernetes_role_binding" "lb_controller_waiter_binding" {
  metadata {
    name      = "lb-controller-waiter-binding"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.lb_controller_waiter.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
    namespace = "kube-system"
  }

  depends_on = [
    kubernetes_role.lb_controller_waiter,
    kubernetes_service_account.aws_load_balancer_controller
  ]
}

# ClusterRole for cluster-scoped resources needed by the wait job
resource "kubernetes_cluster_role" "lb_controller_waiter_cluster" {
  metadata {
    name = "lb-controller-waiter-clusterrole"
  }
  rule {
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["validatingwebhookconfigurations"]
    verbs      = ["get"]
  }
}

# ClusterRoleBinding to grant cluster-scoped permissions
resource "kubernetes_cluster_role_binding" "lb_controller_waiter_cluster_binding" {
  metadata {
    name = "lb-controller-waiter-clusterrolebinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.lb_controller_waiter_cluster.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
    namespace = "kube-system"
  }

  depends_on = [
    kubernetes_cluster_role.lb_controller_waiter_cluster,
    kubernetes_service_account.aws_load_balancer_controller
  ]
}

# Install AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set {
    name  = "clusterName"
    value = "${var.prefix}-cluster"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  # Enable webhook
  set {
    name  = "enableServiceMonitor"
    value = "false"
  }

  set {
    name  = "webhookTLS.enabled"
    value = "true"
  }

  depends_on = [
    module.eks,
    kubernetes_service_account.aws_load_balancer_controller
  ]
}

# Wait for the AWS Load Balancer Controller deployment to be ready
resource "kubernetes_job" "wait_for_lb_controller" {
  metadata {
    generate_name = "wait-for-lb-controller-"
    namespace     = "kube-system"
  }

  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "wait"
          image   = "bitnami/kubectl:latest"
          command = ["/bin/sh", "-c"]
          args = [<<-EOT
            echo "Waiting for AWS Load Balancer Controller deployment..."
            if ! kubectl wait --for=condition=available --timeout=180s deployment/aws-load-balancer-controller -n kube-system; then
              echo "Deployment not ready after 180s. Exiting."
              kubectl logs -n kube-system deploy/aws-load-balancer-controller
              exit 1
            fi
            echo "Deployment ready."

            echo "Waiting for webhook configuration..."
            timeout 60s bash -c '
            until kubectl get validatingwebhookconfigurations aws-load-balancer-webhook &> /dev/null; do
              echo -n .
              sleep 5
            done'
            if [ $? -ne 0 ]; then echo "Webhook configuration check timed out"; exit 1; fi
            echo "Webhook configuration found."

            echo "Waiting for webhook service..."
            timeout 60s bash -c '
            until kubectl get service -n kube-system aws-load-balancer-webhook-service &> /dev/null; do
              echo -n .
              sleep 5
            done'
            if [ $? -ne 0 ]; then echo "Webhook service check timed out"; exit 1; fi
            echo "Webhook service found."

            echo "Waiting for webhook endpoints..."
            timeout 60s bash -c '
            until kubectl get endpoints -n kube-system aws-load-balancer-webhook-service -o json | jq -e ".subsets[].addresses | length > 0" &> /dev/null; do
              echo -n .
              sleep 5
            done'
            if [ $? -ne 0 ]; then echo "Webhook endpoints check timed out"; exit 1; fi
            echo "Webhook endpoints ready."

            echo "AWS Load Balancer Controller is ready."
          EOT
          ]
        }
        restart_policy = "Never"
        service_account_name = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
      }
    }
    backoff_limit = 3 # Reduce backoff limit as we have longer timeouts now
  }

  wait_for_completion = true

  depends_on = [
    helm_release.aws_load_balancer_controller,
    kubernetes_role_binding.lb_controller_waiter_binding,
    kubernetes_cluster_role_binding.lb_controller_waiter_cluster_binding
  ]
}

# Install Foxglove Primary Site
resource "helm_release" "primary_site" {
  name             = "foxglove-primary-site"
  namespace        = kubernetes_namespace.foxglove.metadata[0].name
  repository       = "https://helm-charts.foxglove.dev"
  chart            = "primary-site"
  create_namespace = false

  # Make sure the Load Balancer Controller is installed and ready first
  depends_on = [
    kubernetes_namespace.foxglove,
    kubernetes_secret.site_token,
    module.iam,
    kubernetes_job.wait_for_lb_controller
  ]

  values = [
    yamlencode({
      globals = {
        lake = {
          storageProvider = "aws"
          bucketName     = module.s3_lake.bucket_id
        }
        inbox = {
          storageProvider = "aws"
          bucketName     = module.s3_inbox.bucket_id
        }
        aws = {
          region = data.aws_region.current.name
        }
      }
      inboxListener = {
        deployment = {
          serviceAccount = {
            enabled = true
            annotations = {
              "eks.amazonaws.com/role-arn" = module.iam.iam_inbox_listener_role_arn
            }
          }
          podAnnotations = var.enable_monitoring ? {
            "prometheus.io/scrape" = "true"
          } : {}
        }
      }
      streamService = {
        deployment = {
          serviceAccount = {
            enabled = true
            annotations = {
              "eks.amazonaws.com/role-arn" = module.iam.iam_stream_service_role_arn
            }
          }
          podAnnotations = var.enable_monitoring ? {
            "prometheus.io/scrape" = "true"
          } : {}
        }
      }
      siteController = {
        deployment = {
          podAnnotations = var.enable_monitoring ? {
            "prometheus.io/scrape" = "true"
          } : {}
        }
      }
      garbageCollector = {
        deployment = {
          serviceAccount = {
            enabled = true
            annotations = {
              "eks.amazonaws.com/role-arn" = module.iam.iam_garbage_collector_role_arn
            }
          }
        }
      }
      ingress = {
        annotations = {
          "kubernetes.io/ingress.class"                  = "alb"
          "alb.ingress.kubernetes.io/scheme"            = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"       = "ip"
          "alb.ingress.kubernetes.io/backend-protocol"  = "HTTP"
          "alb.ingress.kubernetes.io/listen-ports"      = "[{\"HTTPS\":443}]"
          "alb.ingress.kubernetes.io/certificate-arn"   = aws_acm_certificate.main.arn
        }
      }
    })
  ]
}

## ----- Horizontal Pod Autoscalers -----

# HPA for site-controller based on CPU utilization
resource "kubernetes_horizontal_pod_autoscaler_v2" "site_controller" {
  count = var.enable_monitoring ? 1 : 0
  metadata {
    name      = "site-controller-hpa"
    namespace = kubernetes_namespace.foxglove.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "foxglove-primary-site-site-controller"
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }

  depends_on = [
    helm_release.primary_site
  ]
}

# HPA for stream-service based on CPU utilization
resource "kubernetes_horizontal_pod_autoscaler_v2" "stream_service" {
  count = var.enable_monitoring ? 1 : 0
  metadata {
    name      = "stream-service-hpa"
    namespace = kubernetes_namespace.foxglove.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "foxglove-primary-site-stream-service"
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }

  depends_on = [
    helm_release.primary_site
  ]
}

# HPA for inbox-listener based on custom metric
resource "kubernetes_horizontal_pod_autoscaler_v2" "inbox_listener" {
  count = var.enable_monitoring ? 1 : 0
  metadata {
    name      = "inbox-listener-hpa"
    namespace = kubernetes_namespace.foxglove.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "foxglove-primary-site-inbox-listener"
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Object"
      object {
        metric {
          name = "foxglove_data_platform_site_controller_unleased_pending_import_count"
        }
        described_object {
          api_version = "apps/v1"
          kind        = "Namespace"
          name        = "foxglove"
        }
        target {
          type          = "AverageValue"
          average_value = "2"
        }
      }
    }
  }

  depends_on = [
    helm_release.primary_site
  ]
}

## ----- Prometheus Setup -----

# Create prometheus namespace
resource "kubernetes_namespace" "prometheus" {
  count = var.enable_monitoring ? 1 : 0

  metadata {
    name = "prometheus"
  }

  depends_on = [
    module.eks
  ]
}

# Create StorageClass for EBS volumes
resource "kubernetes_storage_class" "ebs_sc" {
  count = var.enable_monitoring ? 1 : 0

  metadata {
    name = "ebs-sc"
  }

  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy     = "Delete"

  parameters = {
    type = "gp3"
    fsType = "ext4"
  }

  depends_on = [
    module.eks
  ]
}

# Install Prometheus
resource "helm_release" "prometheus" {
  count = var.enable_monitoring ? 1 : 0

  name       = "${var.prefix}-prometheus"
  namespace  = kubernetes_namespace.prometheus[0].metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"

  set {
    name  = "server.persistentVolume.enabled"
    value = "true"
  }

  set {
    name  = "server.persistentVolume.storageClass"
    value = kubernetes_storage_class.ebs_sc[0].metadata[0].name
  }

  set {
    name  = "server.persistentVolume.size"
    value = "50Gi"
  }

  # Add additional configurations for Prometheus server
  set {
    name  = "server.resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "server.resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "server.resources.limits.cpu"
    value = "1000m"
  }

  set {
    name  = "server.resources.limits.memory"
    value = "1Gi"
  }

  depends_on = [
    kubernetes_namespace.prometheus,
    helm_release.aws_load_balancer_controller,
    kubernetes_storage_class.ebs_sc
  ]
}

# Install Prometheus Adapter for custom metrics
resource "helm_release" "prometheus_adapter" {
  count = var.enable_monitoring ? 1 : 0

  name       = "${var.prefix}-prometheus-adapter"
  namespace  = kubernetes_namespace.prometheus[0].metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-adapter"

  set {
    name  = "prometheus.url"
    value = "http://${var.prefix}-prometheus-server.prometheus.svc.cluster.local"
  }

  depends_on = [
    kubernetes_namespace.prometheus,
    helm_release.prometheus
  ]
}

# Create IAM role for the EBS CSI Driver
module "ebs_csi_role" {
  count = var.enable_monitoring ? 1 : 0

  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${var.prefix}-eks-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  # Handle pre-existing role
  providers = {
    aws = aws
  }
}

# Clean up the existing role if needed
resource "null_resource" "cleanup_ebs_csi_role" {
  count = var.enable_monitoring ? 1 : 0

  provisioner "local-exec" {
    command = "aws iam delete-role --role-name ${var.prefix}-eks-ebs-csi || true"
  }

  triggers = {
    role_name = "${var.prefix}-eks-ebs-csi"
  }
}

## ----- Wait for ALB ----- ##

# RBAC for the ALB wait job
resource "kubernetes_role" "alb_waiter" {
  metadata {
    name      = "alb-waiter-role"
    namespace = kubernetes_namespace.foxglove.metadata[0].name
  }
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get"]
  }
}

resource "kubernetes_role_binding" "alb_waiter_binding" {
  metadata {
    name      = "alb-waiter-binding"
    namespace = kubernetes_namespace.foxglove.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.alb_waiter.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default" # Use default SA in foxglove namespace
    namespace = kubernetes_namespace.foxglove.metadata[0].name
  }
  depends_on = [kubernetes_role.alb_waiter]
}

# Job to wait for the ALB hostname to appear in the Ingress status
resource "kubernetes_job" "wait_for_alb_hostname" {
  metadata {
    generate_name = "wait-for-alb-hostname-"
    namespace     = kubernetes_namespace.foxglove.metadata[0].name
  }

  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "wait"
          image   = "bitnami/kubectl:latest"
          command = ["/bin/sh", "-c"]
          # Use the correct Ingress name 'site'
          args = [<<-EOT
            INGRESS_NAME="site"
            NAMESPACE="${kubernetes_namespace.foxglove.metadata[0].name}"
            export INGRESS_NAME NAMESPACE # Export variables to subshell
            echo "Waiting for Ingress $NAMESPACE/$INGRESS_NAME to have hostname..."
            timeout 300s bash -c \
            'until kubectl get ingress -n "$NAMESPACE" "$INGRESS_NAME" -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" | grep . &> /dev/null; do echo -n .; sleep 10; done'
            if [ $? -ne 0 ]; then
              echo "Ingress hostname check timed out after 300s for $NAMESPACE/$INGRESS_NAME"
              kubectl describe ingress -n "$NAMESPACE" "$INGRESS_NAME"
              exit 1
            fi
            echo "Ingress hostname found."
          EOT
          ]
        }
        restart_policy       = "Never"
        service_account_name = "default"
      }
    }
    backoff_limit = 3
  }

  wait_for_completion = true

  depends_on = [
    helm_release.primary_site,
    kubernetes_role_binding.alb_waiter_binding
  ]
}
