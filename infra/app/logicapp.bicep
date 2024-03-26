//Bicep code to create a new logic app in the resource group, name and location specified as parameter

param location string
param tags object
param logicAppName string

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      actions: {}
      outputs: {}
      parameters: {}
      triggers: {}
    }
    parameters: {}
  }
}


output LOGICAPP_ENDPOINT string = logicApp.properties.accessEndpoint
output logicAppName string = logicApp.name
