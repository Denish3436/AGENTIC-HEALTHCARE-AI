###############################################################################
# Azure Health Data Services (FHIR) Module
###############################################################################

resource "azurerm_healthcare_workspace" "main" {
  name                = replace(var.name, "-", "")
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_healthcare_fhir_service" "main" {
  name                          = "fhir-${var.name}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  workspace_id                  = azurerm_healthcare_workspace.main.id
  kind                          = "fhir-R4"
  configuration_export_storage_account_name = null
  tags                          = var.tags

  authentication {
    authority = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}"
    audience  = "https://${replace(var.name, "-", "")}fhir.fhir.azurehealthcareapis.com"
  }

  identity {
    type = "SystemAssigned"
  }
}

data "azurerm_client_config" "current" {}
