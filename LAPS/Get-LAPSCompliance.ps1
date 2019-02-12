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
$LogFile = "C:\Temp\LAPSCompliance.log"
$LookupDomains = @("domain1.local","domain2.local")
$MaxPasswordAge = 30

ForEach ( $LookupDomain in $LookupDomains ) {
    $DomainDN = $(Get-ADDomain -Server $LookupDomain).DistinguishedName
    $Servers = Get-ADComputer -filter "samAccountName -like ""*W7*"" -or samaccountName -like ""W0*"" -or samAccountName -like ""33-*"" -or samAccountName -like ""6*-*""" -Searchbase "OU=Servers,OU=Domain Computers,$DomainDN" -SearchScope Subtree -Properties Name,ms-Mcs-AdmPwd,ms-Mcs-AdmPwdExpirationTime -Server $LookupDomain | Select Name,ms-Mcs-AdmPwd,ms-Mcs-AdmPwdExpirationTime
    Write-Log $LookupDomain -WritePrefix No -Verbose
    Write-Log "Server`tPing`tPW Last set (days)" -WritePrefix No -Verbose
    ForEach ( $Server in $Servers ) {
        $ExpireInDays = $(NEW-TIMESPAN –Start $(Get-Date) –End $([DateTime]::FromFileTime($Server.'ms-Mcs-AdmPwdExpirationTime')).tostring("yyyy-MM-dd")).Days
        If ( $ExpireInDays -lt -$($MaxPasswordAge) ) {
            $Ping = $(Test-Connection "$($Server.Name).$LookupDomain" -Count 1 -Quiet)
            If ( $ExpireInDays -eq -152468 ) {
                Write-Log "$($Server.Name)`t$Ping`tNever" -WritePrefix No -Verbose
            }
            Else {
                Write-Log "$($Server.Name)`t$Ping`t$($ExpireInDays*-1)" -WritePrefix No -Verbose
            }
        }
    }
    Write-Log " " -WritePrefix No -Verbose
}