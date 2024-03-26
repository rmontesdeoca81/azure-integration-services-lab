//param resourceToken string
param location string
param skuName string = 'Standard'
param tags object

param serviceBusName string
param topicName string
param subscriptionName string

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: serviceBusName
  location: location
  tags: tags

  sku: {
    name: skuName
    tier: skuName
  }

  resource topic 'topics' = {
    name: topicName
    properties: {
      supportOrdering: true
    }

    resource subscription 'subscriptions' = {
      name: subscriptionName
      properties: {
        deadLetteringOnFilterEvaluationExceptions: true
        deadLetteringOnMessageExpiration: true
        maxDeliveryCount: 10
      }
    }
  }
}

output SERVICEBUS_ENDPOINT string = serviceBusNamespace.properties.serviceBusEndpoint
output serviceBusName string = serviceBusNamespace.name
