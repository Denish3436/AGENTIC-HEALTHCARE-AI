@description('The name of the Health Data Services workspace')
param name string

@description('The location of the resource')
param location string

@description('Tags to apply to the resource')
param tags object

@description('FHIR service name')
param fhirServiceName string

@description('FHIR version')
param fhirVersion string = 'R4'

@description('Authentication authority')
param authenticationAuthority string

@description('Authentication audience')
param authenticationAudience string

resource workspace 'Microsoft.HealthcareApis/workspaces@2023-02-28' = {
  name: name
  location: location
  tags: tags
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

resource fhirService 'Microsoft.HealthcareApis/workspaces/fhirservices@2023-02-28' = {
  parent: workspace
  name: fhirServiceName
  location: location
  tags: tags
  kind: 'fhir-R4'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    authenticationConfiguration: {
      authority: authenticationAuthority
      audience: authenticationAudience
      smartProxyEnabled: true
    }
    corsConfiguration: {
      origins: []
      headers: []
      methods: []
      maxAge: 1440
      allowCredentials: false
    }
    exportConfiguration: {
      storageAccountName: ''
    }
    publicNetworkAccess: 'Disabled'
  }
}

output id string = workspace.id
output name string = workspace.name
output fhirServiceId string = fhirService.id
output fhirServiceUrl string = 'https://${workspace.name}-${fhirServiceName}.fhir.azurehealthcareapis.com'
