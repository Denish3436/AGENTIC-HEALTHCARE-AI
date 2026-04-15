@description('The name of the key vault')
param name string

@description('The location of the key vault')
param location string

@description('Tags to apply to the resource')
param tags object

@description('Enable for deployment')
param enabledForDeployment bool = true

@description('Enable for template deployment')
param enabledForTemplateDeployment bool = true

@description('Enable RBAC authorization')
param enableRbacAuthorization bool = true

@description('Enable purge protection')
param enablePurgeProtection bool = true

@description('Enable soft delete')
param enableSoftDelete bool = true

@description('Network ACLs')
param networkAcls object = {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'premium'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enableRbacAuthorization: enableRbacAuthorization
    enablePurgeProtection: enablePurgeProtection
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: 90
    networkAcls: networkAcls
    publicNetworkAccess: 'Disabled'
  }
}

output id string = keyVault.id
output name string = keyVault.name
output uri string = keyVault.properties.vaultUri
