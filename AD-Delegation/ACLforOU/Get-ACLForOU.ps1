Import-Module -Name ActiveDirectory
Import-Module "C:\Temp\SharedCode.psm1" -Force
$LogFile = "C:\temp\Get-ACLForOU\Get-ACLForOU.log"
$DomainDN = $( Get-ADDomain ).DistinguishedName
Dir AD: | out-null

Function Get-ACLForOU ($OU,$Group) {
    $ShortOU = $OU
    $OU = "$OU,$DomainDN"
    $OU_ACL = Get-Acl -Path "AD:\$OU"
    $OU_SDDL = $OU_ACL.GetSecurityDescriptorSddlForm([System.Security.AccessControl.AccessControlSections]::Access)
    If ( $Group -ne $null ) {
        $Group_SID = $(Get-ADGroup "$Group").SID.value
        $OU_SDDL = $OU_SDDL.Split('()',[System.StringSplitOptions]::RemoveEmptyEntries)
        $Group_ACLs = @()
        ForEach ( $Line in $OU_SDDL ) {
            If ( $Line -like "*$Group_SID*" ) {
                $Line = $Line -replace "$Group_SID",""
                $Group_ACLs += $Line
            }
        }
    }
    Else {
        $OU_SDDL.Split('()',[System.StringSplitOptions]::RemoveEmptyEntries) | Out-GridView
    }
}

Get-ACLForOU -OU "OU=Admin" -Group "Task-OU-FullControl-Admin"

exit
Get-ACLForOU -OU "OU=Clients" -Group "Task-Computer-Modify_Enabled_Disabled-Clients"
Get-ACLForOU -OU "OU=MaintenanceGroups" -Group "Task-Group-Modify_Members-MaintenanceGroups"
Get-ACLForOU -OU "OU=MaintenanceGroups" -Group "Task-OU-FullControl-MaintenanceGroups"
Get-ACLForOU -OU "OU=Servers" -Group "Task-Computer-Create-Servers"
Get-ACLForOU -OU "OU=Servers" -Group "Task-Computer-Delete-Servers"
Get-ACLForOU -OU "OU=Servers" -Group "Task-OU-Create-Servers"
Get-ACLForOU -OU "OU=Servers" -Group "Task-OU-Delete-Servers"
Get-ACLForOU -OU "OU=Servers" -Group "Task-OU-FullControl-Servers"
Get-ACLForOU -OU "OU=ServiceAccounts" -Group "Task-User-Manage-ServiceAccounts"
Get-ACLForOU -OU "OU=T1-Accounts,OU=Tier 1,OU=Admin" -Group "Task-User-Manage-T1-Accounts"
Get-ACLForOU -OU "OU=T1-Accounts,OU=Tier 1,OU=Admin" -Group "Task-User-Reset_Passwords-T1-Accounts"
Get-ACLForOU -OU "OU=T1-Accounts,OU=Tier 1,OU=Admin" -Group "Task-User-Unlock-T1-Accounts"
Get-ACLForOU -OU "OU=T1-Roles,OU=Tier 1,OU=Admin" -Group "Task-Group-Modify_Members-T1-Roles"
Get-ACLForOU -OU "OU=T2-Accounts,OU=Tier 2,OU=Admin" -Group "Task-User-Manage-T2-Accounts"
Get-ACLForOU -OU "OU=T2-Accounts,OU=Tier 2,OU=Admin" -Group "Task-User-Reset_Passwords-T2-Accounts"
Get-ACLForOU -OU "OU=T2-Accounts,OU=Tier 2,OU=Admin" -Group "Task-User-Unlock-T2-Accounts"
Get-ACLForOU -OU "OU=T2-Roles,OU=Tier 2,OU=Admin" -Group "Task-Group-Modify_Members-T2-Roles"