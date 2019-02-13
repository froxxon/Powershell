$SourcePath = "C:\Temp\Create least Privilege Model"
Import-module "$SourcePath\SharedCode.psm1"
$LogFile = "$SourcePath\Create-Everything.log"
CD C:\Temp\CM2012Scripts

$Template = "$SourcePath\DelegatedTasks_Domain1_1.0.csv"

Write-Log "--- Start of log ---"
Write-Log

Import-module "$SourcePath\POPADD\POPADD.psd1"
Write-Log "Imported the module POPADD"

Add-DelegationOUs
Write-Log "Created the OU-structure for least privilegies"

Add-RolesAndTasks -template $Template
Write-Log "Added the roles and tasks in the templatefile"

Add-TaskPermissions -template $Template
Write-Log "Added permissions to tasks"

Write-Log "Creating tasks for LocalRights on Server-OU:s"
.\Create-OUAdminTasks\Create-OUAdminTasks.ps1
$Log = Get-Content .\Create-OUAdminTasks\Create-OUAdminTasks.log
If ( $Log -like "*Error*" ) {
    Write-Log "Created tasks for LocalRights on Server-OU:s, but the log contains errormessages" -LogType ERROR
}
Else {
    Write-Log "Created tasks for LocalRights on Server-OU:s"
}

Write-Log "Adding groups to roles"
.\Add-GroupsToRoles\Add-GroupsToRoles.ps1
$Log = Get-Content .\Add-GroupsToRoles\Add-GroupsToRoles.log
If ( $Log -like "*Error*" ) {
    Write-Log "Added groups to roles, but the log contains errormessages" -LogType ERROR
}
Else {
    Write-Log "Added groups to roles"    
}

Write-Log "Adding tasks to roles"
.\Add-TasksToRoles\Add-TasksToRoles.ps1
$Log = Get-Content .\Add-TasksToRoles\Add-TasksToRoles.log
If ( $Log -like "*Error*" ) {
    Write-Log "Added tasks to roles, but the log contains errormessages" -LogType ERROR
}
Else {
    Write-Log "Added tasks to roles"
}

.\Create-ADMAccounts\Create-ADMAccounts.ps1
$Log = Get-Content .\Create-ADMAccounts\Create-ADMAccounts.log
If ( $Log -like "*Error*" ) {
    Write-Log "Created adminaccounts, but the log contains errormessages" -LogType ERROR
}
Else {
    Write-Log "Created adminaccounts"
}

Write-Log "Creating GPO:s for LocalRights on Server-OU:s"
.\Create-LocalRightsGPOs\Create-LocalRightsGPOs.ps1
$Log = Get-Content .\Create-LocalRightsGPOs\Create-LocalRightsGPOs.log
If ( $Log -like "*Error*" ) {
    Write-Log "Created GPO:s for LocalRights on Server-OU:s, but the log contains errormessages" -LogType ERROR
}
Else {
    Write-Log "Created GPO:s for LocalRights on Server-OU:s"
}

Write-Log "Adding users to roles"
.\Add-UsersToRoles\Add-UsersToRoles.ps1
$Log = Get-Content .\Add-UsersToRoles\Add-UsersToRoles.log
If ( $Log -like "*Error*" ) {
    Write-Log "Added users to roles, but the log contains errormessages" -LogType ERROR
}
Else {
    Write-Log "Added users to roles"
}

Write-Log
Write-Log "--- End of log ---"