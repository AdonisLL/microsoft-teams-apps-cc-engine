param baseResourceName string
param senderUPNList string
param location string



module userAppModule 'aadresources.bicep' = {
  name:'userApp'
  params:{

    location:location
    name:'${baseResourceName}-users'
  }
}


module authorAppModule 'aadresources.bicep' = {
  name:'authorApp'
  params:{
    location:location
    name:'${baseResourceName}-authors'
  }
}

module graphAppModule 'aadresources.bicep' = {
  name:'graphAppModule'
  params:{
    location:location
    name:'${baseResourceName}-graph'
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
}


output keyVaultName string = deploy.outputs.keyVaultName
output authorBotId string = deploy.outputs.authorBotId
output userBotId string = deploy.outputs.userBotId
output botAppName string = deploy.outputs.botAppName
output prepFunctionAppName string = deploy.outputs.prepFunctionAppName
output sendFunctionAppName string = deploy.outputs.sendFunctionAppName
output dataFunctionAppName string = deploy.outputs.dataFunctionAppName
output apiSendFunctionAppName string = deploy.outputs.apiSendFunctionAppName
