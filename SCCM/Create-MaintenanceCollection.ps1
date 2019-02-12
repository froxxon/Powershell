Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
cd a01:
Write-host ""

$Today = Get-Date -UFormat %m/%d/%Y

Function RefreshDayOfWeekMinusOne($Day) {
    If ( $Day -eq "TUESDAY" ) { $RefreshDayOfWeek = "MONDAY" }
    If ( $Day -eq "WEDNESDAY" ) { $RefreshDayOfWeek = "TUESDAY" }
    If ( $Day -eq "THURSDAY" ) { $RefreshDayOfWeek = "WEDNESDAY" }
    If ( $Day -eq "FRIDAY" ) { $RefreshDayOfWeek = "THURSDAY" }
    If ( $Day -eq "SATURDAY" ) { $RefreshDayOfWeek = "FRIDAY" }
    If ( $Day -eq "SUNDAY" ) { $RefreshDayOfWeek = "SATURDAY" }
    If ( $Day -eq "MONDAY" ) { $RefreshDayOfWeek = "SUNDAY" }
    Return $RefreshDayOfWeek
}

Function CreateMaintenanceCollection ($Name) {
    If ( $Name.SubString(7,3) -like "Mon" ) { $Day = "måndagar" ; $DayOfWeek = "MONDAY"  }
    If ( $Name.SubString(7,3) -like "Tue" ) { $Day = "tisdagar" ; $DayOfWeek = "TUESDAY"  }
    If ( $Name.SubString(7,3) -like "Wed" ) { $Day = "onsdagar" ; $DayOfWeek = "WEDNESDAY"  }
    If ( $Name.SubString(7,3) -like "Thu" ) { $Day = "torsdagar" ; $DayOfWeek = "THURSDAY"  }
    If ( $Name.SubString(7,3) -like "Fri" ) { $Day = "fredagar" ; $DayOfWeek = "FRIDAY"  }
    If ( $Name.SubString(7,3) -like "Sat" ) { $Day = "lördagar" ; $DayOfWeek = "SATURDAY"  }
    If ( $Name.SubString(7,3) -like "Sun" ) { $Day = "söndagar" ; $DayOfWeek = "SUNDAY" }
    $StartHour = $Name.SubString($Name.IndexOf("kl ")+3,2)
    $LastHour = $Name.SubString($Name.IndexOf("-")+1,2)
    $Description = "Servers with maintenance windows from $Day $($StartHour).00 to $($LastHour).00"

    $RefreshDayOfWeek = $DayOfWeek  
    $RefreshStartHour = $StartHour
    If ( $RefreshStartHour -eq "00" -OR $RefreshStartHour -eq "01" -OR $RefreshStartHour -eq "02" -OR $RefreshStartHour -eq "03" -OR $RefreshStartHour -eq "04" ) {        
        If ( $RefreshStartHour -eq "00" ) {
            $RefreshStartHour = "19"
            $RefreshDayOfWeek = RefreshDayOfWeekMinusOne -Day $DayOfWeek
        }
        If ( $RefreshStartHour -eq "01" ) {
            $RefreshStartHour = "20"
            $RefreshDayOfWeek = RefreshDayOfWeekMinusOne -Day $DayOfWeek
        }
        If ( $RefreshStartHour -eq "02" ) {
            $RefreshStartHour = "21"
            $RefreshDayOfWeek = RefreshDayOfWeekMinusOne -Day $DayOfWeek
        }
        If ( $RefreshStartHour -eq "03" ) {
            $RefreshStartHour = "22"
            $RefreshDayOfWeek = RefreshDayOfWeekMinusOne -Day $DayOfWeek
        }
        If ( $RefreshStartHour -eq "04" ) {
            $RefreshStartHour = "23"
            $RefreshDayOfWeek = RefreshDayOfWeekMinusOne -Day $DayOfWeek
        }
    }
    Else { $RefreshStartHour = "$($RefreshStartHour-5)" }

    Write-host "Creating device collection ""$Name"" with dependencies:"
    Try {
        $RefreshSchedule = New-CMSchedule -DayOfWeek $RefreshDayOfWeek -Start "$(Get-Date -UFormat %m/%d/%Y) $($RefreshStartHour):00" -RecurCount 1
        New-CMDeviceCollection -Name $Name -LimitingCollectionName "SHD.AST#All Managed Windows Servers" -RefreshType 2 -RefreshSchedule $RefreshSchedule -Comment $Description | Out-null
        Write-host " - Device collection successfully created"
        Try {
            Add-CMUserCollectionQueryMembershipRule -CollectionName $Name -RuleName "Maintenance" -QueryExpression "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.SystemGroupName like ""%\\MAINTENANCE $($DayOfWeek.Substring(0,3)) KL $($StartHour).00-$($LastHour).00""" | Out-null
            Write-host " - Query successfully created"
            Try {
                $MaintenanceSchedule = New-CMSchedule -DayOfWeek $DayOfWeek -Start "$(Get-Date -UFormat %m/%d/%Y) $($StartHour):00" -End "$(Get-Date -UFormat %m/%d/%Y) $($LastHour):00" -RecurCount 1
                New-CMMaintenanceWindow -CollectionName $Name -MaintenanceWindowName "Maintenance" -ApplyTo SoftwareUpdatesOnly -Schedule $MaintenanceSchedule | Out-null
                Write-host " - Maintenance Window successfully created"
            }
            Catch { Write-host " - Failed to create Maintenance window - Aborting" }
        }
        Catch { Write-host " - Failed to create the Query - Aborting" }
    }
    Catch { Write-host " - Failed to create the collection - Aborting" }
    Write-host ""
}

### !!! Create an Excluded-collection manually !!! ###

#Monday
CreateMaintenanceCollection -Name "SHD.MW#Mon kl 21.00-22.00"
CreateMaintenanceCollection -Name "SHD.MW#Mon kl 22.00-23.00"
CreateMaintenanceCollection -Name "SHD.MW#Mon kl 23.00-00.00"
#Tuesday
CreateMaintenanceCollection -Name "SHD.MW#Tue kl 07.00-08.00"
CreateMaintenanceCollection -Name "SHD.MW#Tue kl 08.00-09.00"
CreateMaintenanceCollection -Name "SHD.MW#Tue kl 09.00-10.00"
CreateMaintenanceCollection -Name "SHD.MW#Tue kl 10.00-11.00"
CreateMaintenanceCollection -Name "SHD.MW#Tue kl 11.00-12.00"
CreateMaintenanceCollection -Name "SHD.MW#Tue kl 00.00-01.00"
CreateMaintenanceCollection -Name "SHD.MW#Tue kl 01.00-02.00"
CreateMaintenanceCollection -Name "SHD.MW#Tue kl 02.00-03.00"
CreateMaintenanceCollection -Name "SHD.MW#Tue kl 03.00-04.00"
CreateMaintenanceCollection -Name "SHD.MW#Tue kl 04.00-05.00"
CreateMaintenanceCollection -Name "SHD.MW#Tue kl 05.00-06.00"
CreateMaintenanceCollection -Name "SHD.MW#Tue kl 06.00-07.00"
#Wednesday
CreateMaintenanceCollection -Name "SHD.MW#Wed kl 21.00-22.00"
CreateMaintenanceCollection -Name "SHD.MW#Wed kl 22.00-23.00"
CreateMaintenanceCollection -Name "SHD.MW#Wed kl 23.00-00.00"
CreateMaintenanceCollection -Name "SHD.MW#Wed kl 00.00-01.00"
CreateMaintenanceCollection -Name "SHD.MW#Wed kl 01.00-02.00"
CreateMaintenanceCollection -Name "SHD.MW#Wed kl 02.00-03.00"
CreateMaintenanceCollection -Name "SHD.MW#Wed kl 03.00-04.00"
CreateMaintenanceCollection -Name "SHD.MW#Wed kl 04.00-05.00"
CreateMaintenanceCollection -Name "SHD.MW#Wed kl 05.00-06.00"
CreateMaintenanceCollection -Name "SHD.MW#Wed kl 06.00-07.00"
#Thursday
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 07.00-08.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 08.00-09.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 09.00-10.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 10.00-11.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 11.00-12.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 21.00-22.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 22.00-23.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 23.00-00.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 00.00-01.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 01.00-02.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 02.00-03.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 03.00-04.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 04.00-05.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 05.00-06.00"
CreateMaintenanceCollection -Name "SHD.MW#Thu kl 06.00-07.00"
#Friday
CreateMaintenanceCollection -Name "SHD.MW#Fri kl 00.00-01.00"
CreateMaintenanceCollection -Name "SHD.MW#Fri kl 01.00-02.00"
CreateMaintenanceCollection -Name "SHD.MW#Fri kl 02.00-03.00"
CreateMaintenanceCollection -Name "SHD.MW#Fri kl 03.00-04.00"
CreateMaintenanceCollection -Name "SHD.MW#Fri kl 04.00-05.00"
CreateMaintenanceCollection -Name "SHD.MW#Fri kl 05.00-06.00"
CreateMaintenanceCollection -Name "SHD.MW#Fri kl 06.00-07.00"
#Saturday
CreateMaintenanceCollection -Name "SHD.MW#Sat kl 21.00-22.00"
CreateMaintenanceCollection -Name "SHD.MW#Sat kl 22.00-23.00"
CreateMaintenanceCollection -Name "SHD.MW#Sat kl 23.00-00.00"
#Sunday
CreateMaintenanceCollection -Name "SHD.MW#Sun kl 00.00-01.00"
CreateMaintenanceCollection -Name "SHD.MW#Sun kl 01.00-02.00"
CreateMaintenanceCollection -Name "SHD.MW#Sun kl 02.00-03.00"
CreateMaintenanceCollection -Name "SHD.MW#Sun kl 03.00-04.00"
CreateMaintenanceCollection -Name "SHD.MW#Sun kl 04.00-05.00"
CreateMaintenanceCollection -Name "SHD.MW#Sun kl 05.00-06.00"
CreateMaintenanceCollection -Name "SHD.MW#Sun kl 06.00-07.00"