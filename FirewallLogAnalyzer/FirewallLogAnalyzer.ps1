$Computer = "TestClient"
$LogFile = ".\FirewallLogAnalyzer_Results_$Computer.csv"
$Headers = "Date", "Time", "Action", "Protocol", "SrcIP", "DstIP", "SrcPort", "DstPort", "Size", "TCPFlags", "TCPSyn", "TCPAck", "TCPWin", "ICMPType", "ICMPCode", "Info", "Path"
$FileContent = Get-Content ".\pfirewall.log" | ConvertFrom-Csv -Delim ' ' -Header $Headers

$List = @()
$SrcHostNameList = @()
$SrcHostNameList += $Computer
$DstHostNameList = @()
$DstHostNameList += $Computer
$SrcHostIPList = @()
$SrcHostIPList += "127.0.0.1"
$DstHostIPList = @()
$DstHostIPList += "127.0.0.1"
$DstHostTypeList = @()
$DstHostTypeList += "Localhost"

$Counter = 0
$UniqueCounter = 0

ForEach ( $Line in $FileContent ) {
    $Counter++
    Write-Progress -Activity "Analyzing Firewall-log" -Status "Analyzing row: $Counter of $($FileContent.Count). Unique rules found: $UniqueCounter" -percentComplete ($Counter / $FileContent.Count * 100)

    If ( $Line.DstIP -Like "*:*" ) { Continue }
    
    If ( $SrcHostIPList -NotContains $Line.SrcIP ) {
        Try { $SrcHostName = $([System.Net.Dns]::gethostentry($Line.SrcIP)).Hostname }
        Catch { $SrcHostName = "Unknown" }
        $SrcHostIPList += $Line.SrcIP
        $SrcHostNameList += $SrcHostName
    }   
    Else { $SrcHostName = $SrcHostNameList[$SrcHostIPList.IndexOf($Line.SrcIP)] }

    If ( $DstHostIPList -NotContains $Line.DstIP ) {
        Try { $DstHostName = $([System.Net.Dns]::gethostentry($Line.DstIP)).Hostname }
        Catch { $DstHostName = "Unknown" }
        $DstHostIPList += $Line.DstIP
        $DstHostNameList += $DstHostName

        If ( $DstHostName -Like "W*" ) {
            $DstHostNameShort = $DstHostName.Substring(0,$DstHostName.IndexOf("."))
            Try {
                $OU = $($(Get-ADComputer $DstHostNameShort).DistinguishedName -Replace "CN=$DstHostNameShort,OU=","")
                $OU = $OU.Substring(0,$OU.IndexOf(","))
                $DstHostTypeList += $OU
            }
            Catch {
                $DstHostTypeList += ""
            }
        }
        Else {
            If ( $DstHostName -Like "FILE*" ) {
                $DstHostTypeList += "CFS"
            }
            Else {
                $DstHostTypeList += ""
            }
        }
    }    
    Else { $DstHostName = $DstHostNameList[$DstHostIPList.IndexOf($Line.DstIP)] }

#region Destinationports
    $PortType = ""
    If ($Line.'DstPort' -eq "20" -Or $Line.'DstPort' -eq "21") { $PortType = "FTP" }
    If ($Line.'DstPort' -eq "22") { $PortType = "SSH" }
    If ($Line.'DstPort' -eq "23") { $PortType = "Telnet" }
    If ($Line.'DstPort' -eq "25") { $PortType = "SMTP" }
    If ($Line.'DstPort' -eq 53 -And $Line.'Protocol' -eq "TCP" ) { $PortType = "DNS Zone transfer" }
    If ($Line.'DstPort' -eq 53 -And $Line.'Protocol' -eq "UDP" ) { $PortType = "DNS Name mapping" }
    If ($Line.'DstPort' -eq "67" -Or $Line.'DstPort' -eq "68") { $PortType = "DHCP" }
    If ($Line.'DstPort' -eq "69") { $PortType = "TFTP" }
    If ($Line.'DstPort' -eq "80") { $PortType = "HTTP" }
    If ($Line.'DstPort' -eq "88") { $PortType = "Kerberos" }
    If ($Line.'DstPort' -eq "110") { $PortType = "POP3" }
    If ($Line.'DstPort' -eq "123") { $PortType = "NTP" }
    If ($Line.'DstPort' -eq "135") { $PortType = "RPC" }
    If ($Line.'DstPort' -eq "137" -Or $Line.'DstPort' -eq "138" -Or $Line.'DstPort' -eq "139") { $PortType = "NetBIOS" }
    If ($Line.'DstPort' -eq "143") { $PortType = "IMAP" }
    If ($Line.'DstPort' -eq "161" -Or $Line.'DstPort' -eq "162") { $PortType = "SNMP" }
    If ($Line.'DstPort' -eq "179") { $PortType = "BGP" }
    If ($Line.'DstPort' -eq "389") { $PortType = "LDAP" }
    If ($Line.'DstPort' -eq "443") { $PortType = "HTTPS" }
    If ($Line.'DstPort' -eq "464") { $PortType = "Kerberos (Change/Set PW)" }
    If ($Line.'DstPort' -eq "445") { $PortType = "SMB" }
    If ($Line.'DstPort' -eq "636") { $PortType = "LDAPS" }
    If ($Line.'DstPort' -eq "989" -Or $Line.'DstPort' -eq "990") { $PortType = "FTPS" }
    If ($Line.'DstPort' -eq "1688") { $PortType = "KMS" }
    If ($Line.'DstPort' -eq "2535") { $PortType = "MADCAP" }
    If ($Line.'DstPort' -eq "3268") { $PortType = "Global Catalog" }
    If ($Line.'DstPort' -eq "3269") { $PortType = "Global Catalog SSL" }
    If ($Line.'DstPort' -eq "3389") { $PortType = "RDP" }
    If ($Line.'DstPort' -eq "5061") { $PortType = "Skype External SIP" }
    If ($Line.'DstPort' -eq "5353") { $PortType = "Multicast DNS" }
    If ($Line.'DstPort' -eq "5355") { $PortType = "LLMNR" }
    If ($Line.'DstPort' -eq "5722") { $PortType = "DFSR" }
    If ($Line.'DstPort' -eq "5985") { $PortType = "WinRM" }
    If ($Line.'DstPort' -eq "8530" -Or $Line.'DstPort' -eq "8531") { $PortType = "WSUS" }
    If ($Line.'DstPort' -eq "9389") { $PortType = "SOAP" }
    If ($PortType -eq "" -And ($Line.'DstPort' -ge 49152 -And $Line.'DstPort' -le 65535)) { $PortType = "Dynamic (49152-65535)" } 
#endregion

    $Values = "$($Line.DstPort);$PortType;$($Line.Protocol);$SrcHostName;$($Line.SrcIP);$DstHostName;$($Line.DstIP);$($DstHostTypeList[$DstHostIPList.IndexOf($Line.DstIP)]);"
    If ( $List -NotContains $Values ) {
        $List += "$Values"
        $UniqueCounter++
    }
}

"Port;PortType;Protocol;SrcName;SrcIP;DstName;DstIP;OU" | Out-File $LogFile
$List | Sort-Object | Out-File $LogFile -Append