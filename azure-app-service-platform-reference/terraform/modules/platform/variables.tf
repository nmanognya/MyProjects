variable "name_prefix" {
  description = "Prefix used for regional Azure resources. Keep it short and lowercase."
  type        = string
}

variable "location" {
  description = "Azure region for this platform instance."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the platform resources."
  type        = string
}

variable "address_space" {
  description = "CIDR blocks assigned to the platform VNet."
  type        = list(string)
  default     = ["10.40.0.0/16"]
}

variable "integration_subnet_prefixes" {
  description = "CIDR blocks for App Service outbound VNet integration."
  type        = list(string)
  default     = ["10.40.1.0/24"]
}

variable "private_endpoint_subnet_prefixes" {
  description = "CIDR blocks used for Azure Private Endpoints."
  type        = list(string)
  default     = ["10.40.2.0/24"]
}

variable "app_service_sku" {
  description = "App Service Plan SKU."
  type        = string
  default     = "P0v3"
}

variable "http_5xx_alert_threshold" {
  description = "Five-minute HTTP 5xx count that triggers the production App Service alert. Tune from observed traffic before using this in production."
  type        = number
  default     = 5

  validation {
    condition     = var.http_5xx_alert_threshold > 0
    error_message = "http_5xx_alert_threshold must be greater than zero."
  }
}

variable "response_time_alert_threshold_seconds" {
  description = "Fifteen-minute average response-time threshold in seconds for the production App Service alert. Tune from observed latency before using this in production."
  type        = number
  default     = 2

  validation {
    condition     = var.response_time_alert_threshold_seconds > 0
    error_message = "response_time_alert_threshold_seconds must be greater than zero."
  }
}

variable "alert_action_group_ids" {
  description = "Azure Monitor Action Group resource IDs that receive alert notifications. Empty by default so the module does not invent notification destinations."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to resources where supported."
  type        = map(string)
  default     = {}
}
