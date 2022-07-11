@description('The base name to use for the resources that will be provisioned.')
@minLength(1)
param baseResourceName string


@description('The client ID of the user bot Azure AD app, e.g., 123e4567-e89b-12d3-a456-426655440000.')
@minLength(36)
@maxLength(36)
param userClientId string

@description('The client secret of the user bot Azure AD app.')
@minLength(1)
@secure()
param userClientSecret string

@description('The client ID of the author bot Azure AD app, e.g., 123e4567-e89b-12d3-a456-426655440000.')
@minLength(36)
@maxLength(36)
param authorClientId string

@description('The client secret of the author bot Azure AD app.')
@minLength(1)
@secure()
param authorClientSecret string

@description('The client ID of the Microsoft Graph Azure AD app, e.g., 123e4567-e89b-12d3-a456-426655440000.')
@minLength(36)
@maxLength(36)
param graphAppId string

@description('The client secret of the Microsoft Graph Azure AD app.')
@minLength(1)
@secure()
param graphAppSecret string

@description('Semicolon-delimited list of the user principal names (UPNs) allowed to send messages.')
@minLength(0)
param senderUPNList string

@description('If proactive app installation should be enabled.')
param ProactivelyInstallUserApp string = 'true'

@description('User app external ID.')
@minLength(1)
param UserAppExternalId string = newGuid()

@description('Default culture.')
@minLength(1)
@allowed([
  'ar-SA'
  'de-DE'
  'en-US'
  'es-ES'
  'fr-FR'
  'he-IL'
  'ja-JP'
  'ko-KR'
  'pt-BR'
  'ru-RU'
  'zh-CN'
  'zh-TW'
])
param DefaultCulture string = 'en-US'

@description('Comma-delimited list of the supported cultures.')
@minLength(1)
param SupportedCultures string = 'ar-SA,de-DE,en-US,es-ES,fr-FR,he-IL,ja-JP,ko-KR,pt-BR,ru-RU,zh-CN,zh-TW'

@description('How the app will be hosted on a domain that is not *.azurewebsites.net. Azure Front Door is an easy option that the template can set up automatically, but it comes with ongoing monthly costs. ')
@allowed([
  'Custom domain name (recommended)'
  'Azure Front Door'
])
param customDomainOption string = 'Azure Front Door'

@description('The app (and bot) display name.')
@minLength(1)
param appDisplayName string = 'Company Communicator'

@description('The app (and bot) description.')
@minLength(1)
param appDescription string = 'Broadcast messages to multiple teams and people in one go'

@description('The link to the icon for the app. It must resolve to a PNG file.')
@minLength(1)
param appIconUrl string = 'https://raw.githubusercontent.com/OfficeDev/microsoft-teams-company-communicator-app/main/Manifest/color.png'

@description('The ID of the tenant to which the app will be deployed.')
@minLength(1)
@maxLength(36)
param tenantId string = subscription().tenantId

@description('The pricing tier for the hosting plan.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param hostingPlanSku string = 'Standard'

@description('The size of the hosting plan (small, medium, or large).')
@allowed([
  '1'
  '2'
  '3'
])
param hostingPlanSize string = '2'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('A GUID used to identify the role assignment. This is Default value.')
@minLength(1)
param serviceBusWebAppRoleNameGuid string = newGuid()

@description('A GUID used to identify the role assignment. This is Default value.')
@minLength(1)
param serviceBusPrepFuncRoleNameGuid string = newGuid()

@description('A GUID used to identify the role assignment. This is Default value.')
@minLength(1)
param serviceBusApiSendFuncRoleNameGuid string = newGuid()

@description('A GUID used to identify the role assignment. This is Default value.')
@minLength(1)
param serviceBusSendFuncRoleNameGuid string = newGuid()

@description('A GUID used to identify the role assignment. This is Default value.')
@minLength(1)
param serviceBusDataFuncRoleNameGuid string = newGuid()

@description('A GUID used to identify the role assignment. This is Default value.')
@minLength(1)
param storageAccountWebAppRoleNameGuid string = newGuid()

@description('A GUID used to identify the role assignment. This is Default value.')
@minLength(1)
param storageAccountPrepFuncRoleNameGuid string = newGuid()

@description('A GUID used to identify the role assignment. This is Default value.')
@minLength(1)
param storageAccountApiSendFuncRoleNameGuid string = newGuid()

@description('A GUID used to identify the role assignment. This is Default value.')
@minLength(1)
param storageAccountDataFuncRoleNameGuid string = newGuid()

var botAppName_var = '${baseResourceName}${uniqueString(resourceGroup().id)}-bot-app'
var hostingPlanName_var = '${baseResourceName}${uniqueString(resourceGroup().id)}-hosting'
var appInsightsName_var  = '${baseResourceName}${uniqueString(resourceGroup().id)}-app-insights'
var botName_var = '${baseResourceName}${uniqueString(resourceGroup().id)}-bot'
var authorBotName_var = '${baseResourceName}${uniqueString(resourceGroup().id)}-author'
var botAppDomain = '${botAppName_var}.azurewebsites.net'
var botAppUrl = 'https://${botAppDomain}'
var storageAccountName_var_value = toLower(replace('${baseResourceName}${uniqueString(resourceGroup().id)}stg','-',''))
var storageAccountName_var = length(storageAccountName_var_value) > 24 ? substring(replace(storageAccountName_var_value,'-',''),0,24) : storageAccountName_var_value
var prepFunctionAppName_var = '${baseResourceName}${uniqueString(resourceGroup().id)}-prep-function'
var sendFunctionAppName_var = '${baseResourceName}${uniqueString(resourceGroup().id)}-function'
var dataFunctionAppName_var = '${baseResourceName}${uniqueString(resourceGroup().id)}-data-function'
var apiSendFunctionAppName_var = '${baseResourceName}${uniqueString(resourceGroup().id)}-apisend-function'
var serviceBusNamespaceName_var = '${baseResourceName}${uniqueString(resourceGroup().id)}-sbns'
var serviceBusSendQueueName = 'company-communicator-send'
var serviceBusDataQueueName = 'company-communicator-data'
var serviceBusPrepareToSendQueueName = 'company-communicator-prep'
var serviceBusExportQueueName = 'company-communicator-export'
var defaultSASKeyName = 'RootManageSharedAccessKey'
var authRuleResourceId = resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', serviceBusNamespaceName_var, defaultSASKeyName)
var sharedSkus = [
  'Free'
  'Shared'
]
var isSharedPlan = contains(sharedSkus, hostingPlanSku)
var skuFamily = ((hostingPlanSku == 'Shared') ? 'D' : take(hostingPlanSku, 1))
var useFrontDoor = (customDomainOption == 'Azure Front Door')
var frontDoorName_var = baseResourceName
var frontDoorDomain = toLower('${frontDoorName_var}.azurefd.net')
var ProactivelyInstallUserApp_var = ProactivelyInstallUserApp
var UserAppExternalId_var = UserAppExternalId
var i18n_DefaultCulture = DefaultCulture
var i18n_SupportedCultures = SupportedCultures
var AzureserviceBusDataOwner = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/090c5cfd-751d-490a-894a-3ce6f1109419'
var StorageBlobDataContributor = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var keyvaultName_var = length('kv-${botAppName_var}') > 24 ? substring('kv-${botAppName_var}',0,24) : 'kv-${botAppName_var}'
var keyVaultUrl = 'https://${keyvaultName_var}.vault.azure.net'
var subscriptionTenantId = subscription().tenantId
var StorageAccountSecretName = '${keyvaultName_var}StorageAccountConnectionString'
var ServiceBusSecretName = '${keyvaultName_var}ServiceBusConnectionString'
var AppInsightsSecretName = '${keyvaultName_var}AppInsightsKey'
var UserAppSecretName = '${keyvaultName_var}UserAppPassword'
var AuthorAppSecretName = '${keyvaultName_var}AuthorAppPassword'
var GraphAppSecretName = '${keyvaultName_var}GraphAppPassword'
var StorageAccountSecretResourceId = resourceId(resourceGroup().name, 'Microsoft.KeyVault/vaults/secrets', keyvaultName_var, StorageAccountSecretName)
var ServiceBusSecretResourceId = resourceId(resourceGroup().name, 'Microsoft.KeyVault/vaults/secrets', keyvaultName_var, ServiceBusSecretName)
var AppInsightsSecretResourceId = resourceId(resourceGroup().name, 'Microsoft.KeyVault/vaults/secrets', keyvaultName_var, AppInsightsSecretName)
var UserAppSecretResourceId = resourceId(resourceGroup().name, 'Microsoft.KeyVault/vaults/secrets', keyvaultName_var, UserAppSecretName)
var AuthorAppSecretResourceId = resourceId(resourceGroup().name, 'Microsoft.KeyVault/vaults/secrets', keyvaultName_var, AuthorAppSecretName)
var GraphAppSecretResourceId = resourceId(resourceGroup().name, 'Microsoft.KeyVault/vaults/secrets', keyvaultName_var, GraphAppSecretName)

resource storageAccountName 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName_var
  location: location
  kind: 'Storage'
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
  sku: {
    name: 'Standard_LRS'
  }
}

resource serviceBusNamespaceName 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: serviceBusNamespaceName_var
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

resource serviceBusNamespaceName_serviceBusSendQueueName 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: serviceBusNamespaceName
  name: serviceBusSendQueueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    status: 'Active'
    enablePartitioning: false
    enableExpress: false
  }
}

resource serviceBusNamespaceName_serviceBusDataQueueName 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: serviceBusNamespaceName
  name: serviceBusDataQueueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    status: 'Active'
    enablePartitioning: false
    enableExpress: false
  }
}

resource serviceBusNamespaceName_serviceBusPrepareToSendQueueName 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: serviceBusNamespaceName
  name: serviceBusPrepareToSendQueueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    status: 'Active'
    enablePartitioning: false
    enableExpress: false
  }
}

resource serviceBusNamespaceName_serviceBusExportQueueName 'Microsoft.ServiceBus/namespaces/Queues@2017-04-01' = {
  parent: serviceBusNamespaceName
  name: serviceBusExportQueueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    status: 'Active'
    enablePartitioning: false
    enableExpress: false
  }
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName_var
  location: location
  properties: {
  }
  sku: {
    name: (isSharedPlan ? '${skuFamily}1' : '${skuFamily}${hostingPlanSize}')
    tier: hostingPlanSku
    size: '${skuFamily}${hostingPlanSize}'
    family: skuFamily
    capacity: 0
  }
}

resource appInsightsName 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName_var
  location: location
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${botAppName_var}': 'Resource'
  }
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
  kind: 'Component'
}

resource authorBotName 'Microsoft.BotService/botServices@2021-03-01' = {
  name: authorBotName_var
  location: 'global'
  sku: {
    name: 'F0'
  }
  kind: 'azurebot'
  properties: {
    displayName: '${appDisplayName}-author'
    description: appDescription
    iconUrl: appIconUrl
    msaAppId: authorClientId
    endpoint: '${botAppUrl}/api/messages/author'
    developerAppInsightKey: reference(appInsightsName.id, '2015-05-01').InstrumentationKey
  }
}

resource authorBotName_MsTeamsChannel 'Microsoft.BotService/botServices/channels@2021-03-01' = {
  parent: authorBotName
  name: 'MsTeamsChannel'
  location: 'global'
  sku: {
    name: 'F0'
  }
  properties: {
    channelName: 'MsTeamsChannel'
    location: 'global'
    properties: {
      isEnabled: true
    }
  }
}

resource botName 'Microsoft.BotService/botServices@2021-03-01' = {
  name: botName_var
  location: 'global'
  sku: {
    name: 'F0'
  }
  kind: 'azurebot'
  properties: {
    displayName: appDisplayName
    description: appDescription
    iconUrl: appIconUrl
    msaAppId: userClientId
    endpoint: '${botAppUrl}/api/messages/user'
    developerAppInsightKey: reference(appInsightsName.id, '2015-05-01').InstrumentationKey
  }
}

resource botName_MsTeamsChannel 'Microsoft.BotService/botServices/channels@2021-03-01' = {
  parent: botName
  name: 'MsTeamsChannel'
  location: 'global'
  sku: {
    name: 'F0'
  }
  properties: {
    channelName: 'MsTeamsChannel'
    location: 'global'
    properties: {
      isEnabled: true
    }
  }
}

resource botAppName 'Microsoft.Web/sites@2021-02-01' = {
  name: botAppName_var
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlanName.id
    enabled: true
    reserved: false
    clientAffinityEnabled: true
    clientCertEnabled: false
    hostNamesDisabled: false
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      alwaysOn: (!isSharedPlan)
      cors: {
        supportCredentials: true
        allowedOrigins: [
          'https://${frontDoorDomain}'
        ]
      }
    }
  }
  dependsOn: [
    storageAccountName
    appInsightsName
    serviceBusNamespaceName
    prepFunctionAppName
    sendFunctionAppName
    dataFunctionAppName
    apiSendFunctionAppName
  ]
}

resource botAppName_appsettings 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: botAppName
  name: 'appsettings'
  properties: {
    SITE_ROLE: 'app'
    'i18n:DefaultCulture': i18n_DefaultCulture
    'i18n:SupportedCultures': i18n_SupportedCultures
    ProactivelyInstallUserApp: ProactivelyInstallUserApp_var
    UserAppExternalId: UserAppExternalId_var
    'AzureAd:TenantId': tenantId
    'AzureAd:ClientId': graphAppId
    'AzureAd:ClientSecret': '@Microsoft.KeyVault(SecretUri=${reference(GraphAppSecretResourceId, '2015-06-01').secretUriWithVersion})'
    'AzureAd:ApplicationIdURI': (useFrontDoor ? 'api://${frontDoorDomain}' : '')
    UserAppId: userClientId
    UserAppPassword: '@Microsoft.KeyVault(SecretUri=${reference(UserAppSecretResourceId, '2015-06-01').secretUriWithVersion})'
    AuthorAppId: authorClientId
    AuthorAppPassword: '@Microsoft.KeyVault(SecretUri=${reference(AuthorAppSecretResourceId, '2015-06-01').secretUriWithVersion})'
    GraphAppId: graphAppId
    GraphAppPassword: '@Microsoft.KeyVault(SecretUri=${reference(GraphAppSecretResourceId, '2015-06-01').secretUriWithVersion})'
    StorageAccountConnectionString: '@Microsoft.KeyVault(SecretUri=${reference(StorageAccountSecretResourceId, '2015-06-01').secretUriWithVersion})'
    ServiceBusConnection: '@Microsoft.KeyVault(SecretUri=${reference(ServiceBusSecretResourceId, '2015-06-01').secretUriWithVersion})'
    ServiceBusNamespace: '${serviceBusNamespaceName_var}.servicebus.windows.net'
    StorageAccountName: storageAccountName_var
    UseManagedIdentity: 'true'
    AllowedTenants: tenantId
    DisableTenantFilter: 'false'
    AuthorizedCreatorUpns: senderUPNList
    UseCertificate: 'false'
    DisableAuthentication: 'false'
    DisableCreatorUpnCheck: 'false'
    WEBSITE_LOAD_CERTIFICATES: '*'
    APPINSIGHTS_INSTRUMENTATIONKEY: '@Microsoft.KeyVault(SecretUri=${reference(AppInsightsSecretResourceId, '2015-06-01').secretUriWithVersion})'
    WEBSITE_NODE_DEFAULT_VERSION: '16.13.0'
    'KeyVault:Url': keyVaultUrl
    DOTNET_ADD_GLOBAL_TOOLS_TO_PATH: 'false'
  }
  dependsOn: [
    keyvaultName
    keyvaultName_StorageAccountSecretName
    keyvaultName_ServiceBusSecretName
  ]
}

resource prepFunctionAppName 'Microsoft.Web/sites@2021-03-01' = {
  name: prepFunctionAppName_var
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlanName.id
    clientAffinityEnabled: false
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      alwaysOn: (!isSharedPlan)
    }
  }
  dependsOn: [
    storageAccountName
    serviceBusNamespaceName
  ]
}

resource prepFunctionAppName_appsettings 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: prepFunctionAppName
  name: 'appsettings'
  properties: {
    SITE_ROLE: 'function'
    'i18n:DefaultCulture': i18n_DefaultCulture
    'i18n:SupportedCultures': i18n_SupportedCultures
    ProactivelyInstallUserApp: ProactivelyInstallUserApp_var
    UserAppExternalId: UserAppExternalId_var
    TenantId: tenantId
    UserAppId: userClientId
    UserAppPassword: '@Microsoft.KeyVault(SecretUri=${reference(UserAppSecretResourceId, '2015-06-01').secretUriWithVersion})'
    AuthorAppId: authorClientId
    AuthorAppPassword: '@Microsoft.KeyVault(SecretUri=${reference(AuthorAppSecretResourceId, '2015-06-01').secretUriWithVersion})'
    GraphAppId: graphAppId
    GraphAppPassword: '@Microsoft.KeyVault(SecretUri=${reference(GraphAppSecretResourceId, '2015-06-01').secretUriWithVersion})'
    StorageAccountConnectionString: '@Microsoft.KeyVault(SecretUri=${reference(StorageAccountSecretResourceId, '2015-06-01').secretUriWithVersion})'
    ServiceBusConnection: '@Microsoft.KeyVault(SecretUri=${reference(ServiceBusSecretResourceId, '2015-06-01').secretUriWithVersion})'
    ServiceBusNamespace: '${serviceBusNamespaceName_var}.servicebus.windows.net'
    StorageAccountName: storageAccountName_var
    UseManagedIdentity: 'true'
    UseCertificate: 'false'
    WEBSITE_LOAD_CERTIFICATES: '*'
    APPINSIGHTS_INSTRUMENTATIONKEY: '@Microsoft.KeyVault(SecretUri=${reference(AppInsightsSecretResourceId, '2015-06-01').secretUriWithVersion})'
    'KeyVault:Url': keyVaultUrl
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys(storageAccountName.id, '2015-05-01-preview').key1}'
    AzureWebJobsDashboard: '@Microsoft.KeyVault(SecretUri=${reference(StorageAccountSecretResourceId, '2015-06-01').secretUriWithVersion})'
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys(storageAccountName.id, '2015-05-01-preview').key1}'
    WEBSITE_CONTENTSHARE: toLower(prepFunctionAppName_var)
    AzureFunctionsJobHost__extensions__durableTask__maxConcurrentOrchestratorFunctions: '3'
    AzureFunctionsJobHost__extensions__durableTask__maxConcurrentActivityFunctions: '10'
    DOTNET_ADD_GLOBAL_TOOLS_TO_PATH: 'false'
    WEBSITE_NODE_DEFAULT_VERSION: '16.13.0'
  }
  dependsOn: [
    keyvaultName
    keyvaultName_StorageAccountSecretName
    keyvaultName_ServiceBusSecretName
  ]
}


resource sendFunctionAppName 'Microsoft.Web/sites@2021-03-01' = {
  name: sendFunctionAppName_var
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlanName.id
    clientAffinityEnabled: false
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      alwaysOn: (!isSharedPlan)
    }
  }
  dependsOn: [
    storageAccountName
    serviceBusNamespaceName
  ]
}

resource sendFunctionAppName_appsettings 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: sendFunctionAppName
  name: 'appsettings'
  properties: {
    PROJECT: 'Source\\CompanyCommunicator.Send.Func\\Microsoft.Teams.Apps.CompanyCommunicator.Send.Func.csproj'
    SITE_ROLE: 'function'
    'i18n:DefaultCulture': i18n_DefaultCulture
    'i18n:SupportedCultures': i18n_SupportedCultures
    ProactivelyInstallUserApp: ProactivelyInstallUserApp_var
    UserAppId: userClientId
    UserAppPassword: '@Microsoft.KeyVault(SecretUri=${reference(UserAppSecretResourceId, '2015-06-01').secretUriWithVersion})'
    StorageAccountConnectionString: '@Microsoft.KeyVault(SecretUri=${reference(StorageAccountSecretResourceId, '2015-06-01').secretUriWithVersion})'
    ServiceBusConnection: '@Microsoft.KeyVault(SecretUri=${reference(ServiceBusSecretResourceId, '2015-06-01').secretUriWithVersion})'
    ServiceBusNamespace: '${serviceBusNamespaceName_var}.servicebus.windows.net'
    StorageAccountName: storageAccountName_var
    UseManagedIdentity: 'true'
    UseCertificate: 'false'
    MaxNumberOfAttempts: '5'
    WEBSITE_LOAD_CERTIFICATES: '*'
    APPINSIGHTS_INSTRUMENTATIONKEY: '@Microsoft.KeyVault(SecretUri=${reference(AppInsightsSecretResourceId, '2015-06-01').secretUriWithVersion})'
    'KeyVault:Url': keyVaultUrl
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys(storageAccountName.id, '2015-05-01-preview').key1}'
    AzureWebJobsDashboard: '@Microsoft.KeyVault(SecretUri=${reference(StorageAccountSecretResourceId, '2015-06-01').secretUriWithVersion})'
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys(storageAccountName.id, '2015-05-01-preview').key1}'
    WEBSITE_CONTENTSHARE: toLower(sendFunctionAppName_var)
    DOTNET_ADD_GLOBAL_TOOLS_TO_PATH: 'false'
    WEBSITE_NODE_DEFAULT_VERSION: '16.13.0'
  }
  dependsOn: [
    keyvaultName
    keyvaultName_StorageAccountSecretName
    keyvaultName_ServiceBusSecretName
  ]
}


resource dataFunctionAppName 'Microsoft.Web/sites@2022-03-01' = {
  name: dataFunctionAppName_var
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlanName.id
    clientAffinityEnabled: false
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      alwaysOn: (!isSharedPlan)
    }
  }
  dependsOn: [
    storageAccountName
    serviceBusNamespaceName
  ]
}

resource dataFunctionAppName_appsettings 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: dataFunctionAppName
  name: 'appsettings'
  properties: {
    PROJECT: 'Source\\CompanyCommunicator.Data.Func\\Microsoft.Teams.Apps.CompanyCommunicator.Data.Func.csproj'
    SITE_ROLE: 'function'
    'i18n:DefaultCulture': i18n_DefaultCulture
    'i18n:SupportedCultures': i18n_SupportedCultures
    ProactivelyInstallUserApp: ProactivelyInstallUserApp_var
    UserAppId: userClientId
    UserAppPassword: '@Microsoft.KeyVault(SecretUri=${reference(UserAppSecretResourceId, '2015-06-01').secretUriWithVersion})'
    AuthorAppId: authorClientId
    AuthorAppPassword: '@Microsoft.KeyVault(SecretUri=${reference(AuthorAppSecretResourceId, '2015-06-01').secretUriWithVersion})'
    StorageAccountConnectionString: '@Microsoft.KeyVault(SecretUri=${reference(StorageAccountSecretResourceId, '2015-06-01').secretUriWithVersion})'
    ServiceBusConnection: '@Microsoft.KeyVault(SecretUri=${reference(ServiceBusSecretResourceId, '2015-06-01').secretUriWithVersion})'
    ServiceBusNamespace: '${serviceBusNamespaceName_var}.servicebus.windows.net'
    StorageAccountName: storageAccountName_var
    UseManagedIdentity: 'true'
    UseCertificate: 'false'
    WEBSITE_LOAD_CERTIFICATES: '*'
    APPINSIGHTS_INSTRUMENTATIONKEY: '@Microsoft.KeyVault(SecretUri=${reference(AppInsightsSecretResourceId, '2015-06-01').secretUriWithVersion})'
    'KeyVault:Url': keyVaultUrl
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys(storageAccountName.id, '2015-05-01-preview').key1}'
    AzureWebJobsDashboard: '@Microsoft.KeyVault(SecretUri=${reference(StorageAccountSecretResourceId, '2015-06-01').secretUriWithVersion})'
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys(storageAccountName.id, '2015-05-01-preview').key1}'
    WEBSITE_CONTENTSHARE: toLower(dataFunctionAppName_var)
    CleanUpScheduleTriggerTime: '30 23 * * *'
    CleanUpFile: '1'
    DOTNET_ADD_GLOBAL_TOOLS_TO_PATH: 'false'
    WEBSITE_NODE_DEFAULT_VERSION: '16.13.0'
  }
  dependsOn: [
    keyvaultName
    keyvaultName_StorageAccountSecretName
    keyvaultName_ServiceBusSecretName
  ]
}

resource apiSendFunctionAppName 'Microsoft.Web/sites@2022-03-01' = {
  name: apiSendFunctionAppName_var
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlanName.id
    clientAffinityEnabled: false
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      alwaysOn: (!isSharedPlan)
    }
  }
  dependsOn: [
    storageAccountName
    serviceBusNamespaceName
  ]
}

resource apiSendFunctionAppName_appsettings 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: apiSendFunctionAppName
  name: 'appsettings'
  properties: {
    PROJECT: 'Source\\Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func\\Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.csproj'
    SITE_ROLE: 'function'
    'i18n:DefaultCulture': i18n_DefaultCulture
    'i18n:SupportedCultures': i18n_SupportedCultures
    ProactivelyInstallUserApp: ProactivelyInstallUserApp_var
    UserAppId: userClientId
    UserAppPassword: '@Microsoft.KeyVault(SecretUri=${reference(UserAppSecretResourceId, '2022-07-01').secretUriWithVersion})'
    AuthorAppId: authorClientId
    AuthorAppPassword: '@Microsoft.KeyVault(SecretUri=${reference(AuthorAppSecretResourceId, '2022-07-01').secretUriWithVersion})'
    StorageAccountConnectionString: '@Microsoft.KeyVault(SecretUri=${reference(StorageAccountSecretResourceId, '2022-07-01').secretUriWithVersion})'
    ServiceBusConnection: '@Microsoft.KeyVault(SecretUri=${reference(ServiceBusSecretResourceId, '2022-07-01').secretUriWithVersion})'
    ServiceBusNamespace: '${serviceBusNamespaceName_var}.servicebus.windows.net'
    StorageAccountName: storageAccountName_var
    UseManagedIdentity: 'true'
    UseCertificate: 'false'
    WEBSITE_LOAD_CERTIFICATES: '*'
    GraphAppId: graphAppId
    GraphAppPassword: '@Microsoft.KeyVault(SecretUri=${reference(GraphAppSecretResourceId, '2015-06-01').secretUriWithVersion})'
    APPINSIGHTS_INSTRUMENTATIONKEY: '@Microsoft.KeyVault(SecretUri=${reference(AppInsightsSecretResourceId, '2022-07-01').secretUriWithVersion})'
    'KeyVault:Url': keyVaultUrl
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys(storageAccountName.id, '2015-05-01-preview').key1}'
    AzureWebJobsDashboard: '@Microsoft.KeyVault(SecretUri=${reference(StorageAccountSecretResourceId, '2022-07-01').secretUriWithVersion})'
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys(storageAccountName.id, '2015-05-01-preview').key1}'
    WEBSITE_CONTENTSHARE: toLower(apiSendFunctionAppName_var)
    CleanUpScheduleTriggerTime: '30 23 * * *'
    CleanUpFile: '1'
    DOTNET_ADD_GLOBAL_TOOLS_TO_PATH: 'false'
    WEBSITE_NODE_DEFAULT_VERSION: '16.13.0'
  }
  dependsOn: [
    keyvaultName
    keyvaultName_StorageAccountSecretName
    keyvaultName_ServiceBusSecretName
  ]
}


resource keyvaultName 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyvaultName_var
  location: location
  tags: {
    displayName: 'KeyVault'
  }
  properties: {
    tenantId: subscriptionTenantId
    enableSoftDelete: true
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    accessPolicies: [
      {
        tenantId: reference('Microsoft.Web/sites/${botAppName_var}', '2018-02-01', 'Full').identity.tenantId
        objectId: reference('Microsoft.Web/sites/${botAppName_var}', '2018-02-01', 'Full').identity.principalId
        permissions: {
          keys: []
          secrets: [
            'get'
            'set'
            'restore'
          ]
          certificates: []
        }
        // applicationId:botAppName.id
      }
      {
        tenantId: reference('Microsoft.Web/sites/${prepFunctionAppName_var}', '2018-02-01', 'Full').identity.tenantId
        objectId: reference('Microsoft.Web/sites/${prepFunctionAppName_var}', '2018-02-01', 'Full').identity.principalId
        permissions: {
          keys: []
          secrets: [
            'get'
          ]
          certificates: [
            'get'
          ]
        }
        // applicationId:prepFunctionAppName.id
      }
      {
        tenantId: reference('Microsoft.Web/sites/${sendFunctionAppName_var}', '2018-02-01', 'Full').identity.tenantId
        objectId: reference('Microsoft.Web/sites/${sendFunctionAppName_var}', '2018-02-01', 'Full').identity.principalId
        permissions: {
          keys: []
          secrets: [
            'get'
          ]
          certificates: [
            'get'
          ]
        }
         // applicationId:sendFunctionAppName.id
      }
      {
        tenantId: reference('Microsoft.Web/sites/${dataFunctionAppName_var}', '2018-02-01', 'Full').identity.tenantId
        objectId: reference('Microsoft.Web/sites/${dataFunctionAppName_var}', '2018-02-01', 'Full').identity.principalId
        permissions: {
          keys: []
          secrets: [
            'get'
          ]
          certificates: [
            'get'
          ]
        }
        // applicationId:dataFunctionAppName.id
      }
      {
        tenantId: reference('Microsoft.Web/sites/${apiSendFunctionAppName_var}', '2018-02-01', 'Full').identity.tenantId
        objectId: reference('Microsoft.Web/sites/${apiSendFunctionAppName_var}', '2018-02-01', 'Full').identity.principalId
        permissions: {
          keys: []
          secrets: [
            'get'
          ]
          certificates: [
            'get'
          ]
        }
        // applicationId:apiSendFunctionAppName.id
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource keyvaultName_StorageAccountSecretName 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  parent: keyvaultName
  name: StorageAccountSecretName
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys(storageAccountName.id, '2015-05-01-preview').key1}'
    attributes: {
      enabled: true
    }
  }
}

resource keyvaultName_ServiceBusSecretName 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  parent: keyvaultName
  name: ServiceBusSecretName
  properties: {
    value: listkeys(authRuleResourceId, '2017-04-01').primaryConnectionString
    attributes: {
      enabled: true
    }
  }
  dependsOn: [
    serviceBusNamespaceName
  ]
}

resource keyvaultName_UserAppSecretName 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  parent: keyvaultName
  name: UserAppSecretName
  properties: {
    value: userClientSecret
    attributes: {
      enabled: true
    }
  }
}

resource keyvaultName_AuthorAppSecretName 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  parent: keyvaultName
  name: AuthorAppSecretName
  properties: {
    value: authorClientSecret
    attributes: {
      enabled: true
    }
  }
}

resource keyvaultName_GraphAppSecretName 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  parent: keyvaultName
  name: GraphAppSecretName
  properties: {
    value: graphAppSecret
    attributes: {
      enabled: true
    }
  }
}

resource keyvaultName_AppInsightsSecretName 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  parent: keyvaultName
  name: AppInsightsSecretName
  properties: {
    value: reference(appInsightsName.id, '2015-05-01').InstrumentationKey
    attributes: {
      enabled: true
    }
  }
}

resource ServiceBusWebAppRoleNameGuid_resource 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  scope: serviceBusNamespaceName
  name: serviceBusWebAppRoleNameGuid
  properties: {
    roleDefinitionId: AzureserviceBusDataOwner
    principalId: reference(botAppName.id, '2019-08-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource ServiceBusPrepFuncRoleNameGuid_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: serviceBusNamespaceName
  name: serviceBusPrepFuncRoleNameGuid
  properties: {
    roleDefinitionId: AzureserviceBusDataOwner
    principalId: reference(prepFunctionAppName.id, '2019-08-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource ServiceBusSendFuncRoleNameGuid_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: serviceBusNamespaceName
  name: serviceBusSendFuncRoleNameGuid
  properties: {
    roleDefinitionId: AzureserviceBusDataOwner
    principalId: reference(sendFunctionAppName.id, '2019-08-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource ServiceBusDataFuncRoleNameGuid_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: serviceBusNamespaceName
  name: serviceBusDataFuncRoleNameGuid
  properties: {
    roleDefinitionId: AzureserviceBusDataOwner
    principalId: reference(dataFunctionAppName.id, '2019-08-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource ServiceBusApiSendFuncRoleNameGuid_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: serviceBusNamespaceName
  name: serviceBusApiSendFuncRoleNameGuid
  properties: {
    roleDefinitionId: AzureserviceBusDataOwner
    principalId: reference(apiSendFunctionAppName.id, '2019-08-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource StorageAccountWebAppRoleNameGuid_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccountName
  name: storageAccountWebAppRoleNameGuid
  properties: {
    roleDefinitionId: StorageBlobDataContributor
    principalId: reference(botAppName.id, '2019-08-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource StorageAccountPrepFuncRoleNameGuid_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccountName
  name: storageAccountPrepFuncRoleNameGuid
  properties: {
    roleDefinitionId: StorageBlobDataContributor
    principalId: reference(prepFunctionAppName.id, '2019-08-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource StorageAccountDataFuncRoleNameGuid_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccountName
  name: storageAccountDataFuncRoleNameGuid
  properties: {
    roleDefinitionId: StorageBlobDataContributor
    principalId: reference(dataFunctionAppName.id, '2019-08-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource StorageAccountApiSendFuncRoleNameGuid_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccountName
  name: storageAccountApiSendFuncRoleNameGuid
  properties: {
    roleDefinitionId: StorageBlobDataContributor
    principalId: reference(apiSendFunctionAppName.id, '2019-08-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource frontDoorName 'Microsoft.Network/frontDoors@2020-05-01' = if (useFrontDoor) {
  name: frontDoorName_var
  location: 'Global'
  properties: {
    backendPools: [
      {
        name: 'backendPool1'
        properties: {
          backends: [
            {
              address: botAppDomain
              backendHostHeader: botAppDomain
              httpPort: 80
              httpsPort: 443
              priority: 1
              weight: 50
              enabledState: 'Enabled'
            }
          ]
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', frontDoorName_var, 'healthProbeSettings1')
          }
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors/loadBalancingSettings', frontDoorName_var, 'loadBalancingSettings1')
          }
        }
      }
    ]
    healthProbeSettings: [
      {
        name: 'healthProbeSettings1'
        properties: {
          intervalInSeconds: 255
          path: '/health'
          protocol: 'Https'
        }
      }
    ]
    frontendEndpoints: [
      {
        name: 'frontendEndpoint1'
        properties: {
          hostName: frontDoorDomain
          sessionAffinityEnabledState: 'Disabled'
          sessionAffinityTtlSeconds: 0
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: 'loadBalancingSettings1'
        properties: {
          additionalLatencyMilliseconds: 0
          sampleSize: 4
          successfulSamplesRequired: 2
        }
      }
    ]
    routingRules: [
      {
        name: 'routingRule1'
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/frontendEndpoints', frontDoorName_var, 'frontendEndpoint1')
            }
          ]
          acceptedProtocols: [
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'HttpsOnly'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/backendPools', frontDoorName_var, 'backendPool1')
            }
          }
          enabledState: 'Enabled'
        }
      }
      {
        name: 'routingRule2'
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/frontendEndpoints', frontDoorName_var, 'frontendEndpoint1')
            }
          ]
          acceptedProtocols: [
            'Https'
          ]
          patternsToMatch: [
            '/api/*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorRedirectConfiguration'
            customFragment: null
            customHost: botAppDomain
            customPath: ''
            redirectProtocol: 'HttpsOnly'
            customQueryString: null
            redirectType: 'PermanentRedirect'
          }
          enabledState: 'Enabled'
        }
      }
    ]
    enabledState: 'Enabled'
    friendlyName: frontDoorName_var
  }
  dependsOn: [
    botAppName
  ]
}


output keyVaultName string = keyvaultName_var
output authorBotId string = authorClientId
output userBotId string = userClientId
output appDomain string = (useFrontDoor ? frontDoorDomain : 'Please create a custom domain name for ${botAppDomain} and use that in the manifest')
output botAppName string = botAppName.name
output prepFunctionAppName string = prepFunctionAppName.name
output sendFunctionAppName string = sendFunctionAppName.name
output dataFunctionAppName string = dataFunctionAppName.name
output apiSendFunctionAppName string = apiSendFunctionAppName.name
