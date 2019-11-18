#Requires -Version 5.1
New-Variable -Name Namespace -Value 'root\StifleR' -Option AllScope

function Add-Subnet {

    <#
    .SYNOPSIS
        Use this to add a subnet to StifleR

    .DESCRIPTION
        Just another way of adding a new subnet to StifleR
        Details:
        - If you don't automatically add your subnets when clients connect, this could be an alternative...

    .PARAMETER SubnetID
        Specify which subnetID that need to be created

    .PARAMETER GatewayMAC
        Specify the MAC address of the GatewayMAC, default is '00-00-00-00-00-00'

    .PARAMETER TargetBandwidth
        Specify the max bandwidth allowed for the Red leader on this subnet
        
    .PARAMETER Description
        Specify a description that should be added to this subnet
        
    .PARAMETER ParentLocationID
        Make this subnet a child of another subnet by using the Id of the parent
        
    .PARAMETER LEDBATTargetBandwidth
        Specify the max LEDBAT bandwidth allowed for the Red leader on this subnet
        
    .PARAMETER VPN
        Specify if this is a VPN subnet or not, default is false
        
    .PARAMETER WellConnected
        Specify if this is a WellConnected subnet or not
        
    .PARAMETER DOType
        Specify the Delivery Optimization type for this subnet, default is Group (2)
        
    .PARAMETER SetDOGroupID
        This parameter sets the Id of this new subnet as the Delivery Optimization Group ID

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Add-StiflerSubnet -Server server01 -SubnetID 172.10.10.0 -VPN $true
        Creates a new subnet with the SubnetID of 172.10.10.0 and classes it as a VPN subnet

    .FUNCTIONALITY
        StifleR
    #>

    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ValueFromRemainingArguments=$false,Mandatory=$true)]
        [String]$SubnetID,
        [string]$GatewayMAC='00-00-00-00-00-00',
        [String]$LocationName=$SubnetID,
        [uint32]$TargetBandwidth=0,
        [string]$Description,
        [string]$ParentLocationID,
        [int]$LEDBATTargetBandwidth=0,
        [bool]$VPN=$false,
        [bool]$WellConnected=$false,
        [ValidateSet('Not set','HTTP Only','LAN','Group','Internet','Simple','Bypass')]
        [string]$DOType='Not set',
        [switch]$SetDOGroupID
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server

        $SubnetQuery = "SELECT * FROM Subnets WHERE SubnetID = '$SubnetID'"
        Write-Verbose "Variable - SubnetQuery : $SubnetQuery"
        Write-Verbose "Verify if subnet exist: Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Filter ""SubnetID = '$SubnetID'"""
        if ( $(Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Filter "SubnetID = '$SubnetID'") ) {
            Write-Warning "SubnetID $SubnetID already exist, aborting!"
            break
        }
    }

    process {
        Write-Debug "Next step - Adding subnet"
        try {            
            Write-Verbose "Adding subnet: Invoke-CimMethod -Namespace $Namespace -ClassName Subnets -MethodName AddSubnet -ComputerName $Server -Arguments @{ subnet=$SubnetID ; TargetBandwidth=$TargetBandwidth ; locationName=$LocationName ; description=$Description ; GatewayMAC=$GatewayMAC ; ParentLocationId=$ParentLocationID } | out-null"
            Invoke-CimMethod -Namespace $Namespace -ClassName Subnets -MethodName AddSubnet -ComputerName $Server -Arguments @{ subnet=$SubnetID ; TargetBandwidth=$TargetBandwidth ; locationName=$LocationName ; description=$Description ; GatewayMAC=$GatewayMAC ; ParentLocationId=$ParentLocationID } | out-null
            $NewSubnetSuccess = $true
            Write-Verbose 'Variable - NewSubnetSuccess : $true'
            Write-Output "Successfully added the subnet $SubnetID with the following parameters: TargetBanwidth: $TargetBandwidth   locationName=$LocationName   description=$Description   GatewayMAC=$GatewayMAC   ParentLocationId=$ParentLocationID"
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9202 -Message "Successfully added the subnet $SubnetID with the following parameters: TargetBanwidth: $TargetBandwidth   locationName=$LocationName   description=$Description   GatewayMAC=$GatewayMAC   ParentLocationId=$ParentLocationID" -EntryType Information
        }
        catch {
            Write-Warning "Failed to add the subnet $SubnetID with the following parameters: TargetBanwidth: $TargetBandwidth   locationName=$LocationName   description=$Description   GatewayMAC=$GatewayMAC   ParentLocationId=$ParentLocationID"
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9203 -Message "Failed to add the subnet $SubnetID with the following parameters: TargetBanwidth: $TargetBandwidth   locationName=$LocationName   description=$Description   GatewayMAC=$GatewayMAC   ParentLocationId=$ParentLocationID" -EntryType Error
        }

        if ( $NewSubnetSuccess -eq $true ) {
            Write-Debug "Next step - Modify properties"
            if ( $LEDBATTargetBandwidth -ne 0 ) {
                Write-Debug "Next step - Modify property LEDBATTargetBandwidth"
                try {
                    Write-Verbose "Modifying subnet: Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{LEDBATTargetBandwidth = $LEDBATTargetBandwidth} -ComputerName $Server"
                    Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{LEDBATTargetBandwidth = $LEDBATTargetBandwidth} -ComputerName $Server
                    Write-Output "Successfully changed the property LEDBATTargetBandwidth on subnet $SubnetID to $LEDBATTargetBandwidth"
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9204 -Message "Successfully changed the property LEDBATTargetBandwidth on subnet $SubnetID to $LEDBATTargetBandwidth" -EntryType Information
                }
                catch {
                    Write-Warning "Failed to change the property LEDBATTargetBandwidth on subnet $SubnetID to $LEDBATTargetBandwidth"
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9205 -Message "Failed to change the property LEDBATTargetBandwidth on subnet $SubnetID to $LEDBATTargetBandwidth" -EntryType Error
                }
            }

            if ( $VPN -eq $True ) {
                Write-Debug "Next step - Modify property VPN"
                try {
                    Write-Verbose "Modifying subnet: Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{VPN = $VPN } -ComputerName $Server"
                    Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{VPN = $VPN } -ComputerName $Server
                    Write-Output "Successfully changed the property VPN on subnet $SubnetID to $VPN"
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9204 -Message "Successfully changed the property VPN on subnet $SubnetID to $VPN" -EntryType Information
                }
                catch {
                    Write-Warning "Failed to change the property VPN on subnet $SubnetID to $VPN"
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9205 -Message "Failed to change the property VPN on subnet $SubnetID to $VPN" -EntryType Error
                }
            }
            
            if ( $WellConnected -eq $True ) {
                Write-Debug "Next step - Modify property WellConnected"
                try {
                    Write-Verbose "Modifying subnet: Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{WellConnected = $WellConnected } -ComputerName $Server"
                    Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{WellConnected = $WellConnected } -ComputerName $Server
                    Write-Output "Successfully changed the property WellConnected on subnet $SubnetID to $WellConnected"
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9204 -Message "Successfully changed the property WellConnected on subnet $SubnetID to $WellConnected" -EntryType Information
                }
                catch {
                    Write-Warning "Failed to change the property WellConnected on subnet $SubnetID to $WellConnected"
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9205 -Message "Failed to change the property WellConnected on subnet $SubnetID to $WellConnected" -EntryType Error
                }
            }

            if ( $DOType -ne 'Not set' ) {
                Write-Debug "Next step - Modify property DOType"
                if ( $DOType -eq 'HTTP Only' ) { [int]$DOType = 0 }
                if ( $DOType -eq 'LAN' ) { [int]$DOType = 1 }
                if ( $DOType -eq 'Group' ) { [int]$DOType = 2 }
                if ( $DOType -eq 'Internet' ) { [int]$DOType = 3 }
                if ( $DOType -eq 'Simple' ) { [int]$DOType = 99 }
                if ( $DOType -eq 'Bypass' ) { [int]$DOType = 100 }
                Write-Verbose "Modified variable: DOType has now the value of $DOType"

                try {
                    Write-Verbose "Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{DODownloadMode = $DOType } -ComputerName $Server"
                    Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{DODownloadMode = $DOType } -ComputerName $Server
                    Write-Output "Successfully changed the property DODownloadMode on subnet $SubnetID to $DOType"
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9204 -Message "Successfully changed the property DODownloadMode on subnet $SubnetID to $DOType" -EntryType Information
                }
                catch {
                    Write-Warning "Failed to change the property DODownloadMode on subnet $SubnetID to $DOType"
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9205 -Message "Failed to change the property DODownloadMode on subnet $SubnetID to $DOType" -EntryType Error
                }
            }

            if ( $SetDOGroupID ) {
                Write-Debug "Next step - Modify property DOGroupID"
                Write-Verbose "Get Subnets ID (not SubnetID): Get-CIMInstance -Namespace $Namespace -Class Subnets -Filter ""SubnetID LIKE '%$SubnetID%'"" -ComputerName $Server"
                $id = $(Get-CIMInstance -Namespace $Namespace -Class Subnets -Filter "SubnetID LIKE '%$SubnetID%'" -ComputerName $Server).id
                Write-Verbose "Subnets ID is = $id"

                try {
                    Write-Verbose "Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{DOGroupID = $id } -ComputerName $Server"
                    Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{DOGroupID = $id } -ComputerName $Server
                    Write-Output "Successfully changed the property DOGroupID on subnet $SubnetID to $id"
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9204 -Message "Successfully changed the property DOGroupID on subnet $SubnetID to $id" -EntryType Information
                }
                catch {
                    Write-Warning "Failed to change the property DOGroupID on subnet $SubnetID to $id"
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9205 -Message "Failed to change the property DOGroupID on subnet $SubnetID to $id" -EntryType Error
                }
            }
        }
    }

} 

function Get-Client {
    
    <#
    .SYNOPSIS
        Get information about the clients available in StifleR.

    .DESCRIPTION
        Pull client details from the server hosting the StifleR Server service.
        Details:
        - This skips the necessity of using WBEMTest or similiar tools to WMIExplorer to get the same information...

    .PARAMETER Client
        Specify the full name (or partial for multiple results) of the client you want to display information about

    .PARAMETER Property
        Use specific properties contained in the WMI class Clients in the StifleR namespace.

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .PARAMETER ExactMatch
        Use this switch if you want to look for the exact match of the specified value of the Client parameter

    .PARAMETER SubnetID
        Use this parameter if you want to display all clients on a specific subnet

    .EXAMPLE
	Get-StiflerClient -Client Client01 -Server 'server01'
        Pull information about the client Client01 from server01

    .EXAMPLE
	'Clien' | Get-StiflerClient -Server server01
        Pull clients with pipeline where ComputerName like 'Clien' from server01
    
    .EXAMPLE
	'Client01' | Get-StiflerClient -Server server01 -ExactMatch
        Pull client with pipeline where ComputerName equals 'Client01' from server01

    .FUNCTIONALITY
        StifleR
    #>

    [cmdletbinding()]
    param (
        [Parameter(Mandatory, HelpMessage = "Specify the client you want to retrieve information about", ValueFromPipeline, ValueFromPipelineByPropertyName,ParameterSetName = "Client")][ValidateNotNullOrEmpty()]
        [string[]]$Client,
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [Parameter(HelpMessage = "Specify specific properties",ParameterSetName = "Subnet")]
        [string]$SubnetID,
        [array]$Property,
        [switch]$ExactMatch
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server

        if ( $Property -ne '*' ) {
            $ClassProperties = $($(Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Clients) | Get-Member).Name
            foreach ( $Prop in $($Property) ) {
                if ( $ClassProperties -notcontains $Prop ) { $MissingProps += "$Prop" }
            }
            if ( $MissingProps.Count -gt 0 ) { 
                $MissingProps = $MissingProps -join ', '
                Write-Error -Message "One or more of the following properties couldn't be found in the Class Clients: $MissingProps"
                break
            }
        }
    
        $defaultProperties = @(‘ComputerName’,'Version','Online')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        if ( $Property -eq '*' ) { $defaultProperties = '*' }
        if ( $Property -ne $Null -and $Property -notcontains '*' ) { $defaultProperties = $Property }

        if ( $SubnetID ) {
            $VerifyIPaddress = $([bool]($SubnetID -as [ipaddress] -and ($SubnetID.ToCharArray() | ?{$_ -eq "."}).count -eq 3))
            if ( $VerifyIPaddress ) {
                if ( Get-Subnet -Server $Server -SubnetID $Target ) { $SubnetIDExist = $True }
            }
        }
    }

    process {
        $ClientInformation = @()
        if ( $ExactMatch ) {
            if ( $SubnetIDExist ) {
                $id = $(Get-CIMInstance -Namespace $Namespace -Class Subnets -Filter "SubnetID LIKE '%$SubnetID%'" -ComputerName $Server).id
                $ClientInformation = Get-CIMInstance -Namespace $Namespace -Class Clients -Filter "LastOnNetwork = '$id'" -ComputerName $Server
            }
            else {
                $ClientInformation = Get-CIMInstance -Namespace $Namespace -Class Clients -Filter "ComputerName = '$Client'" -ComputerName $Server
            }
        }
        else {
            if ( $SubnetIDExist ) {
                $id = $(Get-CIMInstance -Namespace $Namespace -Class Subnets -Filter "SubnetID LIKE '%$SubnetID%'" -ComputerName $Server).id
                $ClientInformation = Get-CIMInstance -Namespace $Namespace -Class Clients -Filter "LastOnNetwork = '$id'" -ComputerName $Server
            }
            else {
                $ClientInformation = Get-CIMInstance -Namespace $Namespace -Class Clients -Filter "ComputerName LIKE '%$Client%'" -ComputerName $Server
            }
        }
        $ClientInformation | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    }

    end {
        $ClientInformation | Select-Object $defaultProperties -ExcludeProperty PSComputerName,Cim*
    }

}

function Get-ClientVersion {

   <#
    .SYNOPSIS
        Gets all settings from the Servers configuration file

    .DESCRIPTION
        Get a summary of StifleR Agent versions
        Details:
        - Get a summary of StifleR Agent versions on clients you have in your environment
        and the number of clients with each version

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	get-StifleRClientVersion -Server server01
        Get the versions for clients from server01

    .FUNCTIONALITY
        StifleR
    #>

    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        $VersionInfo = @()
        $Versions = $(Get-CimInstance -Namespace $Namespace -Query "Select * from Clients" -ComputerName $Server | Select-Object -Unique version ).version
        foreach ( $Version in $Versions ) {
            $VersionCount = $(Get-CimInstance -Namespace $Namespace -Query "Select * from Clients Where Version = '$Version'" -ComputerName $Server ).Count
            $VersionInfo += New-Object -TypeName psobject -Property @{Version=$Version; Clients=$VersionCount}
        }
        $VersionInfo
    }

}

function Get-Download {

   <#
    .SYNOPSIS
        Use this get information about the downloads in StifleR

    .DESCRIPTION
        Get information about downloads
        Details:
        - Get information about downloads

    .PARAMETER Client
        Specify this parameter if you need to instantly terminate the process

    .PARAMETER Property
        Specify which properties to return from the function

    .PARAMETER State
        Specify what state (of the download) to look, available options if used are
        'Caching','Canceled','Connecting','Error','Suspended','Transferring','TransientError' and 'Queued'

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Get-StifleRDownload -Server server01
        Get all downloads for all clients from 'server01'

    .EXAMPLE
	Get-StifleRDownload -Server server01 -Client client01
        Get all downloads for 'client01'

    .EXAMPLE
	Get-StifleRDownload -Server server01 -State Error -Property ComputerName, State, ID
        Get all downloads for all clients that matches the state 'Error' and only returns the properties
        ComputerName, State and ID

    .FUNCTIONALITY
        StifleR
    #>

    [cmdletbinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [string]$Client,
        [array]$Property,
        [ValidateSet('Caching','Canceled','Connecting','Error','Suspended','Transferring','TransientError','Queued')]
        [string]$State
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server

        $defaultProperties = @(‘ComputerName’,'Created','ID','State','StifleRID')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        if ( $Property -ne '*' ) {
            $ClassProperties = $($(Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Downloads ) | Get-Member).Name
            foreach ( $Prop in $($Property) ) {
                if ( $ClassProperties -notcontains $Prop ) { $MissingProps += "$Prop" }
            }
            if ( $MissingProps.Count -gt 0 ) { 
                $MissingProps = $MissingProps -join ', '
                Write-Error -Message "One or more of the following properties couldn't be found in the Class Downloads: $MissingProps"
                break
            }
        }

        if ( $Property -eq '*' ) { $defaultProperties = '*' }
        if ( $Property -ne $Null -and $Property -notcontains '*' ) { $defaultProperties = $Property }

    }

    process {
        $Downloads = @()
        $Downloads = Get-CimInstance -Namespace $Namespace -Query "Select * from Downloads Where ComputerName Like '%$Client%' And State Like '$State%'" -ComputerName $Server | Sort-Object Created
        $Downloads | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    }

    end {
        $Downloads | Select-Object $defaultProperties -ExcludeProperty PSComputerName,Cim*
    }

}

function Get-EventLog {

   <#
    .SYNOPSIS
        Get event logs from StifleR

    .DESCRIPTION
        Get event logs from StifleR
        Details:
        - Get event logs from StifleR

    .PARAMETER MaxEvents
        Specify how many items that this function will try to get, it is not
        the maximum returned results from it!
        Default is 1000

    .PARAMETER EventID
        Specify one or multiple Event IDs to look for

    .PARAMETER Message
        Specify a string to search for in the Data field (a.k.a. Message)

    .PARAMETER LevelDisplayName
        Specify the type of events you want, default is 'All'
        Available options are 'Trace','Debug','Information','Warning','Error','Critical'

    .PARAMETER ProviderName
        Specify the Provider you want to look into for events, default is 'StifleRServer'
        Available options are 'All','StifleR','StifleRBeacon','StifleRClient' and 'StifleRServer'
        
    .PARAMETER StartDate
        Specify a datetime from when you want to search for events
        
    .PARAMETER EndDate
        Specify a datetime until you want to search for events
        
    .PARAMETER ListLog
        Specify this parameter if you want information about the event log
        for StifleR (FileSize, RecordCount etc.).
        When using this parameter all other input will be ignored!

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Get-StiflerEventLog -Server 'server01' -MaxEvents 10 | sort-object Id
        Get the 10 latest events from server01 and sort them by Id, default is
        by ascending TimeCreated

    .EXAMPLE
	Get-StiflerEventLog -Server 'server01' -LevelDisplayName Information -EventID 4821,1506
	-Message Saving -StartDate (Get-Date).AddMinutes(-60)
        Get all events tagged as Information, EventIDs 4821 or 1506, Message contains 'Saving'
        created within the last 60 minutes

    .EXAMPLE
	Get-StiflerEventLog -Server 'server01' -StartDate (Get-Date).AddMinutes(-120) -EndDate (Get-Date).AddMinutes(-60)
        Get all events that happened from 60 to 120 minutes ago

    .FUNCTIONALITY
        StifleR
    #>

    [cmdletbinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [int]$MaxEvents = 1000,
        [array]$EventID,
        [string]$Message,
        [ValidateSet('Trace','Debug','Information','Warning','Error','Critical')]
        [string]$LevelDisplayName,
        [ValidateSet('All','StifleR','StifleRBeacon','StifleRClient','StifleRServer')]
        [string]$ProviderName='StifleRServer',
        [datetime]$StartDate,
        [datetime]$EndDate,
        [switch]$ListLog
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        if ( $ListLog ) {
            Write-Verbose "When you used the parameter -ListLog all other inputs will be ignored!"
            Get-WinEvent -ComputerName $Server -ListLog StifleR | Select-Object *
        }
        else {
            if ( $LevelDisplayName -eq 'Trace' ) { $Level = 0 }
            if ( $LevelDisplayName -eq 'Debug' ) { $Level = 1 }
            if ( $LevelDisplayName -eq 'Error' ) { $Level = 2 }
            if ( $LevelDisplayName -eq 'Warning' ) { $Level = 3 }
            if ( $LevelDisplayName -eq 'Information' ) { $Level = 4 }
            if ( $LevelDisplayName -eq 'Critical' ) { $Level = 5 }

            if ( $ProviderName -eq 'All' ) {
                $FilterXML = "<QueryList><Query><Select Path='StifleR'>*[System[Provider]["
            }
            else {
                $FilterXML = "<QueryList><Query><Select Path='StifleR'>*[System[Provider[@Name='$ProviderName']]["
            }
                        
            If ( $LevelDisplayName ) {
                $FilterXML = "$FilterXML(Level=$Level)"
                $And = $true
            }
            else {
                $FilterXML = "$FilterXML(Level=0 or Level=1 or Level=2 or Level=3 or Level=4 or Level=5)"
                $And = $true            
            }

            if ( $EventID.Count -ge 1 ) {
                [int]$Counter = 0
                foreach ( $Id in $EventID ) {
                    if ( $Counter -eq 0 ) {
                        if ( $And -eq $true ) {
                            $FilterXML = "$FilterXML and (EventID=$Id"
                        }
                        else {
                            $FilterXML = "$FilterXML(EventID=$Id"
                            $And -eq $true
                        }
                    }
                    else {
                        $FilterXML = "$FilterXML or EventID=$Id"
                    }
                    $Counter++
                }
                $FilterXML = "$FilterXML)"
                $And = $true
            }

            $FilterXML = "$FilterXML]]</Select></Query></QueryList>"
            Write-Verbose "FilterXML string : $FilterXML"

            try {
                [array]$Events = Get-WinEvent -ComputerName $Server -MaxEvents $MaxEvents -FilterXML $FilterXML -ErrorAction Stop #| out-null

                if ( $StartDate -or $EndDate ) {
                    if ( $StartDate -and !$EndDate) {
                        $Events = $Events | Where-Object TimeCreated -ge $StartDate
                    }

                    if ( !$StartDate -and $EndDate) {
                        $Events = $Events | Where-Object TimeCreated -le $EndDate
                    }

                    if ( $StartDate -and $EndDate ) {
                        $Events = $Events | Where-Object { $_.TimeCreated -le $EndDate -and $_.TimeCreated -ge $StartDate }
                    }
                }

                if ( $Message ) {
                    $Events = $Events | Where-Object Message -like "*$Message*" | Sort-Object TimeCreated
                }
                if ( $Events.Count -eq 0 ) {
                    Write-Warning "No events found with the matching criterias, aborting!"
                }
                else {
                    $Events | Sort-Object TimeCreated
                }
            }
            catch {
                if ( $Events.Count -eq 0 ) {
                    Write-Warning "No events found with the matching criterias, aborting!"
                }
            }
        }
    }

}

function Get-Leader {

   <#
    .SYNOPSIS
        Use this to get a list of leaders (Red\Blue)

    .DESCRIPTION
        Use this to get a list of leaders (Red\Blue)
        Details:
        - Use this to get a list of leaders (Red\Blue)

    .PARAMETER SubnetID (Alias NetworkID)
        Specify this parameter if you need to instantly terminate the process

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Get-StifleRLeader -Server 'sserver01'
        Stops the StifleRServer service on server01

    .FUNCTIONALITY
        StifleR
    #>

    [cmdletbinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [Alias('NetworkID')]
        [string]$SubnetID
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        if ( $SubnetID ) {
            $QueryAddition = "WHERE NetworkID Like '%$SubnetID%'"
        }
        $Leaders = @()
        [array]$RedLeaders = Get-CimInstance -Namespace $Namespace -Query "Select * from RedLeaders $QueryAddition" -ComputerName $Server | Select-Object * -ExcludeProperty PSComputerName,PSShowComputerName,CimClass,CimInstanceProperties,CimSystemProperties
        if ( $RedLeaders.Count -gt 0 ) {
            $RedLeaders | Add-Member -Name 'LeaderType' -Value 'Red' -MemberType NoteProperty | out-null
            $Leaders += $RedLeaders
        }                
        [array]$BlueLeaders = Get-CimInstance -Namespace $Namespace -Query "Select * from BlueLeaders $QueryAddition" -ComputerName $Server | Select-Object * -ExcludeProperty PSComputerName,PSShowComputerName,CimClass,CimInstanceProperties,CimSystemProperties
        if ( $BlueLeaders.Count -gt 0 ) {
            $BlueLeaders | Add-Member -Name 'LeaderType' -Value 'Blue' -MemberType NoteProperty | out-null
            $Leaders += $BlueLeaders
        }
        $Leaders | Sort-Object NetworkID
    }

}

function Get-LicenseInformation {

   <#
    .SYNOPSIS
        Use this to get information about your StifleR license

    .DESCRIPTION
        Information about your StifleR License
        Details:
        - Information about your StifleR License

    .PARAMETER InstallDir
        Specify the Installation directory for StifleR Server,
        default is 'C$\Program Files\2Pint Software\StifleR'

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Get-StiflerLicenseInformation -Server server01
        Get information from License.nfo file on server01

    .FUNCTIONALITY
        StifleR
    #>

    [cmdletbinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [string]$InstallDir='C$\Program Files\2Pint Software\StifleR'
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        try {
            Write-Verbose "Get content from license file : (Get-Content ""\\$Server\$InstallDir\License.nfo"").Where({ $_ -eq '[Licensing]'},'SkipUntil')"
            $Content = (Get-Content "\\$Server\$InstallDir\License.nfo").Where({ $_ -eq '[Licensing]'},'SkipUntil')
            $LicenseProperties = [PSCustomObject]@{}
            foreach ( $LicProp in $Content ) {
                if ( $LicProp -ne '[Licensing]' ) {
                    $Attrib = $LicProp.Split('=')
                    $LicenseProperties | Add-Member -Name $Attrib[0] -Value $Attrib[1] -MemberType NoteProperty
                }
            }
            $LicenseProperties | Add-Member -Name 'DaysLeft' -Value $(New-TimeSpan -Start (get-date) -End $LicenseProperties.ExpiryDate).Days -MemberType NoteProperty
            $LicenseProperties
        }
        catch {
            Write-Warning "Failed to get information from the license file on server $Server"
        }
    }

}

function Get-ServerSettings {

   <#
    .SYNOPSIS
        Gets all settings from the Servers configuration file

    .DESCRIPTION
        Gets all values from servers configuration file
        Details:
        - GGets all values from servers configuration file

    .PARAMETER InstallDir
        Specify the Installation directory for StifleR Server,
        default is 'C$\Program Files\2Pint Software\StifleR'
      
    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	get-StifleRServerSettings -Server server01
        Get the settings from server01

    .EXAMPLE
	Get-StifleRServerSettings -Server server01 -InstallDir
    'D$\Program Files\2Pint Software\StifleR'
        Get the settings from server01 where the installations directory for StifleR Server is
        'D$\Program Files\2Pint Software\StifleR' instead of the default directory

    .FUNCTIONALITY
        StifleR
    #>

    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [string]$InstallDir='C$\Program Files\2Pint Software\StifleR',
        [switch]$SortByKeyName
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        try {
            [xml]$Content = Get-Content "\\$Server\$InstallDir\StifleR.Service.exe.config" -ErrorAction 1
            $Properties = @()
            $Properties += $Content.configuration.appSettings.add
            $obj = new-object PSObject
            foreach ( $Prop in $Properties | Sort-Object Key ) {
                $obj | Add-Member -MemberType NoteProperty -Name $Prop.key -Value $Prop.value
            }            
            return $obj
        }
        catch {
            Write-Error "Failed to obtain properties from $Server, check InstallDir and access permissions."
        }
    }

}

function Get-ServerDebugLevel {

   <#
    .SYNOPSIS
        Same as Set-StifleRServerDebugLevel, but only gets the current value

    .DESCRIPTION
        Gets the current value of debug level for StifleR Server
        Details:
        - Gets the current value of debug level for StifleR Server

    .PARAMETER InstallDir
        Specify the Installation directory for StifleR Server,
        default is 'C$\Program Files\2Pint Software\StifleR'
        
    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	get-StifleRServerDebugLevel -Server server01
        Get the current debug level on server01

    .EXAMPLE
	Get-StifleRServerDebugLevel -Server server01 -InstallDir
    'D$\Program Files\2Pint Software\StifleR'
        Get the current debug level on server01 where the installations directory for StifleR Server is
        'D$\Program Files\2Pint Software\StifleR' instead of the default directory

    .FUNCTIONALITY
        StifleR
    #>

    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [string]$InstallDir='C$\Program Files\2Pint Software\StifleR'
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        try {
            [xml]$Content = Get-Content "\\$Server\$InstallDir\StifleR.Service.exe.config" -ErrorAction 1
            $CurrentValue = ($Content.configuration.appSettings.add | Where-Object { $_.Key -eq 'EnableDebugLog' }).Value
            if ( $CurrentValue -eq '0' ) { $DebugLevel = '0 (Disabled)' }
            if ( $CurrentValue -eq '1' ) { $DebugLevel = '1 (Errors Only)' }
            if ( $CurrentValue -eq '2' ) { $DebugLevel = '2 (Warning)' }
            if ( $CurrentValue -eq '3' ) { $DebugLevel = '3 (OK)' }
            if ( $CurrentValue -eq '4' ) { $DebugLevel = '4 (Information)' }
            if ( $CurrentValue -eq '5' ) { $DebugLevel = '5 (Debug)' }
            if ( $CurrentValue -eq '6' ) { $DebugLevel = '6 (Super Verbose)' }
            Write-Output "DebugLevel for StifleR Server is: $DebugLevel"
        }
        catch {
            Write-Error "Failed to obtain properties from $Server, check InstallDir and access permissions."
        }
    }
        
}

function Get-SignalRHubHealth {

    <#
    .SYNOPSIS
        Get statistics about Signal-R

    .DESCRIPTION
        Get statistics about Signal-R

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
    Get-StifleRSIgnalRHubHealth -Server 'server01'
    Get statistics about Signal-R

    .FUNCTIONALITY
        StifleR
    #>

    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        Get-CIMInstance -Namespace $Namespace -Query "Select * from StiflerEngine WHERE id = 1" -ComputerName $Server | FL -property NumberOfClients, ActiveNetworks, ActiveRedLeaders,HubConnectionInitiated,HubConnectionCompleted,ClientINfoInitiated, ClientInfoCompleted, JobReportInitiated ,JobReportCompleted,JobReporDeltatInitiated,JobReportDeltaCompleted
    }

}

function Get-Subnet {

    <#
    .SYNOPSIS
        Get information about the subnets available in StifleR.

    .DESCRIPTION
        Pull subnet details from the server hosting the StifleR Server service.
        Details:
        - This skips the necessity of using WBEMTest or similiar tools to WMIExplorer to get the same information...

    .PARAMETER Identity (LocationName)
        One or more subnets to show information from.

    .PARAMETER SubnetID
        If this property is added, or if all properties are selected (* by defualt), Red- and BlueLeader will be added per subnet as well.

    .PARAMETER Property
        Use specific properties contained in the WMI class Subnet in the StifleR namespace.

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .PARAMETER ShowRedLeader
        Use this switch if you want to show Red leader per subnet

    .PARAMETER ShowBlueLeader
        Use this switch if you want to show Blue leader per subnet

    .EXAMPLE
        Get-StiflerSubnet -Identity '21-*' -Server 'server01' | Format-Table -AutoSize
        Pull subnets with locationname like '21-' from server01

    .EXAMPLE
        '172.16' | Get-StiflerSubnet -Server 'server01' | Select-Object -uUnique LocationName, ActiveClients, AverageBandwidth, RedLeader, BlueLeader | Format-Table -AutoSize
        Pull subnets with pipeline where subnetID like '172.16' from server01 and show current red-/blue leader
    
    .EXAMPLE
        Get-StiflerSubnet -Server 'sever01' -Property LocationName, ActiveClients, AverageBandwidth, SubnetID | Select LocationName, SubnetID, ActiveClients, AverageBandwidth, RedLeader, BlueLeader | Where ActiveClients -gt 0 | Sort AverageBandwidth, LocationName -Descending | Format-Table -AutoSize
        Pull all subnets from sever01 with specific properties and sorts them based on AverageBandwidth

    .FUNCTIONALITY
        StifleR
    #>

    [CmdletBinding()]
    param (
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage = "This parameter is used if you want to query SubnetID(s)")]
        [String]$SubnetID='*',
        [Parameter(HelpMessage = "This parameter is used if you want to query LocationName(s)")]
        [Alias('Identity')]
        [String]$LocationName='*',
        [Parameter(Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [Parameter(HelpMessage = "This parameter is used if you want to query for specific properties")]
        [Array]$Property,
        [switch]$ShowRedLeader,
        [switch]$ShowBlueLeader
    )

    begin {
        $MissingProps = @()
        $ClassProperties = @()
        $SubnetInfo = @()

        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server

        # Check if the specified properties exists in the Subnet class
        if ( $Property -ne '*' ) {
            $ClassProperties = $($(Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets) | Get-Member).Name
            foreach ( $Prop in $($Property) ) {
                if ( $ClassProperties -notcontains $Prop ) { $MissingProps += "$Prop" }
            }
            if ( $MissingProps.Count -gt 0 ) { 
                $MissingProps = $MissingProps -join ', '
                Write-Error -Message "One or more of the following properties couldn't be found in the Class Subnets: $MissingProps"
                break
            }
        }
    }

    process {
        # Sets what default properties should be displayed
        $defaultProperties = @(‘SubnetID’,’LocationName','TargetBandwidth','LEDBATTargetBandwidth','WellConnected','Clients','ActiveClients','VPN')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        if ( $Property -eq '*' ) { $defaultProperties = '*' }
        if ( $Property -ne $Null -and $Property -notcontains '*' ) { $defaultProperties = $Property }

        # Replace Windows wildcards with WMI specific wildcards
        $LocationName = $LocationName.Replace('*','%')
        $LocationName = $LocationName.Replace('?','_')
        $SubnetID = $SubnetID.Replace('*','%')
        $SubnetID = $SubnetID.Replace('?','_')

        # Queries the StifleR server for the subnet information
        $SubnetInfo = Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Property $Property -Filter "LocationName LIKE '%$($LocationName)%' AND SubnetID LIKE '%$($SubnetID)%'"
        
        # If the switches ShowRedLeader or ShowBlueLeader is used, then add that information per subnet
        if ( $ShowRedLeader ) {
            foreach ( $Subnet in $SubnetInfo ) {
                $Subnet | Add-Member -MemberType NoteProperty -Name 'RedLeader' -Value "$($(Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class 'RedLeaders' -Filter "NetworkID LIKE '%$($Subnet.subnetID)%'").ComputerName)"
            }
            $defaultProperties += 'RedLeader'
        }
        if ( $ShowBlueLeader ) {
            foreach ( $Subnet in $SubnetInfo ) {
                $Subnet | Add-Member -MemberType NoteProperty -Name 'BlueLeader' -Value "$($(Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class 'BlueLeaders' -Filter "NetworkID LIKE '%$($Subnet.subnetID)%'").ComputerName)"
            }
            $defaultProperties += 'BlueLeader'
        }
    }

    end {
        # Returns the results collected
        $SubnetInfo | Add-Member MemberSet PSStandardMembers $PSStandardMembers
        $SubnetInfo | Select-Object $defaultProperties -ExcludeProperty PSComputerName,Cim*
    }

}

function Get-SubnetQueue {

    <#
    .SYNOPSIS
        Get information about the subnet queues in StifleR

    .DESCRIPTION
        Get information about the subnet queues in StifleR

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
    Get-StifleRSubnetQUeue -server 'server01'
    Get information about the current queues in StifleR

    .FUNCTIONALITY
        StifleR
    #>

    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        $Clients = Get-CIMInstance -Namespace $Namespace -Query "Select * from Clients" -ComputerName $Server | Select-Object TotalQueueSize_BITS, TotalQueueSize_DO, NetworkID
        $Clients | Group-Object NetworkID | %{
            New-Object psobject -Property @{
                NetworkID = $_.Name
                BITSTotal =“{0:N2}” -f (($_.Group | Measure-Object TotalQueueSize_BITS -Sum).Sum /1MB)
                DOTotal = “{0:N2}” -f(($_.Group | Measure-Object TotalQueueSize_DO -Sum).Sum /1MB)
                Clients = $_.Count
            }
        } |  Sort-Object -Property Clients | FT -AutoSize
        Write-Output "Total Client Count: " $Clients.count
    }

}

function Remove-Client {

   <#
    .SYNOPSIS
        Use this to remove client(s) from StifleR

    .DESCRIPTION
        Just another way of remvoing client(s) from StifleR
        Details:
        - Easily remove one or more of your clients through Powershell

    .PARAMETER Client
        Specify the ComputerName (or part of) of the client(s) you want to
        remove
        
    .PARAMETER Flush
        Specify this if a flush of the object should be performed, default is false
        
    .PARAMETER SkipConfirm
        Specify this switch if you don't want to confirm the removal
        of found clients
        
    .PARAMETER Quiet
        Specify this parameter if you don't want any status message
        about the result

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Remove-StiflerClient -Server server01 -Client Client1 -SkipConfirm -Quite
        Removes the client Client1 and hides the confirmation
        dialog as well as the successful result message

    .EXAMPLE
	Remove-StiflerClient -Server server01 -Client Client1 -Flush
        Removes the client 'Client1' and flushes something...

    .EXAMPLE
	Remove-StiflerClient -Server server01 -Client MININT-
        Removes all clients containing 'MININT-' as ComputerName

    .FUNCTIONALITY
        StifleR
    #>

    [cmdletbinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [Parameter(Mandatory=$true)]
        [string]$Client,
        [switch]$Flush,
        [switch]$Quiet,
        [switch]$SkipConfirm
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        Write-Verbose "Variable - Flush : $Flush"
        if ( $Flush ) {
            $Arguments = @{ flush = $true }
        }
        else {
            $Arguments = @{ flush = $false }
        }

        [array]$Clients = $(Get-CimInstance -Namespace $Namespace -Query "Select ComputerName from Clients WHERE ComputerName LIKE '%$Client%'" -ComputerName $Server).ComputerName

        if ( $Clients.Count -le 0 ) {
            Write-Warning "No clients found matching the input parameters, aborting!"
            break
        }

        if ( !$SkipConfirm ) {
            Write-Output "You are about to delete $($Clients.Count) client(s) listed below:"
            Write-Output " "
            foreach ( $Client in $Clients ) {
                Write-Output "Client: $Client"
            }
            Write-Output " "
            $msg = "Are you sure? [Y/N]"
            do {
                $response = Read-Host -Prompt $msg
            } until ($response -eq 'n' -or $response -eq 'y')
            if ( $response -eq 'n' ) {
                break
            }
            Write-Output " "
        }

        Write-Debug "Next step - Removing clients"
        foreach ( $Client in $Clients ) {
            try {
                Write-Verbose "Invoke-CimMethod -Namespace $Namespace -Query ""SELECT * FROM Clients Where ComputerName = '$Client'"" -MethodName RemoveFromDB -ComputerName $Server -Arguments $Arguments | out-null"
                Invoke-CimMethod -Namespace $Namespace -Query "SELECT * FROM Clients Where ComputerName = '$Client'" -MethodName RemoveFromDB -ComputerName $Server -Arguments $Arguments | out-null
                if ( !$Quiet ) {
                    Write-Output "Successfully removed client: $Client"
                }
                Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9216 -Message "Successfully removed client $Client" -EntryType Information
            }
            catch {
                Write-Warning "Failed to remove client: $Client"
                if ( !$Quiet ) {
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9217 -Message "Failed to remove client $Client" -EntryType Error
                }
            }
        }
    }

}

function Remove-Subnet {

   <#
    .SYNOPSIS
        Use this to remove a subnet from StifleR

    .DESCRIPTION
        Just another way of remvoing a subnet from StifleR
        Details:
        - Easily remove one or more of your subnets through Powershell

    .PARAMETER LocationName
        Specify the LocationName (or part of) of the subnet(s) you want
        to remove
        
    .PARAMETER SubnetID
        Specify the SubnetID (or part of) of the subnet(s) you want to
        remove
        
    .PARAMETER DeleteChildren
        Specify this if all linked childsubnets should be removed in
        the process as well, default is false
        
    .PARAMETER SkipConfirm
        Specify this switch if you don't want to confirm the removal
        of found subnets
        
    .PARAMETER Quiet
        Specify this parameter if you don't want any status message
        about the result

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Remove-StiflerSubnet -Server server01 -SubnetID 172.10.10.0 -SkipConfirm -Quite
        Removes the subnet with SubnetID 172.10.10.0 and hides the confirmation
        dialog as well as the successful result message

    .EXAMPLE
	Remove-StiflerSubnet -Server server01 -LocationName TESTNET -DeleteChildren
        Removes the subnet with the LocationName TESTNET and deletes (if any) the
        childobjects of this subnet

    .EXAMPLE
	Remove-StiflerSubnet -Server server01 -SubnetID 172
        Prompts a question about removing all subnets with SubnetID like 172

    .FUNCTIONALITY
        StifleR
    #>

    [CmdletBinding()]
    param (
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ValueFromRemainingArguments=$true,Mandatory=$true,ParameterSetName = "LocationName")]
        [Alias('Identity')]
        [String]$LocationName,
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [Parameter(Position=2,Mandatory=$true,ParameterSetName = "SubnetID")]
        [String]$SubnetID,
        [switch]$DeleteChildren,
        [switch]$SkipConfirm,
        [switch]$Quiet
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        Write-Verbose "Variable - DeleteChildren : $DeleteChildren"
        if ( $DeleteChildren ) {
            $Arguments = @{ DeleteChildren = $true }
        }
        else {
            $Arguments = @{ DeleteChildren = $false }
        }
        
        Write-Debug "Next step - Get subnets to verify existence" 
        if ( $PsCmdlet.ParameterSetName -eq 'LocationName' ) {
            Write-Verbose "Getting subnet(s) by LocationName - Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Filter ""LocationName LIKE '%$LocationName%'"""
            [array]$Subnets = Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Filter "LocationName LIKE '%$LocationName%'"
        }
        else {
            Write-Verbose "Getting subnet(s) by SubnetID - Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Filter ""SubnetID LIKE '%$SubnetID%'"""
            [array]$Subnets = Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Filter "SubnetID LIKE '%$SubnetID%'"
        }

        if ( $Subnets.Count -le 0 ) {
            Write-Warning "No subnets found matching the input parameters, aborting!"
            break
        }

        Write-Verbose "Variable - SkipConfirm : $SkipCOnfirm"
        if ( !$SkipConfirm ) {
            Write-Output "You are about to delete $($Subnets.Count) subnet(s) listed below:"
            Write-Output " "
            foreach ( $Subnet in $Subnets ) {
                Write-Output "SubnetID: $($Subnet.SubnetID) LocationName: $($Subnet.LocationName)"
            }
            Write-Output " "
            $msg = "Are you sure? [Y/N]"
            do {
                $response = Read-Host -Prompt $msg
            } until ($response -eq 'n' -or $response -eq 'y')
            if ( $response -eq 'n' ) {
                break
            }
            Write-Output " "
        }
        
        foreach ( $Subnet in $Subnets ) {
            if ( $PsCmdlet.ParameterSetName -eq 'LocationName' ) {
                Write-Debug "Next step - Removing subnet based on LocationName"
            }
            else {
                Write-Debug "Next step - Removing subnet based on SubnetID"
            }

            try {
                if ( $PsCmdlet.ParameterSetName -eq 'LocationName' ) {
                    Write-Verbose "Removing subnet: Invoke-CimMethod -Namespace $Namespace -Query ""SELECT * FROM Subnets Where LocationName = '$($Subnet.LocationName)'"" -MethodName RemoveSubnet -ComputerName $Server -Arguments $Arguments | out-null"
                    Invoke-CimMethod -Namespace $Namespace -Query "SELECT * FROM Subnets Where LocationName = '$($Subnet.LocationName)'" -MethodName RemoveSubnet -ComputerName $Server -Arguments $Arguments | out-null
                }
                else {
                    Write-Verbose "Removing subnet: Invoke-CimMethod -Namespace $Namespace -Query ""SELECT * FROM Subnets Where SubnetID = '$($Subnet.SubnetID)'"" -MethodName RemoveSubnet -ComputerName $Server -Arguments $Arguments | out-null"
                    Invoke-CimMethod -Namespace $Namespace -Query "SELECT * FROM Subnets Where SubnetID = '$($Subnet.SubnetID)'" -MethodName RemoveSubnet -ComputerName $Server -Arguments $Arguments | out-null
                }
                if ( !$Quiet ) {
                    Write-Output "Successfully removed SubnetID: $($Subnet.SubnetID) LocationName: $($Subnet.LocationName)"
                }
                Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9206 -Message "Successfully removed subnet $($Subnet.SubnetID) (LocationName: $($Subnet.LocationName)) with the argument DeleteChildren = $DeleteChildren" -EntryType Information
            }
            catch {
                Write-Warning "Failed to remove SubnetID: $($Subnet.SubnetID) LocationName: $($Subnet.LocationName)"
                if ( !$Quiet ) {
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9207 -Message "Failed to remove subnet $($Subnet.SubnetID) (LocationName: $($Subnet.LocationName)) with the argument DeleteChildren = $DeleteChildren" -EntryType Error
                }
            }
        }
    }

}

function Set-Job {

    <#
    .SYNOPSIS
        Use this to cancel, complete, resume or suspend the downloads in StifleR.

    .DESCRIPTION
        If you need to push the big red button, go no further!
        Details:
        - This skips the necessity of using WBEMTest or similiar tools to WMIExplorer to get the same functionality...

    .PARAMETER Target (Identity)
        Specify the client or subnetID that will be targeted for the action, this parameter can't be used in combination with TargetLevel All

    .PARAMETER TargetLevel
        Specify what kind of target you would like, a single Client, a specific SubnetID och All

    .PARAMETER Action
        Specify if you want to Cancel, Complete, Resume or Suspend all jobs

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Set-StiflerJob -Server server01 -TargetLevel Subnet -Action Cancel -Target 192.168.20.2
        Cancels all current transfers on the subnet 192.168.20.2

    .EXAMPLE
	Set-StiflerJob -Server server01 -TargetLevel Client -Action Suspend -Target Client01
        Suspends all current transfers on the client Client01
    
    .EXAMPLE
	Set-StiflerJob -Server server01 -TargetLevel All -Action Resume
        Resumes all the transfers known to StifleR as suspended earlier on all subnets

    .FUNCTIONALITY
        StifleR
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = 'Choose what action you want to perform: Cancel, Complete, Resume or Suspend')]
        [Alias('Identity')]
        [string]$Target,
        [Parameter(Mandatory, HelpMessage = 'Choose what level you want to target: Client, Subnet or All')][ValidateSet('Client','Subnet','All')]
        [string]$TargetLevel,
        [Parameter(Mandatory, HelpMessage = 'Choose what action you want to perform: Cancel, Complete, Resume or Suspend')][ValidateSet('Cancel','Complete','Resume','Suspend')]
        [string]$Action,
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        if ( $TargetLevel -eq 'Subnet' ) {
            if ( $([bool]($Target -as [ipaddress] -and ($Target.ToCharArray() | ?{$_ -eq "."}).count -eq 3)) ) {
                if ( Get-Subnet -Server $Server -SubnetID $Target ) {
                    $Confirm = Read-Host "You are about to $Action all transfers for $Target, are you really sure? [y/n]"
                    while($Confirm -ne "y") {
                        if ($Confirm -eq 'n') { Write-Warning "This command was cancelled by the user, aborting!" ; break }
                        $Confirm = Read-Host "You are about to $Action all transfers for $Target, are you really sure? [y/n]"
                    }
                    if ( $Confirm -eq 'y' ) {
                        $TriggerTarget = $Target
                        $TriggerHappy = $True
                    }
                }
                else { Write-Error "The SubnetID $Target couldn't be found in StifleR" }
            }
            else { Write-Error "The property Target ($Target) is not a correct IP address" }
        }

        if ( $TargetLevel -eq 'Client' ) {
            if ( Get-Client -Server $Server -Client $Target -ExactMatch ) {
                $Confirm = Read-Host "You are about to $Action all transfers for $Target, are you really sure? [y/n]"
                while($Confirm -ne 'y') {
                    if ($Confirm -eq 'n') { Write-Warning "This command was cancelled by the user, aborting!" ; break }
                    $Confirm = Read-Host "You are about to $Action all transfers for $Target, are you really sure? [y/n]"
                }
                if ( $Confirm -eq 'y' ) {
                    $TriggerTarget = $Target
                    $TriggerHappy = $True
                }
            }
            else { Write-Error "The Client $Target couldn't be found in StifleR" }
        }

        if ( $TargetLevel -eq 'All' ) {
            if ( $Target -ne "" ) { Write-Error "The parameter Target can't be used when All is selected as TargetLevel" ; break }
        
            $Confirm = Read-Host "You are about to $Action ALL transfers, are you really sure? [y/n]"
            while($Confirm -ne "y") {
                if ($Confirm -eq 'n') { Write-Output "This command was cancelled by the user, aborting!" ; break }
                $Confirm = Read-Host "You are about to $Action ALL transfers, are you really sure? [y/n]"
            }
            if ( $Confirm -eq 'y' ) {
                $TriggerTarget = 'All'
                $TriggerHappy = $True
            }
        }

        if ( $TriggerHappy ) {
            Write-Debug "Next step : $Action BITSJob for $TriggerTarget"
            Write-Verbose "Trigger BITSJob Action : Invoke-WMIMethod -Namespace $Namespace -Path StifleREngine.Id=1 -Name ModifyJobs -ArgumentList ""$Action"", False, ""*"", 0, ""$TriggerTarget"" -ComputerName $Server | out-null"
            try {
                Invoke-WMIMethod -Namespace $Namespace -Path StifleREngine.Id=1 -Name ModifyJobs -ArgumentList "$Action", False, "*", 0, "$TriggerTarget" -ComputerName $Server | out-null
                Write-Output "Successfully invoked BITSJob change with the following parameters: Action: $Action   Triggertarget: $TriggerTarget"
                Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9200 -Message "Successfully invoked BITSJob change with the following parameters: Action: $Action   Triggertarget: $TriggerTarget" -EntryType Information
            }            
            catch {
                Write-Warning "Failed to invoke BITSJob change with the following parameters: Action: $Action   Triggertarget: $TriggerTarget"
                Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9201 -Message "Failed to invoke BITSJob change with the following parameters: Action: $Action   Triggertarget: $TriggerTarget" -EntryType Error
            }
        }
    }

}

function Set-ServerDebugLevel {

   <#
    .SYNOPSIS
        Use this to change debuglevel for StifleR Server

    .DESCRIPTION
        Easily set the debuglevel for StifleR Server
        Details:
        - Easily set the debuglevel for StifleR Server

    .PARAMETER InstallDir
        Specify the Installation directory for StifleR Server,
        default is 'C$\Program Files\2Pint Software\StifleR'
        
    .PARAMETER DebugLevel
        Specify what the new DebugLevel should be
        
    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Set-StifleRServerDebugLevel -Server server01 -DebugLevel '6.Super Verbose'
        Enable Super verbose debugging on server01

    .EXAMPLE
	Set-StifleRServerDebugLevel -Server server01 -DebugLevel '0.Disabled' -InstallDir
    'D$\Program Files\2Pint Software\StifleR'
        Disable debugging on server01 where the installations directory for StifleR Server is
        'D$\Program Files\2Pint Software\StifleR' instead of the default directory

    .FUNCTIONALITY
        StifleR
    #>

    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [string]$InstallDir='C$\Program Files\2Pint Software\StifleR',
        [Parameter(Mandatory=$true)][ValidateSet('0.Disabled','1.Errors Only','2.Warning','3.OK','4.Informative','5.Debug','6.Super Verbose')]
        [string]$DebugLevel
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        Write-Verbose "Variable - DebugLevel : $DebugLevel"
        if ( $DebugLevel -eq '0.Disabled' ) { [string]$DebugLevel = '0' }
        if ( $DebugLevel -eq '1.Errors Only' ) { [string]$DebugLevel = '1' }
        if ( $DebugLevel -eq '2.Warning' ) { [string]$DebugLevel = '2' }
        if ( $DebugLevel -eq '3.OK' ) { [string]$DebugLevel = '3' }
        if ( $DebugLevel -eq '4.Informative' ) { [string]$DebugLevel = '4' }
        if ( $DebugLevel -eq '5.Debug' ) { [string]$DebugLevel = '5' }
        if ( $DebugLevel -eq '6.Super Verbose' ) { [string]$DebugLevel = '6' }
        Write-Verbose "Variable - DebugLevel (corresponding number): $DebugLevel"

        Write-Verbose "Get content from config: Get-Content ""\\$Server\$InstallDir\StifleR.Service.exe.config"""
        [xml]$Content = Get-Content "\\$Server\$InstallDir\StifleR.Service.exe.config"
        $CurrentValue = ($Content.configuration.appSettings.add | Where-Object { $_.Key -eq 'EnableDebugLog' }).Value
        Write-Verbose "Variable - CurrentValue : $CurrentValue"
        if ( $DebugLevel -eq $CurrentValue ) {
            Write-Warning "This DebugLevel is already active, aborting!"
            break
        }
        $($Content.configuration.appSettings.add | Where-Object { $_.Key -eq 'EnableDebugLog' }).value = $DebugLevel

        Write-Debug "Next step - Set debug level"
        try {
            Write-Verbose "Get config file : [string]$Content = Get-Content ""\\$Server\$InstallDir\StifleR.Service.exe.config"" -Raw"
            [string]$Content = Get-Content "\\$Server\$InstallDir\StifleR.Service.exe.config" -Raw
            Write-Verbose "Replacing and saving content : $Content.Replace(""add key=""EnableDebugLog"" value=""$CurrentValue"",""add key=""EnableDebugLog"" value=""$DebugLevel"") | out-file ""\\$Server\$InstallDir\StifleR.Service.exe.config"" -Encoding utf8 -Force -NoNewline"
            $Content.Replace("add key=""EnableDebugLog"" value=""$CurrentValue""","add key=""EnableDebugLog"" value=""$DebugLevel""") | out-file "\\$Server\$InstallDir\StifleR.Service.exe.config" -Encoding utf8 -Force -NoNewline
            Write-Output "Successfully updated DebugLevel in StifleR Server from $CurrentValue to $DebugLevel."
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9210 -Message "Successfully updated DebugLevel in StifleR Server from $CurrentValue to $DebugLevel." -EntryType Information
        }
        catch {
            Write-Warning "Failed to update DebugLevel in StifleR Server from $CurrentValue to $DebugLevel."
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9211 -Message "Failed to update DebugLevel in StifleR Server from $CurrentValue to $DebugLevel." -EntryType Error
        }
    }
        
}

function Set-ServerSettings {

   <#
    .SYNOPSIS
        Use this to change properties values for StifleR Server

    .DESCRIPTION
        Easily set new values for properties on StifleR Server
        Details:
        - Easily set new values for properties on StifleR Server

    .PARAMETER Property
        Specify which property you want to change
        
    .PARAMETER NewValue
        Specify the new value of the chosen property

    .PARAMETER SkipConfirm
        Specify this switch if you don't want to confirm the change
        of the properties value

    .PARAMETER Clear
        Specify this switch to clear the value of a property

    .PARAMETER InstallDir
        Specify the Installation directory for StifleR Server,
        default is 'C$\Program Files\2Pint Software\StifleR'
        
    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Set-StifleRServerSettings -Server server01 -Property wsapifw -NewValue 1
        Sets the property wsapifw to 1 in StifleR Server

    .EXAMPLE
	Set-StifleRServerSettings -Server server01 -Property wsapifw -NewValue 1 -SkipConfirm
        Sets the property wsapifw to 1 in StifleR Server without asking for confirmation

    .EXAMPLE
	Set-StifleRServerSettings -Server server01 -Property wsapifw -Clear
        Sets the property wsapifw to nothing in StifleR Server

    .FUNCTIONALITY
        StifleR
    #>

    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [string]$InstallDir='C$\Program Files\2Pint Software\StifleR',
        [Parameter(Mandatory=$true)]
        [string]$Property,
        [Parameter(Mandatory=$true,ParameterSetName = "NewValue")]
        [string]$NewValue,
        [string]$SkipConfirm,
        [Parameter(Mandatory=$true,ParameterSetName = "Clear")]
        [switch]$Clear
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        Write-Verbose "Get content from config: Get-Content ""\\$Server\$InstallDir\StifleR.Service.exe.config"""
        [xml]$Content = Get-Content "\\$Server\$InstallDir\StifleR.Service.exe.config"
        $CurrentKeyName = ($Content.configuration.appSettings.add | Where-Object { $_.Key -eq $Property }).key
        Write-Verbose "Variable - CurrentKeyName : $CurrentKeyName"
        if ( !$CurrentKeyName ) {
            Write-Warning "The property '$Property' does not exist, aborting!"
            break
        }
        $CurrentValue = ($Content.configuration.appSettings.add | Where-Object { $_.Key -eq $Property }).Value
        Write-Verbose "Variable - CurrentValue : $CurrentValue"
        if ( $NewValue -eq $CurrentValue ) {
            Write-Warning "The property '$Property' already has the value '$NewValue', aborting!"
            break
        }
        if ( !$SkipConfirm ) {
            Write-Output "You are about to change the property '$Property' from '$CurrentValue' to '$NewValue'."
            Write-Warning "Make sure this change is valid or things might break..."
            Write-Output " "
            $msg = "Apply change? [Y/N]"
            do {
                $response = Read-Host -Prompt $msg
            } until ($response -eq 'n' -or $response -eq 'y')
            if ( $response -eq 'n' ) {
                break
            }
            Write-Output " "
        }

        Write-Debug "Next step - Set server settings"
        try {
            Write-Verbose "Get config file : [string]$Content = Get-Content ""\\$Server\$InstallDir\StifleR.Service.exe.config"" -Raw"
            [string]$Content = Get-Content "\\$Server\$InstallDir\StifleR.Service.exe.config" -Raw
            Write-Verbose "Replacing and saving content : $Content.Replace(""add key=""$CurrentKeyName"" value=""$CurrentValue""","add key=""$CurrentKeyName"" value=""$NewValue"""") | out-file ""\\$Server\$InstallDir\StifleR.Service.exe.config"" -Encoding utf8 -Force -NoNewline"
            $Content.Replace("add key=""$CurrentKeyName"" value=""$CurrentValue""","add key=""$CurrentKeyName"" value=""$NewValue""") | out-file "\\$Server\$InstallDir\StifleR.Service.exe.config" -Encoding utf8 -Force -NoNewline
            Write-Output "Successfully updated the property $Property in StifleR Server from $CurrentValue to $NewValue."
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9210 -Message "Successfully updated the property $Property in StifleR Server from $CurrentValue to $NewValue." -EntryType Information
        }
        catch {
            Write-Warning "Failed to update the property $Property in StifleR Server from $CurrentValue to $NewValue."
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9211 -Message "Failed to update the property $Property in StifleR Server from $CurrentValue to $NewValue." -EntryType Error
        }
    }
        
}

function Set-Subnet {

   <#
    .SYNOPSIS
        Use this to change a properties value on a specific subnet

    .DESCRIPTION
        Easily set new properties on subnets
        Details:
        - Easily set new properties on subnets

    .PARAMETER SubnetID
        Specify the SubnetID for which you want to change the proeprty
        
    .PARAMETER Property
        Specify which property you want to change
        
    .PARAMETER NewValue
        Specify the new value of the chosen property
        
    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Set-StifleRSubnetProperty -Server server01 -SubnetID 172.10.10.0 -Property VPN -NewValue True
        Sets the property VPN to True on subnet 172.10.10.0

    .FUNCTIONALITY
        StifleR
    #>

    [cmdletbinding()]
    param (
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName,Mandatory=$true)]
        [string]$SubnetID,
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [Parameter(Mandatory=$true)]
        [string]$Property,
        [Parameter(Mandatory=$true)]
        [string]$NewValue
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        Write-Verbose "Getting subnet(s) by SubnetID - Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Filter ""SubnetID = '$SubnetID'"""
        if ( !$(Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Filter "SubnetID = '$SubnetID'") ) {
            Write-Output "SubnetID $SubnetID does not exist, aborting!"
            break
        }

        Write-Debug "Next step - Set subnet property"
        try {
            $SubnetQuery = "SELECT * FROM Subnets WHERE SubnetID = '$SubnetID'"
            Write-Verbose "Set subnet property : Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{$Property = $NewValue} -ComputerName $Server"
            Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{$Property = $NewValue} -ComputerName $Server
            Write-Output "Successfully updated '$Property' with the new value '$NewValue' on subnet $SubnetID."
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9208 -Message "Successfully updated the property $Property to $NewValue on subnet $SubnetID." -EntryType Information
        }
        catch {
            Write-Warning "Failed to update $Property with the new value $NewValue on subnet $SubnetID, make sure the property exist!"
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9208 -Message "Failed to update the property $Property to $NewValue on subnet $SubnetID." -EntryType Error
        }
    }

}

function Start-ServerService {

   <#
    .SYNOPSIS
        Use this to start the StifleRServer service if it is not running

    .DESCRIPTION
        Start the StifleRServer service
        Details:
        - Start the StifleRServer service

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Start-StifleRServerService -Server server01
        Starts the StifleRServer service on server01

    .FUNCTIONALITY
        StifleR
    #>

    [cmdletbinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
        
        Write-Verbose "Get status of StifleRServer : get-wmiobject win32_service -ComputerName $Server | Where-Object { $_.name -eq 'StifleRServer'}"
        $Service = (get-wmiobject win32_service -ComputerName $Server | Where-Object { $_.name -eq 'StifleRServer'})
        Write-verbose "Status: $Service"
        if ( $Service.State -eq 'Running' ) {
            Write-Warning 'The service StifleRService is already in the state Started, aborting!'
            break
        }
    }

    process {
        Write-Debug "Next step - Start Service"
        try {
            Write-Verbose "StifleR Service : Invoke-WmiMethod -Path ""Win32_Service.Name='StifleRServer'"" -Name StartService -Computername $Server | out-null"
            Invoke-WmiMethod -Path "Win32_Service.Name='StifleRServer'" -Name StartService -Computername $Server | out-null
            Write-Verbose "Get service state : (Get-Service StifleRServer -ComputerName $Server).WaitForStatus('Running')"
            (Get-Service StifleRServer -ComputerName $Server).WaitForStatus('Running')
            Write-Output "Successfully started service StifleRServer"
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9214 -Message "Successfully started the service StifleRServer." -EntryType Information
        }
        catch {
            Write-Warning "Failed to start service StifleRServer"
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9215 -Message "Failed to start the service StifleRServer." -EntryType Error
        }
    }

}

function Stop-ServerService {

   <#
    .SYNOPSIS
        Use this to stop the StifleRServer service if it is not stopped

    .DESCRIPTION
        Stop the StifleRServer service
        Details:
        - Stop the StifleRServer service

    .PARAMETER Force
        Specify this parameter if you need to instantly terminate the process

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	Stop-StifleRServerService -Server server01
        Stops the StifleRServer service on server01

    .EXAMPLE
	Stop-StifleRServerService -Server server01 -Force
        Stops the StifleRServer service on server01 by killing the process of the service

    .FUNCTIONALITY
        StifleR
    #>

    [cmdletbinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [switch]$Force
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server

        Write-Verbose "Get service state : get-wmiobject win32_service -ComputerName $Server | Where-Object { $_.name -eq 'StifleRServer'}"
        $Service = (get-wmiobject win32_service -ComputerName $Server | Where-Object { $_.name -eq 'StifleRServer'})
        Write-verbose "Status: $Service"
        if ( $Service.State -eq 'Stopped' ) {
            Write-Warning 'The service StifleRService is already in the state Stopped, aborting!'
            break
        }
    }

    process {

        Write-Debug "Next step - Stop Service"
        try {
            if ( !$Force ) {
                Write-Verbose "StifleR Service : Invoke-WmiMethod -Path ""Win32_Service.Name='StifleRServer'"" -Name StopService -Computername $Server | out-null"
                Invoke-WmiMethod -Path "Win32_Service.Name='StifleRServer'" -Name StopService -Computername $Server | out-null
            }
            else {
                Write-Verbose "StifleR Service : (Get-WmiObject -Class Win32_Process -ComputerName $Server -Filter ""name='StifleR.Service.exe'"").Terminate() | out-null"
                $(Get-WmiObject -Class Win32_Process -ComputerName $Server -Filter "name='StifleR.Service.exe'").Terminate() | out-null
            }
            Write-Verbose "Get status of service : (Get-Service StifleRServer -ComputerName $Server).WaitForStatus('Stopped')"
            (Get-Service StifleRServer -ComputerName $Server).WaitForStatus('Stopped')
            Write-Output "Successfully stopped service StifleRServer"
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9212 -Message "Successfully stopped the service StifleRServer." -EntryType Information
        }
        catch {
            Write-Warning "Failed to stop service StifleRServer"
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9213 -Message "Failed to stop the service StifleRServer." -EntryType Error
        }
    }

}

function Test-ServerConnection {

    param ( [String]$Server )

    # Check if the specified server is reachable
    if ( Test-Connection $Server -Count 1 -Quiet -ErrorAction Stop ) {}
    else {
        Write-Error -Message "The specified server $Server could not be contacted"
        break
    }
        
    # Check if the specified server has the WMI namespace for StifleR
    try {
        Get-CIMClass -Namespace $Namespace -ComputerName $Server -ErrorAction Stop | out-null
    }
    catch {
        Write-Error -Message "The specified server $Server is missing the WMI namespace for StifleR"
        break
    }

}

# In progress - Remaining, what to actually show?
function Get-Connection {

    [cmdletbinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [string]$SubnetID,
        [switch]$ActivelyTransfering,
        [string]$ActiveBITSJobsIds,
        [string]$ActiveDOJobIds,
        [int]$Limit=1000
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
        [string]$QueryAdditions = 'WHERE'
        if ( $SubnetID -ne '' ) {
            $QueryAdditions = "$QueryAdditions NetworkID='$SubnetID'"
        }
        if ( $ActivelyTransfering ) {
            if ( $QueryAdditions -ne 'WHERE' ) { $QueryAdditions = "$QueryAdditions AND" }
            $QueryAdditions = "$QueryAdditions ActivelyTransferring='$true'"
        }
        if ( $QueryAdditions -eq 'WHERE' ) { $QueryAdditions = '' }

        write-Output $QueryAdditions
        Get-CimInstance -Namespace $Namespace -Query "Select * from Connections $QueryAdditions" -ComputerName $Server | Select-Object -First $Limit
    }
}

# In progress
function Set-Leader {

    [cmdletbinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME
    )

    begin {
        Write-Verbose "Check server availability with Test-Connection"
        Write-Verbose "Check if server has the StifleR WMI-Namespace"
        Test-ServerConnection $Server
    }

    process {
    }

}