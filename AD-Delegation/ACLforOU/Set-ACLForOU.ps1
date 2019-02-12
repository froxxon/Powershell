Import-Module -Name ActiveDirectory
Import-Module "C:\Temp\SharedCode.psm1"
$Logfile = "C:\Temp\Set-ACLForOU\Set-ACLForOU.log"
$DomainDN = $( Get-ADDomain ).DistinguishedName
Dir AD: | out-null

Function Set-ACLForOU ($Group,$OU,$AccessRights) {
    $OU = "$OU,$DomainDN"
    $Group_SID = $(Get-ADGroup "$Group").SID.value
    $OU_ACL = Get-Acl -Path "AD:\$OU"
    $OU_SDDL = $OU_ACL.GetSecurityDescriptorSddlForm([System.Security.AccessControl.AccessControlSections]::Access)
    $New_SDDL = $OU_SDDL
    $New_SDDL += @("($AccessRights$Group_SID)")
    Try {
        $OU_ACL.SetSecurityDescriptorSddlForm($New_SDDL)
        Set-ACL -Path "AD:\$OU" -AclObject $OU_ACL
        Write-Log "Added new ACL for the group ""$Group"":"
        Write-Log "Applied to OU: $OU"
        Write-Log "Group SID: $Group_SID"
        Write-Log "Accessrights: $AccessRights"
        Write-Log " "
    }
    Catch {
        Write-Log "Couldn't add new ACL for the group ""$Group"":" -LogType ERROR
        Write-Log "Applied to OU: $OU" -LogType ERROR
        Write-Log "Group SID: $Group_SID" -LogType ERROR
        Write-Log "Accessrights: $AccessRights" -LogType ERROR
        Write-Log " " -LogType ERROR
    }
}

### Examples ###
Set-ACLForOU -Group "Task-OU-FullControl-Admin" -OU "OU=Admin" -AccessRights "I;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;"
Set-ACLForOU -Group "Task-Computer-Modify_Enabled_Disabled-Clients" -OU "OU=Clients" -AccessRights "A;CIIO;RPWP;4c164200-20c0-11d0-a768-00aa006e0529;bf967a86-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-OU-FullControl-Domain Computers" -OU "OU=Domain Computers" -AccessRights "A;CI;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;"
Set-ACLForOU -Group "Task-Group-Modify_Members-MaintenanceGroups" -OU "OU=MaintenanceGroups" -AccessRights "A;CIIO;RPWP;bf9679c0-0de6-11d0-a285-00aa003049e2;bf967a9c-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-OU-FullControl-MaintenanceGroups" -OU "OU=MaintenanceGroups" -AccessRights "A;CI;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;"
Set-ACLForOU -Group "Task-Computer-Create-Servers" -OU "OU=Servers" -AccessRights "A;CI;CC;bf967a86-0de6-11d0-a285-00aa003049e2;;"
Set-ACLForOU -Group "Task-Computer-Delete-Servers" -OU "OU=Servers" -AccessRights "A;CI;DC;bf967a86-0de6-11d0-a285-00aa003049e2;;"
Set-ACLForOU -Group "Task-OU-Create-Servers" -OU "OU=Servers" -AccessRights "A;CIIO;CC;bf967aa5-0de6-11d0-a285-00aa003049e2;bf967aa5-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-OU-Delete-Servers" -OU "OU=Servers" -AccessRights "A;CIIO;DT;;bf967aa5-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-OU-FullControl-Servers" -OU "OU=Servers" -AccessRights "A;CI;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;"
Set-ACLForOU -Group "Task-User-Manage-T1-Accounts" -OU "OU=T1-Accounts,OU=Tier 1,OU=Admin" -AccessRights "CIIO;CCDCLCSWRPWPDTLOCRSDRCWDWO;;bf967aba-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-User-Manage-T1-Accounts" -OU "OU=T1-Accounts,OU=Tier 1,OU=Admin" -AccessRights "CI;CCDC;bf967aba-0de6-11d0-a285-00aa003049e2;;"
Set-ACLForOU -Group "Task-User-Manage-T1-Accounts" -OU "OU=T1-Accounts,OU=Tier 1,OU=Admin" -AccessRights "CIIO;RPWP;bf967a68-0de6-11d0-a285-00aa003049e2;bf967aba-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-User-Reset_Passwords-T1-Accounts" -OU "OU=T1-Accounts,OU=Tier 1,OU=Admin" -AccessRights "CIIO;RPWP;bf967a0a-0de6-11d0-a285-00aa003049e2;bf967aba-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-User-Reset_Passwords-T1-Accounts" -OU "OU=T1-Accounts,OU=Tier 1,OU=Admin" -AccessRights "CIIO;CR;00299570-246d-11d0-a768-00aa006e0529;bf967aba-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-User-Unlock-T1-Accounts" -OU "OU=T1-Accounts,OU=Tier 1,OU=Admin" -AccessRights "CIIO;RPWP;28630ebf-41d5-11d1-a9c1-0000f80367c1;bf967aba-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-Group-Modify_Members-T1-Roles" -OU "OU=T1-Roles,OU=Tier 1,OU=Admin" -AccessRights "CIIO;RPWP;bf9679c0-0de6-11d0-a285-00aa003049e2;bf967a9c-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-User-Manage-T2-Accounts" -OU "OU=T2-Accounts,OU=Tier 2,OU=Admin" -AccessRights "CIIO;CCDCLCSWRPWPDTLOCRSDRCWDWO;;bf967aba-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-User-Manage-T2-Accounts" -OU "OU=T2-Accounts,OU=Tier 2,OU=Admin" -AccessRights "CI;CCDC;bf967aba-0de6-11d0-a285-00aa003049e2;;"
Set-ACLForOU -Group "Task-User-Manage-T2-Accounts" -OU "OU=T2-Accounts,OU=Tier 2,OU=Admin" -AccessRights "CIIO;RPWP;bf967a68-0de6-11d0-a285-00aa003049e2;bf967aba-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-User-Reset_Passwords-T2-Accounts" -OU "OU=T2-Accounts,OU=Tier 2,OU=Admin" -AccessRights "CIIO;RPWP;bf967a0a-0de6-11d0-a285-00aa003049e2;bf967aba-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-User-Reset_Passwords-T2-Accounts" -OU "OU=T2-Accounts,OU=Tier 2,OU=Admin" -AccessRights "CIIO;CR;00299570-246d-11d0-a768-00aa006e0529;bf967aba-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-User-Unlock-T2-Accounts" -OU "OU=T2-Accounts,OU=Tier 2,OU=Admin" -AccessRights "CIIO;RPWP;28630ebf-41d5-11d1-a9c1-0000f80367c1;bf967aba-0de6-11d0-a285-00aa003049e2;"
Set-ACLForOU -Group "Task-Group-Modify_Members-T2-Roles" -OU "OU=T2-Roles,OU=Tier 2,OU=Admin" -AccessRights "CIIO;RPWP;bf9679c0-0de6-11d0-a285-00aa003049e2;bf967a9c-0de6-11d0-a285-00aa003049e2;"