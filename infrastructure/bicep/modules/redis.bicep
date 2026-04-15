@description('The name of the Redis cache')
param name string

@description('The location of the resource')
param location string

@description('Tags to apply to the resource')
param tags object

@description('Redis SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Premium'

@description('SKU capacity')
param capacity int = 1

@description('Enable non-SSL port')
param enableNonSslPort bool = false

@description('Minimum TLS version')
param minimumTlsVersion string = '1.2'

@description('Redis configuration')
param redisConfiguration object = {}

resource redis 'Microsoft.Cache/redis@2023-08-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
      family: sku == 'Premium' ? 'P' : 'C'
      capacity: capacity
    }
    enableNonSslPort: enableNonSslPort
    minimumTlsVersion: minimumTlsVersion
    redisConfiguration: redisConfiguration
    publicNetworkAccess: 'Disabled'
    redisVersion: '6'
  }
}

output id string = redis.id
output name string = redis.name
output hostName string = redis.properties.hostName
output sslPort int = redis.properties.sslPort
