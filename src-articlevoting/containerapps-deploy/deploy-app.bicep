param appName string = 'jjarticlevoting'
param envName string = '${appName}-env'
param imageRegistryName string
param imageArticles string
param imageVotes string
param imageUi string

param cosmosAccountName string
param sbNamespaceName string
//param stAccountName string

param logName string = 'jjdev-analytics'
param logResourceGroupName string = 'jjdevmanagement'

param location string = resourceGroup().location

// Reference existing resources:
//    - Log Analytics workspace
//    - Container Registry
//    - Cosmos DB account
//    - ServiceBus namespace with topic
//    - Storage account
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

resource acr 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: imageRegistryName
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' existing = {
  name: cosmosAccountName
} 

resource sbNamespace 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: sbNamespaceName
}
resource sbAuthorization 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-06-01-preview' = {
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

// resource stAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
//   name: stAccountName
// }

// Create Container App Environment
resource env 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
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
    daprAIInstrumentationKey: reference(appInsights.id, '2020-02-02').InstrumentationKey
    /*
    vnetConfiguration: {
      infrastructureSubnetId: '/subscriptions/82fb79bf-ee69-4a57-a76c-26153e544afe/resourceGroups/JJDevV2-Infra/providers/Microsoft.Network/virtualNetworks/JJDevV2NetworkApp/subnets/DmzContainerAppInfra'      
      runtimeSubnetId: '/subscriptions/82fb79bf-ee69-4a57-a76c-26153e544afe/resourceGroups/JJDevV2-Infra/providers/Microsoft.Network/virtualNetworks/JJDevV2NetworkApp/subnets/DmzContainerApp'      
    }
    */
  }
  resource daprStateArticles 'daprComponents@2022-01-01-preview' = {
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
  resource daprStateVotes 'daprComponents@2022-01-01-preview' = {
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
  resource daprPubSub 'daprComponents@2022-01-01-preview' = {
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
/*
        {
          name: 'storage-key'
          value: stAccount.listKeys().keys[0].value
        }

        {
            name: 'jjstate-articles'
            type: 'state.azure.blobstorage'
            version: 'v1'
            metadata: [
              {
                name: 'accountName'
                value: stAccount.name
              }
              {
                name: 'accountKey'
                secretRef: 'storage-key'
              }
              {
                name: 'containerName'
                value: 'articles'
              }
            ]
          }

          {
            name: 'jjstate-votes'
            type: 'state.azure.blobstorage'
            version: 'v1'
            metadata: [
              {
                name: 'accountName'
                value: stAccount.name
              }
              {
                name: 'accountKey'
                secretRef: 'storage-key'
              }
              {
                name: 'containerName'
                value: 'votes'
              }
            ]
          }
          {
            name: 'pubsub'
            type: 'pubsub.azure.servicebus'
            version: 'v1'
            metadata: [
              {
                name: 'connectionString'
                secretRef: 'sb-conn'
              }
            ]
          }
*/
}

// Create Container App: Articles
resource appArticles 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: '${appName}-articles'
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      secrets: [
        {
          name: 'registry-pwd'          
          value: acr.listCredentials().passwords[0].value
        }
      ]
      registries: [
        { 
          // stopped working: acr.properties.loginServer
          server: '${imageRegistryName}.azurecr.io'
          username: acr.listCredentials().username
          passwordSecretRef: 'registry-pwd'
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
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

// Create Container App: Votes
resource appVotes 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: '${appName}-votes'
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
      secrets: [
        {
          name: 'registry-pwd'          
          value: acr.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          // stopped working: acr.properties.loginServer
          server: '${imageRegistryName}.azurecr.io'
          username: acr.listCredentials().username
          passwordSecretRef: 'registry-pwd'
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
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}


// Create Container App: Ui
resource appUi 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: '${appName}-ui'
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
      secrets: [
        {
          name: 'registry-pwd'          
          value: acr.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          // stopped working: acr.properties.loginServer
          server: '${imageRegistryName}.azurecr.io'
          username: acr.listCredentials().username
          passwordSecretRef: 'registry-pwd'
        }
      ]
      dapr: {
        enabled: true
        appPort: 80
        appId: 'ui-votes'
      }
    }
    template: {
      containers: [
        {
          image: '${acr.properties.loginServer}/${imageUi}'
          name: 'ui-votes'
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
