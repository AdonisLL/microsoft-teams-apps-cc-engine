namespace Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Services
{
    using System;
    using System.Threading.Tasks;
    using Microsoft.Extensions.Options;
    using Microsoft.Teams.Apps.CompanyCommunicator.Common.Repositories.NotificationData;
    using Microsoft.Teams.Apps.CompanyCommunicator.Common.Repositories.SentNotificationData;
    using Microsoft.Teams.Apps.CompanyCommunicator.Common.Services.MessageQueues.DataQueue;
    using Microsoft.Teams.Apps.CompanyCommunicator.Common.Services.MessageQueues.PrepareToSendQueue;
    using Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Models;

    /// <summary>
    /// Extensions for the repository of the notification data.
    /// </summary>
    public class NotificationService : INotificationService
    {
        private INotificationDataRepository _notificationDataRepository;
        private readonly IPrepareToSendQueue _prepareToSendQueue;
        private readonly IDataQueue _dataQueue;
        private ISentNotificationDataRepository _sentNotificationDataRepository;
        private readonly double _forceCompleteMessageDelayInSeconds;



        public NotificationService(
            INotificationDataRepository notificationDataRepository,
            IPrepareToSendQueue prepareToSendQueue,
            IDataQueue dataQueue,
            IOptions<DataQueueMessageOptions> dataQueueMessageOptions,
            ISentNotificationDataRepository sentNotificationDataRepository
           )
        {
            _notificationDataRepository = notificationDataRepository;
            _prepareToSendQueue = prepareToSendQueue;
            _dataQueue = dataQueue;
            _sentNotificationDataRepository = sentNotificationDataRepository;
            _forceCompleteMessageDelayInSeconds = dataQueueMessageOptions.Value.ForceCompleteMessageDelayInSeconds;
        }

        

        public async Task<string> CreateSentNotification(DraftNotification notification, string userName)
        {

            var draftNotificationDataEntity = new NotificationDataEntity
            {
                PartitionKey = NotificationDataTableNames.DraftNotificationsPartition,
                RowKey = string.Empty,
                Id = string.Empty,
                AdaptiveCardContent = notification.AdaptiveCardContent,
                ImageLink = notification.ImageLink,
                Summary = notification.Summary,
                Author = notification.Author,
                ButtonTitle = notification.ButtonTitle,
                ButtonLink = notification.ButtonLink,
                CreatedBy = userName,
                CreatedDate = DateTime.UtcNow,
                IsDraft = true,
                Teams = notification.Teams,
                Rosters = notification.Rosters,
                Groups = notification.Groups,
                AllUsers = notification.AllUsers,
                Title = notification.Title,
            };

            var newSentNotificationId =
                await _notificationDataRepository.MoveDraftToSentPartitionAsync(draftNotificationDataEntity);

            // Ensure the data table needed by the Azure Functions to send the notifications exist in Azure storage.
            await _sentNotificationDataRepository.EnsureSentNotificationDataTableExistsAsync();

            var prepareToSendQueueMessageContent = new PrepareToSendQueueMessageContent
            {
                NotificationId = newSentNotificationId,
            };

            await _prepareToSendQueue.SendAsync(prepareToSendQueueMessageContent);

            // Send a "force complete" message to the data queue with a delay to ensure that
            // the notification will be marked as complete no matter the counts
            var forceCompleteDataQueueMessageContent = new DataQueueMessageContent
            {
                NotificationId = newSentNotificationId,
                ForceMessageComplete = true,
            };

            await _dataQueue.SendDelayedAsync(
                forceCompleteDataQueueMessageContent,
                _forceCompleteMessageDelayInSeconds);

            return newSentNotificationId;
        }

    }
}
