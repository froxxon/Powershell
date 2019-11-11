# 2PINTFUNCTIONS POWERSHELL MODULE (.psm/.psd)

A module with some functions to make the life easier to manage StifleR Server with Powershell.
for ease of use just copy those to %ProgramFiles%\WindowsPowershell\Modules\2PintFunctions\ or use 'import-module <PATH>'.
A recommendation at this point in time would also be to test this out in a lab environment, if such exist, first hand ;)

## CHANGE LOG

#### version 1.0.7 (2019-11-11)
- Added *'-NoNewline'* to *'out-file'* while changing config in *'Set-StifleRServerSettings'* to prevent empty rows created in end of configfile
- Added *'-NoNewline'* to *'out-file'* while changing config in *'Set-StifleRServerDebugLevel'* to prevent empty rows created in end of configfile
- Removed *'<'* and *'/>'* *'$Content.Replace'* in *'Set-StifleRServerSettings'*
- Removed *'<'* and *'/>'* *'$Content.Replace'* in *'Set-StifleRServerDebugLevel'*

#### version 1.0.6 (2019-11-11)
- Changed *'Remove-Client'* to *'Draft'* status
- Added CBH to *'Get-SignalRHubHealth'*
- Removed *'.LINK'* from all CBHs
- Changed *'.FUNCITONALITY'* to *'StifleR'* in all CBHs
- Removed status *'Draft'* from *'Set-StilfeRBITSJob'* *( = working as expected at the moment and done! )*
- Added *'[cmdletbinding()]'* to all params (to add messages for *'Write-Verbose'* and *'Write-Debug'* later on)

#### version 1.0.5 (2019-11-10)
- Added *'#Requires -Version 5.1'* to *'2PintFunctions.psm'*
- Added output types on success/failure
- Removed obsolete commented code
- Added CBH to *'Get-StifleRClientVersions'*
- Added CBH to *'Get-StifleRSubnetQueues'*
- Changed *'Select'*, *'Where'* and *'Sort'* to *'Select-Object'*, *'Where-Object'* and *'Sort-Object'*
- Fixed *'$DOType'* bug in *'Add-StiflerSubnet'* by adding the value *'Not set'* as default value
- Added *'out-null'* to Invoke-WMIMethod in *'Set-StifleRBITSJob'* to hide WMI-output
- Renamed *'Set-StifleRSubnetProperty'* to *'Set-StifleRSubnet'* to match Get-function
- Re-added *'$SubnetQuery'* with value to *'Set-StifleRSubnet'*, gone for some unknown reason and broke the function...
- Added *'Remove-Client'* with *'In progress'* status

## EXPLANATION OF FUNCTIONS

#### Add-StifleRSubnet

Creates a new subnet with the SubnetID of 172.10.10.0 and classes it as a VPN subnet

    Add-StiflerSubnet -Server server01 -SubnetID 172.10.10.0 -VPN $true*
    
#### Set-StifleRBITSJob

Cancels all current transfers on the subnet 192.168.20.2

    Set-StiflerBITSJob -Server server01 -TargetLevel Subnet -Action Cancel -Target 192.168.20.2

Suspends all current transfers on the client Client01

    Set-StiflerBITSJob -Server server01 -TargetLevel Client -Action Suspend -Target Client01

Resumes all the transfers known to StifleR as suspended earlier on all subnets

    Set-StiflerBITSJob -Server server01 -TargetLevel All -Action Resume

#### Get-StifleRClient

Pull information about the client Client01 from server01

    Get-StiflerClient -Client Client01 -Server 'server01'

Pull clients with pipeline where ComputerName like 'Clien' from server01

    'Clien' | Get-StiflerClient -Server server01

Pull client with pipeline where ComputerName equals 'Client01' from server01

    'Client01' | Get-StiflerClient -Server server01 -ExactMatch

#### Get-StifleRClientVersions

Get a list of versions and the number of clients for each one

    Get-StifleRClientVersions -Server 'server01'

#### Get-StifleRServerDebugLevel

Get the current debug level on server01

    Get-StifleRServerDebugLevel -Server server01

Get the current debug level on server01 where the installations directory for StifleR Server is
'D$\Program Files\2Pint Software\StifleR' instead of the default directory

    Get-StifleRServerDebugLevel -Server server01 -InstallDir
    'D$\Program Files\2Pint Software\StifleR'

#### Get-StifleRServerSettings

Get the settings from server01

    Get-StifleRServerSettings -Server server01

Get the settings from server01 with keynames sorted in alphabetical order

    Get-StifleRServerSettings -Server server01 -SortByKeyName

Get the settings from server01 where the installations directory for StifleR Server is
'D$\Program Files\2Pint Software\StifleR' instead of the default directory

    Get-StifleRServerSettings -Server server01 -InstallDir
    'D$\Program Files\2Pint Software\StifleR'

#### Get-StifleRSignalRHubHealth

Get statistics about Signal-R

    Get-StifleRSIgnalRHubHealth -Server 'server01'

#### Get-StifleRSubnet

Pull subnets with locationname like '21-' from server01

    Get-StiflerSubnet -Identity '21-*' -Server 'server01' | Format-Table -AutoSize

Pull subnets with pipeline where subnetID like '172.16' from server01 and show current red-/blue leader

    '172.16' | Get-StiflerSubnet -Server 'server01' | Select-Object -uUnique LocationName, ActiveClients, AverageBandwidth, RedLeader, BlueLeader | Format-Table -AutoSize

Pull all subnets from sever01 with specific properties and sorts them based on AverageBandwidth

    Get-StiflerSubnet -Server 'sever01' -Property LocationName, ActiveClients, AverageBandwidth, SubnetID | Select LocationName, SubnetID, ActiveClients, AverageBandwidth, RedLeader, BlueLeader | Where ActiveClients -gt 0 | Sort AverageBandwidth, LocationName -Descending | Format-Table -AutoSize

#### Get-StifleRSubnetQUeues

Get information about the current queues in StifleR

    Get-StifleRSubnetQUeues -server 'server01'

#### Remove-StifleRClient

Removes the client with ComputerName Client1 and hides the confirmation
dialog as well as the successful result message

    Remove-StifleRClient -Server server01 -Client Client1 -SkipConfirm -Quiet

Removes the client with ComputerName Client1 and makes a flush

    Remove-StifleRClient -Server server01 -Client Client1 -Flush

Prompts a question about removing all clients with ComputerName like MININT-

    Remove-StifleRClient -Server server01 -Client MININT-

#### Remove-StifleRSubnet

Removes the subnet with SubnetID 172.10.10.0 and hides the confirmation
dialog as well as the successful result message

    Remove-StiflerSubnet -Server server01 -SubnetID 172.10.10.0 -SkipConfirm -Quiet

Removes the subnet with the LocationName TESTNET and deletes (if any) the
childobjects of this subnet

    Remove-StiflerSubnet -Server server01 -LocationName TESTNET -DeleteChildren

Prompts a question about removing all subnets with SubnetID like 172

    Remove-StiflerSubnet -Server server01 -SubnetID 172

#### Set-StifleRServerDebugLevel

Enable Super verbose debugging on server01

    Set-StifleRServerDebugLevel -Server server01 -DebugLevel '6.Super Verbose'

Disable debugging on server01 where the installations directory for StifleR Server is
'D$\Program Files\2Pint Software\StifleR' instead of the default directory

    Set-StifleRServerDebugLevel -Server server01 -DebugLevel '0.Disabled' -InstallDir
    'D$\Program Files\2Pint Software\StifleR'

#### Set-StifleRServerSettings

Sets the property wsapifw to 1 in StifleR Server

    Set-StifleRServerSettings -Server server01 -Property wsapifw -NewValue 1

Sets the property wsapifw to 1 in StifleR Server without asking for confirmation

    Set-StifleRServerSettings -Server server01 -Property wsapifw -NewValue 1 -SkipConfirm

Sets the property wsapifw to nothing in StifleR Server

    Set-StifleRServerSettings -Server server01 -Property wsapifw -Clear

#### Set-StifleRSubnet

Sets the property VPN to True on subnet 172.10.10.0

    Set-StifleRSubnetProperty -Server server01 -SubnetID 172.10.10.0 -Property VPN -NewValue True

#### Start-StifleRServerService

Starts the StifleRServer service on server01

    Start-StifleRServerService -Server server01

#### Stop-StifleRServerService

Stops the StifleRServer service on server01

    Stop-StifleRServerService -Server server01

Stops the StifleRServer service on server01 by killing the process of the service

    Stop-StifleRServerService -Server server01 -Force
