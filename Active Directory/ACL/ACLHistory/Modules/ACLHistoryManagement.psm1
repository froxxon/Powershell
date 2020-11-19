$Global:DMARCLogsSQLValues = @{
    "AMIdentitySQLServer" = "W008012.froxxen.com"
    "AMIdentityDataBase" = "ACLHistory"
}

function Start-SQLCommand {
<#
.SYNOPSIS
    Used to query SQL databases
.DESCRIPTION
    Use this function to query SQL databases. The function uses the credentials of the account
    that runs the script (Integrated Security).
.PARAMETER SQLServer
    The name of the SQL Server
.PARAMETER Database
    The name of the database on the SQL Server
.PARAMETER SQLQuery
    The Query to run against the database on the SQL Server
.EXAMPLE
    Get all Employees from HRSystem

    Start-SQLCommand -SQLServer SQLSERVER1 -Database HRDatabase -SQLQuery 'SELECT Name,EmployeeID FROM HRSystem'
.EXAMPLE
    Get all Employees from HRSystem with Titles joined in from HRSystemTitles with a
    multiline SQL Query and stores the result in the variable $HRPersonelContent.

    $SQLQueryToExecute = @'
    SELECT HR.EmployeeName,Titles.Title
    FROM
    HRSystemTable AS HR
    INNER JOIN HRSystemTitles AS Titles ON Titles.ID = HR.ID
    WHERE Titles.Title = 'Manager'
    ORDER BY HR.EmployeeName
    '@

    $HRPersonelContent = Start-SQLCommand -SQLServer SQLSERVER1 -Database HRDatabase -SQLQuery $SQLQueryToExecute
.NOTES
    Script name: Start-SQLCommand
    Author:      Micke Sundqvist
    Twitter:     @mickesunkan
    Github:      https://github.com/maekee/Powershell
#>
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$false)][string]$SQLServer = $DMARCLogsSQLValues.AMIdentitySQLServer,
        [parameter(Mandatory=$false)][string]$Database = $DMARCLogsSQLValues.AMIdentityDataBase,
        [parameter(Mandatory=$true)][string]$SQLQuery
    )

	try{
	    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	    $SqlConnection.ConnectionString = "Server=$SQLServer;Database=$Database;Integrated Security=True;" 
	    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	    $SqlCmd.CommandText = $SQLQuery
	    $SqlCmd.Connection = $SqlConnection
	    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	    $SqlAdapter.SelectCommand = $SqlCmd
	    $DataSet = New-Object System.Data.DataSet
	    $nSet = $SqlAdapter.Fill($DataSet)
	    $OutputTable = $DataSet.Tables[0]
	    $SqlConnection.Close();
	    Return $OutputTable
    }
    catch{ Write-Warning $_.Exception.Message }
}

function Get-ACLHistoryLogs {
    [CmdletBinding()]
    param([switch]$OnlyReportNames)

    $returnData = Start-SQLCommand -SQLQuery "EXEC dbo.GetAllACLRecords"
    $returnData
}

function Add-ACLEventRecord {
    [CmdletBinding()]
    param(
		[Parameter(Mandatory=$true)][string]$Timestamp,
        [Parameter(Mandatory=$true)][string]$OpCorrelationID,
        [Parameter(Mandatory=$true)][string]$Modifier,
        [Parameter(Mandatory=$true)][string]$ModifierSAM,
		[Parameter(Mandatory=$true)][string]$TargetObject,
        [Parameter(Mandatory=$true)][string]$TargetType
    )

    try{
#Mandatory: [Timestamp],[OpCorrelationID],[Modifier],[TargetObject]
$returnData = Start-SQLCommand -SQLQuery @"
EXEC AddEventRecord '$Timestamp','$OpCorrelationID','$Modifier','$ModifierSAM','$TargetObject','$TargetType'
"@
        Write-Verbose "Successfully added ACL-history Event record $($OpCorrelationID)"
    }
    catch{
        Write-Warning "Failed when adding ACL-history Event record to database"
    }
}

function Add-ACLModificationRecord {
    [CmdletBinding()]
    param(
		[Parameter(Mandatory=$true)][string]$Timestamp,
        [Parameter(Mandatory=$true)][string]$OpCorrelationID,
        [Parameter(Mandatory=$true)][string]$SDDLType,
		[Parameter(Mandatory=$false)][string]$Type = $null,
        [Parameter(Mandatory=$false)][string]$Principal = $null,
        [Parameter(Mandatory=$true)][string]$Access,
        [Parameter(Mandatory=$false)][string]$AppliesTo = $null,
        [Parameter(Mandatory=$true)][string]$Operation,
        [Parameter(Mandatory=$true)][string]$Checksum
    )

    try{
#Mandatory: [Timestamp],[OpCorrelationID],[SDDLType],[Type],[Principal],[Access],[AppliesTo],[Operation],[Checksum]
$returnData = Start-SQLCommand -SQLQuery @"
EXEC AddModificationRecord '$Timestamp','$OpCorrelationID','$SDDLType','$Type','$Principal','$Access','$AppliesTo','$Operation','$Checksum'
"@
        Write-Verbose "Successfully added ACL-history Modification record $($OpCorrelationID)"
    }
    catch{
        Write-Warning "Failed when adding ACL-history Modification record to database"
    }
}