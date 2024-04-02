using System;
using System.Reflection.Metadata;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Company.Function
{
    public class ServiceBusTopicTriggerToBlobSt
    {
        private readonly ILogger<ServiceBusTopicTriggerToBlobSt> _logger;

        public ServiceBusTopicTriggerToBlobSt(ILogger<ServiceBusTopicTriggerToBlobSt> logger)
        {
            _logger = logger;
        }

        [Function(nameof(ServiceBusTopicTriggerToBlobSt))]
        public async Task Run(
            [ServiceBusTrigger("orders", "orders", Connection = "sbwe2sicdci5cp2_SERVICEBUS")]
            ServiceBusReceivedMessage message,
            ServiceBusMessageActions messageActions)
        {
            _logger.LogInformation("Message ID: {id}", message.MessageId);
            _logger.LogInformation("Message Body: {body}", message.Body);
            _logger.LogInformation("Message Content-Type: {contentType}", message.ContentType);

            // Write the message to a blob storage
            var blobServiceClient = new BlobServiceClient(Environment.GetEnvironmentVariable("BlobStorageConnection"));
            var blobContainerClient = blobServiceClient.GetBlobContainerClient("container1");
            var blobClient = blobContainerClient.GetBlobClient($"{Guid.NewGuid()}.txt");
            await blobClient.UploadAsync(new BinaryData(message.Body));

             // Complete the message
            await messageActions.CompleteMessageAsync(message);
        }
    }
}
