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

variable "use_existing_service_principal" {
  type        = bool
  description = "Whether to use an existing service principal instead of creating one"
  default     = false
}

variable "existing_service_principal_client_id" {
  type        = string
  description = "Client ID of existing service principal to use (required when use_existing_service_principal is true)"
  default     = ""
  
  validation {
    condition     = !var.use_existing_service_principal || length(var.existing_service_principal_client_id) > 0
    error_message = "existing_service_principal_client_id is required when use_existing_service_principal is true."
  }
}

variable "existing_service_principal_object_id" {
  type        = string
  description = "Object ID of existing service principal to use (required when use_existing_service_principal is true)"
  default     = ""
  
  validation {
    condition     = !var.use_existing_service_principal || length(var.existing_service_principal_object_id) > 0
    error_message = "existing_service_principal_object_id is required when use_existing_service_principal is true."
  }
}

variable "existing_service_principal_client_secret" {
  type        = string
  description = "Client secret of existing service principal to use (required when use_existing_service_principal is true)"
  default     = ""
  sensitive   = true
  
  validation {
    condition     = !var.use_existing_service_principal || length(var.existing_service_principal_client_secret) > 0
    error_message = "existing_service_principal_client_secret is required when use_existing_service_principal is true."
  }
}
