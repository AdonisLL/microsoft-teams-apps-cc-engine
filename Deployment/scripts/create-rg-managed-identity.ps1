#!/bin/bash

$token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Connect-MgGraph -AccessToken $token.Token


$appregId = az identity create -g rg-company-communicator -n AppRegCreator --out tsv --query principalId

$checkUri = "https://graph.microsoft.com/v1.0//roleManagement/directory/roleAssignments?$filter=principalId eq '$appregId'" 
az rest --method get --uri $checkUri --headers Content-Type=application/json --query "[].{principalId:principalId}[?principalId=='$appredId']" -o table


$results = az rest --method get --uri $checkUri --headers Content-Type=application/json --query value | convertfrom-json
$exists = ($results | Where-Object {$_.principalId -eq "$appregId"}).principalId

if(!$exists) {
    $principalId = $appregId
    $roleDefinitionId = '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3'
    $directoryScopeId = "/"
    $body = "{'principalId':'$appregId','roleDefinitionId':'$roleDefinitionId','directoryScopeId':'$directoryScopeId'}"
    $uri = "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignments"
    az rest --method post --uri $uri --body $body --headers Content-Type=application/json 
}


Write-Host "Managed Identity creation or verification successfull" -BackgroundColor Green
