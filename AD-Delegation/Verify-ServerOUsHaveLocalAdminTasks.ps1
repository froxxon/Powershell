clear-host
$LookupDomains = @("domain1","domain2")

ForEach ( $LookupDomain in $LookupDomains ) {
    $DomainDN = $(Get-ADDOmain -Server $LookupDomain).DistinguishedName
    $OUs = $(Get-ADOrganizationalUnit -Filter * -SearchBase "OU=Servers,$DomainDN" -SearchScope OneLevel -Server $LookupDomain).Name
    $LocalAdminTasks = $(Get-ADGroup -Filter "Name -like 'Task-Server-LocalAdmin-*'" -SearchBase "OU=T0-Tasks,OU=Tier 0,OU=Admin,$DomainDN" -Server $LookupDomain).Name
    ForEach ( $OU in $OUs ) {
        If ( $LocalAdminTasks -notcontains "Task-Server-LocalAdmin-$OU" ) {write-host "$LookupDOmain - $OU" }
    }
}