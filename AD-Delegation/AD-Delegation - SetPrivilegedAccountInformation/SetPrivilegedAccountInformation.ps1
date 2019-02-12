Function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string]$Message,
        [Parameter(Position=1)]
        [ValidateSet('INFO','WARN','ERROR')][string]$LogType = 'INFO',
        [Parameter(Position=2)]
        [ValidateSet('Yes','No')][string]$WritePrefix = 'Yes'
    )
    $CurrentDateTime = Get-Date -format "yyyy-MM-dd HH:mm"
    if($Message -eq $null){ $Message = "" }
    If ( $WritePrefix -eq "YES" ) {
        $LogEntry = "$LogType $CurrentDateTime - $Message"
    }
    Else {
        $LogEntry = "$Message"
    }
    Add-Content -Value $LogEntry -Path $LogFile -Encoding UTF8
    Write-Verbose $LogEntry
}

$ProdServer = "domain1"
$LookupDomains = @("domain1","domain2")
$ProdStdUsers = "OU=StandardUsers,DC=domain1,DC=local"

# Sets information on the privileged accounts based on attributes from standard user in wp.ams.se
Function SetInformation () {
    $LogFile = "C:\Program Files (x86)\AMSPgm\Logs\AD-Delegation - SetPrivilegedAccountInformation.log"
    $Counter = 0
    ForEach ( $LookupDomain in $LookupDomains ) {
        $DomainDN = $(Get-ADDomain -Server $LookupDomain).DistinguishedName
        $Domain = $(Get-ADDomain -Server $LookupDomain).Name.ToUpper()
        $PrivilegedUsers = $(Get-ADUser -filter 'Enabled -eq $True' -SearchBase "OU=Admin,$DomainDN" -Server $LookupDomain -Properties samAccountName, info, title, department, streetAddress, postalAddress, postalCode, l | Sort samAccountName)
        ForEach ( $User in $PrivilegedUsers ) {
            If ( $User.samAccountName -notlike "T0*" ) {
                $UserAttributes = $(Get-ADUser -LDAPFilter "(name=$($User.samAccountName.Substring(2,5)))" -SearchBase $ProdStdUsers -Server $ProdServer -Properties Manager,department,postalAddress,postalCode,streetAddress,l,title,extensionAttribute2)
                If ( $UserAttributes.Title -ne $Null ) {
                    If ( $UserAttributes.Title -ne $User.Title ) {
                        Try {
                            Set-ADUSer $User.samAccountName -Server $LookupDomain -Replace @{title="$($UserAttributes.Title)"}
                            Write-Log "$Domain\$($User.samAccountName) - Changes where made to the attribute ""title"", from ""$($User.Title)"" to ""$($UserAttributes.Title)""" -LogType INFO
                        }
                        Catch {
                            Write-Log "$Domain\$($User.samAccountName) - Couldn't apply changes to the attribute ""title"", from ""$($User.Title)"" to ""$($UserAttributes.Title)""" -LogType ERROR
                        }
                    }
                }
                If ( $UserAttributes.Department -ne $Null ) {
                    If ( $UserAttributes.Department -ne $User.Department ) {
                        Try {
                            Set-ADUSer $User.samAccountName -Server $LookupDomain -Replace @{department="$($UserAttributes.Department)"}
                            Write-Log "$Domain\$($User.samAccountName) - Changes where made to the attribute ""department"", from ""$($User.Department)"" to ""$($UserAttributes.Department)""" -LogType INFO
                        }
                        Catch {
                            Write-Log "$Domain\$($User.samAccountName) - Couldn't apply changes to the attribute ""department"", from ""$($User.Department)"" to ""$($UserAttributes.Department)""" -LogType ERROR
                        }
                    }
                }
                If ( $UserAttributes.StreetAddress -ne $Null ) {
                    If ( $UserAttributes.StreetAddress -ne $User.StreetAddress ) {
                        Try {
                            Set-ADUSer $User.samAccountName -Server $LookupDomain -Replace @{streetAddress="$($UserAttributes.StreetAddress)"}
                            Write-Log "$Domain\$($User.samAccountName) - Changes where made to the attribute ""streetAddress"", from ""$($User.StreetAddress)"" to ""$($UserAttributes.StreetAddress)""" -LogType INFO
                        }
                        Catch {
                            Write-Log "$Domain\$($User.samAccountName) - Couldn't apply changes to the attribute ""steetAddress"", from ""$($User.StreetAddress)"" to ""$($UserAttributes.StreetAddress)""" -LogType ERROR
                        }
                    }
                }
                If ( $UserAttributes.PostalAddress -ne $Null ) {
                    If ( $UserAttributes.PostalAddress -ne $User.PostalAddress ) {
                        Try {
                            Set-ADUSer $User.samAccountName -Server $LookupDomain -Replace @{postalAddress="$($UserAttributes.postalAddress)"}
                            Write-Log "$Domain\$($User.samAccountName) - Changes where made to the attribute ""postalAddress"", from ""$($User.postalAddress)"" to ""$($UserAttributes.postalAddress)""" -LogType INFO
                        }
                        Catch {
                            Write-Log "$Domain\$($User.samAccountName) - Couldn't apply changes to the attribute ""postalAddress"", from ""$($User.postalAddress)"" to ""$($UserAttributes.postalAddress)""" -LogType ERROR
                        }
                    }
                }
                If ( $UserAttributes.PostalCode -ne $Null ) {
                    If ( $UserAttributes.PostalCode -ne $User.PostalCode) {
                        Try {
                            Set-ADUSer $User.samAccountName -Server $LookupDomain -Replace @{postalCode="$($UserAttributes.PostalCode)"}
                            Write-Log "$Domain\$($User.samAccountName) - Changes where made to the attribute ""postalCode"", from ""$($User.postalCode)"" to ""$($UserAttributes.postalCode)""" -LogType INFO
                        }
                        Catch {
                            Write-Log "$Domain\$($User.samAccountName) - Couldn't apply changes to the attribute ""postalCode"", from ""$($User.postalCode)"" to ""$($UserAttributes.postalCode)""" -LogType ERROR
                        }
                    }
                }
                If ( $UserAttributes.l -ne $Null ) {
                    If ( $UserAttributes.l -ne $User.l) {
                        Try {
                            Set-ADUSer $User.samAccountName -Server $LookupDomain -Replace @{l="$($UserAttributes.l)"}
                            Write-Log "$Domain\$($User.samAccountName) - Changes where made to the attribute ""l (location)"", from ""$($User.l)"" to ""$($UserAttributes.l)""" -LogType INFO
                        }
                        Catch {
                            Write-Log "$Domain\$($User.samAccountName) - Couldn't apply changes to the attribute ""l (location)"", from ""$($User.l)"" to ""$($UserAttributes.l)""" -LogType ERROR
                        }
                    }
                }
                If ( $UserAttributes.Manager -ne $Null -or $UserAttributes.extensionAttribute2 -ne $Null ) {
                    If ( $UserAttributes.Manager -ne $Null ) {
                        $Manager = $UserAttributes.Manager.SubString(3,5)
                    }
                    Else {
                        $Manager = ""
                    }
                    $ExtensionAttribute2 = $UserAttributes.extensionAttribute2
                    $NewInfo = "Manager: $Manager`r`n`extensionAttribute2: $ExtensionAttribute2"
                    If ( $NewInfo -ne $($User.info) ) {
                        Try {
                            Set-ADUSer $User.samAccountName -Server $LookupDomain -Replace @{info="$NewInfo"}
                            If ( $User.Info -notlike "*$($UserAttributes.Manager.SubString(3,5))*" ) {
                                If ( $User.Info -like "*Manager:*" ) {
                                    $OldManager = $User.Info.Split()[1]
                                }
                                Else {
                                    $OldManager = ""
                                }                              
                                Write-Log "$Domain\$($User.samAccountName) - Changes where made to the attribute ""info (manager)"", from ""$OldManager"" to ""$Manager""" -LogType INFO
                            }
                            If ( $User.Info -notlike "*$($UserAttributes.extensionAttribute2)*" ) {
                                If ( $User.Info -like "*extensionAttribute2:*" ) {
                                    $OldExtensionAttribute2 = $User.Info.Split()[4]
                                }
                                Else {
                                    $OldExtensionAttribute2 = ""
                                }
                                Write-Log "$Domain\$($User.samAccountName) - Changes where made to the attribute ""info (extensionAttribute2)"", from ""$OldExtensionAttribute2"" to ""$ExtensionAttribute2""" -LogType INFO
                            }
                        }
                        Catch {
                        }
                    }
                }
                Else {
                    If ( $UserAttributes.Manager -eq $Null ) {
                        Write-Log "$Domain\$($User.samAccountName) - The attribute ""manager"" is empty" -LogType ERROR
                    }
                    If ( $UserAttributes.extensionAttribute2 ) {
                        Write-Log "$Domain\$($User.samAccountName) - The attribute ""extensionAttribute2"" is empty" -LogType ERROR
                    }
                }
            }
        }
    }
}

SetInformation