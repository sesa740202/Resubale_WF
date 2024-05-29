
param(
    [Parameter(Mandatory = $true)]
    [string]$servicerootpath,
    [Parameter(Mandatory = $true)]
    [string]$Outputpath,
    [Parameter(Mandatory = $true)]
    [string]$microapppath,
    [Parameter(Mandatory = $true)]
    [string]$nugetConfigPath
)

Write-Output "dotnet version"
dotnet --version
Write-Output "dotnet runtimes"
dotnet  --list-runtimes
Write-Output "dotnet sdks"
dotnet  --list-sdks

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



if ($null -ne $filenames) {
    write-output "Total services to build: " $filenames.Count

    try {
        foreach ($folderName in $filenames) {
            $files = Get-ChildItem -Path "$servicerootpath" -Recurse -Force -Include *.sln -File | Where-Object { $_.Directory.Name -eq $folderName -and $_.BaseName -eq $folderName }
            foreach ($file in $files) {

     
                if (Test-Path -path $nugetConfigPath) {

                    Write-Host "Nuget Config File is present"
                    Write-Host $nugetConfigPath

                    dotnet restore $file --configfile "$nugetConfigPath"
                    if ($LASTEXITCODE -ne 0) {
                        throw "dotnet restore encountered an error."
                    }

                    $name = $folderName
                    $index = [array]::IndexOf($servicename, $name)
                    $version = $serviceversion[$index]
                    $servicePath = $file.DirectoryName
                    if ($servicename.Count -eq 1 -and $serviceversion.Count -eq 1) {
                        Write-Host "Restoring dependencies for Service: $name, Version: $serviceversion"
                        $version =$serviceversion
                        }
                        else{
                         Write-Host "Restoring dependencies for Service: $name, Version: $version"
                        }
                    Write-Output "Solutionpath" $servicePath
                    Write-Output "Solution" $file
                    $csproj = Get-ChildItem -Path "$servicerootpath" -Recurse -Force -Include *.csproj -File | Where-Object { $_.BaseName -eq $folderName }
                  $baseoutpath="$servicerootpath/servicesout/$folderName/bin"
                    Write-Output "csprojfile:$csproj"
                (Get-Content -Path "$csproj") | ForEach-Object {
                        $_ -replace '</Project>', "  <PropertyGroup>    <BaseOutputPath>$baseoutpath</BaseOutputPath>  
             <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath> </PropertyGroup> </Project>"
                    } | Set-Content -Path "$csproj"

                    Set-Location $servicePath
                    Write-Host "execute: dotnet build $file --configuration Release"
                    dotnet clean "$file" --configuration Release
                    if ($LASTEXITCODE -ne 0) {
                        throw "dotnet clean encountered an error."
                    }
                    dotnet build  "$file" --configuration Release
                    if ($LASTEXITCODE -ne 0) {
                        throw "dotnet build encountered an error."
                    }
                    if($servicename -eq "somovelauncher"){
                    robocopy $baseoutpath\Release $Outputpath\bin /S /E
                    }
                    else{
                        robocopy $baseoutpath\Release $Outputpath\services\$name\$version /S /E   
                    }


                    $exitCode = $LASTEXITCODE

                    if ($exitCode -eq 1) {
                        Write-output "Robocopy completed successfully."
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
    Write-output "No Service for $microapppath"
}