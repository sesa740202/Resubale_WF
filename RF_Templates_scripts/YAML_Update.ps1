param(
    [Parameter(Mandatory = $true)]
    [string]$JsonFilepath,
    [Parameter(Mandatory = $true)]
    [string]$YAMLFilepath
)


try {

Install-Module -Name powershell-yaml
Import-Module powershell-yaml
#$JsonFilepath = "C:\Users\sesa649430\OneDrive - Schneider Electric\deployappservice\SoMoveNGPackageTemplate.json"
$jsondata = Get-Content $JsonFilepath | ConvertFrom-Json
$Jsonyaml = $jsondata.YAMLVersioning
[string[]]$fileContent = Get-Content $YAMLFilepath
$content = ''


foreach ($line in $fileContent) { $content = $content + "`n" + $line }
$yaml = ConvertFrom-YAML $content -Ordered
foreach ($vlaue in $Jsonyaml) {
foreach ($step in $yaml.steps.tasks.arp) {
    if ($step.package -eq $vlaue.name) {
        $step.version = $vlaue.version
    }
}

 $newYamlContent = $yaml | ConvertTo-Yaml

 $newYamlContent | Set-Content $YAMLFilepath

}
}
catch {
    Write-Error "An error occurred: Error: $_" 
    exit 1
}