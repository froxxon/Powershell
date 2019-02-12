$DomainDN = $(Get-ADDomain).DistinguishedName
$Servers = Get-ADComputer -filter * -SearchBase "OU=Servers,$DomainDN" -SearchScope Subtree
Write-host "Found $($Servers.Count) servers"
$TotalCount = $Servers.Count
$Counter = 1
$ServerList = @()
$ServerList += "Server`tStartHour`tLastHour"
ForEach ( $Server in $Servers ) {
    Write-host "Checking $Counter \ $TotalCount"
    $Count 
    $MW = $(Get-ADPrincipalGroupMembership $Server ).Name | Where { $_ -like "*Maintenance*" } | sort
    If ( $MW -notlike "*Maintenance Excluded*" ) {
        $StartHour = $MW[0] -replace $($MW[0].Substring(0,$($MW[0].IndexOf("kl "))+3)),""
        $StartHour = $StartHour -replace $($StartHour.Substring($Starthour.IndexOf("-"),6)),""
        $LastHour = $MW[-1] -replace $($MW[-1].Substring(0,$($MW[-1].IndexOf("-"))+1)),""
        $ServerList += "$($Server.Name)`t$StartHour`t$LastHour"
    }
    $Counter++
}

$ServerList > c:\temp\Servers_MW_WP.log

$ServerList -replace "`t",";"