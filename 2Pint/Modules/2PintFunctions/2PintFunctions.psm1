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
        #pull subnets with locationname like '21-' from server01
        Get-2PSubnet -Identity '21-*' -Server 'server01' | Format-Table -AutoSize

    .EXAMPLE
        #pull subnets with pipeline where locationname like '21-' from server01 and show current red-/blue leader
        '21-*' | Get-2PSubnet -Server 'server01' | Select-Object -uUnique LocationName, ActiveClients, AverageBandwidth, RedLeader, BlueLeader | Format-Table -AutoSize
    
    .EXAMPLE
        #pull all subnets from sever01 with specific properties and sorts them based on AverageBandwidth
        Get-2PSubnet -Server 'sever01' -Property LocationName, ActiveClients, AverageBandwidth, SubnetID | Select LocationName, SubnetID, ActiveClients, AverageBandwidth, RedLeader, BlueLeader | Where ActiveClients -gt 0 | Sort AverageBandwidth, LocationName -Descending | Format-Table -AutoSize

    .LINK
        http://gallery.technet.microsoft.com/scriptcenter/Get-2PSubnet-Get-5607a465

    .FUNCTIONALITY
        Subnets
    #>
    
    [CmdletBinding()]
    Param (
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ValueFromRemainingArguments=$false        )]
        [Alias('Identity')]
        [String]$LocationName='*',

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ComputerName','Computer','__SERVER')]
        [String]$Server,

        [String]$SubnetID='*',
        [Array]$Property='*'
    )

    Begin {     
        # Check if the specified server has the WMI namespace for StifleR
        If ( Get-WMIObject -ComputerName $Server -namespace 'Root' -class '__NAMESPACE' -filter "Name='StifleR'" ) {}
        Else {
            Write-Error -Message "The specified server $Server is missing the WMI namespace for StifleR"
            Break
        }
        
        # Check if the specified properties exists in the Subnet class
        If ( $Property -ne '*' ) {
            $ClassProperties = $($(Get-WMIObject -ComputerName $Server -Namespace 'ROOT\StifleR' -Class Subnets) | Get-Member).Name
            $MissingProps = @()
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
        $Property = $($Property -Join ',')

        # Queries the StifleR server for the subnet information
        $SubnetInfo = Get-WMIObject -ComputerName $Server -Namespace 'ROOT\StifleR' -Class Subnets -Property $Property -Filter "LocationName LIKE '$($LocationName)' AND SubnetID LIKE '$($SubnetID)'" | Select-Object [a-zA-Z]* -ExcludeProperty PSComputerName, Scope, Path, Options, ClassPath, Properties, SystemProperties, Qualifiers, Site, Container
        
        # If $Property contains SubnetID, then add Red- and BlueLeader information per subnet
        If ( $Property -eq '*' -OR $Property -like '*SubnetID*' ) {
            ForEach ( $Subnet in $SubnetInfo ) {
                $Subnet | Add-Member -MemberType NoteProperty -Name 'RedLeader' -Value "$($(Get-WMIObject -ComputerName $Server -Namespace 'ROOT\StifleR' -Class 'RedLeaders' -Filter "NetworkID LIKE '%$($Subnet.subnetID)%'").ComputerName)"
                $Subnet | Add-Member -MemberType NoteProperty -Name 'BlueLeader' -Value "$($(Get-WMIObject -ComputerName $Server -Namespace 'ROOT\StifleR' -Class 'BlueLeaders' -Filter "NetworkID LIKE '%$($Subnet.subnetID)%'").ComputerName)"
            }
        }
    }

    End {
        # Returns the results collected
        $SubnetInfo
    }

}