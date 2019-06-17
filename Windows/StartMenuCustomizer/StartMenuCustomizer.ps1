#region DeclarationOfVariables
    $HidePSWindow = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);' # Part of the process to hide the Powershellwindow if it is not run through ISE
    Add-Type -name win -member $HidePSWindow -namespace native # Part of the process to hide the Powershellwindow if it is not run through ISE
    if ( $(Test-Path variable:global:psISE) -eq $False ) { [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0) } # This hides the Powershellwindow in the background if ISE isn't running
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  
    [string]$global:CurrentFileName = ''
    [bool]$global:Modified = $false
$DefaultContent = @"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout">
  <LayoutOptions StartTileGroupCellWidth="6" StartTileGroupsColumnCount="1" />
  <DefaultLayoutOverride LayoutCustomizationRestrictionType="OnlySpecifiedGroups">
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6">
      </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>
    <CustomTaskbarLayoutCollection PinListPlacement="Replace">
      <defaultlayout:TaskbarLayout>
        <taskbar:TaskbarPinList>
        </taskbar:TaskbarPinList>
      </defaultlayout:TaskbarLayout>
    </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
"@
    $DefaultContent = $DefaultContent.Replace("`r","")
    $DefaultContent = $DefaultContent.Split("`n")
#endregion

function Verify-CloseUnsavedChanges {
    if ( $Modified -eq $true ) {
        $MessageBody = "There are unsaved changes to the document.`n`nDo you want to save them before closing?"
        $MessageTitle = "Unsaved changes"
        $Choice = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"YesNoCancel","Warning")
    }
    else { $Choice = 'No' }
    return $Choice
}

function Manage-Taskbarsettings {
    write-host $menuOptTaskbar.CheckState
    if ( $menuOptTaskbar.Checked -eq $true ) {
    }
    else {
    }
}

function Add-Item ( [string]$string = "hej" ) {
    $PanelNewItem.BringToFront()
}

function Remove-Item {
    $AssocRow = $Null
    if ( $ListBox.SelectedItem.TrimStart() -like '<start:Folder*' ) {
        $AssocRow = $ListBox.SelectedIndex
        do {
            if ( $ListBox.Items.Item($AssocRow) -like "*</start:Folder*" ) { $EndFound = $true }
            else {
                $AssocRow++
                if ( $AssocRow -eq $ListBox.Items.Count ) { $Endfound = $true }
            }
        } until ( $Endfound -eq $true ) 
        $AssocRow = $AssocRow - 1
    }
    if ( $ListBox.SelectedItem.TrimStart() -like '<start:Group*' ) {
        $AssocRow = $ListBox.SelectedIndex
        do {
            if ( $ListBox.Items.Item($AssocRow) -like "*</start:Group*" ) { $EndFound = $true }
            else {
                $AssocRow++
                if ( $AssocRow -eq $ListBox.Items.Count ) { $Endfound = $true }
            }
        } until ( $Endfound -eq $true ) 
        $AssocRow = $AssocRow - 1
    }

    [int]$Temp = $PositionRow.Text - 1
    $ListBox.BeginUpdate()
    try {
        $ListBox.Items.RemoveAt($ListBox.SelectedIndex)
    }
    catch {
        if ( $AssocRow -ne $Null ) {
            $ListBox.Items.RemoveAt($AssocRow)
        }
    }
    $ListBox.EndUpdate()
    try {
        $ListBox.SelectedIndex = $Temp
    }
    catch {}
    $global:Modified = $true
}

function Remove-All {
    $AssocRow = $Null
    $AssocRows = 0
    if ( $ListBox.SelectedItem.TrimStart() -like '<start:Folder*' ) {
        $AssocRow = $ListBox.SelectedIndex
        do {
            if ( $ListBox.Items.Item($AssocRow) -like "*</start:Folder*" ) { $EndFound = $true }
            else {
                $AssocRow++
                if ( $AssocRow -eq $ListBox.Items.Count ) { $Endfound = $true }
            }
            $AssocRows++
        } until ( $Endfound -eq $true )
        $AssocRow = $AssocRow - 1
    }
    if ( $ListBox.SelectedItem.TrimStart() -like '<start:Group*' ) {
        $AssocRow = $ListBox.SelectedIndex
        do {
            if ( $ListBox.Items.Item($AssocRow) -like "*</start:Group*" ) { $EndFound = $true }
            else {
                $AssocRow++
                if ( $AssocRow -eq $ListBox.Items.Count ) { $Endfound = $true }
            }
            $AssocRows++
        } until ( $Endfound -eq $true )         
        $AssocRow = $AssocRow - 1
    }

    [int]$Temp = $PositionRow.Text - 1
    $ListBox.BeginUpdate()
    $Counter = 0
    do {
        $Counter++
        try {
            $ListBox.Items.RemoveAt($ListBox.SelectedIndex)
        }
        catch {}
        try {
            $ListBox.SelectedIndex = $Temp
        }
        catch {}
    }
    until ( $Counter -eq $AssocRows )
    $ListBox.EndUpdate()
    $global:Modified = $true
}

function Move-SelectedItem ([string]$Direction) {
    $ListBox.BeginUpdate()
    $pos = $ListBox.SelectedIndex
    if ( $Direction -eq 'Up' ) {
        $ListBox.items.insert($pos -1,$ListBox.Items.Item($pos))
        $ListBox.SelectedIndex = ($pos -1)
        $ListBox.Items.RemoveAt($pos +1)
    }
    else {
        $ListBox.items.insert($pos,$ListBox.Items.Item($pos +1))
        $ListBox.SelectedIndex = ($pos +1)
        $ListBox.Items.RemoveAt($pos +2)
    }
    $ListBox.EndUpdate()
    Change-Row
    $global:Modified = $true
}

function Change-Row {

    if ( $ListBox.SelectedItem.TrimStart() -like "*start:Group*" ) {
        $PanelGroup.BringToFront()
        $ComboType.SelectedItem = 'Group'
    }
    if ( $ListBox.SelectedItem.TrimStart() -like "*start:Folder*" ) {
        $PanelFolder.BringToFront()
        $ComboType.SelectedItem = 'Folder'
    }
    if ( $ListBox.SelectedItem.TrimStart() -like "*start:Tile*" ) {
        $PanelTile.BringToFront()
        $ComboType.SelectedItem = 'Tile'
        $ComboTileSize.SelectedItem = $($($ListBox.SelectedItem.Substring($($ListBox.SelectedItem.IndexOf('Size="')),9))).Substring(6,3)
        $NumericTileCol.Text = $($($ListBox.SelectedItem.Substring($($ListBox.SelectedItem.IndexOf('Column="')),9))).Substring(8,1)
        $NumericTileRow.Text = $($($ListBox.SelectedItem.Substring($($ListBox.SelectedItem.IndexOf('Row="')),8))).Substring(5,1)
        $IndexAppUserModelID = $($ListBox.SelectedItem.Substring($($ListBox.SelectedItem.IndexOf('AppUserModelID="')),8))
    }
    if ( $ListBox.SelectedItem.TrimStart() -like "*LayoutModificationTemplate*" ) {
        Try { $PanelLayoutModificationTemplate.BringToFront() } Catch {}
        $ComboType.SelectedItem = 'LayoutModificationTemplate'
    }
    if ( $ListBox.SelectedItem.TrimStart() -like "*LayoutOptions*" ) {
        $PanelLayoutOptions.BringToFront()
        $ComboType.SelectedItem = 'LayoutOptions'
    }
    if ( $ListBox.SelectedItem.TrimStart() -like "*DefaultLayoutOverride*" ) {
        $PanelDefaultLayoutOverride.BringToFront()
        $ComboType.SelectedItem = 'DefaultLayoutOverride'
    }
    if ( $ListBox.SelectedItem.TrimStart() -like "*StartLayoutCollection*" ) {
        $PanelStartLayoutCollection.BringToFront()
        $ComboType.SelectedItem = 'StartLayoutCollection'
    }
    if ( $ListBox.SelectedItem.TrimStart() -like "*defaultlayout:StartLayout*" ) {
        $PanelStartlayout.BringToFront()
        $ComboType.SelectedItem = 'StartLayout'
    }
    if ( $ListBox.SelectedItem.TrimStart() -like "*start:DesktopApplicationTile*" ) {
        $PanelDesktopApplicationTile.BringToFront()
        $ComboType.SelectedItem = 'DesktopApplicationTile'
    }
    $PositionRow.Text = "$($ListBox.SelectedIndex + 1)"

    if ( $ListBox.SelectedItem.TrimStart() -like '<start:*' -or $ListBox.SelectedItem.TrimStart() -like '<defaultlayout:*' -or ($ListBox.SelectedItem.TrimStart() -like '<taskbar:*' -and $ListBox.SelectedItem.TrimStart() -notlike '<taskbar:TaskbarPinList*')) {
        $BtnMoveUp.Enabled = $true
        $BtnMoveDown.Enabled = $true
        $BtnRemoveItem.Enabled = $true
        $BtnInsertNewItem.Enabled = $true
        if ( $ListBox.Items.Item($ListBox.SelectedIndex-1)  -like "*<defaultlayout:*" -or $ListBox.Items.Item($ListBox.SelectedIndex-1)  -like "*<taskbar:taskBarPinList*" ) { $BtnMoveUp.Enabled = $false }
        else { $BtnMoveUp.Enabled = $true }
        if ( $ListBox.Items.Item($ListBox.SelectedIndex+1) -like "*</defaultlayout:*" -or $ListBox.Items.Item($ListBox.SelectedIndex+1)  -like "*</taskbar:*" ) { $BtnMoveDown.Enabled = $false }
        else { $BtnMoveDown.Enabled = $true }
        if ( $ListBox.SelectedItem.TrimStart() -like '<defaultlayout:*' ) {
            $BtnMoveUp.Enabled = $false
            $BtnMoveDown.Enabled = $false
            $BtnRemoveItem.Enabled = $false
        }
    }
    else {
        $BtnMoveUp.Enabled = $false
        $BtnMoveDown.Enabled = $false
        $BtnInsertNewItem.Enabled = $false
        $BtnRemoveItem.Enabled = $false
    }

    if ( $ListBox.SelectedItem.TrimStart() -like '<start:Folder*' -or $ListBox.SelectedItem.TrimStart() -like '<start:Group*' ) {
        $BtnRemoveAll.Visible = $true
        if ( $ListBox.SelectedItem.TrimStart() -like '<start:Folder*' ) {
            $BtnRemoveAll.Text = "Remove &entire Folder"
        }
        else {
            $BtnRemoveAll.Text = "Remove &entire Group"
        }
    }
    else {
        $BtnRemoveAll.Visible = $false
    }
}

#region mainForm
    Add-Type -AssemblyName System.Windows.Forms
    $mainForm = New-Object system.Windows.Forms.Form
    $mainForm.Text = "Start Menu (Layout) Customizer - Untitled1.xml"
    $mainForm.FormBorderStyle = 'Fixed3D'
    $mainForm.MaximizeBox = $false
    if ( $(Test-Path variable:global:psISE) -eq $False ) {
        $mainForm.Size = New-Object System.Drawing.Size(1290,778)
    }
    else {
        $mainForm.Size = New-Object System.Drawing.Size(1280,768)
    }
    $mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHOME + "\powershell_ise.exe")
    $mainForm.StartPosition = "centerscreen"
#endregion

#region Menu
    function New-File {
        $SaveChanges = Verify-CloseUnsavedChanges
        if ( $SaveChanges -eq 'No' ) {
            $ListBox.Items.Clear()
            foreach ( $Line in $DefaultContent ) {
                $ListBox.Items.Add($Line) | out-null
                ff ( $Line -like '*<CustomTaskbarLayoutCollection*' ) {
                    $menuOptTaskbar.Checked = $true
                }
                else {
                    $menuOptTaskbar.Checked = $false
                }
            }
            $mainForm.Text = "Start Menu (Layout) Customizer - Untitled1.xml"
            $global:CurrentFileName = ''
            $ListBox.SelectedIndex = 0
            $global:Modified = $false
        }
        if ( $SaveChanges -eq 'Yes' ) {
            if ( $CurrentFileName -ne '' ) {
                Out-File $CurrentFileName
                foreach ( $Line in $ListBox.Items ) {
                    Add-Content -Path $CurrentFileName -Value $Line -Encoding UTF8 -Force
                }
                $ListBox.Items.Clear()
                foreach ( $Line in $DefaultContent ) {
                    $ListBox.Items.Add($Line) | out-null
                }
                $mainForm.Text = "Start Menu (Layout) Customizer - Untitled1.xml"
                $global:CurrentFileName = ".\Untitled1.xml"
                $ListBox.SelectedIndex = 0
                $global:Modified = $false
            }
            else {
                $Result = Save-As
                if ( $Result -eq 'OK' ) {
                    $ListBox.Items.Clear()
                    foreach ( $Line in $DefaultContent ) {
                        $ListBox.Items.Add($Line) | out-null
                        ff ( $Line -like '*<CustomTaskbarLayoutCollection*' ) {
                            $menuOptTaskbar.Checked = $true
                        }
                        else {
                            $menuOptTaskbar.Checked = $false
                        }
                    }
                    $mainForm.Text = "Start Menu (Layout) Customizer - Untitled1.xml"
                    $global:CurrentFileName = ".\Untitled1.xml"
                    $ListBox.SelectedIndex = 0
                    $global:Modified = $false
                }
            }
        }
    }
    
    function Open-File {
        $SaveChanges = Verify-CloseUnsavedChanges
        if ( $SaveChanges -eq 'No' ) {
            $inputFileName = $Null
            $selectOpenForm = New-Object System.Windows.Forms.OpenFileDialog
            $selectOpenForm.Filter = "XML-files (*.xml)|*.xml"
            $selectOpenForm.InitialDirectory = ".\"
            $selectOpenForm.Title = "Select a File to Open"
            $Result = $selectOpenForm.ShowDialog()
            if ($Result -eq "OK") {
                $inputFileName = $selectOpenForm.FileName
                $Content = Get-Content $inputFileName -Encoding UTF8
                if ( $Content[0] -like '<LayoutModificationTemplate *' ) {
                    $ListBox.Items.Clear()
                    foreach ( $Line in $Content ) {
                        $ListBox.Items.Add($Line) | out-null
                        ff ( $Line -like '*<CustomTaskbarLayoutCollection*' ) {
                            $menuOptTaskbar.Checked = $true
                        }
                        else {
                            $menuOptTaskbar.Checked = $false
                        }
                    }
                    $global:CurrentFileName = $inputFileName
                    $global:Modified = $false
                    $mainForm.Text = "Start Menu (Layout) Customizer - $CurrentFileName"
                }
                else {
                    $MessageBody = "This document is an invalid Start menu XML-file.`n`nAborting operation!"
                    $MessageTitle = "Unable to open XML-file"
                    $Choice = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"OK","Error")
                }      
            }
        }
        if ( $SaveChanges -eq 'Yes' ) {
            if ( $CurrentFileName -ne '' ) {
                Out-File $CurrentFileName
                foreach ( $Line in $ListBox.Items ) {
                    Add-Content -Path $CurrentFileName -Value $Line -Encoding UTF8 -Force
                }
                $global:Modified = $false
                Open-File
            }
            else {
                $Result = Save-As
                if ( $Result -eq 'OK' ) {
                    $global:Modified = $false
                    Open-File
                }
            }
        }
    }
    
    function Save {
        if ( $CurrentFileName -ne '' ) {
            Out-File $CurrentFileName -Encoding UTF8 -Force
            foreach ( $Line in $ListBox.Items ) {
                Add-Content -Path $CurrentFileName -Value $Line -Encoding UTF8 -Force
            }
            $global:Modified = $false
            $mainForm.Text = "Start Menu (Layout) Customizer - $CurrentFileName"
        }
        else { Save-As }
    }
    
    function Save-As {
        $outputFileName = $Null
        $selectSaveAsForm = New-Object System.Windows.Forms.SaveFileDialog
        $selectSaveAsForm.Filter = "XML-file (*.xml)|*.xml"
        $selectSaveAsForm.InitialDirectory = ".\"
        $selectSaveAsForm.Title = "Select a File to Save"
        $Result = $selectSaveAsForm.ShowDialog()
        if ($Result -eq "OK") {
            $outputFileName = $selectSaveAsForm.FileName
            if ( $outputFileName -ne $Null ) {
                Out-File $outputFileName
                foreach ( $Line in $ListBox.Items ) {
                    Add-Content -Path $outputFileName -Value $Line -Encoding UTF8 -Force
                }
                $global:CurrentFileName = $outputFileName
                $global:Modified = $false
                $mainForm.Text = "Start Menu (Layout) Customizer - $CurrentFileName"
            }
        }
        return $Result
    }

    function About {
        $aboutForm          = New-Object System.Windows.Forms.Form
        $aboutFormExit      = New-Object System.Windows.Forms.Button
        $aboutFormImage     = New-Object System.Windows.Forms.PictureBox
        $aboutFormNameLabel = New-Object System.Windows.Forms.Label
        $aboutFormText      = New-Object System.Windows.Forms.Label
     
        $aboutForm.AcceptButton  = $aboutFormExit
        $aboutForm.CancelButton  = $aboutFormExit
        $aboutForm.ClientSize    = "350, 115"
        $aboutForm.ControlBox    = $false
        $aboutForm.FormBorderStyle = 'Fixed3D'
        $aboutForm.ShowInTaskBar = $false
        $aboutForm.StartPosition = "CenterParent"
        $aboutForm.Text          = "StartMenuCustomizer.ps1"
        $aboutForm.Add_Load($aboutForm_Load)
    
        $aboutFormNameLabel.Font     = New-Object Drawing.Font("Microsoft Sans Serif", 9, [System.Drawing.FontStyle]::Bold)
        $aboutFormNameLabel.Location = "80, 20"
        $aboutFormNameLabel.Size     = "200, 18"
        $aboutFormNameLabel.Text     = "Start Menu (Layout) Customizer"
        $aboutForm.Controls.Add($aboutFormNameLabel)
     
        $aboutFormText.Location = "100, 40"
        $aboutFormText.Size     = "300, 30"
        $aboutFormText.Text     = "          Fredrik Bergman `n`r www.onpremproblems.com"
        $aboutForm.Controls.Add($aboutFormText)
     
        $aboutFormExit.Location = "135, 75"
        $aboutFormExit.Text     = "OK"
        $aboutForm.Controls.Add($aboutFormExit)
     
        [void]$aboutForm.ShowDialog()
    }
#region Menuitems
    $menuMain         = New-Object System.Windows.Forms.MenuStrip
    $menuNew          = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuFile         = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuOpen         = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuSave         = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuSaveAs       = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuHelp         = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuAbout        = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuOptions      = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuOptTaskbar   = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuMain.ResetBackColor()
    [void]$mainForm.Controls.Add($menuMain)
    $menuFile.Text = "File"
    [void]$menuMain.Items.Add($menuFile)
    $menuNew.Text = "New"
    $menuNew.ShortcutKeys = "Ctrl+N"
    $menuNew.Add_Click({New-File})
    [void]$menuFile.DropDownItems.Add($menuNew)
    $menuOpen.Text = "Open..."
    $menuOpen.ShortcutKeys = "Ctrl+O"
    $menuOpen.Add_Click({Open-File})
    [void]$menuFile.DropDownItems.Add($menuOpen)
    $menuSave.Text = "Save"
    $menuSave.ShortcutKeys = "Ctrl+S"
    $menuSave.Add_Click({Save})
    [void]$menuFile.DropDownItems.Add($menuSave)
    $menuSaveAs.Text = "Save As..."
    $menuSaveAs.ShortcutKeys = "Shift+Ctrl+S"
    $menuSaveAs.Add_Click({Save-As})
    [void]$menuFile.DropDownItems.Add($menuSaveAs)

    # Menu Options - Tools / Options
    $menuOptions.Text = "Options"
    [void]$menuMain.Items.Add($menuOptions)
     
    # Menu Options - Tools / Options / Options 1
    $menuOptTaskbar.Text      = "Include taskbar"
    $menuOptTaskbar.CheckOnClick = $true
    $menuOptTaskbar.Add_Click({Manage-Taskbarsettings})
    [void]$menuOptions.DropDownItems.Add($menuOptTaskbar)
        
    $menuAbout.Text = "About"
    $menuAbout.Add_Click({About})
    [void]$menuMain.Items.Add($menuAbout)    
#endregion
#endregion

#region controls in mainForm
    $ComboType = New-Object System.Windows.Forms.ComboBox
    $ComboType.Location = New-Object System.Drawing.Point(1080,27)
    $ComboType.Width = 170
    $ComboType.Enabled = $false
    $ComboTypeItems = @('Group','Folder','Tile','LayoutModificationTemplate','LayoutOptions','DefaultLayoutOverride','StartLayoutCollection','StartLayout','DesktopApplicationTile')
    foreach ( $ComboTypeItem in $ComboTypeItems ) {
        $ComboType.Items.Add($ComboTypeItem) | out-null
    }
    $mainForm.Controls.Add($ComboType)
    
    $LabelRow = New-Object System.Windows.Forms.Label
    $LabelRow.Location = New-Object System.Drawing.Point(10,706)
    $LabelRow.Text = "Line:"
    $LabelRow.Width = 30
    $mainForm.Controls.Add($LabelRow)
    
    $PositionRow = New-Object System.Windows.Forms.Label
    $PositionRow.Location = New-Object System.Drawing.Point(38,706)
    $PositionRow.Text = 1
    $PositionRow.AutoSize = $true
    $mainForm.Controls.Add($PositionRow)
    
    $BtnMoveUp = New-Object System.Windows.Forms.Button
    $BtnMoveUp.Enabled = $false
    $BtnMoveUp.Location = New-Object System.Drawing.Point(75,702)
    $BtnMoveUp.Width = 100
    $BtnMoveUp.Text = "Move &up"
    $BtnMoveUp.Add_Click({Move-SelectedItem -Direction Up})
    $mainForm.Controls.Add($BtnMoveUp)
    
    $BtnMoveDown = New-Object System.Windows.Forms.Button
    $BtnMoveDown.Enabled = $false
    $BtnMoveDown.Location = New-Object System.Drawing.Point(180,702)
    $BtnMoveDown.Width = 100
    $BtnMoveDown.Text = "Move &down"
    $BtnMoveDown.Add_Click({Move-SelectedItem -Direction Down})
    $mainForm.Controls.Add($BtnMoveDown)
    
    $BtnInsertNewItem = New-Object System.Windows.Forms.Button
    $BtnInsertNewItem.Text = "Insert new &item"
    $BtnInsertNewItem.Enabled = $false
    $BtnInsertNewItem.Width = 100
    $BtnInsertNewItem.Location = New-Object System.Drawing.Point(917,702)
    $BtnInsertNewItem.Add_Click({Add-Item})
    $mainForm.Controls.Add($BtnInsertNewItem)
    
    $BtnRemoveItem = New-Object System.Windows.Forms.Button
    $BtnRemoveItem.Text = "&Remove"
    $BtnRemoveItem.Enabled = $false
    $BtnRemoveItem.Width = 100
    $BtnRemoveItem.Location = New-Object System.Drawing.Point(285,702)
    $BtnRemoveItem.Add_Click({Remove-Item})
    $mainForm.Controls.Add($BtnRemoveItem)
    
    $BtnRemoveAll = New-Object System.Windows.Forms.Button
    $BtnRemoveAll.Text = "Remove All"
    $BtnRemoveAll.Visible = $false
    $BtnRemoveAll.Width = 150
    $BtnRemoveAll.Location = New-Object System.Drawing.Point(390,702)
    $BtnRemoveAll.Add_Click({Remove-All})
    $mainForm.Controls.Add($BtnRemoveAll)

    $ListBox = New-Object System.Windows.Forms.ListBox
    $ListBox.Location = New-Object System.Drawing.Point(0,27)
    $ListBox.HorizontalScrollbar=$true
    $ListBox.Width = 1017
    $ListBox.Height = 670
    $ListBox.Add_SelectedIndexChanged({Change-Row})
    if ( $DefaultContent -ne $Null ) {
        foreach ( $Line in $DefaultContent ) {
            $ListBox.Items.Add($Line) | out-null
            if ( $Line -like '*<CustomTaskbarLayoutCollection*' ) {
                $menuOptTaskbar.CheckState
                $menuOptTaskbar.Checked = $true
                $menuOptTaskbar.CheckState
            }
            else {
                $menuOptTaskbar.Checked = $false
            }
        }
    }
    if ( $ListBox.Items.Count -gt 0 ) { $ListBox.SelectedIndex = 0 }
    $mainForm.Controls.Add($ListBox)
    
    $LabelType = New-Object System.Windows.Forms.Label
    $LabelType.Location = New-Object System.Drawing.Point(1030,30)
    $LabelType.Text = "Type:"
    $LabelType.Autosize = $true
    $mainForm.Controls.Add($LabelType)
#endregion

#region Panels
    #region PanelFolder
        $PanelFolder = New-Object System.Windows.Forms.Panel
        $PanelFolder.Size = New-Object Drawing.Size @(220,630)
        $PanelFolder.Location = New-Object System.Drawing.Point(1030,60)
        $mainForm.Controls.Add($PanelFolder)
    #endregion

    #region PanelGroup
        $PanelGroup = New-Object System.Windows.Forms.Panel
        $PanelGroup.Size = New-Object Drawing.Size @(220,630)
        $PanelGroup.Location = New-Object System.Drawing.Point(1030,60)
        $mainForm.Controls.Add($PanelGroup)
    #endregion

    #region PanelTIle
        $PanelTile = New-Object System.Windows.Forms.Panel
        $PanelTile.Size = New-Object Drawing.Size @(220,630)
        $PanelTile.Location = New-Object System.Drawing.Point(1030,60)
        $mainForm.Controls.Add($PanelTIle)
        $LabelTileSize = New-Object System.Windows.Forms.Label
        $LabelTileSize.Location = New-Object System.Drawing.Point(0,5)
        $LabelTileSize.Text = "Size"
        $LabelTileSize.Width = '50'
        $PanelTile.Controls.Add($LabelTileSize)
        $ComboTileSize = New-Object System.Windows.Forms.ComboBox
        $ComboTileSize.Location = New-Object System.Drawing.Point(50,0)
        $ComboTileSize.DropDownStyle = 'DropDownList'
        $ComboTileSize.Width = 170
        $SizeItems = @('1x1','2x2','2x4','4x4')
        foreach ( $SizeItem in $SizeItems ) {
            $ComboTileSize.Items.Add($SizeItem) | out-null
        }
        $PanelTile.Controls.Add($ComboTileSize)
        $LabelTileColumn = New-Object System.Windows.Forms.Label
        $LabelTileColumn.Text = "Column"
        $LabelTileColumn.Width = '50'
        $LabelTileColumn.Location = New-Object System.Drawing.Point(0,35)
        $PanelTile.Controls.Add($LabelTileColumn)
        $NumericTileCol = New-Object System.Windows.Forms.NumericUpDown
        $NumericTileCol.TextAlign = "Center"
        $NumericTileCol.Width = 170
        $NumericTileCol.Location = New-Object System.Drawing.Point(50,32)
        $PanelTile.Controls.Add($NumericTileCol)
        $LabelTileRow = New-Object System.Windows.Forms.Label
        $LabelTileRow.Text = "Row"
        $LabelTileRow.Width = '50'
        $LabelTileRow.Location = New-Object System.Drawing.Point(0,70)
        $PanelTile.Controls.Add($LabelTileRow)
        $NumericTileRow = New-Object System.Windows.Forms.NumericUpDown
        $NumericTileRow.TextAlign = "Center"
        $NumericTileRow.Width = 170
        $NumericTileRow.Location = New-Object System.Drawing.Point(50,67)
        $PanelTile.Controls.Add($NumericTileRow)
        $mainForm.Controls.Add($BtnMoveUp)
    #endregion

    #region PanelLayoutModificationTemplate
        $PanelLayoutModificationTemplate = New-Object System.Windows.Forms.Panel
        $PanelLayoutModificationTemplate.Size = New-Object Drawing.Size @(220,630)
        $PanelLayoutModificationTemplate.Location = New-Object System.Drawing.Point(1030,60)
        $mainForm.Controls.Add($PanelLayoutModificationTemplate)
    #endregion

    #region PanelLayoutOptions
        $PanelLayoutOptions = New-Object System.Windows.Forms.Panel
        $PanelLayoutOptions.Size = New-Object Drawing.Size @(220,630)
        $PanelLayoutOptions.Location = New-Object System.Drawing.Point(1030,60)
        $mainForm.Controls.Add($PanelLayoutOptions)
    #endregion

    #region PanelDefaultLayoutOverride
        $PanelDefaultLayoutOverride = New-Object System.Windows.Forms.Panel
        $PanelDefaultLayoutOverride.Size = New-Object Drawing.Size @(220,630)
        $PanelDefaultLayoutOverride.Location = New-Object System.Drawing.Point(1030,60)
        $mainForm.Controls.Add($PanelDefaultLayoutOverride)
    #endregion

    #region PanelStartLayoutCollection
        $PanelStartLayoutCollection = New-Object System.Windows.Forms.Panel
        $PanelStartLayoutCollection.Size = New-Object Drawing.Size @(220,630)
        $PanelStartLayoutCollection.Location = New-Object System.Drawing.Point(1030,60)
        $mainForm.Controls.Add($PanelStartLayoutCollection)
    #endregion

    #region PanelStartLayout
        $PanelStartlayout = New-Object System.Windows.Forms.Panel
        $PanelStartlayout.Size = New-Object Drawing.Size @(220,630)
        $PanelStartlayout.Location = New-Object System.Drawing.Point(1030,60)
        $mainForm.Controls.Add($PanelStartlayout)
    #endregion

    #region PanelDesktopApplicationTile
        $PanelDesktopApplicationTile = New-Object System.Windows.Forms.Panel
        $PanelDesktopApplicationTile.Size = New-Object Drawing.Size @(220,630)
        $PanelDesktopApplicationTile.Location = New-Object System.Drawing.Point(1030,60)
        $mainForm.Controls.Add($PanelDesktopApplicationTile)
    #endregion

    #region PanelNewItem
        $PanelNewItem = New-Object System.Windows.Forms.Panel
        $PanelNewItem.Size = New-Object Drawing.Size @(220,630)
        $PanelNewItem.Location = New-Object System.Drawing.Point(1030,60)
        $mainForm.Controls.Add($PanelNewItem)
    #endregion
#endregion

#region GetApplicationLinks
    $AllUserLinks = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\*.lnk" -Recurse
    $AllComputerLinks = Get-ChildItem "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\*.lnk" -Recurse
    #$AllLinks[0].FullName # Name
    try { $AllXPackages = Get-AppxPackage -AllUsers | Select-Object Name, PackageFamilyName }
    catch {
        try { $AllXPackages = Get-AppxPackage | Select-Object Name, PackageFamilyName }
        catch {}
    }
#endregion

$mainForm.ShowDialog()