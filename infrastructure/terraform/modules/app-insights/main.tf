###############################################################################
# Azure Application Insights Module
###############################################################################

resource "azurerm_application_insights" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.workspace_id
  application_type    = "web"
  retention_in_days   = 90
  tags                = var.tags
}
