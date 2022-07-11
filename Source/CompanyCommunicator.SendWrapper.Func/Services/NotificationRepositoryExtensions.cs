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

        ///// <summary>
        ///// Create a new draft notification.
        ///// </summary>
        ///// <param name="notificationRepository">The notification repository.</param>
        ///// <param name="notification">Draft Notification model class instance passed in from Web API.</param>
        ///// <param name="userName">Name of the user who is running the application.</param>
        ///// <returns>The newly created notification's id.</returns>
        //public async Task<string> CreateDraftNotificationAsync(
        //    DraftNotification notification,
        //    string userName)
        //{
        //    var newId = _notificationDataRepository.TableRowKeyGenerator.CreateNewKeyOrderingOldestToMostRecent();

        //    var notificationEntity = new NotificationDataEntity
        //    {
        //        PartitionKey = NotificationDataTableNames.DraftNotificationsPartition,
        //        RowKey = newId,
        //        Id = newId,
        //        AdaptiveCardContent = notification.AdaptiveCardContent,
        //        ImageLink = notification.ImageLink,
        //        Summary = notification.Summary,
        //        Author = notification.Author,
        //        ButtonTitle = notification.ButtonTitle,
        //        ButtonLink = notification.ButtonLink,
        //        CreatedBy = userName,
        //        CreatedDate = DateTime.UtcNow,
        //        IsDraft = true,
        //        Teams = notification.Teams,
        //        Rosters = notification.Rosters,
        //        Groups = notification.Groups,
        //        AllUsers = notification.AllUsers,
        //        Title = notification.Title,
        //    };

        //    await _notificationDataRepository.CreateOrUpdateAsync(notificationEntity);
        //    notification.Id = newId;
        //    //await CreateSentNotification(notification);

        //    return newId;
        //}


        public async Task<string> CreateSentNotification(DraftNotification notification, string userName)
        {

            //if (draftNotification == null)
            //{
            //    throw new ArgumentNullException(nameof(draftNotification));
            //}

            //var draftNotificationDataEntity = await _notificationDataRepository.GetAsync(
            //    NotificationDataTableNames.DraftNotificationsPartition,
            //    draftNotification.Id);
            //if (draftNotificationDataEntity == null)
            //{
            //    throw new Exception($"Draft notification, Id: {draftNotification.Id}, could not be found.");
            //}

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

            // Update user app id if proactive installation is enabled.
            //await this.UpdateUserAppIdAsync();

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
