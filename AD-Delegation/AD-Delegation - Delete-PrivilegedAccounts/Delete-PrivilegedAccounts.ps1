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

$ProdServer = "domain1"
$LookupDomains = @("domain1","domain2")
$ProdStdUsers = "OU=StandardUsers,DC=domain1,DC=local"

$LogFile = "C:\Program Files (x86)\AMSPgm\Logs\AD-Delegation - Delete-PrivilegedAccounts.log"
Try {
    $ProdUsers = $(Get-ADUser -filter * -SearchBase $ProdStdUsers -SearchScope OneLevel -Server $ProdServer).samAccountName
    If ( $ProdUsers.Count -gt 14000 ) {
        ForEach ( $LookupDomain in $LookupDomains ) {
            Write-host "Checking domain: $LookupDomain"
            $Domain = $(Get-ADDomain -Server $LookupDomain).Name.ToUpper()
            $DomainDN = $(Get-ADDomain -Server $LookupDomain).DistinguishedName
            $PrivilegedUsers = $(Get-ADUser -filter 'Enabled -eq $False' -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree -Server $LookupDomain).samAccountName | Sort samAccountName
            ForEach ( $User in $PrivilegedUsers ) {
                If ( $User -notlike "Tl0*") {
                    If ( $ProdUsers -notcontains $($User.Substring(2,5))) {
                        Try {
                            Remove-ADUser $User -Server $LookupDomain -Confirm:$false
                            Write-Log "Removed user: $Domain\$User" -LogType INFO
                        }
                        Catch {
                            Write-Log "Failed to remove user: $Domain\$User" -LogType ERROR
                        }
                    }
                }
            }
        }
    }
}
Catch {}