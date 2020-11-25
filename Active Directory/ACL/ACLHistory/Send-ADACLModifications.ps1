## This scripts queries the database ACLHistory and sends a mail notifications with changes
##
## Author: Fredrik Bergman, 2020-11-20
## Version 1.0.0 - First version //Fredrik Bergman 2020-11-20
##

#region DECLARE SCRIPT DEPENDENCIES
    $ScriptVariables = @{
        "ScriptFolder"            = "C:\PowerShell\TaskScheduler\Get-ADACLModifications"
        "LastMinutes"             = 60
        "MailFrom"                = 'noreply@froxxen.com'
        "MailTo"                  = 'froxxen@froxxen.com'
        "MailSubject"             = 'Recent Active Directory ACL Modifications'
        "SMTPServer"              = 'mail.froxxen.com'
        "SSRSReport"              = 'https://reports.froxxen.com/reports/report/ACLHistory/ACLHistory'
        "ACLHistoryManagement"    = "C:\PowerShell\TaskScheduler\Get-ADACLModifications\Modules\ACLHistoryManagement.psm1"
        "ADRightsModulePath"      = "C:\PowerShell\TaskScheduler\ActiveDirectoryRightsModule\ActiveDirectoryRightsModule.psm1"
        "Colors"                  = @{
                                        "Added"   =  "#3f82b0"
                                        "Changed"  = "#a52869"
                                        "Critical" = "#b8812e"
                                        "Error"    = "#a52869"
                                        "Removed"   = "#db3f28"
                                    }
        "CriticalPermissions"     = @('FullControl','Full Control','All Extended Rights','ExtendedRight ')
    }

    Import-Module $ScriptVariables.ACLHistoryManagement
    Import-Module $ScriptVariables.ADRightsModulePath


function Get-RowColor {
    param (
        [Parameter(Mandatory=$true)]
        [int]$Counter
    )
    if ( $Counter % 2 -eq 0 ) {
        $color = '#ffffff'
    }
    else {
        $color = '#eeeeee'
    }
    $color
}

# CSS for HTML
$Style = @"
<style>
	body {
		font-family: verdana,arial,sans-serif;
		font-size:12px;
	}

	#tmain {
		font-family: verdana,arial,sans-serif;
		font-size:11px;
        text-align:center;
		border-style: hidden;
        width:95%;
    }
	#tmain td {
		border-style: hidden;
		text-align: center;
        padding: 8px;
	}

    #tsum {
        width: 65%;
        border-style: hidden;
        border-width: 1px;
        border-color: #7bd0e0;
        border-top-style: solid;
        text-align:center;
        padding: 0px;
    }
    #tsum td{
        padding: 8px;
        border-style: hidden;
        text-align:center;
    }

    #t01 {
        width: 100%;
        border-style: hidden;
        padding: 0px;
    }
    #t01 td{
        padding: 8px;
        border-style: hidden;
        text-align: left;
        vertical-align: top;
    }
    #t01 tr:nth-child(even) {
        background-color: #eee;
    }
    #t01 tr:nth-child(odd) {
        background-color: #fff;
    }
    #t01 th {
        color: white;
        text-align: left;
        font-weight: bold;
        padding: 8px;
        background-color: #3f82b0;
    }

    #tmods {
        table-layout: auto !important;
    }
    #tmods td{
        background-color: transparent;
        padding: 4px;
    }

    .Critical {
        border-style: solid;
        border-width: 2px;
        border-color: #b8812e;
    }
</style>
"@

# Get all ACL-modifications since...
if ( !$ModifiedACLs ) {
    [array]$ModifiedACLs = Get-ACLHistoryLogs -EndDate $((get-date).AddMinutes(-$($ScriptVariables.LastMinutes)))
}

if ( $ModifiedACLs ) {
    #region Main table
        $HTMLTableForEmail = "$Style`r`n<table id=`"tmain`">"
        $HTMLTableForEmail += "<tr><td><h2>Summary of Access Control List (ACL) Modifications</h2></td></tr>"
        $HTMLTableForEmail += "<tr><td>Report created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</td></tr>"
        if ( $ScriptVariables.SSRSReport -ne '' ) {
            $HTMLTableForEmail += "<tr><td><a href=`"$($ScriptVariables.SSRSReport)`">Link to SSRS report</a></td></tr>"
        }
        #region Summary table
            [int]$TotalModifications = $($ModifiedACLs | Group OpCorrelationID).Count
            [int]$TotalACEAdditions  = @($($ModifiedACLs | Where Operation -eq 'Added' )).Count
            [int]$TotalACERemovals   = @($($ModifiedACLs | Where Operation -eq 'Removed' )).Count
            [int]$TotalCriticals     = @($($ModifiedACLs | where { $_.Access -match "$($ScriptVariables.CriticalPermissions -join '|')" -and $_.Operation -eq 'Added' })).count
            $HTMLTableForEmail += "<tr><td><table align=`"center`" id=`"tsum`"><tr><td><b>Total Modifications:</b></td><td><b>Added ACEs:</b></td><td><b>Removed ACEs</b></td><td><b>Potentially Critical events</b></td></tr><tr><td><font size = `"6`">$($TotalModifications)</font></td><td><font size = `"6`" color=`"#3f82b0`">$TotalACEAdditions</font></td><td><font size=`"6`" color=`"#a50134`">$TotalACERemovals</font></td><td><font size=`"6`" color=`"$($ScriptVariables.Colors.Critical)`">$TotalCriticals</font></td></tr></table></td></tr>"
        #endregion
        #region Top Modifier table
            $HTMLTableForEmail += "<tr><td><h2>Top 5 modifiers</h2></td></tr>"
            $HTMLTableForEmail += "<table id=`"t01`"><th>Modified by</th><th width=`"150px`" style=`"text-align:right;`">Count</th>"
            $Counter = 0
            foreach ( $TopModifier in $ModifiedACLs | Group Modifier | Select -First 5 | Sort-Object Count -Descending) {
                $color = Get-RowColor $Counter
                $HTMLTableForEmail += "<tr style=`"background-color:$($color)`"><td>$($TopModifier.Name)</br><font color=`"grey`">$($TopModifier.Group[0].ModifierSAM)</font></td><td style=`"text-align:right`">$($TopModifier.Count)</td></tr>"
                $Counter++
            }
            $HTMLTableForEmail += "</table></td></tr>"
        #endregion
        #region Modifications table
            $HTMLTableForEmail += "<tr><td align=`"center`"><h2>List of ACL modifications</h2></td></tr>"
            $HTMLTableForEmail += "<tr><td><table id=`"t01`"><th width=`"200px`">Timestamp</th><th width=`"200px`">Modified by</th><th width=`"200px`">Target Object</th><th>Modifications</th></tr></td>"
            foreach ( $ACL in $ModifiedACLs | Group OpCorrelationId ) {
                $Counter++
                $color = Get-RowColor $Counter
                $ACLMeta = $ACL.Group[0]
                $HTMLTableForEmail += "<tr style=`"background-color:$($color)`"><td>$($ACLMeta.Timestamp)</td><td>$($ACLMeta.Modifier)</br><font color=`"grey`">$($ACLMeta.ModifierSAM)</font></td><td><b>$($ACLMeta.TargetType):</b></br>$($ACLMeta.TargetObject)</td><td>"
                foreach ( $ACE in $ACL.Group ) {
                    $textcolor = $ScriptVariables.Colors.$($ACE.Operation)
                    if ( $ACE.Access -match "$($ScriptVariables.CriticalPermissions -join '|')" -and $ACE.Operation -eq 'Added' ) {
                        $CriticalEvent = "class=`"Critical`""
                        $Access = "<font color=`"$($ScriptVariables.Colors.Critical)`"><b>$($ACE.Access)</b></font>"
                    }
                    else {
                        $CriticalEvent = $null
                        $Access = $ACE.Access
                    }
                    $HTMLTableForEmail += "<table id=`"tmods`" $CriticalEvent><tr><td width=`"150px`" align=`"left`"><b>$($ACE.SDDLType)</b></td><td align=`"left`"><font color=`"$textcolor`"><b>$($ACE.Operation)</b></font></td></tr><tr><td><b>Type</b></td><td>$($ACE.Type)</td></tr><tr><td><b>Principal</b></td><td>$($ACE.Principal)</td></tr><tr><td><b>Access</b></td><td>$($Access)</td></tr><tr><td><b>Applies to</b></td><td>$($ACE.AppliesTo)</br></br></td></tr></table>"
                }
                $HTMLTableForEmail += "<font color=`"$($color)`">$($ACL.Group[0].OpCorrelationId)</font>"
            }
        #endregion
        $HTMLTableForEmail += "</td></tr></table></table>"
    #endregion Main table

    #region SEND NOTIFICATION VIA EMAIL
        $mail = New-Object System.Net.Mail.MailMessage -Property @{
            From       = $ScriptVariables.MailFrom
            Subject    = $ScriptVariables.MailSubject
            Body       = $HTMLTableForEmail
            IsBodyHtml = $true
        }
        $mail.To.Add($ScriptVariables.MailTo)
        $SMTPClient = New-Object -TypeName System.Net.Mail.SmtpClient( $ScriptVariables.SMTPServer )
        $SMTPClient.Send( $Mail )
    #endregion
}