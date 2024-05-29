param(

[Parameter(Mandatory=$true)]
[string]$SourcePath,
[Parameter(Mandatory=$true)]
[string]$FortifyServerURL,
[Parameter(Mandatory=$true)]
[string]$FortifyAuthToken,
[Parameter(Mandatory=$true)]
[string]$FortifyApplicationID,
[Parameter(Mandatory=$true)]
[string]$FortifyPath

)

 
try{

#Set-Location -Path "C:\Program Files\Fortify\Fortify_SCA_and_Apps_20.2.2\bin"
Set-Location -Path "$FortifyPath"
Write-Host "srcpath: $SourcePath"
Write-Host "url: $FortifyServerURL"
Write-Host "appid: $FortifyApplicationID"

Function Clean()
{
Write-Host "1. Fortify Clean Build ID related code" -ForegroundColor Cyan

.\sourceanalyzer.exe -b $Env:BUILD_BUILDNUMBER -clean
if ($LASTEXITCODE -ne 0) {
                throw "sourceanalyzer -clean command failed"
            }

Write-Host "1. Fortify Clean Build ID Data :: Complete" -ForegroundColor Cyan

}

Function Translate()
{

Write-Host "2. Fortify Translate Code" -ForegroundColor Cyan


.\sourceanalyzer.exe -b $Env:BUILD_BUILDNUMBER  "$SourcePath/**/*"
if ($LASTEXITCODE -ne 0) {
                throw "sourceanalyzer -Translate command failed"
            }

Write-Host "2. Fortify Translate Code :: Complete" -ForegroundColor Cyan
}

Function Analyse()
{

Write-Host "3. Fortify Analyze Code" -ForegroundColor Cyan
.\sourceanalyzer.exe -b $Env:BUILD_BUILDNUMBER -scan -f "$Env:BUILD_SOURCESDIRECTORY\$Env:BUILD_BUILDNUMBER.fpr"
if ($LASTEXITCODE -ne 0) {
                throw "sourceanalyzer -Analyze command failed"
            }
Write-Host "3. Fortify Analyze Code :: Complete" -ForegroundColor Cyan
}

Function Upload()
{
Write-Host "4. Fortify Upload FPR" -ForegroundColor Cyan

 $FortifyURLAPI= $FortifyServerURL + "/api/v1/projectVersions/"+ $FortifyApplicationID+"/artifacts"

 Write-Host "curl.exe -X POST $FortifyURLAPI -H accept: application/json -H Content-Type: multipart/form-data -F file=@$Env:BUILD_SOURCESDIRECTORY\$Env:BUILD_BUILDNUMBER.fpr -H authorization: FortifyToken $FortifyAuthToken"
            $res= curl.exe -X POST $FortifyURLAPI -H "accept: application/json" -H "Content-Type: multipart/form-data" -F "file=@$Env:BUILD_SOURCESDIRECTORY\$Env:BUILD_BUILDNUMBER.fpr" -H "authorization: FortifyToken $FortifyAuthToken"
             $respcode=$res| ConvertFrom-Json
            if($respcode.responseCode -eq 201){
            if($respcode.data.id -ne 0){
            $artifactid=$respcode.data.id
            write-host "$artifactid"
       $FortifyURLArti= $FortifyServerURL +"/api/v1/artifacts/"+ $artifactid
            DO {
           $FPRres= curl.exe -X GET $FortifyURLArti -H "accept: application/json" -H "Authorization: FortifyToken $FortifyAuthToken"
           $checkstatus=  $FPRres|ConvertFrom-Json
            Write-Host $checkstatus.data.status
           
           } While ($checkstatus.data.status -eq "PROCESSING")
            $FortifyURLCritical=$FortifyServerURL + "/api/v1/projectVersions/"+ $FortifyApplicationID+"/issues?q=%5Bfortify%20priority%20order%5D%3Acritical&qm=issues"
            $FortifyURLHigh=$FortifyServerURL + "/api/v1/projectVersions/"+ $FortifyApplicationID+"/issues?q=%5Bfortify%20priority%20order%5D%3Ahigh&qm=issues"
            $FortifyURLMedium=$FortifyServerURL + "/api/v1/projectVersions/"+ $FortifyApplicationID+"/issues?q=%5Bfortify%20priority%20order%5D%3Amedium&qm=issues"
            $FortifyURLLow=$FortifyServerURL + "/api/v1/projectVersions/"+ $FortifyApplicationID+"/issues?q=%5Bfortify%20priority%20order%5D%3Alow&qm=issues"
            $FortifyURLTotal=$FortifyServerURL + "/api/v1/projectVersions/"+ $FortifyApplicationID+"/issues"
            $FortifyURLName=$FortifyServerURL + "/api/v1/projectVersions/"+ $FortifyApplicationID
           
            $criticalsres= curl.exe -X GET $FortifyURLCritical -H "accept: application/json" -H "Authorization: FortifyToken $FortifyAuthToken" -s
            $highres = curl.exe -X GET $FortifyURLHigh -H "accept: application/json" -H "Authorization: FortifyToken $FortifyAuthToken" -s
            $mediumres = curl.exe -X GET $FortifyURLMedium -H "accept: application/json" -H "Authorization: FortifyToken $FortifyAuthToken" -s
            $lowres = curl.exe -X GET $FortifyURLLow -H "accept: application/json" -H "Authorization: FortifyToken $FortifyAuthToken" -s
            $totalres = curl.exe -X GET $FortifyURLTotal -H "accept: application/json" -H "Authorization: FortifyToken $FortifyAuthToken" -s
            $nameres = curl.exe -X GET $FortifyURLName -H "accept: application/json" -H "Authorization: FortifyToken $FortifyAuthToken" -s
           
            $criticalres=$criticalsres | ConvertFrom-Json
            $highres=$highres | ConvertFrom-Json
           $mediumres= $mediumres | ConvertFrom-Json
           $lowres= $lowres | ConvertFrom-Json
           $totalres= $totalres | ConvertFrom-Json
           $nameres= $nameres | ConvertFrom-Json
           $criticalcount= $criticalres.count 
           $highcount= $highres.count
            $mediumcount= $mediumres.count
            $lowrescount= $lowres.count
            $totalrescount= $totalres.count
            $name= $nameres.data.name
            $verurl=$FortifyServerURL + "/html/ssc/version/"+ $FortifyApplicationID+"/audit"
            write-host "Critical Count:  $criticalcount"
            write-host "High Count:  $highcount"
            write-host "Medium Count:  $mediumcount"
            write-host "Low Count:  $lowrescount"
            write-host "Total Count:  $totalrescount"
            write-host "Version Name:  $name"
            write-host "Version Url:  $verurl"
            Write-Host "##vso[task.setvariable variable=FortifyHigh;]$highcount"
            Write-Host "##vso[task.setvariable variable=FortifyLow;] $lowrescount"
            Write-Host "##vso[task.setvariable variable=FortifyMedium;]$mediumcount"
            Write-Host "##vso[task.setvariable variable=FortifyCritical;]$criticalcount"
            Write-Host "##vso[task.setvariable variable=FortifyTotal;]$totalrescount"
            Write-Host "##vso[task.setvariable variable=FortifyName;]$name"
            Write-Host "##vso[task.setvariable variable=FortifyEndpoint;]$verurl"
            if($criticalcount -gt 0 -or  $highcount -gt 0 -or $mediumcount -gt 0){
            Write-Host "##vso[task.setvariable variable=GenerateReport;]true"

            }else{
            Write-Host "##vso[task.setvariable variable=GenerateReport;]false"

            }

                }



            Write-Output "Uploaded successfully"
            }else{
                throw "sourceanalyzer upload command failed" 
            }
            
Write-Host "4. Fortify Upload FPR :: Complete" -ForegroundColor Cyan
}

Clean
Translate
Analyse
Upload
      
       

 
}
catch [Exception]
{
    Write-Host "##vso[task.logissue type=error;]An error occurred: - $($error[0].Exception)"
    "##vso[task.complete result=Failed;]"
}
 

 

 
