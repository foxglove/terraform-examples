variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create the resources in"
}

variable "resource_location" {
  type        = string
  description = "Name of resource location to create the resources in"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account to hold the `inbox` and `lake` containers"
}

variable "deleted_blob_retention_days" {
  type        = number
  description = "Retention policy to keep blobs for X days"
}

variable "deleted_container_retention_days" {
  type        = number
  description = "Retention policy to keep containers for X days"
}

variable "inbox_notification_endpoint" {
  type        = string
  description = "https endpoint to call on file upload"
}

variable "inbox_webhook_max_delivery_attempts" {
  type        = number
  description = "Max number of retries for the inbox webhook"
}

variable "inbox_webook_event_minutes_to_live" {
  type        = number
  description = "Max TTL for the inbox webhook event"
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster (will be used as DNS prefix as well)"
}

variable "cluster_min_nodes" {
  type        = string
  description = "Minimum number of nodes in the cluster"
}

variable "cluster_max_nodes" {
  type        = string
  description = "Maximum number of nodes in the cluster"
}

variable "cluster_vm_size" {
  type        = string
  description = "Cluster VM size"
}

variable "application_display_name" {
  type        = string
  description = "Name of the application registration within Azure Active Directory"
}