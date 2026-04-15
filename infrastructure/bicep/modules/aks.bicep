@description('The name of the AKS cluster')
param name string

@description('The location of the AKS cluster')
param location string

@description('Tags to apply to the resource')
param tags object

@description('Kubernetes version')
param kubernetesVersion string

@description('DNS prefix for the cluster')
param dnsPrefix string

@description('Enable RBAC')
param enableRBAC bool = true

@description('Enable Azure Policy')
param enableAzurePolicy bool = true

@description('Enable Secret Store CSI Driver')
param enableSecretStoreCSIDriver bool = true

@description('Network plugin')
param networkPlugin string = 'azure'

@description('Network policy')
param networkPolicy string = 'azure'

@description('Load balancer SKU')
param loadBalancerSku string = 'standard'

@description('Outbound type')
param outboundType string = 'loadBalancer'

@description('System node pool configuration')
param systemNodePool object

@description('User node pools configuration')
param userNodePools array = []

@description('ACR resource ID for integration')
param acrId string

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

resource aks 'Microsoft.ContainerService/managedClusters@2023-10-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: dnsPrefix
    enableRBAC: enableRBAC
    networkProfile: {
      networkPlugin: networkPlugin
      networkPolicy: networkPolicy
      loadBalancerSku: loadBalancerSku
      outboundType: outboundType
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
    }
    agentPoolProfiles: [
      {
        name: systemNodePool.name
        count: systemNodePool.count
        vmSize: systemNodePool.vmSize
        mode: systemNodePool.mode
        osType: systemNodePool.osType
        availabilityZones: systemNodePool.?availabilityZones ?? []
        enableAutoScaling: systemNodePool.enableAutoScaling
        minCount: systemNodePool.?minCount
        maxCount: systemNodePool.?maxCount
        type: 'VirtualMachineScaleSets'
        enableNodePublicIP: false
        maxPods: 110
      }
    ]
    addonProfiles: {
      azurepolicy: {
        enabled: enableAzurePolicy
      }
      azureKeyvaultSecretsProvider: {
        enabled: enableSecretStoreCSIDriver
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
    }
    autoScalerProfile: {
      'scale-down-delay-after-add': '10m'
      'scale-down-unneeded-time': '10m'
      'scale-down-utilization-threshold': '0.5'
    }
    securityProfile: {
      defender: {
        securityMonitoring: {
          enabled: true
        }
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
    workloadAutoScalerProfile: {
      keda: {
        enabled: true
      }
    }
  }
}

// Additional user node pools
resource userNodePool 'Microsoft.ContainerService/managedClusters/agentPools@2023-10-01' = [for pool in userNodePools: {
  parent: aks
  name: pool.name
  properties: {
    count: pool.count
    vmSize: pool.vmSize
    mode: pool.mode
    osType: pool.osType
    availabilityZones: pool.?availabilityZones ?? []
    enableAutoScaling: pool.enableAutoScaling
    minCount: pool.?minCount
    maxCount: pool.?maxCount
    type: 'VirtualMachineScaleSets'
    enableNodePublicIP: false
    maxPods: 110
    nodeLabels: pool.?nodeLabels
    nodeTaints: pool.?nodeTaints
  }
}]

// ACR Pull Role Assignment
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aks.id, acrId, 'AcrPull')
  scope: resourceId('Microsoft.ContainerRegistry/registries', last(split(acrId, '/')))
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}

output id string = aks.id
output name string = aks.name
output fqdn string = aks.properties.fqdn
output kubeletIdentityObjectId string = aks.properties.identityProfile.kubeletidentity.objectId
output oidcIssuerUrl string = aks.properties.oidcIssuerProfile.issuerURL
