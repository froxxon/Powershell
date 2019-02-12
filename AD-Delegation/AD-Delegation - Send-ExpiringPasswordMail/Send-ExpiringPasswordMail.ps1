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

$LogFile = "C:\Program Files (x86)\AMSPgm\Logs\AD-Delegation - Report Expiring Password.log"

$LookupDomains = @("domain1","domain2")
$Users = @()
$UserProperties = @{}
$ProdServer = "domain1.local"

ForEach ( $LookupDomain in $LookupDomains ) {
    $DomainName = $($( Get-ADDomain -Server $LookupDomain).Name).ToUpper()
    $DomainDN = $( Get-ADDomain -Server $LookupDomain).DistinguishedName

    $ExpiringPWUsers = Get-ADUser -Filter "name -like ""t*adm"" -and Enabled -eq 'true'" -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree –Properties “samAccountName”, “msDS-UserPasswordExpiryTimeComputed” -Server $LookupDomain | Select-Object -Property “samAccountName”,@{Name=“ExpiryDate”;Expression={[datetime]::FromFileTime($_.“msDS-UserPasswordExpiryTimeComputed”)}}
    $Today = (get-date)
    ForEach ( $User in $ExpiringPWUsers ) {
        If ( $User.ExpiryDate -ne $Null ) {
            $DaysToExpire = (New-TimeSpan -Start $Today -End ($User.ExpiryDate)).Days
            If (($DaysToExpire -eq 3) -or ($DaysToExpire -eq 10) ) {
                $UserProperties.samAccountName = $User.samAccountName
                $UserProperties.shortName = $($User.samAccountName).Substring(2,5)
                Try {
                    $MailExists = $($($Users | Where { $_.shortName -like $UserProperties.shortName } | Select MailAddress)[0]).MailAddress
                }
                Catch { $MailExists = $Null }
                If ( $MailExists -eq $Null ) {
                    $UserAttributes = Get-ADUser $($User.samAccountName).Substring(2,5) -properties mail, givenName -Server $ProdServer | Select mail, givenName
                    $UserProperties.MailAddress = $UserAttributes.mail
                    $UserProperties.givenName = $UserAttributes.givenName
                    $UserProperties.DaysToExpire = $DaysToExpire
                    $UserProperties.Domain = $DomainName
                }
                Else {
                    $UserProperties.MailAddress = $($($Users | Where { $_.shortName -like $UserProperties.shortName } | Select MailAddress)[0]).MailAddress
                    $UserProperties.givenName = $($($Users | Where { $_.shortName -like $UserProperties.shortName } | Select givenName)[0]).givenName
                    $UserProperties.DaysToExpire = $DaysToExpire
                    $UserProperties.Domain = $DomainName
                }
                $Users += $(New-Object PSobject -Property $UserProperties)
            }
        }
    }
}

ForEach ( $User in $($Users | where { $_.DaysToExpire -eq 3 -or $_.DaysToExpire -eq 10 } ) ) {
        $HowToChange = "Change password by logging into a machine and press Ctrl+Alt+Delete (End if remote) and choose ""Change password...""."
    }

    $MailBody =""
    
    Try {
        Send-MailMessage -Encoding utf8 -Priority High -Body $MailBody -To $User.MailAddress -from "mail@domain1.local" -SmtpServer "smtp.domain1.local" -subject "One of your passwords are about to expire."
        Write-log "Successfully sent mail to $($User.MailAddress) that the password for $($User.Domain)\$($User.samAccountName) will expire in $($UserProperties.DaysToExpire) days"
    }
    Catch {
        Write-Log "Failed to send mail to $($User.MailAddress)  that the password for $($User.Domain)\$($User.samAccountName) will expire in $($UserProperties.DaysToExpire) days" -LogType ERROR
    }
}