output "acr_id" {
  description = "ID of the container registry"
  value       = azurerm_container_registry.main.id
}

output "login_server" {
  description = "Login server for ACR"
  value       = azurerm_container_registry.main.login_server
}

output "admin_username" {
  description = "Admin username (if enabled)"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}
