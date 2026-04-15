# 🚀 Quick Start Guide - Azure Healthcare AI Platform

> **Deploy this enterprise healthcare AI platform to Azure in under 30 minutes**

## Prerequisites

### Required Tools
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install kubectl
az aks install-cli

# Verify installations
az --version
kubectl version --client
```

### Azure Account Setup
1. **Azure Subscription** - Get one at https://azure.microsoft.com/free/
2. **Login to Azure**:
   ```bash
   az login
   az account set --subscription "YOUR_SUBSCRIPTION_ID"
   ```

---

## 🎯 One-Command Deployment

### Step 1: Clone Repository
```bash
git clone https://github.com/YOUR_USERNAME/agentic-healthcare-ai.git
cd agentic-healthcare-ai
```

### Step 2: Configure Environment
```bash
# Copy template
cp env.template .env

# Edit with your details
nano .env
```

**Required Variables:**
```bash
AZURE_SUBSCRIPTION_ID="your-subscription-id"
AZURE_LOCATION="eastus"
RESOURCE_GROUP="rg-healthcare-ai"
AZURE_OPENAI_KEY="your-openai-key"
```

### Step 3: Deploy Infrastructure
```bash
# Deploy all Azure resources
./deploy-azure.sh
```

This script will:
- ✅ Create resource group
- ✅ Deploy AKS cluster
- ✅ Deploy Azure Container Registry
- ✅ Deploy Azure OpenAI Service
- ✅ Deploy PostgreSQL, Redis, Cosmos DB
- ✅ Configure monitoring and security
- ✅ Deploy applications to AKS

**Deployment time:** ~20-25 minutes

---

## 🌐 Access Your Application

After deployment completes:

```bash
# Get AKS credentials
az aks get-credentials --resource-group rg-healthcare-ai --name aks-healthcare-ai

# Get application URL
kubectl get service healthcare-ai-ui -n healthcare-ai

# Access the UI
# Navigate to the EXTERNAL-IP shown above
```

**Default endpoints:**
- **UI**: http://EXTERNAL-IP
- **API**: http://EXTERNAL-IP:8000
- **Health Check**: http://EXTERNAL-IP/health

---

## 📊 Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n healthcare-ai

# Expected output:
# NAME                                  READY   STATUS    RESTARTS
# healthcare-ai-ui-xxx                  1/1     Running   0
# healthcare-ai-crewai-xxx              1/1     Running   0
# healthcare-ai-autogen-xxx             1/1     Running   0

# Check services
kubectl get svc -n healthcare-ai

# View logs
kubectl logs -f deployment/healthcare-ai-ui -n healthcare-ai
```

---

## 🔧 Common Commands

### View Application Logs
```bash
# UI logs
kubectl logs -f deployment/healthcare-ai-ui -n healthcare-ai

# CrewAI agent logs
kubectl logs -f deployment/healthcare-ai-crewai -n healthcare-ai

# Autogen agent logs
kubectl logs -f deployment/healthcare-ai-autogen -n healthcare-ai
```

### Scale Application
```bash
# Scale UI to 5 replicas
kubectl scale deployment healthcare-ai-ui --replicas=5 -n healthcare-ai

# Auto-scaling is already configured (3-20 pods)
kubectl get hpa -n healthcare-ai
```

### Update Application
```bash
# Build and push new image
az acr build --registry YOUR_ACR_NAME --image healthcare-ai-ui:v2 ./ui

# Update deployment
kubectl set image deployment/healthcare-ai-ui healthcare-ai-ui=YOUR_ACR_NAME.azurecr.io/healthcare-ai-ui:v2 -n healthcare-ai
```

---

## 🔐 Security Setup

### Enable Azure AD Authentication
```bash
# Create Azure AD app registration
az ad app create --display-name "Healthcare AI Platform"

# Configure RBAC
kubectl create clusterrolebinding healthcare-ai-admin \
  --clusterrole=cluster-admin \
  --user=YOUR_EMAIL@domain.com
```

### Configure Secrets
```bash
# Create Kubernetes secrets
kubectl create secret generic healthcare-ai-secrets \
  --from-literal=azure-openai-key="YOUR_KEY" \
  --from-literal=database-password="YOUR_PASSWORD" \
  -n healthcare-ai
```

---

## 💰 Cost Estimation

**Monthly costs (production):**
- AKS: $500-1,000
- Azure OpenAI: $1,000-2,000
- Databases: $500-800
- **Total: ~$2,000-3,800/month**

**Development costs:**
- Use smaller VM sizes
- Single-region deployment
- **Total: ~$500-800/month**

---

## 🛠️ Troubleshooting

### Pods Not Starting
```bash
# Describe pod to see errors
kubectl describe pod POD_NAME -n healthcare-ai

# Check events
kubectl get events -n healthcare-ai --sort-by='.lastTimestamp'
```

### Can't Access Application
```bash
# Check service status
kubectl get svc healthcare-ai-ui -n healthcare-ai

# Check ingress
kubectl get ingress -n healthcare-ai

# Port forward for testing
kubectl port-forward svc/healthcare-ai-ui 3030:80 -n healthcare-ai
# Access at http://localhost:3030
```

### Database Connection Issues
```bash
# Test PostgreSQL connection
kubectl run -it --rm psql-test --image=postgres:15 --restart=Never -- \
  psql -h YOUR_POSTGRES_HOST -U healthcareadmin -d healthcare_ai

# Test Redis connection
kubectl run -it --rm redis-test --image=redis:7 --restart=Never -- \
  redis-cli -h YOUR_REDIS_HOST -p 6380 --tls ping
```

---

## 🧹 Cleanup

### Delete Everything
```bash
# Delete resource group (removes all resources)
az group delete --name rg-healthcare-ai --yes --no-wait

# This will delete:
# - AKS cluster
# - Container Registry
# - Databases
# - All other Azure resources
```

### Delete Just the Application
```bash
# Keep infrastructure, remove app
kubectl delete namespace healthcare-ai
```

---

## 📚 Next Steps

1. **Configure Custom Domain**
   - Set up Azure Front Door
   - Configure SSL certificate
   - Update DNS records

2. **Enable Monitoring**
   - View Application Insights dashboard
   - Set up custom alerts
   - Configure log queries

3. **Deploy to Production**
   - Use Azure DevOps pipeline
   - Enable multi-region deployment
   - Configure disaster recovery

4. **Customize Application**
   - Modify agent configurations
   - Add custom FHIR resources
   - Integrate with EHR systems

---

## 🆘 Get Help

- **Documentation**: See `docs/` folder
- **Issues**: Open GitHub issue
- **Azure Support**: https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade

---

## ✅ Success Checklist

After deployment, verify:

- [ ] All pods are running (`kubectl get pods -n healthcare-ai`)
- [ ] Services have external IPs (`kubectl get svc -n healthcare-ai`)
- [ ] UI is accessible in browser
- [ ] API health check returns 200 OK
- [ ] Application Insights shows telemetry
- [ ] No errors in pod logs

**Congratulations! Your Azure Healthcare AI Platform is live! 🎉**
