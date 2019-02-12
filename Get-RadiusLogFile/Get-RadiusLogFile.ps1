$t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
add-type -name win -member $t -namespace native
If ( $(Test-Path variable:global:psISE) -eq $False ) { [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0) } # This hides the Powershellwindow in the background if ISE isn't running

Function ViewRadiusLogForm { 
    
    # Gather Domaininformation
    $DomainDN = "DC="+$env:USERDNSDOMAIN.replace(".",",DC=")
    $Filter = "(&(objectClass=Computer))"
    
    # Organizational Unit where the RADIUS-servers are located
    $OU = "OU=RADIUS,OU=Servers,$DomainDN" # <- Put the OU here where the RADIUS servers are located

    # Sets how many rows to show from the end of the logfile, 0 shows all lines
    $SelectRows = 5000
    
    # Searching for Radius-logs in this location on the current server
    $LogFileLocation = "C$\Windows\System32\LogFiles" # Default RADIUS-log location
    
    #Load assemblies for System.Windows.Forms and System.Drawing
    [reflection.assembly]::loadwithpartialname(“System.Windows.Forms”) | Out-Null 
    [reflection.assembly]::loadwithpartialname(“System.Drawing”) | Out-Null 

    # Create new objects to be used within the script
    $RadiusLogForm = New-Object System.Windows.Forms.Form 
    $ServerLabel = New-Object System.Windows.Forms.Label
    $ServerComboBox = New-Object System.Windows.Forms.ComboBox    
    $LogFileLabel = New-Object System.Windows.Forms.Label
    $LogFIleComboBox = New-Object System.Windows.Forms.ComboBox
    $SelectRowsLabel = New-Object System.Windows.Forms.Label
    $SelectRowsTextBox = New-Object System.Windows.Forms.TextBox
    $ComputerNameLabel = New-Object System.Windows.Forms.Label
    $ComputerNameTextBox = New-Object System.Windows.Forms.TextBox
    $MACAddressLabel = New-Object System.Windows.Forms.Label
    $MACAddressTextBox = New-Object System.Windows.Forms.TextBox
    $ClearButton = New-Object System.Windows.Forms.Button
    $ShowLogButton = New-Object System.Windows.Forms.Button
    $InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

    #Defines what will happen when clicking on the button ClearButton
    $handler_ClearButton_Click = { 
        # Removing all values from ServerComboBox
        $ServerComboBox.Items.Clear()
        
        # Searching for RADIUS-servers in the OU specified above
        $Searcher=[adsisearcher]$Filter
        $Searcher.SearchRoot="LDAP://$OU"
        $Servers = $searcher.FindAll()
        
        # Resolves the name of the servers found above
        $Servers = $Servers.Path -Replace "LDAP://CN=",""
        $Servers = $Servers -Replace ",$OU",""
        
        # Adding servers to ServerComboBox
        ForEach ($Server in $Servers) {
            $ServerComboBox.Items.Add($Server) | out-null
        }
        
        # The first value in ServerComboBox is selected
        $ServerComboBox.Text = $ServerComboBox.Items[0]
        
        # Removing all values from LogFileComboBox
        $LogFileComboBox.Text = ""
        
        # Sets SelectRowsTextBox to the value of SelectRows
        $SelectRowsTextBox.Text = $SelectRows

        # Clears the value of ComputerName
        $ComputerNameTextBox.Text = $Null

        # Clears the value of MACAddress
        $MACAddressTextBox.Text = $Null
    }
    
    #Defines what will happen when clicking on the button ShowLogButton
    $handler_ShowLogButton_Click = { 
        # Sets where the logfiles are located
        $LogFile = "\\$($ServerComboBox.Text)\$($LogFileLocation)\$($LogFIleComboBox.Text)"
        
        # Sets which headers will be displayed in Out-GridView
        $Headers = "ComputerName","ServiceName","Record-Date","Record-Time","Packet-Type","User-Name","Fully-Qualified-Distinguished-Name","Called-Station-ID","Calling-Station-ID","Callback-Number","Framed-IP-Address","NAS-Identifier","NAS-IP-Address","NAS-Port","Client-Vendor","Client-IP-Address","Client-Friendly-Name","Event-Timestamp","Port-Limit","NAS-Port-Type","Connect-Info","Framed-Protocol","Service-Type","Authentication-Type","Policy-Name","Reason-Code","Class","Session-Timeout","Idle-Timeout","Termination-Action","EAP-Friendly-Name","Acct-Status-Type","Acct-Delay-Time","Acct-Input-Octets","Acct-Output-Octets","Acct-Session-Id","Acct-Authentic","Acct-Session-Time","Acct-Input-Packets","Acct-Output-Packets","Acct-Terminate-Cause","Acct-Multi-Ssn-ID","Acct-Link-Count","Acct-Interim-Interval","Tunnel-Type","Tunnel-Medium-Type","Tunnel-Client-Endpt","Tunnel-Server-Endpt","Acct-Tunnel-Conn","Tunnel-Pvt-Group-ID","Tunnel-Assignment-ID","Tunnel-Preference","MS-Acct-Auth-Type","MS-Acct-EAP-Type","MS-RAS-Version","MS-RAS-Vendor","MS-CHAP-Error","MS-CHAP-Domain","MS-MPPE-Encryption-Types","MS-MPPE-Encryption-Policy","Proxy-Policy-Name","Provider-Type","Provider-Name","Remote-Server-Address","MS-RAS-Client-Name","MS-RAS-Client-Version"
        
        # Gets content from the selected logfile, if SelectRowsTextBox is set to 0 it will show all lines, otherwise just the specified number from the last row upwards

        If ( $ComputerNameTextBox.Text -ne "" -and $MACAddressTextBox.Text -ne "" ) {
            $MessageBody = "Enter either Computername or MAC address, not both!"
            $MessageTitle = "$($Form.Text)"
            [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Information")
        }
        Else {
        $ServerComboBox.Enabled = $False
        $LogFIleComboBox.Enabled = $False
        $SelectRowsTextBox.Enabled = $False
        $ComputerNameTextBox.Enabled = $False
        $MACAddressTextBox.Enabled = $False
        $ClearButton.Enabled = $False
        $ShowLogButton.Enabled = $False
        If ( $SelectRowsTextBox.Text -gt 0 ) { $LogContent = Get-content -tail $SelectRowsTextBox.Text "Filesystem::\\$($ServerComboBox.Text)\$LogFileLocation\$($LogFileComboBox.Text)" | ConvertFrom-Csv -Delim ',' -Header $Headers }
        Else { $LogContent = Get-content "Filesystem::\\$($ServerComboBox.Text)\$LogFileLocation\$($LogFileComboBox.Text)" | ConvertFrom-Csv -Delim ',' -Header $Headers }
        }

        # Changes the values so it would be easier to read than just the original numbers, while keeping the number within parentheses
        ForEach ( $Line in $LogContent ) {
            If ($Line.'Authentication-Type' -eq "1") { $Line.'Authentication-Type' = "PAP (1)" }
            If ($Line.'Authentication-Type' -eq "2") { $Line.'Authentication-Type' = "CHAP (2)" }
            If ($Line.'Authentication-Type' -eq "3") { $Line.'Authentication-Type' = "MS-CHAP (3)" }
            If ($Line.'Authentication-Type' -eq "4") { $Line.'Authentication-Type' = "MS-CHAP v2 (4)" }
            If ($Line.'Authentication-Type' -eq "5") { $Line.'Authentication-Type' = "EAP (5)" }
            If ($Line.'Authentication-Type' -eq "7") { $Line.'Authentication-Type' = "None (7)" }
            If ($Line.'Authentication-Type' -eq "8") { $Line.'Authentication-Type' = "Custom (8)" }
            If ($Line.'Framed-Protocol' -eq "1") { $Line.'Framed-Protocol' = "PPP (1)" }
            If ($Line.'Framed-Protocol' -eq "2") { $Line.'Framed-Protocol' = "SLIP (2)" }
            If ($Line.'Framed-Protocol' -eq "3") { $Line.'Framed-Protocol' = "AppleTalk Remote Access Protocol (ARAP) (3)" }
            If ($Line.'Framed-Protocol' -eq "4") { $Line.'Framed-Protocol' = "Gandalf proprietary SingleLink/MultiLink protocol (4)" }
            If ($Line.'Framed-Protocol' -eq "5") { $Line.'Framed-Protocol' = "Xylogics proprietary IPX/SLIP (5)" }
            If ($Line.'Framed-Protocol' -eq "6") { $Line.'Framed-Protocol' = "X.75 Synchronous (6)" }
            If ($Line.'NAS-Port-Type' -eq "0") { $Line.'NAS-Port-Type' = "Async (0)" }
            If ($Line.'NAS-Port-Type' -eq "1") { $Line.'NAS-Port-Type' = "Sync (1)" }
            If ($Line.'NAS-Port-Type' -eq "2") { $Line.'NAS-Port-Type' = "ISDN Sync (2)" }
            If ($Line.'NAS-Port-Type' -eq "3") { $Line.'NAS-Port-Type' = "ISDN Async V.120 (3)" }
            If ($Line.'NAS-Port-Type' -eq "4") { $Line.'NAS-Port-Type' = "ISDN Async V.110 (4)" }
            If ($Line.'NAS-Port-Type' -eq "5") { $Line.'NAS-Port-Type' = "Virtual (5)" }
            If ($Line.'NAS-Port-Type' -eq "6") { $Line.'NAS-Port-Type' = "PIAFS (6)" }
            If ($Line.'NAS-Port-Type' -eq "7") { $Line.'NAS-Port-Type' = "HDLC Clear Channel (7)" }
            If ($Line.'NAS-Port-Type' -eq "8") { $Line.'NAS-Port-Type' = "X.25 (8)" }
            If ($Line.'NAS-Port-Type' -eq "9") { $Line.'NAS-Port-Type' = "X.75 (9)" }
            If ($Line.'NAS-Port-Type' -eq "10") { $Line.'NAS-Port-Type' = "G.3 Fax (10)" }
            If ($Line.'NAS-Port-Type' -eq "11") { $Line.'NAS-Port-Type' = "SDSL - Symmetric DSL (11)" }
            If ($Line.'NAS-Port-Type' -eq "12") { $Line.'NAS-Port-Type' = "ADSL-CAP - Asymmetric DSL, Carrierless Amplitude Phase Modulation (12)" }
            If ($Line.'NAS-Port-Type' -eq "13") { $Line.'NAS-Port-Type' = "ADSL-DMT - Asymmetric DSL, Discrete Multi-Tone (13)" }
            If ($Line.'NAS-Port-Type' -eq "14") { $Line.'NAS-Port-Type' = "IDSL - ISDN Digital Subscriber Line (14)" }
            If ($Line.'NAS-Port-Type' -eq "15") { $Line.'NAS-Port-Type' = "Ethernet (15)" }
            If ($Line.'NAS-Port-Type' -eq "16") { $Line.'NAS-Port-Type' = "xDSL - Digital Subscriber Line of unknown type (16)" }
            If ($Line.'NAS-Port-Type' -eq "17") { $Line.'NAS-Port-Type' = "Cable (17)" }
            If ($Line.'NAS-Port-Type' -eq "18") { $Line.'NAS-Port-Type' = "Wireless - Other (18)" }
            If ($Line.'NAS-Port-Type' -eq "19") { $Line.'NAS-Port-Type' = "Wireless - IEEE 802.11 (19)" }
            If ($Line.'NAS-Port-Type' -eq "20") { $Line.'NAS-Port-Type' = "Token-Ring (20)" }
            If ($Line.'NAS-Port-Type' -eq "21") { $Line.'NAS-Port-Type' = "FDDI (21)" }
            If ($Line.'NAS-Port-Type' -eq "22") { $Line.'NAS-Port-Type' = "Wireless - CDMA2000 (22)" }
            If ($Line.'NAS-Port-Type' -eq "23") { $Line.'NAS-Port-Type' = "Wireless - UMTS (23)" }
            If ($Line.'NAS-Port-Type' -eq "24") { $Line.'NAS-Port-Type' = "Wireless - 1X-EV (24)" }
            If ($Line.'NAS-Port-Type' -eq "25") { $Line.'NAS-Port-Type' = "IAPP (25)" }
            If ($Line.'NAS-Port-Type' -eq "26") { $Line.'NAS-Port-Type' = "FTTP - Fiber to the Premises (26)" }
            If ($Line.'NAS-Port-Type' -eq "27") { $Line.'NAS-Port-Type' = "Wireless - IEEE 802.16 (27)" }
            If ($Line.'NAS-Port-Type' -eq "28") { $Line.'NAS-Port-Type' = "Wireless - IEEE 802.20 (28)" }
            If ($Line.'NAS-Port-Type' -eq "29") { $Line.'NAS-Port-Type' = "Wireless - IEEE 802.22 (29)" }
            If ($Line.'NAS-Port-Type' -eq "30") { $Line.'NAS-Port-Type' = "PPPoA - PPP over ATM (30)" }
            If ($Line.'NAS-Port-Type' -eq "31") { $Line.'NAS-Port-Type' = "PPPoEoA - PPP over Ethernet over ATM (31)" }
            If ($Line.'NAS-Port-Type' -eq "32") { $Line.'NAS-Port-Type' = "PPPoEoE - PPP over Ethernet over Ethernet (32)" }
            If ($Line.'NAS-Port-Type' -eq "33") { $Line.'NAS-Port-Type' = "PPPoEoVLAN - PPP over Ethernet over VLAN (33)" }
            If ($Line.'NAS-Port-Type' -eq "34") { $Line.'NAS-Port-Type' = "PPPoEoQinQ - PPP over Ethernet over IEEE 802.1QinQ (34)" }
            If ($Line.'NAS-Port-Type' -eq "35") { $Line.'NAS-Port-Type' = "xPON - Passive Optical Network (35)" }
            If ($Line.'NAS-Port-Type' -eq "36") { $Line.'NAS-Port-Type' = "Wireless - XGP (36)" }
            If ($Line.'NAS-Port-Type' -eq "37") { $Line.'NAS-Port-Type' = "WiMAX Pre-Release 8 IWK Function (37)" }
            If ($Line.'NAS-Port-Type' -eq "38") { $Line.'NAS-Port-Type' = "WIMAX-WIFI-IWK: WiMAX WIFI Interworking (38)" }
            If ($Line.'NAS-Port-Type' -eq "39") { $Line.'NAS-Port-Type' = "WIMAX-SFF: Signaling Forwarding Function for LTE/3GPP2 (39)" }
            If ($Line.'NAS-Port-Type' -eq "40") { $Line.'NAS-Port-Type' = "WIMAX-HA-LMA: WiMAX HA and or LMA function (40)" }
            If ($Line.'NAS-Port-Type' -eq "41") { $Line.'NAS-Port-Type' = "WIMAX-DHCP: WIMAX DCHP service (41)" }
            If ($Line.'NAS-Port-Type' -eq "42") { $Line.'NAS-Port-Type' = "WIMAX-LBS: WiMAX location based service (42)" }
            If ($Line.'NAS-Port-Type' -eq "43") { $Line.'NAS-Port-Type' = "WIMAX-WVS: WiMAX voice service (43)" }
            If ($Line.'Packet-Type' -eq "1") { $Line.'Packet-Type' = "Access-Request (1)" }
            If ($Line.'Packet-Type' -eq "2") { $Line.'Packet-Type' = "Access-Accept (2)" }
            If ($Line.'Packet-Type' -eq "3") { $Line.'Packet-Type' = "Access-Reject (3)" }
            If ($Line.'Packet-Type' -eq "4") { $Line.'Packet-Type' = "Accounting-Request (4)" }
            If ($Line.'Packet-Type' -eq "5") { $Line.'Packet-Type' = "Accounting-Response (5)" }
            If ($Line.'Packet-Type' -eq "6") { $Line.'Packet-Type' = "Accounting-Status (now Interim Accounting) (6)" }
            If ($Line.'Packet-Type' -eq "7") { $Line.'Packet-Type' = "Password-Request (7)" }
            If ($Line.'Packet-Type' -eq "8") { $Line.'Packet-Type' = "Password-Ack (8)" }
            If ($Line.'Packet-Type' -eq "9") { $Line.'Packet-Type' = "Password-Reject (9)" }
            If ($Line.'Packet-Type' -eq "10") { $Line.'Packet-Type' = "Accounting-Message (10)" }
            If ($Line.'Packet-Type' -eq "11") { $Line.'Packet-Type' = "Access-Challenge (11)" }
            If ($Line.'Packet-Type' -eq "12") { $Line.'Packet-Type' = "Status-Server (experimental) (12)" }
            If ($Line.'Packet-Type' -eq "13") { $Line.'Packet-Type' = "Status-Client (experimental) (13)" }
            If ($Line.'Packet-Type' -eq "21") { $Line.'Packet-Type' = "Resource-Free-Request (21)" }
            If ($Line.'Packet-Type' -eq "22") { $Line.'Packet-Type' = "Resource-Free-Response (22)" }
            If ($Line.'Packet-Type' -eq "23") { $Line.'Packet-Type' = "Resource-Query-Request (23)" }
            If ($Line.'Packet-Type' -eq "24") { $Line.'Packet-Type' = "Resource-Query-Response (24)" }
            If ($Line.'Packet-Type' -eq "25") { $Line.'Packet-Type' = "Alternate-Resource-Reclaim-Request (25)" }
            If ($Line.'Packet-Type' -eq "26") { $Line.'Packet-Type' = "NAS-Reboot-Request (26)" }
            If ($Line.'Packet-Type' -eq "27") { $Line.'Packet-Type' = "NAS-Reboot-Response (27)" }
            If ($Line.'Packet-Type' -eq "28") { $Line.'Packet-Type' = "Reserved (28)" }
            If ($Line.'Packet-Type' -eq "29") { $Line.'Packet-Type' = "Next-Passcode (29)" }
            If ($Line.'Packet-Type' -eq "30") { $Line.'Packet-Type' = "New-Pin (30)" }
            If ($Line.'Packet-Type' -eq "31") { $Line.'Packet-Type' = "Terminate-Session (31)" }
            If ($Line.'Packet-Type' -eq "32") { $Line.'Packet-Type' = "Password-Expired (32)" }
            If ($Line.'Packet-Type' -eq "33") { $Line.'Packet-Type' = "Event-Request (33)" }
            If ($Line.'Packet-Type' -eq "34") { $Line.'Packet-Type' = "Event-Response (34)" }
            If ($Line.'Packet-Type' -ge 35 -and $Line.'Packet-Type' -le 39) { $Line.'Packet-Type' = "Unassigned (35-39)" }
            If ($Line.'Packet-Type' -eq "40") { $Line.'Packet-Type' = "Disconnect-Request (40)" }
            If ($Line.'Packet-Type' -eq "41") { $Line.'Packet-Type' = "Disconnect-ACK (41)" }
            If ($Line.'Packet-Type' -eq "42") { $Line.'Packet-Type' = "Disconnect-NAK (42)" }
            If ($Line.'Packet-Type' -eq "43") { $Line.'Packet-Type' = "CoA-Request (43)" }
            If ($Line.'Packet-Type' -eq "44") { $Line.'Packet-Type' = "CoA-ACK (44)" }
            If ($Line.'Packet-Type' -eq "45") { $Line.'Packet-Type' = "CoA-NAK (45)" }
            If ($Line.'Packet-Type' -ge 46 -and $Line.'Packet-Type' -le 49) { $Line.'Packet-Type' = "Unassigned (46-49)" }
            If ($Line.'Packet-Type' -eq "50") { $Line.'Packet-Type' = "IP-Address-Allocate (50)" }
            If ($Line.'Packet-Type' -eq "51") { $Line.'Packet-Type' = "IP-Address-Release (51)" }
            If ($Line.'Packet-Type' -eq "52") { $Line.'Packet-Type' = "Protocol-Error (52)" }
            If ($Line.'Packet-Type' -ge 53 -and $Line.'Packet-Type' -le 249) { $Line.'Packet-Type' = "Unassigned (53-249)" }
            If ($Line.'Packet-Type' -ge 250 -and $Line.'Packet-Type' -le 253) { $Line.'Packet-Type' = "Experimental Use (250-253)" }
            If ($Line.'Packet-Type' -eq "254") { $Line.'Packet-Type' = "Reserved (254)" }
            If ($Line.'Packet-Type' -eq "255") { $Line.'Packet-Type' = "Reserved (255)" }
            If ($Line.'Reason-Code' -eq "0") { $Line.'Reason-Code' = "IAS_SUCCESS (0)" }
            If ($Line.'Reason-Code' -eq "1") { $Line.'Reason-Code' = "IAS_INTERNAL_ERROR (1)" }
            If ($Line.'Reason-Code' -eq "2") { $Line.'Reason-Code' = "IAS_ACCESS_DENIED (2)" }
            If ($Line.'Reason-Code' -eq "3") { $Line.'Reason-Code' = "IAS_MALFORMED_REQUEST (3)" }
            If ($Line.'Reason-Code' -eq "4") { $Line.'Reason-Code' = "IAS_GLOBAL_CATALOG_UNAVAILABLE (4)" }
            If ($Line.'Reason-Code' -eq "5") { $Line.'Reason-Code' = "IAS_DOMAIN_UNAVAILABLE (5)" }
            If ($Line.'Reason-Code' -eq "6") { $Line.'Reason-Code' = "IAS_SERVER_UNAVAILABLE (6)" }
            If ($Line.'Reason-Code' -eq "7") { $Line.'Reason-Code' = "IAS_NO_SUCH_DOMAIN (7)" }
            If ($Line.'Reason-Code' -eq "8") { $Line.'Reason-Code' = "IAS_NO_SUCH_USER (8)" }
            If ($Line.'Reason-Code' -eq "16") { $Line.'Reason-Code' = "IAS_AUTH_FAILURE (16)" }
            If ($Line.'Reason-Code' -eq "17") { $Line.'Reason-Code' = "IAS_CHANGE_PASSWORD_FAILURE (17)" }
            If ($Line.'Reason-Code' -eq "18") { $Line.'Reason-Code' = "IAS_UNSUPPORTED_AUTH_TYPE (18)" }
            If ($Line.'Reason-Code' -eq "32") { $Line.'Reason-Code' = "IAS_LOCAL_USERS_ONLY (32)" }
            If ($Line.'Reason-Code' -eq "33") { $Line.'Reason-Code' = "IAS_PASSWORD_MUST_CHANGE (33)" }
            If ($Line.'Reason-Code' -eq "34") { $Line.'Reason-Code' = "IAS_ACCOUNT_DISABLED (34)" }
            If ($Line.'Reason-Code' -eq "35") { $Line.'Reason-Code' = "IAS_ACCOUNT_EXPIRED (35)" }
            If ($Line.'Reason-Code' -eq "36") { $Line.'Reason-Code' = "IAS_ACCOUNT_LOCKED_OUT (36)" }
            If ($Line.'Reason-Code' -eq "37") { $Line.'Reason-Code' = "IAS_INVALID_LOGON_HOURS (37)" }
            If ($Line.'Reason-Code' -eq "38") { $Line.'Reason-Code' = "IAS_ACCOUNT_RESTRICTION (38)" }
            If ($Line.'Reason-Code' -eq "48") { $Line.'Reason-Code' = "IAS_NO_POLICY_MATCH (48)" }
            If ($Line.'Reason-Code' -eq "64") { $Line.'Reason-Code' = "IAS_DIALIN_LOCKED_OUT (64)" }
            If ($Line.'Reason-Code' -eq "65") { $Line.'Reason-Code' = "IAS_DIALIN_DISABLED (65)" }
            If ($Line.'Reason-Code' -eq "66") { $Line.'Reason-Code' = "IAS_INVALID_AUTH_TYPE (66)" }
            If ($Line.'Reason-Code' -eq "67") { $Line.'Reason-Code' = "IAS_INVALID_CALLING_STATION (67)" }
            If ($Line.'Reason-Code' -eq "68") { $Line.'Reason-Code' = "IAS_INVALID_DIALIN_HOURS (68)" }
            If ($Line.'Reason-Code' -eq "69") { $Line.'Reason-Code' = "IAS_INVALID_CALLED_STATION (69)" }
            If ($Line.'Reason-Code' -eq "70") { $Line.'Reason-Code' = "IAS_INVALID_PORT_TYPE (70)" }
            If ($Line.'Reason-Code' -eq "71") { $Line.'Reason-Code' = "IAS_INVALID_RESTRICTION (71)" }
            If ($Line.'Reason-Code' -eq "80") { $Line.'Reason-Code' = "IAS_NO_RECORD (80)" }
            If ($Line.'Reason-Code' -eq "96") { $Line.'Reason-Code' = "IAS_SESSION_TIMEOUT (96)" }
            If ($Line.'Reason-Code' -eq "97") { $Line.'Reason-Code' = "IAS_UNEXPECTED_REQUEST (97)" }
            If ($Line.'Service-Type' -eq "1") { $Line.'Service-Type' = "Login (1)" }
            If ($Line.'Service-Type' -eq "2") { $Line.'Service-Type' = "Framed (2)" }
            If ($Line.'Service-Type' -eq "3") { $Line.'Service-Type' = "Callback Login (3)" }
            If ($Line.'Service-Type' -eq "4") { $Line.'Service-Type' = "Callback Framed (4)" }
            If ($Line.'Service-Type' -eq "5") { $Line.'Service-Type' = "Outbound (5)" }
            If ($Line.'Service-Type' -eq "6") { $Line.'Service-Type' = "Administrative (6)" }
            If ($Line.'Service-Type' -eq "7") { $Line.'Service-Type' = "NAS Prompt (7)" }
            If ($Line.'Service-Type' -eq "8") { $Line.'Service-Type' = "Authenticate Only (8)" }
            If ($Line.'Service-Type' -eq "9") { $Line.'Service-Type' = "Callback NAS Prompt (9)" }
            If ($Line.'Service-Type' -eq "10") { $Line.'Service-Type' = "Call Check (10)" }
            If ($Line.'Service-Type' -eq "11") { $Line.'Service-Type' = "Callback Administrative (11)" }
            If ($Line.'Service-Type' -eq "12") { $Line.'Service-Type' = "Voice (12)" }
            If ($Line.'Service-Type' -eq "13") { $Line.'Service-Type' = "Fax (13)" }
            If ($Line.'Service-Type' -eq "14") { $Line.'Service-Type' = "Modem Relay (14)" }
            If ($Line.'Service-Type' -eq "15") { $Line.'Service-Type' = "IAPP-Register (15)" }
            If ($Line.'Service-Type' -eq "16") { $Line.'Service-Type' = "IAPP-AP-Check (16)" }
            If ($Line.'Service-Type' -eq "17") { $Line.'Service-Type' = "Authorize Only (17)" }
            If ($Line.'Service-Type' -eq "18") { $Line.'Service-Type' = "Framed-Management (18)" }
            If ($Line.'Service-Type' -eq "19") { $Line.'Service-Type' = "Additional-Authorization (19)" }
            If ($Line.'Tunnel-Medium-Type' -eq "1") { $Line.'Tunnel-Medium-Type' = "IPv4 (IP version 4) (1)" }
            If ($Line.'Tunnel-Medium-Type' -eq "2") { $Line.'Tunnel-Medium-Type' = "IPv6 (IP version 6) (2)" }
            If ($Line.'Tunnel-Medium-Type' -eq "3") { $Line.'Tunnel-Medium-Type' = "NSAP (3)" }
            If ($Line.'Tunnel-Medium-Type' -eq "4") { $Line.'Tunnel-Medium-Type' = "HDLC (8-bit multidrop) (4)" }
            If ($Line.'Tunnel-Medium-Type' -eq "5") { $Line.'Tunnel-Medium-Type' = "BBN 1822 (5)" }
            If ($Line.'Tunnel-Medium-Type' -eq "6") { $Line.'Tunnel-Medium-Type' = "802 (includes all 802 media plus Ethernet ""canonical format"") (6)" }
            If ($Line.'Tunnel-Medium-Type' -eq "7") { $Line.'Tunnel-Medium-Type' = "E.163 (POTS) (7)" }
            If ($Line.'Tunnel-Medium-Type' -eq "8") { $Line.'Tunnel-Medium-Type' = "E.164 (SMDS, Frame Relay, ATM) (8)" }
            If ($Line.'Tunnel-Medium-Type' -eq "9") { $Line.'Tunnel-Medium-Type' = "F.69 (Telex) (9)" }
            If ($Line.'Tunnel-Medium-Type' -eq "10") { $Line.'Tunnel-Medium-Type' = "X.121 (X.25, Frame Relay) (10)" }
            If ($Line.'Tunnel-Medium-Type' -eq "11") { $Line.'Tunnel-Medium-Type' = "IPX (11)" }
            If ($Line.'Tunnel-Medium-Type' -eq "12") { $Line.'Tunnel-Medium-Type' = "Appletalk (12)" }
            If ($Line.'Tunnel-Medium-Type' -eq "13") { $Line.'Tunnel-Medium-Type' = "Decnet IV (13)" }
            If ($Line.'Tunnel-Medium-Type' -eq "14") { $Line.'Tunnel-Medium-Type' = "Banyan Vines (14)" }
            If ($Line.'Tunnel-Medium-Type' -eq "15") { $Line.'Tunnel-Medium-Type' = "E.164 with NSAP format subaddress (15)" }
            If ($Line.'Tunnel-Type' -eq "1") { $Line.'Tunnel-Type' = "Point-to-Point Tunneling Protocol (PPTP) (1)" }
            If ($Line.'Tunnel-Type' -eq "2") { $Line.'Tunnel-Type' = "Layer Two Forwarding (L2F) (2)" }
            If ($Line.'Tunnel-Type' -eq "3") { $Line.'Tunnel-Type' = "Layer Two Tunneling Protocol (L2TP) (3)" }
            If ($Line.'Tunnel-Type' -eq "4") { $Line.'Tunnel-Type' = "Ascend Tunnel Management Protocol (ATMP) (4)" }
            If ($Line.'Tunnel-Type' -eq "5") { $Line.'Tunnel-Type' = "Virtual Tunneling Protocol (VTP) (5)" }
            If ($Line.'Tunnel-Type' -eq "6") { $Line.'Tunnel-Type' = "IP Authentication Header in the Tunnel-mode (AH) (6)" }
            If ($Line.'Tunnel-Type' -eq "7") { $Line.'Tunnel-Type' = "IP-in-IP Encapsulation (IP-IP) (7)" }
            If ($Line.'Tunnel-Type' -eq "8") { $Line.'Tunnel-Type' = "Minimal IP-in-IP Encapsulation (MIN-IP-IP) (8)" }
            If ($Line.'Tunnel-Type' -eq "9") { $Line.'Tunnel-Type' = "IP Encapsulating Security Payload in the Tunnel-mode (ESP) (9)" }
            If ($Line.'Tunnel-Type' -eq "10") { $Line.'Tunnel-Type' = "Generic Route Encapsulation (GRE) (10)" }
            If ($Line.'Tunnel-Type' -eq "11") { $Line.'Tunnel-Type' = "Bay Dial Virtual Services (DVS) (11)" }
            If ($Line.'Tunnel-Type' -eq "12") { $Line.'Tunnel-Type' = "IP-in-IP Tunneling (12)" }
            If ($Line.'Tunnel-Type' -eq "13") { $Line.'Tunnel-Type' = "Virtual LANs (VLAN) (13)" }
            If ($Line.'Termination-Action' -eq "0") { $Line.'Termination-Action' = "Default (0)" }
            If ($Line.'Termination-Action' -eq "1") { $Line.'Termination-Action' = "RADIUS-Request (1)" }            
        }
        # Passing the gathered data to Out-GridView
        If ( $ComputerNameTextBox.Text -eq "" -and $MACAddressTextBox.Text -eq "" ) { $LogContent | Out-GridView -PassThru }
        If ( $ComputerNameTextBox.Text -ne "" -and $MACAddressTextBox.Text -eq "" ) {
            $Test = $LogContent | Where { $_.'Fully-Qualified-Distinguished-Name' -like "*$($ComputerNameTextBox.Text)*" }
            If ( $Test.Count -gt 0 ) { 
                $Test | Out-GridView -PassThru
            }
            Else {
                $MessageBody = "No posts where found with the entered criterias"
                $MessageTitle = "$($Form.Text)"
                [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Information")
            }
        }
        If ( $ComputerNameTextBox.Text -eq "" -and $MACAddressTextBox.Text -ne "" ) {
            $MACAddress = $($MACAddressTextBox.Text).ToLower()
            $MACAddress = $MACAddress -replace "-",""
            $MACAddress = $MACAddress -replace ":",""
            $Test = $LogContent | Where { $_.'Calling-Station-ID' -like "*$($MACAddressTextBox.Text)*" }
            If ( $Test.Count -gt 0 ) { 
                $Test | Out-GridView -PassThru
            }
            Else {
                $MessageBody = "No posts where found with the entered criterias"
                $MessageTitle = "$($Form.Text)"
                [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Information")
            }
        }
        $ServerComboBox.Enabled = $True
        $LogFIleComboBox.Enabled = $True
        $SelectRowsTextBox.Enabled = $True
        $ComputerNameTextBox.Enabled = $True
        $MACAddressTextBox.Enabled = $True
        $ClearButton.Enabled = $True
        $ShowLogButton.Enabled = $True
    }

    # Sets the WindowState to same as the variable InitialFormWindowState
    { $RadiusLogForm.WindowState = $InitialFormWindowState } | out-null

    # Creating the RadiusLogForm-object
    $RadiusLogForm.Text = “View Radius log”
    $RadiusLogForm.Name = “View Radius log”
    $RadiusLogForm.FormBorderStyle = 'Fixed3D'
    $RadiusLogForm.MaximizeBox = $False
    $System_Drawing_Size = New-Object System.Drawing.Size 
    $System_Drawing_Size.Width = 370
    $System_Drawing_Size.Height = 200
    $RadiusLogForm.ClientSize = $System_Drawing_Size

    # Sets variables that will be the same for a couple of the objects in the form
    $LabelXWidth = 100
    $LabelXPoint = 10
    $TextBoxXWidth = 250
    $TextBoxXPoint = 110
    $ButtonXPoint = 10
    $RowHeight = 25

    # Creating the ServerLabel-object
    $ServerLabel.Name = "ServerLabel"
    $ServerLabel.Text = "Server:"
    $System_Drawing_Size.Width = $LabelXWidth
    $System_Drawing_Size.Height = $RowHeight
    $ServerLabel.Size = $System_Drawing_Size 
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $LabelXPoint
    $System_Drawing_Point.Y = 10
    $ServerLabel.Location = $System_Drawing_Point 

    # Creating the ServerComboBox-object
    $ServerComboBox.TabIndex = 1
    $ServerComboBox.Name = "ServerComboBox"
    $System_Drawing_Size.Width = $TextBoxXWidth
    $System_Drawing_Size.Height = $RowHeight
    $ServerComboBox.Size = $System_Drawing_Size 
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $TextBoxXPoint
    $System_Drawing_Point.Y = 10
    $ServerComboBox.Location = $System_Drawing_Point
    $ServerComboBox.DropDownStyle = "DropDownList"
    
    # Searching for RADIUS-servers in the OU specified above
    $Searcher=[adsisearcher]$Filter
    $Searcher.SearchRoot="LDAP://$OU"
    $Servers = $searcher.FindAll()
    
    # Resolves the name of the servers found above
    $Servers = $Servers.Path -Replace "LDAP://CN=",""
    $Servers = $Servers -Replace ",$OU",""
    
    # Adding servers to ServerComboBox
    ForEach ($Server in $Servers) {
        $ServerComboBox.Items.Add($Server) | out-null
    }

    # If LogFileComboBox is less than or equal to 0 LogFileComboBox and ShowLogButton will be disabled, otherwise enabled
    If ( $LogFileComboBox.Items.Count -le 0 ) { $LogFileComboBox.Enabled = $False ; $ShowLogButton.Enabled = $False }
    Else {
        $LogFileComboBox.Enabled = $True
        $ShowLogButton.Enabled = $True
    }
    
    # Defines what will happen when the selected item in ServerComboBox is changed
    $ServerComboBox_IfSelectedIndexChanged = {
            
        # Removing all values from LogFileComboBox
        $LogFileComboBox.Items.Clear()
            
        # Gather the logfiles from the selected server
        $LogFiles = $(Get-ChildItem *.log -Path "\\$($ServerComboBox.Text)\$LogFileLocation").Name

        # If LogFileComboBox is less than or equal to 0 LogFileComboBox and ShowLogButton will be disabled, otherwise enabled
        If ( $LogFiles.Count -le 0 ) { $LogFileComboBox.Enabled = $False ; $ShowLogButton.Enabled = $False }
        Else {
            $LogFileComboBox.Enabled = $True
            $ShowLogButton.Enabled = $True
        }

        # Adding logfiles found to LogFileComboBox
        ForEach ($File in $LogFiles) {
            $LogFileComboBox.Items.Add($File) | out-null
        }
        # The last value in LogFileComboBox is selected
        $LogFileComboBox.SelectedIndex = $LogFileComboBox.Items.Count - 1
    }
    
    # Adding the function what will happen when changing ServerComboBox
    $ServerComboBox.Add_SelectedIndexChanged($ServerComboBox_IfSelectedIndexChanged)
    
    # Creating the LogFileLabel-object
    $LogFileLabel.Name = "LogFileLabel"
    $LogFileLabel.Text = "Log file location:"
    $System_Drawing_Size.Width = $LabelXWidth 
    $System_Drawing_Size.Height = $RowHeight
    $LogFileLabel.Size = $System_Drawing_Size 
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $LabelXPoint
    $System_Drawing_Point.Y = 40
    $LogFileLabel.Location = $System_Drawing_Point 

    # Creating the LogFileComboBox-object
    $ServerComboBox.Text = $ServerComboBox.Items[0]
    $LogFileComboBox.TabIndex = 2
    $LogFileComboBox.Name = "LogFileTextBox"
    $System_Drawing_Size.Width = $TextBoxXWidth
    $System_Drawing_Size.Height = $RowHeight
    $LogFileComboBox.Size = $System_Drawing_Size 
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $TextBoxXPoint
    $System_Drawing_Point.Y = 40
    $LogFileComboBox.Location = $System_Drawing_Point
    
    # Sets the ComboBox-type to DropDownList so it would be Read-only
    $LogFileComboBox.DropDownStyle = "DropDownList"

    # Gather the logfiles from the selected server
    $LogFiles = $(Get-ChildItem *.log -Path "\\$($ServerComboBox.Text)\$LogFileLocation").Name
    
    # Adding logfiles found to LogFileComboBox
    ForEach ($File in $LogFiles) {
        $LogFileComboBox.Items.Add($File) | out-null
    }
    
    # The last value in LogFileComboBox is selected
    $LogFileComboBox.SelectedIndex = $LogFileComboBox.Items.Count - 1

    # Creating the SelectRowsLabel-object
    $SelectRowsLabel.Name = "SelectRowsLabel"
    $SelectRowsLabel.Text = "Show last rows (0=All):"
    $System_Drawing_Size.Width = $LabelXWidth
    $System_Drawing_Size.Height = $RowHeight
    $SelectRowsLabel.Size = $System_Drawing_Size 
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $LabelXPoint
    $System_Drawing_Point.Y = 70
    $SelectRowsLabel.Location = $System_Drawing_Point 

    # Creating the ServerTextBox-object
    $SelectRowsTextBox.TabIndex = 3
    $SelectRowsTextBox.Name = "SelectRowsTextBox"
    $SelectRowsTextBox.Text = $SelectRows
    $System_Drawing_Size.Width = $TextBoxXWidth
    $System_Drawing_Size.Height = $RowHeight
    $SelectRowsTextBox.Size = $System_Drawing_Size 
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $TextBoxXPoint
    $System_Drawing_Point.Y = 70
    $SelectRowsTextBox.Location = $System_Drawing_Point
    
    # Sets the MaxLength for SelectROwsTextBox to 4
    $SelectRowsTextBox.MaxLength = 4

    # Delete other characters than numeric values if entered into SelectRowsTextBox
    $SelectRowsTextBox.Add_TextChanged({ $this.Text = $this.Text -replace '\D' })

    # Creating the ComputerNameLabel-object
    $ComputerNameLabel.Name = "ComputerNameLabel"
    $ComputerNameLabel.Text = "Computername:"
    $System_Drawing_Size.Width = $LabelXWidth
    $System_Drawing_Size.Height = $RowHeight
    $ComputerNameLabel.Size = $System_Drawing_Size 
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $LabelXPoint
    $System_Drawing_Point.Y = 100
    $ComputerNameLabel.Location = $System_Drawing_Point 

    # Creating the ComputerNameTextBox-object
    $ComputerNameTextBox.TabIndex = 4
    $ComputerNameTextBox.Name = "ComputerNameTextBox"
    $System_Drawing_Size.Width = $TextBoxXWidth
    $System_Drawing_Size.Height = $RowHeight
    $ComputerNameTextBox.Size = $System_Drawing_Size 
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $TextBoxXPoint
    $System_Drawing_Point.Y = 100
    $ComputerNameTextBox.Location = $System_Drawing_Point

    # Creating the MACAddressLabel-object
    $MACAddressLabel.Name = "MACAddressLabel"
    $MACAddressLabel.Text = "MAC address:"
    $System_Drawing_Size.Width = $LabelXWidth
    $System_Drawing_Size.Height = $RowHeight
    $MACAddressLabel.Size = $System_Drawing_Size 
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $LabelXPoint
    $System_Drawing_Point.Y = 130
    $MACAddressLabel.Location = $System_Drawing_Point 

    # Creating the MACAddressTextBox-object
    $MACAddressTextBox.TabIndex = 5
    $MACAddressTextBox.Name = "MACAddressTextBox"
    $System_Drawing_Size.Width = $TextBoxXWidth
    $System_Drawing_Size.Height = $RowHeight
    $MACAddressTextBox.too
    $MACAddressTextBox.Size = $System_Drawing_Size 
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $TextBoxXPoint
    $System_Drawing_Point.Y = 130
    $MACAddressTextBox.Location = $System_Drawing_Point

    # Creating the ClearButton-object
    $ClearButton.TabIndex = 6
    $ClearButton.Name = “ClearButton”
    $System_Drawing_Size = New-Object System.Drawing.Size 
    $System_Drawing_Size.Width = 100
    $System_Drawing_Size.Height = 25 
    $ClearButton.Size = $System_Drawing_Size 
    $ClearButton.UseVisualStyleBackColor = $True
    $ClearButton.Text = “Reset”
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = 10
    $System_Drawing_Point.Y = 160
    $ClearButton.Location = $System_Drawing_Point 
    $ClearButton.add_Click($handler_ClearButton_Click)

    # Creating the ShowLogButton-object
    $ShowLogButton.TabIndex = 7
    $ShowLogButton.Name = “ShowLogButton”
    $System_Drawing_Size = New-Object System.Drawing.Size 
    $System_Drawing_Size.Width = 100
    $System_Drawing_Size.Height = 25 
    $ShowLogButton.Size = $System_Drawing_Size 
    $ShowLogButton.UseVisualStyleBackColor = $True
    $ShowLogButton.Text = “Show Radius-log”
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = 260
    $System_Drawing_Point.Y = 160
    $ShowLogButton.Location = $System_Drawing_Point 
    $ShowLogButton.add_Click($handler_ShowLogButton_Click)

    # Adding created objects to the RadiusLogForm
    $RadiusLogForm.Controls.Add($ServerLabel)
    $RadiusLogForm.Controls.Add($ServerComboBox)
    $RadiusLogForm.Controls.Add($LogFileLabel)
    $RadiusLogForm.Controls.Add($LogFIleComboBox)
    $RadiusLogForm.Controls.Add($SelectRowsLabel)
    $RadiusLogForm.Controls.Add($SelectRowsTextBox)
    $RadiusLogForm.Controls.Add($ComputerNameLabel)
    $RadiusLogForm.Controls.Add($ComputerNameTextBox)
    $RadiusLogForm.Controls.Add($MACAddressLabel)
    $RadiusLogForm.Controls.Add($MACAddressTextBox)
    $RadiusLogForm.Controls.Add($ClearButton)
    $RadiusLogForm.Controls.Add($ShowLogButton)

    # Displays the RadiusLogForm-window
    $RadiusLogForm.ShowDialog()| Out-Null
}

# Trigger the ViewRadiusLogForm-function
ViewRadiusLogForm