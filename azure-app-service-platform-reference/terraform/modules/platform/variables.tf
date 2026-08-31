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

variable "tags" {
  description = "Tags applied to resources where supported."
  type        = map(string)
  default     = {}
}
