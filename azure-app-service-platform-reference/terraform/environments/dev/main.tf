resource "azurerm_resource_group" "this" {
  name     = "rg-portfolio-app-${var.name_suffix}-dev"
  location = var.location

  tags = local.tags
}

locals {
  tags = {
    environment = "dev"
    project     = "azure-app-service-platform-reference"
    managed_by  = "terraform"
  }
}

module "platform" {
  source = "../../modules/platform"

  name_prefix        = "pf${var.name_suffix}dev"
  location           = var.location
  resource_group_name = azurerm_resource_group.this.name
  app_service_sku    = "P0v3"
  tags               = local.tags
}
