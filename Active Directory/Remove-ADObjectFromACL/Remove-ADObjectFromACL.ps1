## This script removes an objects access in a specified ACL
##
## Logs can be found in .\Logs folder
##
## Version 1.0.0 - First release // 2020-11-05
## Version 1.0.1 - Changed the parameter IdentityReference to array with corresponding funcitonality // 2020-11-06
## Version 1.0.2 - Added functionality so only objects with one or more matching IdentityReferences will be added to $ADObjects // 2020-11-06

#region Variables and functions
    $ScriptVariables = @{
        ScriptFolder       = "C:\Scripts\Remove-ADObjectFromACL"
        Threshold          = 1
        SearchBase         = "OU=Domain Computers,DC=domain,DC=local"
        IdentityReferences = @('BUILTIN\Account Operators','BUILTIN\Print Operators')
    }

    Set-Location $ScriptVariables.ScriptFolder -ErrorAction SilentlyContinue
    $logsFolder = Join-Path $ScriptVariables.ScriptFolder "Logs"

    function Remove-ADObjectFromACL {
        <#
        .SYNOPSIS
            Removes an entire object from a specified Access Control List (ACL)
    
        .DESCRIPTION
            Removes an entire object from a specified ACL
    
        .PARAMETER IdentityReference
            Specify the IdentityReference (array) that will be removed from the target object
    
        .PARAMETER TargetDN
            Specify the DistinguishedName of one object that should get the IdentityReference(s) removed from the ACL
    
        .EXAMPLE
            Remove-ADObjectFromACL -IdentityReference "BUILTIN\Print Operators" -TargetDN "CN=TestComputer,DC=domain,DC=local"
            Removes 'BUILTIN\Print Operators' from the ACL of 'TestComputer'

        .EXAMPLE
            Remove-ADObjectFromACL -IdentityReference "BUILTIN\Print Operators","BUILTIN\Account Operators" -TargetDN "CN=TestComputer,DC=domain,DC=local"
            Removes 'BUILTIN\Print Operators' and 'BUILTIN\Account Operators' from the ACL of 'TestComputer'
    
        .FUNCTIONALITY
            ACL Management
        #>
    
        param(
            [parameter(mandatory=$true)][ValidateNotNullOrEmpty()]
            [array]$IdentityReference,
            [parameter(mandatory=$true)][ValidateNotNullOrEmpty()]
            [string]$TargetDN
        )
    
        try {
            Import-Module ActiveDirectory -ErrorAction Stop
        }
        catch {
            Write-Error $_.Exception.Message
            break
        }
    
        $TargetDistinguishedName = [ADSI]("LDAP://$TargetDN")
        if ( $TargetDistinguishedName.distinguishedName ) {
            $CurrentACEinACL    = @()
            $GetCurrentACEinACL = @()
            $IdentitiesFound    = @()
            foreach ( $identity in $IdentityReference ) {
                [array]$GetCurrentACEinACL = $(Get-Acl -Path "AD:$($TargetDistinguishedName.distinguishedName)" ).Access | Where { $_.IdentityReference -eq "$Identity" -and $_.IsInherited -eq $false}
                if ( $GetCurrentACEinACL.Count -gt 0 ) {
                    Write-Log "Found $($GetCurrentACEinACL.Count) ACE(s) for `'$Identity`' to remove from `'$($TargetDistinguishedName.distinguishedName)`'"
                    $IdentitiesFound += $Identity
                    [array]$CurrentACEinACL += $GetCurrentACEinACL
                }
            }
            if ( $CurrentACEinACL.Count -gt 0 ) {
                foreach ( $RemoveACE in $CurrentACEinACL ) {
                    [void]$TargetDistinguishedName.PSBase.ObjectSecurity.RemoveAccessRule($RemoveACE)
                }
                try {
                    $TargetDistinguishedName.PSBase.CommitChanges()
                    Write-Log "Successfully removed ACE(s) for `'$($IdentitiesFound -join "`',`'")`' from `'$($TargetDistinguishedName.distinguishedName)`'"
                }
                catch {
                    Write-Log "Failed to remove ACE(s) for `'$($IdentitiesFound -join "`',`'")`' from `'$($TargetDistinguishedName.distinguishedName)`', error: $($_.Exception.Message)"
                }
            }
        }
        else {
            Write-Warning "The object `'$TargetDN`' could not be found in Active Directory"
        }
    }

    Function Write-Log {
        param([Parameter(Mandatory=$true, Position=0)][string]$Message)
        $logdate = (Get-Date -format "yyyy-MM-dd")
	    $logtime = (Get-Date -format "yyyy-MM-dd HH:mm:ss") + " >>"
	    $logfile = "Logfile_" + $logdate + ".log"
	    $logfilepath = Join-Path $logsFolder $logfile
	    if( (test-path $logfilepath) ) {
            "$logtime $Message" | Out-File -Append $logfilepath -Encoding utf8
            Write-Verbose "$logtime $Message" -Verbose
        }
        else {
            Write-Verbose "$logtime $Message" -Verbose
        }
    }
#endregion

if ( !$ADObjects ) {
    $ADObjects = @()
    $TempADObjects = Get-ADComputer -Filter * -SearchBase $ScriptVariables.SearchBase -properties ntSecurityDescriptor | Select Name, distinguishedName, ntSecurityDescriptor
    foreach ( $ADObject in $TempADObjects ) {
        foreach ( $Identity in $ScriptVariables.IdentityReferences ) {
            if ( $ADObject.distinguishedName -notin $ADObjects ) {
                if ( $identity -in $ADObject.ntSecurityDescriptor.Access.IdentityReference ) {
                    $ADObjects += ($ADObject).DistinguishedName
                }
            }
        }
    }
}

foreach ( $ADObject in $ADObjects | Select -First $ScriptVariables.Threshold ) {
    Remove-ADObjectFromACL -TargetDN $ADObject -IdentityReference $ScriptVariables.IdentityReferences
}

# Run below to see specific IdentityReferences for an object
# ($(Get-Acl -Path "AD:$($ADObject)" ).Access | Where { $_.IsInherited -eq $false}).IdentityReference | Select -Unique | Sort
