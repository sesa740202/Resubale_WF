
param(
    [Parameter(Mandatory = $true)]
    [string]$mferootpath,
    [Parameter(Mandatory = $true)]
    [string]$Outputpath,
    [Parameter(Mandatory = $true)]
    [string]$microapppath
)


cd "$mferootpath"


$appmanifest = "$Outputpath\app.manifest.json"
$jcontent = Get-Content $appmanifest | ConvertFrom-Json
$mfename = $jcontent.mfes.name
$mfeversion = $jcontent.mfes.version
write-output "Total mfes to build: " $mfename.Count


if ($null -ne $mfename) {
$nodever = node --version
$npmver = npm --version
write-output "npm version:" $npmver
write-output "node version:" $nodever


    write-output "Parallel Build started..."
    $scriptBlock = {
        param($folderName, $mfeversions, $Outputpath, $mferootpath,$mfenames)
 #$folderName
 #$mfeversions
 #$Outputpath
 #$mferootpath
        try {
            $files = Get-ChildItem -Path "$mferootpath" -Recurse -Force -Include *.esporj, *package.json -File | Where-Object { $_.FullName -notlike "*node_modules*" -and $_.Directory.Name -eq $folderName }
            foreach ($file in $files) {
                $name = $folderName
                $index = [array]::IndexOf($mfenames, $name)
                $version = $mfeversions[$index]
                $mfePath = $file.DirectoryName
               
                if ($mfenames.Count -eq 1 -and $mfeversions.Count -eq 1) {
                    Write-Host "Restoring npm dependencies for MFE: $name, Version: $mfeversions"
                    $version =$mfeversions
                    }
                    else{
                        Write-output "Restoring npm dependencies for MFE: $name, Version: $version"
                    }



                Set-Location "$mfePath"
                Write-output "npm install"
                $npminstallLogPath = Join-Path $mfePath "npm_install.log"
                $npmbuildLogPath = Join-Path $mfePath "npm_build.log"
                npm install > $npminstallLogPath 2>&1
                if ($LASTEXITCODE -ne 0) {
                    $loginstallContents = Get-Content -Path $npminstallLogPath
                    foreach ($line in $loginstallContents ) {
                        $formattedLog += " $line`n"
           
                    }
                    throw "npm install encountered an error. Check $npminstallLogPath for details. `n$formattedLog"
           
                }
                $loginstallContents = Get-Content -Path $npminstallLogPath
                Write-Output $loginstallContents 
                Write-output "npm build"
                npm run build > $npmbuildLogPath 2>&1
                if ($LASTEXITCODE -ne 0) {
                    $logbuildContents = Get-Content -Path $npmbuildLogPath 
                    foreach ($line in $logbuildContents ) {
                        $formattedLog += " $line`n"
           
                    }
                    throw "npm build encountered an error. Check $npmbuildLogPath for details. `n$formattedLog"
                }
                $logbuildContents = Get-Content -Path $npmbuildLogPath 
                Write-Output $logbuildContents 
                robocopy $mfePath\dist\$name $Outputpath\mfes\$name\$version /S /E
                $exitCode = $LASTEXITCODE

                if ($exitCode -eq 1) {
                    Write-output "Robocopy completed successfully."
                }
                else {
                    Write-output  "Robocopy encountered an error. Exit code: $exitCode"
                    throw "Robocopy encountered an error. Exit code: $exitCode"
                }    
            }

        }
        catch {
            Write-Error "An error occurred in job for MFE: $folderName. Error: $_" 
            exit 1
        }
    }

    $jobs = @()

    foreach ($folderName in $mfename) {
        $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $folderName, $mfeversion ,$Outputpath ,$mferootpath,$mfename
        $jobs += $job
    }

    # Wait for all jobs to complete
    $jobs | Wait-Job

    # Retrieve job results if needed
    foreach ($job in $jobs) {
        $jobResults = Receive-Job -Job $job

        
        Write-Output "Output from $($job.Name):"
        foreach ($outputResult in $jobResults) {
            Write-Output "    $outputResult"
            
        }
    }

    # Clean up jobs
    $jobs | Remove-Job

}
else {
    Write-output "No MFE for $microapppath"
}