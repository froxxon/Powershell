$date = New-Object System.DateTime(2017,2,20)
$Users = get-adobject -filter {(createTimeStamp -gt $date) -and (deleted -eq $True)} -IncludeDeletedObjects -properties *
Clear-Host
samAccountName
ForEach ( $User in $Users ) {
    If ( $User.objectClass -eq "groupPolicyContainer" ) { "$($User.DisplayName)`n$($User.objectClass)`n$($User.Modified)`n" ; Continue }
    "$($User."msDS-LastKnownRDN")`n$($User.objectClass)`n$($User.Modified)`n"
}