﻿New-Variable -Name Namespace -Value 'root\StifleR' -Option AllScope

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

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Get-StiflerSubnet-Get-5607a465

    .FUNCTIONALITY
        Subnets
    #>

    [CmdletBinding()]
    param (
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage = "This parameter is used if you want to query SubnetID(s)")]
        [String]$SubnetID='*',
        #[Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage = "This parameter is used if you want to query LocationName(s)")]
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
        $SubnetInfo | Select $defaultProperties -ExcludeProperty PSComputerName
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

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Get-StiflerClient-Get-5607a465

    .FUNCTIONALITY
        Clients
    #>

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
        if ( $ExactMatch ) {
            if ( $SubnetIDExist ) {
                #$ClientInformation = Get-CIMInstance -Namespace $Namespace -Class Clients -Filter "NetworkID = '$SubnetID'" -ComputerName $Server
                $id = $(Get-CIMInstance -Namespace $Namespace -Class Subnets -Filter "SubnetID LIKE '%$SubnetID%'" -ComputerName $Server).id
                $ClientInformation = Get-CIMInstance -Namespace $Namespace -Class Clients -Filter "LastOnNetwork = '$id'" -ComputerName $Server
            }
            else {
                $ClientInformation = Get-CIMInstance -Namespace $Namespace -Class Clients -Filter "ComputerName = '$Client'" -ComputerName $Server
            }
        }
        else {
            if ( $SubnetIDExist ) {
                #$ClientInformation = Get-CIMInstance -Namespace $Namespace -Class Clients -Filter "NetworkID LIKE '%$SubnetID%'" -ComputerName $Server
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
        $ClientInformation | Select $defaultProperties -ExcludeProperty PSComputerName
    }

}

function Set-BITSJob {

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
	Set-StiflerBITSJob -Server server01 -TargetLevel Subnet -Action Cancel -Target 192.168.20.2
        Cancels all current transfers on the subnet 192.168.20.2

    .EXAMPLE
	Set-StiflerBITSJob -Server server01 -TargetLevel Client -Action Suspend -Target Client01
        Suspends all current transfers on the client Client01
    
    .EXAMPLE
	Set-StiflerBITSJob -Server server01 -TargetLevel All -Action Resume
        Resumes all the transfers known to StifleR as suspended earlier on all subnets

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Set-StiflerBITSJob-Get-5607a465

    .FUNCTIONALITY
        BITS
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
        Test-ServerConnection $Server
    }

    process {
        if ( $TargetLevel -eq 'Subnet' ) {
            if ( $([bool]($Target -as [ipaddress] -and ($Target.ToCharArray() | ?{$_ -eq "."}).count -eq 3)) ) {
                if ( Get-Subnet -Server $Server -SubnetID $Target ) {
                    $Confirm = Read-Host "You are about to $Action all transfers for $Target, are you really sure? [y/n]"
                    while($Confirm -ne "y") {
                        if ($Confirm -eq 'n') { Write-Host "This command was cancelled by the user" ; break }
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
                    if ($Confirm -eq 'n') { Write-Host "This command was cancelled by the user" ; break }
                    $Confirm = Read-Host "You are about to $Action all transfers for $Target, are you really sure? [y/n]"
                }
                if ( $Confirm -eq 'y' ) {
                    $TriggerTarget = $Target
                    $TriggerHappy = $True
                }
            }
            else { write-Error "The Client $Target couldn't be found in StifleR" }
        }

        if ( $TargetLevel -eq 'All' ) {
            if ( $Target -ne "" ) { Write-Error "The parameter Target can't be used when All is selected as TargetLevel" ; break }
        
            $Confirm = Read-Host "You are about to $Action ALL transfers, are you really sure? [y/n]"
            while($Confirm -ne "y") {
                if ($Confirm -eq 'n') { Write-Host "This command was cancelled by the user" ; break }
                $Confirm = Read-Host "You are about to $Action ALL transfers, are you really sure? [y/n]"
            }
            if ( $Confirm -eq 'y' ) {
                $TriggerTarget = 'All'
                $TriggerHappy = $True
            }
        }

        if ( $TriggerHappy ) {
            try {
                Invoke-WMIMethod -Namespace $Namespace -Path StifleREngine.Id=1 -Name ModifyJobs -ArgumentList "$Action", False, "*", 0, "$TriggerTarget" -ComputerName $Server
                Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9200 -Message "Successfully invoked BITSJob change with the following parameters: Action: $Action   Triggertarget: $TriggerTarget" -EntryType Information
            }            
            catch {
                Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9201 -Message "Failed to invoke BITSJob change with the following parameters: Action: $Action   Triggertarget: $TriggerTarget" -EntryType Error
            }
        }
    }

}

function Add-Subnet {

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
        [ValidateSet('HTTP Only','LAN','Group','Internet','Simple','Bypass')]
        [string]$DOType,
        [switch]$SetDOGroupID
    )

    begin {
        Test-ServerConnection $Server

        $SubnetQuery = "SELECT * FROM Subnets WHERE SubnetID = '$SubnetID'"
        if ( $(Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Filter "SubnetID = '$SubnetID'") ) {
            write-host "SubnetID $SubnetID already exist, aborting!"
            break
        }
    }

    process {
        try {            
            Invoke-CimMethod -Namespace $Namespace -ClassName Subnets -MethodName AddSubnet  -ComputerName $Server -Arguments @{ subnet=$SubnetID ; TargetBandwidth=$TargetBandwidth ; locationName=$LocationName ; description=$Description ; GatewayMAC=$GatewayMAC ; ParentLocationId=$ParentLocationID } | out-null
            $NewSubnetSuccess = $true
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9202 -Message "Successfully added the subnet $SubnetID with the following parameters: TargetBanwidth: $TargetBandwidth   locationName=$LocationName   description=$Description   GatewayMAC=$GatewayMAC   ParentLocationId=$ParentLocationID" -EntryType Information
        }
        catch {
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9203 -Message "Failed to add the subnet $SubnetID with the following parameters: TargetBanwidth: $TargetBandwidth   locationName=$LocationName   description=$Description   GatewayMAC=$GatewayMAC   ParentLocationId=$ParentLocationID" -EntryType Error
        }

        if ( $NewSubnetSuccess = $true ) {
            if ( $LEDBATTargetBandwidth -ne 0 ) {
                try {
                    Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{LEDBATTargetBandwidth = $LEDBATTargetBandwidth} -ComputerName $Server
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9204 -Message "Successfully changed the property LEDBATTargetBandwidth on subnet $SubnetID to $LEDBATTargetBandwidth" -EntryType Information
                }
                catch {
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9205 -Message "Failed to change the property LEDBATTargetBandwidth on subnet $SubnetID to $LEDBATTargetBandwidth" -EntryType Error
                }
            }

            if ( $VPN -eq $True ) {
                try {
                    Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{VPN = $VPN } -ComputerName $Server
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9204 -Message "Successfully changed the property VPN on subnet $SubnetID to $VPN" -EntryType Information
                }
                catch {
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9205 -Message "Failed to change the property VPN on subnet $SubnetID to $VPN" -EntryType Error
                }
            }
                
            if ( $WellConnected -eq $True ) {
                try {
                    Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{WellConnected = $VPN } -ComputerName $Server
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9204 -Message "Successfully changed the property WellConnected on subnet $SubnetID to $WellConnected" -EntryType Information
                }
                catch {
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9205 -Message "Failed to change the property WellConnected on subnet $SubnetID to $WellConnected" -EntryType Error
                }
            }

            if ( $DOType -ne $null ) {
                if ( $DOType -eq 'HTTP Only' ) { [int]$DOType = 0 }
                if ( $DOType -eq 'LAN' ) { [int]$DOType = 1 }
                if ( $DOType -eq 'Group' ) { [int]$DOType = 2 }
                if ( $DOType -eq 'Internet' ) { [int]$DOType = 3 }
                if ( $DOType -eq 'Simple' ) { [int]$DOType = 99 }
                if ( $DOType -eq 'Bypass' ) { [int]$DOType = 100 }

                try {
                    Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{DODownloadMode = $DOType } -ComputerName $Server
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9204 -Message "Successfully changed the property DODownloadMode on subnet $SubnetID to $DOType" -EntryType Information
                }
                catch {
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9205 -Message "Failed to change the property DODownloadMode on subnet $SubnetID to $DOType" -EntryType Error
                }
            }

            if ( $SetDOGroupID ) {
                $id = $(Get-CIMInstance -Namespace $Namespace -Class Subnets -Filter "SubnetID LIKE '%$SubnetID%'" -ComputerName $Server).id

                try {
                    Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{DOGroupID = $id } -ComputerName $Server
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9204 -Message "Successfully changed the property DOGroupID on subnet $SubnetID to $id" -EntryType Information
                }
                catch {
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9205 -Message "Failed to change the property DOGroupID on subnet $SubnetID to $id" -EntryType Error
                }
            }
        }
    }

}

function Remove-Subnet {

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
        Test-ServerConnection $Server
    }

    process {
        if ( $DeleteChildren ) {
            $Arguments = @{ DeleteChildren = $true }
        }
        else {
            $Arguments = @{ DeleteChildren = $false }
        }
        
        if ( $PsCmdlet.ParameterSetName -eq 'LocationName' ) {
            [array]$Subnets = Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Filter "LocationName LIKE '%$LocationName%'"
        }
        else {
            [array]$Subnets = Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Filter "SubnetID LIKE '%$SubnetID%'"
        }

        if ( $Subnets.Count -le 0 ) {
            write-host "No subnets found matching the input parameters, aborting!"
            break
        }

        if ( !$SkipConfirm ) {
            write-host "You are about to delete $($Subnets.Count) subnet(s) listed below:"
            write-host " "
            foreach ( $Subnet in $Subnets ) {
                write-host "SubnetID: $($Subnet.SubnetID) LocationName: $($Subnet.LocationName)"
            }
            write-host " "
            $msg = "Are you sure? [Y/N]"
            do {
                $response = Read-Host -Prompt $msg
            } until ($response -eq 'n' -or $response -eq 'y')
            if ( $response -eq 'n' ) {
                break
            }
            write-host " "
        }
        foreach ( $Subnet in $Subnets ) {
            try {
                if ( $PsCmdlet.ParameterSetName -eq 'LocationName' ) {
                    Invoke-CimMethod -Namespace $Namespace -Query "SELECT * FROM Subnets Where LocationName = '$($Subnet.LocationName)'" -MethodName RemoveSubnet -ComputerName $Server -Arguments $Arguments | out-null
                }
                else {
                    Invoke-CimMethod -Namespace $Namespace -Query "SELECT * FROM Subnets Where SubnetID = '$($Subnet.SubnetID)'" -MethodName RemoveSubnet -ComputerName $Server -Arguments $Arguments | out-null
                }
                if ( !$Quiet ) {
                    write-host "Successfully removed SubnetID: $($Subnet.SubnetID) LocationName: $($Subnet.LocationName)"
                }
                Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9206 -Message "Successfully removed subnet $($Subnet.SubnetID) (LocationName: $($Subnet.LocationName)) with the argument DeleteChildren = $DeleteChildren" -EntryType Information
            }
            catch {
                if ( !$Quiet ) {
                    write-host "Failed to remove SubnetID: $($Subnet.SubnetID) LocationName: $($Subnet.LocationName)"
                    Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9207 -Message "Failed to remove subnet $($Subnet.SubnetID) (LocationName: $($Subnet.LocationName)) with the argument DeleteChildren = $DeleteChildren" -EntryType Error
                }
            }
        }
    }

}

function Get-SignalRHubHealth {

    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME
    )

    begin {
        Test-ServerConnection $Server
    }

    process {
        Get-CIMInstance -Namespace $Namespace -Query "Select * from StiflerEngine WHERE id = 1" -ComputerName $Server | FL -property NumberOfClients, ActiveNetworks, ActiveRedLeaders,HubConnectionInitiated,HubConnectionCompleted,ClientINfoInitiated, ClientInfoCompleted, JobReportInitiated ,JobReportCompleted,JobReporDeltatInitiated,JobReportDeltaCompleted
    }

}

function Get-SubnetQueues {

    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME
    )

    begin {
        Test-ServerConnection $Server
    }

    process {
        $Clients = Get-CIMInstance -Namespace $Namespace -Query "Select * from Clients" -ComputerName $Server | Select TotalQueueSize_BITS, TotalQueueSize_DO, NetworkID
        $Clients | Group-Object NetworkID | %{
            New-Object psobject -Property @{
                NetworkID = $_.Name
                BITSTotal =“{0:N2}” -f (($_.Group | Measure-Object TotalQueueSize_BITS -Sum).Sum /1MB)
                DOTotal = “{0:N2}” -f(($_.Group | Measure-Object TotalQueueSize_DO -Sum).Sum /1MB)
                Clients = $_.Count
            }
        } |  Sort-Object -Property Clients | FT -AutoSize
        Write-Host "Total Client Count: " $Clients.count
    }

}

function Get-ClientVersions {

    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME
    )

    begin {
        Test-ServerConnection $Server
    }

    process {
        $VersionInfo = @()
        $Versions = $(Get-CimInstance -Namespace $Namespace -Query "Select * from Clients" -ComputerName $Server | Select -Unique version ).version
        foreach ( $Version in $Versions ) {
            $VersionCount = $(Get-CimInstance -Namespace $Namespace -Query "Select * from Clients Where Version = '$Version'" -ComputerName $Server ).Count
            $VersionInfo += New-Object -TypeName psobject -Property @{Version=$Version; Clients=$VersionCount}
        }
        $VersionInfo
    }

}

function Update-SubnetProperty {

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
        Test-ServerConnection $Server
    }

    process {
        if ( !$(Get-CIMInstance -ComputerName $Server -Namespace $Namespace -Class Subnets -Filter "SubnetID = '$SubnetID'") ) {
            write-host "SubnetID $SubnetID does not exist, aborting!"
            break
        }

        try {
            Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{$Property = $NewValue} -ComputerName $Server
            write-host "Successfully updated '$Property' with the new value '$NewValue' on subnet $SubnetID."
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9208 -Message "Successfully updated the property $Property to $NewValue on subnet $SubnetID." -EntryType Information
        }
        catch {
            write-host "Failed to update $Property with the new value $NewValue on subnet $SubnetID."
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9208 -Message "Failed to update the property $Property to $NewValue on subnet $SubnetID." -EntryType Error
        }
    }

}

function Set-ServerDebugLevel {
}

function Get-Connections {
}

function Start-ServerService {
}

function Stop-ServerService {
}