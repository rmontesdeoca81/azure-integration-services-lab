//Create new event grid

param location string
param tags object
param eventGridTopicName string


resource eventGridTopic 'Microsoft.EventGrid/topics@2021-06-01-preview' = {
  tags: tags
  name: eventGridTopicName
  location: location
  properties: {}
}



output EVENTGRID_ENDPOINT string = eventGridTopic.properties.endpoint
output eventGridName string = eventGridTopic.name
