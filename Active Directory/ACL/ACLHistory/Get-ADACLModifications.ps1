## Scriptet söker i ElasticSearch efter events där ACL har modifierats
##
## Författare: Fredrik Bergman, 2020-11-10
## Version 1.0.0 - First version //Fredrik Bergman 2020-11-13
## Version 1.0.1 - AllGPOs now obtain its information from Get-ADObject instead och Get-GPO  //Fredrik Bergman 2020-11-14
## Version 1.0.1 - Moved Active Directory functions to module 'ActiveDirectoryRightsModule' //Fredrik Bergman 2020-11-14
## Version 1.0.1 - Added the highlightning when addition of critical events (ex. FullControl) //Fredrik Bergman 2020-11-14
## Version 1.0.2 - Added highlightning of Timestamp if it happens between 20.00 and 06.59 //Fredrik bergman 2020-11-15
## Version 1.0.2 - Added hightligtning of the specific permissions considered Critical under Access //Fredrik Bergman 2020-11-15
## Version 1.0.3 - Merged columns 'Object Type' and 'Object (Name)' to 'Target Object' //Fredrik Bergman 2020-11-15
## Version 1.0.3 - Added samAccountName (by SubjectUserName) to 'Modified by' //Fredrik Bergman 2020-11-15
## Version 1.0.4 - Added functionality to write to database //Fredrik Bergman 2020-11-18
##

[CmdletBinding()]
param (
    [ValidateSet('1m','15m','30m','35m','1h','2h','6h','12h','1d','3d','7d', IgnoreCase = $false)]
    [string]$Timeframe = '2h',
    [ValidateSet('10','100','500','1000','10000')]
    [int]$IndexThreshold = '1000',
    [switch]$SkipNotification
)

#region DECLARE SCRIPT DEPENDENCIES
    $ScriptVariables = @{
        "ScriptFolder"            = "C:\PowerShell\TaskScheduler\Get-ADACLModifications"
        "MailFrom"                = 'noreply@froxxen.com'
        "MailSubject"             = 'Recent Active Directory ACL Modifications'
        "ToRecipients"            = 'froxxen@froxxen.com'
        "SMTPServer"              = 'mail.froxxen.com'
        "ElasticSearchUri"        = "http://192.168.2.205:9200"
        "ExcludedSDDLs"           = @('Everyone: Deny DeleteTree, Delete This Object Only',
                                      'Everyone: Deny ExtendedRight Change Password This Object Only',
                                      'NT AUTHORITY\SELF: Deny ExtendedRight Change Password This Object Only',
                                      'NT AUTHORITY\SELF: Allow ExtendedRight Send As This object and all descendant objects',
                                      'NT AUTHORITY\SELF: Allow Read All Properties;Write All Properties Personal Information This object and all descendant objects'
                                    )
        "ColorAdded"              = "#3f82b0"
        "ColorRemoved"            = "#db3f28"
        "ColorError"              = "#a52869"
        "CriticalPermissions"     = @('FullControl','All Extended Rights','ExtendedRight ')
        "WriteToSQL"              = $true
    }

    $ACLHistoryModule   = "$($ScriptVariables.ScriptFolder)\Modules\ACLHistoryManagement.psm1"
    $ADRightsModulePath = "$($ScriptVariables.ScriptFolder)\Modules\ActiveDirectoryRightsModule.psm1"
    Import-Module $ACLHistoryModule
    Import-Module $ADRightsModulePath

function Get-StringHash { 
    param (
        [String]$String,
        $HashName = "MD5"
    )
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
    $algorithm = [System.Security.Cryptography.HashAlgorithm]::Create('MD5')
    $StringBuilder = New-Object System.Text.StringBuilder 
    $algorithm.ComputeHash($bytes) | 
    ForEach-Object { $null = $StringBuilder.Append($_.ToString("x2")) } 
    $StringBuilder.ToString() 
}

Function Invoke-ElasticSearchRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$ElasticSearchUri,
        [Parameter(Mandatory=$false, Position=1)][string]$DSLQuery
    )

    #region Function variables
        $RequestParams = @{
            "ErrorAction" = "Stop"
            "Verbose" = $false
        }
    #endregion

    #region DSLQuery parameter used (Switch to/append _search API)
        if($DSLQuery){

            if($ElasticSearchUri -notmatch "_search$"){
                $ElasticSearchUri = "$ElasticSearchUri/_search"
            }

            [void]$RequestParams.Add("Method","Post")
            [void]$RequestParams.Add("Body",$DSLQuery)
            [void]$RequestParams.Add("ContentType","application/json")
            [void]$RequestParams.Add("UseBasicParsing",$true)

        }
    #endregion

    #region Invoke-RestMethod
        try{
            Invoke-RestMethod -Uri "$ElasticSearchUri" @RequestParams
        }
        catch{
            Write-Warning "Something went wrong: $($(($_ | ConvertFrom-Json).error.reason))"
        }
    #endregion
}

# CSS for HTML
$Style = @"
<style>
	body {
		font-family: verdana,arial,sans-serif;
		font-size:12px;
	}
	table {
		font-family: verdana,arial,sans-serif;
		font-size:11px;
		border-style: hidden;
        width:95%;
    }
	td {
		border-style: hidden;
		text-align: center;
        padding: 8px;
	}
    #tsum {
        width: 65%;
        border-style: hidden;
        border-width: 1px;
        border-color: #7bd0e0;
        border-top-style: solid;
        text-align:center;
        padding: 0px;
    }
    #tsum td{
        padding: 8px;
        border-style: hidden;
        text-align:center;
    }
    #t01 {
        width: 100%;
        border-style: hidden;
        padding: 0px;
        spacing: 0px;
    }
    #t01 td{
        padding: 8px;
        border-style: hidden;
        text-align: left;
        vertical-align: top;
    }
    #t01 tr:nth-child(even) {
        background-color: #eee;
    }
    #t01 tr:nth-child(odd) {
        background-color: #fff;
    }
    #t01 th {
        color: white;
        text-align: left;
        font-weight: bold;
        padding: 8px;
        background-color: #3f82b0;
    }
    #data {
        table-layout: auto !important;
    }
    #data td{
        width: auto !important;
        background-color: transparent;
        spacing: 0px;
        padding: 2px;
    }
    .Critical {
        border-style: solid;
        border-width: 2px;
        border-color: #b8812e;
    }
</style>
"@

#DSL query fetches events from ElasticSearch
$DSLQuery = @"
{
  `"size`" : $IndexThreshold,
  `"query`": {
    `"bool`": {
      `"filter`": [
	    { `"range`":  { `"@timestamp`": {`"gte`": `"now-$Timeframe`",`"lt`": `"now`"}}}
      ],
      `"must`" : [
        { `"match`": { `"event.code`": `"5136`" }},
        { `"match`": { `"tags`": `"dcsecurity`" }},
        { `"match`": { `"winlog.event_data.AttributeLDAPDisplayName`": `"nTSecurityDescriptor`" }}
      ],
      `"must_not`" : [
        { `"match`": { `"winlog.event_data.SubjectUserName`": `"SYSTEM`" }},
        { `"match`": { `"winlog.event_data.ObjectClass`": `"serviceConnectionPoint`" }},
        { `"match`": { `"winlog.event_data.ObjectClass`": `"msExchActiveSyncDevices`" }}
      ]
    }
  }
}
"@
#endregion

#region GET ELASTICSEARCH EVENTS AND PARSE DATA

    # Connecting to Elasticsearch, not using -UseSecurityProtocol Tls12 #-Credential $ESKredds }
    if ( !$ElasticSearchResults ) { $ElasticSearchResults = Invoke-ElasticSearchRequest -ElasticSearchUri $ScriptVariables.ElasticSearchUri -DSLQuery $DSLQuery } 
    # Gathers a list of all attributes and Extended rights in the AD schema to use as display names
    if ( !$ADRightsGUIDs ) { $ADRightsGUIDs = Get-ADRightsGUIDs }
    # Gathers a list of all group policies in the domain to use as display names
    if ( !$AllGPOs ) { $AllGPOs = Get-ADObject -LDAPFilter "(objectClass=groupPolicyContainer)" -SearchBase "CN=Policies,CN=System,$((Get-ADDomain).DistinguishedName)" -Properties DisplayName | Select DisplayName, Name }

    #region Parse ElasticSearch events if found (Custom)
        if($ElasticSearchResults.hits.hits.Count -gt 0){
            $FilteredEvents = @($ElasticSearchResults.hits.hits._source) | Sort '@timestamp' -Descending
            #$FilteredEvents = $FilteredEvents | where { $_.winlog.event_data.OpCorrelationID -eq '{99b90236-a887-4a39-976d-a078f08bdab0}' } # debug
            $FilteredEvents.count # debug - shows current objects found in Elastic

            [array]$EventsToSend      = @() # Array with Events that will be sent
            [array]$UsedCorrIDs       = @() # Contains a list with already checked OpCorrelationIDs
            [array]$VerifiedADObjects = @() # Contains a list of checked Active Directory identities
            [int]$ACEAdded            = 0   # Sums all ACEs added
            [int]$ACERemoved          = 0   # Sums all ACEs removed
            [int]$ACECriticals        = 0   # Sums all events marked as Critical

            if($FilteredEvents.Count -gt 1){
                # loop through every event found in Elastic
                Foreach($CurrentFilteretedEvent in $FilteredEvents ){
                    if ( $CurrentFilteretedEvent.winlog.event_data.OpCorrelationID -notin $UsedCorrIDs ) {
                        $FirstEventRow = $true
                        
                        # convert timestamp to a specified format
                        $Timestamp = Get-Date $CurrentFilteretedEvent.'@timestamp' -format "yyyy-MM-dd HH:mm:ss"
                        $TimestampSQL = Get-Date $CurrentFilteretedEvent.'@timestamp' -format "yyyy-MM-dd HH:mm:ss"
                        if ( ([regex]::match($Timestamp,"\s{1}(2|0)[^(7|8|9)]:")).Success -eq $true ) {
                            $Timestamp = "<font color=`"red`">$Timestamp</font>"
                        }

                        $UsedCorrIDs += $CurrentFilteretedEvent.winlog.event_data.OpCorrelationID                            
                        [array]$CompareEvents = $FilteredEvents | where { $_.winlog.event_data.OpCorrelationID -eq $CurrentFilteretedEvent.winlog.event_data.OpCorrelationID }
                        # there can only be two events with matching OpCorrelationIDs, otherwise skip
                        if ( $CompareEvents.Count -eq 2 ) {
                            $CompareResultOwner = $null
                            $CompareResultGroup = $null
                            $CompareOwnerAndGroupNew = ConvertFrom-SddlString $($CompareEvents.winlog.event_data | Where OperationType -eq '%%14674').AttributeValue -Type ActiveDirectoryRights
                            $CompareOwnerAndGroupOld = ConvertFrom-SddlString $($CompareEvents.winlog.event_data | Where OperationType -eq '%%14675').AttributeValue -Type ActiveDirectoryRights
                            # check if change occured for Owner
                            if ( $CompareOwnerAndGroupNew.Owner -ne $CompareOwnerAndGroupOld.Owner ) {
                                $CompareResultOwner = "<table id=`"data`"><tr><td align=`"left`"><b>Owner</b></td><td align=`"right`">`'$($CompareOwnerAndGroupOld.Owner)`' changed to <font color=`"$($ScriptVariables.ColorAdded)`">`'$($CompareOwnerAndGroupNew.Owner)</font>`'</td></tr></table>"
                                $ACEAdded++
                            }
                            # check if change occured for Group
                            if ( $CompareOwnerAndGroupNew.Group -ne $CompareOwnerAndGroupOld.Group ) {
                                $CompareResultGroup = "<table id=`"data`"><tr><td><b>Owner</b></td><td>`'$($CompareOwnerAndGroupOld.Group)`' changed to <font color=`"$($ScriptVariables.ColorAdded)`">`'$($CompareOwnerAndGroupNew.Group)</font>`'</td></tr></table>"
                                $ACEAdded++
                            }
                                
                            $NewEvent = $($CompareEvents.winlog.event_data | Where OperationType -eq '%%14674').AttributeValue
                            $OldEvent = $($CompareEvents.winlog.event_data | Where OperationType -eq '%%14675').AttributeValue
                            $ComparedSDDLs = Compare-SDDLValues -NewSDDL $NewEvent -OldSDDL $OldEvent
                            
                            if ( $ComparedSDDLs ) {
                                $MergedDACL = "D:$($ComparedSDDLs.SDDL -join '')"
                                $ADSObject  = New-Object System.DirectoryServices.ActiveDirectorySecurity
                                $ADSObject.SetSecurityDescriptorSddlForm($MergedDACL)
                                $ADSAccessRules = $ADSObject.GetAccessRules($true, $false, [System.Security.Principal.NTAccount])   
                                if ( $ADSAccessRules ) {
                                    [array]$tempResultDACL = Get-ACERights -SID $ADSAccessRules
                                }
                                $CompareResultDACL = @()
                                foreach ( $result in $tempResultDACL ) {
                                    # skip excluded server names
                                    if ( $($CurrentFilteretedEvent.winlog.event_data.SubjectUserName) -notin $ScriptVariables.ExcludedServers ) {
                                        # skip excluded permissions
                                        #write-output "$($result.IdentityReference): $($result.access) $($result.Permission) $($result.ApplyTo)" # debug
                                        if ( "$($result.IdentityReference): $($result.access) $($result.Permission) $($result.ApplyTo)" -notin $ScriptVariables.ExcludedSDDLs ) {
                                            $Operation = $ComparedSDDLs[$($tempResultDACL.indexOf($result))].Operation
                                            if ( $Operation -eq 'Added' ) {
                                                $ColorizeOp = "<font color=`"$($ScriptVariables.ColorAdded)`">$Operation</font>"
                                                $ACEAdded++
                                            }
                                            elseif ( $Operation -eq 'Removed' ) {
                                                $ColorizeOp = "<font color=`"$($ScriptVariables.ColorRemoved)`">$Operation</font>"
                                                $ACERemoved++
                                            }
                                            else {
                                                $ColorizeOp = "<font color=`"$($ScriptVariables.ColorError)`">ERROR</font>"
                                            }
                                            if ( $FirstEventRow -eq $true ) {
                                                $FirstEventRow = $false
                                                $FirstEvent = $null
                                            }
                                            else {
                                                $FirstEvent = '</br>'
                                            }

                                            # if this is considered a critical event, then highlight it
                                            foreach ( $Critical in $ScriptVariables.CriticalPermissions ) {
                                                if ( $result.Permission -match $Critical -and $Operation -eq 'Added' ) {
                                                    $CriticalEvent = "class=`"Critical`""
                                                    $CriticalEventTD = "class=`"CriticalTD`""
                                                    foreach ( $CriticalPermifssion in $ScriptVariables.CriticalPermissions ) {
                                                        $Crit = ([regex]::match($($result.permission),"$($CriticalPermission).*(?=,)?")).value
                                                        if ( $Crit ) {
                                                            $CritResult = $result.Permission -replace $Crit, "<font color=`"#b8812e`"><b>$Crit</b></font>" -replace 'ExtendedRight ','ExtendedRight: '
                                                        }                                                    
                                                    }
                                                    $ACECriticals++
                                                }
                                                else {
                                                    $CriticalEvent = $null
                                                }
                                            }
                                            $CompareResultDACL += "$($FirstEvent)<table id=`"data`" $CriticalEvent><tr><td align=`"left`"><b>DACL</b></td><td align=`"right`"><font color=`"a1a1a5`"><b>$ColorizeOp</b></font></td></tr><tr><td><b>Type</b></td><td>$($result.access)</td></tr><tr><td><b>Principle</b></td><td>$($result.IdentityReference)</td></tr><tr><td><b>Access</b></td><td>$($CritResult)</td></tr><tr><td><b>Applies to</b></td><td>$($result.ApplyTo)</td></tr></table>"
                                            if ( $ScriptVariables.WriteToSQL ) {
                                                # Checksum corresponds to the primary key in the Modification table, so duplicates wont exist
                                                $Checksum = Get-StringHash "$TimestampSQL $($CurrentFilteretedEvent.winlog.event_data.OpCorrelationID) 'DACL' $($result.access) $($result.IdentityReference) $($result.Permission) $($result.ApplyTo) $($Operation)"
                                                Add-ACLModificationRecord -Timestamp $TimestampSQL -OpCorrelationID $CurrentFilteretedEvent.winlog.event_data.OpCorrelationID -SDDLType 'DACL' -Type $result.access -Principal $result.IdentityReference -Access $result.Permission.Trim() -AppliesTo $result.ApplyTo -Operation $Operation -Checksum $Checksum
                                            }
                                        }
                                    }
                                }
                            }
                            if ( $CompareResultOwner ) {
                                if ( $ScriptVariables.WriteToSQL ) {
                                    # Checksum corresponds to the primary key in the Modification table, so duplicates wont exist
                                    $Checksum = Get-StringHash "$TimestampSQL $($CurrentFilteretedEvent.winlog.event_data.OpCorrelationID) 'Owner' $($CompareOwnerAndGroupOld.Owner) $($CompareOwnerAndGroupNew.Owner)"
                                    Add-ACLModificationRecord -Timestamp $TimestampSQL -OpCorrelationID $CurrentFilteretedEvent.winlog.event_data.OpCorrelationID -SDDLType 'Owner' -Type 'N/A' -Principal 'N/A' -Access "Owner changed from ""$($CompareOwnerAndGroupOld.Owner)"" to ""$($CompareOwnerAndGroupNew.Owner)""" -AppliesTo 'N/A' -Operation "Changed" -Checksum $Checksum
                                }
                            }
                            if ( $CompareResultGroup ) {
                                if ( $ScriptVariables.WriteToSQL ) {
                                    # Checksum corresponds to the primary key in the Modification table, so duplicates wont exist
                                    $Checksum = Get-StringHash "$TimestampSQL $($CurrentFilteretedEvent.winlog.event_data.OpCorrelationID) 'Group' $($CompareOwnerAndGroupOld.Owner) $($CompareOwnerAndGroupNew.Owner)"
                                    Add-ACLModificationRecord -Timestamp $TimestampSQL -OpCorrelationID $CurrentFilteretedEvent.winlog.event_data.OpCorrelationID -SDDLType 'Group' -Type 'N/A' -Principal 'N/A' -Access "Group changed from ""$($CompareOwnerAndGroupOld.Group)"" to ""$($CompareOwnerAndGroupNew.Group)""" -AppliesTo 'N/A' -Operation "Changed" -Checksum $Checksum
                                }
                            }
                        }
                        
                        # if the objectClass equals groupPolicyContainer then get display name from the array AllGPOs
                        if ( $CurrentFilteretedEvent.winlog.event_data.ObjectClass -eq 'groupPolicyContainer' ) {
                            $ObjectName = $($AllGPOs | Where Name -eq "$([regex]::match($CurrentFilteretedEvent.winlog.event_data.ObjectDN,"{.*}").value)").DisplayName
                            if ( !$ObjectName ) {
                                $ObjectName = $([regex]::match($CurrentFilteretedEvent.winlog.event_data.ObjectDN,"{.*}")).Value
                            }
                        }

                        # Otherwise set the variable ObjectName and checks if this is already verified against AD, to skip more Gets than necessary
                        else {
                            if ( $($CurrentFilteretedEvent.winlog.event_data.ObjectDN) -notin $VerifiedADObjects ) {
                                $CheckADObject = Get-ADObject -ldapfilter "(distinguishedName=$($CurrentFilteretedEvent.winlog.event_data.ObjectDN))" | Select Name, distinguishedName
                                if ( $CheckADObject ) {
                                    $VerifiedADObjects += $CheckADObject
                                    $ObjectName = $CheckADObject.Name
                                }
                                else {
                                    $ObjectName = $CurrentFilteretedEvent.winlog.event_data.ObjectDN
                                }
                            }
                            else {
                                $ObjectName = $($VerifiedADObjects | where distinguishedName -eq $CurrentFilteretedEvent.winlog.event_data.ObjectDN).Name
                            }
                        }

                        # if $CurrentFilteretedEvent.winlog.event_data.SubjectUserName is already verified then don't query AD again
                        if ( $($CurrentFilteretedEvent.winlog.event_data.SubjectUserName) -notin $VerifiedADObjects ) {
                            $CheckADObject = Get-ADObject -ldapfilter "(samAccountName=$($CurrentFilteretedEvent.winlog.event_data.SubjectUserName))" | Select Name, distinguishedName, samAccountName
                            if ( $CheckADObject ) {
                                $VerifiedADObjects += $CheckADObject
                                $ModifiedBy = "$($CheckADObject.Name)</br><font color=`"#a1a1a5`">($($CurrentFilteretedEvent.winlog.event_data.SubjectUserName))</font>"
                                $ModifiedByToSQL = $CheckADObject.Name
                            }
                            else {
                                $ModifiedBy = $CurrentFilteretedEvent.winlog.event_data.SubjectUserName
                                $ModifiedByToSQL = $CurrentFilteretedEvent.winlog.event_data.SubjectUserName
                            }
                        }
                        else {
                            $Modifier = $VerifiedADObjects | where samAccountName -eq $CurrentFilteretedEvent.winlog.event_data.SubjectUserName | Select Name, samAccountName
                            $ModifiedBy = "$($Modifier.Name)</br><font color=`"#a1a1a5`">($($CurrentFilteretedEvent.winlog.event_data.SubjectUserName))</font>"
                            $ModifiedByToSQL = $Modifier.Name
                        }

                        # Builds a list of modifications per event and adds object to array if it is not empty
                        $Modifications = $null
                        if ( $CompareResultOwner ) { $Modifications += "$CompareResultOwner" }
                        if ( $CompareResultGroup ) { $Modifications += "$CompareResultGroup" }
                        if ( $CompareResultDACL  ) { $Modifications += "$CompareResultDACL" }
                        if ( $CompareResultSACL  ) { $Modifications += "<b>System ACL changes:</b></br>$($CompareResultSACL | out-string)" }

                        # build current object and add to array
                        $CurrentObj = New-Object PSObject -Property @{
                            CorrID          = $CurrentFilteretedEvent.winlog.event_data.OpCorrelationID
                            Timestamp       = $Timestamp
                            'Target Object' = "<b>$($CurrentFilteretedEvent.winlog.event_data.ObjectClass):</b> $ObjectName"
                            Modifications   = $Modifications
                            "Modified by"   = $ModifiedBy
                        }
                        if ( $Modifications ) {
                            if ( $ScriptVariables.WriteToSQL ) {
                                # The primary key in the table Events is OpCorrelationID, so duplicates wont exist
                                Add-ACLEventRecord -Timestamp $TimestampSQL -OpCorrelationID $CurrentObj.CorrID -Modifier $ModifiedByToSQL -ModifierSAM $CurrentFilteretedEvent.winlog.event_data.SubjectUserName -TargetObject $ObjectName -TargetType $CurrentFilteretedEvent.winlog.event_data.ObjectClass
                            }
                            $EventsToSend += $CurrentObj
                        }
                    }
                }
                #region building HTML, building the page more or less from the bottom to the top
                    # Set page topic
                    $H2String = "Summary of Access Control List (ACL) Modifications"
                    $HTMLTableForEmail = $null # debug, will be empty when run through scheduled task
                    # Set topic and headers for Modifications
                    $HTMLTableForEmail = $HTMLTableForEmail + "<tr><td style=`"text-align:center`"><h2>List of ACL modifications (last $Timeframe)</h2></td></tr>"
                    $HTMLTableForEmail = $HTMLTableForEmail + "<tr><td><table id=`"t01`"><th>Timestamp</th><th>Modified by</th><th>Target Object</th><th>Modifications</th>"
                    # Set table for Top Modifiers
                    $HTMLTopModsTable = "<tr><td><h2>Top 5 modifiers</h2></td></tr>"
                    $HTMLTopModsTable = $HTMLTopModsTable + "<table id=`"t01`"><th>Modified by</th><th style=`"text-align:right;`">Count</th>"
                    $counter = 0
                    foreach ( $TopModifier in $EventsToSend | group 'Modified by' | Select -First 5 | Sort-Object Count -Descending) {
                        if ( $counter % 2 -eq 0 ) {
                            $color = '#ffffff'
                        }
                        else {
                            $color = '#eeeeee'
                        }
                        $counter++
                        $HTMLTopModsTable = $HTMLTopModsTable + "<tr style=`"background-color:$($color)`"><td>$($TopModifier.Name)</td><td style=`"text-align:right`">$($TopModifier.Count)</td></tr>"
                    }
                    $HTMLTopModsTable = $HTMLTopModsTable + "</table></td></tr>"
                    # Set table structure Modifications
                    $counter = 0
                    foreach ( $Mod in $EventsToSend ) {
                        if ( $counter % 2 -eq 0 ) {
                            $color = '#ffffff'
                        }
                        else {
                            $color = '#eeeeee'
                        }
                        $counter++

                        # sets another background color if event contains a critical permission
                        $HTMLTableForEmail = $HTMLTableForEmail + "<tr style=`"background-color:$($color)`"><td width=`"200px`">$($Mod.Timestamp)</td><td width=`"200px`">$($Mod.'Modified by')</td><td>$($Mod.'Target Object')</td><td width=`"*`">$($Mod.Modifications)<font color=`"$($color)`">$($Mod.CorrID)</font></td></tr>"
                    }
                    # Add end of table Modifiers to HTML
                    $HTMLTableForEmail = $HTMLTableForEmail + "</table></td></tr></table>"
                    # Add the table Top Modifiers to HTML
                    $HTMLTableForEmail = $HTMLTopModsTable + $HTMLTableForEmail 
                    # Set table structure for Summary
                    $SummaryTable = "<tr><td><table align=`"center`" id=`"tsum`"><tr><td><b>Total Modifications:</b></td><td><b>Added ACEs:</b></td><td><b>Removed ACEs</b></td><td><b>Potentially Critical events</b></td></tr><tr><td><font size = `"6`">$($EventsToSend.Count)</font></td><td><font size = `"6`" color=`"#3f82b0`">$ACEAdded</font></td><td><font size=`"6`" color=`"#a50134`">$ACERemoved</font></td><td><font size=`"6`" color=`"#b8812e`">$ACECriticals</font></td></tr></table></td></tr>"
                    # Add the table Summary to HTML
                    $HTMLTableForEmail = $SummaryTable + $HTMLTableForEmail
                    # Add the page topic last
                    $HTMLTableForEmail = "<tr><td>Report created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</td></tr>" + $HTMLTableForEmail
                    $HTMLTableForEmail = "<table align=`"center`"><tr><td><h2>$H2String</h2></td></tr>" + $HTMLTableForEmail
                    # Add the CSS variable to the top
                    $HTMLTableForEmail = $Style + $HTMLTableForEmail
                #endregion
            }

            if ($EventsToSend.Count -gt 0 ) {
                $ExecuteNotificationBlock = $true
                $HTMLTableForEmail | out-file "C:\PowerShell\TaskScheduler\Get-ADACLModifications\LastStatusSent.html"
            }
            else {
                $ExecuteNotificationBlock = $false
            }
        }
    #endregion
#endregion

#region SEND NOTIFICATION VIA EMAIL
    if ( $ExecuteNotificationBlock -and !$SkipNotification ) {
        $mail = New-Object System.Net.Mail.MailMessage -Property @{
            From       = $ScriptVariables.MailFrom
            Subject    = $ScriptVariables.MailSubject
            Body       = $HTMLTableForEmail
            IsBodyHtml = $true
        }
        $mail.To.Add($ScriptVariables.ToRecipients)
        $SMTPClient = New-Object -TypeName System.Net.Mail.SmtpClient( $ScriptVariables.SMTPServer )
        $SMTPClient.Send( $Mail )
    }
#endregion