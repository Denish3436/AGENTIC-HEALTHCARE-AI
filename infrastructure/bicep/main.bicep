targetScope = 'subscription'

@description('The environment name (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'prod'

@description('The primary Azure region for resources')
param location string = 'eastus'

@description('The secondary Azure region for disaster recovery')
param secondaryLocation string = 'westus2'

@description('The name prefix for all resources')
param namePrefix string = 'healthcare-ai'

@description('Azure OpenAI Service deployment name')
param openAIDeploymentName string = 'gpt-4'

@description('Enable Azure Monitor and Application Insights')
param enableMonitoring bool = true

@description('Enable Azure Security Center')
param enableSecurityCenter bool = true

@description('Tags to apply to all resources')
param tags object = {
  Environment: environment
  Project: 'Healthcare-AI'
  ManagedBy: 'Azure-DevOps'
  CostCenter: 'Healthcare-Innovation'
  Compliance: 'HIPAA'
}

var resourceGroupName = 'rg-${namePrefix}-${environment}'
var aksClusterName = 'aks-${namePrefix}-${environment}'
var acrName = replace('acr${namePrefix}${environment}', '-', '')
var keyVaultName = 'kv-${namePrefix}-${environment}'
var appInsightsName = 'ai-${namePrefix}-${environment}'
var logAnalyticsName = 'la-${namePrefix}-${environment}'
var cosmosDbName = 'cosmos-${namePrefix}-${environment}'
var postgresName = 'psql-${namePrefix}-${environment}'
var redisName = 'redis-${namePrefix}-${environment}'
var openAIName = 'openai-${namePrefix}-${environment}'
var healthDataName = 'health-${namePrefix}-${environment}'
var frontDoorName = 'fd-${namePrefix}-${environment}'
var apiManagementName = 'apim-${namePrefix}-${environment}'

// Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Log Analytics Workspace
module logAnalytics 'modules/log-analytics.bicep' = {
  scope: resourceGroup
  name: 'logAnalytics'
  params: {
    name: logAnalyticsName
    location: location
    tags: tags
    retentionInDays: environment == 'prod' ? 90 : 30
  }
}

// Application Insights
module appInsights 'modules/app-insights.bicep' = if (enableMonitoring) {
  scope: resourceGroup
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
    tags: tags
    workspaceResourceId: logAnalytics.outputs.id
  }
}

// Azure Key Vault
module keyVault 'modules/key-vault.bicep' = {
  scope: resourceGroup
  name: 'keyVault'
  params: {
    name: keyVaultName
    location: location
    tags: tags
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// Azure Container Registry
module acr 'modules/container-registry.bicep' = {
  scope: resourceGroup
  name: 'containerRegistry'
  params: {
    name: acrName
    location: location
    tags: tags
    sku: environment == 'prod' ? 'Premium' : 'Standard'
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
    zoneRedundancy: environment == 'prod' ? 'Enabled' : 'Disabled'
  }
}

// Azure Kubernetes Service
module aks 'modules/aks.bicep' = {
  scope: resourceGroup
  name: 'aksCluster'
  params: {
    name: aksClusterName
    location: location
    tags: tags
    kubernetesVersion: '1.28.3'
    dnsPrefix: '${namePrefix}-${environment}'
    enableRBAC: true
    enableAzurePolicy: true
    enableSecretStoreCSIDriver: true
    networkPlugin: 'azure'
    networkPolicy: 'azure'
    loadBalancerSku: 'standard'
    outboundType: 'loadBalancer'
    systemNodePool: {
      name: 'system'
      count: environment == 'prod' ? 3 : 2
      vmSize: environment == 'prod' ? 'Standard_D4s_v3' : 'Standard_D2s_v3'
      mode: 'System'
      osType: 'Linux'
      availabilityZones: environment == 'prod' ? ['1', '2', '3'] : []
      enableAutoScaling: true
      minCount: environment == 'prod' ? 3 : 2
      maxCount: environment == 'prod' ? 10 : 5
    }
    userNodePools: [
      {
        name: 'apps'
        count: environment == 'prod' ? 3 : 2
        vmSize: environment == 'prod' ? 'Standard_D8s_v3' : 'Standard_D4s_v3'
        mode: 'User'
        osType: 'Linux'
        availabilityZones: environment == 'prod' ? ['1', '2', '3'] : []
        enableAutoScaling: true
        minCount: environment == 'prod' ? 3 : 2
        maxCount: environment == 'prod' ? 20 : 10
        nodeLabels: {
          workload: 'healthcare-ai'
        }
        nodeTaints: []
      }
    ]
    acrId: acr.outputs.id
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

// Azure Cosmos DB
module cosmosDb 'modules/cosmos-db.bicep' = {
  scope: resourceGroup
  name: 'cosmosDb'
  params: {
    name: cosmosDbName
    location: location
    tags: tags
    locations: environment == 'prod' ? [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: true
      }
      {
        locationName: secondaryLocation
        failoverPriority: 1
        isZoneRedundant: true
      }
    ] : [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseName: 'healthcare-ai'
    containers: [
      {
        name: 'conversations'
        partitionKey: '/patientId'
        throughput: environment == 'prod' ? 1000 : 400
      }
      {
        name: 'assessments'
        partitionKey: '/assessmentId'
        throughput: environment == 'prod' ? 1000 : 400
      }
      {
        name: 'audit-logs'
        partitionKey: '/userId'
        throughput: environment == 'prod' ? 1000 : 400
      }
    ]
  }
}

// Azure Database for PostgreSQL
module postgres 'modules/postgresql.bicep' = {
  scope: resourceGroup
  name: 'postgresql'
  params: {
    name: postgresName
    location: location
    tags: tags
    administratorLogin: 'healthcareadmin'
    version: '15'
    skuName: environment == 'prod' ? 'Standard_D4s_v3' : 'Standard_D2s_v3'
    storageSizeGB: environment == 'prod' ? 512 : 128
    backupRetentionDays: environment == 'prod' ? 35 : 7
    geoRedundantBackup: environment == 'prod' ? 'Enabled' : 'Disabled'
    highAvailability: environment == 'prod' ? 'ZoneRedundant' : 'Disabled'
  }
}

// Azure Cache for Redis
module redis 'modules/redis.bicep' = {
  scope: resourceGroup
  name: 'redis'
  params: {
    name: redisName
    location: location
    tags: tags
    sku: environment == 'prod' ? 'Premium' : 'Standard'
    capacity: environment == 'prod' ? 1 : 1
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
  }
}

// Azure OpenAI Service
module openAI 'modules/openai.bicep' = {
  scope: resourceGroup
  name: 'openAI'
  params: {
    name: openAIName
    location: 'eastus'
    tags: tags
    sku: 'S0'
    deployments: [
      {
        name: 'gpt-4'
        model: {
          format: 'OpenAI'
          name: 'gpt-4'
          version: '0613'
        }
        scaleSettings: {
          scaleType: 'Standard'
        }
      }
      {
        name: 'gpt-35-turbo'
        model: {
          format: 'OpenAI'
          name: 'gpt-35-turbo'
          version: '0613'
        }
        scaleSettings: {
          scaleType: 'Standard'
        }
      }
      {
        name: 'text-embedding-ada-002'
        model: {
          format: 'OpenAI'
          name: 'text-embedding-ada-002'
          version: '2'
        }
        scaleSettings: {
          scaleType: 'Standard'
        }
      }
    ]
    publicNetworkAccess: 'Disabled'
  }
}

// Azure Health Data Services
module healthData 'modules/health-data-services.bicep' = {
  scope: resourceGroup
  name: 'healthDataServices'
  params: {
    name: healthDataName
    location: location
    tags: tags
    fhirServiceName: 'fhir-${namePrefix}-${environment}'
    fhirVersion: 'R4'
    authenticationAuthority: 'https://login.microsoftonline.com/${tenant().tenantId}'
    authenticationAudience: 'https://${healthDataName}.fhir.azurehealthcareapis.com'
  }
}

// Azure API Management
module apiManagement 'modules/api-management.bicep' = {
  scope: resourceGroup
  name: 'apiManagement'
  params: {
    name: apiManagementName
    location: location
    tags: tags
    sku: environment == 'prod' ? 'Premium' : 'Developer'
    skuCapacity: environment == 'prod' ? 2 : 1
    publisherEmail: 'devops@healthcare-ai.com'
    publisherName: 'Healthcare AI Platform'
    virtualNetworkType: environment == 'prod' ? 'Internal' : 'None'
  }
}

// Azure Front Door
module frontDoor 'modules/front-door.bicep' = if (environment == 'prod') {
  scope: resourceGroup
  name: 'frontDoor'
  params: {
    name: frontDoorName
    tags: tags
    backendPools: [
      {
        name: 'healthcare-ai-backend'
        backends: [
          {
            address: '${aksClusterName}.${location}.cloudapp.azure.com'
            httpPort: 80
            httpsPort: 443
            priority: 1
            weight: 100
          }
        ]
      }
    ]
    enableWAF: true
    wafMode: 'Prevention'
  }
}

// Outputs
output resourceGroupName string = resourceGroup.name
output aksClusterName string = aks.outputs.name
output acrLoginServer string = acr.outputs.loginServer
output keyVaultUri string = keyVault.outputs.uri
output appInsightsInstrumentationKey string = enableMonitoring ? appInsights.outputs.instrumentationKey : ''
output cosmosDbEndpoint string = cosmosDb.outputs.endpoint
output postgresServerFqdn string = postgres.outputs.fqdn
output redisHostName string = redis.outputs.hostName
output openAIEndpoint string = openAI.outputs.endpoint
output healthDataFhirUrl string = healthData.outputs.fhirServiceUrl
output apiManagementGatewayUrl string = apiManagement.outputs.gatewayUrl
output frontDoorEndpoint string = environment == 'prod' ? frontDoor.outputs.endpoint : ''
