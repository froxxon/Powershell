$Containers = @()
$UserStatuses = @()

"Reading OU List ..."
$Containers = Get-ADOrganizationalUnit -Filter * -Properties * | sort canonicalname | select distinguishedname, canonicalname

"Reading Container List ..."
$Containers += Get-ADObject -SearchBase (Get-ADDomain).distinguishedname -SearchScope OneLevel -LDAPFilter '(objectClass=container)' -Properties * | sort canonicalname | select distinguishedname, canonicalname

foreach($Cntr in $Containers)
{
    "Evaluating - " + $Cntr.distinguishedname + " ..."
    
    $UserStatuses += Get-ADUser -Filter * -SearchBase $Cntr.distinguishedname -SearchScope OneLevel -Properties * | where {($_.nTSecurityDescriptor.AreAccessRulesProtected -eq $true) -and ($_.enabled -eq $true)} | select @{n='OU';e={$Cntr.distinguishedname}}, displayname, userprincipalname,samAccountName, @{n='Inheritance Broken';e={$_.nTSecurityDescriptor.AreAccessRulesProtected}}
}

$UserStatuses | export-csv -path C:\temp\UsersWithInheritanceBroken.csv