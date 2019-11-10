2PINTFUNCTIONS POWERSHELL MODULE
-

A module with some functions to make the life easier to manage StifleR Server with Powershell.
for ease of use just copy those to %ProgramFiles%\WindowsPowershell\Modules\2PintFunctions\ or use 'import-module <PATH>'.
A recommendation at this point in time would also be to test this out in a lab environment, if such exist, first hand ;)

CHANGE LOG
-

version 1.0.5 (2019-11-10)
- Added '#Requires -Version 5.1' to .psm
- Added output types on success/failure
- Removed obsolete commented code
- Added CBH to Get-StifleRClientVersions
- Added CBH to Get-StifleRSubnetQueues
- Changed Select, Where and Sort to Select-Object, Where-Object and Sort-Object
- Fixed $DOType bug in Add-StiflerSubnet by adding the value 'Not set' as default value
- Added out-null to Invoke-WMIMethod in Set-StifleRBITSJob to hide WMI-output
- Renamed Set-StifleRSubnetProperty to Set-StifleRSubnet to match Get-function
- Re-added $SubnetQuery with value to Set-StifleRSubnet, gone for some unknown reason and broke the function...
- Added Remove-Client with 'In progress' status

EXPLANATION OF FUNCTIONS
-

Add-StifleRSubnet
    
    .DESCRIPTION
	Just another way of adding a new subnet to StifleR

    .EXAMPLE
	Add-StiflerSubnet -Server server01 -SubnetID 172.10.10.0 -VPN $true
	Creates a new subnet with the SubnetID of 172.10.10.0 and classes it as a VPN subnet

Set-StifleRBITSJob
    
    .DESCRIPTION
        If you need to push the big red button, go no further!

    .EXAMPLE
	Set-StiflerBITSJob -Server server01 -TargetLevel Subnet -Action Cancel -Target 192.168.20.2
        Cancels all current transfers on the subnet 192.168.20.2

    .EXAMPLE
	Set-StiflerBITSJob -Server server01 -TargetLevel Client -Action Suspend -Target Client01
        Suspends all current transfers on the client Client01
    
    .EXAMPLE
	Set-StiflerBITSJob -Server server01 -TargetLevel All -Action Resume
        Resumes all the transfers known to StifleR as suspended earlier on all subnets

Get-StifleRClient
    
    .DESCRIPTION
        Pull client details from the server hosting the StifleR Server service.

    .EXAMPLE
	Get-StiflerClient -Client Client01 -Server 'server01'
        Pull information about the client Client01 from server01

    .EXAMPLE
	'Clien' | Get-StiflerClient -Server server01
        Pull clients with pipeline where ComputerName like 'Clien' from server01
    
    .EXAMPLE
	'Client01' | Get-StiflerClient -Server server01 -ExactMatch
        Pull client with pipeline where ComputerName equals 'Client01' from server01

Get-StifleRClientVersions
    
    .DESCRIPTION
        Get a summary of which versions of clients you have in your environment
        and the number of clients with each version

    .EXAMPLE
        Get-StifleRClientVersions -Server 'server01'
        Get a list of versions and the number of clients for each one

Get-StifleRServerDebugLevel
    
    .DESCRIPTION
        Gets the current value of debug level for StifleR Server

    .EXAMPLE
	get-StifleRServerDebugLevel -Server server01
        Get the current debug level on server01

    .EXAMPLE
	Get-StifleRServerDebugLevel -Server server01 -InstallDir
        'D$\Program Files\2Pint Software\StifleR'
        Get the current debug level on server01 where the installations directory for StifleR Server is
        'D$\Program Files\2Pint Software\StifleR' instead of the default directory

Get-StifleRServerSettings
    
    .DESCRIPTION
        Gets all values from servers configuration file

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

Get-StifleRSignalRHubHealth
    
    .DESCRIPTION
        Get statistics about Signal-R

    .EXAMPLE
        Get-StifleRSIgnalRHubHealth -Server 'server01'
        Get statistics about Signal-R

Get-StifleRSubnet
    
    .DESCRIPTION
        Pull subnet details from the server hosting the StifleR Server service.

    .EXAMPLE
        Get-StiflerSubnet -Identity '21-*' -Server 'server01' | Format-Table -AutoSize
        Pull subnets with locationname like '21-' from server01

    .EXAMPLE
        '172.16' | Get-StiflerSubnet -Server 'server01' | Select-Object -uUnique LocationName, ActiveClients, AverageBandwidth, RedLeader, BlueLeader | Format-Table -AutoSize
        Pull subnets with pipeline where subnetID like '172.16' from server01 and show current red-/blue leader
    
    .EXAMPLE
        Get-StiflerSubnet -Server 'sever01' -Property LocationName, ActiveClients, AverageBandwidth, SubnetID | Select LocationName, SubnetID, ActiveClients, AverageBandwidth, RedLeader, BlueLeader | Where ActiveClients -gt 0 | Sort AverageBandwidth, LocationName -Descending | Format-Table -AutoSize
        Pull all subnets from sever01 with specific properties and sorts them based on AverageBandwidth

Get-StifleRSubnetQUeues
    
    .DESCRIPTION
        Get information about the current queues in StifleR

    .EXAMPLE
        Get-StifleRSubnetQUeues -server 'server01'
        Get information about the current queues in StifleR

Remove-StifleRSubnet
    
    .DESCRIPTION
	Just another way of remvoing a subnet from StifleR

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

Set-StifleRServerDebugLevel
    
    .DESCRIPTION
        Easily set the debuglevel for StifleR Server

    .EXAMPLE
	Set-StifleRServerDebugLevel -Server server01 -DebugLevel '6.Super Verbose'
        Enable Super verbose debugging on server01

    .EXAMPLE
	Set-StifleRServerDebugLevel -Server server01 -DebugLevel '0.Disabled' -InstallDir
        'D$\Program Files\2Pint Software\StifleR'
        Disable debugging on server01 where the installations directory for StifleR Server is
        'D$\Program Files\2Pint Software\StifleR' instead of the default directory

Set-StifleRServerSettings
    
    .DESCRIPTION
	Easily set new values for properties on StifleR Server

    .EXAMPLE
	Set-StifleRServerSettings -Server server01 -Property wsapifw -NewValue 1
	Sets the property wsapifw to 1 in StifleR Server

    .EXAMPLE
	Set-StifleRServerSettings -Server server01 -Property wsapifw -NewValue 1 -SkipConfirm
	Sets the property wsapifw to 1 in StifleR Server without asking for confirmation

    .EXAMPLE
	Set-StifleRServerSettings -Server server01 -Property wsapifw -Clear
	Sets the property wsapifw to nothing in StifleR Server

Set-StifleRSubnet
    
    .DESCRIPTION
        Easily set new properties on subnets

    .EXAMPLE
	Set-StifleRSubnetProperty -Server server01 -SubnetID 172.10.10.0 -Property VPN -NewValue True
	Sets the property VPN to True on subnet 172.10.10.0

Start-StifleRServerService
    
    .DESCRIPTION
        Start the StifleRServer service

    .EXAMPLE
	Start-StifleRServerService -Server server01
        Starts the StifleRServer service on server01

Stop-StifleRServerService
    
    .DESCRIPTION
        Stop the StifleRServer service

    .EXAMPLE
	Stop-StifleRServerService -Server server01
        Stops the StifleRServer service on server01

    .EXAMPLE
	Stop-StifleRServerService -Server server01 -Force
        Stops the StifleRServer service on server01 by killing the process of the service
