Function GetRowColor {
    $global:RowBGColor = "#eeeeee"
    If ( $KeyColumn -ne "" ) {
        If ( $KeyColumnType -eq "Number" ) {
            If ( $Result.$KeyColumn -le $MediumThreshold ) { $global:RowBGColor = "fff0b3"}
            If ( $Result.$KeyColumn -le $MinimumThreshold ) { $global:RowBGColor = "#ffb3b3"}
        }
        If ( $KeyColumnType -eq "Date" ) {
            $Timespan = $(NEW-TIMESPAN –Start $([datetime]"$($Result.$KeyColumn)") –End (GET-DATE)).Days
            If ( $Timespan -gt $MediumThreshold ) { $global:RowBGColor = "fff0b3"}
            If ( $Timespan -gt $MinimumThreshold ) { $global:RowBGColor = "#ffb3b3"}
        }
    }
    If ( $global:OddRow -eq $False ) {
        $global:OddRow = $True
        $global:RowBGColor = "#ffffff"
        If ( $KeyColumn -ne "" ) {
            If ( $KeyColumnType -eq "Number" ) {
                If ( $MediumThreshold -ne "" ) {
                    If ( $Result.$KeyColumn -le $MediumThreshold ) { $global:RowBGColor = "#fffae6" }
                }
                If ( $MinimumThreshold -ne "" ) {
                    If ( $Result.$KeyColumn -le $MinimumThreshold ) { $global:RowBGColor = "#ffe6e6" }
                }
            }
            If ( $KeyColumnType -eq "Date" ) {
                $Timespan = $(NEW-TIMESPAN –Start $([datetime]"$($Result.$KeyColumn)") –End (GET-DATE)).Days
                $Timespan = ((GET-DATE) – $([datetime]"$($Result.$KeyColumn)")).Days
                If ( $MediumThreshold -ne "" ) {
                    If ( $Timespan -gt $MediumThreshold ) { $global:RowBGColor = "#fffae6" }
                }
                If ( $MinimumThreshold -ne "" ) {
                    If ( $Timespan -gt $MinimumThreshold ) { $global:RowBGColor = "#ffe6e6" }
                }
            }
        }
    }
    Else { $global:OddRow = $False }
}

function Invoke-SQL {
    param(
        [string] $dataSource = ".\SQLEXPRESS",
        [string] $database = "DBName",
        [string] $sqlCommand = $(throw "Please specify a query.")
      )
    $connectionString = "Data Source=$dataSource; Integrated Security=SSPI; Initial Catalog=$database"
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    $connection.Close()
    $dataSet.Tables
}

Function CreateTable {
    param(
        [string] $Header,
        [string] $Query,
        [string] $KeyColumn = $Null, 
        [ValidateSet('Number','Date')][string]$KeyColumnType,
        [string] $MediumThreshold,
        [string] $MinimumThreshold,
        [string] $ShowRows = 10
    )
    [array]$Results = Invoke-SQL -dataSource $DBServer -database $DBName -sqlCommand $Query
    If ( $Results.Count -gt 0 ) {
        If ( $ShowRows -ge $($Results.Count) ) { $ShowRowValue = $Results.Count }
        Else { $ShowRowValue = $ShowRows }
        $global:HTML += "`n<font face=""$FontFace""><font size=5><b>$Header</b></font>"
        $global:HTML += "`n<table width=100%><tr>"
        $global:HTML += "<td width=*><font size=2><i>Showing $ShowRowValue of $($Results.Count) matches</i></font></td>"
        If ( $MinimumThreshold -ne "" ) {
            $global:HTML += "<td width=150px align=right><font size=2><i>Min. threshold: $MinimumThreshold</i></font></td>"
        }
        If ( $MediumThreshold -ne "" ) {
            $global:HTML += "<td width=150px align=right><font size=2><i>Med. threshold: $MediumThreshold</i></font></td></tr>"
        }
        $global:HTML += "`n</table>"
        $global:HTML += "`n<table border=""0"" width=""100%"" cellpadding=""6"" cellspacing=""0"">"
        $HostNameColumnCount = 0
        $DomainColumnCount = 0
        $HostNameColumn = $Null
        $DomainColumn = $Null
        ForEach ( $Column in $($Columns.Split(","))) {
            If ( $Column -eq $KeyColumn ) {
                $global:HTML += "`n<td style=""border-bottom: 1px solid $BorderColor""><font size=4><b>$Column</b></font></td>"
            }
            Else {
                $global:HTML += "`n<td style=""border-bottom: 1px solid $BorderColor""><font size=2><b>$Column</b></font></td>"
            }
            If ( $Column -eq "HostName" ) {
                $HostNameColumn = $HostNameColumnCount
            }
            Else {
                $HostNameColumnCount++
            }
            If ( $Column -eq "Domain" ) {
                $DomainColumn = $DomainColumnCount
            }
            Else {
                $DomainColumnCount++
            }
        }
        $global:HTML += "`n</tr>"
        $Counter = 0
        ForEach ( $Result in $Results ) {
            If ( $Counter -eq $ShowRows ) { Continue }
            GetRowColor
            $global:HTML += "`n<tr bgcolor=""$RowBGColor"">"

            $FieldCount = ($Result | Get-Member -MemberType Property).Count
            $global:HTML += "`n"
    
            For ($i=0; $i -lt $FieldCount; $i++) {
                $FieldValue = $($Result.ItemArray[$i])
                
                $Information = $Null
                If ( $HostNameColumn -ne $Null -and $DomainColumn -ne $Null ) {
                    Try {
                        $ServerInfo = Get-ADComputer $($Result.ItemArray[$HostNameColumn]) -Server $($Result.ItemArray[$DomainColumn]) -Properties DNSHostName, DistinguishedName, description | Select DNSHostName,DistinguishedName,description
                        $Information += "<b>Host</b><br>$($ServerInfo.DNSHostName)<br><br>"
                        $Information += "<b>DistinguishedName</b><br>$($ServerInfo.DistinguishedName)<br><br>"
                        $Information += "<b>Description</b><br>$($ServerInfo.description)<br><br>"
                        If ( Test-Connection -ComputerName "$($Result.ItemArray[$HostNameColumn]).$($Result.ItemArray[$DomainColumn])" -Count 1 -Quiet ) {
                            $Information += "<b>Ping-response:</b></i> (when report created)</i><br><font color=""Green"">Yes</font>"
                        }
                        Else {
                            $Information += "<b>Ping-response:</b></i> (when report created)</i><br><font color=""Red"">No</font>"
                        }
                    }
                    Catch {}
                }

                If ( $i -eq 0 ) {
                    If ( $Information -ne $Null ) {
                        $global:HTML += "<td style=""border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;"" class=""CellWithComment""><span class=""CellComment"">$Information</span><font size=2>$FieldValue</font></td>"
                    }
                    Else {
                        $global:HTML += "<td style=""border-left: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;""><font size=2>$FieldValue</font></td>"
                    }
                }
                If ( $i -gt 0 -and $i -lt ($FieldCount-1) ) { $global:HTML += "<td style=""border-bottom: 1px solid $BorderColor;""><font size=2>$FieldValue</font></td>" }
                If ( $i -eq ($FieldCount-1) ) { $global:HTML += "<td style=""border-right: 1px solid $BorderColor;border-bottom: 1px solid $BorderColor;""><font size=2>$FieldValue</font></td>" }
            }
            $global:HTML += "`n</tr>"
            $Counter++
        }
        $global:HTML += "`n</table>"
        $global:HTML += "`n<br><br>"
    }
}

$DBServer = "" # <- Put the server for that has the database here
$DBName = "ClientHealth"
$HTMLFile = "C:\Temp\ConfigMgrClientHealthReport.html"
$FontFace = "Tahoma"
$BorderColor = "gray"

$HTML = ""
$HTML = @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>ConfigMgr Client Health report</title>
</head><body>
<style>

.CellWithComment{
  position:relative;
}

.CellComment{
  display:none;
  position:absolute; 
  z-index:100;
  border:1px;
  background-color:white;
  border-style:solid;
  border-width:1px;
  border-color:black;
  padding:10px;
  color:black;
  font-size:10px;
  left: 100%;
  top: 25%;
  margin-top: -50%;
  margin-left: -50%;
}

.CellWithComment:hover span.CellComment{
  display:block;
}

.CellWithComment:hover {color:gray;
}
</style>
"@

[array]$Results = Invoke-SQL -dataSource $DBServer -database $DBName -sqlCommand "SELECT Hostname FROM Clients WHERE OperatingSystem LIKE '%Server%' ORDER BY Hostname"
If ( $Results.Count -gt 0 ) {
$HTML += "`n<table><tr><td><font size=2 face=""$FontFace"">"
$HTML += "`n<b>ConfigMgr Client Health - Powershell tables</b> (v.0.1)<br>"
$HTML += "`nReport created: $(Get-Date)<br>"
$HTML += "`nTotal servers in database: $($Results.Count)"
$HTML += "`n</font></td></tr></table><br>"
}

$Columns = "Hostname,OperatingSystem,OSDiskFreeSpace,Domain,Timestamp"
CreateTable -Header "Servers with diskspace less than 10GB" -Query "SELECT $Columns FROM Clients WHERE OSDiskFreeSpace <=10 AND OperatingSystem LIKE '%Server%' ORDER BY OSDiskFreeSpace ASC" -KeyColumn "OSDiskFreeSpace" -KeyColumnType "Number" -MinimumThreshold "3.0" -MediumThreshold "6.0" -ShowRows 25

$Columns = "Hostname,OperatingSystem,OSDiskFreeSpace,OSUpdates,RefreshComplianceState,Domain,Timestamp,ClientVersion"
CreateTable -Header "Servers not patched in 60 days query" -Query "SELECT $Columns FROM Clients WHERE OSUpdates <= DATEADD(DAY, -60, GETDATE()) AND OperatingSystem LIKE '%Server%' ORDER BY OSUpdates ASC" -KeyColumn "OSUpdates" -KeyColumnType "Date" -MinimumThreshold "60" -MediumThreshold "30" -ShowRows 25

$Columns = "Hostname,OperatingSystem,OSDiskFreeSpace,Domain,Timestamp"
CreateTable -Header "ConfigMgr Client Health-script inactive for 7 days" -Query "SELECT $Columns FROM Clients WHERE Timestamp <= DATEADD(DAY, -7, GETDATE()) AND OperatingSystem LIKE '%Server%' ORDER BY Timestamp" -KeyColumn "Timestamp" -KeyColumnType "Date" -MinimumThreshold "7" -MediumThreshold "4" -ShowRows 25

$Columns = "Hostname,OperatingSystem,LastBootTime,Domain,Timestamp"
CreateTable -Header "Last boot time is greater than 60 days" -Query "SELECT $Columns FROM Clients WHERE LastBootTime <= DATEADD(DAY, -60, GETDATE()) AND OperatingSystem LIKE '%Server%' ORDER BY LastBootTime" -KeyColumn "LastBootTime" -KeyColumnType "Date" -MinimumThreshold "60" -MediumThreshold "30" -ShowRows 25

$Columns = "Hostname,OperatingSystem,PSVersion,Domain,Timestamp"
CreateTable -Header "Servers with old Powershell version" -Query "SELECT $Columns FROM Clients WHERE PSVersion < 4 AND OperatingSystem LIKE '%Server%' ORDER BY PSVersion" -KeyColumn "PSVersion" -KeyColumnType "Number" -MinimumThreshold 2 -MediumThreshold 3 -ShowRows 25

$HTML += "`n<table><tr><td><br><br></td></tr></table>"
$HTML += "`n</body></html>"
$HTML -replace '\n', "`r`n" | out-file $HTMLFile
Invoke-Item $HTMLFile