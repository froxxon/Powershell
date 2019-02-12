$DC = $(Get-ADDomainController).Name
$DCs = $(Get-ADDomainController -Filter * | Select-Object name ).Name

$DNSRoot = $( Get-ADDomain ).DNSRoot
$LoggedOnToServers = @()
$MaxEvents = 250000

$FilterXML = "<QueryList><Query Id='0' Path='Security'><Select Path='Security'>*[System[Provider[@Name='Microsoft-Windows-Security-Auditing'] and (EventID=4624)] and EventData[Data[@Name='LMPackageName']='NTLM V1'] ]</Select></Query></QueryList>"

cls
Write-host ""
Write-host "Analyzing NTLM V1 sessions connecting to DCs"
Write-host ""

ForEach ( $DC in $DCs ) {
    Write-host "- Analyzing events from $DC"
    $Events = Get-WinEvent –FilterXml $filterXml -ComputerName $DCs[0] -MaxEvents $MaxEvents

    ForEach ( $Event in $Events ) {
        $EventXML = $Null
        [xml]$EventXML= $Event.ToXml()
        ForEach ( $Dataevent in $eventXML.Event.EventData.Data ) {
            If ( $($DataEvent.Name) -eq "WorkstationName" ) {
                $ServerName = "$($DataEvent.'#text').$DNSRoot"
                If ( $LoggedOnToServers -notcontains $ServerName ) {
                    $LoggedOnToServers += $ServerName
                }
            }
        }
    }
}
Write-host ""
Write-Host "NTLM sessions from servers:"
$LoggedOnToServers | Sort
Write-host ""