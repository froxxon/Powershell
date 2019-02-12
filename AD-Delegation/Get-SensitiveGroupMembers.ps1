Clear-Host

Function GetRowColor {
    $global:RowBGColor = $OddRowBGColor
    If ( $global:OddRow -eq $False ) {
        $global:OddRow = $True
        $global:RowBGColor = "#ffffff"
    }
    Else { $global:OddRow = $False }
}

$LookupDomains = @("domain1","domain2")
$SensitiveGroups = @("Domain Admins","Enterprise Admins","Schema Admins","Role-T0-Infrastructure")

$Users = @()
$HTML = @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Sensitive groups in all AD-domains</title>
</head><body>
"@

ForEach ( $LookupDomain in $LookupDomains ) {

    If ( $LookupDomain -eq "domain1" ) { $DomainBGColor = "#c2d4ff" ; $TypeBGColor = "#dbe6ff" ; $OddRowBGColor = "#f5f8ff" }
    If ( $LookupDomain -eq "domain2" ) { $DomainBGColor = "#cbffc2" ; $TypeBGColor = "#dcffd6" ; $OddRowBGColor = "#f6fff5" }

    $HTML += "`n<table cellpadding=5 cellspacing=0>"
    $HTML += "`n<tr><td colspan=3><b>Domain: $($LookupDomain.ToUpper())</b></td></tr>"
    $HTML += "`n<tr><td width=""200px""><b>User</b></td><td width=""350px""><b>Group</b></td><td width=""200px""><b>Enabled</b></td></tr>"
    ForEach ( $SensitiveGroup in $SensitiveGroups ) {
        $Users = Get-ADGroupMember $SensitiveGroup -Server $LookupDomain | Sort samAccountName | Add-Member @{ADGroup="$SensitiveGroup"} -PassThru -Force
        ForEach ( $User in $Users ) {
            If ( $SensitiveGroups -notcontains $User.name ) {
                $Enabled = $(Get-ADUser $User.distinguishedName -Properties Enabled -Server $LookupDomain -ErrorAction SilentlyContinue).Enabled
                $EnabledColor = "Green"
                If ( $Enabled -ne "True" ) { $Enabled = "False" ; $EnabledColor = "Red" }
                GetRowColor
                $HTML += "`n<tr bgcolor=""$RowBGColor""><td>$($User.samAccountName)</td><td>$($User.ADGroup)</td><td><font color=""$EnabledColor"">$($Enabled)</font></td></tr>"
            }
        }
    }
    $HTML += "`n</table>"
    $HTML += "`n<br><br>"
}
$HTML += "`n</body></html>"
$HTML | Out-File "C:\Temp\SensitiveGroupMembers.html"