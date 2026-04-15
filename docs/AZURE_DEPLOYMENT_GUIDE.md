# Azure Deployment Guide for Healthcare AI Platform

> **Comprehensive guide for deploying the Healthcare AI Platform on Microsoft Azure**

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Azure Resource Setup](#azure-resource-setup)
3. [Infrastructure Deployment](#infrastructure-deployment)
4. [Application Deployment](#application-deployment)
5. [Security Configuration](#security-configuration)
6. [Monitoring Setup](#monitoring-setup)
7. [Disaster Recovery](#disaster-recovery)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Azure Subscription Requirements

- **Azure Subscription**: Active subscription with Owner or Contributor role
- **Resource Providers**: Ensure the following are registered:
  ```bash
  az provider register --namespace Microsoft.ContainerService
  az provider register --namespace Microsoft.ContainerRegistry
  az provider register --namespace Microsoft.KeyVault
  az provider register --namespace Microsoft.OperationalInsights
  az provider register --namespace Microsoft.Insights
  az provider register --namespace Microsoft.CognitiveServices
  az provider register --namespace Microsoft.HealthcareApis
  az provider register --namespace Microsoft.DocumentDB
  az provider register --namespace Microsoft.DBforPostgreSQL
  az provider register --namespace Microsoft.Cache
  ```

### Required Tools

Install the following tools on your local machine:

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# kubectl
az aks install-cli

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Azure DevOps CLI extension
az extension add --name azure-devops
```

### Service Principal Creation

Create a service principal for Azure DevOps:

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create service principal
az ad sp create-for-rbac \
  --name "healthcare-ai-devops-sp" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth > azure-credentials.json

# Save the output securely - you'll need it for Azure DevOps
```

---

## Azure Resource Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/agentic-healthcare-ai.git
cd agentic-healthcare-ai
```

### Step 2: Configure Environment Variables

```bash
# Copy the environment template
cp env.template .env

# Edit the .env file with your Azure credentials
nano .env
```

Required environment variables:

```bash
# Azure Subscription
AZURE_SUBSCRIPTION_ID="your-subscription-id"
AZURE_TENANT_ID="your-tenant-id"
AZURE_LOCATION="eastus"

# Resource Names
RESOURCE_GROUP="rg-healthcare-ai-prod"
AKS_CLUSTER_NAME="aks-healthcare-ai-prod"
ACR_NAME="acrhealthcareai"
KEY_VAULT_NAME="kv-healthcare-ai-prod"

# Azure OpenAI
AZURE_OPENAI_ENDPOINT="https://your-openai.openai.azure.com/"
AZURE_OPENAI_KEY="your-openai-key"
AZURE_OPENAI_DEPLOYMENT="gpt-4"

# Azure Health Data Services
FHIR_BASE_URL="https://your-workspace-fhir.fhir.azurehealthcareapis.com"

# Application Insights
APPINSIGHTS_CONNECTION_STRING="your-connection-string"
```

---

## Infrastructure Deployment

### Option 1: Automated Deployment with Bicep

```bash
# Navigate to infrastructure directory
cd infrastructure/bicep

# Login to Azure
az login

# Create deployment
az deployment sub create \
  --name healthcare-ai-deployment \
  --location eastus \
  --template-file main.bicep \
  --parameters @parameters.json \
  --parameters environment=prod

# Wait for deployment to complete (15-30 minutes)
```

### Option 2: Step-by-Step Manual Deployment

#### 1. Create Resource Group

```bash
az group create \
  --name rg-healthcare-ai-prod \
  --location eastus \
  --tags Environment=Production Project=Healthcare-AI Compliance=HIPAA
```

#### 2. Deploy Azure Container Registry

```bash
az acr create \
  --resource-group rg-healthcare-ai-prod \
  --name acrhealthcareai \
  --sku Premium \
  --location eastus \
  --admin-enabled false \
  --public-network-enabled false
```

#### 3. Deploy Azure Kubernetes Service

```bash
az aks create \
  --resource-group rg-healthcare-ai-prod \
  --name aks-healthcare-ai-prod \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3 \
  --enable-managed-identity \
  --enable-addons monitoring,azure-policy,azure-keyvault-secrets-provider \
  --enable-cluster-autoscaler \
  --min-count 3 \
  --max-count 10 \
  --network-plugin azure \
  --network-policy azure \
  --zones 1 2 3 \
  --kubernetes-version 1.28.3 \
  --attach-acr acrhealthcareai
```

#### 4. Deploy Azure Key Vault

```bash
az keyvault create \
  --name kv-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --location eastus \
  --enable-rbac-authorization true \
  --enable-purge-protection true \
  --enable-soft-delete true \
  --retention-days 90 \
  --public-network-access Disabled
```

#### 5. Deploy Azure OpenAI Service

```bash
az cognitiveservices account create \
  --name openai-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --kind OpenAI \
  --sku S0 \
  --location eastus \
  --custom-domain openai-healthcare-ai-prod \
  --public-network-access Disabled

# Deploy GPT-4 model
az cognitiveservices account deployment create \
  --name openai-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --deployment-name gpt-4 \
  --model-name gpt-4 \
  --model-version 0613 \
  --model-format OpenAI \
  --sku-capacity 120 \
  --sku-name Standard
```

#### 6. Deploy Azure Health Data Services

```bash
# Create workspace
az healthcareapis workspace create \
  --name health-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --location eastus

# Create FHIR service
az healthcareapis workspace fhir-service create \
  --workspace-name health-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --name fhir-healthcare-ai-prod \
  --kind fhir-R4 \
  --location eastus \
  --identity-type SystemAssigned
```

#### 7. Deploy Supporting Services

```bash
# PostgreSQL
az postgres flexible-server create \
  --name psql-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --location eastus \
  --admin-user healthcareadmin \
  --tier GeneralPurpose \
  --sku-name Standard_D4s_v3 \
  --storage-size 512 \
  --version 15 \
  --high-availability ZoneRedundant \
  --public-access None

# Redis Cache
az redis create \
  --name redis-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --location eastus \
  --sku Premium \
  --vm-size P1 \
  --enable-non-ssl-port false \
  --minimum-tls-version 1.2

# Cosmos DB
az cosmosdb create \
  --name cosmos-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --locations regionName=eastus failoverPriority=0 isZoneRedundant=true \
  --locations regionName=westus2 failoverPriority=1 isZoneRedundant=true \
  --enable-automatic-failover true \
  --public-network-access Disabled
```

---

## Application Deployment

### Step 1: Configure AKS Credentials

```bash
az aks get-credentials \
  --resource-group rg-healthcare-ai-prod \
  --name aks-healthcare-ai-prod \
  --overwrite-existing
```

### Step 2: Create Kubernetes Secrets

```bash
# Get Azure OpenAI credentials
OPENAI_KEY=$(az cognitiveservices account keys list \
  --name openai-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --query key1 -o tsv)

# Get Application Insights connection string
APPINSIGHTS_CS=$(az monitor app-insights component show \
  --app ai-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --query connectionString -o tsv)

# Create Kubernetes secret
kubectl create secret generic healthcare-ai-secrets \
  --namespace healthcare-ai \
  --from-literal=azure-openai-endpoint="https://openai-healthcare-ai-prod.openai.azure.com/" \
  --from-literal=azure-openai-key="$OPENAI_KEY" \
  --from-literal=app-insights-connection-string="$APPINSIGHTS_CS" \
  --from-literal=fhir-base-url="https://health-healthcare-ai-prod-fhir-healthcare-ai-prod.fhir.azurehealthcareapis.com" \
  --from-literal=postgres-connection-string="postgresql://healthcareadmin@psql-healthcare-ai-prod:5432/healthcare_ai" \
  --from-literal=redis-connection-string="redis-healthcare-ai-prod.redis.cache.windows.net:6380,ssl=True"
```

### Step 3: Deploy Application to AKS

```bash
# Apply Kubernetes manifests
kubectl apply -f kubernetes/aks-deployment.yaml

# Verify deployment
kubectl get pods -n healthcare-ai
kubectl get services -n healthcare-ai
kubectl get ingress -n healthcare-ai
```

### Step 4: Configure Azure DevOps Pipeline

1. **Create Azure DevOps Project**:
   - Navigate to https://dev.azure.com
   - Create new project: "Healthcare-AI"

2. **Configure Service Connection**:
   - Go to Project Settings > Service connections
   - Create new Azure Resource Manager connection
   - Use the service principal credentials from earlier

3. **Import Pipeline**:
   ```bash
   # Push code to Azure Repos
   git remote add azure https://dev.azure.com/YOUR_ORG/Healthcare-AI/_git/Healthcare-AI
   git push azure main
   ```

4. **Create Pipeline Variables**:
   - Navigate to Pipelines > Library
   - Create variable group: `healthcare-ai-variables`
   - Add all required variables from `.env`

5. **Run Pipeline**:
   - Navigate to Pipelines
   - Create new pipeline from `azure-pipelines.yml`
   - Run the pipeline

---

## Security Configuration

### Enable Azure Defender

```bash
# Enable Azure Defender for AKS
az security pricing create \
  --name KubernetesService \
  --tier Standard

# Enable Azure Defender for Container Registries
az security pricing create \
  --name ContainerRegistry \
  --tier Standard

# Enable Azure Defender for Key Vault
az security pricing create \
  --name KeyVaults \
  --tier Standard
```

### Configure Network Security

```bash
# Apply network policies
kubectl apply -f azure-devops/security-policies.yml

# Verify network policies
kubectl get networkpolicies -n healthcare-ai
```

### Enable Azure Policy

```bash
# Assign HIPAA compliance policy
az policy assignment create \
  --name "HIPAA-Compliance" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-healthcare-ai-prod" \
  --policy-set-definition "HIPAA HITRUST 9.2"
```

---

## Monitoring Setup

### Configure Application Insights

```bash
# Application Insights is already configured via Bicep deployment
# Verify it's working:
az monitor app-insights component show \
  --app ai-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod
```

### Set Up Alerts

```bash
# Apply monitoring configuration
kubectl apply -f azure-devops/azure-monitoring.yml

# Create action group for alerts
az monitor action-group create \
  --name healthcare-ai-alerts \
  --resource-group rg-healthcare-ai-prod \
  --short-name hc-alerts \
  --email-receiver name=devops email=devops@healthcare-ai.com
```

---

## Disaster Recovery

### Backup Configuration

```bash
# Enable AKS backup
az backup vault create \
  --name bv-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --location eastus

# Configure database backups (automated with Bicep deployment)
# Verify backup configuration
az postgres flexible-server show \
  --name psql-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --query backup
```

### Test Disaster Recovery

```bash
# Test failover for Cosmos DB
az cosmosdb failover-priority-change \
  --name cosmos-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --failover-policies westus2=0 eastus=1
```

---

## Troubleshooting

### Common Issues

#### 1. Pod Not Starting

```bash
# Check pod logs
kubectl logs -n healthcare-ai <pod-name>

# Describe pod for events
kubectl describe pod -n healthcare-ai <pod-name>

# Check secrets
kubectl get secrets -n healthcare-ai
```

#### 2. Image Pull Errors

```bash
# Verify ACR integration
az aks check-acr \
  --name aks-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --acr acrhealthcareai.azurecr.io
```

#### 3. Network Connectivity Issues

```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Test service connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://healthcare-ai-crewai:8000/health
```

### Support Resources

- **Azure Support**: https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade
- **Azure DevOps Support**: https://developercommunity.visualstudio.com/AzureDevOps
- **Documentation**: https://docs.microsoft.com/azure

---

## Next Steps

After successful deployment:

1. ✅ Verify all services are running
2. ✅ Test API endpoints
3. ✅ Configure custom domain and SSL
4. ✅ Set up CI/CD workflows
5. ✅ Configure monitoring dashboards
6. ✅ Perform security audit
7. ✅ Document runbooks
8. ✅ Train operations team

---

**Deployment Complete! 🎉**

Your Healthcare AI Platform is now running on Azure with enterprise-grade security, scalability, and observability.
