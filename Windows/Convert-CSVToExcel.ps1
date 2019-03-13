Function Convert-CSVToExcel {

    [CmdletBinding()]
    param (
        [Array]$Headers,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][String]$TargetFile,
        [ValidateNotNullOrEmpty()][String]$SourceFile,
        [String]$SheetName = "Sheet1",
        [String]$Delimiter = ";",
        [Int]$Rowcount,
        [switch]$NoHeadersInCSV
    )
    
    $excel = New-Object -ComObject excel.application 
    #$excel.visible = $true
    $workbook = $excel.Workbooks.Add()
    $ExcelWorkbook= $workbook.Worksheets.Item(1) 
    $ExcelWorkbook.Name = $SheetName

    If ( $Headers -eq $Null ) { $Headers = $(Get-Content $SourceFile -First 1).Split($Delimiter)}
    [System.Collections.ArrayList]$Records = Import-Csv -Path $SourceFile -Delimiter $Delimiter -Header $Headers

    If ( $Headers -ne $Null -and $NoHeadersInCSV -eq $false ) { $Records.RemoveAt(0)}
    If ( $RowCount -ne 0 ) { $Records = $Records | Select -First $RowCount }

    $Counter = 1
    ForEach ( $Header in $Headers ) {
        $ExcelWorkbook.Cells.Item(1,$Counter) = $Header
        $ExcelWorkbook.Cells.Item(1,$Counter).Font.Size = 12
        $ExcelWorkbook.Cells.Item(1,$Counter).Font.Bold=$True 
        $ExcelWorkbook.Cells.Item(1,$Counter).Font.ColorINdex = 2
        $ExcelWorkbook.Cells.Item(1,$Counter).Interior.ColorIndex = 49
        $Counter++
    }

    $headerRange = $ExcelWorkbook.Range("1:1")
    $headerRange.AutoFilter() | Out-Null

    $ExcelWorkbook.Application.ActiveWindow.SplitRow = 1
    $ExcelWorkbook.Application.ActiveWindow.FreezePanes = $true

    $Counter = 2
    foreach($record in $Records) { 
        Try {
            $HeadCounter = 1
            ForEach ( $Header in $Headers ) {
                $excel.cells.item($Counter,$headCounter) = $record.$Header
                $HeadCounter++ 
            }
            $Counter++ 
        }
        Catch {}
    } 

    $usedRange = $ExcelWorkbook.UsedRange 
    $usedRange.EntireColumn.AutoFit() | Out-Null

    $workbook.SaveAs($TargetFile)
    $excel.Quit()
}

#Convert-CSVToExcel -Headers 'Boundary Group','DPType','ScopeLeases','ScopeDescription','ScopeCIDR' -TargetFile 'C:\Scripts\SCCM\Get-CMBoundariesWithoutDP.xlsx' -SourceFile 'C:\Scripts\SCCM\Get-CMBoundariesWithoutDP.log' -SheetName 'List of Boundaries etc.' -Delimiter ';' -Rowcount 10
Convert-CSVToExcel -TargetFile 'C:\Scripts\SCCM\Get-CMBoundariesWithoutDP.xlsx' -SourceFile 'C:\Scripts\SCCM\Get-CMBoundariesWithoutDP.log' -SheetName 'List of Boundaries etc.' -Delimiter ';' -Rowcount 10

C:\Scripts\SCCM\Get-CMBoundariesWithoutDP.xlsx