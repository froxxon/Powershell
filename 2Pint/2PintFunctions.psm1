Function Get-Subnet {

    <#
    .SYNOPSIS
        Get information about the subnets available in StifleR.

    .DESCRIPTION
        Pull subnet details from the server hosting the StifleR Server service.
        Details:
        - This skips the necessity of using WBEMTest or similiar tools to WMIExplorer to get the same information...

    .PARAMETER Identity (LocationName)
        One or more subnets to show information from.

    .PARAMETER SubnetID
        If this property is added, or if all properties are selected (* by defualt), Red- and BlueLeader will be added per subnet as well.

    .PARAMETER Property
        Use specific properties contained in the WMI class Subnet in the StifleR namespace.

    .PARAMETER Server (ComputerName, Computer)
        This will be the server hosting the StifleR Server-service.

    .EXAMPLE
        Get-StiflerSubnet -Identity '21-*' -Server 'server01' | Format-Table -AutoSize
        Pull subnets with locationname like '21-' from server01

    .EXAMPLE
        '21-*' | Get-StiflerSubnet -Server 'server01' | Select-Object -uUnique LocationName, ActiveClients, AverageBandwidth, RedLeader, BlueLeader | Format-Table -AutoSize
        Pull subnets with pipeline where locationname like '21-' from server01 and show current red-/blue leader
    
    .EXAMPLE
        Get-StiflerSubnet -Server 'sever01' -Property LocationName, ActiveClients, AverageBandwidth, SubnetID | Select LocationName, SubnetID, ActiveClients, AverageBandwidth, RedLeader, BlueLeader | Where ActiveClients -gt 0 | Sort AverageBandwidth, LocationName -Descending | Format-Table -AutoSize
        Pull all subnets from sever01 with specific properties and sorts them based on AverageBandwidth

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Get-StiflerSubnet-Get-5607a465

    .FUNCTIONALITY
        Subnets
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ValueFromRemainingArguments=$false,HelpMessage = "This parameter is used if you want to query LocationName(s)")]
        [Alias('Identity')]
        [String]$LocationName='*',
        [Parameter(Mandatory=$true,HelpMessage = "Specify the server where StifleR Server is installed")]
        [ValidateNotNullOrEmpty()]
        [Alias('ComputerName','Computer','__SERVER')]
        [String]$Server,
        [Parameter(HelpMessage = "This parameter is used if you want to query SubnetID(s)")]
        [String]$SubnetID='*',
        [Parameter(HelpMessage = "This parameter is used if you want to query for specific properties")]
        [Array]$Property,
        [switch]$ShowRedLeader,
        [switch]$ShowBlueLeader
    )

    begin {     

        $MissingProps = @()
        $ClassProperties = @()
        $SubnetInfo = @()

        # Check if the specified server is reachable
        if ( Test-Connection $Server -Count 1 -Quiet -ErrorAction Stop ) {}
        else {
            Write-Error -Message "The specified server $Server could not be contacted"
            Break        
        }
        
        # Check if the specified server has the WMI namespace for StifleR
        try {
            Get-CIMClass -Namespace Root\StifleR -ComputerName $Server -ErrorAction Stop | out-null
        }
        catch {
            Write-Error -Message "The specified server $Server is missing the WMI namespace for StifleR"
            Break
        }

        # Check if the specified properties exists in the Subnet class
        if ( $Property -ne '*' ) {
            $ClassProperties = $($(Get-CIMInstance -ComputerName $Server -Namespace 'ROOT\StifleR' -Class Subnets) | Get-Member).Name
            foreach ( $Prop in $($Property) ) {
                if ( $ClassProperties -notcontains $Prop ) { $MissingProps += "$Prop" }
            }
            if ( $MissingProps.Count -gt 0 ) { 
                $MissingProps = $MissingProps -join ', '
                Write-Error -Message "One or more of the following properties couldn't be found in the Class Subnets: $MissingProps"
                Break
            }
        }
    }

    process {

        $defaultProperties = @(‘SubnetID’,’LocationName','TargetBandwidth','LEDBATTargetBandwidth','WellConnected','Clients')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        If ( $Property -eq '*' ) { $defaultProperties = '*' }
        If ( $Property -ne $Null -and $Property -notcontains '*' ) { $defaultProperties = $Property }

        # Replace Windows wildcards with WMI specific wildcards
        $LocationName = $LocationName.Replace('*','%')
        $LocationName = $LocationName.Replace('?','_')
        $SubnetID = $SubnetID.Replace('*','%')
        $SubnetID = $SubnetID.Replace('?','_')

        # Queries the StifleR server for the subnet information
        $SubnetInfo = Get-CIMInstance -ComputerName $Server -Namespace 'ROOT\StifleR' -Class Subnets -Property $Property -Filter "LocationName LIKE '%$($LocationName)%' AND SubnetID LIKE '%$($SubnetID)%'"
        # If $Property contains SubnetID, then add Red- and BlueLeader information per subnet
        If ( $ShowRedLeader ) {
            foreach ( $Subnet in $SubnetInfo ) {
                $Subnet | Add-Member -MemberType NoteProperty -Name 'RedLeader' -Value "$($(Get-CIMInstance -ComputerName $Server -Namespace 'ROOT\StifleR' -Class 'RedLeaders' -Filter "NetworkID LIKE '%$($Subnet.subnetID)%'").ComputerName)"
            }
            $defaultProperties += 'RedLeader'
        }
        If ( $ShowBlueLeader ) {
            foreach ( $Subnet in $SubnetInfo ) {
                $Subnet | Add-Member -MemberType NoteProperty -Name 'BlueLeader' -Value "$($(Get-CIMInstance -ComputerName $Server -Namespace 'ROOT\StifleR' -Class 'BlueLeaders' -Filter "NetworkID LIKE '%$($Subnet.subnetID)%'").ComputerName)"
            }
            $defaultProperties += 'BlueLeader'
        }
    }

    end {
        # Returns the results collected
        $SubnetInfo | Add-Member MemberSet PSStandardMembers $PSStandardMembers
        $SubnetInfo | Select $defaultProperties -ExcludeProperty PSComputerName
    }
}

Function Get-Client {
    param (
        [Parameter(Mandatory, HelpMessage = "Specify the client you want to retrieve information about", ValueFromPipeline, ValueFromPipelineByPropertyName)][ValidateNotNullOrEmpty()]
        [string[]]$Client,
        [Parameter(HelpMessage = "Specify StifleR server")][ValidateNotNullOrEmpty()]
        [string]$Server = $env:COMPUTERNAME,
        [Parameter(HelpMessage = "Specify specific properties")]
        [array]$Property
    )
    
    $defaultProperties = @(‘ComputerName’,’ClientIPAddress','Version')
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

    If ( $Property -eq '*' ) { $defaultProperties = '*' }
    If ( $Property -ne $Null -and $Property -notcontains '*' ) { $defaultProperties = $Property }

    $ClientInformation = Get-CIMInstance -Namespace 'Root\StifleR' -Class Clients -Filter "ComputerName LIKE '%$Client%'" -ComputerName $Server
    $ClientInformation | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    $ClientInformation | Select $defaultProperties -ExcludeProperty PSComputerName
}

Function Update-SubnetBandwidth {
    <#
    .SYNOPSIS
    Update StifleR subnet bandwidth
    
    .DESCRIPTION
    This function'll update StifleR managed subnet bandwidth
    
    .PARAMETER SubnetId
    Specify subnet you want to update
    
    .PARAMETER TargetBandwidth
    Specify targeted bandwidth in MB
    
    .PARAMETER WellConnected
    Specify if subnet should be tagged as well connected
    
    .PARAMETER StiflerServer
    Specify StifleR server name, default is localhost
    
    .EXAMPLE
    Update-SrSubnetBandwidth -SubnetId "192.168.2.0" -TargetBandwidth 20
    .EXAMPLE
    Update-SrSubnetBandwidth -SubnetId "192.168.2.0" -WellConnected Yes
    .EXAMPLE
    Update-SrSubnetBandwidth -SubnetId "192.168.2.0" -WellConnected No
    .EXAMPLE
    Get-SrSubnet -Filter "192.168" | Update-SrSubnetBandwidth -TargetBandwidth 20
    
    .NOTES
    Author:         Michal Kirejczyk
    Version:        1.0.1
    Date:           2018-12-13
    What's new:
                    1.0.1 (2018-12-13) - Function now requires exact subnetId to be provided, use Get-SrSubnet | Update-SrSubnetBandwidth if you want to use wildcard 
                    1.0.0 (2018-12-12) - Function Created
    #>
    
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [Parameter(Mandatory, HelpMessage = "Specify subnets you want to update", ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = "Default")]
        [Parameter(Mandatory, HelpMessage = "Specify subnets you want to update", ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = "LEDBATTargetBandwidth")]
        [Parameter(Mandatory, HelpMessage = "Specify subnets you want to update", ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = "WellConnected")]
        [ValidateNotNullOrEmpty()]
        [string[]]$SubnetId,
        [Parameter(Mandatory, HelpMessage = "Specify targeted bandwidth in MB", Position = 1, ParameterSetName = "Default")]
        [ValidateNotNullOrEmpty()]
        [int]$TargetBandwidth,
        [Parameter(Mandatory, HelpMessage = "Specify LEDBAT targeted bandwidth in MB", Position = 1, ParameterSetName = "LEDBATTargetBandwidth")]
        [ValidateNotNullOrEmpty()]
        [int]$LEDBATTargetBandwidth,
        [Parameter(Mandatory, HelpMessage = "Specify this switch if you want to set subnet to well connected", Position = 2, ParameterSetName = "WellConnected")]
        [ValidateSet("Yes", "No")]
        [ValidateNotNullOrEmpty()]
        [string]$WellConnected,
        [Parameter(Mandatory = $false, HelpMessage = "Specify StifleR server", Position = 3, ParameterSetName = "Default")]
        [Parameter(Mandatory = $false, HelpMessage = "Specify StifleR server", Position = 3, ParameterSetName = "LEDBATTargetBandwidth")]
        [Parameter(Mandatory = $false, HelpMessage = "Specify StifleR server", Position = 3, ParameterSetName = "WellConnected")]
        [ValidateNotNullOrEmpty()]
        [string]$StiflerServer = $env:COMPUTERNAME
    )
    begin {
        # Populate default Write-Log parameters
        $functionName = $MyInvocation.MyCommand
        $PSDefaultParameterValues.Clear()
        $PSDefaultParameterValues.Add('Write-Log:ExecutionScenario', "$ExecutionScenario")
        $PSDefaultParameterValues.Add('Write-Log:FunctionName', "$functionName")
        $PSDefaultParameterValues.Add('Write-Log:LogPath', "$(Join-Path -Path $env:ProgramData -ChildPath "2Pint Software\StifleR\Logs\stiflerservermodule.log")")
        $PSDefaultParameterValues.Add('Write-Log:ErrorAction', "SilentlyContinue")
        # If verbose write verbose
        if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
            $PSDefaultParameterValues.Add('Write-Log:Verbose', $true)
            $PSDefaultParameterValues.Add('Get-SrSubnet:Verbose', $true)
        }
    }
    process {
        try {
            # Get Subnets
            Write-Host "Attempting to get $SubnetId"
            # Execute every subnet
            foreach ($s in $SubnetId) {              
                $query = "SELECT * FROM Subnets WHERE subnetId = '$s'"
                $subnet = Get-CimInstance -Namespace Root\StifleR -Query $query -ComputerName $StiflerServer
                if ($subnet) {
                    try {
                        # Update bandwidth based on targetedbandwidth or wellconnected
                        #Target bandwidth
                        if ($TargetBandwidth) {
                            [int]$calculateToKb = $TargetBandwidth * 1024
                            Write-Host "Attempting to update $SubnetId bandwidth to $TargetBandwidth MB"
                            if ($subnet.TargetBandwidth -ne $calculateToKb) {
                                Set-CimInstance -InputObject $subnet -ComputerName $StiflerServer -Property @{TargetBandwidth = $calculateToKb} -ErrorAction Stop
                                Write-Host "$SubnetId updated"
                            }
                            else {
                                Write-Host "No updated needed on $SubnetId"
                            }
                        }
                        #Target bandwidth
                        if ($LEDBATTargetBandwidth) {
                            [int]$calculateToKb = $LEDBATTargetBandwidth * 1024
                            Write-Host "Attempting to update $SubnetId LEDBAT bandwidth to $LEDBATTargetBandwidth MB"
                            if ($subnet.LEDBATTargetBandwidth -ne $calculateToKb) {
                                Set-CimInstance -InputObject $subnet -ComputerName $StiflerServer -Property @{LEDBATTargetBandwidth = $calculateToKb} -ErrorAction Stop
                                Write-Host "$SubnetId updated"
                            }
                            else {
                                Write-Host "No updated needed on $SubnetId"
                            }
                        }
                        # Well connected = Yes
                        elseif ($WellConnected -eq "Yes") {
                            Write-Host "Attempting to set $SubnetId to well connected"
                            if ($subnet.WellConnected -ne $true) {
                                Set-CimInstance -InputObject $subnet -ComputerName $StiflerServer -Property @{WellConnected = $true} -ErrorAction Stop
                                Write-Host "$SubnetId updated"
                            }
                            else {
                                Write-Host "No updated needed on $SubnetId"
                            }
                        }
                        # Well connected = No
                        elseif ($WellConnected -eq "No") {
                            Write-Host "Attempting to disable well connected on $SubnetId"
                            if ($subnet.WellConnected -ne $false) {
                                Set-CimInstance -InputObject $subnet -ComputerName $StiflerServer -Property @{WellConnected = $false} -ErrorAction Stop
                                Write-Host "$SubnetId updated"
                            }
                            else {
                                Write-Host "No updated needed on $SubnetId"
                            }
                        }
                    }
                    catch {
                        Write-Host "Failed to update subnet, exception: $($_.Exception.Message)"
                        Write-Error -ErrorRecord $_
                    }   
                }
                else {
                    Write-Host "Subnet $SubnetId not found"
                }
                                              
            }
        }
        catch {
            Write-Host "Failed to find subnets, line: $($_.InvocationInfo.ScriptLineNumber), exception: $($_.Exception.Message)"
            Write-Error -ErrorRecord $_
        }
    }
}

Function Add-Subnet {

    [CmdletBinding()]
    param (
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ValueFromRemainingArguments=$false,Mandatory=$true)]
        [Alias('Identity')]
        [String]$LocationName='*',
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ComputerName','Computer','__SERVER')]
        [String]$Server,
        [String]$SubnetID='*'
    )

    begin {
    }

    process {
    }

    end {
    }

}

Function Remove-Subnet {

    [CmdletBinding()]
    param (
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ValueFromRemainingArguments=$false,Mandatory=$true)]
        [Alias('Identity')]
        [String]$LocationName='*',
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ComputerName','Computer','__SERVER')]
        [String]$Server,
        [String]$SubnetID='*'
    )

    begin {
    }

    process {
    }

    end {
    }

}

Function Start-BITSJob {
}

Function Suspend-BITSJob {
}

Function Stop-BITSJob {
}