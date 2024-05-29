param(
    [Parameter(Mandatory = $true)]
    [string]$SQLInstance,
    [Parameter(Mandatory = $true)]
    [string]$SQLDatabase,
    [Parameter(Mandatory = $true)]
    [string]$SQLUsername,
    [Parameter(Mandatory = $true)]
    [string]$SQLPassword,
    [Parameter(Mandatory = $true)]
    [string]$APPName,
    [Parameter(Mandatory = $true)]
    [string]$Branch ,
    [Parameter(Mandatory = $true)]
    [string]$Project,
    [Parameter(Mandatory = $true)]
    [string]$Program,
    [Parameter(Mandatory = $true)]
    [string]$BuildID,
    [Parameter(Mandatory = $true)]
    [string]$BDBAName,
    [Parameter(Mandatory = $true)]
    [string]$BDBAComp,
    [Parameter(Mandatory = $true)]
    [string]$BDBAVuln,
    [Parameter(Mandatory = $true)]
    [string]$BDBALice,
    [Parameter(Mandatory = $true)]
    [string]$BDBAStatus,
    [Parameter(Mandatory = $true)]
    [string]$BDBAUrl,
    [Parameter(Mandatory = $true)]
    [string]$BDHName,
    [Parameter(Mandatory = $true)]
    [string]$BDHLiceRisk,
    [Parameter(Mandatory = $true)]
    [string]$BDHOperRisk,
    [Parameter(Mandatory = $true)]
    [string]$BDHSecuRisk,
    [Parameter(Mandatory = $true)]
    [string]$BDHUrl,
    [Parameter(Mandatory = $true)]
    [string]$FortifyName,
    [Parameter(Mandatory = $true)]
    [string]$FortifyHigh,
    [Parameter(Mandatory = $true)]
    [string]$FortifyLow,
    [Parameter(Mandatory = $true)]
    [string]$FortifyMedium,
    [Parameter(Mandatory = $true)]
    [string]$FortifyCritical,
    [Parameter(Mandatory = $true)]
    [string]$FortifyTotal,
    [Parameter(Mandatory = $true)]
    [string]$FortifyEndpoint,
    [Parameter(Mandatory = $true)]
    [string]$SonarName,
    [Parameter(Mandatory = $true)]
    [string]$SonarQmp1,
    [Parameter(Mandatory = $true)]
    [string]$SonarQmp2,
    [Parameter(Mandatory = $true)]
    [string]$SonarQmp3,
    [Parameter(Mandatory = $true)]
    [string]$SonarStatus,
    [Parameter(Mandatory = $true)]
    [string]$SonarUrl

)


try {

    $SQLModuleCheck = Get-Module -ListAvailable SqlServer
    if ($null -eq $SQLModuleCheck) {
        write-host "SqlServer Module Not Found"
        
            throw " Please install the SqlServer module.."
       
    }
    else {
        write-host "SqlServer Module:$SQLModuleCheck  "
        Import-Module SqlServer 


        Write-Host "Server: $SQLInstance"
        Write-Host "DB Name: $SQLDatabase"
        Write-Host "User: $SQLUsername"
        Write-Host "AppName: $APPName"
        Write-Host "Branch: $Branch"


        $SQLQuery1 = "USE $SQLDatabase SELECT ID FROM APPLIST where APPNAME='$APPName' and ENV='$Branch'"
        $SQLQuery1Output = Invoke-Sqlcmd -query $SQLQuery1 -ServerInstance "$SQLInstance"  -Username "$SQLUsername" -Password "$SQLPassword" -TrustServerCertificate:$true
        $SQLQuery1Output.count
        $SQLQuery1Output
        if ($SQLQuery1Output.count -eq 1) {
            Write-Host "App Name is already added.."
        }
        else {
            Write-Host "App Name is not added.."
            $SQLQuery1 = "USE $SQLDatabase INSERT INTO [APPLIST] ([APPNAME] ,[ENV] ,[PROJECT] ,[PROGRAM]) Output Inserted.ID 
            VALUES ('$APPName','$Branch','$Project','$Program') "
            $SQLQuery1Output = Invoke-Sqlcmd -query $SQLQuery1 -ServerInstance "$SQLInstance" -Username "$SQLUsername" -Password "$SQLPassword" -TrustServerCertificate:$true 
            $SQLQuery1Output.count
            $SQLQuery1Output
            Write-Host "App Name added Successfully.."
        }
        if ($SQLQuery1Output.count -eq 1) {
            Write-Host "Inserting into BDBA.."
            $SQLQuery2 = "USE $SQLDatabase INSERT INTO [dbo].[BDBA] ([BDBANAME] ,[COMPONENTS],[VULNERABILITIES],[LICENSE],[STATUS],[APPLISTID],[URL],[BUILDID])
            VALUES ('$BDBAName','$BDBAComp','$BDBAVuln','$BDBALice','$BDBAStatus','$($SQLQuery1Output.ID)','$BDBAUrl','$BuildID' )"
            $SQLQuery2Output = Invoke-Sqlcmd -query $SQLQuery2 -ServerInstance "$SQLInstance" -Username "$SQLUsername" -Password "$SQLPassword" -TrustServerCertificate:$true
            $SQLQuery2Output.count
            $SQLQuery2Output
            Write-Host "Successfully added into BDBA Table.."


            Write-Host "Inserting into BDH.."
            $SQLQuery3 = "USE $SQLDatabase INSERT INTO [dbo].[BDH] ([BDHNAME],[LICENSERISK],[OPERATIONALRISK],[SECURITYRISK],[APPLISTID],[URL],[BUILDID])
            VALUES('$BDHName','$BDHLiceRisk','$BDHOperRisk','$BDHSecuRisk','$($SQLQuery1Output.ID)','$BDHUrl','$BuildID')"
            $SQLQuery3Output = Invoke-Sqlcmd -query $SQLQuery3 -ServerInstance "$SQLInstance" -Username "$SQLUsername" -Password "$SQLPassword" -TrustServerCertificate:$true
            $SQLQuery3Output.count
            $SQLQuery3Output
            Write-Host "Successfully added into BDH Table.."

            Write-Host "Inserting into Fortify.."
            $SQLQuery4 = "USE $SQLDatabase INSERT INTO [dbo].[FORTIFY] ([FORTIFYNAME],[CRITICAL],[HIGH],[MEDIUM],[LOW],[TOTAL],[APPLISTID],[URL],[BUILDID])
            VALUES('$FortifyName','$FortifyCritical','$FortifyHigh','$FortifyMedium','$FortifyLow','$FortifyTotal','$($SQLQuery1Output.ID)','$FortifyEndpoint','$BuildID')"
            $SQLQuery4Output = Invoke-Sqlcmd -query $SQLQuery4 -ServerInstance "$SQLInstance" -Username "$SQLUsername" -Password "$SQLPassword" -TrustServerCertificate:$true
            $SQLQuery4Output.count
            $SQLQuery4Output
            Write-Host "Successfully added into Fortify Table.."

            Write-Host "Inserting into Sonarqube.."
            $SQLQuery5 = "USE [InT_Reports] INSERT INTO [dbo].[SONARQUBE] ([SONARNAME],[QMP1],[QMP2],[QMP3],[STATUS],[APPLISTID],[URL],[BUILDID])
            VALUES('$SonarName','$SonarQmp1','$SonarQmp2','$SonarQmp3','$SonarStatus','$($SQLQuery1Output.ID)','$SonarUrl','$BuildID')"
            $SQLQuery5Output = Invoke-Sqlcmd -query $SQLQuery5 -ServerInstance "$SQLInstance" -Username "$SQLUsername" -Password "$SQLPassword" -TrustServerCertificate:$true
            $SQLQuery5Output.count
            $SQLQuery5Output
            Write-Host "Successfully added into Sonarqube Table.."




        }else{

            throw "Error: Unable to insert the data into the table.. $SQLQuery1"

        }

    }
}
catch {
    Write-Host "Error: $_" 
    exit 1
}

