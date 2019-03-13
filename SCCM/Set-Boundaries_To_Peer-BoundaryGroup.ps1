Clear-Host
Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
cd a01:
$Boundaries = @("Bound01","Bound02")

ForEach ( $Boundary in $Boundaries ) {
    Try {
        $BoundaryID = $(Get-CMBoundary -BoundaryName "*Production - Central - $Boundary*").BoundaryID
        Write-host "Successfully" -ForegroundColor Green -NoNewline ; Write-host " retrieved BoundaryID: $BoundaryID for Boundary: ""*Production - Central - $Boundary*"""
        Try {
            Add-CMBoundaryToGroup -BoundaryID $BoundaryID -BoundaryGroupName "Production - Central Peer content"
            Write-host "Successfully" -ForegroundColor Green -NoNewline ; Write-host " added BoundaryGroup: ""Production - Central Peer content"" to BoundaryID: $BoundaryID"
            Try {
                Remove-CMBoundaryFromGroup -BoundaryGroupName "Production - Central content - $Boundary" -BoundaryId $BoundaryID -Force
                Write-host "Successfully" -ForegroundColor Green -NoNewline ; Write-host "Successfully removed BoundaryID: $BoundaryID from BoundaryGroup: ""Production - Central content  - $Boundary"""
            }
            Catch {
                Write-host "Failed" -ForegroundColor Red -NoNewline ; Write-host " to remove BoundaryID: $BoundaryID from BoundaryGroup: ""Production - Central content - $Boundary"""
            }
        }
        Catch {
            Write-host "Failed" -ForegroundColor Red -NoNewline ; Write-host " to add BoundaryGroup: ""Production - Central content"" to BoundaryID: $BoundaryID"
        }
    }
    Catch {
        Write-host "Failed" -ForegroundColor Red -NoNewline ; Write-host " to retrieve BoundaryID: $BoundaryID for Boundary: ""*Production - Central - $Boundary*"""
    }
    Write-host ""
}