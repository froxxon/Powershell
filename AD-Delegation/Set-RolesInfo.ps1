$LookupDomains = @("domain1","domain2")

$AllRoles = @()
ForEach ( $LookupDomain in $LookupDomains ) {
    $DomainDN = $(Get-ADDomain -Server $LookupDomain).Distinguishedname
    $Roles = Get-ADGroup -filter 'Name -like "Role-T*"' -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree -Server $LookupDomain -Properties Name, Info | Select Name, Info
    ForEach ( $Role in $Roles ) {
        If ( $AllRoles.Name -notcontains $Role.Name ) { $AllRoles += $Role }
    }
}
$AllRoles = $AllRoles | Sort Name

ForEach ( $LookupDomain in $LookupDomains ) {
    If ( $LookupDomain -ne "domain3" ) {
        ForEach ( $Role in $AllRoles ) {
            Try{  
                Try {
                    Set-ADGroup $Role.Name -replace @{info="Manager: $Manager"} -Server $LookupDomain
                    Write-host "Sets Info for group: $($Role.Name) in domain: $LookupDOmain"
                }
                Catch {}
            }
            Catch {}
        }
    }
}