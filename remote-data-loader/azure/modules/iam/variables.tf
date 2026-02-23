variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create the resources in"
}

variable "application_display_name" {
  type        = string
  description = "Name of the application registration within Azure Active Directory"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account"
}

variable "cache_container_name" {
  type        = string
  description = "Name of the cache container"
}
