resource "azurerm_eventgrid_system_topic" "inbox_event_topic" {
  name                   = "${var.storage_account_name}-inbox-events"
  resource_group_name    = var.resource_group_name
  location               = var.resource_location
  source_arm_resource_id = var.storage_account_resource_id
  topic_type             = "Microsoft.Storage.StorageAccounts"
  identity {
    type = "SystemAssigned"
  }
}

#
# Queueing is managed by the FG control plane, but uses a deadletter storage container
# in the case of API unreachability.
#
resource "azurerm_storage_container" "inbox_notifications_dql" {
  name                  = "${var.storage_account_name}-inbox-dlq"
  storage_account_name  = var.storage_account_name
  container_access_type = "private"
}

#
# The FG endpoint must be running when this resource is created or updated to
# complete the validation handshake.
#
resource "azurerm_eventgrid_system_topic_event_subscription" "webhook_event_subscription" {
  name                  = "${var.storage_account_name}-inbox-notifications-sub"
  system_topic          = azurerm_eventgrid_system_topic.inbox_event_topic.name
  resource_group_name   = azurerm_eventgrid_system_topic.inbox_event_topic.resource_group_name
  event_delivery_schema = "EventGridSchema"
  subject_filter {
    subject_begins_with = "/blobServices/default/containers/inbox/blobs/"
  }
  included_event_types = [
    "Microsoft.Storage.BlobCreated",
  ]
  webhook_endpoint {
    url = var.inbox_notification_endpoint

    # The FG endpoint requires that max_events_per_batch be set to 1 (the default).
    max_events_per_batch = 1
  }

  # Retry policy: https://learn.microsoft.com/en-us/azure/event-grid/manage-event-delivery#set-retry-policy
  retry_policy {
    max_delivery_attempts = var.inbox_webhook_max_delivery_attempts
    event_time_to_live    = var.inbox_webook_event_minutes_to_live
  }

  storage_blob_dead_letter_destination {
    storage_account_id          = var.storage_account_resource_id
    storage_blob_container_name = azurerm_storage_container.inbox_notifications_dql.name
  }
}
