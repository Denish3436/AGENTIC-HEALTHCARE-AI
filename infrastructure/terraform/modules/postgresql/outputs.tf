output "fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "server_id" {
  description = "ID of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "admin_login" {
  description = "Administrator login"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
  sensitive   = true
}
