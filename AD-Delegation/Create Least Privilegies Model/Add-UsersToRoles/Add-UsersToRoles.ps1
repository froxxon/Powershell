Function AddUserToGroup ($User,$Tier,$Role) {
    $UserExist = Get-ADUser -LDAPFilter "(sAMAccountName=l$Tier$User)"
    If ($UserExist -ne $Null) {
        Try {
            Add-ADPrincipalGroupMembership -identity:"l$Tier$User" -memberof:"Role-T$Tier-$Role"
            Write-Log "Added l$Tier$User to Role-T$Tier-$Role"
        }
        Catch {
            Write-Log "Couldn't add l$Tier$User to Role-T$Tier-$Role" -LogType ERROR
        }
    }
}

Import-module 'C:\temp\SharedCode.psm1'
$LogFile = "C:\temp\LeastPrivilegies\Add-UsersToRoles\Add-UsersToRoles.log"

$Users = $(Get-ADUser -LDAPFilter "(name=*adm)" -SearchBase "OU=AdminUsers,$DomainDN").Name
ForEach ( $User in $Users ) {

    $Groups = Get-ADPrincipalGroupMembership $User | select name
    ForEach ( $Group in $Groups ){
    #    If ( $Group.Name -eq "ITAApplikationAdmins" ) {
    #        AddUserToGroup -User $User -Tier "1" -Role "Application"
    #        AddUserToGroup -User $User -Tier "2" -Role "Application"
    #    }
    #    If ( $Group.Name -eq "ITAInfraAdmins" ) {
    #        AddUserToGroup -User $User -Tier "0" -Role "Infrastructure"
    #        AddUserToGroup -User $User -Tier "1" -Role "Infrastructure"
    #        AddUserToGroup -User $User -Tier "2" -Role "Infrastructure"
    #    }
    #    If ( $Group.Name -eq "ITADriftAdmins" ) {
    #        AddUserToGroup -User $User -Tier "1" -Role "Operations"
    #        AddUserToGroup -User $User -Tier "2" -Role "Operations"
    #    }
    #    If ( $Group.Name -eq "ITAMessagingAdmins" ) {
    #        AddUserToGroup -User $User -Tier "1" -Role "Messaging"
    #        AddUserToGroup -User $User -Tier "2" -Role "Messaging"
    #    }
    #    If ( $Group.Name -eq "ITAPrintAdmins" ) {
    #        AddUserToGroup -User $User -Tier "1" -Role "Print"
    #        AddUserToGroup -User $User -Tier "2" -Role "Print"
    #    }
    #    If ( $Group.Name -eq "PISASSOAdmins" ) {
    #        AddUserToGroup -User $User -Tier "1" -Role "IAM"
    #    }
    #    If ( $Group.Name -eq "SANAdmins" ) {
    #        AddUserToGroup -User $User -Tier "1" -Role "Storage"
    #    }
        If ( $Group.Name -eq "ServicedeskAdmins" ) {
            AddUserToGroup -User $User -Tier "1" -Role "Servicedesk"
            AddUserToGroup -User $User -Tier "2" -Role "Servicedesk"
        }
        If ( $Group.Name -eq "ServicedeskAdminAdmins" ) {
            AddUserToGroup -User $User -Tier "1" -Role "Administration"
        }
        If ( $Group.Name -eq "ServicedeskOfficeAdmins" ) {
            AddUserToGroup -User $User -Tier "1" -Role "Office"
            AddUserToGroup -User $User -Tier "2" -Role "Servicedesk"
        }
        If ( $Group.Name -eq "ServicedeskPCAdmins" ) {
            AddUserToGroup -User $User -Tier "1" -Role "PC"
            AddUserToGroup -User $User -Tier "2" -Role "PC"
        }
    #    If ( $Group.Name -eq "SharepointAdmins" ) {
    #        AddUserToGroup -User $User -Tier "1" -Role "Sharepoint"
    #    }
    #    If ( $Group.Name -eq "VMWareAdmins" ) {
    #        AddUserToGroup -User $User -Tier "1" -Role "VIP"
    #    }
    }

}