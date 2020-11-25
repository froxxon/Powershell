## This script queries ElasticSearch for events where ACLs has been modified
##
## Auhtor: Fredrik Bergman, 2020-11-10
## Version 1.0.0 - First version //Fredrik Bergman 2020-11-13
## Version 1.0.1 - AllGPOs now obtain its information from Get-ADObject instead och Get-GPO  //Fredrik Bergman 2020-11-14
## Version 1.0.1 - Moved Active Directory functions to module 'ActiveDirectoryRightsModule' //Fredrik Bergman 2020-11-14
## Version 1.0.1 - Added the highlightning when addition of critical events (ex. FullControl) //Fredrik Bergman 2020-11-14
## Version 1.0.2 - Added highlightning of Timestamp if it happens between 20.00 and 06.59 //Fredrik bergman 2020-11-15
## Version 1.0.2 - Added hightligtning of the specific permissions considered Critical under Access //Fredrik Bergman 2020-11-15
## Version 1.0.3 - Merged columns 'Object Type' and 'Object (Name)' to 'Target Object' //Fredrik Bergman 2020-11-15
## Version 1.0.3 - Added samAccountName (by SubjectUserName) to 'Modified by' //Fredrik Bergman 2020-11-15
## Version 1.0.4 - Added functionality to write to database //Fredrik Bergman 2020-11-18
## Version 1.0.5 - Rebuilt script to handle HTML-report in separate script //Fredrik Bergman //2020-11-20
## Version 1.0.6 - Added TargetDN to the Event database and updated scripts accordingly //Fredrik Bergman //2020-11-25
## Version 1.0.7 - Added displaynames for GPO Permissions if objectType equal groupPolicyContainer //Fredrik Bergman //2020-11-25
##

#region DECLARE SCRIPT DEPENDENCIES
    $ScriptVariables = @{
        "ScriptFolder"            = "C:\PowerShell\TaskScheduler\Get-ADACLModifications"
        "ACLHistoryManagement"    = "C:\PowerShell\TaskScheduler\Get-ADACLModifications\Modules\ACLHistoryManagement.psm1"
        "ADRightsModulePath"      = "C:\Powershell\TaskScheduler\Get-ADACLModifications\Modules\ActiveDirectoryRightsModule.psm1"
        "ElasticSearchUri"        = "http://192.168.2.205:9200"
        "ExcludedSDDLs"           = @(
                                      'Everyone: Deny DeleteTree, Delete This Object Only',
                                      'Everyone: Deny Delete Subtree, Delete This Object Only',
                                      'Everyone: Deny ExtendedRight Change Password This Object Only',
                                      'NT AUTHORITY\SELF: Deny ExtendedRight Change Password This Object Only',
                                      'NT AUTHORITY\SELF: Allow ExtendedRight Send As This object and all descendant objects',
                                      'NT AUTHORITY\SELF: Allow Read All Properties;Write All Properties Personal Information This object and all descendant objects'
                                    )
        "WriteToSQL"              = $true
    }

    Import-Module $ScriptVariables.ACLHistoryManagement
    Import-Module $ScriptVariables.ADRightsModulePath

    $Timeframe = '1h'
    $IndexThreshold = '1000'
    $DCAuditTag = "dcsecurity"

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
            if($_.ErrorDetails.Message -match "missing authentication credentials for REST request"){
                Write-Warning "Did you forget to specify credentials when connecting to `"$ElasticSearchUri`"? API Response:$($(($_ | ConvertFrom-Json).error.reason))"
            }
            elseif($_.ErrorDetails.Message -match "unable to authenticate user"){
                Write-Warning "User $($Credential.UserName) could not be authenticated when connecting to `"$ElasticSearchUri`". Are you sure this user exists? API Response:$($(($_ | ConvertFrom-Json).error.reason))"
            }
            elseif($_.ErrorDetails.Message -match "failed to authenticate user"){
                Write-Warning "Did you type the wrong password for user $($Credential.UserName) when connecting to `"$ElasticSearchUri`". API Response:$($(($_ | ConvertFrom-Json).error.reason))"
            }
            elseif($_.Exception.Message -match "The underlying connection was closed"){
                Write-Warning "Error occurred during Invoke-RestMethod with uri `"$ElasticSearchUri`". Make sure you dont use http against https and vice versa. Exception:$($_.Exception.Message)"
            }
            elseif($_.Exception.Message -match "\(404\) Not Found"){
                Write-Warning "Are you sure `"$ElasticSearchUri`" is correct? Check that again please. Exception:$($_.Exception.Message)"
            }
            else{
                Write-Warning "Error occurred during Invoke-RestMethod with uri `"$ElasticSearchUri`". Exception:$($_.Exception.Message)"
            }
        }
    #endregion
}

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
        { `"match`": { `"tags`": `"$DCAuditTag`" }},
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
    if ( !$ElasticSearchResults ) { $ElasticSearchResults = Invoke-ElasticSearchRequest -ElasticSearchUri $ScriptVariables.ElasticSearchUri -DSLQuery $DSLQuery }
    # Gathers a list of all attributes and Extended rights in the AD schema to use as display names
    if ( !$ADRightsGUIDs ) { $ADRightsGUIDs = Get-ADRightsGUIDs }
    # Gathers a list of all group policies in the domain to use as display names
    if ( !$AllGPOs ) { $AllGPOs = Get-ADObject -LDAPFilter "(objectClass=groupPolicyContainer)" -SearchBase "CN=Policies,CN=System,$((Get-ADDomain).DistinguishedName)" -Properties DisplayName | Select DisplayName, Name }

    if($ElasticSearchResults.hits.hits.Count -gt 0){
        $FilteredEvents = @($ElasticSearchResults.hits.hits._source) | Sort '@timestamp' -Descending
        #$FilteredEvents = $FilteredEvents | where { $_.winlog.event_data.OpCorrelationID -eq '{99b90236-a887-4a39-976d-a078f08bdab0}' } # debug
        $FilteredEvents.count # debug - shows current objects found in Elastic

        [array]$EventsToSend      = @() # Array with Events that will be sent
        [array]$UsedCorrIDs       = @() # Contains a list with already checked OpCorrelationIDs
        [array]$VerifiedADObjects = @() # Contains a list of checked Active Directory identities

        if($FilteredEvents.Count -gt 1){
            # loop through every event found in Elastic
            Foreach($CurrentFilteretedEvent in $FilteredEvents ){
                if ( $CurrentFilteretedEvent.winlog.event_data.OpCorrelationID -notin $UsedCorrIDs ) {
                    # convert timestamp to a specified format
                    $Timestamp = Get-Date $CurrentFilteretedEvent.'@timestamp' -format "yyyy-MM-dd HH:mm:ss"
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
                            $CompareResultOwner = "Changed from ""$($CompareOwnerAndGroupOld.Owner)"" to ""$($CompareOwnerAndGroupNew.Owner)"""
                        }
                        # check if change occured for Group
                        if ( $CompareOwnerAndGroupNew.Group -ne $CompareOwnerAndGroupOld.Group ) {
                            $CompareResultGroup = "Changed from ""$($CompareOwnerAndGroupOld.Group)"" to ""$($CompareOwnerAndGroupNew.Group)"""
                        }
                                
                        $NewEvent = $($CompareEvents.winlog.event_data | Where OperationType -eq '%%14674').AttributeValue
                        $OldEvent = $($CompareEvents.winlog.event_data | Where OperationType -eq '%%14675').AttributeValue
                        $ComparedSDDLs = Compare-SDDLValues -NewSDDL $NewEvent -OldSDDL $OldEvent
                        if ( $ComparedSDDLs ) {
                            $ADSObject  = New-Object System.DirectoryServices.ActiveDirectorySecurity
                            $ADSObject.SetSecurityDescriptorSddlForm($("D:$($ComparedSDDLs.SDDL -join '')"))
                            $ADSAccessRules = $ADSObject.GetAccessRules($true, $false, [System.Security.Principal.NTAccount])   
                            if ( $ADSAccessRules ) {
                                [array]$tempResultDACL = Get-ACERights -SID $ADSAccessRules
                            }
                            $CompareResultDACL = @()
                            foreach ( $result in $tempResultDACL ) {
                                # skip excluded server names
                                if ( $($CurrentFilteretedEvent.winlog.event_data.SubjectUserName) -notin $ScriptVariables.ExcludedServers ) {
                                    #write-output "$($result.IdentityReference): $($result.access) $($result.Permission) $($result.ApplyTo)" # debug
                                    # if ObjectType is a groupPolicyContainer, then translate Permission accordingly
                                    if ( $CurrentFilteretedEvent.winlog.event_data.ObjectClass -eq 'groupPolicyContainer' ) {
                                        if ( $result.Permission -eq ('Create All Child Objects, Delete All Child Objects, Read All Properties, Write All Properties, Delete, GenericExecute, Modify Permissions, Modify Owner').Trim() ) {
                                            $result.Permission = 'Edit Settings, delete, modify security (GPO)'
                                        }
                                        if ( $result.Permission -eq ('Create All Child Objects, Delete All Child Objects, Read All Properties, Write All Properties, GenericExecute').Trim() ) {
                                            $result.Permission = 'Edit Settings (GPO)'
                                        }
                                        if ( $result.Permission -eq ('Read All Properties, GenericExecute').Trim() ) {
                                            $result.Permission = 'Read (GPO)'
                                        }
                                    }
                                    
                                    # skip excluded permissions
                                    if ( "$($result.IdentityReference): $($result.access) $($result.Permission) $($result.ApplyTo)" -notin $ScriptVariables.ExcludedSDDLs ) {
                                        $Operation = $ComparedSDDLs[$($tempResultDACL.indexOf($result))].Operation
                                        if ( $ScriptVariables.WriteToSQL ) {
                                            # Checksum corresponds to the primary key in the Modification table, so duplicates wont exist
                                            $Checksum = Get-StringHash "$Timestamp $($CurrentFilteretedEvent.winlog.event_data.OpCorrelationID) 'DACL' $($result.access) $($result.IdentityReference) $($result.Permission) $($result.ApplyTo) $($Operation)"
                                            Add-ACLModificationRecord -Timestamp $Timestamp -OpCorrelationID $CurrentFilteretedEvent.winlog.event_data.OpCorrelationID -SDDLType 'DACL' -Type $result.access -Principal $result.IdentityReference -Access $result.Permission.Trim() -AppliesTo $result.ApplyTo -Operation $Operation -Checksum $Checksum
                                        }
                                    }
                                }
                            }
                        }
                        if ( $CompareResultOwner ) {
                            if ( $ScriptVariables.WriteToSQL ) {
                                # Checksum corresponds to the primary key in the Modification table, so duplicates wont exist
                                $Checksum = Get-StringHash "$Timestamp $($CurrentFilteretedEvent.winlog.event_data.OpCorrelationID) 'Owner' $($CompareOwnerAndGroupOld.Owner) $($CompareOwnerAndGroupNew.Owner)"
                                Add-ACLModificationRecord -Timestamp $Timestamp -OpCorrelationID $CurrentFilteretedEvent.winlog.event_data.OpCorrelationID -SDDLType 'Owner' -Type 'N/A' -Principal 'N/A' -Access "Owner changed from ""$($CompareOwnerAndGroupOld.Owner)"" to ""$($CompareOwnerAndGroupNew.Owner)""" -AppliesTo 'N/A' -Operation "Changed" -Checksum $Checksum
                            }
                        }
                        if ( $CompareResultGroup ) {
                            if ( $ScriptVariables.WriteToSQL ) {
                                # Checksum corresponds to the primary key in the Modification table, so duplicates wont exist
                                $Checksum = Get-StringHash "$Timestamp $($CurrentFilteretedEvent.winlog.event_data.OpCorrelationID) 'Group' $($CompareOwnerAndGroupOld.Owner) $($CompareOwnerAndGroupNew.Owner)"
                                Add-ACLModificationRecord -Timestamp $Timestamp -OpCorrelationID $CurrentFilteretedEvent.winlog.event_data.OpCorrelationID -SDDLType 'Group' -Type 'N/A' -Principal 'N/A' -Access "Group changed from ""$($CompareOwnerAndGroupOld.Group)"" to ""$($CompareOwnerAndGroupNew.Group)""" -AppliesTo 'N/A' -Operation "Changed" -Checksum $Checksum
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
                    else { # Otherwise set the variable ObjectName and checks if this is already verified against AD, to skip more Gets than necessary
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
                            $ModifiedBy = $CheckADObject.Name
                        }
                        else {
                            $ModifiedBy = $CurrentFilteretedEvent.winlog.event_data.SubjectUserName
                        }
                    }
                    else {
                        $Modifier = $VerifiedADObjects | where samAccountName -eq $CurrentFilteretedEvent.winlog.event_data.SubjectUserName | Select Name, samAccountName
                        $ModifiedBy = $Modifier.Name
                    }

                    if ( $ScriptVariables.WriteToSQL ) {
                        # The primary key in the table Events is OpCorrelationID, so duplicates wont exist
                        Add-ACLEventRecord -Timestamp $Timestamp -OpCorrelationID $CurrentFilteretedEvent.winlog.event_data.OpCorrelationID -Modifier $ModifiedBy -ModifierSAM $CurrentFilteretedEvent.winlog.event_data.SubjectUserName -TargetObject $ObjectName -TargetDN $CurrentFilteretedEvent.winlog.event_data.ObjectDN -TargetType $CurrentFilteretedEvent.winlog.event_data.ObjectClass
                    }
                }
            }
        }
    }
#endregion