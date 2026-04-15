###############################################################################
# Outputs for Healthcare AI Platform
###############################################################################

# ─── Resource Group ───────────────────────────────────────────────────────────

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

# ─── AKS ──────────────────────────────────────────────────────────────────────

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.cluster_fqdn
}

output "aks_kube_config_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
}

# ─── Container Registry ──────────────────────────────────────────────────────

output "acr_login_server" {
  description = "Login server for ACR"
  value       = module.container_registry.login_server
}

# ─── Key Vault ────────────────────────────────────────────────────────────────

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.key_vault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.key_vault_uri
}

# ─── Databases ────────────────────────────────────────────────────────────────

output "postgresql_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = module.postgresql.fqdn
  sensitive   = true
}

output "cosmos_db_endpoint" {
  description = "Endpoint of the Cosmos DB account"
  value       = module.cosmos_db.endpoint
}

output "redis_hostname" {
  description = "Hostname of the Redis cache"
  value       = module.redis.hostname
  sensitive   = true
}

# ─── Monitoring ───────────────────────────────────────────────────────────────

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.app_insights.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = module.log_analytics.workspace_id
}

# ─── OpenAI ───────────────────────────────────────────────────────────────────

output "openai_endpoint" {
  description = "Azure OpenAI service endpoint"
  value       = module.openai.endpoint
}

# ─── Health Data Services ─────────────────────────────────────────────────────

output "fhir_service_url" {
  description = "FHIR service URL"
  value       = module.health_data_services.fhir_url
}
