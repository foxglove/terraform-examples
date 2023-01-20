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
  description = "Name of the storage account to hold the `inbox` and `lake` containers"
}

variable "inbox_storage_container_name" {
  type        = string
  description = "Name of the `inbox` container"
}

variable "lake_storage_container_name" {
  type        = string
  description = "Name of the `lake` container"
}
