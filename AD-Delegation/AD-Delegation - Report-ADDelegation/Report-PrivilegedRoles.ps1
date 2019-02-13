Function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string]$Message,
        [Parameter(Position=1)]
        [ValidateSet('INFO','WARN','ERROR')][string]$LogType = 'INFO',
        [Parameter(Position=2)]
        [ValidateSet('Yes','No')][string]$WritePrefix = 'Yes'
    )
    $CurrentDateTime = Get-Date -format "yyyy-MM-dd HH:mm"
    if($Message -eq $null){ $Message = "" }
    If ( $WritePrefix -eq "YES" ) {
        $LogEntry = "$LogType $CurrentDateTime - $Message"
    }
    Else {
        $LogEntry = "$Message"
    }
    Add-Content -Value $LogEntry -Path $LogFile -Encoding UTF8
    Write-Verbose $LogEntry
}

Function GetRowColor {
    $global:RowBGColor = $OddRowBGColor
    If ( $global:OddRow -eq $False ) {
        $global:OddRow = $True
        $global:RowBGColor = "#ffffff"
    }
    Else { $global:OddRow = $False }
}

$LogFile = "C:\Program Files (x86)\AMSPgm\Logs\AD-Delegation - Report-PrivilegedRoles.log"
Write-log "Start creation of reports"
$LookupDomains = @("domain1","domain2")
$Prod = "domain1.local"

#Write-Log "Collecting managers for all roles"
$AllManagers = @()
ForEach ( $LookupDomain in $LookupDomains ) {
    $DomainDN = $(Get-ADDomain -Server $LookupDomain).Distinguishedname
    $Roles = Get-ADGroup -filter 'samAccountName -like "*Role-T*"' -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree -Server $LookupDomain -Properties info
    ForEach ( $Role in $Roles ) {
        $Manager = $Role.info
        If ( $Manager -ne $Null ) { $Manager = $Manager.Substring(9,5) }
        If ( $AllManagers -notcontains $Manager ) { $AllManagers += $Manager }
    }
}
$AllManagers = $AllManagers | Sort

$FirstDomain = $True
$BorderColor = "gray"
$FontFace = "Tahoma"

$ProdStdUsers = "OU=StandardUsers,DC=domain1,DC=local"

ForEach ( $Manager in $AllManagers ) {
    If ( $Manager.Length -eq 5 ) {
    $HTML = ""
    $HTML = @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>AD-Delegation - Your employed privileged users - $Manager</title>
</head><body>
<font face=$FontFace size=2>
<table border="0" width="100%" cellpadding="5" cellspacing="15">
<tr><td></td><td style="border: 1px solid $BorderColor;" bgcolor="#c2d4ff" width=50></td><td width=50>Prod</td><td width=50></td><td style="border: 1px solid $BorderColor;" bgcolor="#cbffc2" width=50></td><td width=50>T2</td><td width=50></td><td style="border: 1px solid $BorderColor;" bgcolor="#ffc2c2" width=50></td><td width=50>T1</td><td width=50></td><td style="border: 1px solid $BorderColor;" bgcolor="#fff8c2" width=50></td><td width=50>Utveckling</td><td width=50></td><td style="border: 1px solid $BorderColor;" bgcolor="#e0e0e0" width=50></td><td width=50>Övrigt</td><td></td>
</table>
"@

        ForEach ( $LookupDomain in $LookupDomains ) {
            $DomainDN = $(Get-ADDomain -Server $LookupDomain).Distinguishedname
            $Domain = $(Get-ADDomain -Server $LookupDomain).DNSRoot.ToUpper()
            $DomainInHTML = $False

            If ( $LookupDomain -eq "domain1" ) { $DomainBGColor = "#c2d4ff" ; $TypeBGColor = "#dbe6ff" ; $OddRowBGColor = "#f5f8ff" }
            If ( $LookupDomain -eq "domain2" ) { $DomainBGColor = "#cbffc2" ; $TypeBGColor = "#dcffd6" ; $OddRowBGColor = "#f6fff5" }

            [array]$AllRoles = Get-ADGroup -filter "Info -like ""*Manager: $Manager*""" -SearchBase "OU=Admin,$DomainDN" -Property samAccountName,Info -SearchScope Subtree -Server $LookupDomain
            [array]$T0Roles = $AllRoles | Where { $_.samAccountName -like "Role-T0*" }
            If ( $T0Roles.Count -gt 0 ) {
                If ( $FirstDomain -eq $True ) { $FirstDomain = $False }
                Else { } #$HTML += "`<br>" }
                ForEach ( $T0Role in $T0Roles ) {
                    [array]$RoleMembers = Get-ADGroupMember $T0Role -Server $LookupDomain | %{Get-ADUser -Identity $_.DistinguishedName -Properties Enabled -Server $LookupDomain |?{ $_.Enabled -eq $True }}
                    If ( $Rolemembers.Count -gt 0 ) {
                        $HTML += "`n<tr><td><br></td></tr>"
                        $HTML += "`n<table border=""0"" width=""100%"" cellpadding=""5"" cellspacing=""0"">"
                        If ( $DomainInHTML -eq $False ) {
                            $HTML += "`n<tr><td></td></tr>"
                            $HTML += "`n<tr><td colspan=""2""><font size=4><b>Domän: $Domain</b></font></td></tr>"
                            $HTML += "`n<tr><td><br></td></tr>"
                            $DomainInHTML = $True
                        }
                        $HTML += "`n<tr><td width=""250px"" ><b>$($T0Role.Name)</b></td><td colspan=2>$($RoleMembers.Count)</td></tr>"
                        $HTML += "`n<tr><td width=""250px""><b>Användare<b></td><td width=""*""><b>Chef</b></td></tr>"
                        $FirstRow = $True
                        ForEach ( $Member in $RoleMembers ) {
                            [array]$User = Get-ADUser -filter "samAccountName -eq ""$($Member.samAccountName)"" -and enabled -eq 'true'" -Property GivenName,Surname,samAccountName,Info -Server $LookupDomain
                            If ( $User.Count -gt 0 ) {
                                Try { $UsersManager = Get-ADUser -filter "samAccountName -eq ""$($User.Info.Substring(9,5))""" -SearchBase $ProdStdUsers -SearchScope OneLevel -Property GivenName,Surname,samAccountName -Server $Prod }
                                Catch {}
                                GetRowColor
                                If ( $FirstRow -eq $True ) {
                                    $HTML += "`n<tr bgcolor=""$RowBGColor""><td style=""border-top: 1px solid $BorderColor;border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$($User.GivenName) $($User.Surname)</td><td style=""border-top: 1px solid $BorderColor;border-right: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$($UsersManager.GivenName) $($UsersManager.SurName) ($($UsersManager.samAccountName))</td></tr>"
                                    $FirstRow = $False
                                }
                                Else {
                                    $HTML += "`n<tr bgcolor=""$RowBGColor""><td style=""border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$($User.GivenName) $($User.Surname)</td><td style=""border-right: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$($UsersManager.GivenName) $($UsersManager.SurName) ($($UsersManager.samAccountName))</td></tr>"
                                }
                            }
                        }
                    }
                }
                $HTML += "`n</table>"
            }
            [array]$T1Roles = $AllRoles | Where { $_.samAccountName -like "Role-T1*" }
            If ( $T1Roles.Count -gt 0 ) {
                If ( $FirstDomain -eq $True ) { $FirstDomain = $False }
                Else { } #$HTML += "`<br>" }
                ForEach ( $T1Role in $T1Roles ) {
                    [array]$RoleMembers = Get-ADGroupMember $T1Role -Server $LookupDomain | %{Get-ADUser -Identity $_.DistinguishedName -Properties Enabled -Server $LookupDomain |?{ $_.Enabled -eq $True }}
                    If ( $Rolemembers.Count -gt 0 ) {
                        $HTML += "`n<tr><td><br></td></tr>"
                        $HTML += "`n<table border=""0"" width=""100%"" cellpadding=""5"" cellspacing=""0"">"
                        If ( $DomainInHTML -eq $False ) {
                            $HTML += "`n<tr><td></td></tr>"
                            $HTML += "`n<tr><td colspan=""2""><font size=4><b>Domän: $Domain</b></font></td></tr>"
                            $HTML += "`n<tr><td><br></td></tr>"
                            $DomainInHTML = $True
                        }
                        $HTML += "`n<tr><td width=""250px"" ><b>$($T1Role.Name)</b></td><td colspan=2>$($RoleMembers.Count)</td></tr>"
                        $HTML += "`n<tr><td width=""250px""><b>Användare<b></td><td width=""*""><b>Chef</b></td></tr>"
                        $FirstRow = $True
                        ForEach ( $Member in $RoleMembers ) {
                            [array]$User = Get-ADUser -filter "samAccountName -eq ""$($Member.samAccountName)"" -and enabled -eq 'true'" -Property GivenName,Surname,samAccountName,Info -Server $LookupDomain
                            If ( $User.Count -gt 0 ) {
                                Try { $UsersManager = Get-ADUser -filter "samAccountName -eq ""$($User.Info.Substring(9,5))""" -SearchBase $ProdStdUsers -SearchScope OneLevel -Property GivenName,Surname,samAccountName -Server $Prod }
                                Catch {}
                                GetRowColor
                                If ( $FirstRow -eq $True ) {
                                    $HTML += "`n<tr bgcolor=""$RowBGColor""><td style=""border-top: 1px solid $BorderColor;border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$($User.GivenName) $($User.Surname)</td><td style=""border-top: 1px solid $BorderColor;border-right: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$($UsersManager.GivenName) $($UsersManager.SurName) ($($UsersManager.samAccountName))</td></tr>"
                                    $FirstRow = $False
                                }
                                Else {
                                    $HTML += "`n<tr bgcolor=""$RowBGColor""><td style=""border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$($User.GivenName) $($User.Surname)</td><td style=""border-right: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$($UsersManager.GivenName) $($UsersManager.SurName) ($($UsersManager.samAccountName))</td></tr>"
                                }
                            }
                        }
                    }
                }
                $HTML += "`n</table>"
            }
            [array]$T2Roles = $AllRoles | Where { $_.samAccountName -like "Role-T2*" }
            If ( $T2Roles.Count -gt 0 ) {
                ForEach ( $T2Role in $T2Roles ) {
                    #[array]$RoleMembers = Get-ADGroupMember $T2Role -Server $LookupDomain
                    [array]$RoleMembers = Get-ADGroupMember $T2Role -Server $LookupDomain | %{Get-ADUser -Identity $_.DistinguishedName -Properties Enabled -Server $LookupDomain |?{ $_.Enabled -eq $True }}
                    If ( $Rolemembers.Count -gt 0 ) {
                        $HTML += "`n<tr><td><br></td></tr>"
                        $HTML += "`n<tr><td><br></td></tr>"
                        $HTML += "`n<table border=""0"" width=""100%"" cellpadding=""5"" cellspacing=""0"">"
                        If ( $DomainInHTML -eq $False ) {
                            $HTML += "`n<tr><td></td></tr>"
                            $HTML += "`n<tr><td colspan=""2""><font size=4><b>Domän: $Domain</b></font></td></tr>"
                            $DomainInHTML = $True
                        }
                        $HTML += "`n<tr><td width=""250px"" ><b>$($T2Role.Name)</b></td><td colspan=2>$($RoleMembers.Count)</td></tr>"
                        $HTML += "`n<tr><td width=""250px"" ><b>Användare<b></td><td width=""350px"" width=""*""><b>Chef</b></td></tr>"
                        $FirstRow = $True
                        ForEach ( $Member in $RoleMembers ) {
                            [array]$User = Get-ADUser -filter "samAccountName -eq ""$($Member.samAccountName)"" -and enabled -eq 'true'" -Property GivenName,Surname,samAccountName,Info -Server $LookupDomain
                            If ( $User.Count -gt 0 ) {
                                Try { $UsersManager = Get-ADUser -filter "samAccountName -eq ""$($User.Info.Substring(9,5))""" -SearchBase $ProdStdUsers -SearchScope OneLevel -Property GivenName,Surname,samAccountName -Server $Prod }
                                Catch {}
                                GetRowColor
                                If ( $FirstRow -eq $True ) {
                                    $HTML += "`n<tr bgcolor=""$RowBGColor""><td style=""border-top: 1px solid $BorderColor;border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$($User.GivenName) $($User.Surname)</td><td style=""border-top: 1px solid $BorderColor;border-right: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$($UsersManager.GivenName) $($UsersManager.SurName) ($($UsersManager.samAccountName))</td></tr>"
                                    $FirstRow = $False
                                }
                                Else {
                                    $HTML += "`n<tr bgcolor=""$RowBGColor""><td style=""border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$($User.GivenName) $($User.Surname)</td><td style=""border-right: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$($UsersManager.GivenName) $($UsersManager.SurName) ($($UsersManager.samAccountName))</td></tr>"
                                }
                            }
                        }
                    }
                }
            }
            $HTML += "`n</table>"
        }
        $HTML += "`n</body></html>"
    }
    $HTML -replace '\n', "`r`n" | out-file "C:\Program Files (x86)\Logs\AD-Delegation - Report-ADDelegation\Temp\AD-Delegation - Dina privilegierade roller - $Manager.html"
    $FirstDomain = $True
}
Write-log "Finished creation of reports"