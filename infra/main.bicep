targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

//Secure password wirh numbers, leter and special characters
@minLength(8)
@description('SQL Password< Numbers, letters and special characters')
@secure()
param sqlPassword string

// Developer Name
@description('Developer Name')
param developerName string

//ServiceBus 
param serviceBusTopicName string = 'orders'
param serviceBusSubscriptionName string = 'orders'

//Event Grid
//param eventGridTopicName string = 'evt-orders'

//Application Insights
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param logAnalyticsName string = ''

param resourceGroupName string = ''
// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location, developerName))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}-${resourceToken}'
  location: location
  tags: tags
}

// Logic App 1
module logicApp1Resources './app/logicapp.bicep' = {
  name: 'logic-app1'
  scope: rg
  params: {
    location: location
    tags: tags
    userAssignedIdentityId: access.outputs.managedIdentityId
    logicAppName: '${abbrs.logicWorkflows}1-${resourceToken}'
    appServicePlanName: appServicePlanWindowsResources.outputs.name
    storageAccountName: storageResources.outputs.name
    applicationInsightsName: monitoring.outputs.applicationInsightsName
  }
  dependsOn: [
    appServicePlanWindowsResources
  ]
}

// Logic App 2
module logicApp2Resources './app/logicapp.bicep' = {
  name: 'logic-app2'
  scope: rg
  params: {
    location: location
    tags: tags
    userAssignedIdentityId: access.outputs.managedIdentityId
    logicAppName: '${abbrs.logicWorkflows}2-${resourceToken}'
    appServicePlanName: appServicePlanWindowsResources.outputs.name
    storageAccountName: storageResources.outputs.name
    applicationInsightsName: monitoring.outputs.applicationInsightsName
  }
  dependsOn: [
    appServicePlanWindowsResources
  ]
}

// Service Bus
module serviceBusResources './app/servicebus.bicep' = {
  name: 'sb-resources'
  scope: rg
  params: {
    location: location
    tags: tags
    serviceBusName: '${abbrs.serviceBusNamespaces}${resourceToken}'
    skuName: 'Standard'
    subscriptionName: serviceBusSubscriptionName
    topicName: serviceBusTopicName
  }
}

// API Management
/*module apimanagementResources './core/gateway/apim.bicep' = {
  name: 'apim'
  scope: rg
  params: {
    location: location
    tags: tags
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    userAssignedIdentityId: access.outputs.managedIdentityId
    name: '${abbrs.apiManagementService}${resourceToken}'
    sku: 'Developer'
  }
  dependsOn: [
    monitoring
  ]
}*/

module keyVaultResources './core//security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    location: location
    tags: tags
    name: '${abbrs.keyVaultVaults}${resourceToken}'
  }
}

// SQL Database
module databaseResources './core/database/sqlserver/sqlserver.bicep' = {
  name: 'sqlserver'
  scope: rg
  params: {
    location: location
    tags: tags
    name: '${abbrs.sqlServersDatabases}${resourceToken}'
    databaseName: 'db-events'
    keyVaultName: keyVaultResources.outputs.name
    sqlAdminPassword: sqlPassword
    appUserPassword: sqlPassword
    tableName: 'GlobalEvents'
  }
}

// Function App
module functionAppResources './core/host/functions.bicep' = {
  name: 'functions'
  scope: rg
  params: {
    location: location
    tags: tags
    name: '${abbrs.webSitesFunctions}${resourceToken}'
    appServicePlanId: appServicePlanLinuxResources.outputs.id
    storageAccountName: storageResources.outputs.name
    userAssignedIdentityId: access.outputs.managedIdentityId
    runtimeName: 'dotnet-isolated'
    runtimeVersion: '8.0'        
  }
  dependsOn: [
    storageResources
    appServicePlanLinuxResources
  ]
}

// Event Grid
/*module eventGridResources './app/eventgrid.bicep' = {
  name: 'eventgrid'
  scope: rg
  params: {
    location: location
    tags: tags
    eventGridTopicName: eventGridTopicName 
    eventGridNamespace: '${abbrs.eventGridNamespaces}${resourceToken}'
  }
}//*/

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

// Storage
module storageResources './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    location: location
    tags: tags
    name: '${abbrs.storageStorageAccounts}${resourceToken}'
    containers: [
      {
        name: 'container1'
        accessType: 'private'
      }
    ]
  }
}

// App Service Plan Function App
module appServicePlanLinuxResources './core/host/appserviceplan.bicep' = {
  name: 'appserviceplanlinux'
  scope: rg
  params: {
    location: location
    tags: tags
    name: 'service-plan-linux-${resourceToken}'
    kind: 'Linux'
    sku: {
      name: 'S1'
      tier: 'Standard'
      size: 'S1'
      family: 'S'
      capacity: 1
    }
  }
}

// App Service Plan Logic App
module appServicePlanWindowsResources './core/host/appserviceplan.bicep' = {
  name: 'appserviceplanwindows'
  scope: rg
  params: {
    location: location
    tags: tags
    name: 'service-plan-windows-${resourceToken}'
    sku: {
      name: 'WS1'
      tier: 'WorkflowStandard'
      size: 'WS1'
      family: 'WS'
      capacity: 1
    }
    kind: 'elastic'
    properties: {
      perSiteScaling: false
      elasticScaleEnabled: true
      maximumElasticWorkerCount: 20
      isSpot: false
      reserved: false
      isXenon: false
      hyperV: false
      targetWorkerCount: 0
      targetWorkerSizeId: 0
      zoneRedundant: false
    }
  }
}

// Access
module access './app/access.bicep' = {
  name: 'sb-access'
  scope: rg
  params: {
    location: location
    serviceBusName: serviceBusResources.outputs.serviceBusName
    sqlserverName: databaseResources.outputs.sqlServerName
    storageName: storageResources.outputs.name
    managedIdentityName: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
  }
}

output SERVICEBUS_ENDPOINT string = serviceBusResources.outputs.SERVICEBUS_ENDPOINT
output SERVICEBUS_NAME string = serviceBusResources.outputs.serviceBusName
output AZURE_MANAGED_IDENTITY_NAME string = access.outputs.managedIdentityName

output LOGICAAPP1_ENDPOINT string = logicApp1Resources.outputs.LOGICAPP_ENDPOINT
output LOGICAPP1_NAME string = logicApp1Resources.outputs.logicAppName
output LOGICAAPP2_ENDPOINT string = logicApp2Resources.outputs.LOGICAPP_ENDPOINT
output LOGICAPP2_NAME string = logicApp2Resources.outputs.logicAppName

//output APIM_ENDPOINT string = apimanagementResources.outputs.APIM_ENDPOINT
//output APIM_NAME string = apimanagementResources.outputs.apimServiceName

output STORAGE_NAME string = storageResources.outputs.name
output STORAGE_PRIMARY_ENDPOINT_BLOB string = storageResources.outputs.primaryEndpoints.blob

output APSERVICEPLAN_LINUX_ID string = appServicePlanLinuxResources.outputs.id
output APSERVICEPLAN_WINDOWS_ID string = appServicePlanWindowsResources.outputs.id

output FUNCTION_ENDPOINT string = functionAppResources.outputs.uri
output FUNCTION_NAME string = functionAppResources.outputs.name

output SQL_CONNECTIONSTRINGKEY string = databaseResources.outputs.connectionStringKey
output SQL_CONNECTIONSTRING string = databaseResources.outputs.connectionString
output SQL_SERVERNAME string = databaseResources.outputs.sqlServerName
output SQL_ADMIN_USERNAME string = databaseResources.outputs.sqlAdminUserName
output SQL_FULLY_QUALIFIEDNAME string = databaseResources.outputs.fullyQualifiedDomainName
