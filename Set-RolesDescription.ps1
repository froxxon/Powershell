$LookupDomains = @("domain1","domain2")

$AllRoles = @()
ForEach ( $LookupDomain in $LookupDomains ) {
    $DomainDN = $(Get-ADDomain -Server $LookupDomain).Distinguishedname
    $Roles = Get-ADGroup -filter 'Name -like "Role-T*"' -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree -Server $LookupDomain -Properties Name, Description | Select Name, Description
    ForEach ( $Role in $Roles ) {
        If ( $AllRoles.Name -notcontains $Role.Name ) { $AllRoles += $Role }
    }
}
$AllRoles = $AllRoles | Sort Name
$AllRoles | where { $_.Description -eq $Null }

ForEach ( $LookupDomain in $LookupDomains ) {
    If ( $LookupDomain -ne "domain3" ) {
        ForEach ( $Role in $AllRoles ) {
            Try{  
                $GroupDescription = "Users in this group manages System servers as administrators"
                Try {
                    Set-ADGroup $Role.Name -Description $GroupDescription -Server $LookupDomain
                    Write-host "Sets description of group: $($Role.Name) in domain: $LookupDOmain"
                }
                Catch {}
            }
            Catch {}
        }
    }
}