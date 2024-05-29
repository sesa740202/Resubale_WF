param(
    [Parameter(Mandatory = $true)]
    [string]$PackageName,
    [Parameter(Mandatory = $true)]
    [string]$APITOKEN,
    [Parameter(Mandatory = $true)]
    [int]$GroupID
)


try {

    Set-Location -Path "$ENV:BUILD_ARTIFACTSTAGINGDIRECTORY"
    Write-Output "Packagename: $PackageName"


    $uploadurl = "https://ldfr40102ovah.schneider-electric.com/api/upload/"
    $authtoken = "Authorization: Bearer $APITOKEN"
    $group = "Group: $GroupID"
    Write-Output "Package uploading started...."

    $response = curl.exe -H $authtoken  -H $group -T $PackageName $uploadurl -s
    $jsresult = $response | ConvertFrom-Json
   

    if ($jsresult.meta.code -eq 200) {
        $checkurl = "https://ldfr40102ovah.schneider-electric.com/api/product/" + $jsresult.results.sha1sum  

        Write-Output "Product ID: $($jsresult.results.product_id)"
        Write-Output "Package uploaded successfully. Started for analysing..."

        do {
            $checkresponse = curl.exe -H  $authtoken $checkurl -s
            $jscheckres = $checkresponse | ConvertFrom-Json
            if ($jscheckres.results.status -eq 'B') {
                Write-Output "Package is analysing.."
            }
            else {
                Write-Output "Package analyse completed.."
            }

            Start-Sleep -s 5
        }while ($jscheckres.results.status -eq 'B')

        $VulnStatus = $jscheckres.results.summary.verdict.short
        $VulnCount = $jscheckres.results.summary.'vuln-count'.exact
        $ReportURL = $jscheckres.results.report_url
        $BDBAName =  $jscheckres.results.name
        $BDBAComCount = $jscheckres.results.components.Count
        $licenses= $jscheckres.results.components.license|select name | sort-object -Property name -Unique 
        $totallicense= $licenses.name | Where-Object { $_ -ne 'unknown' }
        $BDBALicCount= $totallicense.count


        Write-Output "VulnStatus: $VulnStatus"
        Write-Output "VulnCount: $VulnCount"
        Write-Output "ReportURL: $ReportURL"
        Write-Output "BDBAName: $BDBAName"
        Write-Output "BDBAComCount: $BDBAComCount"
        Write-Output "BDBALicCount: $BDBALicCount"

        Write-Output ("##vso[task.setvariable variable=BDBAReportURL;]$ReportURL")    
        Write-Output ("##vso[task.setvariable variable=BDBAVulnStatus;]$VulnStatus")    
        Write-Output ("##vso[task.setvariable variable=BDBAVulnCount;]$VulnCount")
        Write-Output ("##vso[task.setvariable variable=BDBAName;]$BDBAName")
        Write-Output ("##vso[task.setvariable variable=BDBAComp;]$BDBAComCount")
        Write-Output ("##vso[task.setvariable variable=BDBALice;]$BDBALicCount")
    }
    else {
        throw "Upload package failed... $jsresult"

    }


}
Catch {
    Write-Host "##vso[task.logissue type=error;]Error - $($error[0].Exception)"
    "##vso[task.complete result=Failed;]"
}