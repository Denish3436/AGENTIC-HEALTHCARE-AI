@description('The name of the Front Door')
param name string

@description('Tags to apply to the resource')
param tags object

@description('Backend pools configuration')
param backendPools array

@description('Enable WAF')
param enableWAF bool = true

@description('WAF mode')
@allowed([
  'Detection'
  'Prevention'
])
param wafMode string = 'Prevention'

resource frontDoor 'Microsoft.Network/frontDoors@2021-06-01' = {
  name: name
  location: 'global'
  tags: tags
  properties: {
    enabledState: 'Enabled'
    frontendEndpoints: [
      {
        name: 'defaultFrontend'
        properties: {
          hostName: '${name}.azurefd.net'
          sessionAffinityEnabledState: 'Disabled'
          webApplicationFirewallPolicyLink: enableWAF ? {
            id: wafPolicy.id
          } : null
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: 'loadBalancingSettings1'
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
          additionalLatencyMilliseconds: 0
        }
      }
    ]
    healthProbeSettings: [
      {
        name: 'healthProbeSettings1'
        properties: {
          path: '/health'
          protocol: 'Https'
          intervalInSeconds: 30
          healthProbeMethod: 'GET'
          enabledState: 'Enabled'
        }
      }
    ]
    backendPools: [for pool in backendPools: {
      name: pool.name
      properties: {
        backends: pool.backends
        loadBalancingSettings: {
          id: resourceId('Microsoft.Network/frontDoors/loadBalancingSettings', name, 'loadBalancingSettings1')
        }
        healthProbeSettings: {
          id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', name, 'healthProbeSettings1')
        }
      }
    }]
    routingRules: [
      {
        name: 'routingRule1'
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/frontendEndpoints', name, 'defaultFrontend')
            }
          ]
          acceptedProtocols: [
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'HttpsOnly'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/backendPools', name, backendPools[0].name)
            }
          }
          enabledState: 'Enabled'
        }
      }
    ]
  }
}

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' = if (enableWAF) {
  name: '${name}wafpolicy'
  location: 'global'
  tags: tags
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: wafMode
      customBlockResponseStatusCode: 403
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
          ruleSetAction: 'Block'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
    }
  }
}

output id string = frontDoor.id
output name string = frontDoor.name
output endpoint string = frontDoor.properties.frontendEndpoints[0].properties.hostName
