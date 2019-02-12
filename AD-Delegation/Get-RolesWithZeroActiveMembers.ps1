Clear-Host
$LookupDomains = @("domain1","domain2")
$ActiveMembers = @()
$RolesInfo = @()

ForEach ($LookupDomain in $LookupDomains ) {
    $DomainDN = $(Get-ADDomain -Server $LookupDomain).DistinguishedName
    $Roles = Get-ADGroup -Filter 'Name -like "Role-T*"' -SearchBase "OU=Admin,$DomainDN" -Server $LookupDomain
    ForEach ( $Role in $Roles ) {
        $ActiveMembers = @(Get-ADGroup $Role -Server $LookupDomain | Get-ADGroupMember -Server $LookupDomain | Get-ADUser -Properties samAccountName, Enabled -Server $LookupDomain | Where Enabled -eq $True).Count
        If ( $ActiveMembers[0] -eq 0 ) {
            $TempObject = New-Object System.Object
            $TempObject | Add-Member -MemberType NoteProperty -Name "Role" -Value $Role.Name -Force
            $TempObject | Add-Member -MemberType NoteProperty -Name "Domain" -Value $LookupDomain -Force
            $RolesInfo  += $TempObject
        }
    }
}

$RolesInfo

Function GetUsersWihtoutRoles {
    $LookupDomains = @("domain1","domain2")

    ForEach ($LookupDomain in $LookupDomains ) {
        $DomainDN = $(Get-ADDomain -Server $LookupDomain).DistinguishedName
        $Users = Get-ADUser -Filter 'Enabled -eq "True"' -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree -Properties samAccountName, memberof -Server $LookupDomain
        ForEach ( $User in $Users ) {
            If ( $($User.MemberOf).Count -eq 0 ) {
                write-host "$LookupDomain\$($User.samAccountName)"
            }
        }
    }
}
GetUsersWihtoutRoles