$Computers = get-content ".\Computers.txt"

ForEach ($Computer in $Computers) {
    If(Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
        Write-host "Trigger RefreshCompliance on $Computer"
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            $SCCMUpdatesStore = New-Object -ComObject Microsoft.CCM.UpdatesStore ; $SCCMUpdatesStore.RefreshServerComplianceState()
        }    
    }
}