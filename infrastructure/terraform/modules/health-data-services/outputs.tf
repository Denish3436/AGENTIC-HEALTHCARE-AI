output "workspace_id" {
  description = "ID of the Health Data Services workspace"
  value       = azurerm_healthcare_workspace.main.id
}

output "fhir_url" {
  description = "URL of the FHIR service"
  value       = "https://${replace(var.name, "-", "")}fhir.fhir.azurehealthcareapis.com"
}
