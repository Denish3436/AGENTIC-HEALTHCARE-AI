@description('The name of the API Management service')
param name string

@description('The location of the resource')
param location string

@description('Tags to apply to the resource')
param tags object

@description('SKU name')
@allowed([
  'Developer'
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Developer'

@description('SKU capacity')
param skuCapacity int = 1

@description('Publisher email')
param publisherEmail string

@description('Publisher name')
param publisherName string

@description('Virtual network type')
@allowed([
  'None'
  'External'
  'Internal'
])
param virtualNetworkType string = 'None'

resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
    capacity: skuCapacity
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: virtualNetworkType
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'False'
    }
  }
}

output id string = apiManagement.id
output name string = apiManagement.name
output gatewayUrl string = apiManagement.properties.gatewayUrl
