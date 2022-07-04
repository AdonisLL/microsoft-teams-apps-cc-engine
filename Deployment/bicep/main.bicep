param baseResourceName string
param senderUPNList string
param location string
param authorResourceAppId string = newGuid()
param userResourceAppId string = newGuid()
param graphResourceAppId string = newGuid()



module userAppModule 'aadresources.bicep' = {
  name:'userApp'
  params:{

    location:location
    resourceAppId:userResourceAppId
    name:'${baseResourceName}-users'
  }
}


module authorAppModule 'aadresources.bicep' = {
  name:'authorApp'
  params:{
    location:location
    resourceAppId:authorResourceAppId
    name:'${baseResourceName}-authors'
  }
}

module graphAppModule 'aadresources.bicep' = {
  name:'graphAppModule'
  params:{
    location:location
    resourceAppId:graphResourceAppId
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
