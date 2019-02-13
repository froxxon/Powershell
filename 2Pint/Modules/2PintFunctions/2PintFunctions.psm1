Function Add-Subnet {

    [CmdletBinding()]
    Param (
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ValueFromRemainingArguments=$false,Mandatory=$true)]
        [Alias('Identity')]
        [String]$LocationName='*',
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ComputerName','Computer','__SERVER')]
        [String]$Server,
        [String]$SubnetID='*'
    )

    Begin {
    }

    Process {
    }

    End {
    }

}

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
    Param (
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
        [Array]$Property='*'
    )

    Begin {     

        $MissingProps = @()
        $ClassProperties = @()
        $SubnetInfo = @()

        # Check if the specified server is reachable
        If ( Test-Connection $Server -Count 1 -Quiet -ErrorAction Stop ) {}
        Else {
            Write-Error -Message "The specified server $Server could not be contacted"
            Break        
        }
        
        # Check if the specified server has the WMI namespace for StifleR
        Try {
            Get-CIMClass -Namespace Root\StifleR -ComputerName $Server -ErrorAction Stop
        }
        Catch {
            Write-Error -Message "The specified server $Server is missing the WMI namespace for StifleR"
            Break
        }

        # Check if the specified properties exists in the Subnet class
        If ( $Property -ne '*' ) {
            $ClassProperties = $($(Get-CIMInstance -ComputerName $Server -Namespace 'ROOT\StifleR' -Class Subnets) | Get-Member).Name
            ForEach ( $Prop in $($Property) ) {
                If ( $ClassProperties -notcontains $Prop ) { $MissingProps += "$Prop" }
            }
            If ( $MissingProps.Count -gt 0 ) { 
                $MissingProps = $MissingProps -join ', '
                Write-Error -Message "One or more of the following properties couldn't be found in the Class Subnets: $MissingProps"
                Break
            }
        }
    }

    Process {
        # Replace Windows wildcards with WMI specific wildcards
        $LocationName = $LocationName.Replace('*','%')
        $LocationName = $LocationName.Replace('?','_')
        $SubnetID = $SubnetID.Replace('*','%')
        $SubnetID = $SubnetID.Replace('?','_')

        # Queries the StifleR server for the subnet information
        $SubnetInfo = Get-CIMInstance -ComputerName $Server -Namespace 'ROOT\StifleR' -Class Subnets -Property $Property -Filter "LocationName LIKE '$($LocationName)' AND SubnetID LIKE '$($SubnetID)'" | Select-Object [a-zA-Z]* -ExcludeProperty PSComputerName, Scope, Path, Options, ClassPath, Properties, SystemProperties, Qualifiers, Site, Container
        # If $Property contains SubnetID, then add Red- and BlueLeader information per subnet
        If ( $Property -eq '*' -OR $Property -like '*SubnetID*' ) {
            ForEach ( $Subnet in $SubnetInfo ) {
                $Subnet | Add-Member -MemberType NoteProperty -Name 'RedLeader' -Value "$($(Get-CIMInstance -ComputerName $Server -Namespace 'ROOT\StifleR' -Class 'RedLeaders' -Filter "NetworkID LIKE '%$($Subnet.subnetID)%'").ComputerName)"
                $Subnet | Add-Member -MemberType NoteProperty -Name 'BlueLeader' -Value "$($(Get-CIMInstance -ComputerName $Server -Namespace 'ROOT\StifleR' -Class 'BlueLeaders' -Filter "NetworkID LIKE '%$($Subnet.subnetID)%'").ComputerName)"
            }
        }
    }

    End {
        # Returns the results collected
        $SubnetInfo
    }

}

Function Remove-Subnet {

    [CmdletBinding()]
    Param (
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ValueFromRemainingArguments=$false,Mandatory=$true)]
        [Alias('Identity')]
        [String]$LocationName='*',
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ComputerName','Computer','__SERVER')]
        [String]$Server,
        [String]$SubnetID='*'
    )

    Begin {
    }

    Process {
    }

    End {
    }

}
