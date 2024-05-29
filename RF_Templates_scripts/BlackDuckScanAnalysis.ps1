 
 param(
[Parameter(Mandatory=$true)]
[string]$BlackDuckAPITOKEN,
[Parameter(Mandatory=$true)]
[string]$Product,
[Parameter(Mandatory=$true)]
[string]$BlackDuckURL,
[Parameter(Mandatory=$true)]
[string]$ProductVersion
)

try{

    ## Generate BearerToken

    Write-host "Generate BearerToken" -BackgroundColor Blue 

    $Authheader = @{
    'Authorization'= "token $BlackDuckAPITOKEN"
    'Accept'= 'application/vnd.blackducksoftware.user-4+json'
        }
    $root = $BlackDuckURL+ "/api/tokens/authenticate"
    Write-host $root
    Write-host $BlackDuckAPITOKEN
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    write-host "Invoke-RestMethod $root -Headers $Authheader -Method Post"
    $bearerToken = Invoke-RestMethod $root -Headers $Authheader -Method Post

    ## Get the Project data $Product
    Write-host "Get the Project data $Product" -BackgroundColor Blue 

    $btoken=$bearerToken.bearerToken
    $rootprojects = $BlackDuckURL+"/api/projects?q=name%3A" + $Product
    Write-Host $rootprojects
    $bearerheader = @{
        Authorization = "Bearer $btoken"
        #Accept= "*/*"
        Accept= "application/vnd.blackducksoftware.project-detail-4+json"
        "Content-Type"= "application/json"
        }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $projectsresult = Invoke-RestMethod $rootprojects -Headers $bearerheader -Method Get

    #if([string]::IsNullOrEmpty($projectsresult)){ Throw "Product/Project not found"}
    if($projectsresult.totalCount -eq 0){ Throw "Product/Project not found"}

    ## Get the Version data $Product-$ProductVersion
    Write-host "Get the version data $Product-$ProductVersion" -BackgroundColor Blue 
    
    $versions=$projectsresult.items._meta.links[0].href

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $versionsresult = Invoke-RestMethod $versions -Headers $bearerheader -Method Get

    foreach($version in $versionsresult.items)
    {
     if ($version.versionName -eq $ProductVersion)
     {
     $versionriskprofile=$version._meta.links[2].href
     }
    }

    if([string]::IsNullOrEmpty($versionriskprofile)){ Throw "Version not found"}

    ## Get the risk profile for $Product-$ProductVersion
    Write-host "Get the risk profile for $Product-$ProductVersion" -BackgroundColor Blue 

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $versionriskprofileresult = Invoke-RestMethod $versionriskprofile -Headers $bearerheader -Method Get

    $licenseRisk = $versionriskprofileresult.categories.LICENSE | Select Critical, High,Medium
    $SecurityRisk = $versionriskprofileresult.categories.VULNERABILITY | Select Critical, High ,Medium
    $operationalRisk =$versionriskprofileresult.categories.OPERATIONAL | Select Critical, High,Medium
    $endpoint=$versionriskprofileresult._meta.links.href+"/components"

    Write-Host "licenseRisk :: $licenseRisk" -BackgroundColor DarkYellow
    Write-Host "OperationalRisk :: $operationalRisk" -BackgroundColor DarkYellow
    Write-Host "SecurityRisk :: $SecurityRisk" -BackgroundColor DarkYellow
    Write-Host "endpoint:$endpoint"


    Write-Host ("##vso[task.setvariable variable=BDHLiceRisk;]$licenseRisk") 
    Write-Host ("##vso[task.setvariable variable=BDHOperRisk;]$operationalRisk") 
    Write-Host ("##vso[task.setvariable variable=BDHSecuRisk;]$SecurityRisk") 
     Write-Host ("##vso[task.setvariable variable=BDHUrl;]$endpoint") 


      


 }
 catch 
{
    Write-Host "##vso[task.logissue type=error;]Error- $($error[0].Exception)" -ForegroundColor DarkRed
    "##vso[task.complete result=Failed;]"
} 


 #   $(BlackDuckURL)/api/projects/9e648586-060f-4a7a-92e2-fe82f08497b7/versions/8bd1a493-1399-489b-a26b-c7b23c96114a/riskprofile
##curl.exe -X POST "$(BlackDuckURL)/api/tokens/authenticate" -H "Accept: application/vnd.blackducksoftware.user-4+json" -H "Authorization: token NzVjZWQ4NWMtMDgzYS00Yzc4LTg0ZWEtMjdhOWUyZmZkNWRkOmQ4NzgwNTY1LTQ4NDUtNGZjNC04M2UwLTUxZDQ4NjVkZDdmZg=="




