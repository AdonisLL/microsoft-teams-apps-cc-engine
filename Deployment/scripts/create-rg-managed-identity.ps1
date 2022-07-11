#!/bin/bash
Write-Host 'Step to get AZ Access Token'

# Write-Host 'Install MS Graph Module'
# Install-Module Microsoft.Graph -Scope CurrentUsers

# Write-Host 'Install AZ Accounts Module'
# Install-Module -Name Az

$token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Write-Host $token
Connect-MgGraph -AccessToken $token.Token

$AppName = $env:AppName
$resourceGroupName = $env:resourceGroupName

#$appregId = az identity create -g rg-company-communicator -n AppRegCreator --out tsv --query principalId

$appregId = az identity create -g $resourceGroupName -n $AppName --out tsv --query principalId

Write-Host 'Sleeping for 60 seconds..... for user creation' -BackgroundColor Green
Start-Sleep -Seconds 60


$checkUri = "https://graph.microsoft.com/v1.0//roleManagement/directory/roleAssignments?$filter=principalId eq '$appregId'" 

$results = az rest --method get --uri $checkUri --headers Content-Type=application/json --query value | convertfrom-json
$exists = ($results | Where-Object {$_.principalId -eq "$appregId"}).principalId

if($null -eq $exists) {
    $roleDefinitionId = '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3'
    $directoryScopeId = "/"
    $body = "{'principalId':'$appregId','roleDefinitionId':'$roleDefinitionId','directoryScopeId':'$directoryScopeId'}"
    $uri = "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignments"
    az rest --method post --uri $uri --body $body --headers Content-Type=application/json 
}


Write-Host "Managed Identity creation or verification successfull" -BackgroundColor Green
