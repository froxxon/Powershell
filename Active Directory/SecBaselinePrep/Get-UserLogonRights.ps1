$ServerOU = "<SERVER OU>"
[array]$servers = get-adcomputer -ldapfilter '(name=*)' -Properties Name, distinguishedName, Description, OperatingSystem -SearchBase $ServerOU -SearchScope Subtree | where { $_.operatingSystem -like '*Windows*'}
$OutFile = "C:\Temp\MemberServers-URASummary.csv"
$failedsessions = 0
$successessions = 0
$counter = 1
$objects = @()
$ErrorActionPreference = "SilentlyContinue"

foreach( $Server in $Servers ) {
    $Hostname = $Server.Name
    write-host "Processing $Counter / $($Servers.Count) - $Hostname" -NoNewline
    try {
        # Creates session to the remote computer
        $Session = New-PSSession -ComputerName $hostname -ErrorAction SilentlyContinue
        # Invokes command to the remote session specified above
        $localobj = Invoke-Command -Session $Session -ScriptBlock{
            # function to get the Account Name of the specificed SID
            function Get-AccountName {
                param(
                    [String] $principal
                )

                if ( $principal[0] -eq "*" ) {
                    $SIDName = $principal.Substring(1)
                    $sid = New-Object System.Security.Principal.SecurityIdentifier($SIDName)
                    $sid.Translate([Security.Principal.NTAccount]).value
                }
                else {
                    return $principal
                }
            }
            
            # Hash table containing ShortName and DisplayName of each User Rights Assignment
            $UserRights = @{
                "SeTrustedCredManAccessPrivilege"               = "Access Credential Manager as a trusted caller"
                "SeNetworkLogonRight"                           = "Access this computer from the network"
                "SeTcbPrivilege"                                = "Act as part of the operating system"
                "SeMachineAccountPrivilege"                     = "Add workstations to domain"
                "SeIncreaseQuotaPrivilege"                      = "Adjust memory quotas for a process"
                "SeInteractiveLogonRight"                       = "Allow log on locally"
                "SeRemoteInteractiveLogonRight"                 = "Allow log on through Remote Desktop Services"
                "SeBackupPrivilege"                             = "Back up files and directories"
                "SeChangeNotifyPrivilege"                       = "Bypass traverse checking"
                "SeSystemtimePrivilege"                         = "Change the system time"
                "SeTimeZonePrivilege"                           = "Change the time zone"
                "SeCreatePagefilePrivilege"                     = "Create a pagefile"
                "SeCreateTokenPrivilege"                        = "Create a token object"
                "SeCreateGlobalPrivilege"                       = "Create global objects"
                "SeCreatePermanentPrivilege"                    = "Create permanent shared objects"
                "SeCreateSymbolicLinkPrivilege"                 = "Create symbolic links"
                "SeDebugPrivilege"                              = "Debug programs"
                "SeDenyNetworkLogonRight"                       = "Deny access to this computer from the network" 
                "SeDenyBatchLogonRight"                         = "Deny log on as a batch job"
                "SeDenyServiceLogonRight"                       = "Deny log on as a service"
                "SeDenyInteractiveLogonRight"                   = "Deny log on locally"
                "SeDenyRemoteInteractiveLogonRight"             = "Deny log on through Remote Desktop Services"
                "SeEnableDelegationPrivilege"                   = "Enable computer and user accounts to be trusted for delegation"
                "SeRemoteShutdownPrivilege"                     = "Force shutdown from a remote system"
                "SeAuditPrivilege"                              = "Generate security audits"
                "SeImpersonatePrivilege"                        = "Impersonate a client after authentication"
                "SeIncreaseWorkingSetPrivilege"                 = "Increase a process working set"
                "SeIncreaseBasePriorityPrivilege"               = "Increase scheduling priority"
                "SeLoadDriverPrivilege"                         = "Load and unload device drivers"
                "SeLockMemoryPrivilege"                         = "Lock pages in memory"
                "SeBatchLogonRight"                             = "Log on as a batch job"
                "SeServiceLogonRight"                           = "Log on as a service"
                "SeSecurityPrivilege"                           = "Manage auditing and security log"
                "SeRelabelPrivilege"                            = "Modify an object label"
                "SeSystemEnvironmentPrivilege"                  = "Modify firmware environment values"
                "SeManageVolumePrivilege"                       = "Perform volume maintenance tasks"
                "SeProfileSingleProcessPrivilege"               = "Profile single process"
                "SeSystemProfilePrivilege"                      = "Profile system performance"
                "SeUndockPrivilege"                             = "Remove computer from docking station"
                "SeAssignPrimaryTokenPrivilege"                 = "Replace a process level token"
                "SeRestorePrivilege"                            = "Restore files and directories"
                "SeShutdownPrivilege"                           = "Shut down the system"
                "SeSyncAgentPrivilege"                          = "Synchronize directory service data"
                "SeTakeOwnershipPrivilege"                      = "Take ownership of files or other objects"
            }

            # Hash table containing Microsofts baseline recommended settings for each User Rights Assignment
            $MSUserRights = @{
                "Access Credential Manager as a trusted caller"                  = "[[Empty]]"
                "Access this computer from the network"                          = "*S-1-5-11,*S-1-5-32-544"
                "Act as part of the operating system"                            = "[[Empty]]"
                "Allow log on locally"                                           = "*S-1-5-32-544"
                "Back up files and directories"                                  = "*S-1-5-32-544"
                "Create a pagefile"                                              = "*S-1-5-32-544"
                "Create a token object"                                          = "[[Empty]]"
                "Create global objects"                                          = "*S-1-5-19,*S-1-5-20,*S-1-5-32-544,*S-1-5-6"
                "Create permanent shared objects"                                = "[[Empty]]"
                "Debug programs"                                                 = "*S-1-5-32-544"
                "Deny access to this computer from the network"                  = "*S-1-5-114"
                "Deny log on through Remote Desktop Services"                    = "*S-1-5-113"
                "Enable computer and user accounts to be trusted for delegation" = "[[Empty]]"
                "Force shutdown from a remote system"                            = "*S-1-5-32-544"
                "Impersonate a client after authentication"                      = "*S-1-5-19,*S-1-5-20,*S-1-5-32-544,*S-1-5-6"
                "Load and unload device drivers"                                 = "*S-1-5-32-544"
                "Lock pages in memory"                                           = "[[Empty]]"
                "Manage auditing and security log"                               = "*S-1-5-32-544"
                "Modify firmware environment values"                             = "*S-1-5-32-544"
                "Perform volume maintenance tasks"                               = "*S-1-5-32-544"
                "Profile single process"                                         = "*S-1-5-32-544"
                "Restore files and directories"                                  = "*S-1-5-32-544"
                "Take ownership of files or other objects"                       = "*S-1-5-32-544"            
            }

            $remoteobjects = @()
            $tempFile = "C:\Windows\Temp\UserRights.txt"
            
            # Creates temporary file with data to retrive User Rights Assignments
            # requires out-null or empty objects could be added to array
            secedit /export /areas USER_RIGHTS /cfg $tempFile | out-null
            
            # Gathers the result from the secedit command, regex is used to only obtain the correct key/value pairs
            $content = $(Select-String '^(Se\S+) = (\S+)' $tempFile | Select line).line
            foreach ( $line in $content ) {
                
                if ( $line -match "\w[^=\s]*" ) {
                    $Shortname = $matches.Values.trim()
                }
                else { $ShortName = "<Unknown>" }

                $DisplayName = $UserRights.$Shortname

                if ( $line -match "(?<=\=).*" ) {
                    [array]$tempSIDs = $matches.Values.trim() -split ','
                }
                else { [array]$tempSIDs += "[[Empty]]" }
                if ( ($tempSIDs -join ',') -eq $MSUserRights.$DisplayName ) {
                    $Status = 'Match'
                }
                elseif ( $MSUserRights.Keys -notcontains $DisplayName ) {
                    $Status = 'N/A'
                }
                else {
                    $Status = 'Different'
                }

                if ( $Shortname -ne "<Unknown>" -or $Shortname -ne "" -or $Shortname -ne $null ) {
                    $SIDs = @()
                    foreach ( $SID in $tempSIDs ) {
                        $SIDs += Get-AccountName $SID
                    }
                    $obj = New-Object PSObject -Property ([ordered]@{ 
                        Hostname    = $env:COMPUTERNAME
                        DisplayName = $DisplayName
                        Status      = $Status
                        SIDs        = $SIDs
                    })
                    if ( $obj ) {
                        $remoteobjects += $obj
                    }
                }
            }
            foreach ( $MSUserRight in $MSUserRights.keys ) {
                if ( $remoteobjects.DisplayName -notcontains $MSUserRight ) {
                    [array]$tempSIDs += "[[Empty]]"
                    if ( $tempSIDs -eq $MSUserRights.$MSUserRight ) {
                        $Status = 'Match'
                    }
                    elseif ( $MSUserRights.Keys -notcontains $MSUserRight ) {
                        $Status = 'N/A'
                    }
                    else {
                        $Status = 'Different'
                    }                    
                    $obj = New-Object PSObject -Property ([ordered]@{ 
                        Hostname    = $env:COMPUTERNAME
                        DisplayName = $MSUserRight
                        Status      = $Status
                        SIDs        = "Empty"
                    })
                    if ( $obj ) {
                        $remoteobjects += $obj
                    }
                }
            }
            remove-item $tempFile -ErrorAction SilentlyContinue
            return $remoteobjects
        }
        write-host " - " -NoNewline
        write-host "succeeded" -ForegroundColor Green
        $successessions++
    }
    catch {
        write-host " - " -NoNewline
        write-host "failed" -ForegroundColor Red
        $failedsessions++
    }
    finally {
        $Counter++
        if ( $localobj ) {
            $objects += $localobj | Select HostName, DisplayName, Status, SIDs | Sort DisplayName
        }
        if ( $Session ) {
            Remove-PSSession $Session -ErrorAction SilentlyContinue
        }
    }
}
#$objects | sort Hostname, DisplayName | ft * -AutoSize
$objects | select HostName, DisplayName, Status, @{Name='SIDs';Expression={$_.SIDs -join ','}} | convertto-csv -Delimiter ';' | % {$_ -replace '"',''} | out-file $outFile -Encoding utf8