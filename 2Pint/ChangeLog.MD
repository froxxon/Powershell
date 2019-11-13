## CHANGE LOG

#### version 1.1.0 (2019-11-13)
- Added functions *'Get-StifleREventLogs'*, *'Get-StifleRLeaders'* and *'Set-StifleRLeaders'* as *'In progress'*
- Added function **'Get-StifleRLicenseInformation'**
- Added parameter InstallDir to CBH for *'Set-StifleRServerSettings'*

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
