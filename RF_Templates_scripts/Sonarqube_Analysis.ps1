param(
    [Parameter(Mandatory = $true)]
    [string]$SonarToken,
    [Parameter(Mandatory = $true)]
    [string]$ProjectKeys,
    [Parameter(Mandatory = $true)]
    [string]$AppUrl,
    [Parameter(Mandatory = $true)]
    [string]$Branch

)

try{

write-host "ProjectKeys: $ProjectKeys"
write-host "Branch: $Branch"
write-host "AppUrl: $AppUrl"


$splitString = $ProjectKeys.Split(",").Trim()
 $ar1=$null
 $ar2=$null
 $ar3=$null
 $ar4=$null
 $ar5=$null
 $v1=$null
 $v2=$null
 $v3=$null
 $v4=$null
ForEach ($part in $splitString) {
    Write-host $part
    if($part -ne ""){
    $p1res=curl.exe -u "$($SonarToken):" "$AppUrl/api/issues/search?componentKeys=$part&tags=qm-p1&resolved=false&tags=qm-p3&branch=$Branch&additionalFields=_all" -s
    $p2res=curl.exe -u "$($SonarToken):" "$AppUrl/api/issues/search?componentKeys=$part&tags=qm-p2&resolved=false&tags=qm-p3&branch=$Branch&additionalFields=_all" -s
    $p3res=curl.exe -u "$($SonarToken):" "$AppUrl/api/issues/search?componentKeys=$part&tags=qm-p3&resolved=false&tags=qm-p3&branch=$Branch&additionalFields=_all" -s
    $qgres=curl.exe -u "$($SonarToken):" "$AppUrl/api/measures/component?component=$part&branch=$Branch&metricKeys=alert_status" -s
    $endpoint= "$AppUrl/dashboard?id=$part&branch=$Branch"

    $p1result=$p1res | ConvertFrom-Json
    $p2result=$p2res | ConvertFrom-Json
    $p3result=$p3res | ConvertFrom-Json
    $qgresult=$qgres | ConvertFrom-Json


   #$d1=$p1result.issues |Select-Object project | sort-object -Property project -Unique
   # $v1= ($d1.project +"="+$p1result.total )
   $d1=$qgresult.component.key
   $v1=($d1+"="+$p1result.total )
   $ar1+=@($v1)
   #$d2=$p2result.issues |Select-Object project | sort-object -Property project -Unique
   #$v2= ($d2.project +"="+$p2result.total )
   $v2= ($d1 +"="+$p2result.total )
   $ar2+=@($v2)
  # $d3=$p3result.issues |Select-Object project | sort-object -Property project -Unique
   #$v3= ($d3.project +"="+$p3result.total )
   $v3= ($d1 +"="+$p3result.total )
   $ar3+=@($v3) 
   $d4= $qgresult.component.key
   $v4= ($d4 +"="+ $qgresult.component.measures.value)
   $ar4+=@($v4)
   $ar5+=@($endpoint)

   }

}

$qmp1= $ar1  -join ","
$qmp2= $ar2  -join ","
$qmp3= $ar3  -join ","
$qualitygate= $ar4  -join ","
$endpointurl= $ar5  -join ","



    


Write-host "total qmp1 : $qmp1"
Write-host "total qmp2 : $qmp2"
Write-host "total qmp3 : $qmp3"
Write-host "Quality Gates : $qualitygate"
Write-host "endpointurl : $endpointurl"




Write-Output ("##vso[task.setvariable variable=SonarQmp1;]$qmp1")
Write-Output ("##vso[task.setvariable variable=SonarQmp2;]$qmp2")
Write-Output ("##vso[task.setvariable variable=SonarQmp3;]$qmp3")
Write-Output ("##vso[task.setvariable variable=SonarStatus;]$qualitygate")
Write-Output ("##vso[task.setvariable variable=SonarUrl;]$endpointurl")


}
catch{
    Write-Host "Error: $_"
    exit 1
}