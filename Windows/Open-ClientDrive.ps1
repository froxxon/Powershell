$t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
add-type -name win -member $t -namespace native
If ( $(Test-Path variable:global:psISE) -eq $False ) { [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0) } # This hides the Powershellwindow in the background if ISE isn't running

Function ViewForm { 

    #Load assemblies for System.Windows.Forms and System.Drawing
    [reflection.assembly]::loadwithpartialname(“System.Windows.Forms”) | Out-Null 
    [reflection.assembly]::loadwithpartialname(“System.Drawing”) | Out-Null 
    Add-Type -AssemblyName PresentationCore,PresentationFramework

    # Create new objects to be used within the script
    $Form = New-Object System.Windows.Forms.Form 
    $ComputerLabel = New-Object System.Windows.Forms.Label
    $ComputerTextBox = New-Object System.Windows.Forms.TextBox
    $UserNameLabel = New-Object System.Windows.Forms.Label
    $UserNameTextBox = New-Object System.Windows.Forms.TextBox
    $PasswordLabel = New-Object System.Windows.Forms.Label
    $PasswordTextBox = New-Object System.Windows.Forms.TextBox
    $ConnectButton = New-Object System.Windows.Forms.Button

    #Defines what will happen when clicking on the button ConnectButton
    $handler_ConnectButton_Click = { 
        If ( Test-Connection -ComputerName $($ComputerTextBox.Text) -Count 1 ) {
            net use \\$($ComputerTextBox.Text)\c$ /user:$($UserNameTextBox.Text) $($PasswordTextBox.Text) /p:no
            If ( $LASTEXITCODE -eq 0 ) {
                explorer \\$($ComputerTextBox.Text)\c$
                net use /delete \\$($ComputerTextBox.Text)\c$
            }
            Else {
                $ErrorMessage = "An error occured while connecting."
                If ( $error[0] -like "*The referenced account is currently locked out and may not be logged on to.*" ) { $ErrorMessage = "The user account is currently locked out" }
                If ( $error[0] -like "*The specified network password is not correct.*" ) { $ErrorMessage = "The password is incorrect" ; $PasswordTextBox.Text = "" }
                If ( $error[0] -like "*The user name or password is incorrect.*" ) { $ErrorMessage = "The password is incorrect" ; $PasswordTextBox.Text = "" }
                [System.Windows.MessageBox]::Show($ErrorMessage,"$($Form.Text) - Error connecting","Ok","Warning")
            }
        }
        Else {
            [System.Windows.MessageBox]::Show("Can't connect to computer $($ComputerTextBox.Text), no ping response","$($Form.Text) - Error connecting","Ok","Warning")
        }
    }

    # Creating the Form-object
    $Form.Text = “Open Client Drive”
    $Form.Name = “Open Client Drive”
    $Form.FormBorderStyle = 'Fixed3D'
    $Form.MaximizeBox = $False
    $System_Drawing_Size = New-Object System.Drawing.Size 
    $System_Drawing_Size.Width = 230
    $System_Drawing_Size.Height = 133
    $Form.ClientSize = $System_Drawing_Size

    # Sets variables that will be the same for a couple of the objects in the form
    $LabelXWidth = 100
    $LabelXPoint = 10
    $TextBoxXWidth = 250
    $TextBoxXPoint = 110
    $ButtonXPoint = 10
    $RowHeight = 25

    # Creating the ComputerLabel-object
    $ComputerLabel.Name = "ComputerLabel"
    $ComputerLabel.Text = "Computer:"
    $System_Drawing_Size.Width = $LabelXWidth
    $System_Drawing_Size.Height = $RowHeight
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $LabelXPoint
    $System_Drawing_Point.Y = 10
    $ComputerLabel.Location = $System_Drawing_Point

    # Creating the ComputerTextBox-object
    $ComputerTextBox.Name = "ComputerTextBox"
    $System_Drawing_Size.Width = $TextBoxXWidth
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $TextBoxXPoint
    $System_Drawing_Point.Y = 10
    $ComputerTextBox.Location = $System_Drawing_Point 
    
    # Creating the UserNameLabel-object
    $UserNameLabel.Name = "UserNameLabel"
    $UserNameLabel.Text = "Username (ex. L2berfeadm):"
    $System_Drawing_Size.Width = $LabelXWidth 
    $System_Drawing_Size.Height = $RowHeight
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $LabelXPoint
    $System_Drawing_Point.Y = 40
    $UserNameLabel.Location = $System_Drawing_Point
    
    # Creating the UserNameTextBox-object
    $UserNameTextBox.Name = "UserNameTextBox"
    $UserNameTextBox.Text = $UserName
    $UserNameTextBox.Enabled = $False
    $System_Drawing_Size.Width = $TextBoxXWidth
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $TextBoxXPoint
    $System_Drawing_Point.Y = 40
    $UserNameTextBox.Location = $System_Drawing_Point 

    # Creating the PasswordLabel-object
    $PasswordLabel.Name = "PasswordLabel"
    $PasswordLabel.Text = "Password:"
    $System_Drawing_Size.Width = $LabelXWidth
    $System_Drawing_Size.Height = $RowHeight
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $LabelXPoint
    $System_Drawing_Point.Y = 70
    $PasswordLabel.Location = $System_Drawing_Point

    # Creating the PasswordTextBox-object
    $PasswordTextBox.Name = "PasswordTextBox"
    $System_Drawing_Size.Width = $TextBoxXWidth
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = $TextBoxXPoint
    $System_Drawing_Point.Y = 70
    $PasswordTextBox.PasswordChar = "*"
    $PasswordTextBox.Location = $System_Drawing_Point 
    
    # Creating the ConnectButton-object
    $ConnectButton.TabIndex = 7
    $ConnectButton.Name = “ConnectButton”
    $System_Drawing_Size = New-Object System.Drawing.Size 
    $System_Drawing_Size.Width = 100
    $System_Drawing_Size.Height = 25 
    $ConnectButton.Size = $System_Drawing_Size 
    $ConnectButton.UseVisualStyleBackColor = $True
    $ConnectButton.Text = “Connect”
    $System_Drawing_Point = New-Object System.Drawing.Point 
    $System_Drawing_Point.X = 110
    $System_Drawing_Point.Y = 100
    $ConnectButton.Location = $System_Drawing_Point 
    $ConnectButton.add_Click($handler_ConnectButton_Click)

    # Adding created objects to the Form
    $Form.Controls.Add($ComputerLabel)
    $Form.Controls.Add($ComputerTextBox)
    $Form.Controls.Add($UserNameLabel)
    $Form.Controls.Add($UserNameTextBox)
    $Form.Controls.Add($PasswordLabel)
    $Form.Controls.Add($PasswordTextBox)
    $Form.Controls.Add($ConnectButton)

    # Displays the Form-window
    $Form.ShowDialog()| Out-Null
}

# Trigger the ViewForm-function
ViewForm