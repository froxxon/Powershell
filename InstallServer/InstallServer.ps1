$DefaultSubnetPrefix = 24
$DefaultGateway      = '192.168.1.1'
$DefaultDNSPrimary   = '192.168.1.2'
$DefaultDNSSecondary = '192.168.1.3'
$RestServer          = '192.168.1.14:4093'
$DomainDN            = 'DC=domain,DC=local'

function Verify-IPv4 {
    $IPv4Regex = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    if ( $txtIPAddress.Text -match $IPv4Regex -and $txtGateway.Text -match $IPv4Regex -and $txtDNSPrimary.Text -match $IPv4Regex -and $txtDNSSecondary.Text -match $IPv4Regex) {
        $btnContinue.IsEnabled = $true
    }
    else {
        $btnContinue.IsEnabled = $false
    }
    
    if ( $txtIPAddress.Text -notmatch $IPv4Regex ) {
        $txtIPAddress.BorderBrush = 'Red'
    }
    else {
        $txtIPAddress.BorderBrush = '#FFABADB3'
    }

    if ( $txtGateway.Text -notmatch $IPv4Regex ) {
        $txtGateway.BorderBrush = 'Red'
    }
    else {
        $txtGateway.BorderBrush = '#FFABADB3'
    }

    if ( $txtDNSPrimary.Text -notmatch $IPv4Regex ) {
        $txtDNSPrimary.BorderBrush = 'Red'
    }
    else {
        $txtDNSPrimary.BorderBrush = '#FFABADB3'
    }

    if ( $txtDNSSecondary.Text -notmatch $IPv4Regex ) {
        $txtDNSSecondary.BorderBrush = 'Red'
    }
    else {
        $txtDNSSecondary.BorderBrush = '#FFABADB3'
    }
}

function Get-OUs {
    $cmbOUs.Items.Clear()
    $cmbOUs.Items.Add("NewComputers") | out-null
    #$OUs = Invoke-RestMethod -Method Get -Uri "http://$RestServer/ServerOUs"
    foreach ( $OU in $OUs ) {
        $cmbOUs.Items.Add($OU) | out-null
    }
    $cmbOUs.SelectedIndex = 0
}

Function Get-MWs {
    $lsbMws.Items.Clear()
    #$MWs = Invoke-RestMethod -Method Get -Uri "http://$RestServer/MaintenanceGroups"
    foreach ( $MW in $MWs ) {
        $lsbMws.Items.Add($MW.TrimStart()) | out-null
    }
}

function Get-IP {
    (gwmi -Class 'Win32_NetworkAdapterConfiguration' -Filter "IPEnabled = 1") | foreach {
        $_.IPAddress |% {
            if($_ -ne $null) {
                if($_.IndexOf('.') -gt 0 -and !$_.StartsWith("169.254") -and $_ -ne "0.0.0.0") {
                    $ip = $_
                }
            }
        }
    }
    $ip 
}

function Get-GW {
    (gwmi -Class 'Win32_NetworkAdapterConfiguration' -Filter "IPEnabled = 1") | foreach {
        $_.DefaultIPGateway |% {
            if($_ -ne $null) {
                if($_.IndexOf('.') -gt 0 -and !$_.StartsWith("169.254") -and $_ -ne "0.0.0.0") {
                    $gw = $_                   
                }
            }
        }
    }
    $gw 
}

if (!$psise) {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName System.Windows.Forms
    $t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);' # Part of the process to hide the Powershellwindow if it is not run through ISE
    Add-Type -name win -member $t -namespace native # Part of the process to hide the Powershellwindow if it is not run through ISE
}

$InputXML = @"
<Window x:Name="Form" x:Class="InstallServerGUI.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:InstallServerGUI"
        mc:Ignorable="d"
        Title="Installera server - Konfiguration" Height="402.832" Width="420.334" ResizeMode="NoResize" WindowStartupLocation="CenterScreen" Topmost="True" Background="#7FEEEEEE" Foreground="#7FEEEEEE" ShowInTaskbar="False" BorderBrush="#7FA8A8A8" BorderThickness="1" WindowStyle="None">
    <Grid x:Name="grd1" Margin="0" Opacity="0.9">
        <Grid.Background>
            <RadialGradientBrush>
                <GradientStop Color="#FF4B4B4B" Offset="0"/>
                <GradientStop Color="#FF575757" Offset="1"/>
            </RadialGradientBrush>
        </Grid.Background>
        <Label Content="Datornamn" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="15,20,0,0" FontWeight="Bold" Foreground="White"/>
        <Label Content="Beskrivning" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="15,48,0,0" FontWeight="Bold" Foreground="White"/>
        <Label Content="DHCP" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="15,86,0,0" FontWeight="Bold" Foreground="White"/>
        <RadioButton x:Name="rbnDHCPOn" Content="Ja" HorizontalAlignment="Left" VerticalAlignment="Top" Checked="RadioButton_Checked" FontWeight="Bold" Foreground="White" IsChecked="True" Width="56" TabIndex="3" Margin="304,92,0,0"/>
        <RadioButton x:Name="rbnDHCPOff" Content="Nej" HorizontalAlignment="Left" VerticalAlignment="Top" Checked="RadioButton_Checked" FontWeight="Bold" Foreground="White" TabIndex="4" Margin="360,92,0,0"/>
        <Label Content="IP-address" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="15,112,0,0" FontWeight="Bold" Foreground="White"/>
        <Label Content="SubnÃ¤tsprefix" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="15,139,0,0" FontWeight="Bold" Foreground="White"/>
        <Label Content="Gateway" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="15,165,0,0" FontWeight="Bold" Foreground="White"/>
        <Label Content="DNS-server 1" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="15,191,0,0" FontWeight="Bold" Foreground="White"/>
        <Label Content="DNS-server 2" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="15,217,0,0" FontWeight="Bold" Foreground="White"/>
        <TextBox x:Name="txtComputerName" HorizontalAlignment="Left" Height="23" VerticalAlignment="Top" Width="226" Margin="175,23,0,0" HorizontalContentAlignment="Right" TextChanged="txtComputerName_TextChanged" TabIndex="1" MaxLines="1"/>
        <TextBox x:Name="txtIPAddress" HorizontalAlignment="Left" Height="23" TextWrapping="Wrap" VerticalAlignment="Top" Width="226" Margin="175,115,0,0" HorizontalContentAlignment="Right" TabIndex="5" IsEnabled="False"/>
        <TextBox x:Name="txtGateway" HorizontalAlignment="Left" Height="23" TextWrapping="Wrap" VerticalAlignment="Top" Width="226" Margin="175,168,0,0" HorizontalContentAlignment="Right" TabIndex="7" IsEnabled="False"/>
        <TextBox x:Name="txtDNSPrimary" HorizontalAlignment="Left" Height="23" TextWrapping="Wrap" VerticalAlignment="Top" Width="226" Margin="175,194,0,0" HorizontalContentAlignment="Right" TabIndex="8" IsEnabled="False"/>
        <TextBox x:Name="txtDNSSecondary" HorizontalAlignment="Left" Height="23" TextWrapping="Wrap" VerticalAlignment="Top" Width="226" Margin="175,220,0,0" HorizontalContentAlignment="Right" TabIndex="9" IsEnabled="False"/>
        <TextBox x:Name="txtDescription" HorizontalAlignment="Left" Height="23" VerticalAlignment="Top" Width="226" Margin="175,51,0,0" HorizontalContentAlignment="Right" TabIndex="2" MaxLines="1"/>
        <Button x:Name="btnReset" Content="Återställ" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="16,362,0,0" FontWeight="Bold" TabIndex="17"/>
        <Button x:Name="btnContinue" Content="Fortsätt" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="326,362,0,0" FontWeight="Bold" TabIndex="16"/>
        <Label Content="Typ av installation" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="16,324,0,0" FontWeight="Bold" Foreground="White"/>
        <Label Content="OU" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="15,259,0,0" FontWeight="Bold" Foreground="White"/>
        <ComboBox x:Name="cmbOUs" HorizontalAlignment="Left" VerticalAlignment="Top" Width="190" Margin="175,263,0,0" IsReadOnly="True" HorizontalContentAlignment="Right" TabIndex="10" MaxDropDownHeight="110"/>
        <Button x:Name="btnReloadOUs" Content="â†»" HorizontalAlignment="Left" VerticalAlignment="Top" Width="31" Margin="370,263,0,0" Height="22" FontWeight="Bold" TabIndex="11" ToolTip="Uppdatera OUs"/>
        <ComboBox x:Name="cmbSubnetPrefix" HorizontalAlignment="Left" VerticalAlignment="Top" Width="226" Margin="175,142,0,0" HorizontalContentAlignment="Right" IsReadOnly="True" TabIndex="6" IsEnabled="False" MaxDropDownHeight="80">
            <ComboBoxItem HorizontalAlignment="Left" Width="188" Selected="ComboBoxItem_Selected"/>
        </ComboBox>
        <StackPanel Margin="239,330,0,0" Orientation="Horizontal" HorizontalAlignment="Left" VerticalAlignment="Top">
            <RadioButton x:Name="rbnDE" Content="Desktop Exp." HorizontalAlignment="Left" VerticalAlignment="Top" IsChecked="True" Width="114" FontWeight="Bold" Foreground="White" TabIndex="14"/>
            <RadioButton x:Name="rbnCore" Content="Core" HorizontalAlignment="Right" VerticalAlignment="Top" FontWeight="Bold" Foreground="White" TabIndex="15"/>
        </StackPanel>
        <Label Content="ServicefÃ¶nster" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="16,293,0,0" FontWeight="Bold" Foreground="White"/>
        <Button x:Name="btnReloadMWs" Content="â†»" HorizontalAlignment="Left" VerticalAlignment="Top" Width="31" Margin="370,297,0,0" Height="20" FontWeight="Bold" TabIndex="13" ToolTip="Uppdatera servicefÃ¶nster"/>
        <Button x:Name="btnSelectMWs" Content="Välj..." HorizontalAlignment="Left" VerticalAlignment="Top" Width="190" Margin="175,297,0,0" FontWeight="Bold" TabIndex="17"/>
        <ListBox x:Name="lsbMws" HorizontalAlignment="Left" Height="265" VerticalAlignment="Top" Width="385" Margin="16,20,0,0" Visibility="Hidden" SelectionMode="Extended"/>
    </Grid>
</Window>

"@

#region XAML
    $inputXML = $inputXML -replace '\s{1}[\w\d_-]+="{x:Null}"',''
    $inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
    $inputXML = $inputXML -replace 'TextChanged="[\w\d-]+\w"',''
    $inputXML = $inputXML -replace 'SelectionChanged="[\w\d-]+\w"',''
    $inputXML = $inputXML -replace ' Selected="[\w\d-]+\w"',''
    $inputXML = $inputXML -replace ' Click="[\w\d-]+"',''
    $inputXML = $inputXML -replace 'Checked="CheckBox_Checked" ',''
    $inputXML = $inputXML -replace 'Checked="RadioButton_Checked" ',''

    [xml]$xaml = $inputXML
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    try {
        $Form = [Windows.Markup.XamlReader]::Load( $reader )
    }
    catch {
        Write-Warning $_.Exception
        throw
    }
    
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
        try {
            Set-Variable -Name "$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop
        }
        catch {
            throw
        }
    }
#endregion

try {
    $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Continue
    $tsloaded = $true
}
catch {
    $tsloaded = $false
}

if ( $tsloaded ) {
    $txtComputerName.Text = $TSEnv.Value("_SMSTSMachineName")
}
$txtIPAddress.Text = Get-IP
$cmbSubnetPrefix.SelectedIndex = $DefaultSubnetPrefix 
$txtGateway.Text = Get-GW
$txtDNSPrimary.Text = $DefaultDNSPrimary
$txtDNSSecondary.Text = $DefaultDNSSecondary

$btnReset.Add_Click({
    if ( $tsenabled ) {
        $txtComputerName.Text = $TSEnv.Value("_SMSTSMachineName")
    }
    $txtIPAddress.Text = Get-IP
    $rbnDHCPOn.IsChecked = $true
    $cmbSubnetPrefix.SelectedIndex = $DefaultSubnetPrefix 
    $txtGateway.Text = Get-GW
    $txtDNSPrimary.Text = $DefaultDNSPrimary
    $txtDNSSecondary.Text = $DefaultDNSSecondary
    $txtDescription.Text = ''
    $rbnDE.IsChecked = $true
    $cmbOUs.SelectedIndex = 0
    $lsbMws.Visibility = "Hidden"
    $btnSelectMWs.Content = "Välj..."
    $btnContinue.IsEnabled = $true
    Get-OUs
    Get-MWs
})

$btnContinue.Add_Click({
    if ( $tsloaded ) {
        if ( $rbnDE.IsChecked ) {
            $tsenv.Value("FRXOSType") = "DE"
        }
        else {
            $tsenv.Value("FRXOSType") = "Core"
        }
        $TSEnv.Value("_SMSTSMachineName")   = $txtComputerName.Text
        $TSEnv.Value("OSDComputerName")     = $txtComputerName.Text
        $tsenv.Value("FRXComputerName")     = $txtComputerName.Text
        if ( $rbnDHCPOff.IsChecked -eq $true ) {
            $tsenv.Value("FRXIPAddress")    = $txtIPAddress.Text
            $tsenv.Value("FRXSubnet")       = $cmbSubnetPrefix.SelectedItem
            $tsenv.Value("FRXGateway")      = $txtGateway.Text
            $tsenv.Value("FRXDNSPrimary")   = $txtDNSPrimary.Text
            $tsenv.Value("FRXDNSSecondary") = $txtDNSSecondary.Text
        }
        else {
            $tsenv.Value("FRXDHCPOn") = "Yes"
        }
        $tsenv.Value("FRXDescription") = $txtDescription.Text
        if ( $cmbOUs.SelectedItem -eq 'NewComputers' ) {
            $TargetOU = "OU=$($cmbOUs.SelectedItem),OU=Domain Computers,$DomainDN"
        }
        else {
            $TargetOU = "OU=$($cmbOUs.SelectedItem),OU=Servers,OU=Domain Computers,$DomainDN"
        }
        $tsEnv.Value("FRXOU") = $TargetOU
        foreach ( $Selection in $lsbMws.SelectedItems ) {
            $tsEnv.Value("FRXMW$Counter") = $Selection
            $counter++
        }
    }

    $Form.Close()
})

$txtComputerName.Add_GotFocus({
    $txtComputerName.SelectAll()
})

$txtComputerName.Add_TextChanged({
    if ( $txtComputerName.Text -eq '' ) {
        $txtComputerName.BorderBrush = 'Red'
        $btnContinue.IsEnabled = $false
    }
    else {
        $txtComputerName.BorderBrush = '#FFABADB3'
        $btnContinue.IsEnabled = $true
        Verify-IPv4
    }
})

$txtDescription.Add_GotFocus({
    $txtDescription.SelectAll()
})

$txtIPAddress.Add_GotFocus({
    $txtIPAddress.SelectAll()
})

$txtIPAddress.Add_TextChanged({
    Verify-IPv4
})

$txtGateway.Add_GotFocus({
    $txtGateway.SelectAll()
})

$txtGateway.Add_TextChanged({
    Verify-IPv4
})

$txtDNSPrimary.Add_GotFocus({
    $txtDNSPrimary.SelectAll()
})

$txtDNSPrimary.Add_TextChanged({
    Verify-IPv4
})

$txtDNSSecondary.Add_GotFocus({
    $txtDNSSecondary.SelectAll()
})

$txtDNSSecondary.Add_TextChanged({
    Verify-IPv4
})

$IPv4prefixes = 1..32
foreach ( $prefix in $IPv4prefixes ) { $cmbSubnetPrefix.Items.Add($prefix) | out-null }
$cmbSubnetPrefix.SelectedIndex = $DefaultSubnetPrefix

$rbnDHCPOn.Add_Checked({
    $txtIPAddress.IsEnabled = $false
    $cmbSubnetPrefix.IsEnabled = $false
    $txtGateway.IsEnabled = $false
    $txtDNSPrimary.IsEnabled = $false
    $txtDNSSecondary.IsEnabled = $false
    $btnContinue.IsEnabled = $true
})

$rbnDHCPOff.Add_Checked({
    $txtIPAddress.IsEnabled = $true
    $cmbSubnetPrefix.IsEnabled = $true
    $txtGateway.IsEnabled = $true
    $txtDNSPrimary.IsEnabled = $true
    $txtDNSSecondary.IsEnabled = $true
    Verify-IPv4
})

$btnSelectMWs.Add_Click({
    if ( $btnSelectMWs.Content -ne "Spara") {
        $lsbMws.Visibility = "Visible"
        $lsbMws.Focus()
        $btnSelectMWs.Content = "Spara"
        $btnContinue.IsEnabled = $false
    }
    else {
        $lsbMws.Visibility = "Hidden"
        if ( $lsbMws.SelectedItems.Count -gt 0 ) {
            $btnSelectMWs.Content = "$($lsbMws.SelectedItems.Count) valda fönster"
        }
        else {
            $btnSelectMWs.Content = "Välj..."
        }
        $btnContinue.IsEnabled = $true
        Verify-IPv4
    }
})

$btnReloadOUs.Add_Click({
    Get-OUs
})

$btnReloadMWs.Add_Click({
    if ( $lsbMws.Visibility -eq "Hidden" ) {
        $btnSelectMWs.Content = "Välj..."
    }
    Get-MWs
})

Get-OUs
Get-MWs
$txtComputerName.Focus() | out-null

$Form.ShowDialog() | out-null