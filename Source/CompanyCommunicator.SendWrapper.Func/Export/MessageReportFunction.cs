using Azure.Storage.Blobs.Models;
using Azure.Storage.Sas;
using CsvHelper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using Microsoft.Teams.Apps.CompanyCommunicator.Common.Clients;
using Microsoft.Teams.Apps.CompanyCommunicator.Common.Extensions;
using Microsoft.Teams.Apps.CompanyCommunicator.Common.Repositories.NotificationData;
using Microsoft.Teams.Apps.CompanyCommunicator.Common.Repositories.TeamData;
using Microsoft.Teams.Apps.CompanyCommunicator.Common.Resources;
using Microsoft.Teams.Apps.CompanyCommunicator.Common.Services.MicrosoftGraph;
using Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Mappers;
using Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Models;
using System;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Threading.Tasks;

namespace Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Export
{
    public class MessageReportFunction
    {
        private readonly IStorageClientFactory _storageClientFactory;
        private readonly IStringLocalizer<Strings> _localizer;
        private readonly IDataStreamFacade _userDataStream;
        private IConfiguration _configuration;
        private INotificationDataRepository _notificationDataRepository;
        private readonly ITeamDataRepository _teamDataRepository;
        private readonly IGroupsService _groupsService;

        /// <summary>
        /// Initializes a new instance of the <see cref="UploadActivity"/> class.
        /// </summary>
        /// <param name="storageClientFactory">the storage client factory.</param>
        /// <param name="userDataStream">the user data stream.</param>
        /// <param name="localizer">Localization service.</param>
        public MessageReportFunction(
            IStorageClientFactory storageClientFactory,
            IDataStreamFacade userDataStream,
            IStringLocalizer<Strings> localizer,
            IConfiguration configuration,
            INotificationDataRepository notificationDataRepository,
            ITeamDataRepository teamDataRepository,
            IGroupsService groupsService)
        {
            _storageClientFactory = storageClientFactory ?? throw new ArgumentNullException(nameof(storageClientFactory));
            _userDataStream = userDataStream ?? throw new ArgumentNullException(nameof(userDataStream));
            _localizer = localizer ?? throw new ArgumentNullException(nameof(localizer));
            _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
            _notificationDataRepository = notificationDataRepository ?? throw new ArgumentNullException(nameof(notificationDataRepository));
            _teamDataRepository = teamDataRepository ?? throw new ArgumentNullException(nameof(teamDataRepository));
            _groupsService = groupsService ?? throw new ArgumentNullException(nameof(groupsService));
        }

        [FunctionName("MessageReportFunction")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            try
            {
                string notificationId = req.Query["notificationId"];
                string reportLink = await this.GetNotificationReport(notificationId, log);

                var notificationEntity = await _notificationDataRepository.GetAsync(
                partitionKey: NotificationDataTableNames.SentNotificationsPartition,
                rowKey: notificationId);

                if (notificationEntity == null)
                {
                    return new NotFoundResult();
                }

                var groupNames = await _groupsService.
                GetByIdsAsync(notificationEntity.Groups).
                Select(x => x.DisplayName).
                ToListAsync();

                var result = new SentNotification
                {
                    Id = notificationEntity.Id,
                    Title = notificationEntity.Title,
                    ImageLink = notificationEntity.ImageLink,
                    Summary = notificationEntity.Summary,
                    Author = notificationEntity.Author,
                    ButtonTitle = notificationEntity.ButtonTitle,
                    ButtonLink = notificationEntity.ButtonLink,
                    CreatedDateTime = notificationEntity.CreatedDate,
                    SentDate = notificationEntity.SentDate,
                    Succeeded = notificationEntity.Succeeded,
                    Failed = notificationEntity.Failed,
                    Unknown = this.GetUnknownCount(notificationEntity),
                    Canceled = notificationEntity.Canceled > 0 ? notificationEntity.Canceled : (int?)null,
                    TeamNames = await _teamDataRepository.GetTeamNamesByIdsAsync(notificationEntity.Teams),
                    RosterNames = await _teamDataRepository.GetTeamNamesByIdsAsync(notificationEntity.Rosters),
                    GroupNames = groupNames,
                    AllUsers = notificationEntity.AllUsers,
                    SendingStartedDate = notificationEntity.SendingStartedDate,
                    ErrorMessage = notificationEntity.ErrorMessage,
                    WarningMessage = notificationEntity.WarningMessage,
                    CanDownload = true,
                    SendingCompleted = notificationEntity.IsCompleted(),
                    ReportDownloadUrl = reportLink,
                    Duration = (TimeSpan)(notificationEntity.SentDate - notificationEntity.SendingStartedDate),
                    TotalMessageCount = notificationEntity.TotalMessageCount
                };

                if (notificationId == null)
                {
                    throw new ArgumentNullException(nameof(notificationId));
                }

                return new OkObjectResult(result);
            }
            catch (Exception ex)
            {
                log.LogError(ex.Message);
                return BadRequestObjectResult(ex);
            }
        }

        private IActionResult BadRequestObjectResult(Exception ex)
        {
            throw new NotImplementedException();
        }

        public async Task<string> GetNotificationReport(string notificationId, ILogger log)
        {
            //log.LogInformation($"Saying hello to {name}.");
            //return $"Hello {name}!";

            var fileName = GetFileName();

            var blobContainerClient = _storageClientFactory.CreateBlobContainerClient();
            await blobContainerClient.CreateIfNotExistsAsync();
            await blobContainerClient.SetAccessPolicyAsync(PublicAccessType.None);
            var blob = blobContainerClient.GetBlobClient(fileName);

            var notificationDataEntity = await _notificationDataRepository.GetAsync(
               partitionKey: NotificationDataTableNames.SentNotificationsPartition,
               rowKey: notificationId);

            if (notificationDataEntity == null)
                throw new ArgumentNullException(nameof(notificationDataEntity));

            using var memorystream = new MemoryStream();
            using (var archive = new ZipArchive(memorystream, ZipArchiveMode.Create, true))
            {
                // message delivery csv creation.
                var messageDeliveryFileName = string.Concat("FileName_Message_Delivery", ".csv");
                var messageDeliveryFile = archive.CreateEntry(messageDeliveryFileName, CompressionLevel.Optimal);
                using (var entryStream = messageDeliveryFile.Open())
                {
                    using (var writer = new StreamWriter(entryStream, System.Text.Encoding.UTF8))
                    using (var csv = new CsvWriter(writer, CultureInfo.InvariantCulture))
                    {
                        if (notificationDataEntity.Teams.Any())
                        {
                            var teamDataMap = new TeamDataMap(_localizer);
                            csv.Configuration.RegisterClassMap(teamDataMap);
                            var teamDataStream = _userDataStream.GetTeamDataStreamAsync(notificationId, notificationDataEntity.Status);
                            await foreach (var data in teamDataStream)
                            {
                                await csv.WriteRecordsAsync(data);
                            }
                        }
                        else
                        {
                            var userDataMap = new UserDataMap(_localizer);
                            csv.Configuration.RegisterClassMap(userDataMap);
                            var userStream = _userDataStream.GetUserDataStreamAsync(notificationId, notificationDataEntity.Status);
                            await foreach (var data in userStream)
                            {
                                await csv.WriteRecordsAsync(data);
                            }
                        }
                    }
                }
            }

            memorystream.Position = 0;
            await blob.UploadAsync(memorystream, true);
            int blobSasTimeout = 24;
            int blobSasTimeoutConfig;
            if (int.TryParse(_configuration.GetValue<string>("BlobSasTimeoutHours"), out blobSasTimeoutConfig))
            {
                blobSasTimeout = blobSasTimeoutConfig > 0 ? Convert.ToInt32(blobSasTimeoutConfig) : blobSasTimeout;
            }
            var url = blob.GenerateSasUri(BlobSasPermissions.Read, DateTimeOffset.UtcNow.AddHours(blobSasTimeout)).ToString();
            return url;
        }

        private string GetFileName()
        {
            var guid = Guid.NewGuid().ToString();
            var fileName = "FileName_ExportData";
            return $"{fileName}_{guid}.zip";
        }

        private int? GetUnknownCount(NotificationDataEntity notificationEntity)
        {
            var unknown = notificationEntity.Unknown;

            // In CC v2, the number of throttled recipients are counted and saved in NotificationDataEntity.Unknown property.
            // However, CC v1 saved the number of throttled recipients in NotificationDataEntity.Throttled property.
            // In order to make it backward compatible, we add the throttled number to the unknown variable.
            var throttled = notificationEntity.Throttled;
            if (throttled > 0)
            {
                unknown += throttled;
            }

            return unknown > 0 ? unknown : (int?)null;
        }
    }

    public class NotificationInput
    {
        public string notificationId { get; set; }
    }
}