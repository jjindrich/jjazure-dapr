
param imageRegistryName string

param identityId string
param identityPrincipalId string
param roleId string

targetScope = 'resourceGroup'

resource acr 'Microsoft.ContainerRegistry/registries@2022-12-01' existing = {
  name: imageRegistryName
}

resource acrRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, identityId, roleId)
  scope: acr
  properties: {
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleId
  }
}

output acrLoginServer string = acr.properties.loginServer
