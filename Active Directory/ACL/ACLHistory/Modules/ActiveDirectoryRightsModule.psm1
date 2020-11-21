# convert SIDs to Well Known identifier
function Get-ADSIDIdentity {
    param(
        [string]$SID
    )

    $KnownSIDS = @{
        'S-1-0'        = 'Null Authority'
        'S-1-0-0'      = 'Nobody'
        'S-1-1'        = 'World Authority'
        'S-1-1-0'      = 'Everyone'
        'S-1-2'        = 'Local Authority'
        'S-1-2-0'      = 'Local'
        'S-1-2-1'      = 'Console Logon'
        'S-1-3'        = 'Creator Authority'
        'S-1-3-0'      = 'Creator Owner'
        'S-1-3-1'      = 'Creator Group'
        'S-1-3-4'      = 'Owner Rights'
        'S-1-5-80-0'   = 'All Services'
        'S-1-4'        = 'Non Unique Authority'
        'S-1-5'        = 'NT Authority'
        'S-1-5-1'      = 'Dialup'
        'S-1-5-2'      = 'Network'
        'S-1-5-3'      = 'Batch'
        'S-1-5-4'      = 'Interactive'
        'S-1-5-6'      = 'Service'
        'S-1-5-7'      = 'Anonymous'
        'S-1-5-9'      = 'Enterprise Domain Controllers'
        'S-1-5-10'     = 'Self'
        'S-1-5-11'     = 'Authenticated Users'
        'S-1-5-12'     = 'Restricted Code'
        'S-1-5-13'     = 'Terminal Server Users'
        'S-1-5-14'     = 'Remote Interactive Logon'
        'S-1-5-15'     = 'This Organization'
        'S-1-5-17'     = 'This Organization'
        'S-1-5-18'     = 'Local System'
        'S-1-5-19'     = 'NT Authority Local Service'
        'S-1-5-20'     = 'NT Authority Network Service'
        'S-1-5-32-544' = 'Administrators'
        'S-1-5-32-545' = 'Users'
        'S-1-5-32-546' = 'Guests'
        'S-1-5-32-547' = 'Power Users'
        'S-1-5-32-548' = 'Account Operators'
        'S-1-5-32-549' = 'Server Operators'
        'S-1-5-32-550' = 'Print Operators'
        'S-1-5-32-551' = 'Backup Operators'
        'S-1-5-32-552' = 'Replicators'
        'S-1-5-32-554' = 'Pre-Windows 2000 Compatibility Access'
        'S-1-5-32-555' = 'Remote Desktop Users'
        'S-1-5-32-556' = 'Network Configuration Operators'
        'S-1-5-32-557' = 'Incoming forest trust builders'
        'S-1-5-32-558' = 'Performance Monitor Users'
        'S-1-5-32-559' = 'Performance Log Users'
        'S-1-5-32-560' = 'Windows Authorization Access Group'
        'S-1-5-32-561' = 'Terminal Server License Servers'
        'S-1-5-32-562' = 'Distributed COM Users'
        'S-1-5-32-569' = 'Cryptographic Operators'
        'S-1-5-32-573' = 'Event Log Readers'
        'S-1-5-32-574' = 'Certificate Services DCOM Access'
        'S-1-5-32-575' = 'RDS Remote Access Servers'
        'S-1-5-32-576' = 'RDS Endpoint Servers'
        'S-1-5-32-577' = 'RDS Management Servers'
        'S-1-5-32-578' = 'Hyper-V Administrators'
        'S-1-5-32-579' = 'Access Control Assistance Operators'
        'S-1-5-32-580' = 'Remote Management Users'
    }

    if ( $SID ) {
        try {
            $ID = New-Object System.Security.Principal.SecurityIdentifier($SID)
            $ParsedSID = ($ID.Translate( [System.Security.Principal.NTAccount] )).Value
        }
        catch {
            $ParsedSID = ($KnownSIDs.GetEnumerator() | Where Name -eq $SID).Value
            if ( !$ParsedSID ) {
                $ParsedSID = $SID
            }
        }
        finally {
            $ParsedSID
        }
    }
    else {
        $KnownSIDs.GetEnumerator() | sort Name
    }
}

# creates an array of all GUIDs for attributes and Extended rights in AD
function Get-ADRightsGUIDs {
    $GUIDs = @()
    $SchemaGUIDs = Get-ADObject -SearchBase (Get-ADRootDSE).schemaNamingContext -LDAPFilter '(schemaIDGUID=*)' -Properties name, displayName, schemaIDGUID, ObjectClass
    foreach ( $GUID in $SchemaGUIDs ) {
        $obj = New-Object -TypeName psobject
        $obj | Add-Member -MemberType NoteProperty -Name Name -Value $GUID.Name
        $obj | Add-Member -MemberType NoteProperty -Name GUID -Value $([System.Guid]$GUID.schemaIDGUID)
        $obj | Add-Member -MemberType NoteProperty -Name ObjectClass -Value $GUID.ObjectClass
        $GUIDs += $obj
    }
    $ExtendedRightsGUIDs = Get-ADObject -SearchBase "CN=Extended-Rights,$((Get-ADRootDSE).configurationNamingContext)" -LDAPFilter '(&(objectclass=controlAccessRight)(rightsguid=*))' -Properties Name, displayName, rightsGUID, ObjectClass
    foreach ( $GUID in $ExtendedRightsGUIDs ) {
        $obj = New-Object -TypeName psobject
        $obj | Add-Member -MemberType NoteProperty -Name Name -Value $GUID.Name
        $obj | Add-Member -MemberType NoteProperty -Name DisplayName -Value $GUID.displayName
        $obj | Add-Member -MemberType NoteProperty -Name GUID -Value $([System.GUID]$GUID.rightsGUID)
        $obj | Add-Member -MemberType NoteProperty -Name ObjectClass -Value $GUID.ObjectClass
        $GUIDs += $obj
    }
    $GUIDs | Select Name, DisplayName, GUID, ObjectClass | Sort-Object Name
}

# translate names of grouped attributes and inheritance types
function Get-ACERights {
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        [array]$SID
    )

    $ArrayAllACE = New-Object System.Collections.ArrayList
    foreach ( $SIDObject in $SID ) {
        #region Distribute SIDObject attributes
            if( $null -ne $SIDObject.AccessControlType ) {
                $objAccess      = $($SIDObject.AccessControlType.toString())
            }
            else { 
                $objAccess      = $($SIDObject.AuditFlags.toString())
            }
            $objPrinc           = $($SIDObject.IdentityReference.toString())
            $objFlags           = $($SIDObject.ObjectFlags.toString())
            $objType            = $($SIDObject.ObjectType.toString())
            $objIsInheried      = $($SIDObject.IsInherited.toString())
            $objInheritedType   = $($SIDObject.InheritedObjectType.toString())
            $objRights          = $($SIDObject.ActiveDirectoryRights.toString())
            $objInheritanceType = $($SIDObject.InheritanceType.toString())
            $ObjTypeDisplayName = $(($ADRightsGUIDs | Where GUID -eq $objType).DisplayName)
            if ( !$ObjTypeDisplayName ) {
                $ObjTypeDisplayName = $(($ADRightsGUIDs | Where GUID -eq $objType).Name)
            }
            $ObjInheritDisplayName = $(($ADRightsGUIDs | Where GUID -eq $objInheritedType).DisplayName)
            if ( !$ObjInheritDisplayName ) {
                $ObjInheritDisplayName = $(($ADRightsGUIDs | Where GUID -eq $objInheritedType).Name)
            }
        #endregion

        #region Get attribute group translations
        $objRightsStrings = @()
        foreach ( $objRight in $objRights -split ', ' ) {
        # https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.activedirectoryrights?view=dotnet-plat-ext-5.0
            $objRightString = $null
            Switch ($objRight) {
                "Self" { $objRightString = "Validated Write" }
                "GenericRead" { $objRightString = "Read Permissions, List Contents, Read All Properties, List" }
                "CreateChild" { $objRightString = "Create All Child Objects"}
                "DeleteChild" { $objRightString = "Delete All Child Objects" }
                "DeleteTree" { $objRightString = "Delete Subtree" }
                "GenericAll" { $objRightString = "Full Control" }
                "ReadControl" { $objRightString = "Read Permissions" }
                "ReadProperty" { 
                    Switch ($objInheritanceType) {
                        "None" { 
                            Switch ($objFlags) { 
                                "ObjectAceTypePresent" { $objRightString = "Read" }
                    		    "ObjectAceTypePresent, InheritedObjectAceTypePresent" { $objRightString = "Read" }
                                default { $objRightString = "Read All Properties" }
                            }
                        }
                        "Children" {
                            Switch ($objFlags) { 
                                "ObjectAceTypePresent" { $objRightString = "Read" }
                    		    "ObjectAceTypePresent, InheritedObjectAceTypePresent" { $objRightString = "Read" }
                                default { $objRightString = "Read All Properties" }
                            }
                        }
                        "Descendents" {
                            Switch ($objFlags) { 
                                "ObjectAceTypePresent" { $objRightString = "Read" }
                                "ObjectAceTypePresent, InheritedObjectAceTypePresent" { $objRightString = "Read" }
                                default { $objRightString = "Read All Properties" }
                            }
                        }
                        default { $objRightString = "Read All Properties" }
                    }
                }
                "ExtendedRight" { 
                    switch($objType) {
                        "00000000-0000-0000-0000-000000000000" { $objRightString = "All Extended Rights" }
                    }
                }
                "WriteDacl" { $objRightString = "Modify Permissions" }
                "WriteOwner" { $objRightString = "Modify Owner" }
                "WriteProperty" {
                    Switch ($objInheritanceType) {
                        "None" {
                            Switch ($objFlags) { 
                                "ObjectAceTypePresent" { $objRightString = "Write"	}
                                "ObjectAceTypePresent, InheritedObjectAceTypePresent" { $objRightString = "Write" }
                                default { $objRightString = "Write All Properties" }
                            }
                        }
                        "Children" {
                            Switch ($objFlags) { 
                                "ObjectAceTypePresent" { $objRightString = "Write"	}
                                "ObjectAceTypePresent, InheritedObjectAceTypePresent" { $objRightString = "Write" }
                                default { $objRightString = "Write All Properties" }
                            }
                        }
                        "Descendents" {
                            Switch ($objFlags) { 
                                "ObjectAceTypePresent" { $objRightString = "Write"	}
                                "ObjectAceTypePresent, InheritedObjectAceTypePresent" { $objRightString = "Write" }
                                default { $objRightString = "Write All Properties" }
                            }
                        }
                        default { $objRightString = "Write All Properties" }
                    }
                }
            default {}
            }
            if ( !$objRightString ) {
                $objRightString = $objRight
            }
            #$objRightString
            foreach ( $obj in $objRightString -split ', ' ) {
                if ( $objRightsStrings -notcontains $obj ) {
                    [array]$objRightsStrings += $obj
                }
            }
        }
        $objRights = $objRightsStrings -Join ', '
        #endregion


        #region Get identityReference if it is unknown
            $IdentityReference = $($SIDObject.IdentityReference.toString())
            if ($IdentityReference.contains("S-1-")) {
                $strNTAccount = "$($env:USERDOMAIN)\$(Get-ADSIDIdentity -SID $IdentityReference)"
                $IdentityReference = $strNTAccount
            }
            else {
                $strNTAccount = $IdentityReference
            }
        #endregion

        #region Get Inheritance Type based on ObjectFlags
            Switch ($objInheritanceType) {
                "All" {
            	    Switch ($objFlags) { 
            	    	"InheritedObjectAceTypePresent" {
            	    	    $strApplyTo =  "This object and all descendant objects"
                            $strPerm =  "$objRights $ObjInheritDisplayName"
            	    	}    	
            	    	"ObjectAceTypePresent" {
            	    	    $strApplyTo =  "This object and all descendant objects"
                            $strPerm =  "$objRights $ObjTypeDisplayName"
            	    	} 
            	    	"ObjectAceTypePresent, InheritedObjectAceTypePresent" {
            	    	    $strApplyTo =  "$ObjInheritDisplayName"
                            $strPerm =  "$objRights $ObjTypeDisplayName"
            	    	} 	      	
            	    	"None" {
            	    	    $strApplyTo ="This object and all descendant objects"
                            $strPerm = "$objRights"
            	    	} 
            	    	default {
            	    	    $strApplyTo = "Error"
                            $strPerm = "Error: Failed to display permissions 1K"
            	    	} 	 
            	    }
                }
                "Descendents" {
                	Switch ($objFlags) { 
                		"InheritedObjectAceTypePresent" {
                		    $strApplyTo = "$ObjInheritDisplayName"
                            $strPerm = "$objRights"
                		}
                		"None" {
                		    $strApplyTo = "All descendant objects"
                            $strPerm = "$objRights"
                		} 	      	
                		"ObjectAceTypePresent" {
                		    $strApplyTo = "All descendant objects"
                            $strPerm = "$objRights $ObjTypeDisplayName"
                		} 
                		"ObjectAceTypePresent, InheritedObjectAceTypePresent" {
                		    $strApplyTo = "$ObjInheritDisplayName"
                            $strPerm = "$objRights $ObjTypeDisplayName"
                		}
                		default {
                		    $strApplyTo = "Error"
                            $strPerm = "Error: Failed to display permissions 2K"
                		} 	 
                	} 		
                }
                "None" {
                	Switch ($objFlags) { 
                		"ObjectAceTypePresent" {
                		    $strApplyTo = "This Object Only"
                            $strPerm = "$objRights $ObjTypeDisplayName"
                		} 
                		"None" {
                		    $strApplyTo = "This Object Only"
                            $strPerm = "$objRights"
                		} 
                		default {
                		    $strApplyTo = "Error"
                            $strPerm = "Error: Failed to display permissions 4K"
                		} 	 
                	}
                }
                "SelfAndChildren" {
                	Switch ($objFlags) { 
                		"ObjectAceTypePresent" {
                		    $strApplyTo = "This object and all descendant objects"
                            $strPerm = "$objRights $ObjTypeDisplayName"
                		}
                		"InheritedObjectAceTypePresent" {
                		    $strApplyTo = "All descendant objects"
                            $strPerm = "$objRights $ObjInheritDisplayName"
                		} 
                        "ObjectAceTypePresent, InheritedObjectAceTypePresent" {
                		    $strApplyTo =  "$ObjInheritDisplayName"
                            $strPerm =  "$objRights $ObjTypeDisplayName"
                		} 	      	
                		"None" {
                		    $strApplyTo = "This object and all descendant objects"
                            $strPerm = "$objRights"
                		}                                  	   
                		default {
                		    $strApplyTo = "Error"
                            $strPerm = "Error: Failed to display permissions 5K"
                		} 	 
                	}   	
                } 	
                "Children" {
                    Switch ($objFlags) { 
                		"InheritedObjectAceTypePresent" {
                		    $strApplyTo = "All descendant objects"
                            $strPerm = "$objRights $ObjInheritDisplayName"
                		} 
                		"None" {
                		    $strApplyTo = "All descendant objects"
                            $strPerm = "$objRights"
                		} 	      	
                		"ObjectAceTypePresent, InheritedObjectAceTypePresent" {
                		    $strApplyTo = "$ObjInheritDisplayName"
                            $strPerm = "$ObjTypeDisplayName $objRights"
                		} 	
                		"ObjectAceTypePresent" {
                		    $strApplyTo = "All descendant objects"
                            $strPerm = "$objRights $ObjTypeDisplayName"
                		} 		      	
                		default {
                		    $strApplyTo = "Error"
                            $strPerm = "Error: Failed to display permissions 6K"
                		}
                	}
                }
                default {
                	$strApplyTo = "Error"
                    $strPerm = "Error: Failed to display permissions 7K"
                } 	 
            }

            if ( $objInheritanceType -eq 'Descendents' -and $objFlags -eq 'InheritedObjectAceTypePresent' ) {
                $strApplyTo = $(($ADRightsGUIDs | Where GUID -eq $objInheritedType).DisplayName)
                if ( !$strApplyTo ) {
                    $strApplyTo = $(($ADRightsGUIDs | Where GUID -eq $objInheritedType).Name)
                    if ( !$strApplyTo ) {
                        $strApplyTo = "Error"
                    }
                }
                if ( $strApplyTo -ne 'Error' ) {
                    $strApplyTo = "Descendent $($strApplyTo) objects"
                }
            }
            elseif ( $objInheritanceType -match "(All|Descendents)" -and $objFlags -eq 'ObjectAceTypePresent, InheritedObjectAceTypePresent' ) {
                $strApplyTo = "Descendent $($strApplyTo) objects"
            }
        #endregion
        
        if ( $strPerm -eq 'Validated Write' -and $strPerm -ne 'Validated Write ' ) {
            $strPerm = "All Validated Writes"
        }
        $strPerm = $strPerm -replace '  ',' ' -replace 'DNS Host Name Attributes ','' -replace 'Validated write Validated write','Validated Write'

        $objhashtableACE = [pscustomobject][ordered]@{
            IdentityReference = $IdentityReference
            #Trustee           = $strNTAccount
            Access            = $objAccess
            InheritanceType   = $objInheritanceType
            Inhereted         = $objIsInheried
            ApplyTo           = $strApplyTo
            Permission        = $strPerm
        }
        [void]$ArrayAllACE.Add($objhashtableACE)
    }
    $ArrayAllACE
}

# compare two SDDLs against each other
Function Compare-SDDLValues {
    param(
        [parameter(Mandatory=$true)]
        $NewSDDL,
        [parameter(Mandatory=$true)]
        $OldSDDL
    )

    if($NewSDDL -match "(?<=\().*"){
        $NewSDDLValue = [regex]::match($NewSDDL,"(?<=\().*")
    }
    [array]$NewSDDLArray = ($NewSDDLValue -replace "\)",")`n") -split "\n"
    $NewSDDLArray[0] = "($($NewSDDLArray[0])"
                                    
    if($OldSDDL -match "(?<=\().*"){
        $OldSDDLValue = [regex]::match($OldSDDL,"(?<=\().*")
    }
    [array]$OldSDDLArray = ($OldSDDLValue -replace "\)",")`n") -split "\n"
    $OldSDDLArray[0] = "($($OldSDDLArray[0])"

    $SDDLResultArray = @{}
    foreach ( $Array in $NewSDDLArray ) {
        if ( $Array -notin $OldSDDLArray ) {
            $SDDLResultArray.Add($Array,'Added')
        }
    }
    foreach ( $Array in $OldSDDLArray ) {
        if ( $Array -notin $NewSDDLArray ) {
            $SDDLResultArray.Add($Array,'Removed')
        }
    }
                              
    $ReturnSDDLObject = @()
    foreach($SDDLResultItem in $SDDLResultArray.GetEnumerator()){
        $CurrentObj = New-Object PSObject -Property @{
            ACEs      = (ConvertFrom-SddlString -Sddl "D:$($SDDLResultItem.Name)" -Type ActiveDirectoryRights).RawDescriptor.DiscretionaryAcl
            Operation = $SDDLResultItem.Value
            SDDL      = $SDDLResultItem.Name
        }
        $ReturnSDDLObject += $CurrentObj
    }
    $ReturnSDDLObject
}
