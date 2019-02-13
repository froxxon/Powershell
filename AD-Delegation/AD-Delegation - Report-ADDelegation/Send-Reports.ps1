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

$LogFile = "C:\Program Files (x86)\Logs\AD-Delegation - Send-AD-Delegation-reports.log"
$ReportSource = "C:\Program Files (x86)\Logs\AD-Delegation - Report-ADDelegation\Temp"
$Reports = $(Get-Childitem $ReportSource).Name.Replace(".html","")

ForEach ( $Report in $Reports ) {
    $Manager = $Null
    $MailAddress = $Null
    If ( $Report -notlike "*AllDomains" ) {
        $Manager = $Report.Substring($($Report.Length)-5)
        Try {
            $MailAddress = $(Get-ADUser $Manager -Properties mail).mail
        }
        Catch {
        }
    }
    If ( $Report -like "*AllDomains" ) { $MailAddress = "security@domain1.local" }  
    If ( $Report -like "*AllDomains" ) {
        $Type = "summary"
        $Subject = "AD-Delegation - Summary of privileged accounts"
        $MailBody = @"
Hi!
"@
    }
    If ( $Report -like "*Your employed privileged users*" ) {
        $Type = "users"
        $Subject = "AD-Delegation - Your employed privileged users"
        $MailBody = @"
Hi!
"@
    }
    If ( $Report -like "*Your privileged roles*" ) {
        $Type = "roles"
        $Subject = "AD-Delegation - Your privileged roles"
        $MailBody = @"
Hi!
"@
    }
    If ( $MailAddress -ne $Null ) {
            Try {
                Send-MailMessage -Encoding utf8 -Priority High -Body $MailBody -To $MailAddress -from "noreply@domain1.local" -SmtpServer "smtp.domain1.local" -subject $Subject -Attachments "$ReportSource\$($Report).html"
                sleep -Seconds 10
                Write-Log "Sent $Type report to $MailAddress"
                Remove-Item "$ReportSource\$($Report).html"
            }
            Catch {
                Write-Log "Failed to send report to $MailAddress"
            }
        #}
    }
}