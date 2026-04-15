# Azure DevOps Best Practices for Healthcare AI Platform

> **Enterprise-grade DevOps practices for healthcare applications on Azure**

## Table of Contents

1. [CI/CD Pipeline Strategy](#cicd-pipeline-strategy)
2. [Infrastructure as Code](#infrastructure-as-code)
3. [Security & Compliance](#security--compliance)
4. [Monitoring & Observability](#monitoring--observability)
5. [Disaster Recovery](#disaster-recovery)
6. [Cost Optimization](#cost-optimization)

---

## CI/CD Pipeline Strategy

### Multi-Stage Pipeline Architecture

Our Azure DevOps pipeline follows a multi-stage approach:

```
┌─────────────┐
│   Build     │ → Compile, Test, Security Scan
└──────┬──────┘
       │
┌──────▼──────┐
│  Dev Deploy │ → Development Environment
└──────┬──────┘
       │
┌──────▼──────┐
│ Stage Deploy│ → Staging Environment
└──────┬──────┘
       │
┌──────▼──────┐
│ Prod Deploy │ → Production (with approvals)
└─────────────┘
```

### Branch Strategy

**GitFlow Model:**

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - New features
- `hotfix/*` - Production fixes
- `release/*` - Release preparation

### Pipeline Triggers

```yaml
# Automated triggers
trigger:
  branches:
    include: [main, develop, release/*]
  paths:
    exclude: [docs/**, README.md]

# Pull request validation
pr:
  branches:
    include: [main, develop]
  paths:
    exclude: [docs/**, README.md]
```

### Build Optimization

**Best Practices:**

1. **Parallel Jobs**: Run independent tasks in parallel
2. **Caching**: Cache dependencies to speed up builds
3. **Incremental Builds**: Only rebuild changed components
4. **Container Layer Caching**: Optimize Docker builds

```yaml
# Example: Parallel job execution
jobs:
  - job: BuildUI
    pool: { vmImage: 'ubuntu-latest' }
  - job: BuildAPI
    pool: { vmImage: 'ubuntu-latest' }
  - job: SecurityScan
    pool: { vmImage: 'ubuntu-latest' }
```

---

## Infrastructure as Code

### Bicep Best Practices

**1. Modular Design**

```bicep
// Use modules for reusability
module aks 'modules/aks.bicep' = {
  name: 'aksDeployment'
  params: {
    name: aksClusterName
    location: location
  }
}
```

**2. Parameter Files**

Separate parameters by environment:
- `parameters.dev.json`
- `parameters.staging.json`
- `parameters.prod.json`

**3. Resource Naming Convention**

```
{resource-type}-{project}-{environment}-{region}

Examples:
- aks-healthcare-ai-prod-eastus
- acr-healthcare-ai-prod
- kv-healthcare-ai-prod-eastus
```

**4. Tagging Strategy**

```bicep
var tags = {
  Environment: environment
  Project: 'Healthcare-AI'
  ManagedBy: 'Azure-DevOps'
  CostCenter: 'Healthcare-Innovation'
  Compliance: 'HIPAA'
  Owner: 'DevOps-Team'
  CreatedDate: utcNow('yyyy-MM-dd')
}
```

### Terraform Alternative

For teams preferring Terraform:

```hcl
# main.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sthealthcareaitfstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

module "aks" {
  source = "./modules/aks"
  
  cluster_name        = var.aks_cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  node_count          = var.node_count
}
```

---

## Security & Compliance

### HIPAA Compliance Checklist

**Administrative Safeguards:**

- ✅ Security Management Process (Azure Security Center)
- ✅ Workforce Security (Azure AD + RBAC)
- ✅ Information Access Management (Conditional Access)
- ✅ Security Awareness Training (Documentation)
- ✅ Security Incident Procedures (Azure Sentinel)

**Physical Safeguards:**

- ✅ Facility Access Controls (Azure Data Centers)
- ✅ Workstation Security (Azure Virtual Desktop)
- ✅ Device and Media Controls (Azure Information Protection)

**Technical Safeguards:**

- ✅ Access Control (Azure AD + MFA)
- ✅ Audit Controls (Azure Monitor + Log Analytics)
- ✅ Integrity Controls (Azure Policy)
- ✅ Transmission Security (TLS 1.2+, Private Endpoints)

### Secret Management

**Azure Key Vault Integration:**

```bash
# Store secrets in Key Vault
az keyvault secret set \
  --vault-name kv-healthcare-ai-prod \
  --name azure-openai-key \
  --value "your-secret-key"

# Reference in Kubernetes
apiVersion: v1
kind: Secret
metadata:
  name: healthcare-ai-secrets
type: Opaque
data:
  azure-openai-key: <from-keyvault>
```

**Pipeline Secret Management:**

```yaml
# Use Azure DevOps variable groups
variables:
  - group: healthcare-ai-secrets
  
steps:
  - task: AzureKeyVault@2
    inputs:
      azureSubscription: 'healthcare-ai-subscription'
      KeyVaultName: 'kv-healthcare-ai-prod'
      SecretsFilter: '*'
```

### Security Scanning

**Multi-Layer Security:**

1. **Code Analysis**: SonarQube, Bandit, ESLint
2. **Dependency Scanning**: Dependabot, Snyk, Safety
3. **Container Scanning**: Trivy, Azure Defender
4. **Infrastructure Scanning**: Checkov, tfsec
5. **Runtime Protection**: Azure Defender for Kubernetes

```yaml
# Security scan stage
- stage: SecurityScan
  jobs:
    - job: CodeAnalysis
      steps:
        - script: bandit -r . -f json -o bandit-report.json
        - script: safety check --json
    
    - job: ContainerScan
      steps:
        - task: AzureCLI@2
          inputs:
            scriptType: bash
            inlineScript: |
              docker run aquasec/trivy image \
                --severity HIGH,CRITICAL \
                $(containerRegistry)/$(imageRepository):$(tag)
```

---

## Monitoring & Observability

### Three Pillars of Observability

**1. Metrics (Azure Monitor)**

```yaml
# Key metrics to track
metrics:
  - name: request_duration_seconds
    type: histogram
    help: "HTTP request duration"
  
  - name: request_total
    type: counter
    help: "Total HTTP requests"
  
  - name: ai_agent_response_time
    type: histogram
    help: "AI agent response time"
  
  - name: fhir_api_calls_total
    type: counter
    help: "Total FHIR API calls"
```

**2. Logs (Log Analytics)**

```kusto
// Query examples
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "ERROR"
| project TimeGenerated, LogEntry, ContainerName
| order by TimeGenerated desc

// Performance analysis
requests
| where timestamp > ago(24h)
| summarize 
    avg(duration), 
    percentile(duration, 95), 
    percentile(duration, 99) 
  by bin(timestamp, 5m)
```

**3. Traces (Application Insights)**

```python
# Distributed tracing example
from opencensus.ext.azure.trace_exporter import AzureExporter
from opencensus.trace.tracer import Tracer

tracer = Tracer(
    exporter=AzureExporter(
        connection_string=os.getenv('APPLICATIONINSIGHTS_CONNECTION_STRING')
    )
)

with tracer.span(name='process_patient_assessment'):
    # Your code here
    pass
```

### Alert Configuration

**Critical Alerts:**

```yaml
alerts:
  - name: HighErrorRate
    condition: error_rate > 5%
    duration: 5m
    severity: critical
    action: page_oncall
  
  - name: HighLatency
    condition: p95_latency > 2s
    duration: 5m
    severity: warning
    action: notify_team
  
  - name: PodCrashLoop
    condition: pod_restart_count > 5
    duration: 10m
    severity: critical
    action: page_oncall
```

### Dashboard Design

**Azure Dashboard Components:**

1. **System Health**: Service availability, error rates
2. **Performance**: Response times, throughput
3. **Business Metrics**: Patient assessments, AI agent usage
4. **Security**: Failed auth attempts, policy violations
5. **Cost**: Resource consumption, budget tracking

---

## Disaster Recovery

### RTO and RPO Targets

| Component | RTO | RPO | Strategy |
|-----------|-----|-----|----------|
| AKS Cluster | 4 hours | 1 hour | Multi-region deployment |
| PostgreSQL | 1 hour | 5 minutes | Geo-replication |
| Cosmos DB | Automatic | 0 | Multi-region writes |
| Redis Cache | 30 minutes | 15 minutes | Zone redundancy |
| Container Images | 15 minutes | 0 | Geo-replication |

### Backup Strategy

**Automated Backups:**

```bash
# AKS backup using Velero
velero backup create healthcare-ai-backup \
  --include-namespaces healthcare-ai \
  --storage-location azure \
  --snapshot-volumes

# Database backups (automated)
az postgres flexible-server backup create \
  --name psql-healthcare-ai-prod \
  --resource-group rg-healthcare-ai-prod \
  --backup-name manual-backup-$(date +%Y%m%d)
```

### Disaster Recovery Testing

**Quarterly DR Drills:**

1. **Failover Test**: Switch to secondary region
2. **Restore Test**: Restore from backup
3. **Data Integrity**: Verify data consistency
4. **Performance Test**: Validate performance in DR mode
5. **Documentation Update**: Update runbooks

---

## Cost Optimization

### Azure Cost Management

**Cost Allocation Tags:**

```bicep
var costTags = {
  CostCenter: 'Healthcare-Innovation'
  Department: 'Engineering'
  Project: 'Healthcare-AI'
  Environment: environment
}
```

**Budget Alerts:**

```bash
# Create budget
az consumption budget create \
  --budget-name healthcare-ai-monthly \
  --amount 10000 \
  --time-grain Monthly \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --resource-group rg-healthcare-ai-prod
```

### Resource Optimization

**1. Right-Sizing:**

- Use Azure Advisor recommendations
- Monitor resource utilization
- Adjust VM sizes based on actual usage

**2. Auto-Scaling:**

```yaml
# HPA configuration
spec:
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

**3. Reserved Instances:**

- Purchase 1-year or 3-year reservations for predictable workloads
- Potential savings: 40-60%

**4. Spot Instances:**

- Use for non-critical batch processing
- Potential savings: up to 90%

### Cost Monitoring Dashboard

**Key Metrics:**

- Daily/Monthly spend by resource
- Cost trends and forecasts
- Budget vs. actual
- Cost per patient assessment
- Cost per API call

---

## Performance Optimization

### AKS Performance Tuning

**Node Pool Configuration:**

```bicep
userNodePools: [
  {
    name: 'apps'
    vmSize: 'Standard_D8s_v3'
    enableAutoScaling: true
    minCount: 3
    maxCount: 20
    nodeLabels: {
      workload: 'healthcare-ai'
      'node.kubernetes.io/instance-type': 'compute-optimized'
    }
  }
]
```

**Resource Requests and Limits:**

```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

### Database Performance

**PostgreSQL Optimization:**

```sql
-- Create indexes for common queries
CREATE INDEX idx_patient_id ON assessments(patient_id);
CREATE INDEX idx_created_at ON assessments(created_at);

-- Enable query performance insights
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
```

**Cosmos DB Optimization:**

- Use appropriate partition keys
- Optimize RU/s allocation
- Implement caching for read-heavy workloads

### Caching Strategy

**Multi-Level Caching:**

1. **Browser Cache**: Static assets (CDN)
2. **API Gateway Cache**: API responses (5 minutes)
3. **Redis Cache**: Session data, FHIR resources (15 minutes)
4. **Application Cache**: In-memory caching for hot data

---

## Continuous Improvement

### DevOps Metrics

**DORA Metrics:**

| Metric | Target | Current |
|--------|--------|---------|
| Deployment Frequency | Daily | Daily |
| Lead Time for Changes | < 1 day | 4 hours |
| Mean Time to Recovery | < 1 hour | 30 minutes |
| Change Failure Rate | < 15% | 10% |

### Retrospectives

**Monthly Review:**

- Pipeline performance analysis
- Security incident review
- Cost optimization opportunities
- Team feedback and improvements

### Knowledge Management

**Documentation Standards:**

- Architecture Decision Records (ADRs)
- Runbooks for common operations
- Troubleshooting guides
- Onboarding documentation

---

## Conclusion

Following these Azure DevOps best practices ensures:

✅ **Reliability**: High availability and disaster recovery  
✅ **Security**: HIPAA compliance and defense in depth  
✅ **Performance**: Optimized resource utilization  
✅ **Cost Efficiency**: Controlled spending with maximum value  
✅ **Agility**: Fast, safe deployments with quick rollback  
✅ **Observability**: Complete visibility into system health  

**Remember**: DevOps is a journey of continuous improvement. Regularly review and update these practices based on lessons learned and evolving requirements.
