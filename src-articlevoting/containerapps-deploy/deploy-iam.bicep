
param identityId string
param identityPrincipalId string
param roleId string

targetScope = 'subscription'

resource acrRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, identityId, roleId)
  properties: {
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleId
  }
}
