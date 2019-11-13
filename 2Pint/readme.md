# 2PINTFUNCTIONS POWERSHELL MODULE (.psm/.psd)

A module with some functions to make the life easier to manage StifleR Server with Powershell.
for ease of use just copy those to %ProgramFiles%\WindowsPowershell\Modules\2PintFunctions\ or use 'import-module <PATH>'.
A recommendation at this point in time would also be to test this out in a lab environment, if such exist, first hand ;)

## CHANGE LOG

#### version 1.1.0 (2019-11-13)
- Added functions *'Get-StifleREventLogs'*, *'Get-StifleRLeaders'* and *'Set-StifleRLeaders'* as *'In progress'*
- Added function **'Get-StifleRLicenseInformation'**
- Added parameter InstallDir to CBH for *'Set-StifleRServerSettings'*

<details><summary>View all</summary>
    
#### version 1.0.9 (2019-11-12)
- All functions that sets data in some way have *'Write-Debug'* and *'Write-Verbose'* messages now

#### version 1.0.8 (2019-11-12)
- Started to add *'Write-Debug'* and *'Write-Verbose'* where applicable, to be continued...
- Corrected the mistake *'if ( $NewSubnetSuccess = $true )'* to *'if ( $NewSubnetSuccess -eq $true ) {'* in *'Add-StifleRSubnet'*

#### version 1.0.7 (2019-11-11)
- Added *'-NoNewline'* to *'out-file'* while changing config in *'Set-StifleRServerSettings'* to prevent empty rows created in end of configfile
- Added *'-NoNewline'* to *'out-file'* while changing config in *'Set-StifleRServerDebugLevel'* to prevent empty rows created in end of configfile
- Removed *'<'* and *'/>'* from *'$Content.Replace'* in *'Set-StifleRServerSettings'*
- Removed *'<'* and *'/>'* from *'$Content.Replace'* in *'Set-StifleRServerDebugLevel'*

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

#### version -le 1.0.4 (< 2019-11-10)
- Build phase undocumented
</details>

## REQUIREMENTS

<details><summary>Show</summary><br>

For everything to work as expected the following requirements should be met:

- Powershell version 5.1
- Remote WMI from source to the server running '*StifleR Server'*
- *'Test-ServerConnection'* (only available inside the module) uses *'ICMPv4 Echo request'* (also called *'ping'*) as one parameter to check availability of the provided parameter *'Server'*
- For *'Get-/Set-StifleRServerSettings'* and *'Get-/Set-StifleRServerDebugLevel'* *'C$'* (default, or the parameter INSTALLDIR) must be reachable by SMB from source and permissions to read/write in the specified location
- 'Get-StifleRLicenseInformation' requires permission to read License.nfo in InstallDir by fileshare
- Correct access in StifleR is of course a requirement as well with rights to read or edit depending on what your needs are
- *'Start-/Stop-StilfeRServerService'* requires Administrator rights (if not explicitly provided for the service *StifleRServer'* otherwise)
</details>

## EXPLANATION OF FUNCTIONS

**<details><summary>Add-StifleRSubnet</summary>**
    
Add-StiflerSubnet [-Server <String>] [-SubnetID] <String> [-GatewayMAC <String>] [-LocationName <String>] [-TargetBandwidth <UInt32
>] [-Description <String>] [-ParentLocationID <String>] [-LEDBATTargetBandwidth <Int32>] [-VPN <Boolean>] [-WellConnected <Boolean>
] [-DOType <String>] [-SetDOGroupID] [<CommonParameters>]

Creates a new subnet with the SubnetID of 172.10.10.0 and classes it as a VPN subnet

    Add-StiflerSubnet -Server 'server01' -SubnetID 172.10.10.0 -VPN $true*
</details>

**<details><summary>Set-StifleRBITSJob</summary>**

Cancels all current transfers on the subnet 192.168.20.2

    Set-StiflerBITSJob -Server 'server01' -TargetLevel Subnet -Action Cancel -Target 192.168.20.2

Suspends all current transfers on the client Client01

    Set-StiflerBITSJob -Server 'server01' -TargetLevel Client -Action Suspend -Target Client01

Resumes all the transfers known to StifleR as suspended earlier on all subnets

    Set-StiflerBITSJob -Server 'server01' -TargetLevel All -Action Resume
</details>

**<details><summary>Get-StifleRClient</summary>**

Pull information about the client Client01 from server01

    Get-StiflerClient -Client Client01 -Server 'server01'

Pull clients with pipeline where ComputerName like 'Clien' from server01

    'Clien' | Get-StiflerClient -Server 'server01'

Pull client with pipeline where ComputerName equals 'Client01' from server01

    'Client01' | Get-StiflerClient -Server 'server01' -ExactMatch
</details>

**<details><summary>Get-StifleRClientVersions</summary>**

Get a list of versions and the number of clients for each one

    Get-StifleRClientVersions -Server 'server01'
</details>

**<details><summary>Get-StifleRLicenseInformation</summary>**

Get information about your licensing from server01

    Get-StifleRLicenseInformation -Server 'server01'
</details>

**<details><summary>Get-StifleRServerDebugLevel</summary>**

Get the current debug level on server01

    Get-StifleRServerDebugLevel -Server 'server01'

Get the current debug level on server01 where the installations directory for StifleR Server is
'D$\Program Files\2Pint Software\StifleR' instead of the default directory

    Get-StifleRServerDebugLevel -Server 'server01' -InstallDir
    'D$\Program Files\2Pint Software\StifleR'
</details>

**<details><summary>Get-StifleRServerSettings</summary>**

Get the settings from server01

    Get-StifleRServerSettings -Server 'server01'

Get the settings from server01 with keynames sorted in alphabetical order

    Get-StifleRServerSettings -Server 'server01' -SortByKeyName

Get the settings from server01 where the installations directory for StifleR Server is
'D$\Program Files\2Pint Software\StifleR' instead of the default directory

    Get-StifleRServerSettings -Server 'server01' -InstallDir
    'D$\Program Files\2Pint Software\StifleR'
</details>

**<details><summary>Get-StifleRSignalRHubHealth</summary>**

Get statistics about Signal-R

    Get-StifleRSIgnalRHubHealth -Server 'server01'
</details>

**<details><summary>Get-StifleRSubnet</summary>**

Pull subnets with locationname like '21-' from server01

    Get-StiflerSubnet -Identity '21-*' -Server 'server01' | Format-Table -AutoSize

Pull subnets with pipeline where subnetID like '172.16' from server01 and show current red-/blue leader

    '172.16' | Get-StiflerSubnet -Server 'server01' | Select-Object -uUnique LocationName, ActiveClients, AverageBandwidth, RedLeader, BlueLeader | Format-Table -AutoSize

Pull all subnets from sever01 with specific properties and sorts them based on AverageBandwidth

    Get-StiflerSubnet -Server 'sever01' -Property LocationName, ActiveClients, AverageBandwidth, SubnetID | Select LocationName, SubnetID, ActiveClients, AverageBandwidth, RedLeader, BlueLeader | Where ActiveClients -gt 0 | Sort AverageBandwidth, LocationName -Descending | Format-Table -AutoSize
</details>

**<details><summary>Get-StifleRSubnetQUeues</summary>**

Get information about the current queues in StifleR

    Get-StifleRSubnetQUeues -server 'server01'
</details>

**<details><summary>Remove-StifleRClient</summary>**

Removes the client with ComputerName Client1 and hides the confirmation
dialog as well as the successful result message

    Remove-StifleRClient -Server 'server01' -Client Client1 -SkipConfirm -Quiet

Removes the client with ComputerName Client1 and makes a flush

    Remove-StifleRClient -Server 'server01' -Client Client1 -Flush

Prompts a question about removing all clients with ComputerName like MININT-

    Remove-StifleRClient -Server 'server01' -Client MININT-
</details>

**<details><summary>Remove-StifleRSubnet</summary>**

Removes the subnet with SubnetID 172.10.10.0 and hides the confirmation
dialog as well as the successful result message

    Remove-StiflerSubnet -Server 'server01' -SubnetID 172.10.10.0 -SkipConfirm -Quiet

Removes the subnet with the LocationName TESTNET and deletes (if any) the
childobjects of this subnet

    Remove-StiflerSubnet -Server 'server01' -LocationName TESTNET -DeleteChildren

Prompts a question about removing all subnets with SubnetID like 172

    Remove-StiflerSubnet -Server 'server01' -SubnetID 172
</details>

**<details><summary>Set-StifleRServerDebugLevel</summary>**

Enable Super verbose debugging on server01

    Set-StifleRServerDebugLevel -Server 'server01' -DebugLevel '6.Super Verbose'

Disable debugging on server01 where the installations directory for StifleR Server is
'D$\Program Files\2Pint Software\StifleR' instead of the default directory

    Set-StifleRServerDebugLevel -Server 'server01' -DebugLevel '0.Disabled' -InstallDir
    'D$\Program Files\2Pint Software\StifleR'
</details>

**<details><summary>Set-StifleRServerSettings</summary>**

Sets the property wsapifw to 1 in StifleR Server

    Set-StifleRServerSettings -Server 'server01' -Property wsapifw -NewValue 1

Sets the property wsapifw to 1 in StifleR Server without asking for confirmation

    Set-StifleRServerSettings -Server 'server01' -Property wsapifw -NewValue 1 -SkipConfirm

Sets the property wsapifw to nothing in StifleR Server

    Set-StifleRServerSettings -Server 'server01' -Property wsapifw -Clear
</details>

**<details><summary>Set-StifleRSubnet</summary>**

Sets the property VPN to True on subnet 172.10.10.0

    Set-StifleRSubnetProperty -Server 'server01' -SubnetID 172.10.10.0 -Property VPN -NewValue True
</details>

**<details><summary>Start-StifleRServerService</summary>**

Starts the StifleRServer service on server01

    Start-StifleRServerService -Server 'server01'
</details>

**<details><summary>Stop-StifleRServerService</summary>**

Stops the StifleRServer service on server01

    Stop-StifleRServerService -Server 'server01'

Stops the StifleRServer service on server01 by killing the process of the service

    Stop-StifleRServerService -Server 'server01' -Force
</details>
