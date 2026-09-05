variable "location" {
  description = "Azure region used by the dev environment."
  type        = string
  default     = "eastus2"
}

variable "name_suffix" {
  description = "Short globally unique suffix for resources such as the Web App."
  type        = string
}
