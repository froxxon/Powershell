Function Write-Log {
   Param ([string]$logstring)
   $Timestamp = Get-Date
   $logstring = "$Timestamp - $logstring"
   Add-content $Logfile -value $logstring
}

Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1" ; cd a01:

$Computers = @("Computer1","Computer2","Computer3")
$Domain = "domain.local"
$username = "$Domain\ServiceAccountUser" # <- Put the name for the service account here
$Password = "" # <- Put the password for the service account here
$DomainDN = $(Get-ADDomain).DistinguishedName
$domaininfo = new-object DirectoryServices.DirectoryEntry("LDAP://$Domain/ou=Clients,$DomainDN",$UserName,$Password)
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $domaininfo

ForEach ( $Computer in $Computers ) {
    $LogFile = "C:\temp\Remove-DuplicateUsersFromCMDevice\Logs\$Computer.log"
    $objSearcher.Filter = "(&(objectCategory=computer)(cn=$Computer))"
    $objSearcher.PropertiesToLoad.Add("primaryuser") | out-null
    $PrimaryUser = $objSearcher.FindAll()
    $PrimaryUser = $PrimaryUser.Properties.afprimaryuser
    Write-Log "The primary user for $Computer is $PrimaryUser"

    $Users = $(Get-CMUserDeviceAffinity -DeviceName $Computer).UniqueUserName
    ForEach ( $User in $Users ) {
        If ( $User -ne "$Domain\$PrimaryUser" -or $User -contains "local_users" ) {
            If ( $PrimaryUser -ne $Null ) {
                Remove-CMDeviceAffinityFromUser -UserName $User -DeviceName $Computer -Force
                Write-Log " - Removed $User from $Computer"
            }
        }
    }
    If ( $PrimaryUser -eq $Null ) { Move-Item $LogFile "C:\temp\Remove-DuplicateUsersFromCMDevice\Logs\NoPrimaryUser" }
    $PrimaryUser = ""
    $Users = ""
    $User = ""
}