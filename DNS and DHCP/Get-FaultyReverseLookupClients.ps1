Clear-host 
$DNSServer = 'domain.local'
$DNSDomain = ".domain.local."
$OutFile = $false
$OutFilePath = "C:\Scripts\DNS and DHCP"
$Counter = 0
$MatchingRL = @()
$MismatchingRL = @()
$MissingRL = @()
$RZoneFilter = '*.in-addr.arpa'
$FLClients = @()
$RLClients = @{}
$RLZClients = @()
$MultipleRZoneRecords = @()
$InactiveRZoneRecords = @()

write-host " "
write-host "Querying DNS for objects like " -NoNewline
# Edit the next line to match hostnames you would like to match
write-host "client* or server*" -ForegroundColor Yellow
write-host "This might take about a minute to complete..."
if ( $FLClients.Count -eq 0 ) {
    # Edit the end of the next line to match hostnames you would like to match
    $FLClients = Get-DnsServerResourceRecord -ZoneName $DNSServer -ComputerName $DNSServer -RRType A | Select @{Name='IPv4';Expression={$($_.RecordData.IPv4Address.IPAddressToString)}}, Hostname # | Where { $_.Hostname -like 'client*' -or $_.Hostname -like 'server*' }
}
write-host "Number of objects found: " -NoNewline ; write-host $FLClients.Count -ForegroundColor Green
write-host " "
write-host "Comparing objects in Forward and Reverse zones"
write-host "This might take a couple of minutes..."
write-host " "

foreach ( $FLClient in $FLClients ) {
    $RLZoneName = "$($FLClient.IPv4.Split('.')[1]).$($FLClient.IPv4.Split('.')[0]).in-addr.arpa"
    $RLRecord = "$($FLClient.IPv4.Split('.')[3]).$($FLClient.IPv4.Split('.')[2])"
    try {
        $RLClient = $(Get-DnsServerResourceRecord $RLRecord -ZoneName $RLZoneName -ComputerName $DNSServer -RRType Ptr -ErrorAction 1 | select @{Name='IPv4';Expression={"$($FLClient.IPv4.Split('.')[0]).$($FLClient.IPv4.Split('.')[1]).$($_.Hostname.SPlit('.')[1]).$($_.Hostname.SPlit('.')[0])"}}, @{Name='Hostname';Expression={$($_.RecordData.PtrDomainName).TrimEnd($DNSDomain)}})
        if ( $FLClient.Hostname -eq $RLClient.Hostname ) {
            $MatchingRL += $FLClient.Hostname
        }
        else {
            $MismatchingRL += $FLClient.Hostname
        }
    }
    catch {
        $MissingRL += $FClient.Hostname
    }
}

write-host "Gather Reverse zones matching filter: " -NoNewline
write-host $RZoneFilter -ForegroundColor Yellow
$RLZones = $(Get-DnsServerZone -ComputerName $DNSServer | Where ZoneName -like $RZoneFilter).ZoneName
write-host "Reverse zones found: " -NoNewline
write-host "$($RLZones.Count)" -ForegroundColor Green
write-host " "

foreach ( $RLZone in $RLZones ) {
    $Counter++
    write-host "$Counter / $($RLZones.Count) - Get objects in Reverse zone: $RLZone - " -NoNewline
    if ( $RLZone.Split('.')[2] -eq 'in-addr' ) {
        $IPAddress = "$($RLZone.SPlit('.')[1]).$($RLZone.SPlit('.')[0])"
        # Edit the end of the next line to match hostnames you would like to match
        $RLZClients = $(Get-DnsServerResourceRecord -ZoneName $RLZone -ComputerName $DNSServer -RRType Ptr | select @{Name='IPv4';Expression={"$IPAddress.$($_.Hostname.SPlit('.')[1]).$($_.Hostname.SPlit('.')[0])"}}, @{Name='Hostname';Expression={$($_.RecordData.PtrDomainName).TrimEnd($DNSDomain)}}) #| Where { $_.Hostname -like 'client*' -or $_.Hostname -like 'server*' } | Sort IP
    }
    else {
        $IPAddress = "$($RLZone.SPlit('.')[2]).$($RLZone.SPlit('.')[1]).$($RLZone.SPlit('.')[0])"
        # Edit the end of the next line to match hostnames you would like to match
        $RLZClients = $(Get-DnsServerResourceRecord -ZoneName $RLZone -ComputerName $DNSServer -RRType Ptr | select @{Name='IPv4';Expression={"$IPAddress.$($_.Hostname.SPlit('.')[0])"}}, @{Name='Hostname';Expression={$($_.RecordData.PtrDomainName).TrimEnd($DNSDomain)}}) #| Where { $_.Hostname -like 'client*' -or $_.Hostname -like 'server*' } | Sort IP
    }
    write-host $RLZClients.Count -ForegroundColor Green
    foreach ( $RLClient in $RLZClients ) {
        if ( $RLClients.containskey($RLClient.Hostname) ) {
            $RLClients.$($RLClient.Hostname) = "$($RLClients.$($RLClient.Hostname));$($RLClient.IPv4)"
        }
        else {
            $RLClients.add($RLClient.Hostname,$RLClient.IPv4)
        }
    }
}

write-host " "
write-host "Gather objects having multiple Reverse records"
write-host "This might take a couple of minutes..."
foreach ( $FLClient in $FLClients ) {
    try {
        $MultipleRecordCheck = $RLClients.$($FLClient.Hostname).Split(';')
    }
    catch {}
    if ( $MultipleRecordCheck.Count -gt 1 ) {
        foreach ( $Record in $MultipleRecordCheck ) {
            if ( $Record -ne $FLClient.IPv4 ) {
                $Object = New-Object PSObject -Property @{
                    Hostname = $FLClient.Hostname
                    IPv4 = $Record
                }
                $InactiveRZoneRecords += $Object
            }
        }
    }
}

write-host " "
write-host "Matching objects         : " -NoNewline ; write-host $($MatchingRL.Count) -ForegroundColor Green
write-host "Mismatching objects      : " -NoNewline ; write-host $($MismatchingRL.Count) -ForegroundColor Green
write-host "Missing in Reverse zone  : " -NoNewline ; write-host $($MissingRL.Count) -ForegroundColor Green
write-host "Inactive Reverse objects : " -NoNewline ; write-host $($InactiveRZoneRecords.Count) -ForegroundColor Green

if ( $OutFile -eq $true ) {
    $MatchingRL | out-file "$OutFilePath\DNSMatchingObjects.txt"
    $MismatchingRL | out-file "$OutFilePath\DNSMismatchingObjects.txt"
    $MissingRL | out-file "$OutFilePath\DNSMissingInReverseZone.txt"
    $InactiveRZoneRecords | out-file "$OutFilePath\DNSInactiveReverseObjects.txt"
}