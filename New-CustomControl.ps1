Function New-CustomControl {

    param (
        [ValidateSet('Button','CheckBox','CheckedListBox','Form','Label','ListBox','RadioButton','TabControl','TabPage','TextBox')]
        [string]$Type,
        [string]$Name,
        [bool]$UseVisualStyleBackColor=$True,
        [int]$XSize,
        [int]$YSize,
        [int]$TabIndex,
        [string]$BackColor,
        [ValidateSet('Center','None','Stretch','Tile','Zoom')]
        [string]$BackgroundImageLayout,
        [ValidateSet('Fixed3D','FixedDialog','FixedSingle','FixedToolWindow','None','Sizable','SizableToolWindow')]
        [string]$FormBorderStyle,
        [string]$Text,
        [int]$Width,
        [int]$Height,
        [int]$YAxis,
        [int]$XAxis,
        [int]$MaxLength,
        [ValidateSet('CenterParent','CenterScreen','Manual','WindowsDefaultBounds','WindowsDefaultLocation')]
        [string]$StartPosition,
        [bool]$MaximizeBox=$True,
        [bool]$MinimizeBox=$True

    )

    $NewObject = New-Object System.Windows.Forms.$Type
    $NewObject.Location = New-Object system.drawing.point($XAxis,$YAxis)

    If ( $Type -eq 'Button' ) {
        $NewObject.Text = $Text
        $NewObject.Width = $Width
        If ( $Height -ne 0 ) {
            $NewObject.Height = $Height
        }
    }

    If ( $Type -eq 'CheckBox' ) {
        $NewObject.Text = $Text
        $NewObject.Width = $Width
        If ( $Height -ne 0 ) {
            $NewObject.Height = $Height
        }
    }

    If ( $Type -eq 'Form' ) {
        $NewObject.BackColor = $BackColor
        $NewObject.BackgroundImageLayout = $BackgroundImageLayout
        $NewObject.FormBorderStyle = $FormBorderStyle
        $NewObject.Text = $Text
        $NewObject.Width = $Width
        $NewObject.Height = $Height
        $NewObject.StartPosition = $StartPosition
        $NewObject.MaximizeBox = $MaximizeBox
        $NewObject.MinimizeBox = $MinimizeBox
    }

    If ( $Type -eq 'Label') {
        $NewObject.Text = $Text
        $NewObject.Width = $Width
        If ( $Height -ne 0 ) {
            $NewObject.Height = $Height
        }
    }

    If ( $Type -eq 'RadioButton') {
        $NewObject.Text = $Text
        $NewObject.Width = $Width
        If ( $Height -ne 0 ) {
            $NewObject.Height = $Height
        }
    }

    If ( $Type -eq 'TextBox') {
        $NewObject.Text = $Text
        $NewObject.MaxLength = $MaxLength
        $NewObject.Width = $Width
        If ( $Height -ne 0 ) {
            $NewObject.Height = $Height
        }
    }

    If ( $Type -eq 'TabControl' ) {
    }

    If ( $Type -eq 'TabPage' ) {
        $NewObject.Size = "$XSize, $YSize"
        $NewObject.TabIndex = $TabIndex
        $NewObject.Name = $Name
        $NewObject.Text = $Text
        $NewObject.UseVisualStyleBackColor = $UseVisualStyleBackColor
    }

    Return $NewObject

}

$Form = New-CustomControl -Type Form -Text 'Banal testform' -BackColor '#fffff2' -BackgroundImageLayout None -FormBorderStyle FixedDialog -Width 395 -Height 215 -StartPosition CenterScreen -MaximizeBox $False -MinimizeBox $True
$TabControl = New-CustomControl -Type TabControl
$tabNewUser = New-CustomControl -Type TabPage -XSize 390 -YSize 215 -Name 'tabNewUser' -Text 'Skapa en användare' -UseVisualStyleBackColor $True -TabIndex 0
$tabServer = New-CustomControl -Type TabPage -XSize 390 -YSize 215 -Name 'tabServer' -Text 'Servrar' -UseVisualStyleBackColor $True -TabIndex 1

$TabControl.Controls.Add($tabNewUser)
$TabControl.Controls.Add($tabServer)
$TabControl.Width = $Form.Width
$TabControl.Height = $Form.Height
$Form.controls.Add($TabControl)

$lblUserName = New-CustomControl -Type Label -Text 'Användarnamn: ' -Width 100 -XAxis 25 -YAxis 10
$tabNewUser.controls.Add($lblUserName)

$txtUserName = New-CustomControl -Type TextBox -MaxLength 10 -Width 150 -XAxis 200 -YAxis 10
$txtUserNameChange = { if ( $txtUserName.BackColor -eq '#ffffff' ) { $txtUserName.BackColor = '#eeeeee' } Else { $txtUserName.BackColor = '#ffffff' } }
$txtUserName.Add_TextChanged($txtUserNameChange)
$tabNewUser.controls.Add($txtUserName)

$chkBox = New-CustomControl -Type CheckBox -Text 'Enabled' -Width 200 -XAxis 290 -YAxis 40
$tabNewUser.controls.Add($chkBox)

$lblUserName = New-CustomControl -Type Label -Text 'Access group: ' -Width 100 -XAxis 150 -YAxis 70
$tabNewUser.controls.Add($lblUserName)

$RbtnOK = New-CustomControl -Type RadioButton -Text 'Remote Desktop User' -Width 150 -XAxis 70 -YAxis 100
$tabNewUser.controls.Add($RbtnOK)
$RbtnOK2 = New-CustomControl -Type RadioButton -Text 'Administrator' -Width 150 -XAxis 220 -YAxis 100
$tabNewUser.controls.Add($RbtnOK2)

$btnOK = New-CustomControl -Type Button -Text 'Press me!' -Width 150 -XAxis 200 -YAxis 130
$btnOK.Add_Click{ [System.Windows.MessageBox]::Show("$($txtUserName.Text)`n$($chkBox.Checked)`n$($RBtnOK.Checked)",'Titel',"Ok","Information") }
$tabNewUser.controls.Add($btnOK)

[void]$Form.ShowDialog()