targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

//ServiceBus 
param serviceBusTopicName string = 'orders'
param serviceBusSubscriptionName string = 'orders'

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
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }


// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

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

// Service Bus
module serviceBusResources './app/servicebus.bicep' = {
  name: 'sb-resources'
  scope: rg
  params: {
    location: location
    tags: tags
    serviceBusName: '${abbrs.serviceBusNamespaces}${resourceToken}'
    skuName: 'Standard'
    subscriptionName:serviceBusSubscriptionName
    topicName: serviceBusTopicName
  }

}

// Service Bus Access
module serviceBusAccess './app/access.bicep' = {
  name: 'sb-access'
  scope: rg
  params: {
    location: location
    serviceBusName: serviceBusResources.outputs.serviceBusName
    managedIdentityName: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
  }
}

// Logic App 1
module logicApp1Resources './app/logicapp.bicep' = {
  name: 'logic-app1'
  scope: rg
  params: {
    location: location
    tags: tags
    logicAppName: '${abbrs.logicWorkflows}1-${resourceToken}'
  }
}

// Logic App 2
module logicApp2Resources './app/logicapp.bicep' = {
  name: 'logic-app2'
  scope: rg
  params: {
    location: location
    tags: tags
    logicAppName: '${abbrs.logicWorkflows}2-${resourceToken}'
  }
}

// API Management
module apimanagementResources './core/gateway/apim.bicep' = {
  name: 'apim'
  scope: rg
  params: {
    location: location
    tags: tags    
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    name: '${abbrs.apiManagementService}${resourceToken}'
  }
  dependsOn: [
    monitoring
  ]
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

// App Service Plan
module appServicePlanResources './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    location: location
    tags: tags    
    name: 'service-plan-${resourceToken}'
    sku: {
      name: 'S1' // Free tier
      tier: 'Standard'
      size: 'S1'
      family: 'S'
      capacity: 1
    }
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
    appServicePlanId:appServicePlanResources.outputs.id
    storageAccountName: storageResources.outputs.name
    runtimeName:'dotnetcore'
    runtimeVersion:'4'
  }
  dependsOn: [
    storageResources
    appServicePlanResources
  ]
}

// Event Grid
module eventGridResources './app/eventgrid.bicep' = {
  name: 'eventgrid'
  scope: rg
  params: {
    location: location
    tags: tags    
    eventGridTopicName: '${abbrs.eventGridDomainsTopics}${resourceToken}'
  }
}

output SERVICEBUS_ENDPOINT string = serviceBusResources.outputs.SERVICEBUS_ENDPOINT
output SERVICEBUS_NAME string = serviceBusResources.outputs.serviceBusName
output AZURE_MANAGED_IDENTITY_NAME string = serviceBusAccess.outputs.managedIdentityName

output LOGICAAPP1_ENDPOINT string = logicApp1Resources.outputs.LOGICAPP_ENDPOINT
output LOGICAPP1_NAME string = logicApp1Resources.outputs.logicAppName
output LOGICAAPP2_ENDPOINT string = logicApp2Resources.outputs.LOGICAPP_ENDPOINT
output LOGICAPP2_NAME string = logicApp2Resources.outputs.logicAppName

output APIM_ENDPOINT string = apimanagementResources.outputs.APIM_ENDPOINT
output APIM_NAME string = apimanagementResources.outputs.apimServiceName

output STORAGE_NAME string = storageResources.outputs.name
output STORAGE_PRIMARY_ENDPOINT_BLOB string = storageResources.outputs.primaryEndpoints.blob

output APSERVICEPLAN_ID string = appServicePlanResources.outputs.id

output FUNCTION_ENDPOINT string = functionAppResources.outputs.uri
output FUNCTION_NAME string = functionAppResources.outputs.name




