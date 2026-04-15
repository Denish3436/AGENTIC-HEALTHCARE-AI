@description('The name of the PostgreSQL server')
param name string

@description('The location of the resource')
param location string

@description('Tags to apply to the resource')
param tags object

@description('Administrator login')
@secure()
param administratorLogin string

@description('PostgreSQL version')
param version string = '15'

@description('SKU name')
param skuName string = 'Standard_D4s_v3'

@description('Storage size in GB')
param storageSizeGB int = 128

@description('Backup retention days')
param backupRetentionDays int = 7

@description('Geo-redundant backup')
param geoRedundantBackup string = 'Disabled'

@description('High availability mode')
param highAvailability string = 'Disabled'

resource postgresql 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: 'GeneralPurpose'
  }
  properties: {
    version: version
    administratorLogin: administratorLogin
    storage: {
      storageSizeGB: storageSizeGB
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    highAvailability: {
      mode: highAvailability
    }
    network: {
      publicNetworkAccess: 'Disabled'
    }
  }
}

resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-03-01-preview' = {
  parent: postgresql
  name: 'healthcare_ai'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

output id string = postgresql.id
output name string = postgresql.name
output fqdn string = postgresql.properties.fullyQualifiedDomainName
