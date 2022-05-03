param location string = resourceGroup().location

module cosmos 'deploy-cosmos.bicep' = {
  name: 'jjcosmos'
  params:{
    location: location
    cosmosName: 'jjcosmos'
  }
}

// module st 'deploy-storage.bicep' = {
//   name: 'jjstoragedapr'
//   params:{
//     stName: 'jjstoragedapr'
//   }
// }

module sb 'deploy-sb.bicep' = {
  name: 'jjsbus'
  params:{
    location: location
    sbName: 'jjsbus'
  }
}

module app 'deploy-app.bicep' = {
  name: 'jjapp'
  params: {
    location: location
    appName: 'jjarticlevoting'
    imageRegistryName: 'jjakscontainers'
    imageArticles: 'api-articles:v1'
    imageVotes: 'api-votes:v1'
    imageUi: 'ui-votes:v1'
    cosmosAccountName: cosmos.outputs.cosmosAccountName
    sbNamespaceName: sb.outputs.sbNamespaceName
    //stAccountName: st.outputs.stAccountName   // use is for storage account state store
  }
}
