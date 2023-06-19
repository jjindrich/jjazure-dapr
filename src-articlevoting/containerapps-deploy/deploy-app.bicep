param appName string = 'jjarticlevoting'
param envName string = '${appName}-env'
param imageRegistryName string
param imageRegistryResourceGroupName string = 'jjinfra-rg'
param imageArticles string
param imageVotes string
param imageUiBase string
param imageUiTagNew string
param imageUiTagOld string

param cosmosAccountName string
param sbNamespaceName string

param logName string = 'jjazworkspace'
param logResourceGroupName string = 'jjinfra-rg'

param location string = resourceGroup().location

// Reference existing resources:
//    - Log Analytics workspace
//    - Container Registry
//    - Cosmos DB account
//    - ServiceBus namespace with topic
resource log 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logName
  scope: resourceGroup(logResourceGroupName)
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${appName}-appinsights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: log.id
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2022-12-01' existing = {
  name: imageRegistryName
  scope: resourceGroup(imageRegistryResourceGroupName)
}
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' existing = {
  name: cosmosAccountName
} 

resource sbNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: sbNamespaceName
}
resource sbAuthorization 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' = {
  name: 'RootManageSharedAccessKey'
  parent: sbNamespace
  properties: {
    rights: [
      'Listen'
      'Send'
      'Manage'
    ]
  }
}

// Identity to access ACR
resource acaIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${envName}-acr-identity'
  location: location
}
var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
module acaRole 'deploy-iam.bicep' = {
  name: 'aca-role'
  scope: subscription()
  params: {
    roleId: acrPullRole
    identityId: acaIdentity.id
    identityPrincipalId: acaIdentity.properties.principalId    
  }
}

// Create Container App Environment
resource env 'Microsoft.App/managedEnvironments@2022-10-01' = {
  name: envName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: log.properties.customerId
        sharedKey: log.listKeys().primarySharedKey
      }      
    }
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
  }  
  resource daprStateArticles 'daprComponents@2022-10-01' = {
    name: 'jjstate-articles'
    properties: {
      componentType: 'state.azure.cosmosdb'
      version: 'v1'
      ignoreErrors: false
      initTimeout: '5s'
      secrets: [
        {
          name: 'cosmos-key'
          value: cosmosAccount.listKeys().primaryMasterKey
        }        
      ]
      metadata: [
        {
          name: 'url'
          value: cosmosAccount.properties.documentEndpoint
        }
        {
          name: 'masterKey'
          secretRef: 'cosmos-key'
        }
        {
          name: 'database'
          value: 'jjdb'
        }
        {
          name: 'collection'
          value: 'articles'
        }
      ]
      scopes: [
        'app-articles'
      ]
    }
  }
  resource daprStateVotes 'daprComponents@2022-10-01' = {
    name: 'jjstate-votes'
    properties: {
      componentType: 'state.azure.cosmosdb'
      version: 'v1'
      ignoreErrors: false
      initTimeout: '5s'
      secrets: [
        {
          name: 'cosmos-key'
          value: cosmosAccount.listKeys().primaryMasterKey
        }        
      ]
      metadata: [
        {
          name: 'url'
          value: cosmosAccount.properties.documentEndpoint
        }
        {
          name: 'masterKey'
          secretRef: 'cosmos-key'
        }
        {
          name: 'database'
          value: 'jjdb'
        }
        {
          name: 'collection'
          value: 'votes'
        }
      ]
      scopes: [
        'app-votes'
      ]
    }
  }
  resource daprPubSub 'daprComponents@2022-10-01' = {
    name: 'pubsub'
    properties: {
      componentType: 'pubsub.azure.servicebus'
      version: 'v1'
      ignoreErrors: false
      initTimeout: '5s'
      secrets: [
        {
          name: 'sb-conn'
          value: sbAuthorization.listKeys().primaryConnectionString 
        }        
      ]
      metadata: [
        {
          name: 'connectionString'
          secretRef: 'sb-conn'
        }
      ]
      scopes: [
        'app-articles'
        'app-votes'
      ]
    }
  }
  // TODO: refactor to use Storage account as daprComponents
}

// Create Container App: Articles
resource appArticles 'Microsoft.App/containerApps@2022-10-01' = {
  name: '${appName}-articles'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${acaIdentity.id}': {}
    }
  }  
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      secrets: []
      registries: [
        { 
          server: '${imageRegistryName}.azurecr.io'
          identity: acaIdentity.id
        }
      ]      
      dapr: {
        enabled: true
        appPort: 5005  
        appId: 'app-articles'        
      }
    }
    template: {
      containers: [
        {
          image: '${acr.properties.loginServer}/${imageArticles}'
          name: 'app-articles'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
      
    }
  }
}

// Create Container App: Votes
resource appVotes 'Microsoft.App/containerApps@2022-10-01' = {
  name: '${appName}-votes'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${acaIdentity.id}': {}
    }
  }  
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
      secrets: []
      registries: [
        {
          server: '${imageRegistryName}.azurecr.io'
          identity: acaIdentity.id
        }
      ]
      dapr: {
        enabled: true
        appPort: 80
        appId: 'app-votes'
      }
    }
    template: {
      containers: [
        {
          image: '${acr.properties.loginServer}/${imageVotes}'
          name: 'app-votes'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
}

// Create Container App: Ui
resource appUi 'Microsoft.App/containerApps@2022-10-01' = {
  name: '${appName}-ui'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${acaIdentity.id}': {}
    }
  }    
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      activeRevisionsMode: 'multiple'
      ingress: {
        external: true
        targetPort: 80
        traffic: [
          {
            latestRevision: true            
            weight: 80         
          }
          {
            revisionName: '${appName}-ui--${imageUiTagOld}'
            weight: 20
          }
        ]
      }
      secrets: []
      registries: [
        {
          server: '${imageRegistryName}.azurecr.io'
          identity: acaIdentity.id
        }
      ]
      dapr: {
        enabled: true
        appPort: 80
        appId: 'ui-votes'
      }
    }
    template: {
      revisionSuffix: imageUiTagNew
      containers: [
        {
          image: '${acr.properties.loginServer}/${imageUiBase}:${imageUiTagNew}'
          name: 'ui-votes'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
}
