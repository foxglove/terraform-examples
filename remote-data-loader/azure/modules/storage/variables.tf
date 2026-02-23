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
  description = "Name of the storage account to hold the cache container"
}

variable "cache_expiration_days" {
  type        = number
  description = "Number of days after which cached objects are deleted"
  default     = 30
}
