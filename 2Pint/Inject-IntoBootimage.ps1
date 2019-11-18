# An easier way to get your bootimage working with WinPE, BranchCache and the help of 2Pint Softwares tool WinPEGen.
# Make sure ADK is in place and run with elevated permissions (needed to moutn ISO for example, will warn and abort otherwise!).
# Dont forget to change variables to suite your environment!
# 
# Requires OSD Toolkit 2.2.2.1 or later

#region CustomVariables
    $WinPEGenPath = 'C:\Temp\Stifler\2Pint Software OSD Toolkit 2.2.2.1\WinPE Generator\x64'
    $StifleRClientSource = "C:\Temp\StifleR\StifleR Client 2.3.0.0"
    $ADKPath = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM'
    $PackagePath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs"
    $WIMPath = 'C:\WinPE_x64'
    $MountPath = 'C:\Mount'
    $InstallWIMFile = 'install.wim'
    $BootWIMFile = 'boot.wim'
#endregion

function Verify-Path {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    If (!(Test-Path $Path)) {
        write-host "Path not found: " -NoNewline
        write-host $Path -NoNewline -ForegroundColor Yellow
        write-host ", " -NoNewline
        write-host "aborting!" -ForegroundColor Red
        Write-Host " "
        if (!$psISE) {
            read-host “Press ENTER to continue...”
            exit
        }
    }
}

# AF Specific groups
if ( $((New-Object System.DirectoryServices.DirectorySearcher("(&(objectCategory=User)(samAccountName=$($env:username)))")).FindOne().GetDirectoryEntry().memberOf) -like '*Role-T1-Infrastructure*' -or $((New-Object System.DirectoryServices.DirectorySearcher("(&(objectCategory=User)(samAccountName=$($env:username)))")).FindOne().GetDirectoryEntry().memberOf) -like '*Role-T1-Operations*' ) {}
else {
    write-host " "
    write-host "DON'T CLICK ON SOMETHING THAT DOESN'T BELONG TO YOU!" -ForegroundColor Red
    write-host " "
    read-host “Press ENTER to continue...”
    exit
}

if ($psISE) { clear-host }

write-host "Script to create BCENABLEDBOOTIMAGE"
write-host "(make sure the correct version of ADK is installed on this computer)" -ForegroundColor DarkGray
write-host " "
write-host "Listing values of variables (change in top of script if needed)" -ForegroundColor DarkGray
write-host "Path to WINPEGen       : " -NoNewline ; write-host $WinPEGenPath -ForegroundColor Yellow
Write-host "Path to StifleR Client : " -NoNewline ; write-host $StifleRClientSource -ForegroundColor Yellow
write-host "Path to ADK            : " -NoNewline ; write-host $ADKPath -ForegroundColor Yellow
write-host "Path to ADK packages   : " -NoNewline ; write-host $PackagePath -ForegroundColor Yellow
write-host "Path to WIM files      : " -NoNewline ; write-host $WIMPath -ForegroundColor Yellow
write-host "Path to Mount          : " -NoNewline ; write-host $MountPath -ForegroundColor Yellow
write-host "Name of Install.wim    : " -NoNewline ; write-host $InstallWIMFile -ForegroundColor Yellow
write-host "Name of Boot.wim       : " -NoNewline ; write-host $BootWIMFile -ForegroundColor Yellow
write-host " "

# Verify local Administrator membership
If (! ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") ) {
    write-host "This script needs to be started with elevated credentials, " -NoNewline
    write-host "aborting!" -ForegroundColor Red
    write-host " "
    if (!$psISE) {
        read-host “Press ENTER to continue...”
        exit
    }
}

# Verifying paths in variables, aborting script if not found
Verify-Path $WinPEGenPath
Verify-Path $StifleRClientSource
Verify-Path $ADKPath
Verify-Path $PackagePath
Verify-Path $WIMPath
Verify-Path $MountPath
Verify-Path "$WIMPath\$InstallWIMFile"
Verify-Path "$WIMPath\$BootWIMFile"

write-host "Check WIMs Build and Languages values  - " -NoNewline
$BootWIM = Get-WindowsImage -ImagePath $WIMPath\$BootWIMFile -Index 1 | select build, languages
$InstallWIM = Get-WindowsImage -ImagePath $WIMPath\$InstallWIMFile -Index 3 | select build, languages
if ( $BootWIM.Build -eq $InstallWIM.Build -and $BootWIM.Languages -eq $InstallWIM.Languages ) {
    write-host "Success" -ForegroundColor Green
    $MatchingProperties = $true
}

if ( $MatchingProperties -eq $true ) {
    write-host "Injecting 2Pints functions to image    - " -NoNewline
    $OSDToolkit = & “$WinPEGenPath\WinPEGen.exe” “$WIMPath\$InstallWIMFile” 1 “$WIMPath\$BootWIMFile” 1 /Add-BITS /Copy-BITSPolicy /Add-StifleR /StifleRSource:$StifleRClientSource #/StifleRConfig:$StifleRConfigPath\$StifleRConfigFile
    if ( $OSDToolkit -like '*Successfully created a WinPE image with BranchCache!' ) {
        write-host "Success" -ForegroundColor Green
        write-host "Mounting image                         - " -NoNewline
        $MountImage = & "$ADKPath\Imagex" /mountrw $WIMPath\$BootWIMFile 1 $MountPath
        if ( $MountImage -contains 'Successfully mounted image.' ) {
            write-host "Success" -ForegroundColor Green
            write-host "Injecting .Net into image              - " -NoNewline
            $InjectDotNet = & "$ADKPath\dism" /image:$MountPath /add-package /packagepath:"$PackagePath\WinPE-NetFx.cab"
            if ( $InjectDotNet -contains 'The operation completed successfully.' ) {
                write-host "Success" -ForegroundColor Green
                write-host "Injecting .Net en-us into image        - " -NoNewline
                $InjectDotNetenUs = & "$ADKPath\dism" /image:$MountPath /add-package /packagepath:"$PackagePath\en-us\WinPE-NetFx_en-us.cab"
                if ( $InjectDotNetenUs -contains 'The operation completed successfully.' ) {
                    write-host "Success" -ForegroundColor Green
                    write-host "Injecting Powershell into image        - " -NoNewline
                    $InjectPS = & "$ADKPath\dism" /image:$MountPath /add-package /packagepath:"$PackagePath\WinPE-PowerShell.cab"
                    if ( $InjectPS -contains 'THe operation completed successfully.' ) {
                        write-host "Success" -ForegroundColor Green
                        write-host "Unmounting and saving changes to image - " -NoNewline
                        $UnmountImage = & "$ADKPath\Imagex" /unmount /commit $MountPath
                        if ( $UnmountImage -contains 'Successfully unmounted image.' ) {
                            write-host "Success" -ForegroundColor Green
                        }
                        else {
                            write-host "Fail" -ForegroundColor Red
                            write-host " "
                            write-host "Output from failed command:"
                            write-host $UnmountImage
                            $Fail = $true
                        }
                    }
                    else {
                        write-host "Fail" -ForegroundColor Red
                        write-host " "
                        write-host "Output from failed command:"
                        write-host $InjectPS
                        $Fail = $true
                    }
                }
                else {
                    write-host "Fail" -ForegroundColor Red
                    write-host " "
                    write-host "Output from failed command:"
                    write-host $InjectDotNetenUs
                    $Fail = $true
                }
            }
            else {
                write-host "Fail" -ForegroundColor Red
                write-host " "
                write-host "Output from failed command:"
                write-host $InjectDotNet
                $Fail = $true
            }
        }
        else {
            write-host "Fail" -ForegroundColor Red
            write-host " "
            write-host "Output from failed command:"
            write-host $MountImage
            $Fail = $true
        }
    }
    else {
        write-host "Fail" -ForegroundColor Red
        write-host " "
        write-host "Output from failed command:"
        write-host $OSDToolkit
        $Fail = $true
    }
}
else {
    write-host "Fail" -ForegroundColor Red
    write-host " "
    write-host "Mismatch in Build or Languages values:"
    write-host "Boot.wim Build    : " -NoNewline ; write-host $($BootWIM.Build)"   " -NoNewline -ForegroundColor Yellow
    write-host "Install.wim Build    : " -NoNewline ; write-host $($InstallWIM.Build) -ForegroundColor Yellow
    write-host "Boot.wim Language : " -NoNewline ; write-host $($BootWIM.Languages)"   " -NoNewline -ForegroundColor Yellow
    write-host "Install.wim Language : " -NoNewline ; write-host $($InstallWIM.Languages) -ForegroundColor Yellow
    $Fail = $true
}

if ( $MountImage -contains 'Successfully mounted image.' -and $Fail -eq $true ) {
    write-host " "
    write-host "Discarding changes because of an error - " -NoNewline
    $UnmountImage = & "$ADKPath\Imagex" /unmount $MountPath
    if ( $UnmountImage -contains 'Successfully unmounted image.' ) {
        write-host "Success" -ForegroundColor Green        
    }
    else {
        write-host "Fail" -ForegroundColor Red
        write-host " "
        write-host "Output from failed command:"
        write-host $UnmountImage
    }
}

write-host " "
if (!$psISE) { read-host “Press ENTER to continue...” }
