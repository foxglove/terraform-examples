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

variable "storage_account_resource_id" {
  type        = string
  description = "ID of the storage account"
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
