$DomainDN = $(Get-ADDomain).DistinguishedName
ForEach ( $Tier2User in $(Get-ADUser -filter * -SearchBase "OU=T1-Accounts,OU=Tier 1,OU=Admin,$DomainDN" | Sort samAccountName ) ) {
    $Tier1UserPath = "AD:\CN=$($Tier2User.Name),OU=T1-Accounts,OU=Tier 1,OU=Admin,$DomainDN"
    $Tier2UserSID = $(Get-ADUser $($Tier2User.Name)).SID
    $ACL = Get-ACL -Path $Tier1UserPath
    If ( $($ACL.Access | Where { $_.IdentityReference -like "*$($Tier2User.Name)*" -and $_.ActiveDirectoryRights -eq "ExtendedRight" }).Count -eq 0 ) {
        $ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Tier2UserSID,"ExtendedRight","Allow",([GUID]("00299570-246d-11d0-a768-00aa006e0529")).guid,"None",([GUID]("bf967aba-0de6-11d0-a285-00aa003049e2")).guid))
        Write-host "Added permissions to $($Tier2User.Name)"
        Set-ACL -Path $Tier1UserPath -ACLObject $ACL
    }
}
ForEach ( $Tier2User in $(Get-ADUser -filter * -SearchBase "OU=T2-Accounts,OU=Tier 2,OU=Admin,$DomainDN" | Sort samAccountName ) ) {
    If ( Get-ADUser -LDAPFilter "(name=*$($Tier2User.Name -replace "l2","l1")*)" -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree ) {
        $Tier2UserPath = "AD:\CN=$($Tier2User.Name),OU=T2-Accounts,OU=Tier 2,OU=Admin,$DomainDN"
        $Tier2UserSID = $(Get-ADUser $($Tier2User.Name -replace "l2","l1")).SID
        $ACL = Get-ACL -Path $Tier2UserPath 
        If ( $($ACL.Access | Where { $_.IdentityReference -like "*$($Tier2User.Name -replace "l2","l1")*" -and $_.ActiveDirectoryRights -eq "ExtendedRight" }).Count -eq 0 ) {
            $ACL.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Tier2UserSID,"ExtendedRight","Allow",([GUID]("00299570-246d-11d0-a768-00aa006e0529")).guid,"None",([GUID]("bf967aba-0de6-11d0-a285-00aa003049e2")).guid))
            Write-host "Added permissions to $($Tier2User.Name)"
            Set-ACL -Path $Tier2UserPath -ACLObject $ACL
        }
    }
}