Import-module 'C:\temp\SharedCode.psm1'
$LogFile = "C:\temp\Create-LocalRightsGPOs\Create-LocalRightsGPOs.log"

$DC = Get-ADDomainController -Discover -Domain $Domain
$QueryGroups = "Task-Server-Local*"
$GPOs = $(Get-ADGroup -Server $DC -Filter {name -like $QueryGroups}).Name

Write-Log "Will try to create $($GPOs.Count) group policies on the following domain controller $DC"
Write-Log

ForEach ( $GPO in $GPOs ) {
    
    # Creating GPO
    Try {
        New-GPO -Server $DC -Name $GPO | out-null
        Write-Log "Created the GPO $GPO"
    }
    Catch {
        Write-Log "Couldn't create the GPO $GPO" -LogType ERROR
    }

    # Set the GPOStatus
    Try {
        If ( (get-gpo $GPO -Server $DC).gpostatus -ne "UserSettingsDisabled" ) {
            (get-gpo $GPO -server $DC).gpostatus = "UserSettingsDisabled"
            Write-Log "Changed GPOStatus to UserSettingsDisabled for $GPO"
        }
        Write-Log "The GPOStatus for $GPO is already set to UserSettingsDisabled"
    }
    Catch {
        Write-Log "Couldn't change GPOStatus to UserSettingsDisabled" -LogType ERROR
    }

    # Create the GptTmp.inf file
    Try {
        $GPOGuid = $(Get-GPO $GPO -Server $DC).id
        $GPOGuid = "{" + $GPOGuid + "}"
        Write-Log "Group policy GUID to create the GptTmp.inf file for: $GPOGuid"
        $SecGroupSid = (Get-ADGroup $GPO -Server $DC).SID.Value
        Write-Log "The SID is $SecGroupSid for the group $GPO"
        Write-Log "Creating the folderstructure for \\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\Windows NT\SecEdit"
        If (!(Test-Path "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft")) { New-Item "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\" -type Directory | out-null }
        If (!(Test-Path "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\Windows NT")) { New-Item "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\Windows NT\" -type Directory | out-null }
        If (!(Test-Path "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\Windows NT\SecEdit")) { New-Item "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\Windows NT\SecEdit" -type Directory | out-null }
        $infFile="\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\Windows NT\SecEdit\GptTmpl.inf"
        New-Item $infFile -ItemType File | out-null
        Write-Log "Created the GptTmp.inf in the folderstructure above"
    }
    Catch {
        Write-Log "Something didn't work when creating GptTmp.inf in the folderstructure above" -LogType ERROR
    }

    # Adding information to the GptTmp.inf file
    Try {
        $MemberOf = "*$($SecGroupSid)__Memberof = *S-1-5-32-544"
        If ( $GPO -like "*LocalUser*" ) {
            $MemberOf = "*$($SecGroupSid)__Memberof = *S-1-5-32-555"
        }
        $Members = "*$($SecGroupSid)__Members ="
        $fileContents = "[Unicode]","Unicode=yes","[Version]",'signature="$CHICAGO$"',"Revision=1","[Group Membership]",$MemberOf,$Members
        Set-Content $infFile $fileContents
        Write-Log "Added content for Restricted groups to GptTmp.inf"
    }
    Catch {
        Write-Log "Couldn't add content for Restricted groups to GptTmp.inf" -LogType ERROR
    }

    # Increasing the version in GPT.INI
    Try {
        $GPTINI= "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\GPT.INI"
        $GPTINIContent = Get-Content $GPTINI
        ForEach ( $GPTINIRow in $GPTINIContent ) {
            If ( $GPTINIRow -like "Version=*" ) {
                $TempNumber = $GPTINIRow.Substring(8,1)
                [int]$VersionNumber = $TempNumber
                Write-Log "The current version in GPT.INI is $VersionNumber"
                $VersionNumber++
                Break
            }
        }
        $Version = "Version=$VersionNumber"
        $DisplayName = "displayName=$GPO"
        $fileContents="[General]",$Version,$DisplayName
        Set-Content $GPTINI $fileContents
        Write-Log "Increased the version in GPT.INI to $VersionNumber"
    }
    Catch {
        Write-Log "Failed to Increase the version in GPT.INI to $VersionNumber" -LogType ERROR
    }

    # Sets the gPCMachineExtensionNames to include Restricted groups
    Try {
        Set-ADObject -Server $DC "CN=$GPOGuid,CN=Policies,CN=System,$DomainDN" -Replace @{gPCMachineExtensionNames="[{827D319E-6EAC-11D2-A4EA-00C04F79F83A}{803E14A0-B4FB-11D0-A0D0-00A0C90F574B}]"}
        Write-Log "Replaced the attribute gPCMachineExtensionNames for the policy CN=$GPOGuid,CN=Policies,CN=System,$DomainDN"
    }
    Catch {
        Write-Log "Couldn't replace the attribute gPCMachineExtensionNames" -LogType ERROR
    }

    # Sets versionNumber to same as GPT.INI
    Try {
        Set-ADObject -Server $DC "CN=$GPOGuid,CN=Policies,CN=System,$DomainDN" -Replace @{versionNumber=$VersionNumber}
        Write-Log "Replaced the attribute versionNumber for the policy CN=$GPOGuid,CN=Policies,CN=System,$DomainDN to match GPT.INI"
    }
    Catch {
        Write-Log "Couldn't replace the attribute versionNumber" -LogType ERROR
    }

    # Linking GPO to OU
    If ( $GPO -like "*LocalUser*" ) {
        $OUName = $GPO -Replace "Task-Server-LocalUser-",""
    }
    If ( $GPO -like "*LocalAdmin*" ) {
        $OUName = $GPO -Replace "Task-Server-LocalAdmin-",""
    }
    $OU = $(Get-ADOrganizationalUnit -Server $DC -LDAPFilter "(name=$OUName)" -SearchBase "OU=Servers,OU=Domain Computers,$DOmainDN" -SearchScope Subtree).DistinguishedName
    If ( $GPO -like "Task-Server-LocalAdmin-All" ) {
        $OU = "OU=Servers,OU=Domain Computers,$DOmainDN"
    }
    Try {
        New-GPLink -Server $DC -Name $GPO -Target $OU | out-null
        Write-Log "Linked $GPO to $OU"
    }
    Catch {
        Write-Log "Couldn't link $GPO to $OU" -LogType ERROR
    }

    Write-Log
}

Write-Log "--- End of log ---"