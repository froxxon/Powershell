$LookupDomains = @("domain1","domain2")
$global:Roles = @()
$global:ObsoleteManagers = @()
$global:TempObsoleteManagers = @()
$SMTPServer = "" # <- Put SMTP server here

# Get information about Roles
Function GetRoles {
    ForEach ( $LookupDomain in $LookupDomains ) {
        $DomainDN = $(Get-ADDomain -Server $LookupDomain).DistinguishedName
        $global:Roles += Get-ADGroup -Filter 'Name -like "Role-T*"' -Properties Name, Description, Info -SearchScope Subtree -SearchBase "OU=Admin,$DomainDN" -Server $LookupDomain | Select Name, @{Name='Manager'; Expression = {"$($_.'Info'.Substring(9,5))"}}, Description | Add-Member -NotePropertyName Domain -NotePropertyValue $LookupDomain -Passthru #-Force
    }
}

# Check if Managers exist in Production as standard users
Function CheckForManagersInProd {
    $Managers = $global:Roles.Manager | select -Unique | sort
    ForEach ( $Manager in $Managers ) {
        $Filter = 'samAccountName -eq "' + $Manager + '" -and Enabled -eq "True"'
        $UserExist = Get-ADUser -filter $Filter -Properties samAccountName -SearchBase "OU=x500Users,DC=wp,DC=ams,DC=se" -SearchScope OneLevel
        If ( $UserExist.Count -eq 0 ) {
            $global:TempObsoleteManagers += $Manager
        }
    }
    ForEach ( $Manager in $global:TempObsoleteManagers ) {
        $global:ObsoleteManagers += $global:Roles | Where Manager -eq $Manager
    }
}

GetRoles
CheckForManagersInProd

#Lists Roles missing Manager
$RolesMissingManager = $global:Roles | Where Manager -eq $Null

#Lists Roles with obsolete Managers that doesn't exist in Production
$RolesWithObsoleteManagers = $global:ObsoleteManagers | select Name, Manager, Domain, Description

#Lists all Roles to get different Managers for same Role
#$global:Roles | select Name, Manager, Domain, Description | sort Name

If ( $RolesWithObsoleteManagers -ne $Null -or $RolesMissingManager -ne $Null ) {
    $MailBody ="Hi!
    
This is a list of roles that are missing or not existing managers connected to them.
     
"
    If ( $RolesWithObsoleteManagers -ne $Null ) {
        $MailBody += "Those roles has Managers that no longer exists:`n`n"
        ForEach ( $Role in $RolesWithObsoleteManagers ) {
            $MailBody += "$($Role.Name)`t$($Role.Manager)`t$($Role.Domain)`n"
        }
    }
    If ( $RolesMissingManager -ne $Null ) {
        If ( $RolesWithObsoleteManagers -ne $Null ) {
            $MailBody += "`n"
        }
        $MailBody += "Those roles are missing a manager:`n`n"
        ForEach ( $Role in $RolesMissingManager ) {
            $MailBody += "$($Role.Name)`t$($Role.Domain)`n"
        }
    }
    $MailBody += "`nBest regards"
}

$Recipients = @("mail@mail.com")
Send-MailMessage -Encoding utf8 -Body $MailBody -From noreply@domain.local -To $Recipients -Subject "AD-Delegation Roles needs attention!" -SmtpServer $SMTPServer