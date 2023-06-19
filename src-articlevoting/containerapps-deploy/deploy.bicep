param location string = resourceGroup().location

module cosmos 'deploy-cosmos.bicep' = {
  name: 'jjcosmos'
  params:{
    location: location
    cosmosName: 'jjcosmos${uniqueString(resourceGroup().id)}'
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
    imageRegistryName: 'jjazacr'
    imageRegistryResourceGroupName: 'jjmicroservices-rg'
    imageArticles: 'api-articles:v1'
    imageVotes: 'api-votes:v1'
    imageUiBase: 'ui-votes'
    imageUiTagOld: 'v1'
    imageUiTagNew: 'v1'
    //imageUiTagNew: 'v2'
    cosmosAccountName: cosmos.outputs.cosmosAccountName
    sbNamespaceName: sb.outputs.sbNamespaceName
    logResourceGroupName: 'jjinfra-rg'
    logName: 'jjazworkspace'
  }
}
