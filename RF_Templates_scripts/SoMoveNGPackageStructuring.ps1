
param(
    [Parameter(Mandatory = $true)]
    [string]$JsonFilepath,
    [Parameter(Mandatory = $true)]
    [string]$PackagePath
)
try {

#$JsonFilepath = "C:\Users\sesa649430\OneDrive - Schneider Electric\deployappservice\PackageTemplate.json"
$jsondata = Get-Content $JsonFilepath | ConvertFrom-Json
$Jsonpts = $jsondata.PTSPackage
$Jsonpckname = $jsondata.PackageName
$Jsonofflinepck = $jsondata.offlinePackages

$checkptsfile = curl.exe -s -I "$($Jsonpts.url)$($Jsonpts.name)"
$statusptsLine = ($checkptsfile -split '\r?\n' | Select-Object -First 1).Trim()
$statusptsLine
if ($statusptsLine -match '^HTTP/\d\.\d (\d+)') {
    $statusptsCode = $Matches[1]
    Write-Host "Extracted status code: $statusptsCode"
}
elseif ($statusptsLine -match '^HTTP/2 (\d+)') {
    $statusptsCode = $Matches[1]
    Write-Host "Extracted status code for HTTP/2: $statusptsCode"
}
else {
    Write-Host "Status code not found."
    $statusptsCode = "-1"
}

if ($statusptsCode -eq "200") {
    curl.exe  -o "$PackagePath/$($Jsonpts.name)" --insecure "$($Jsonpts.url)$($Jsonpts.name)"
    Expand-Archive -Path "$PackagePath/$($Jsonpts.name)" -DestinationPath "$PackagePath\$($Jsonpckname.name).$($Jsonpckname.version)" -Force

    New-Item -Path "$PackagePath\$($Jsonpckname.name).$($Jsonpckname.version)\offlinePackages" -ItemType Directory          

   
   
    foreach ($vlaue in $Jsonofflinepck) {
        Write-Host "$($vlaue.name)"
        Write-Host "$($vlaue.url)"

        $checkofflinepck = curl.exe -s -I "$($vlaue.url)$($vlaue.name)" 
        $statusofflinepck = ($checkofflinepck -split '\r?\n' | Select-Object -First 1).Trim()
        $statusofflinepck
        if ($statusofflinepck -match '^HTTP/\d\.\d (\d+)') {
            $statusofflinepckCode = $Matches[1]
            Write-Host "Extracted status code: $statusofflinepckCode"
        }
        elseif ($statusofflinepck -match '^HTTP/2 (\d+)') {
            $statusofflinepckCode = $Matches[1]
            Write-Host "Extracted status code for HTTP/2: $statusofflinepckCode"
        }
        else {
            Write-Host "Status code not found."
            $statusofflinepckCode = "-1"
        }

        if ($statusofflinepckCode -eq "200") {
            Set-Location 
            curl.exe  -o "$PackagePath\$($Jsonpckname.name).$($Jsonpckname.version)\offlinePackages\$($vlaue.name)" --insecure "$($vlaue.url)$($vlaue.name)"

        }else {
          
           
            throw "No $($vlaue.name) file present"
           
        
        }

    }
     $finalpackagepath="$PackagePath\$($Jsonpckname.name).$($Jsonpckname.version)"
     write-host "Final Package Path: $finalpackagepath"
    Write-Host "##vso[task.setvariable variable=FinalPackagePath;]$finalpackagepath"
}else {
   
   
    throw "No $($Jsonpts.name) file present"
    

}

}
catch {
    Write-Error "An error occurred: Error: $_" 
    exit 1
}