variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
  default     = "1.27"
}

variable "node_group_instance_types" {
  type        = list(string)
  description = "Instance types for the default managed node group"
  default     = ["t3.small"]
}

variable "node_group_min_size" {
  type        = number
  description = "Minimum number of nodes in the default node group"
  default     = 0
}

variable "node_group_max_size" {
  type        = number
  description = "Maximum number of nodes in the default node group"
  default     = 2
}

variable "node_group_desired_size" {
  type        = number
  description = "Desired number of nodes in the default node group"
  default     = 1
}

variable "fargate_namespaces" {
  type        = list(string)
  description = "List of Kubernetes namespaces to create Fargate profiles for"
  default     = []
}
