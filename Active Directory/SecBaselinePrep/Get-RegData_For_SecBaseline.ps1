$content = get-content C:\temp\SecBaselinesToCompare.csv | convertfrom-csv -Delimiter ';' | where RegPath -ne $null
$ServerOU = "<OU where servers belongs>"
[array]$servers = get-adcomputer -ldapfilter '(name=*)' -Properties Name, distinguishedName, Description, OperatingSystem -SearchBase $ServerOU -SearchScope Subtree | where { $_.operatingSystem -like '*Windows*'}
$OutFile = "C:\Temp\MemberServers-RegistrySummary.csv"
$failedsessions = 0
$successessions = 0
$counter = 1
$objects = @()
foreach ( $server in $servers ) {
    $Hostname = $server.Name
    write-host "Processing $Counter / $($Servers.Count) - $Hostname" -NoNewline
    try {
        $Session = New-PSSession -ComputerName $hostname -ErrorAction SilentlyContinue
        $localobj = $null
        $localobj = Invoke-Command -Session $Session -ArgumentList (,$content) -ScriptBlock {
            param ( [array]$content )
            $remoteobjects = @()
            foreach ( $item in $content | where RegPath -ne $null ) {
                try {
                    $data = $(Get-ItemProperty $item.RegPath -Name $item.RegValue -ErrorAction SilentlyContinue).$($item.RegValue)
                    if ( $item.RegData -ne $data ) { $Status = 'Different' }
                    if ( $item.RegData -eq $data ) { $Status = 'Match' }
                    $props = @{
                        DisplayName = $item.DisplayName
                        RegPath     = $item.RegPath
                        RegValue    = $item.RegValue
                        RegData     = $Data
                        Hostname    = $env:ComputerName
                        Status      = $Status
                    }
                    $remoteobj = new-object psobject -Property $props
                    $remoteobjects += $remoteobj
                }
                catch {}
            }
            return $remoteobjects
        }
        if ( $localobj ) {
            $objects += $localobj
        }
        write-host " - " -NoNewline
        write-host "succeeded" -ForegroundColor Green
        $successessions++
    }
    catch {
        write-host " - " -NoNewline
        write-host "failed" -ForegroundColor Red
        $failedsessions++
    }
    finally {
        if ( $Session ) {
            Remove-PSSession $Session -ErrorAction SilentlyContinue
        }
    }
    $Counter++
}
# Output the result to CSV-file
$objects | select HostName, DisplayName, Status, RegData, RegValue, RegPath | convertto-csv -Delimiter ';' | % {$_ -replace '"',''} | out-file $outFile -Encoding utf8

# Show compliance per DisplayName
$objects | Group-Object DisplayName | 
    Select  @{Name="Display";Expression={$_.Name}},
            @{Name="Match";Expression={ ($_.Group | Where {$_.Status -match "Match"}).Count }},
            @{Name="Diff";Expression={ ($_.Group | Where {$_.Status -match "Different"}).Count }},
            @{Name="Percentage";Expression={ "$((($_.Group | Where {$_.Status -match "Match"}).Count / ($_.Group).Count)*100)%" }} | sort Percentage | ft -AutoSize

# Show summary
write-output ""
"Successful sessions : $successessions"
"Failed sessions     : $failedsessions"
"Total               : $($objects.count)"
"Matches             : $(($objects | where status -eq 'Match').count)"