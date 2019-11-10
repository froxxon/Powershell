New-Variable -Name Namespace -Value 'root\StifleR' -Option AllScope

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

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Add-StifleRSubnet-Get-5607a465

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
                    Set-CimInstance -Namespace $Namespace -Query $SubnetQuery -Property @{WellConnected = $WellConnected } -ComputerName $Server
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

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Remove-StifleRSubnet-Get-5607a465

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

function Set-SubnetProperty {

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

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Set-StifleRSubnetProperty-Get-5607a465

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
            write-host "Failed to update $Property with the new value $NewValue on subnet $SubnetID, make sure the property exist!"
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

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Start-StifleRServerService-Get-5607a465

    .FUNCTIONALITY
        StifleR
    #>

    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME
    )

    begin {
        Test-ServerConnection $Server
        $Service = (get-wmiobject win32_service -ComputerName $Server | where { $_.name -eq 'StifleRServer'})
        if ( $Service.State -eq 'Running' ) {
            write-host 'The service StifleRService is already in the state Started, aborting!'
            break
        }
    }

    process {
        try {
            Invoke-WmiMethod -Path "Win32_Service.Name='StifleRServer'" -Name StartService -Computername $Server | out-null
            (Get-Service StifleRServer -ComputerName $Server).WaitForStatus('Running')
            Write-Host "Successfully started service StifleRServer"
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9214 -Message "Successfully started the service StifleRServer." -EntryType Information
        }
        catch {
            Write-Host "Failed to start service StifleRServer"
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

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Stop-StifleRServerService-Get-5607a465

    .FUNCTIONALITY
        StifleR
    #>

    param (
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()][Alias('ComputerName','Computer','__SERVER')]
        [string]$Server = $env:COMPUTERNAME,
        [switch]$Force
    )

    begin {
        Test-ServerConnection $Server
        $Service = (get-wmiobject win32_service -ComputerName $Server | where { $_.name -eq 'StifleRServer'})
        if ( $Service.State -eq 'Stopped' ) {
            write-host 'The service StifleRService is already in the state Stopped, aborting!'
            break
        }
    }

    process {
        try {
            if ( !$Force ) {
                Invoke-WmiMethod -Path "Win32_Service.Name='StifleRServer'" -Name StopService -Computername $Server | out-null
            }
            else {
                $(Get-WmiObject -Class Win32_Process -ComputerName $Server -Filter "name='StifleR.Service.exe'").Terminate() | out-null
            }
            (Get-Service StifleRServer -ComputerName $Server).WaitForStatus('Stopped')
            Write-Host "Successfully stopped service StifleRServer"
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9212 -Message "Successfully stopped the service StifleRServer." -EntryType Information
        }
        catch {
            Write-Host "Failed to stop service StifleRServer"
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9213 -Message "Failed to stop the service StifleRServer." -EntryType Error
        }
    }

}

# Draft
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

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Set-StifleRServerDebugLevel-Get-5607a465

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
        Test-ServerConnection $Server
    }

    process {
        if ( $DebugLevel -eq '0.Disabled' ) { [string]$DebugLevel = '0' }
        if ( $DebugLevel -eq '1.Errors Only' ) { [string]$DebugLevel = '1' }
        if ( $DebugLevel -eq '2.Warning' ) { [string]$DebugLevel = '2' }
        if ( $DebugLevel -eq '3.OK' ) { [string]$DebugLevel = '3' }
        if ( $DebugLevel -eq '4.Informative' ) { [string]$DebugLevel = '4' }
        if ( $DebugLevel -eq '5.Debug' ) { [string]$DebugLevel = '5' }
        if ( $DebugLevel -eq '6.Super Verbose' ) { [string]$DebugLevel = '6' }

        [xml]$Content = Get-Content "\\$Server\$InstallDir\StifleR.Service.exe.config"
        $CurrentValue = ($Content.configuration.appSettings.add | Where-Object { $_.Key -eq 'EnableDebugLog' }).Value
        if ( $DebugLevel -eq $CurrentValue ) {
            write-host "This DebugLevel is already active, aborting!"
            break
        }
        $($Content.configuration.appSettings.add | Where-Object { $_.Key -eq 'EnableDebugLog' }).value = $DebugLevel
        try {
            [string]$Content = Get-Content "\\$Server\$InstallDir\StifleR.Service.exe.config" -Raw
            $Content.Replace("<add key=""EnableDebugLog"" value=""$CurrentValue""/>","<add key=""EnableDebugLog"" value=""$DebugLevel""/>") | out-file "\\$Server\$InstallDir\StifleR.Service.exe.config" -Encoding utf8 -Force
            write-host "Successfully updated DebugLevel in StifleR Server from $CurrentValue to $DebugLevel."
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9210 -Message "Successfully updated DebugLevel in StifleR Server from $CurrentValue to $DebugLevel." -EntryType Information
        }
        catch {
            write-host "Failed to update DebugLevel in StifleR Server from $CurrentValue to $DebugLevel."
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

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Set-StifleRServerSettings-Get-5607a465

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
        Test-ServerConnection $Server
    }

    process {
        [xml]$Content = Get-Content "\\$Server\$InstallDir\StifleR.Service.exe.config"
        $CurrentKeyName = ($Content.configuration.appSettings.add | Where-Object { $_.Key -eq $Property }).key
        if ( !$CurrentKeyName ) {
            write-host "The property '$Property' does not exist, aborting!"
            break
        }
        $CurrentValue = ($Content.configuration.appSettings.add | Where-Object { $_.Key -eq $Property }).Value
        if ( $NewValue -eq $CurrentValue ) {
            write-host "The property '$Property' already has the value '$NewValue', aborting!"
            break
        }
        if ( !$SkipConfirm ) {
            write-host "You are about to change the property '$Property' from '$CurrentValue' to '$NewValue'."
            write-host "IMPORTANT! Make sure this change is valid or things might break..."
            write-host " "
            $msg = "Apply change? [Y/N]"
            do {
                $response = Read-Host -Prompt $msg
            } until ($response -eq 'n' -or $response -eq 'y')
            if ( $response -eq 'n' ) {
                break
            }
            write-host " "
        }
        try {
            [string]$Content = Get-Content "\\$Server\$InstallDir\StifleR.Service.exe.config" -Raw
            $Content.Replace("<add key=""$CurrentKeyName"" value=""$CurrentValue""/>","<add key=""$CurrentKeyName"" value=""$NewValue""/>") | out-file "\\$Server\$InstallDir\StifleR.Service.exe.config" -Encoding utf8 -Force
            write-host "Successfully updated the property $Property in StifleR Server from $CurrentValue to $NewValue."
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9210 -Message "Successfully updated the property $Property in StifleR Server from $CurrentValue to $NewValue." -EntryType Information
        }
        catch {
            write-host "Failed to update the property $Property in StifleR Server from $CurrentValue to $NewValue."
            Write-EventLog -ComputerName $Server -LogName StifleR -Source "StifleR" -EventID 9211 -Message "Failed to update the property $Property in StifleR Server from $CurrentValue to $NewValue." -EntryType Error
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

    .PARAMETER SortByKeyName
        Specify this if it the result should be sorted by Ascending keynames
        
    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
	get-StifleRServerSettings -Server server01
        Get the settings from server01

    .EXAMPLE
	get-StifleRServerSettings -Server server01 -SortByKeyName
        Get the settings from server01 with keynames sorted in alphabetical order

    .EXAMPLE
	Get-StifleRServerSettings -Server server01 -InstallDir
    'D$\Program Files\2Pint Software\StifleR'
        Get the settings from server01 where the installations directory for StifleR Server is
        'D$\Program Files\2Pint Software\StifleR' instead of the default directory

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Get-StifleRServerSettings-Get-5607a465

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
        Test-ServerConnection $Server
    }

    process {
        try {
            [xml]$Content = Get-Content "\\$Server\$InstallDir\StifleR.Service.exe.config" -ErrorAction 1
            $Properties = @()
            $Properties += $Content.configuration.appSettings.add
            if ( $SortByKeyName ) {
                return $Properties | sort key
            }
            else {
                return $Properties
            }
        }
        catch {
            write-host "Failed to obtain properties from $Server, check InstallDir and access permissions."
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

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Get-StifleRServerDebugLevel-Get-5607a465

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
            write-host "DebugLevel for StifleR Server is: $DebugLevel"
        }
        catch {
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

# In progress
function Get-Connections {
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

        write-host $QueryAdditions
        Get-CimInstance -Namespace $Namespace -Query "Select * from Connections $QueryAdditions" -ComputerName $Server | Select -First $Limit
    }
}