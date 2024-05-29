param(
    [Parameter(Mandatory=$true)]
    [string]$P12CertName,
    [Parameter(Mandatory=$true)]
    [string]$KEYSTORE_PWD,
    [Parameter(Mandatory=$true)]
    [string]$TRUSTSTORE_PWD,
    [Parameter(Mandatory=$true)]
    [string]$CodeSignPath,
    [Parameter(Mandatory = $true)]
    [string]$ARPPath,
    [Parameter(Mandatory = $true)]
    [string]$CodeSignEnv ,
    [Parameter(Mandatory = $true)]
    [string]$ARPName,
    [Parameter(Mandatory = $true)]
    [string]$ARPSignUtilsPath,
    [Parameter(Mandatory = $true)]
    [string]$CMSCerPath

)


write-host "ARPPath: $ARPPath"
write-host "Prod: $CodeSignEnv"


try{


function Codesignmapping {
    $global:signclientpath = "$CodeSignPath"
    $global:signclientcmd = "$signclientpath\bin\signclient.cmd"
    $global:signclientemptypath = "$signclientpath\Empty" 
    if (Test-Path -Path "$signclientpath\in\$ARPName") {
        Write-Host "Folder Exists" 
    } 
    else { 
        Write-Host "Folder does not exists, creating"
        New-Item -Path "$signclientpath\in" -Name $ARPName -ItemType Directory -Force 
    }

    if (Test-Path -Path "$signclientpath\out\$ARPName") {
        Write-Host "Folder Exists" 
    } 
    else { 
        Write-Host "Folder does not exists, creating"
        New-Item -Path "$signclientpath\out" -Name $ARPName -ItemType Directory -Force 
    }

    $global:indir = "$signclientpath\in\$ARPName"

    $global:outdir = "$signclientpath\out\$ARPName"

    If ($CodeSignEnv  -eq $true) {
        $global:workerid = "115" # Release Signing
        $global:environ="Official"
         $global:CMSCer="$CMSCerPath\CMS_3K_PROD.cer"

        Write-Host "Signing for ProductionRelease"
    }
    elseif ($CodeSignEnv  -eq $false) {
        $global:workerid = "114" # Release Signing
         $global:environ="Test"
         $global:CMSCer="$CMSCerPath\CMS_3K_TEST.pem"
         Write-Host "Signing for TestRelease"
    }

    
}

function Clean() {        
    Write-Host "Cleaning in use RoboCopy "
    robocopy "$signclientemptypath"  "$indir" /MIR /ETA
    Write-Host "Cleaning out use RoboCopy "
    robocopy "$signclientemptypath"  "$outdir" /MIR /ETA

}
function Delete() {        
  
   if (Test-Path -Path "$signclientpath\in\$ARPName") {
        Write-Host "Folder Exists. Deleting in folder..." 
       Remove-Item -Path "$signclientpath\in\$ARPName" -Recurse -Force   
    } 
    if (Test-Path -Path "$signclientpath\out\$ARPName") {
        Write-Host "Folder Exists. Deleting out folder..."
        Remove-Item -Path "$signclientpath\out\$ARPName" -Recurse -Force 
    } 


}


Codesignmapping
Clean


write-host "Creating the SHA256 bin file...."

openssl sha256 -binary -out "$ARPPath\$ARPName.bin" "$ARPPath\$ARPName.arp"

 Write-host "Copying bin file to $indir"

 Get-ChildItem -Path "$ARPPath\*" -Force  -Include "$ARPName.bin" | Copy-Item -Destination $indir -Include *   

 Write-Host "Starting Bin CodeSigning"
 Set-Location "$signclientpath\bin"

Write-host  signclient.cmd signdocument -host codesigning.se.com -port 443 -workerid $workerid -infile "$indir\$ARPName.bin" -outfile "$outdir\$ARPName.bin" -keystore "$signclientpath\Keys\$P12CertName.p12" -keystorepwd $KEYSTORE_PWD -truststore "$signclientpath\Keys\codesign.jks" -truststorepwd $TRUSTSTORE_PWD -metadata USING_CLIENTSUPPLIED_HASH=true -metadata CLIENTSIDE_HASHDIGESTALGORITHM=SHA-256
   
          $a = & cmd /c  signclient.cmd signdocument -host codesigning.se.com -port 443 -workerid $workerid -infile "$indir\$ARPName.bin" -outfile "$outdir\$ARPName.bin" -keystore "$signclientpath\Keys\$P12CertName.p12" -keystorepwd $KEYSTORE_PWD -truststore "$signclientpath\Keys\codesign.jks" -truststorepwd $TRUSTSTORE_PWD -metadata USING_CLIENTSUPPLIED_HASH=true -metadata CLIENTSIDE_HASHDIGESTALGORITHM=SHA-256  
       
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
            Write-Host "Completed Bin CodeSigning"
        }
        
         Write-Host "Copying bin file back from outdir to $ARPPath"
               # Copy-Item -Path $outdir\*  $folder\ -Force -Recurse -Wait
                 ROBOCOPY /MOV /IS "$outdir" "$ARPPath"
                #Clean In/Out Dir
                
                Clean
                Delete

 Write-Host "Code Sign the ARP with ARPUtility"
  Set-Location $ARPSignUtilsPath
  Write-Host "ARPSignUtility.exe append -f $ARPPath\$ARPName.arp -c $ARPPath\$ARPName.bin"
  .\ARPSignUtility.exe append -f "$ARPPath\$ARPName.arp" -c "$ARPPath\$ARPName.bin"
  if($LASTEXITCODE -eq 0){
  Write-Host "Succeeded"
  }
  else{
  throw "Failed from ARPUtility Append"

  }
  Write-Host "Verify the ARP with ARPUtility"
  Write-Host "ARPSignUtility.exe verify -f $ARPPath\signed\$ARPName.arp -c $CMSCer -k $environ"
   .\ARPSignUtility.exe verify -f "$ARPPath\signed\$ARPName.arp" -c "$CMSCer" -k $environ

   if($LASTEXITCODE -eq 0){
  Write-Host "Succeeded"
  }
  else{
  throw "Failed from ARPUtility Verify "

  }

}catch
{
 Write-Error "An error occurred while Code Signing. Error: $_" 

        exit 1
}


