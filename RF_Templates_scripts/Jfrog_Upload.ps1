param(
    [Parameter(Mandatory = $true)]
    [string]$Jfrog_Username,
    [Parameter(Mandatory = $true)]
    [string]$Jfrog_Token,
    [Parameter(Mandatory = $true)]
    [string]$JfrogReponame,
    [Parameter(Mandatory = $true)]
    [string]$Package,
    [Parameter(Mandatory = $true)]
    [string]$Url    ,
    [Parameter(Mandatory = $true)]
    [string]$Filepath

)


write-host "Username: $Jfrog_Username"
write-host "Jfrog_Token: $Jfrog_Token"
write-host "Package: $Package"
write-host "JfrogRepo: $JfrogReponame"
write-host "Url: $Url"

try{
Write-host "Uploading the package..."


$jfrogdesturl="$Url/$JfrogReponame/arp/$Package"
Write-host "jfrogdesturl: $jfrogdesturl"

$credential_bytes = [System.Text.Encoding]::UTF8.GetBytes($Username + ":" + $Jfrog_Token)
$credentials = [System.Convert]::ToBase64String($credential_bytes)
$credential_header = "Basic " + $credentials    
$res=Invoke-WebRequest -Uri $jfrogdesturl -InFile "$Filepath" -Method Put -Headers @{"Authorization"="$credential_header"} -UseBasicParsing


if($res.StatusCode -eq 201){
write-host "Package uploaded successfully"
}else{
throw "response error $res.StatusCode"
}

}catch
{
 Write-Error "An error occurred while uploading. Error: $_" 

        exit 1
}


