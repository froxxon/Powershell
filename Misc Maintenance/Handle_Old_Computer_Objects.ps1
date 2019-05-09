# Change to your environments site code for SCCM
$SCCMSiteCode = "<ENTER SITE CODE>"
# Change to path where logfiles should be saved
$LogFile = "<ENTER PATH>\Handle_Old_Computer_Objects.log"
# Imports the module from the default path when the SCCM AdminConsole is installed
Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
cd "$($SCCMSiteCode):"

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
    if ( $WritePrefix -eq "YES" ) {
        $LogEntry = "$LogType $CurrentDateTime - $Message"
    }
    else {
        $LogEntry = "$Message"
    }
    Add-Content -Value $LogEntry -Path $LogFile -Encoding UTF8
    Write-Verbose $LogEntry
}

$NotifyDate = $(Get-Date).AddDays(-90)
$WhenChangedDate = $(Get-Date).AddDays(-104)
$AfterChangedDate = $(Get-Date).AddDays(-284)
# Change to where your clients are located in Active Directory
$SearchBase = 'OU=Clients,DC=domain,DC=local'
[array]$NotifyComputerOwners = Get-ADComputer -filter 'enabled -eq $true' -SearchBase $SearchBase -SearchScope Subtree -Properties WhenChanged | Sort WhenChanged
[array]$DisablingComputers = Get-ADComputer -filter 'WhenChanged -lt $WhenChangedDate -and enabled -eq $true' -SearchBase $SearchBase -SearchScope Subtree -Properties WhenChanged | Sort WhenChanged
[array]$DeleteComputers = Get-ADComputer -filter 'WhenChanged -lt $AfterChangedDate -and enabled -eq $false' -SearchBase $SearchBase -SearchScope Subtree -Properties WhenChanged | Sort WhenChanged

# Disable the computer objects in Active Directory and and deletes from SCCM that haven't been used for at least $WhenChangedDate days
if ( $DisablingComputers.Count -gt 0 ) {
    foreach ( $Computer in $DisablingComputers ) {
        try {
            Remove-CMDevice -DeviceName $Computer.Name -Force
            Write-Log "Successfully removed $($Computer.Name) in SCCM"
        }
        catch {
            Write-Log "Failed to remove $($Computer.Name) in SCCM" -LogType ERROR
        }
        try {
            Disable-ADAccount $Computer.DistinguishedName
            Write-Log "Successfully disabled $($Computer.Name) in AD"
        }
        catch {
            Write-Log "Failed to disable $($Computer.Name) in AD" -LogType ERROR
        }
    }
}

# Change to where your user accounts are located to be able to retrieve the mail attribute
$StandardUsers = Get-ADUser -Filter * -SearchBase "OU=StandardUsers,DC=domain,DC=local" -SearchScope OneLevel -Properties Mail, msDS-PrimaryComputer
$MailBody = @"
Hello!

Your computer is about to be disabled within 14 days because it haven't been used for about three months.

Contact servicedesk at <NUMBER or whatever> to enable the computer if necessary.

Best regards
<SOMETHING, SOMEONE, SOMEWHERE>
"@

$SentList = @()
# Creates a list of mails already sent and won't send to those again the next time this task runs
$AlreadySent = Get-Content 'C:\Program Files\ScheduledTasks\Handle_Old_Computer_Objects\Templist'
Remove-Item 'C:\Program Files\ScheduledTasks\Handle_Old_Computer_Objects\Templist' -Force

# Deletes the computer object in Active Directory after being disabled for 180 days
If ( $DeleteComputers.Count -gt 0 ) {
   foreach ( $Computer in $DeleteComputers ) {
        try {
            Remove-ADObject $Computer.DistinguishedName -Recursive -Confirm:$False
            Write-Log "Successfully deletd $($Computer.Name) in AD"
        }
        catch {
            Write-Log "Failed to delete $($Computer.Name) in AD" -LogType ERROR
        }
    }
}

# Sends a mail to people with computers that are about to be disabled, if such a person exists
foreach ( $Computer in $NotifyComputerOwners ) {
    if ( $(New-Timespan –Start $NotifyDate –End $($Computer.WhenChanged)).Days -eq 0 ) {
        [array]$MailTo = $($StandardUsers | Where msDS-PrimaryComputer -match $Computer.Name).Mail
        if ( $MailTo.Count -gt 0 ) {
            foreach ( $MailTos in $MailTo ) {
                # Change to your organizations UPN
                if ( $MailTos -like '*@domain.local' ) {
                    $MailSubject = "Your computer $($Computer.Name) will be disabled!"
                    try {
                        If ( $AlreadySent -notcontains $MailTos ) {
                            #Send-MailMessage -Body $MailBody -From "noreply@arbetsformedlingen.se" -Encoding UTF8 -SmtpServer 'ismtp.wp.ams.se' -To $MailTos -Subject $MailSubject
                            Write-Log "Successfully sent notification by mail to owner of $($Computer.Name)"
                            $SentList += $MailTos
                        }
                    }
                    catch {
                        Write-Log "Failed to send notification by mail to owner of $($Computer.Name)" -LogType ERROR
                    }
                }
            }
        }
    }
}
$SentList | Out-file 'C:\Program Files\ScheduledTasks\Handle_Old_Computer_Objects\Templist'