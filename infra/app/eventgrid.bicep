//Create new event grid

param location string
param tags object

param eventGridNamespace string
param eventGridTopicName string


resource eventgrid_resource 'Microsoft.EventGrid/namespaces@2023-12-15-preview' = {
  name: eventGridNamespace
  location:location
  tags: tags
  sku: {
    name: 'Standard'
    capacity: 1
  }
  /*properties: {
    topicsConfiguration: {}
    isZoneRedundant: true
    publicNetworkAccess: 'Enabled'
  }*/
}

resource eventgrid_topic_resource 'Microsoft.EventGrid/namespaces/topics@2023-12-15-preview' = {
  parent: eventgrid_resource
  name: eventGridTopicName
  properties: {
    publisherType: 'Custom'
    inputSchema: 'CloudEventSchemaV1_0'
    eventRetentionInDays: 7
  }
}


//output EVENTGRID_HOSTNAME string = eventgrid_resource.properties.topicSpacesConfiguration.hostname
//output eventGridNamespaceName string = eventgrid_resource.name
