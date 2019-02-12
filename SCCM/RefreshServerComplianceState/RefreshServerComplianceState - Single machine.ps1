$Computer = "server01"

    Invoke-Command -ComputerName $Computer -ScriptBlock {
        $SCCMUpdatesStore = New-Object -ComObject Microsoft.CCM.UpdatesStore ; $SCCMUpdatesStore.RefreshServerComplianceState() ; New-EventLog -LogName Application -Source SyncStateScript -ErrorAction SilentlyContinue ; Write-EventLog -LogName Application -Source SyncStateScript -EventId 555 -EntryType Information -Message "Sync State ran successfully"
    }