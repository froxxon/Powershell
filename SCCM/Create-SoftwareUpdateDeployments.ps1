Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
cd a01:

Function CreateDeployment ( $SoftwareUpdateGroupName,$Collection, $DeploymentType ) {
    Write-host "Creating deployment for SUG ""$SoftwareUpdateGroupName"" to the collection ""$Collection"""
    Try {
        New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $SoftwareUpdateGroupName -DeploymentType $DeploymentType -CollectionName $Collection -ProtectedType RemoteDistributionPoint -AvailableDateTime "$(Get-Date -format yyyy/MM/dd) 00:00AM" -DeadlineDateTime "$(Get-Date -format yyyy/MM/dd) 00:00AM" | out-null         
        Write-host "Created the deployment successfully"
    }
    Catch {
        Write-host "Failed to create deployment"
    }
    Write-host ""
}

$TargetCollection = "SHD.SU#Server group - General servers - Domain"
CreateDeployment -SoftwareUpdateGroupName "SHD - ADR - Windows Server 2018-07-11 00:00:00" -Collection $TargetCollection -DeploymentType Required
CreateDeployment -SoftwareUpdateGroupName "SHD - ADR - Windows Server 2018-08-15 00:00:00" -Collection $TargetCollection -DeploymentType Required
CreateDeployment -SoftwareUpdateGroupName "SHD - ADR - Windows Server 2018-09-12 00:00:00" -Collection $TargetCollection -DeploymentType Required