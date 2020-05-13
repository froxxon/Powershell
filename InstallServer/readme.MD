# INSTALLSERVER

## Task Sequence step 1 - Start InstallServer

![TS step 1](img/TS_step_1_-_Start_InstallServer_script.jpg)

Trigger the GUI for InstallServer through the built-in script execution

![InstallServer GUI](img/InstallServer_GUI.jpg)

## Task Sequence step 2 - Configure network settings

![TS step 2](img/TS_step_2_-_Konfigurera_natverksinstallningar.jpg)

The TS variable %FRXOU% is set through the main script and used to place the computer object in this step

## Task Sequence step 3 - Set local computer description

![TS step 3](img/TS_step_3_-_Satt_lokal_datorbeskrivning.jpg)

```$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Continue```

```Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\LanManServer\Parameters -Name srvcomment -Value $tsenv.Value("FRXDescription") -ErrorAction SilentlyContinue```

## Task Sequence step 4 - Set computer description in AD

![TS step 4](img/TS_step_4_-_Satt_beskrivning_på_AD-objekt.jpg)

```$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Continue```

```$DomainDN = "LDAP://CN=$($TSEnv.Value("FRXComputerName")),$($TSEnv.Value("FRXOU"))"```
```$Computer = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $DomainDN,$($TSEnv.Value("FRXCustomUserName")),$($TSEnv.Value("FRXCustomUserInfo"))```
```$Computer.description = $TSEnv.Value("FRXDescription")```
```$Computer.setinfo()```

## Task Sequence step 2 - Add service window groups

![TS step 5](img/TS_step_5_-_Lagger_till_servicefonstergrupper.jpg)

```$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Continue```

```$DomainDN = "LDAP://CN=$($TSEnv.Value("FRXComputerName")),$($TSEnv.Value("FRXOU"))"```
```$Computer = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList``` ```$DomainDN,$($TSEnv.Value("FRXCustomUserName")),$($TSEnv.Value("FRXCustomUserInfo"))```

```foreach ( $MW in $($TSEnv.GetVariables() | where { $_ -like "FRXMW*" }) ) {```
```    $DomainDN = "LDAP://CN=$($TSEnv.Value($MW)),OU=MaintenanceGroups,DC=froxxen,DC=com"```
```    $MWGroup = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $DomainDN,$($TSEnv.Value("FRXCustomUserName")),$($TSEnv.Value("FRXCustomUserInfo"))```
```    $MWGroup.Add($Computer.ADSPath)```
```}```

## Task Sequence step 6 - Configure NIC settings

![TS step 6](img/TS_step_6_-_Satter_angiven_konfiguration_på_natverkskort.jpg)

```$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Continue```
```New-NetIPAddress –IPAddress $tsenv.Value("FRXIPAddress") -DefaultGateway $tsenv.Value("FRXGateway") -PrefixLength $tsenv.Value("FRXSubnet") -InterfaceIndex (Get-NetAdapter).InterfaceIndex```

```Set-DNSClientServerAddress –InterfaceIndex (Get-NetAdapter).InterfaceIndex –ServerAddresses $tsenv.Value("FRXDNSPrimary"),$tsenv.Value("FRXDNSSecondary")```
