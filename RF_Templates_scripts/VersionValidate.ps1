Param
(
    [Parameter(Mandatory=$true)]
    [string]$newversion,
    [Parameter(Mandatory=$true)]
    [string]$url,
    [Parameter(Mandatory=$true)]
    [string]$proxy
)
Write-Host "url: $url"
#$url = "https://devappregistrymarketplace.azurewebsites.net/api/appcontainers/global/inbuilt-apps/somoveng"
$output = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json"  -Proxy $proxy
$versions=$output.versions.version

$nextversion = $newversion
$portalversion=$versions | Measure-Object -Maximum

Write-Host "From portal version:"  $portalversion.Maximum
Write-Host "Next Version: $nextversion"

if([version]$portalversion.Maximum -lt [version]$nextversion){
 write-host "Portal Version" $portalversion.Maximum "is less than Next Verison $nextversion. Deploy the new version $nextversion of app"
Write-Host "##vso[task.setvariable variable=Deploy;]$true"
}elseif([version]$portalversion.Maximum -gt [version]$nextversion)
{ write-host "Portal Version" $portalversion.Maximum "is greater than Next Verison $nextversion. Do nothing!!!!!!!!!" 
Write-Host "##vso[task.setvariable variable=Deploy;]$false"
}
elseif([version]$portalversion.Maximum -eq [version]$nextversion)
{ write-host "Portal Version" $portalversion.Maximum "is the same as Next Verison $nextversion. Do nothing!!!!!!!!!" 
Write-Host "##vso[task.setvariable variable=Deploy;]$false"
}

