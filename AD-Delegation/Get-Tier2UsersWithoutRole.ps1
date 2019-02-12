$DomainDN = $(Get-ADDomain).DistinguishedName
$Tier2Users = $(Get-ADUser -filter * -SearchBase "OU=T2-Accounts,OU=Tier 2,OU=Admin,$DomainDN" -SearchScope OneLevel).Name

ForEach ( $User in $L2Users ) {
    $ConnectedToRule = $False
    $memberOf = $(Get-ADPrincipalGroupMembership $User).Name
    ForEach ( $Member in $MemberOf ) {
        If ( $Member -like "Role-*" ) { 
            $ConnectedToRule = $True
            Continue
        }
    }
    If ( $ConnectedToRule -eq $False ) {
        Write-host "$User"
    }
}