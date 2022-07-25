# Company Communicator API

This repo utilizes the core functionality of [Company Communicator](https://github.com/OfficeDev/microsoft-teams-apps-company-communicator) with a focus on sending Adaptive Card content via a web api.

This project was initialy built to overcome the current throttling limits to send proactive messages (aka notifications) to users in Teams via the Power Platform. While the solution described in [this article](https://docs.microsoft.com/en-us/power-virtual-agents/teams/advanced-proactive-message-teams) is very convenient and requires not dev skills to sent proactive messages via Power Automate and Power Virtual agent, it depends on [well known limitations](https://docs.microsoft.com/en-us/power-virtual-agents/teams/advanced-proactive-message-teams#known-limitations) from Power Automate and the Microsoft Teams connector.

Company Communicator runs on Azure and handles Teams notifications to very large tenant (100K and above) with a scheduling and reporting engine built-in. This project explains how to deploy this custom version of Company Communicator that exposes a set of API to be asyncrhonously called from Power Automate or any other client.

This project is a fork of the main Company Communicator application - It was developed and tested based on v5.1 and commit a45c53dc1b02cd9fcfbb7ef53381b2adc6e47d59 (June 21st, 2022)

## Deployment

You can deploy this solution by following the methodologies described in Company Communicator source repo:
- [Manual deployment](https://github.com/OfficeDev/microsoft-teams-apps-company-communicator/wiki/Deployment-guide)
- [Automated deployment via PowerShell](https://github.com/OfficeDev/microsoft-teams-apps-company-communicator/wiki/Deployment-guide-powershell)

## API Usage

Once deployed, the solution exposes the following endpoints:

- https://**{hostname}**.azurewebsites.net/**api/SendApiWrapperFunction_HttpStart** 
- https://**{hostname}**.azurewebsites.net/**api/MessageReportFunction**

With **{hostname}** the "base resource name" provided for the deployment of the solution on Azure.

### **SendApiWrapperFunction_HttpStart**
This is the endpoint to send an Adaptive Card object (in JSON format) to a group or users or into a team's channel. This call should be made **asynchronous** as it takes time (up to several minutes or hours) to send the notification to the targeted list of users. The API will respond with a HTTP status **"202 - Accepted"** and provides a list of URL to poll and get the status of the processing

**INPUT:**

| Parameter | Type | Format | Required | Description |
|---|---|---|---|---|
| code | Query string| string | YES | The code (master key) of the Azure Function app |
| AllUsers | Query string| string | NO | If set to 'true' the notification will be sent to all users that have the "Company Communicator user app" installed | 
| GroupId | Query string| string | NO | When the groupID is provided, all the members of the group that have the "Company Communicator user app" installed will receive the notification. <br>__Note__: this solution works with any group created from Azure AD |
| TeamsChannel | Query string| string | NO | When the TeamsChannel ID is provided, the notification is sent in the General channel of the team where the "Company Communicator user app" is installed. | 
| N/A | body | JSON | YES | The request should contain the JSON of the Adaptive Card to be sent. | 

**Note**: the API requires at least one of this query parameter to be provided - "AllUser" OR "GroupId" OR "TeamsChannel"

Example:

```
POST /api/SendApiWrapperFunction_HttpStart?code={AzFunctionCode}&AllUsers=true
Host: https://cc-api.azurewebsites.net/
Content-Type: application/json

{
    "type": "AdaptiveCard",
    "body": [
        {
            "type": "TextBlock",
            "text": "Push to group of users"
        }
    ],
    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
    "version": "1.3"
}
```

**OUTPUT:**

```JSON
{
    "id": "string",
    "statusQueryGetUri": "string",
    "sendEventPostUri": "string",
    "terminatePostUri": "string",
    "purgeHistoryDeleteUri": "string",
    "restartPostUri": "string"
}
```

To get the status of the process, you should sent a GET HTTP request to the URL provided as the value of the "statusQueryGetUri" property. You should poll this URL until the "runtimeStatus" is not "Running" (e.g. "Completed")

Example:

```
GET https://cc-api.azurewebsites.net/runtime/webhooks/durabletask/instances/{InstanceID}?taskHub={taskID}&connection=Storage&code={AzFunctionCode}
```

Response:

```Json
{
  "name": "SendApiWrapper_Orchestration",
  "instanceId": "f1c45bcf985148798af11ec57809e537",
  "runtimeStatus": "Completed",
  "input": {
    "Teams": [],
    "Rosters": [],
    "Groups": [
      "0e528aac-ceb1-436d-8240-c06c9775d3ef"
    ],
    "AllUsers": false,
    "AdaptiveCardContent": "Placeholder for the Adaptive Card",
    "SendInstanceId": "ed584b62-75f1-48b3-8080-95ea37ed5a7a",
    "Id": null,
    "Title": "",
    "ImageLink": null,
    "Summary": null,
    "Author": null,
    "ButtonTitle": null,
    "ButtonLink": null,
    "CreatedDateTime": "0001-01-01T00:00:00"
  },
  "customStatus": null,
  "output": {
    "NotificationId": "2517438188283520851",
    "Status": "Sent",
    "ErrorMessage": null,
    "WarningMessage": null
  },
  "createdTime": "2022-07-22T09:26:11Z",
  "lastUpdatedTime": "2022-07-22T09:27:34Z"
}
```

**The important information are:**
| Property |  Description |
|---|---|
|runtimeStatus| Indicates the status for the processing - Running / Completed / Failed|
|NotificationId|The ID of the notification sent - Require to query the MessageReportFunction endpoint |

### **MessageReportFunction**
This is the endpoint to get the detailed report of the processing. A successful processing doesn't mean that all the targeted users received the notification. Typical situations of notification send failed would be :
- The user doesn't have the "Company Communicator user app" installed
- The user doesn't have a Teams license assigned
- The user is a guest (not a member of the tenant)

This API provides a general status in terms of total messages sent, successfuly delivered and failed to deliver as well as a report in CSV format (in a ZIP file)

**INPUT:**

| Parameter | Type | Format | Required | Description |
|---|---|---|---|---|
| code | Query string| string | YES | The code (master key) of the Azure Function app |
| NotificationId | Query string| string | YES | The notification ID provided after the completion of the "SendApiWrapperFunction_HttpStart" process | 

Example:

```
GET https://cc-api.azurewebsites.net/api/MessageReportFunction?notificationId={notificaitonID}&code={AzFunctionCode}
```

**OUTPUT:**

```JSON
{
  "sendingStartedDate": "2022-07-22T09:26:11.6479329Z",
  "sentDate": "2022-07-22T09:26:14.4572819Z",
  "succeeded": 3,
  "failed": 2,
  "unknown": null,
  "canceled": null,
  "teamNames": [],
  "rosterNames": [],
  "groupNames": [
    "CC v5.11 Authors"
  ],
  "allUsers": false,
  "errorMessage": null,
  "warningMessage": null,
  "canDownload": true,
  "sendingCompleted": true,
  "reportDownloadUrl": "https://wxd4wrahjxcu2.blob.core.windows.net/exportdatablobs/FileName_ExportData_e72d9724-7fcc-4255-b5d7-de7db571bf0c.zip?sv=2021-06-08&se=2022-07-23T09%3A27%3A38Z&sr=b&sp=r&sig=vt7U1iY%2FMVB5FlAiKns0150lbdVJWLN6v2WIc6wlgxI%3D",
  "duration": "00:00:02.8093490",
  "totalMessageCount": 5,
  "id": "2517438188283520851",
  "title": "",
  "imageLink": null,
  "summary": null,
  "author": null,
  "buttonTitle": null,
  "buttonLink": null,
  "createdDateTime": "2022-07-22T09:26:11.6478984Z"
}
```

The property "reportDownloadUrl" provides a link to download the CSV report (in ZIP file) from the Azure storage account - The default time-to-live is 24 hours. We recommend to store this file on a SharePoint / OneDrive location.

## Integration with Power Automate / Azure Logic App

This solution was designed to be integrated into a Power Automate flow - Here is the high level flow:

<p align="center">
    <img src="./assets/images/power-automate-flow.png" alt="Power Automate Flow" width="500"/>
</p>

Let's check the configuration of each action:

### 1. Get Teams groupID

In this example, we get the group ID from a Teams team. The solution also support any O365 Group as well as Security Groups (dynamic / assigned / mail-enabled), all users and Teams channel.
<p align="center">
    <img src="./assets/images/power-automate-1-get-groupID.png" alt="Get Teams groupID" width="500"/>
</p>

### 2. Get secrets from Azure KeyVault

It is recommended and a best practice to store all your secrets in Azure Keyvault. We use this connector to get the Azure Function code as well as the secret of the "MS Graph API" application - cf. following section on how to configure Azure AD authentication between Power Automate and the Azure function.

**We recommend to toggle "Secure Outputs" to ON for the Keyvault actions.**
<p align="center">
    <img src="./assets/images/power-automate-2-get-AKV-secrets.png" alt="Get secrets from Azure KeyVault" width="500"/>
</p>

### 3. Send notification to GroupID

We use a standard HTTP connector to call the "/api/SendApuWrapperFunction_HttpStart" endpoint - The function code comes from the previous step as well as the GroupID. The body should contain the Adaptive Card payload - Please check the documentation on [Adaptive Cards](https://docs.microsoft.com/en-us/adaptive-cards/) to create your own content.

**Please verify that the action is configured for "asynchronous pattern"** - More info [here](https://docs.microsoft.com/en-us/azure/connectors/connectors-native-http#asynchronous-request-response-behavior)

In this screenshot, Azure AD authentication is configured to query the API - Please read the following section for the configuration steps.
<p align="center">
    <img src="./assets/images/power-automate-3-send-notification.png" alt="Send notification to GroupID" width="500"/>
</p>

### 4. Get Status Report

We use a standard HTTP connector to call the "/api/MessageReportFunction" endpoint - The function code comes from the previous step as well as the NotificaitonId. 

In this screenshot, Azure AD authentication is configured to query the API - Please read the following section for the configuration steps.
<p align="center">
    <img src="./assets/images/power-automate-4-get-status-report.png" alt="Get Status Report" width="500"/>
</p>

### 5. Get detailed CSV (ZIP file) 

We call the URL provided by the MessageReportFunction to download the report in CSV format.

<p align="center">
    <img src="./assets/images/power-automate-5-download-ZIP.png" alt="Get detailed CSV (ZIP file)" width="500"/>
</p>


### 6. Store ZIP to SharePoint online

We store the ZIP file onto SharePoint online. In the "File Content" section of this action, use the following expression - This will convert the file from base64 format to Binary.

```
base64ToBinary(body('HTTP_GET_-_Download_ZIP_file')?['$content'])
```

<p align="center">
    <img src="./assets/images/power-automate-6-store-ZIP-to-SPO.png" alt="Power Automate Flow" width="500"/>
</p>


## Add the Company Communicator bot capability to your Power App

Now that we have the CC API deployed and tested, we may want to add this capability to an existing Power App. All you need to do is to update your Power App manifest to add CC API bot capability.

### Step 1 - Download your Power App manifest

From the Power Platform portal - https://make.powerapps.com - select your Power App (under "Apps") and click on "Add to Teams" - Last, select "Download app" to get a ZIP file (aka app package) that contains the app manifest (JSON file) and 2 icons (PNG files)

More info on this page - https://docs.microsoft.com/en-us/power-apps/teams/embed-teams-app

### Step 2 - Update your app manifest 

Unzip the downloaded file and open the manifest (JSON)

**Add the bot capability** - Insert the following section in the manifest - Replace `<<user_botId>>` with the `%userBotId%` from the [deployment Company Communicator](https://github.com/OfficeDev/microsoft-teams-apps-company-communicator/wiki/Deployment-guide)

```JSON
  "bots": [{
    "botId": "<<user_botId>>",
    "scopes": [
      "personal",
      "team"
    ],
    "supportsFiles": false,
    "isNotificationOnly": true
  }],
```

Also **update the list of validDomains** to add the `%appDomain%` from the [deployment Company Communicator](https://github.com/OfficeDev/microsoft-teams-apps-company-communicator/wiki/Deployment-guide) - e.g. appName.azurefd.net
```JSON
  "validDomains": [
    "<<appDomain>>",
    "*.powerapps.com"
  ]
```

Last, update the version of the application (e.g. 1.0.0 --> 1.0.1)
```JSON
  "version": "1.0.x",
```

More info on Teams app manifest schema on this page - https://docs.microsoft.com/en-us/microsoftteams/platform/resources/schema/manifest-schema

### Step 3 - Update the application 

 - Create a new app package: select the 3 files (JSON + 2 PNG) and generate a Zip. 

   Note: Zip the files directly - NOT the folder that contains the files
 - Upload the new Zip file in Teams Admin Center - https://admin.teams.microsot.com

   Note: we assume that your application is already deployed in Teams app catalog. If not, review this [documentation](https://docs.microsoft.com/en-us/power-apps/teams/embed-teams-app).


## Configure Azure AD auth between Azure Function and Power Automate

It is recommended and a best practice to activate Azure AD authentication whenever possible - We want to activate this configuration between Power Automate and the Azure Function.

**Note:** please configure Azure Ad auth once you've tested that Company Communicator works as expected as well as the Power Automate flow that calls the API.

### Step 1 - Activate Azure AD on the Azure Function

- Identify the Azure Function that hosts your API endpoints (e.g. cc-apisend-function)
- Go the "Authentication" and select "Add identity provider"
- Select "Microsoft Azure AD" as identity provider 
- Select "Pick an existing app registration in this directory" and select the "Microsoft Graph App" created during the deployment of Company Communicator - The issuer will be automatically provided
- Set "Restrict Access" to "Require authentication"
- Set "Unauthenticated requests" to "HTTP 401 Unauthorized: recommended for APIs"
- Check "Token store"
- Click on the "Add" button to confirm the configuration
- Edit the configuration of the newly created Indentity provider and enter the value of the "Allowed token audience" - This is the value of the "Application ID URI" of your "Microsoft Graph app" under Azure AD app registration (e.g. api://cc-api.azurefd.net)

More info on Azure AD configuration for Azure App Service here - https://docs.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad

### Step 2 - Configure the HTTP requests in Power Automate

In Power Automate, configure the 2 HTTP requests to the API endpoints following these steps:

- On the HTTP action in Power Automate, select "Add new parameter" and check "Authentication"
- As "Authentication Type" select "Active Directory OAuth"
- Then provide the following parameters:
   - Authority - "https://login.microsoftonline.com"
   - Tenant - provide your tenant ID (preferably saved in a Power Apps parameter)
   - Audience - This is the value of the "Application ID URI" of your "Microsoft Graph app" under Azure AD app registration (e.g. api://cc-api.azurefd.net)
   - Client ID - This is the client ID of your "Microsoft Graph API" app.
   - Credential Type - "Secret"
   - Secret - This is the client secret of your "Microsoft Graph API" app - **We highly recommend to store this secret in Azure Keyvault and get the secret from the vault. 
   
**Congrats, You're done!**

## Legal notice

This app template is provided under the [MIT License](https://github.com/OfficeDev/microsoft-teams-company-communicator-app/blob/main/LICENSE) terms.  In addition to these terms, by using this app template you agree to the following:

- You, not Microsoft, will license the use of your app to users or organization. 

- This app template is not intended to substitute your own regulatory due diligence or make you or your app compliant with respect to any applicable regulations, including but not limited to privacy, healthcare, employment, or financial regulations.

- You are responsible for complying with all applicable privacy and security regulations including those related to use, collection and handling of any personal data by your app. This includes complying with all internal privacy and security policies of your organization if your app is developed to be sideloaded internally within your organization. Where applicable, you may be responsible for data related incidents or data subject requests for data collected through your app.

- Any trademarks or registered trademarks of Microsoft in the United States and/or other countries and logos included in this repository are the property of Microsoft, and the license for this project does not grant you rights to use any Microsoft names, logos or trademarks outside of this repository. Microsoft’s general trademark guidelines can be found [here](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general.aspx).

- If the app template enables access to any Microsoft Internet-based services (e.g., Office365), use of those services will be subject to the separately-provided terms of use. In such cases, Microsoft may collect telemetry data related to app template usage and operation. Use and handling of telemetry data will be performed in accordance with such terms of use.

- Use of this template does not guarantee acceptance of your app to the Teams app store. To make this app available in the Teams app store, you will have to comply with the [submission and validation process](https://docs.microsoft.com/en-us/microsoftteams/platform/concepts/deploy-and-publish/appsource/publish), and all associated requirements such as including your own privacy statement and terms of use for your app.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
