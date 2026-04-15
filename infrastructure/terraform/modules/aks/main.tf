###############################################################################
# Azure Kubernetes Service (AKS) Module
###############################################################################

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  default_node_pool {
    name                = "system"
    vm_size             = "Standard_D4s_v3"
    enable_auto_scaling = true
    min_count           = var.environment == "prod" ? 3 : 1
    max_count           = var.environment == "prod" ? 5 : 3
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    vnet_subnet_id      = var.subnet_id

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }

    zones = var.environment == "prod" ? [1, 2, 3] : [1]
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.0.0.0/16"
    dns_service_ip    = "10.0.0.10"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  azure_policy_enabled = true

  auto_scaler_profile {
    balance_similar_node_groups      = true
    max_graceful_termination_sec     = 600
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_utilization_threshold = 0.5
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
    ]
  }
}

# Application node pool
resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  name                  = "apps"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.environment == "prod" ? "Standard_D8s_v3" : "Standard_D4s_v3"
  enable_auto_scaling   = true
  min_count             = var.environment == "prod" ? 3 : 1
  max_count             = var.environment == "prod" ? 20 : 5
  os_disk_size_gb       = 128
  vnet_subnet_id        = var.subnet_id
  tags                  = var.tags

  node_labels = {
    "nodepool-type" = "application"
    "environment"   = var.environment
    "workload"      = "healthcare-ai"
  }

  zones = var.environment == "prod" ? [1, 2, 3] : [1]

  lifecycle {
    ignore_changes = [node_count]
  }
}

# Attach ACR to AKS
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = var.acr_id != "" ? 1 : 0
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = var.acr_id
}
