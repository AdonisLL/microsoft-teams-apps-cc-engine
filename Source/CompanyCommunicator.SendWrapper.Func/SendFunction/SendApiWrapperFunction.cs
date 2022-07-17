using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.DurableTask;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using Microsoft.Teams.Apps.CompanyCommunicator.Common.Repositories.NotificationData;
using Microsoft.Teams.Apps.CompanyCommunicator.Common.Resources;
using Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Models;
using Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Services;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using ExecutionContext = Microsoft.Azure.WebJobs.ExecutionContext;
using JsonSerializer = System.Text.Json.JsonSerializer;

namespace Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func
{
    public class SendFunction
    {
        private readonly INotificationService _notificationService;
        private readonly IStringLocalizer<Strings> localizer;
        private INotificationDataRepository _notificationDataRepository;
        private readonly IHttpClientFactory _httpClientFactory;

        public SendFunction(
            INotificationService notificationService,
            INotificationDataRepository notificationDataRepository,
            IHttpClientFactory httpClientFactory
            )
        {
            _notificationService = notificationService;
            _notificationDataRepository = notificationDataRepository;
            _httpClientFactory = httpClientFactory;
        }

        [FunctionName("SendApiWrapper_Orchestration")]
        public static async Task<ActionResult> RunOrchestrator(
            [OrchestrationTrigger] IDurableOrchestrationContext context)
        {
            DraftNotification notification = context.GetInput<DraftNotification>();
            string notificationId = await context.CallActivityAsync<string>("SendApiWrapper_Work", notification);

            try
            {
                string status = await context.CallActivityAsync<string>("SendApiWrapper_CheckStatus", notificationId);

                while (status != nameof(NotificationStatus.Sent))
                {
                    if (
                        status != nameof(NotificationStatus.Canceled) &&
                        status != nameof(NotificationStatus.Failed))

                    {
                        DateTime dueTime = context.CurrentUtcDateTime.AddMinutes(1);
                        await context.CreateTimer(dueTime, CancellationToken.None);
                        status = await context.CallActivityAsync<string>("SendApiWrapper_CheckStatus", notificationId);
                    }
                    else
                    {
                        return new BadRequestObjectResult(new SentResponse() { NotificationId = notificationId, Status = $"Notification status = {status}" });
                    }
                    context.SetCustomStatus($"Notification status = {status}");

                }
            }
            catch (Exception ex)
            {
                return new BadRequestObjectResult(new SentResponse() { NotificationId = notificationId, Status = ex.Message });
            }

            return new OkObjectResult(new SentResponse() { NotificationId = notificationId });
        }

        [FunctionName("SendApiWrapper_Work")]
        public async Task<string> Work_Function([ActivityTrigger] DraftNotification notification, ILogger log)
        {
            return await _notificationService.CreateSentNotification(notification, "Power Automate");
        }

        [FunctionName("SendApiWrapper_CheckStatus")]
        public async Task<string> Status_Function([ActivityTrigger] string notificationId, ILogger log)
        {
            var notificationDataEntity = await _notificationDataRepository.GetAsync(
                partitionKey: NotificationDataTableNames.SentNotificationsPartition,
                rowKey: notificationId);

            if (notificationDataEntity == null)
                throw new ArgumentNullException(nameof(notificationDataEntity));

            return notificationDataEntity.Status;
        }

        [FunctionName("SendApiWrapperFunction_HttpStart")]
        public async Task<ActionResult> HttpStart(
        [HttpTrigger(AuthorizationLevel.Function, "get", "post")]
            HttpRequest req,
        [DurableClient] IDurableOrchestrationClient starter,
        ILogger log, ExecutionContext context)
        {
            // Function input comes from the request content.
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();

            var notificationData = JsonSerializer.Deserialize<DraftNotification>(requestBody, new JsonSerializerOptions() { PropertyNameCaseInsensitive = true });
            var _groupId = req.Query["GroupId"];
            var _allUsers = req.Query["AllUsers"];
            var _teamsChannelId = req.Query["TeamsChannel"];
            var _title = req.Query["Title"];

            List<string> groupList = new List<string>();
            if (!string.IsNullOrEmpty(_groupId))
            {
                groupList.Add(_groupId);
            }

            // General channel of teams.
            List<string> _teamsChannelList = new List<string>();
            if (!string.IsNullOrEmpty(_teamsChannelId))
            {
                _teamsChannelList.Add(_teamsChannelId);
            }

            bool allUsers;
            if (Boolean.TryParse(_allUsers, out allUsers))
            {
                allUsers = Convert.ToBoolean(_allUsers);
                groupList = new List<string>();
            }

            DraftNotification notification = new DraftNotification()
            {
                AdaptiveCardContent = requestBody,
                Groups = groupList,
                AllUsers = allUsers,
                SendInstanceId = Guid.NewGuid().ToString(),
                Teams = _teamsChannelList,
                Title = !string.IsNullOrEmpty(_groupId) ? _title.ToString() : string.Empty
            };

            if (notification == null)
                throw new ArgumentNullException(nameof(notification));

            if (!notification.Validate(localizer, out string errorMessage))
                return new BadRequestObjectResult(errorMessage);

            string instanceId = await starter.StartNewAsync("SendApiWrapper_Orchestration", notification);

            log.LogInformation($"Started orchestration with ID = '{instanceId}'.");

            return (ActionResult)starter.CreateCheckStatusResponse(req, instanceId);
        }

        /// <summary>
        /// Get the orchestration status of the notification.
        /// </summary>
        /// <param name="functionPayload">the payload of the orchestration containing Status Uri, Terminate Uri etc.</param>
        /// <returns>the status of the orchestration.</returns>
        public async Task<string> GetOrchestrationStatusAsync(string functionPayload)
        {
            var instancePayload = JsonConvert.DeserializeObject<HttpManagementPayload>(functionPayload);
            var client = _httpClientFactory.CreateClient();
            var response = await client.GetAsync(instancePayload.StatusQueryGetUri);
            var content = await response.Content.ReadAsStringAsync();
            var functionResp = JsonConvert.DeserializeObject<OrchestrationStatusResponse>(content);
            return functionResp.RuntimeStatus;
        }
    }
}

public class SentResponse
{
    public string NotificationId { get; set; }

    public string Status { get; set; }
}