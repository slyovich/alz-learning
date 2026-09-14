resource "azurerm_resource_group" "this" {
  name     = "rg-${var.PROJECT}-${var.REGION_SHORTNAME}-${var.ENVIRONMENT}-001"
  location = var.REGION_NAME
}
