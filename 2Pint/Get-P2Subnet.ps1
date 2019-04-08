clear-host
Import-Module 2PintFunctions -Force

Get-StiflerSubnet *U* -Server StiflerServer.domain.local -Property LocationName, ActiveClients, AverageBandwidth, SubnetID | Where ActiveClients -gt 0 | Select LocationName, SubnetID, ActiveClients, AverageBandwidth, RedLeader | Sort LocationName | Format-Table -AutoSize

$(Get-StiflerSubnet *U* -Server StiflerServer.domain.local).LocationName | Sort

Get-StiflerSubnet MySubnet -Server StiflerServer.domain.local -ShowRedLeader

Get-StiflerSubnet -SubnetID 192.168.20.0 -Server StiflerServer.domain.local -ShowRedLeader

get-stiflerclient -Client CLI- -Server StiflerServer.domain.local