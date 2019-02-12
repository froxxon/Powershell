$LookupDomains = @("domain1","domain2")
$TaskName = "Task-Computer-DenyLogon-T1"

ForEach ( $LookupDomain in $LookupDomains ) {
    $DomainDN = $(Get-ADDOmain -Server $LookupDomain).DistinguishedName
    $Roles = $(Get-ADGroup -filter * -SearchBase "OU=T1-Roles,OU=Tier 1,OU=Admin,$DomainDN" -Properties memberOf -Server $LookupDomain | Where memberOf -notcontains "CN=$TaskName,OU=T0-Tasks,OU=Tier 0,OU=Admin,$DomainDN").Name
    ForEach ( $Role in $Roles ) {
       Add-ADGroupMember -Identity $TaskName -Members $Role -Server $LookupDomain
    }
    Write-host "Domain: $LookupDomain"
    $Roles
    $Roles.Count
}

