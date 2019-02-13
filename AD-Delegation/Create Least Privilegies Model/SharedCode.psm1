Function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string]$Message,
        [Parameter(Position=1)]
        [ValidateSet('INFO','WARN','ERROR')][string]$LogType = 'INFO'
    )
    $CurrentDateTime = Get-Date -format "yyyy-MM-dd HH:mm"
    if($Message -eq $null){ $Message = "" }
    $LogEntry = "$LogType $CurrentDateTime - $Message"
    Add-Content -Value $LogEntry -Path $LogFile -Encoding UTF8
    Write-Verbose $LogEntry
}

$global:Domain = $( Get-ADDomain ).DNSRoot # domain.domain.com
$global:DomainName = $( Get-ADDomain ).Name # domain
$global:DomainDN = $( Get-ADDomain ).DistinguishedName # DC=domain,DC=domain,DC=com