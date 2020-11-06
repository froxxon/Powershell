$OUDistinguishedName = "OU=Objects,$((Get-ADDomain).DistinguishedName)"
$ClientOwners = Get-ADComputer -Filter * -properties ntSecurityDescriptor -SearchBase "$OUDistinguishedName" | Where { $_.ntSecurityDescriptor.Owner -ne 'DOMAIN\Domain Admins'} | Select Name, distinguishedName, @{name='Owner';e={$_.ntSecurityDescriptor.Owner}} | Sort
$ClientOwners.Count
$UserOwners = Get-ADUser -Filter * -properties ntSecurityDescriptor -SearchBase $OUDistinguishedName | Where { $_.ntSecurityDescriptor.Owner -ne 'DOMAIN\Domain Admins' } | Select Name, distinguishedName, @{name='Owner';e={$_.ntSecurityDescriptor.Owner}} | Sort
$UserOwners.count
$GroupOwners = Get-ADGroup -Filter * -properties ntSecurityDescriptor -SearchBase $OUDistinguishedName | Where { $_.ntSecurityDescriptor.Owner -ne 'DOMAIN\Domain Admins'} | Select Name, distinguishedName, @{name='Owner';e={$_.ntSecurityDescriptor.Owner}} | Sort
$GroupOwners.count

$objNewOwner = New-Object System.Security.Principal.NTAccount("DOMAIN", "Domain Admins")
# CHANGE FOREACH BELOW TO THE CORRECT ARRAY (ex. $UserOwners) AND THE OUTFILE PATH
foreach ( $object in $GroupOwners ) {
    $OutfileOld = "C:\Temp\ACLBackup\Group\$($object.Name)_Old.txt"
    $OutfileNew = "C:\Temp\ACLBackup\Group\$($object.Name)_New.txt"
    $ACL = Get-ACL -Path "AD:$($object.distinguishedName)"
    $ACL.sddl | out-file $OutfileOld -Append
    $ACL.SetOwner($objNewOwner)
    try {
        Set-ACL -Path "AD:$($object.distinguishedName)" -AclObject $ACL
        $ACL = Get-ACL -Path "AD:$($object.distinguishedName)"
        $ACL.sddl | out-file $OutfileNew -Append
        Write-Output "$((get-date -format "yyyy-MM-dd HH:mm:ss")) - Successfully changed Owner from `'$($object.Owner)`' to `'$($objNewOwner)`' for `'$($object.distinguishedName)`'"
    }
    catch {
        Write-Output "$((get-date -format "yyyy-MM-dd HH:mm:ss")) - Failed to change Owner from `'$($object.Owner)`' to `'$($objNewOwner)`' for `'$($object.distinguishedName)`'"
    }
}