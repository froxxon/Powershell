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

Function GetGroupManager {
    $global:GroupManager = $Null
    If ( $($AllRoles.Name.IndexOf($Group)) -ne -1 ) {
        Try { 
            $global:GroupManager = " ($($($AllRoles[$($AllRoles.Name.IndexOf($Group))].Info).Substring(9,5)))"
        }
        Catch {
            $global:GroupManager = $Null
        }
    }
}

Function GetGroupDescription {
    If ( $($AllRoles.Name.IndexOf($Group)) -ne -1 ) {
        $global:GroupDescription = $AllRoles[$($AllRoles.Name.IndexOf($Group))].Description
    }
    If ( $Group -like "VMWare*" ) { $global:GroupDescription = "Grants access to VMWare VSphere" }
}

Function NewTableRRowMember ( $GivenName, $SurName ) {
    If ( $Information -ne $Null ) {
        $IfInfo = "class=""CellWithComment""><span class=""CellComment"">$Information</span"
    }
    If ( $FirstRow -eq $True ) {
        If ( $FirstManagerRow -eq $True ) {
            $global:HTML += "`n<tr bgcolor=""$RowBGColor""><td style=""border-top: 1px solid $BorderColor;border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$GivenName $Surname</td><td style=""border-top: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"" $IfInfo>$Group$($GroupManager)</td><td style=""border-top: 1px solid $BorderColor;border-right: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$GroupDescription</td></tr>"
            $global:FirstManagerRow = $False
        }
        Else {
            $global:HTML += "`n<tr bgcolor=""$RowBGColor""><td style=""border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$GivenName $Surname</td><td style=""border-bottom: 1px solid $BorderColor;"" $IfInfo>$Group$($GroupManager)</td><td style=""border-right: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$GroupDescription</td></tr>"
        }
        $global:FirstRow = $False
    }
    Else {
        $global:HTML += "`n<tr bgcolor=""$RowBGColor""><td style=""border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;""></td><td style=""border-bottom: 1px solid $BorderColor;"" $IfInfo>$Group$($GroupManager)</td><td style=""border-right: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"">$GroupDescription</td></tr>"
    }
    $IfInfo = $Null
}

$LogFile = "C:\Program Files (x86)\Logs\AD-Delegation - Report-AllPrivilegedUsers.log"
Write-log "Start creation of report"
$LookupDomains = @("domain1","domain2")
$Prod = "domain1.local"

$AllRoles = @()
ForEach ( $LookupDomain in $LookupDomains ) {
    $DomainDN = $(Get-ADDomain -Server $LookupDomain).Distinguishedname
    $Roles = Get-ADGroup -filter 'Name -like "Role-T0*" -or Name -like "Role-T1*" -or Name -like "Role-T2*" -or Name -like "Task-*"' -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree -Server $LookupDomain -Properties Name, Description, Info | Select Name, Description, Info
    ForEach ( $Role in $Roles ) {
        If ( $AllRoles.Name -notcontains $Role.Name ) { $AllRoles += $Role }
    }
}
$AllRoles = $AllRoles | Sort Name

$AllManagers = @()
ForEach ( $LookupDomain in $LookupDomains ) {
    $DomainDN = $(Get-ADDomain -Server $LookupDomain).Distinguishedname
    $Users = Get-ADUser -filter 'Enabled -eq $True' -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree -Server $LookupDomain -Properties info
    ForEach ( $User in $Users ) {
        $Manager = $User.info
        If ( $Manager -ne $Null ) { $Manager = $Manager.Substring(9,5) }
        If ( $AllManagers -notcontains $Manager ) { $AllManagers += $Manager }
    }
}
$AllManagers = $AllManagers | Sort

$ActiveUsers = 0
$FirstDomain = $True
$BorderColor = "gray"
$FontFace = "Tahoma"

$HTML = @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>AD-Delegation - All AD-delegated privileged users</title>
</head><body>
<style>

.CellWithComment{
  position:relative;
}

.CellComment{
  display:none;
  position:absolute; 
  z-index:100;
  border:1px;
  background-color:white;
  border-style:solid;
  border-width:1px;
  border-color:black;
  padding:10px;
  color:black;
  font-size:10px;
  left: 100%;
  top: 25%;
  margin-top: -50%;
  margin-left: -50%;
  width: 250px;
}

.CellWithComment:hover span.CellComment{
  display:block;
}

.CellWithComment:hover {  color:gray;
}
</style>
<font face=$FontFace size=2>
<table border="0" width="100%" cellpadding="5" cellspacing="15">
<tr><td></td><td style="border: 1px solid $BorderColor;" bgcolor="#c2d4ff" width=50></td><td width=50>Prod</td><td width=50></td><td style="border: 1px solid $BorderColor;" bgcolor="#cbffc2" width=50></td><td width=50>T2</td><td width=50></td><td style="border: 1px solid $BorderColor;" bgcolor="#ffc2c2" width=50></td><td width=50>T1</td><td width=50></td><td style="border: 1px solid $BorderColor;" bgcolor="#fff8c2" width=50></td><td width=50>Utveckling</td><td width=50></td><td style="border: 1px solid $BorderColor;" bgcolor="#e0e0e0" width=50></td><td width=50>Övrigt</td><td></td>
</table>
"@

$AllT0Users = @()
$AllT1Users = @()
$AllT2Users = @()
$HTML += "`n<table border=""0"" width=""100%"" cellpadding=""5"" cellspacing=""0"">"
$HTML += "`n<tr><td><b>Domain</b></td><td><b>T0 accounts</b></td><td><b>T1 accounts</b></td><td><b>T2 accounts</td></tr>"

ForEach ( $LookupDomain in $LookupDomains ) {
    If ( $LookupDomain -eq "domain1" ) { $DomainBGColor = "#c2d4ff" ; $TypeBGColor = "#dbe6ff" ; $OddRowBGColor = "#f5f8ff" }
    If ( $LookupDomain -eq "domain2" ) { $DomainBGColor = "#cbffc2" ; $TypeBGColor = "#dcffd6" ; $OddRowBGColor = "#f6fff5" }

    $DomainDN = $(Get-ADDomain -Server $LookupDomain).Distinguishedname
    $Domain = $(Get-ADDomain -Server $LookupDomain).DNSRoot.ToUpper()
    $AllUsers = $(Get-ADUser -filter 'Enabled -eq $True' -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree -Server $LookupDomain -Properties samAccountName ).samAccountName
    $T0Users = $AllUsers | Where { $_ -like "T0*" }
    $AllT0Users += $T0Users
    $T1Users = $AllUsers | Where { $_ -like "T1*" }
    $AllT1Users += $T1Users
    Try {
        $T2Users = $AllUsers | Where { $_ -like "T2*" }
        $AllT2Users += $T2Users
    }
    Catch { $T2Users = $Null }
    If ( $FirstDomain -eq $True ) {
        $HTML += "`n<tr bgcolor=""$TypeBGColor""><td style=""border-top: 1px solid $BorderColor;border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor"">$Domain</td><td style=""border-top: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor"">$($T0Users.Count)</td><td style=""border-top: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor"">$($T1Users.Count)</td><td style=""border-top: 1px solid $BorderColor;border-right: 1px solid $BorderColor;border-Bottom: 1px solid $BorderColor;"">$($T2Users.Count)</td></tr>"
        $FirstDomain = $False
    }
    Else {
        $HTML += "`n<tr bgcolor=""$TypeBGColor""><td style=""border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor"">$Domain</td><td style=""border-bottom: 1px solid $BorderColor"">$($T0Users.Count)</td><td style=""border-bottom: 1px solid $BorderColor"">$($T1Users.Count)</td><td style=""border-right: 1px solid $BorderColor;border-Bottom: 1px solid $BorderColor;"">$($T2Users.Count)</td></tr>"
    }
}
$HTML += "`n<tr><td><b>Total accounts</b></td><td>$($AllT0Users.Count)</td><td>$($AllT1Users.Count)</td><td>$($AllT2Users.Count)</td></tr>"
$HTML += "`n<tr><td><b>Unique user accounts</b></td><td>$($($AllT0Users | Select-Object -Unique).Count)</td><td>$($($AllT1Users | Select-Object -Unique).Count)</td><td>$($($AllT2Users | Select-Object -Unique).Count)</td></tr>"
$HTML += "`n</table>"

$ProdStdUsers = "OU=StandardUsers,DC=domain,DC=local"

ForEach ( $LookupDomain in $LookupDomains ) {

    $DomainDN = $(Get-ADDomain -Server $LookupDomain).Distinguishedname
    $Domain = $(Get-ADDomain -Server $LookupDomain).DNSRoot.ToUpper()
    If ( $LookupDomain -eq "domain1" ) { $DomainBGColor = "#c2d4ff" ; $TypeBGColor = "#dbe6ff" ; $OddRowBGColor = "#f5f8ff" }
    If ( $LookupDomain -eq "domain2" ) { $DomainBGColor = "#cbffc2" ; $TypeBGColor = "#dcffd6" ; $OddRowBGColor = "#f6fff5" }

    $HTML += "`n<table border=""0"" width=""100%"" cellpadding=""5"" cellspacing=""0"">"
    $HTML += "`n<tr><td><br></td></tr>"
    $HTML += "`n<tr><td colspan=""3""><font size=4><b>Domän: $Domain</b></font></td></tr>"

    ForEach ( $Manager in $AllManagers ) {
        $ManagerInHTML = $False
        If ( $Manager.Length -eq 5 ) {
            $ManagerInfo = Get-ADUser -filter "samAccountName -like ""$Manager""" -SearchBase $ProdStdUsers -Server $Prod -Properties GivenName, Surname, samAccountName
            $AllUsers = Get-ADUser -filter 'Enabled -eq $true' -SearchBase "OU=Admin,$DomainDN" -Property GivenName,Surname,samAccountName,Info,memberof -SearchScope Subtree -Server $LookupDomain | Where { $_.Info -like "*$($Manager)*" } | Sort GivenName,Surname
            [array]$T0Users = $AllUsers | Where { $_.samAccountName -like "T0*" }
            If ( $T0Users.Count -gt 0 ) {
                $HTML += "`n<tr><td><br></td></tr>"
                If ( $ManagerInHTML -eq $False ) {
                    $HTML += "`n<tr><td><b>Chef</b></td><td colspan=2>$($ManagerInfo.GivenName) $($ManagerInfo.Surname) ($Manager)</td></tr>"
                    $ManagerInHTML = $True
                }
                $HTML += "`n<tr><td><b>T0-behörigheter</b></td><td colspan=2>$($T1Users.Count)</td></tr>"
                $HTML += "`n<tr><td width=""250px""><b>Användare<b></td><td width=""350px""><b>Roll (ansvarig)</b></td><td width=""*""><b>Rollbeskrivning</b></td></tr>"
                $FirstRow = $True
                $FirstManagerRow = $True
                ForEach ( $T0User in $T0Users ) {
                    $Groups = $T0User.memberof
                    $FirstRow = $True
                    ForEach ( $Group in $Groups ) {
                        If ( $Group -like "*Role-*" -or $Group -like "*VMWare*" -or $Group -like "*Task-*" ) {
                            $Group = $Group.Substring(3,$($Group.IndexOf(",OU=")-3))
                            GetRowColor
                            GetGroupDescription
                            GetGroupManager
                            $Information = $Null
                            If ( $Group -like "*Role-*" ) {
                                [array]$GroupMemberOf = $(Get-ADPrincipalGroupMembership $Group -Server $LookupDomain -ResourceContextServer $LookupDomain ).Name
                                If ( $GroupMemberOf -gt 0 ) {
                                    $Information += "<b>Group:</b><br>$Group<br><br><b>Member of:</b><br>"
                                    ForEach ( $MemberGroup in $GroupMemberOf ) {
                                        $Information += "$MemberGroup<br>"
                                    }
                                }
                            }
                            NewTableRRowMember -GivenName $T0User.GivenName -SurName $T0User.SurName
                            $GroupDescription = ""
                        }
                    }
                    $FirstRow = $False
                }
            }
            [array]$T1Users = $AllUsers | Where { $_.samAccountName -like "T1*" }
            If ( $T1Users.Count -gt 0 ) {
                $HTML += "`n<tr><td><br></td></tr>"
                If ( $ManagerInHTML -eq $False ) {
                    $HTML += "`n<tr><td><b>Chef</b></td><td colspan=2>$($ManagerInfo.GivenName) $($ManagerInfo.Surname) ($Manager)</td></tr>"
                    $ManagerInHTML = $True
                }
                $HTML += "`n<tr><td><b>Serverbehörigheter</b></td><td colspan=2>$($T1Users.Count)</td></tr>"
                $HTML += "`n<tr><td width=""250px""><b>Användare<b></td><td width=""350px""><b>Roll (ansvarig)</b></td><td width=""*""><b>Rollbeskrivning</b></td></tr>"
                $FirstManagerRow = $True
                ForEach ( $T1User in $T1Users ) {
                    $Groups = $T1User.memberof
                    $FirstRow = $True
                    ForEach ( $Group in $Groups ) {
                        If ( $Group -like "*Role-*" -or $Group -like "*VMWare*" -or $Group -like "*Task-*" ) {
                            $Group = $Group.Substring(3,$($Group.IndexOf(",OU=")-3))
                            GetRowColor
                            GetGroupDescription
                            GetGroupManager
                            $Information = $Null
                            If ( $Group -like "*Role-*" ) {
                                [array]$GroupMemberOf = $(Get-ADPrincipalGroupMembership $Group -Server $LookupDomain -ResourceContextServer $LookupDomain ).Name
                                If ( $GroupMemberOf -gt 0 ) {
                                    $Information += "<b>Group:</b><br>$Group<br><br><b>Member of:</b><br>"
                                    ForEach ( $MemberGroup in $GroupMemberOf ) {
                                        $Information += "$MemberGroup<br>"
                                    }
                                }
                            }
                            NewTableRRowMember -GivenName $T1User.GivenName -SurName $T1User.SurName
                            $GroupDescription = ""
                        }
                    }
                    $FirstRow = $False
                }
            }
            [array]$T2Users = $AllUsers | Where { $_.samAccountName -like "T2*" }
            If ( $T2Users.Count -gt 0 ) {
                $HTML += "`n<tr><td></td></tr>"
                If ( $ManagerInHTML -eq $False ) {
                    $HTML += "`n<tr><td><b>Chef</b></td><td colspan=2>$($ManagerInfo.GivenName) $($ManagerInfo.Surname) ($Manager)</td></tr>"
                    $ManagerInHTML = $True
                }
                $HTML += "`n<tr><td><b>Klientadministratörskonton</b></td><td colspan=2>$($T2Users.Count)</td></tr>"
                $HTML += "`n<tr><td width=""250px""><b>Användare</b></td><td width=""350px""><b>Roll (ansvarig)</b></td><td width=""*""><b>Rollbeskrivning</b></td></tr>"
                $FirstManagerRow = $True
                ForEach ( $T2User in $T2Users ) {
                    $Groups = $T2User.memberof
                    $FirstRow = $True
                    ForEach ( $Group in $Groups ) {
                        If ( $Group -like "*Role-*" -or $Group -like "*VMWare*" -or $Group -like "*Task-*" ) {
                            $Group = $Group.Substring(3,$($Group.IndexOf(",OU=")-3))
                            GetRowColor
                            GetGroupDescription
                            GetGroupManager
                            $Information = $Null
                            If ( $Group -like "*Role-*" ) {
                                [array]$GroupMemberOf = $(Get-ADPrincipalGroupMembership $Group -Server $LookupDomain -ResourceContextServer $LookupDomain ).Name
                                If ( $GroupMemberOf -gt 0 ) {
                                    $Information += "<b>Group:</b><br>$Group<br><br><b>Member of:</b><br>"
                                    ForEach ( $MemberGroup in $GroupMemberOf ) {
                                        $Information += "$MemberGroup<br>"
                                    }
                                }
                            }
                            NewTableRRowMember -GivenName $T2User.GivenName -SurName $T2User.SurName
                            $GroupDescription = ""
                        }
                    }
                    $FirstRow = $False
                }
            }
        }
    }
    $HTML += "`n</table>"
}

$HTML += "`n</body></html>"
$HTML -replace '\n', "`r`n" | out-file "C:\Program Files (x86)\Logs\AD-Delegation - Report-ADDelegation\Temp\AD-Delegation - AllDomains.html"
Write-log "Finished creation of report"