Clear-Host
$LookupDomains = @("domain1","domain2")

ForEach ( $LookupDomain in $LookupDomains ) {
    $DomainDN = $(Get-ADDomain -Server $LookupDomain).DistinguishedName
    
    # Check for privileged users password expiration time
    #Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} -SearchBase "OU=Admin,$DomainDN" –Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" -Server $LookupDomain | Select-Object -Property samAccountName,@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}} | Sort ExpiryDate -Descending
    
    # Check for privileged users with Password Never Expires set, should not be many at all!
    $Users = Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $True} -SearchBase "OU=Admin,$DomainDN" –Properties "DisplayName" -Server $LookupDomain | Select-Object -Property samAccountName
    $ExcludedUsers = @("user1","user2","user3")
    ForEach ( $User in $Users ) {
        If ( $ExcludedUsers -notcontains $User.samAccountName ) {
            Write-host "$LookupDomain\$($User.samAccountName)"
            Set-ADUser -Identity $User.samAccountName -PasswordNeverExpires:$FALSE -Server $LookupDomain
        }
    }
}

Disable-ADAccount user3 -Server $LookupDomain