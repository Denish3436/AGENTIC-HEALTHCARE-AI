#!/bin/bash

###############################################################################
# Azure Healthcare AI Platform - Automated Deployment Script
# 
# This script deploys the complete healthcare AI platform to Azure
# Prerequisites: Azure CLI, kubectl installed and logged in
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}Error: .env file not found. Please copy env.template to .env and configure it.${NC}"
    exit 1
fi

# Validate required variables
REQUIRED_VARS=("AZURE_SUBSCRIPTION_ID" "AZURE_LOCATION" "RESOURCE_GROUP")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}Error: $var is not set in .env file${NC}"
        exit 1
    fi
done

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Azure Healthcare AI Platform - Deployment Script        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Set subscription
echo -e "${YELLOW}→ Setting Azure subscription...${NC}"
az account set --subscription "$AZURE_SUBSCRIPTION_ID"
echo -e "${GREEN}✓ Subscription set${NC}"
echo ""

# Create resource group
echo -e "${YELLOW}→ Creating resource group: $RESOURCE_GROUP${NC}"
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$AZURE_LOCATION" \
    --tags Environment=Production Project=Healthcare-AI ManagedBy=Script
echo -e "${GREEN}✓ Resource group created${NC}"
echo ""

# Deploy infrastructure using Bicep
echo -e "${YELLOW}→ Deploying Azure infrastructure (this takes 15-20 minutes)...${NC}"
echo -e "${BLUE}  Deploying: AKS, ACR, Key Vault, OpenAI, Databases, Monitoring${NC}"

DEPLOYMENT_NAME="healthcare-ai-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --template-file infrastructure/bicep/main.bicep \
    --parameters infrastructure/bicep/parameters.json \
    --parameters location="$AZURE_LOCATION" \
    --no-wait

echo -e "${BLUE}  Deployment started. Checking status...${NC}"

# Wait for deployment to complete
while true; do
    STATUS=$(az deployment group show \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query properties.provisioningState -o tsv)
    
    if [ "$STATUS" == "Succeeded" ]; then
        echo -e "${GREEN}✓ Infrastructure deployment completed successfully${NC}"
        break
    elif [ "$STATUS" == "Failed" ]; then
        echo -e "${RED}✗ Infrastructure deployment failed${NC}"
        az deployment group show \
            --name "$DEPLOYMENT_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --query properties.error
        exit 1
    else
        echo -e "${BLUE}  Status: $STATUS - waiting...${NC}"
        sleep 30
    fi
done
echo ""

# Get deployment outputs
echo -e "${YELLOW}→ Retrieving deployment outputs...${NC}"
AKS_NAME=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query properties.outputs.aksClusterName.value -o tsv)

ACR_NAME=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query properties.outputs.acrLoginServer.value -o tsv)

echo -e "${GREEN}✓ AKS Cluster: $AKS_NAME${NC}"
echo -e "${GREEN}✓ ACR: $ACR_NAME${NC}"
echo ""

# Get AKS credentials
echo -e "${YELLOW}→ Configuring kubectl for AKS...${NC}"
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --overwrite-existing
echo -e "${GREEN}✓ kubectl configured${NC}"
echo ""

# Build and push container images
echo -e "${YELLOW}→ Building and pushing container images to ACR...${NC}"

echo -e "${BLUE}  Building UI image...${NC}"
az acr build \
    --registry "${ACR_NAME%%.*}" \
    --image healthcare-ai-ui:latest \
    --file ui/Dockerfile \
    ./ui

echo -e "${BLUE}  Building CrewAI agent image...${NC}"
az acr build \
    --registry "${ACR_NAME%%.*}" \
    --image healthcare-ai-crewai:latest \
    --file crewai_fhir_agent/Dockerfile \
    ./crewai_fhir_agent

echo -e "${BLUE}  Building Autogen agent image...${NC}"
az acr build \
    --registry "${ACR_NAME%%.*}" \
    --image healthcare-ai-autogen:latest \
    --file autogen_fhir_agent/Dockerfile \
    ./autogen_fhir_agent

echo -e "${GREEN}✓ All images built and pushed${NC}"
echo ""

# Create Kubernetes secrets
echo -e "${YELLOW}→ Creating Kubernetes secrets...${NC}"

OPENAI_KEY="${AZURE_OPENAI_KEY:-placeholder}"
APPINSIGHTS_CS=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query properties.outputs.appInsightsConnectionString.value -o tsv 2>/dev/null || echo "")

kubectl create namespace healthcare-ai --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic healthcare-ai-secrets \
    --namespace healthcare-ai \
    --from-literal=azure-openai-key="$OPENAI_KEY" \
    --from-literal=app-insights-connection-string="$APPINSIGHTS_CS" \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✓ Secrets created${NC}"
echo ""

# Update deployment manifest with ACR name
echo -e "${YELLOW}→ Preparing Kubernetes deployment...${NC}"
sed "s/\${ACR_NAME}/$ACR_NAME/g" kubernetes/aks-deployment.yaml > /tmp/aks-deployment-temp.yaml

# Deploy to AKS
echo -e "${YELLOW}→ Deploying application to AKS...${NC}"
kubectl apply -f /tmp/aks-deployment-temp.yaml
rm /tmp/aks-deployment-temp.yaml

echo -e "${GREEN}✓ Application deployed${NC}"
echo ""

# Wait for pods to be ready
echo -e "${YELLOW}→ Waiting for pods to be ready (this may take 2-3 minutes)...${NC}"
kubectl wait --for=condition=ready pod \
    -l app=healthcare-ai-ui \
    -n healthcare-ai \
    --timeout=300s 2>/dev/null || echo "UI pods starting..."

kubectl wait --for=condition=ready pod \
    -l app=healthcare-ai-crewai \
    -n healthcare-ai \
    --timeout=300s 2>/dev/null || echo "CrewAI pods starting..."

kubectl wait --for=condition=ready pod \
    -l app=healthcare-ai-autogen \
    -n healthcare-ai \
    --timeout=300s 2>/dev/null || echo "Autogen pods starting..."

echo ""

# Get service information
echo -e "${YELLOW}→ Retrieving service information...${NC}"
echo ""
kubectl get pods -n healthcare-ai
echo ""
kubectl get svc -n healthcare-ai
echo ""

# Get external IP
EXTERNAL_IP=$(kubectl get svc healthcare-ai-ui -n healthcare-ai -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              DEPLOYMENT COMPLETED SUCCESSFULLY             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ Resource Group: $RESOURCE_GROUP${NC}"
echo -e "${GREEN}✓ AKS Cluster: $AKS_NAME${NC}"
echo -e "${GREEN}✓ Container Registry: $ACR_NAME${NC}"
echo ""
echo -e "${YELLOW}Application Access:${NC}"
if [ "$EXTERNAL_IP" != "Pending..." ]; then
    echo -e "${GREEN}  UI: http://$EXTERNAL_IP${NC}"
    echo -e "${GREEN}  API: http://$EXTERNAL_IP:8000${NC}"
    echo -e "${GREEN}  Health: http://$EXTERNAL_IP/health${NC}"
else
    echo -e "${YELLOW}  External IP is being assigned. Run this command to check:${NC}"
    echo -e "${BLUE}  kubectl get svc healthcare-ai-ui -n healthcare-ai${NC}"
fi
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo -e "${BLUE}  View pods:    kubectl get pods -n healthcare-ai${NC}"
echo -e "${BLUE}  View logs:    kubectl logs -f deployment/healthcare-ai-ui -n healthcare-ai${NC}"
echo -e "${BLUE}  Scale app:    kubectl scale deployment healthcare-ai-ui --replicas=5 -n healthcare-ai${NC}"
echo ""
echo -e "${YELLOW}Azure Portal:${NC}"
echo -e "${BLUE}  https://portal.azure.com/#@/resource/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP${NC}"
echo ""
echo -e "${GREEN}🎉 Your Healthcare AI Platform is now running on Azure!${NC}"
echo ""
