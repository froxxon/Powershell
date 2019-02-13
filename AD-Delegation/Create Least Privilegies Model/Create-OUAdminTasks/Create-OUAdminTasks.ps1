Import-module 'C:\temp\SharedCode.psm1'
$LogFile = "C:\temp\Create-OUAdminTasks\Create-OUAdminTasks.log"

Function CreateGroup ($GroupName,$Description) {
    Try {
        New-ADGroup -Path "OU=T0-Tasks,OU=Tier 0,OU=Admin,$DomainDN" -Name $GroupName -GroupScope DomainLocal  -GroupCategory Security -Description $Description
        Write-Log "Created $GroupName in OU=T0-Tasks,OU=Tier 0,OU=Admin,$DomainDN"
    }
    Catch {
        Write-Log "Couldn't create $GroupName in OU=T0-Tasks,OU=Tier 0,OU=Admin,$DomainDN" -LogType ERROR
    }
}

$OUs = $(Get-ADOrganizationalUnit -LDAPFilter '(name=*)' -SearchBase "OU=Servers,$DOmainDN" -SearchScope Subtree).Name
$Description = "Local Server Administrator"
ForEach ( $OU in $OUs ) {
    $GroupName = "Task-Server-LocalAdmin-$OU"
    If ( $OU -ne "Servers" ) {
        CreateGroup -GroupName $GroupName -Description $Description
    }
}

$Description = "Local Server User"
CreateGroup -GroupName "Task-Server-LocalUser-Adminservers" -Description $Description