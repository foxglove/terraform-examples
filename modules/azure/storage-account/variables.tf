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
  description = "Name of the storage account"
}

variable "deleted_blob_retention_days" {
  type        = number
  description = "Retention policy to keep blobs for X days"
}

variable "deleted_container_retention_days" {
  type        = number
  description = "Retention policy to keep containers for X days"
}
