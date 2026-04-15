###############################################################################
# Healthcare AI Platform - Main Terraform Configuration
# 
# This deploys the complete Azure infrastructure for the healthcare AI platform
# Alternative to Bicep templates in ../bicep/
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sthealthcareaitfstate"
    container_name       = "tfstate"
    key                  = "healthcare-ai.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azuread" {}

# ─── Data Sources ─────────────────────────────────────────────────────────────

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

# ─── Random Suffix ────────────────────────────────────────────────────────────

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# ─── Local Variables ──────────────────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  name_suffix = random_string.suffix.result

  common_tags = {
    Environment = var.environment
    Project     = "Healthcare-AI"
    ManagedBy   = "Terraform"
    Compliance  = "HIPAA"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
}

# ─── Resource Group ───────────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

# ─── Modules ──────────────────────────────────────────────────────────────────

module "log_analytics" {
  source = "./modules/log-analytics"

  name                = "log-${local.name_prefix}-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

module "app_insights" {
  source = "./modules/app-insights"

  name                = "appi-${local.name_prefix}-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  workspace_id        = module.log_analytics.workspace_id
  tags                = local.common_tags
}

module "key_vault" {
  source = "./modules/key-vault"

  name                = "kv-${local.name_prefix}-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  environment         = var.environment
  tags                = local.common_tags
}

module "container_registry" {
  source = "./modules/container-registry"

  name                = "acr${replace(local.name_prefix, "-", "")}${local.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.environment == "prod" ? "Premium" : "Standard"
  tags                = local.common_tags
}

module "aks" {
  source = "./modules/aks"

  name                       = "aks-${local.name_prefix}-${local.name_suffix}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  dns_prefix                 = "healthcare-ai-${var.environment}"
  kubernetes_version         = var.kubernetes_version
  environment                = var.environment
  log_analytics_workspace_id = module.log_analytics.workspace_id
  acr_id                     = module.container_registry.acr_id
  tags                       = local.common_tags
}

module "postgresql" {
  source = "./modules/postgresql"

  name                = "psql-${local.name_prefix}-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  key_vault_id        = module.key_vault.key_vault_id
  tags                = local.common_tags
}

module "redis" {
  source = "./modules/redis"

  name                = "redis-${local.name_prefix}-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  tags                = local.common_tags
}

module "cosmos_db" {
  source = "./modules/cosmos-db"

  name                = "cosmos-${local.name_prefix}-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  tags                = local.common_tags
}

module "openai" {
  source = "./modules/openai"

  name                = "oai-${local.name_prefix}-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.openai_location
  environment         = var.environment
  key_vault_id        = module.key_vault.key_vault_id
  tags                = local.common_tags
}

module "health_data_services" {
  source = "./modules/health-data-services"

  name                = "hds-${local.name_prefix}-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}
