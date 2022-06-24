param location string = resourceGroup().location

module cosmos 'deploy-cosmos.bicep' = {
  name: 'jjcosmos'
  params:{
    location: location
    cosmosName: 'jjcosmos'
  }
}

module sb 'deploy-sb.bicep' = {
  name: 'jjsbus'
  params:{
    location: location
    sbName: 'jjsbus'
  }
}

module appv1 'deploy-app.bicep' = {
  name: 'jjappv1'
  params: {
    location: location
    appName: 'jjarticlevoting'
    vnetId: '/subscriptions/82fb79bf-ee69-4a57-a76c-26153e544afe/resourceGroups/JJDevV2-Infra/providers/Microsoft.Network/virtualNetworks/JJDevV2NetworkApp/subnets/DmzContainerApp'
    imageRegistryName: 'jjakscontainers'
    imageArticles: 'api-articles:v1'
    imageVotes: 'api-votes:v1'
    imageUiBase: 'ui-votes'
    imageUiTagOld: 'v1'
    //imageUiTagNew: 'v1'
    imageUiTagNew: 'v2'
    cosmosAccountName: cosmos.outputs.cosmosAccountName
    sbNamespaceName: sb.outputs.sbNamespaceName
  }
}
