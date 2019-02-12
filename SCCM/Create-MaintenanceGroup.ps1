Function CreateMaintenanceGroup ($Day,$StartHour,$LastHour,$Domain) {

    $DomainDN = $(Get-ADDomain -Server $Domain).DistinguishedName

    If ( $Day -eq "Mon" ) { $DayName = "måndagar" }
    If ( $Day -eq "Tue" ) { $DayName = "tisdagar" }
    If ( $Day -eq "Wed" ) { $DayName = "onsdagar" }
    If ( $Day -eq "Thu" ) { $DayName = "torsdagar" }
    If ( $Day -eq "Fri" ) { $DayName = "fredagar" }
    If ( $Day -eq "Sat" ) { $DayName = "lördagar" }
    If ( $Day -eq "Sun" ) { $DayName = "söndagar" }

    $GroupName = "Maintenance $Day kl $($StartHour).00-$($LastHour).00"
    $Description = "Servers with maintenance windows from $DayName $($StartHour).00 to $($LastHour).00"

    Try {
        New-ADGroup $GroupName -Description $Description -DisplayName $GroupName -GroupCategory Security -GroupScope Global -Path "OU=MaintenanceGroups,$DomainDN" -Server $Domain
        Write-host "Created the group: ""$GroupName"" in $Domain"
    }
    Catch {
        Write-host "Failed to create the group: ""$GroupName"" in $Domain"
    }
}

# Domain
CreateMaintenanceGroup -Day "Wed" -StartHour "21" -LastHour "22" -Domain "domain.local"
CreateMaintenanceGroup -Day "Wed" -StartHour "22" -LastHour "23" -Domain "domain.local"
CreateMaintenanceGroup -Day "Wed" -StartHour "23" -LastHour "00" -Domain "domain.local"