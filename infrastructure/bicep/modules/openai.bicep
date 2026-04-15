@description('The name of the Azure OpenAI service')
param name string

@description('The location of the resource')
param location string

@description('Tags to apply to the resource')
param tags object

@description('SKU name')
param sku string = 'S0'

@description('Model deployments')
param deployments array = []

@description('Public network access')
param publicNetworkAccess string = 'Disabled'

resource openAI 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for item in deployments: {
  parent: openAI
  name: item.name
  sku: {
    name: 'Standard'
    capacity: 120
  }
  properties: {
    model: item.model
    scaleSettings: item.scaleSettings
  }
}]

output id string = openAI.id
output name string = openAI.name
output endpoint string = openAI.properties.endpoint
