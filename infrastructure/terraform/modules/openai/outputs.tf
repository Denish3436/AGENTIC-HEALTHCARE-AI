output "endpoint" {
  description = "Endpoint of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}

output "id" {
  description = "ID of the OpenAI service"
  value       = azurerm_cognitive_account.openai.id
}
