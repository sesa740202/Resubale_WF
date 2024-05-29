param(
[Parameter(Mandatory=$true)]
[string]$FortifyToken,
[Parameter(Mandatory=$true)]
[string]$FortifyURL,
[Parameter(Mandatory=$true)]
[string]$ProjectVersionID,
[Parameter(Mandatory=$true)]
[string]$ReportFormat,
[Parameter(Mandatory=$true)]
[string]$Reporttype,
[Parameter(Mandatory=$true)]
[string]$outputPath,
[Parameter(Mandatory=$true)]
[string]$FortifyReportDelToken,
[Parameter(Mandatory=$true)]
[string]$Buildnumber
)

try
{
$FortifyAPIURL = $FortifyURL + "/api/v1"
Write-Host "===== Fortify Report Generattion"
Write-Host "===== FortifyAPIURL: $FortifyAPIURL"


Function FetchProjVersionDetails()
{
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "FortifyToken $FortifyToken")
    $fetchProjVersionDetailsUri = "$FortifyAPIURL" + "/projectVersions/" + $ProjectVersionID
    $fetchProjVersionDetailsresponse = Invoke-RestMethod "$fetchProjVersionDetailsUri" -Method Get -Headers $headers 
    #$fetchProjVersionDetailsresponse
    if($fetchProjVersionDetailsresponse.responseCode -eq "200")
    {
    write-host "===== Fetch the project details for $ProjectVersionID"
    # $ApplicationName=$fetchProjVersionDetailsresponse.data.project.name
    # $ApplicationVersionID=$fetchProjVersionDetailsresponse.data.project.id
    # $ProjectVersionName=$fetchProjVersionDetailsresponse.data.name
     $projDetails = [PSCustomObject]@{
        ApplicationName=$fetchProjVersionDetailsresponse.data.project.name
        ApplicationVersionID=$fetchProjVersionDetailsresponse.data.project.id
        ProjectVersionName=$fetchProjVersionDetailsresponse.data.name
    }

    return $projDetails
    }
    else
    {
    throw "===== Unable to fetch project details"
    }

}

Function setReportType()
{
if($Reporttype -ieq "DeveloperWorkBench")
{
$payload_devloperWorkbench = "{
`n    `"name`": `"$ReportName`",
`n    `"note`": `"Devops Generated Report`",
`n    `"format`": `"$ReportFormat`",
`n    `"inputReportParameters`": [
`n        {
`n            `"name`": `"Key Terminology`",
`n            `"identifier`": `"IncludeSectionDescriptionOfKeyTerminology`",
`n            `"paramValue`": true,
`n            `"type`": `"BOOLEAN`"
`n        },
`n        {
`n            `"name`": `"About Fortify Solutions`",
`n            `"identifier`": `"IncludeSectionAboutFortifySecurity`",
`n            `"paramValue`": true,
`n            `"type`": `"BOOLEAN`"
`n        },
`n        {
`n            `"name`": `"Application Version`",
`n            `"identifier`": `"projectversionid`",
`n            `"paramValue`": $ProjectVersionID,
`n            `"type`": `"SINGLE_PROJECT`"
`n        }
`n    ],
`n    `"reportDefinitionId`": 10,
`n    `"type`": `"ISSUE`",
`n    `"project`": {
`n        `"id`": $ProjectVersionID,
`n        `"name`": `"$ProjectVersionName`",
`n        `"version`": {
`n         
`n            `"id`": $ApplicationVersionID,
`n                    `"name`": `"$ApplicationName`"
`n        }
`n    }
`n}"
}


return $payload_devloperWorkbench
}
function Generateuploadtoken()
{
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "FortifyToken $FortifyToken")
    $genuploadtokenuri = "$FortifyAPIURL" + "/fileTokens"
    $data = "{`"fileTokenType`":`"REPORT_FILE`"}"
    $genuploadtokenresponse = Invoke-RestMethod "$genuploadtokenuri" -Method POST -Headers $headers -Body $data
    #$genuploadtokenresponse
    $counter =0
    for($counter=0;$counter -le 3;$counter++)
    {
     $genuploadtokenresponse = Invoke-RestMethod "$genuploadtokenuri" -Method POST -Headers $headers -Body $data
     if($genuploadtokenresponse.responseCode -eq "201")
     {
     
          $genuploadtokendata = [PSCustomObject]@{
          token=$genuploadtokenresponse.data.token
        
    }

    return $genuploadtokendata
     }
     else{continue;}
    }


}

function DeleteReport([string] $reportId)
{
        Write-Host "===== deleting the report with Id $reportId"
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Content-Type", "application/json")
        $headers.Add("Authorization", "FortifyToken $FortifyReportDelToken")
        $deletereporturi = "$FortifyAPIURL" + "/reports/" + $reportId        
        $deletereportresponse = Invoke-RestMethod -Uri "$deletereporturi" -Method Delete -Headers $headers
        #$deletereportresponse
        #$deletereportresponse.response_code
        $delRespCode=$deletereportresponse.responseCode
        if($delRespCode -eq 200)
        {
            Write-Host "===== deleted the report with Id $reportId"
        }
        else{
            Write-Warning "===== Error in deleting the report with Id $reportId"
        }
        
}

function DownloadReport([string] $repdwnloadtoken,[string] $reportId)
{
    $repdwnloadtoken = $repdwnloadtoken.Trim(" ");
    $reportDownloadri= "$FortifyURL" + "/transfer/reportDownload.html?mat=" + $repdwnloadtoken + "&id=" + $reportId
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "FortifyToken $FortifyToken")
    #$outputPath = $outputPath + "/" + $ProjectVersionName+ "." + $ReportFormat
    $reportdwnloadres= curl.exe -X GET "$reportDownloadri" -o "$outputPath"  -s -w '%{response_code}\n'
    if($reportdwnloadres -eq "200")
    {
        write-host "===== report downloaded to $outputPath"
        DeleteReport -reportId $reportId
    }
    else {Write-Host "===== report download failed"}
}
    
function CreateReport()
{
    # POST create report
    $cruri= "$FortifyAPIURL" + "/reports"
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "FortifyToken $FortifyToken")
    #$payload_devloperWorkbench
    $response = Invoke-RestMethod "$cruri" -Method POST -Headers $headers -Body $payload_devloperWorkbench
    $response.responseCode
    $response.data.status
    $response.data.id
    $createResCode = $response.responseCode

        if($createResCode -eq "201") 
        {
        
        Write-Host "===== Checking the status of the report created"
        $checkreportUri = "$FortifyAPIURL" + "/reports/" + $response.data.id
        #write-host "Invoke-RestMethod $checkreportUri -Method Get -Headers $headers"
        $checkrepresponse = Invoke-RestMethod "$checkreportUri" -Method Get -Headers $headers
        $checkrepresponse
        while($checkrepresponse.data.status -ieq "PROCESSING" )
        {
            Write-Host "===== Waiting for report processing..."
            Start-Sleep -Seconds 30
            $checkrepresponse = Invoke-RestMethod "$checkreportUri" -Method Get -Headers $headers
        }
        $repdwnloadtoken=Generateuploadtoken
        $reportdenloadtoken=$repdwnloadtoken.token
        #write-host "$reportdenloadtoken"
        DownloadReport -repdwnloadtoken $reportdenloadtoken -reportId $response.data.id 
        }
}



    $resprojData=FetchProjVersionDetails
    
    $ProjectVersionName=$resprojData.ProjectVersionName
    $ApplicationName=$resprojData.ApplicationName
    $ApplicationVersionID=$resprojData.ApplicationVersionID
    $ReportName=$ProjectVersionName

   
Write-Host "===== ProjectVersionID: $ProjectVersionID"
Write-Host "===== ProjectVersionName: $ProjectVersionName"
Write-Host "===== ApplicationName: $ApplicationName"
Write-Host "===== ApplicationVersionID: $ApplicationVersionID"
Write-Host "===== FortifyAPIURL: $FortifyAPIURL"
Write-Host "===== FortifyToken: $FortifyToken"
Write-Host "===== ReportName: $ReportName"
Write-Host "===== Reporttype: $Reporttype"
Write-Host "===== ReportFormat: $ReportFormat"

$outputPath = $outputPath + "/" + $ProjectVersionName + "-" + $Buildnumber + "." + $ReportFormat
Write-Host "##vso[task.setvariable variable=FileOutputpath;]$outputPath"
Write-Host "===== Output: $outputPath"
    $payload_devloperWorkbench= setReportType
    CreateReport
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
} 