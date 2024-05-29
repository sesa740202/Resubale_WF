
param(
    [Parameter(Mandatory = $true)]
    [string]$mferootpath
)

try {

 Set-Location "$mferootpath"
 $coverageDirectory = "mfecoverages"
  if (Test-Path $coverageDirectory) {
      Remove-Item $coverageDirectory -Force -Recurse
  }
  New-Item $coverageDirectory -ItemType Directory

 $coveragespath = "$mferootpath\mfecoverages"

 $counter = 1

$combinedMFEPath = @() 

foreach($file in Get-ChildItem  -Recurse -Force -include "jest.config.js" |  Where {$_.FullName -notlike "*node_modules*"}){
  Write-Host "file: $file"
 Set-Location $file.DirectoryName

 
 npm run test

foreach($lcovfile in Get-ChildItem  -Recurse -Force -include "lcov.info" | Where {$_.FullName -notlike "*node_modules*"}){
            Write-Host "lcovfile: $lcovfile"
            $relativePath = Get-Item $lcovfile.FullName | Resolve-Path -Relative
              Copy-Item $lcovfile.fullname -Destination $coveragespath
               $newNamePath = join-path -path $coveragespath -childpath "lcov.info"
            Rename-Item -Path  $newNamePath  -NewName "lcov_${counter}.info"
            Write-Host "lcovcounterfile: lcov_${counter}.info"
            $counter = $counter + 1
            
            } 
 $combinedMFEPath += $file.DirectoryName
 $combinedMFEPathString = $combinedMFEPath -join ','
 write-host "combinedMFEPathString: $combinedMFEPathString"           
 
}

 Set-Location $coveragespath
# write-host "Merging with powershell...."
 #Get-Content $coveragespath'\*.info' | Out-File -Encoding utf8 $coveragespath'\merged.txt' -verbose
 #Rename-Item -Path  $coveragespath'\merged.txt'  -NewName "lcov_merged.info" -verbose
 # Set-Location "$mferootpath"
 #write-host "Merging with lcov-result-merger...."
 #npx lcov-result-merger@4.1.0 'mfecoverages/lcov_*.info' 'mfecoverages/lcov_merged.info'

 $coveragefiles= (Get-ChildItem -Recurse -Filter 'lcov_*.info' |% { $_.FullName + ',' }) -join ''

 if ([string]::IsNullOrEmpty($coveragefiles)){
    Write-Host "No coverage files";
    }
else{
   Write-Output ("##vso[task.setvariable variable=CoverageFiles;]$coveragefiles") 
    Write-Output ("##vso[task.setvariable variable=CoverageMFEPath;]$combinedMFEPathString") 
    }


 }
 catch
 {
 Write-Error "An error occurred in test run for MFE: $file. Error: $_" 
            exit 1
 }