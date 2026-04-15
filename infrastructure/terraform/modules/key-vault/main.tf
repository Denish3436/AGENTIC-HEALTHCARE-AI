###############################################################################
# Azure Key Vault Module
###############################################################################

resource "azurerm_key_vault" "main" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 90
  purge_protection_enabled    = var.environment == "prod" ? true : false
  enabled_for_disk_encryption = true
  tags                        = var.tags

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Recover", "Purge",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Purge",
    ]

    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]
  }

  network_acls {
    bypass         = "AzureServices"
    default_action = var.environment == "prod" ? "Deny" : "Allow"
  }
}
