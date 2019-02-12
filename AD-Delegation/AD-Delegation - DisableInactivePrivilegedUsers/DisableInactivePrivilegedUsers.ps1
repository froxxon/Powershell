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

$ProdServer = "domain1.local"
$LookupDomains = @("domain1","domain2")
$ProdStdUsers = "OU=StandardUsers,DC=domain1,DC=local"

$LogFile = "C:\Program Files (x86)\AMSPgm\Logs\AD-Delegation - DisableInactiveProdUsers.log"
$DisabledStandardUsers = $(Get-ADUser -filter 'Enabled -eq $False' -SearchBase $ProdStdUsers | Sort ).samAccountName

ForEach ( $LookupDomain in $LookupDomains ) {
    $DomainDN = $(Get-ADDomain -Server $LookupDomain).DistinguishedName
    $PrivilegedUsers = $(Get-ADUser -filter 'Enabled -eq $True' -SearchBase "OU=Admin,$DomainDN" -Server $LookupDomain | Sort ).samAccountName
    #$DAs = $(Get-ADGroupMember "Domain Admins" -Recursive -Server $LookupDomain).samAccountName
    ForEach ( $User in $PrivilegedUsers ) {
        If ( $User -notlike "l0*" ) {
        #If ( $DAs -notcontains $User ) {
            If ( $DisabledStandardUsers -contains $($User.SubString(2,5)) ) {
                Try {
                    Disable-ADAccount $User -Server $LookupDomain
                    write-Log "$DomainDN\$User disabled because standard account is disabled in Prod" -LogType INFO
                }
                Catch {
                    write-Log "$DomainDN\$User disabled unsuccessfully (1)" -LogType ERROR
                }
            }
        }
    }
    $InactiveUsers = $(Get-ADUser -filter "LastLogonTimestamp -lt $((Get-Date).AddDays(-194).ToFileTimeUTC()) -and Enabled -eq 'True'" -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree -Server $LookupDomain).samAccountName
    ForEach ( $User in $InactiveUsers ) {
        If ( $User -notlike "T0*" ) {
            Try {
                Disable-ADAccount $User -Server $LookupDomain
                write-Log "Disabled $DomainDN\$User due to inactivity for 194 days" -LogType INFO
            }
            Catch {
                write-Log "$DomainDN\$User disabled unsuccessfully (2)" -LogType ERROR
            }
        }
    }
}
