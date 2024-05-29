
param(
    [Parameter(Mandatory = $true)]
    [string]$servicerootpath,
    [Parameter(Mandatory = $true)]
    [string]$Outputpath,
    [Parameter(Mandatory = $true)]
    [string]$microapppath,
    [Parameter(Mandatory = $true)]
    [string]$nugetConfigPath,
    [Parameter(Mandatory = $true)]
    [string]$CodeSignProd,
    [Parameter(Mandatory = $true)]
    [string]$P12CertName,
    [Parameter(Mandatory = $true)]
    [string]$KEYSTORE_PWD,
    [Parameter(Mandatory = $true)]
    [string]$TRUSTSTORE_PWD,
    [Parameter(Mandatory = $true)]
    [string]$CodeSignPath,
    [Parameter(Mandatory = $true)]
    [string]$DTMName

)

function codesignmapping {
    $global:signclientpath = "$CodeSignPath"
    $global:signclientcmd = "$signclientpath\bin\signclient.cmd"
    $global:signclientemptypath = "$signclientpath\Empty" 
    if (Test-Path -Path "$signclientpath\in\$DTMName") {
       Write-Host "Folder Exists" 
    } 
    else { 
       Write-Host "Folder does not exists, creating"
        New-Item -Path "$signclientpath\in" -Name $DTMName -ItemType Directory -Force 
    }

    if (Test-Path -Path "$signclientpath\out\$DTMName") {
       Write-Host "Folder Exists" 
    } 
    else { 
       Write-Host "Folder does not exists, creating"
        New-Item -Path "$signclientpath\out" -Name $DTMName -ItemType Directory -Force 
    }

    $global:indir = "$signclientpath\in\$DTMName"

    $global:outdir = "$signclientpath\out\$DTMName"

    If ($CodeSignProd -eq $true) {
        $global:workerid = "6" # Release Signing
       Write-Host "Signing for ProductionRelease"
    }
    elseif ($CodeSignProd -eq $false) {
         $global:workerid = "5" # Release Signing
         Write-Host "Signing for DevRelease"
    }

    
}




function Clean() {        
   Write-Host "Cleaning in use RoboCopy "
    robocopy "$signclientemptypath"  "$indir" /MIR /ETA
   Write-Host "Cleaning out use RoboCopy "
    robocopy "$signclientemptypath"  "$outdir" /MIR /ETA

}







#Write-Output "dotnet runtimes"
#dotnet  --list-runtimes
#Write-Output "dotnet sdks"
#dotnet  --list-sdks

$appmanifest = Join-Path $servicerootpath "app.manifest.json"
$jcontent = Get-Content $appmanifest | ConvertFrom-Json

$serviceentrypoint = $jcontent.services.entrypoint
$servicetoolhandlerpath = $jcontent.toolHandlerPath
if ($null -ne $serviceentrypoint) {
    $filenames = $serviceentrypoint | ForEach-Object {
        [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $_ -Leaf))
    } | Select-Object -Unique
    $serviceversion = $jcontent.services.version
    $servicename = $jcontent.services.microserviceName

}
elseif ($null -ne $servicetoolhandlerpath) {
    $filenames = $servicetoolhandlerpath | ForEach-Object {
        [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $_ -Leaf))
    } | Select-Object -Unique
    $serviceversion = $jcontent.version
    $servicename = $jcontent.name

}


function codesignbegin($folderpath, $servicename) {
    try {
       
       Write-Host "Copying dlls from $folderpath to In Dir"
        Clean
        Get-ChildItem -Path "$folderpath\*" -Force  -Include "$servicename.exe", "$servicename.dll" | Copy-Item -Destination $indir -Include *   
       Write-Host "Starting CodeSigning"
        Set-Location "$signclientpath\bin"
       Write-Host signclient.cmd signdocument -host codesigning.se.com -port 443 -clientside -digestalgorithm SHA256 -workerid $workerid -indir $indir -outdir $outdir -keystore "$signclientpath\Keys\$P12CertName.p12" -keystorepwd $KEYSTORE_PWD -truststore "$signclientpath\Keys\codesign.jks" -truststorepwd $TRUSTSTORE_PWD threads 10
        $a = & cmd /c signclient.cmd signdocument -host codesigning.se.com -port 443 -clientside -digestalgorithm SHA256 -workerid $workerid -indir $indir -outdir $outdir -keystore "$signclientpath\Keys\$P12CertName.p12" -keystorepwd $KEYSTORE_PWD -truststore "$signclientpath\Keys\codesign.jks" -truststorepwd $TRUSTSTORE_PWD threads 10   
       
        if ($a | Select-String -Pattern 'ERROR [SignDocumentCommand]' -CaseSensitive -SimpleMatch) { 

            ForEach ($line in $($a -split "`r`n")) {
                Write-host $line

            }
            throw $line

        }
        else {
            ForEach ($line in $($a -split "`r`n")) {
                Write-host $Line
            }
           Write-Host "Completed CodeSigning"
        }

       Write-Host "Copying files from Out Dir to $folderpath"
        ROBOCOPY /MOV /IS "$outdir" "$folderpath"

        Clean

    }
    catch [Exception] {
        Write-Host "##vso[task.logissue type=error;]failed CodeSigning Files - $($error[0].Exception)"
        "##vso[task.complete result=Failed;]"
    }
    

    
}






if ($null -ne $filenames) {
   Write-Host "msbuild version"
    MSBuild.exe -version
   Write-Host "Total services to build: " $filenames.Count
    codesignmapping
    try {
        foreach ($folderName in $filenames) {
            $files = Get-ChildItem -Path "$servicerootpath" -Recurse -Force -Include *.sln -File | Where-Object { $_.Directory.Name -eq $folderName -and $_.BaseName -eq $folderName }
            foreach ($file in $files) {

     
                if (Test-Path -path $nugetConfigPath) {

                   Write-Host "Nuget Config File is present"
                   Write-Host $nugetConfigPath
                    msbuild.exe  /t:Restore /p:RestoreConfigFile="$nugetConfigPath"  $file
                    #dotnet restore $file --configfile "$nugetConfigPath"
                    if ($LASTEXITCODE -ne 0) {
                        throw "msbuild restore encountered an error."
                    }

                    $name = $folderName
                    $index = [array]::IndexOf($servicename, $name)
                    $version = $serviceversion[$index]
                    $servicePath = $file.DirectoryName
                    if ($servicename.Count -eq 1 -and $serviceversion.Count -eq 1) {
                       Write-Host "Restoring dependencies for Service: $name, Version: $serviceversion"
                        $version = $serviceversion
                    }
                    else {
                       Write-Host "Restoring dependencies for Service: $name, Version: $version"
                    }
                   Write-Host "Solutionpath" $servicePath
                   Write-Host "Solution" $file
                    $csproj = Get-ChildItem -Path "$servicerootpath" -Recurse -Force -Include *.csproj -File | Where-Object { $_.BaseName -eq $folderName }
                    $baseoutpath = "$servicerootpath/servicesout/$folderName/bin"
                   Write-Host "csprojfile:$csproj"
                (Get-Content -Path "$csproj") | ForEach-Object {
                        $_ -replace '</Project>', "  <PropertyGroup>    <BaseOutputPath>$baseoutpath</BaseOutputPath>  
             <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath> </PropertyGroup> </Project>"
                    } | Set-Content -Path "$csproj"

                    $projcsfile = [xml](gc $csproj)
                    $PlatformTarget = $projcsfile.Project.PropertyGroup.PlatformTarget
                  
                    if ([string]::IsNullOrEmpty("$PlatformTarget".Trim())) {
                        Write-Host "PlatformTarget is null or empty"
                        $PlatformTarget = "Any CPU"
                        Write-Host "PlatformTarget $PlatformTarget"
                    }
                    else {
                        Write-Host "PlatformTarget is not null or empty"
                       
                       
                        $PlatformTarget = "$PlatformTarget".Trim()

                        if( $PlatformTarget -eq "AnyCPU"){
                            $PlatformTarget = "Any CPU"
                        }
                        Write-Host "PlatformTarget $PlatformTarget"
                                            
                    }
                    
                    Set-Location $servicePath
                    Write-host "execute: msbuild.exe  "$file"  /t:"Clean"  /t:"Rebuild" /p:configuration="Release" /p:platform="$PlatformTarget"" 
                    # dotnet clean "$file" --configuration Release
                    # if ($LASTEXITCODE -ne 0) {
                    #    throw "dotnet clean encountered an error."
                    # }
                    # dotnet build  "$file" --configuration Release
                    msbuild.exe  "$file"  /t:"Clean"  /t:"Rebuild" /p:configuration="Release" /p:platform="$PlatformTarget"
                    if ($LASTEXITCODE -ne 0) {
                        throw "msbuild build encountered an error."
                    }
                    if ($servicename -eq "somovelauncher") {
                        robocopy $baseoutpath\Release $Outputpath\bin /S /E
                        $exitCode = $LASTEXITCODE
                       codesignbegin "$Outputpath\bin" "$folderName"
                    }
                    else {
                     if($PlatformTarget -eq "x86"){
                        robocopy $baseoutpath\x86\Release $Outputpath\services\$name\$version /S /E   
                        $exitCode = $LASTEXITCODE
                     }else{
                        robocopy $baseoutpath\Release $Outputpath\services\$name\$version /S /E   
                        $exitCode = $LASTEXITCODE

                     }
                       
                      
                        codesignbegin "$Outputpath\services\$name\$version" "$folderName"
                    }


                   

                    if ($exitCode -eq 1) {
                       Write-Host "Robocopy completed successfully."
                    }
                    else {
                      
                        throw "Robocopy encountered an error. Exit code: $exitCode"
                    }   
                }
                else {
                    throw "Nuget Config File not present"
                
                }
        
            }
        }

    }
    catch {
        Write-Error "An error occurred in Service: $folderName. Error: $_" 
        exit 1
    }

}
else {
   Write-Host "No Service for $microapppath"
}