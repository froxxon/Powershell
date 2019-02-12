clear-host
Import-Module 2PintFunctions -Force
write-host $(Get-Date)

Get-StiflerSubnet -Server w002142 -Property LocationName, ActiveClients, AverageBandwidth, SubnetID |
    Where ActiveClients -gt 0 |
    Select LocationName, SubnetID, ActiveClients, AverageBandwidth, RedLeader, BlueLeader |
    Sort AverageBandwidth, LocationName -Descending |
    Format-Table -AutoSize