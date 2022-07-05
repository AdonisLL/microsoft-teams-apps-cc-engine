using Azure.Storage.Blobs.Models;
using Azure.Storage.Sas;
using CsvHelper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using Microsoft.Teams.Apps.CompanyCommunicator.Common.Clients;
using Microsoft.Teams.Apps.CompanyCommunicator.Common.Resources;
using Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Mappers;
using Newtonsoft.Json;
using System;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Threading.Tasks;

namespace Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Export
{
    public class DataExportFunction
    {
        private readonly IStorageClientFactory _storageClientFactory;
        private readonly IStringLocalizer<Strings> _localizer;
        private readonly IDataStreamFacade _userDataStream;

        /// <summary>
        /// Initializes a new instance of the <see cref="UploadActivity"/> class.
        /// </summary>
        /// <param name="storageClientFactory">the storage client factory.</param>
        /// <param name="userDataStream">the user data stream.</param>
        /// <param name="localizer">Localization service.</param>
        public DataExportFunction(
            IStorageClientFactory storageClientFactory,
            IDataStreamFacade userDataStream,
            IStringLocalizer<Strings> localizer)
        {
            _storageClientFactory = storageClientFactory ?? throw new ArgumentNullException(nameof(storageClientFactory));
            _userDataStream = userDataStream ?? throw new ArgumentNullException(nameof(userDataStream));
            _localizer = localizer ?? throw new ArgumentNullException(nameof(localizer));
        }

        [FunctionName("DataExportFunction")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            try
            {
                string notificationId = req.Query["notificationId"];
                string response = await this.GetNotificationReport(notificationId, log);

                return new OkObjectResult(response);
            }
            catch(Exception ex)
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
                        var userDataMap = new UserDataMap(_localizer);
                        csv.Configuration.RegisterClassMap(userDataMap);
                        var userStream = _userDataStream.GetUserDataStreamAsync(notificationId, "Sent");
                        await foreach (var data in userStream)
                        {
                            await csv.WriteRecordsAsync(data);
                        }
                    }
                }
            }

            memorystream.Position = 0;
            await blob.UploadAsync(memorystream, true);
            var url = blob.GenerateSasUri(BlobSasPermissions.Read, DateTimeOffset.UtcNow.AddDays(1)).ToString();
            return url;
        }

        private string GetFileName()
        {
            var guid = Guid.NewGuid().ToString();
            var fileName = "FileName_ExportData";
            return $"{fileName}_{guid}.zip";
        }
    }

    public class NotificationInput
    {
        public string notificationId { get; set; }
    }
}