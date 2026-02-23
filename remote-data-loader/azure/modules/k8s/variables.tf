variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create the resources in"
}

variable "resource_location" {
  type        = string
  description = "Name of resource location to create the resources in"
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster (will be used as DNS prefix as well)"
}

variable "cluster_min_nodes" {
  type        = number
  description = "Minimum number of nodes in the cluster"
  default     = 1
}

variable "cluster_max_nodes" {
  type        = number
  description = "Maximum number of nodes in the cluster"
  default     = 4
}

variable "cluster_vm_size" {
  type        = string
  description = "Cluster VM size"
  default     = "Standard_D4_v2"
}
