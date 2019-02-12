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

Clear-Host
Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
cd a01:

$LogFile = "C:\Temp\Get-CMBoundariesWithoutDP.log"

$BoundaryFilter = "Local Content" # <- Check those Boundaries (filter)
$DHCPServer = "" # <- Put the DHCP server here
$DPs = @("") # <- Put general DPs here
$ReplaceSuffixes = @(".domain.local")
$OverallSiteSystems = @("") # <- Put MPs and general servers here
$FallBackDP = "" # <. Put Fallback DP here
$MissingDHCPScope = @()
$MissingDPs = @()
$HasStandardDP = @()
$HasFallbackDP = @()
$Counter = 1

$BoundaryGroups = $(Get-CMBoundaryGroup -Name "*$BoundaryFilter*" ).Name | Sort
If ( $DHCPScopes -eq $Null ) { $DHCPScopes = Get-DhcpServerv4Scope -ComputerName $DHCPServer | Sort }

Write-Log "Counter;Boundary Group;DPType,DHCPLeases" -WritePrefix No

ForEach ( $BoundaryGroup in $BoundaryGroups ) {
    
    $ScopeName = ""
    $ScopeClients = 0
    $ScopeID = ""

    $ScopeName = Try { $BoundaryGroup.Split("-",4)[3].Trim() } Catch {}
    If ( $DHCPScopes.Name -notcontains $ScopeName ) { $MissingDHCPScope += $ScopeName }
    Else {
        $ScopeID = $($DHCPScopes | Where Name -eq $ScopeName).ScopeId.IPAddressToString
        $ScopeClients = @(Get-DHCPServerv4Lease -ComputerName $DHCPServer -ScopeId $ScopeID | Where HostName -Like '99-*').Count
    }
    [System.Collections.ArrayList]$SiteSystems =Try { $(Get-CMBoundary -BoundaryGroupName $BoundaryGroup).SiteSystems.ToUpper() } Catch { Write-Log "Something happened while checking $BoundaryGroup" -WritePrefix No -LogType ERROR}
    ForEach ( $ReplaceSuffix in $ReplaceSuffixes ) { $SiteSystems = $SiteSystems -replace $ReplaceSuffix,"" }
    $TempString = "$Counter / $($BoundaryGroups.Count);$BoundaryGroup"
    ForEach ( $System in $OverallSiteSystems ) { Try { $SiteSystems.Remove($System) } Catch {}}
    If ( $SiteSystems -contains $FallBackDP  ) { $HasFallbackDP += "$BoundaryGroup" }
    if ( $DPs -notcontains $SiteSystems -and $((@($SiteSystems) -like 'LDP*').Count) -eq 0) {
        $MissingDPs += $BoundaryGroup
        Write-Log "$TempString;Missing;0" -WritePrefix No
    }
    Else {
        If ( $SiteSystems -contains $FallBackDP ) { Write-Log "$TempString;Fallback;$ScopeClients" -WritePrefix No }
        Else { 
            $HasStandardDP += $BoundaryGroup
            Write-Log "$TempString;Standard;$ScopeClients" -WritePrefix No
        } 
    }
    $Counter++
}
Write-Log " " -WritePrefix No
Write-Log "Has standard DP    : $($HasStandardDP.Count)" -WritePrefix No
Write-Log "Has Fallback DP    : $($HasFallbackDP.Count)" -WritePrefix No
Write-Log "Missing DP         : $($MissingDPs.Count)" -WritePrefix No
Write-Log "Missing DHCP Scope : $($MissingDHCPScope.Count)" -WritePrefix No
Write-Log " " -WritePrefix No

#If ( $HasStandardDP.Count -gt 0 ) { Write-Log "List of boundary group(s) with Standard DP:" -WritePrefix No ; Write-Log $($HasStandardDP -Join "`n") -WritePrefix No ; Write-Log " " -WritePrefix No}
If ( $HasFallbackDP.Count -gt 0 ) { Write-Log "List of boundary group(s) with Fallback DP:" -WritePrefix No ; Write-Log $($HasFallbackDP -Join "`n") -WritePrefix No ; Write-Log " " -WritePrefix No}
If ( $MissingDPs.Count -gt 0 ) { Write-Log "List of boundary group(s) missing DP:" -WritePrefix No ; Write-Log $($MissingDPs -Join "`n") -WritePrefix No ; Write-Log " " -WritePrefix No}
If ( $MissingDHCPScope.Count -gt 0 ) { Write-Log "List of missing DHCP-scope(s):" -WritePrefix No ; Write-Log $($MissingDHCPScope -Join "`n") -WritePrefix No ; Write-Log " " -WritePrefix No}
