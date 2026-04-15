# Terraform Infrastructure for Healthcare AI Platform

## Overview

This directory contains Terraform configurations to deploy the complete Azure infrastructure for the Healthcare AI Platform. This is an **alternative** to the Bicep templates in `../bicep/`.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50
- Azure subscription with Owner/Contributor access

## Modules

| Module | Description |
|--------|-------------|
| `aks` | Azure Kubernetes Service cluster with system + app node pools |
| `container-registry` | Azure Container Registry with geo-replication support |
| `key-vault` | Azure Key Vault with access policies and network ACLs |
| `log-analytics` | Log Analytics workspace with Container Insights |
| `app-insights` | Application Insights for APM telemetry |
| `postgresql` | PostgreSQL Flexible Server with HA and audit database |
| `redis` | Azure Cache for Redis with TLS enforcement |
| `cosmos-db` | Cosmos DB with conversations and assessments containers |
| `openai` | Azure OpenAI Service with GPT-4 and GPT-3.5 deployments |
| `health-data-services` | Azure Health Data Services with FHIR R4 service |

## Quick Start

### 1. Create Backend Storage (one-time)

```bash
az group create --name rg-terraform-state --location eastus

az storage account create \
  --name sthealthcareaitfstate \
  --resource-group rg-terraform-state \
  --sku Standard_LRS \
  --encryption-services blob

az storage container create \
  --name tfstate \
  --account-name sthealthcareaitfstate
```

### 2. Initialize and Deploy

```bash
cd infrastructure/terraform

# Initialize
terraform init

# Review plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan
```

### 3. Get AKS Credentials

```bash
# Use the output command
$(terraform output -raw aks_kube_config_command)
```

## Environment-Specific Deployments

```bash
# Development
terraform workspace new dev
terraform apply -var="environment=dev"

# Staging
terraform workspace new staging
terraform apply -var="environment=staging"

# Production
terraform workspace new prod
terraform apply -var="environment=prod"
```

## Estimated Costs

| Environment | Monthly Cost |
|-------------|-------------|
| Dev | $500-800 |
| Staging | $800-1,500 |
| Production | $2,350-5,950 |

## Cleanup

```bash
terraform destroy
```
