param baseResourceName string
param senderUPNList string
param location string
param appName string

module userAppModule 'aadresources.bicep' = {
  name:'userApp'
  params:{
    appName: appName
    location:location
    name:'${baseResourceName}-users'
  }
}


module authorAppModule 'aadresources.bicep' = {
  name:'authorApp'
  params:{
    appName: appName
    location:location
    name:'${baseResourceName}-authors'
  }
}

module graphAppModule 'aadresources.bicep' = {
  name:'graphAppModule'
  params:{
    location:location
    name:'${baseResourceName}-graph'
    appName: appName
  }
}


module deploy 'deploy.bicep' = {
  name:'deploy'
  params:{
    authorClientId: authorAppModule.outputs.clientId
    authorClientSecret: authorAppModule.outputs.clientSecret
    baseResourceName: baseResourceName
    graphAppId: graphAppModule.outputs.clientId
    graphAppSecret: graphAppModule.outputs.clientSecret
    senderUPNList: senderUPNList
    userClientId: userAppModule.outputs.clientId
    userClientSecret: userAppModule.outputs.clientSecret
    location: location
  }
  dependsOn:[graphAppModule,userAppModule,authorAppModule]
}


output keyVaultName string = deploy.outputs.keyVaultName
output authorBotId string = deploy.outputs.authorBotId
output userBotId string = deploy.outputs.userBotId
output botAppName string = deploy.outputs.botAppName
output prepFunctionAppName string = deploy.outputs.prepFunctionAppName
output sendFunctionAppName string = deploy.outputs.sendFunctionAppName
output dataFunctionAppName string = deploy.outputs.dataFunctionAppName
output apiSendFunctionAppName string = deploy.outputs.apiSendFunctionAppName
