param managedIdentityName string
param serviceBusName string
param sqlserverName string
param storageName string
param location string
//param logicApp1Name string
//param logicApp2Name string
//param functionName string

//Service Bus Data Sender and Receiver roles
// See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-service-bus-data-sender
var roleIdS = '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39' // Azure Service Bus Data Sender
// See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-service-bus-data-receiver
var roleIdR = '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0' // Azure Service Bus Data Receiver

var sqlContributorRoleId = '6d8ee4ec-f05a-4a1d-8b00-a9b17e38b437'

var storageContributor = '17d1049b-9a84-46fb-8f53-869881c3d3ab'

// user assigned managed identity to use throughout
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusName
}

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlserverName
}

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageName
}

// Grant permissions to the managedIdentity to specific role to storage account
resource roleAssignmentStorage 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, storageContributor, managedIdentityName)
  scope: storage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageContributor)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal' // managed identity is a form of service principal
  }
  dependsOn: [
    storage
  ]
}

// Grant permissions to the managedIdentity to specific role to sql server
resource roleAssignmentSqlServer 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(sqlServer.id, sqlContributorRoleId, managedIdentityName)
  scope: sqlServer
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', sqlContributorRoleId)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal' // managed identity is a form of service principal
  }
  dependsOn: [
    sqlServer
  ]
}

// Grant permissions to the managedIdentity to specific role to servicebus
resource roleAssignmentReceiver 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(serviceBus.id, roleIdR, managedIdentityName)
  scope: serviceBus
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIdR)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal' // managed identity is a form of service principal
  }
  dependsOn: [
    serviceBus
  ]
}

// Grant permissions to the managedIdentity to specific role to servicebus
resource roleAssignmentSender 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(serviceBus.id, roleIdS, managedIdentityName)
  scope: serviceBus
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIdS)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal' // managed identity is a form of service principal
  }
  dependsOn: [
    serviceBus
  ]
}

output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientlId string = managedIdentity.properties.clientId
output managedIdentityId string = managedIdentity.id
output managedIdentityName string = managedIdentity.name
