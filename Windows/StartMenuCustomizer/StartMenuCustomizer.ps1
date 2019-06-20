#region DeclarationOfVariables
    Add-Type -AssemblyName System.Windows.Forms
    #Add-Type -AssemblyName PresentationFramework
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
$DefaultContent = @"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout">
  <LayoutOptions StartTileGroupCellWidth="6" StartTileGroupsColumnCount="1" />
  <DefaultLayoutOverride LayoutCustomizationRestrictionType="OnlySpecifiedGroups">
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6">
        <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Flashplayer.lnk" />
        <start:Group Name="Rekommenderat">
          <start:Folder Size="2x2" Column="0" Row="0">
            <start:Tile Size="2x2" Column="0" Row="0" AppUserModelID="Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge" />
            <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk" />
            <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk" />
          </start:Folder>
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
          <start:Folder Size="2x2" Column="0" Row="2">
            <start:Tile Size="2x2" Column="0" Row="0" AppUserModelID="Microsoft.WindowsMaps_8wekyb3d8bbwe!App" />
            <start:Tile Size="2x2" Column="2" Row="0" AppUserModelID="Microsoft.Windows.Photos_8wekyb3d8bbwe!App" />
            <start:Tile Size="2x2" Column="4" Row="0" AppUserModelID="Microsoft.BingWeather_8wekyb3d8bbwe!App" />
            <start:Tile Size="2x2" Column="0" Row="2" AppUserModelID="Microsoft.WindowsCalculator_8wekyb3d8bbwe!App" />
          </start:Folder>
        </start:Group>
        <start:Group Name="Office">
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Outlook.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Outlook 2016.lnk" />
          <start:DesktopApplicationTile Size="1x1" Column="2" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Word.lnk" />
          <start:DesktopApplicationTile Size="1x1" Column="2" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Word 2016.lnk" />
          <start:DesktopApplicationTile Size="1x1" Column="3" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk" />
          <start:DesktopApplicationTile Size="1x1" Column="3" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\PowerPoint 2016.lnk" />
          <start:DesktopApplicationTile Size="1x1" Column="2" Row="1" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Excel.lnk" />
          <start:DesktopApplicationTile Size="1x1" Column="2" Row="1" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Excel 2016.lnk" />
          <start:DesktopApplicationTile Size="1x1" Column="3" Row="1" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\OneNote.lnk" />
          <start:DesktopApplicationTile Size="1x1" Column="3" Row="1" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\OneNote 2016.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Skype for Business 2016.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Skype för företag 2016.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Skype för företag.lnk" />
        </start:Group>
      </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>
    <CustomTaskbarLayoutCollection PinListPlacement="Replace">
      <defaultlayout:TaskbarLayout>
        <taskbar:TaskbarPinList>
          <taskbar:UWA AppUserModelID="Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge" />
          <taskbar:DesktopApp DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk" />
          <taskbar:DesktopApp DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
          <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Outlook.lnk" />
          <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Outlook 2016.lnk" />
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
        $Choice = [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,"YesNoCancel","Warning")
    }
    else { $Choice = 'No' }
    return $Choice
}

function Manage-Taskbarsettings {
    if ( $menuOptTaskbar.Checked -eq $true ) {
        $ListBox.Items.Insert($($ListBox.Items.Count -1),'    <CustomTaskbarLayoutCollection PinListPlacement="Replace">')
        $ListBox.Items.Insert($($ListBox.Items.Count -1),'      <defaultlayout:TaskbarLayout>')
        $ListBox.Items.Insert($($ListBox.Items.Count -1),'        <taskbar:TaskbarPinList>')
        $ListBox.Items.Insert($($ListBox.Items.Count -1),'        </taskbar:TaskbarPinList>')
        $ListBox.Items.Insert($($ListBox.Items.Count -1),'      </defaultlayout:TaskbarLayout>')
        $ListBox.Items.Insert($($ListBox.Items.Count -1),'    </CustomTaskbarLayoutCollection>')
        $global:Modified = $true
    }
    else {
        $MessageBody = "All parts of the custom taskbar will be removed.`n`nAre you sure?"
        $MessageTitle = "Removing custom Taskbar"
        $Choice = [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,"YesNo","Warning")
        If ( $Choice -eq 'Yes' ) {
            $AssocRow = $Null
            $AssocRows = 0
            foreach ( $item in $ListBox.Items ) {
                if ( $Item.TrimStart() -like '<CustomTaskbarLayoutCollection*' ) {
                    $AssocRow = $ListBox.Items.IndexOf($Item)
                }
            }

            $Counter = 0
            $TempRow = $AssocRow
            do {
                if ( $ListBox.Items.Item($TempRow) -like "*</CustomTaskbarLayoutCollection*" ) { $EndFound = $true }
                else {
                    $TempRow++
                    if ( $TempRow -eq $ListBox.Items.Count ) { $Endfound = $true }
                }
                $AssocRows++
            } until ( $Endfound -eq $true )         
        
            [int]$Temp = $LblPositionRow.Text - 1
            $ListBox.BeginUpdate()
            $Counter = 0
            do {
                $Counter++
                try {
                    $ListBox.Items.RemoveAt($AssocRow)
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
        Else {
            $menuOptTaskbar.Checked = $true
        }
    }
}

function Insert-NewItem ( [string]$string = "hej" ) {
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

    [int]$Temp = $LblPositionRow.Text - 1
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
    if ( $ListBox.SelectedItem.TrimStart() -like '<start:Folder*' ) { $RemoveAllType = "folder" }
    if ( $ListBox.SelectedItem.TrimStart() -like '<start:Group*' ) { $RemoveAllType = "group" }
    $MessageBody = "All parts of the selected $RemoveAllType will be removed.`n`nAre you sure?"
    $MessageTitle = "Removing entire $RemoveAllType"
    $Choice = [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,"YesNo","Warning")
    If ( $Choice -eq 'Yes' ) {
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

        [int]$Temp = $LblPositionRow.Text - 1
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
    Change-ListBoxRow
    $global:Modified = $true
}

function Change-ListBoxRow {
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
        $SelectedItem = $ListBox.SelectedItem.Split('"')
        $Counter = 0
        foreach ( $Item in $SelectedItem ) {
            if ( $Item -like '*Size=*' ) { $ComboTileSize.SelectedItem = $SelectedItem[$Counter +1] }
            if ( $Item -like '*Row=*' ) { $NumericTileRow.Text = $SelectedItem[$Counter +1] }
            if ( $Item -like '*Column=*' ) { $NumericTileCol.Text = $SelectedItem[$Counter +1] }
            if ( $Item -like '*AppUserModelID=*' ) {
                if ( $ComboBoxAppUserModelID.Items -contains $SelectedItem[$Counter +1] ) {
                    $ComboBoxAppUserModelID.SelectedItem = $SelectedItem[$Counter +1]
                }
                    else { $ComboBoxAppUserModelID.Text = $SelectedItem[$Counter +1]
                }
            }
            $Counter++
        }
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
        $PanelDAT.BringToFront()
        $ComboType.SelectedItem = 'DesktopApplicationTile'
        $SelectedItem = $ListBox.SelectedItem.Split('"')
        $Counter = 0
        foreach ( $Item in $SelectedItem ) {
            if ( $Item -like '*Size=*' ) { $ComboDATSize.SelectedItem = $SelectedItem[$Counter +1] }
            if ( $Item -like '*Row=*' ) { $NumericDATRow.Text = $SelectedItem[$Counter +1] }
            if ( $Item -like '*Column=*' ) { $NumericDATCol.Text = $SelectedItem[$Counter +1] }
            if ( $Item -like '*DesktopApplicationLinkPath=*' ) {
                if ( $ComboBoxDAT.Items -contains $SelectedItem[$Counter +1] ) {
                    $ComboBoxDAT.SelectedItem = $SelectedItem[$Counter +1]
                }
                    else { $ComboBoxDAT.Text = $SelectedItem[$Counter +1]
                }
            }
            $Counter++
        }
    }
    $LblPositionRow.Text = "$($ListBox.SelectedIndex + 1)"

    if ( $ListBox.SelectedItem.TrimStart() -like '<start:*' -or $ListBox.SelectedItem.TrimStart() -like '</start:*' -or $ListBox.SelectedItem.TrimStart() -like '<defaultlayout:Start*' -or $ListBox.SelectedItem.TrimStart() -like '<taskbar:*' ) {
        $BtnMoveUp.Enabled = $true
        $BtnMoveDown.Enabled = $true
        $BtnRemoveItem.Enabled = $true
        $BtnInsertNewItem.Enabled = $true
        if ( $ListBox.Items.Item($ListBox.SelectedIndex-1)  -like "*<defaultlayout:Start*" -or $ListBox.Items.Item($ListBox.SelectedIndex-1)  -like "*<taskbar:taskBarPinList*" ) { $BtnMoveUp.Enabled = $false }
        else { $BtnMoveUp.Enabled = $true }
        if ( $ListBox.Items.Item($ListBox.SelectedIndex+1) -like "*</defaultlayout:Start*" -or $ListBox.Items.Item($ListBox.SelectedIndex+1)  -like "*</taskbar:*" ) { $BtnMoveDown.Enabled = $false }
        else { $BtnMoveDown.Enabled = $true }
        if ( $ListBox.SelectedItem.TrimStart() -like '</start:Folder*' ) {
            $BtnRemoveItem.Enabled = $false
            If ( $ListBox.Items.Item($ListBox.SelectedIndex-1) -like "*<start:Folder*" ) { $BtnMoveUp.Enabled = $false }
            If ( $ListBox.Items.Item($ListBox.SelectedIndex+1) -like "*<start:Folder*" ) { $BtnMoveDown.Enabled = $false }
        }
        if ( $ListBox.SelectedItem.TrimStart() -like '</start:Group*' ) {
            $BtnRemoveItem.Enabled = $false
            If ( $ListBox.Items.Item($ListBox.SelectedIndex-1) -like "*<start:Group*" ) { $BtnMoveUp.Enabled = $false }
            If ( $ListBox.Items.Item($ListBox.SelectedIndex+1) -like "*<start:Group*" ) { $BtnMoveDown.Enabled = $false }
        }
        if ( $ListBox.SelectedItem.TrimStart() -like '<start:Folder*' ) {
            $BtnRemoveItem.Enabled = $false
            If ( $ListBox.Items.Item($ListBox.SelectedIndex-1) -like "*</start:Folder*" ) { $BtnMoveUp.Enabled = $false }
            If ( $ListBox.Items.Item($ListBox.SelectedIndex+1) -like "*</start:Folder*" ) { $BtnMoveDown.Enabled = $false }
        }
        if ( $ListBox.SelectedItem.TrimStart() -like '<start:Group*' ) {
            $BtnRemoveItem.Enabled = $false
            If ( $ListBox.Items.Item($ListBox.SelectedIndex-1) -like "*</start:Group*" ) { $BtnMoveUp.Enabled = $false }
            If ( $ListBox.Items.Item($ListBox.SelectedIndex+1) -like "*</start:Group*" ) { $BtnMoveDown.Enabled = $false }
        }
        if ( $ListBox.SelectedItem.TrimStart() -like '<defaultlayout:*' -or $ListBox.SelectedItem.TrimStart() -like '<taskbar:TaskbarPinList*') {
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

function Show-DesignView {
    $BtnChangeView.Text = "&Cancel"
    $ListBox.Visible = $false
    $ListBox.Enabled = $false
    $mainTxtBox.Visible = $true
    $mainTxtBox.Enabled = $true
    $menuOptTaskbar.Enabled = $false
    $ComboType.Visible = $false
    $LblRow.Visible = $false
    $LblPositionRow.Visible = $false
    $BtnMoveUp.Visible = $false
    $BtnMoveDown.Visible = $false
    $BtnRemoveItem.Visible = $false
    $BtnRemoveAll.Visible = $false
    $BtnInsertNewItem.Visible = $false
    $BtnTextViewApply.Visible = $true
    $mainTxtBox.BringToFront()
    $mainTxtBox.Clear()
    foreach ( $item in $ListBox.Items ) {
        $mainTxtBox.Text += "$Item`n"
    }
    $BtnTextViewApply.Enabled = $false
    $mainTxtBox.Focus()
}

function Hide-DesignView {
    $BtnChangeView.Text = "Text-&view"
    $ListBox.Visible = $true
    $ListBox.Enabled = $true
    $mainTxtBox.Visible = $false
    $mainTxtBox.Enabled = $false
    $menuOptTaskbar.Enabled = $true
    $ComboType.Visible = $true
    $LblRow.Visible = $true
    $LblPositionRow.Visible = $true
    $BtnMoveUp.Visible = $true
    $BtnMoveDown.Visible = $true
    $BtnRemoveItem.Visible = $true
    $BtnInsertNewItem.Visible = $true
    $BtnTextViewApply.Visible = $false
    $ListBox.SelectedIndex = 0
}

function Apply-TextViewResult {
            $ListBox.Items.Clear()
            if ( $mainTxtBox.Text -contains '<CustomTaskbarLayoutCollection' ) {
                $menuOptTaskbar.Checked = $true
            }
            else {
                $menuOptTaskbar.Checked = $false
            }

            foreach ( $Line in $mainTxtBox.Text.Split("`n") ) {
                if ( $Line -ne '' ) {
                    $ListBox.Items.Add($Line.TrimEnd()) | out-null
                }
            }
            Hide-DesignView
}

#region mainForm
    $mainForm = New-Object system.Windows.Forms.Form
    $mainForm.Text = "Start Menu (Layout) Customizer - Untitled1.xml"
    $mainForm.Font = 'MS Sans Serif,10,style=Regular'
    $mainForm.FormBorderStyle = 'Fixed3D'
    $mainForm.BackColor = '#ffffff'
    $mainForm.add_FormClosing({
        $SaveChanges = Verify-CloseUnsavedChanges
        If ( $SaveChanges -eq 'Yes ' ) {
            $SaveBeforeClosing = Save-LayoutFile
            If ( $SaveBeforeClosing -eq 'Cancel' ) {
                $_.Cancel = $true
            }
        }
        If ( $SaveChanges -eq 'Cancel' ) {
            $_.Cancel = $true
        }
    })
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
    function New-LayoutFile {
        $SaveChanges = Verify-CloseUnsavedChanges
        if ( $SaveChanges -eq 'No' ) {
            $ListBox.Items.Clear()
            if ( $DefaultContent -like '*<CustomTaskbarLayoutCollection*' ) {
                $menuOptTaskbar.Checked = $true
            }
            else {
                $menuOptTaskbar.Checked = $false
            }
            foreach ( $Line in $DefaultContent ) {
                $ListBox.Items.Add($Line) | out-null
            }
            $mainForm.Text = "Start Menu (Layout) Customizer - Untitled1.xml"
            $global:CurrentFileName = ''
            $ListBox.SelectedIndex = 0
            $global:Modified = $false
            Hide-DesignView
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
                Hide-DesignView
            }
            else {
                $Result = Save-As
                if ( $Result -eq 'OK' ) {
                    $ListBox.Items.Clear()
                    if ( $DefaultContent -like '*<CustomTaskbarLayoutCollection*' ) {
                        $menuOptTaskbar.Checked = $true
                    }
                    else {
                        $menuOptTaskbar.Checked = $false
                    }
                    foreach ( $Line in $DefaultContent ) {
                        $ListBox.Items.Add($Line) | out-null
                    }
                    $mainForm.Text = "Start Menu (Layout) Customizer - Untitled1.xml"
                    $global:CurrentFileName = ".\Untitled1.xml"
                    $ListBox.SelectedIndex = 0
                    $global:Modified = $false
                    Hide-DesignView
                }
            }
        }
    }
    
    function Open-LayoutFile {
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
                if ( $Content -like '*<CustomTaskbarLayoutCollection*' ) {
                    $menuOptTaskbar.Checked = $true
                }
                else {
                    $menuOptTaskbar.Checked = $false
                }
                if ( $Content[0] -like '<LayoutModificationTemplate *' ) {
                    $ListBox.Items.Clear()
                    foreach ( $Line in $Content ) {
                        $ListBox.Items.Add($Line) | out-null
                    }
                    $global:CurrentFileName = $inputFileName
                    $global:Modified = $false
                    $mainForm.Text = "Start Menu (Layout) Customizer - $CurrentFileName"
                }
                else {
                    $MessageBody = "This document is an invalid Start menu XML-file.`n`nAborting operation!"
                    $MessageTitle = "Unable to open XML-file"
                    $Choice = [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,"OK","Error")
                }      
                Hide-DesignView
            }
        }
        if ( $SaveChanges -eq 'Yes' ) {
            if ( $CurrentFileName -ne '' ) {
                Out-File $CurrentFileName
                foreach ( $Line in $ListBox.Items ) {
                    Add-Content -Path $CurrentFileName -Value $Line -Encoding UTF8 -Force
                }
                $global:Modified = $false
                Open-LayoutFile
            }
            else {
                $Result = Save-As
                if ( $Result -eq 'OK' ) {
                    $global:Modified = $false
                    Open-LayoutFile
                }
            }
        }
    }
    
    function Save-LayoutFile {
        if ( $CurrentFileName -ne '' ) {
            Out-File $CurrentFileName -Encoding UTF8 -Force
            foreach ( $Line in $ListBox.Items ) {
                Add-Content -Path $CurrentFileName -Value $Line -Encoding UTF8 -Force
            }
            $global:Modified = $false
            $mainForm.Text = "Start Menu (Layout) Customizer - $CurrentFileName"
        }
        else { Save-As-NewLayoutFile }
    }
    
    function Save-As-NewLayoutFile {
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

    function About_SMLC {
        $aboutForm          = New-Object System.Windows.Forms.Form
        $aboutFormExit      = New-Object System.Windows.Forms.Button
        $aboutFormImage     = New-Object System.Windows.Forms.PictureBox
        $aboutFormNameLabel = New-Object System.Windows.Forms.Label
        $aboutFormText      = New-Object System.Windows.Forms.Label
     
        $aboutForm.AcceptButton  = $aboutFormExit
        $aboutForm.CancelButton  = $aboutFormExit
        $aboutForm.ClientSize    = "350, 115"
        $aboutForm.BackColor     = '#ffffff'
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
    $menuNew.Add_Click({New-LayoutFile})
    [void]$menuFile.DropDownItems.Add($menuNew)
    $menuOpen.Text = "Open..."
    $menuOpen.ShortcutKeys = "Ctrl+O"
    $menuOpen.Add_Click({Open-LayoutFile})
    [void]$menuFile.DropDownItems.Add($menuOpen)
    $menuSave.Text = "Save"
    $menuSave.ShortcutKeys = "Ctrl+S"
    $menuSave.Add_Click({Save-LayoutFile})
    [void]$menuFile.DropDownItems.Add($menuSave)
    $menuSaveAs.Text = "Save As..."
    $menuSaveAs.ShortcutKeys = "Shift+Ctrl+S"
    $menuSaveAs.Add_Click({Save-As-NewLayoutFile})
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
    $menuAbout.Add_Click({About_SMLC})
    [void]$menuMain.Items.Add($menuAbout)    
#endregion
#endregion

#region controls in mainForm
    $LabelType = New-Object System.Windows.Forms.Label
    $LabelType.Location = New-Object System.Drawing.Point(10,35)
    $LabelType.Text = "Type:"
    $LabelType.Autosize = $true
    $mainForm.Controls.Add($LabelType)

    $ComboType = New-Object System.Windows.Forms.ComboBox
    $ComboType.Location = New-Object System.Drawing.Point(60,32)
    $ComboType.Width = 170
    $ComboType.Enabled = $false
    $ComboType.FlatStyle = 0
    $ComboTypeItems = @('Group','Folder','Tile','LayoutModificationTemplate','LayoutOptions','DefaultLayoutOverride','StartLayoutCollection','StartLayout','DesktopApplicationTile')
    foreach ( $ComboTypeItem in $ComboTypeItems ) {
        $ComboType.Items.Add($ComboTypeItem) | out-null
    }
    $mainForm.Controls.Add($ComboType)
    
    $LblRow = New-Object System.Windows.Forms.Label
    $LblRow.Location = New-Object System.Drawing.Point(10,706)
    $LblRow.Text = "Line:"
    $LblRow.Width = 32
    $mainForm.Controls.Add($LblRow)
    
    $LblPositionRow = New-Object System.Windows.Forms.Label
    $LblPositionRow.Location = New-Object System.Drawing.Point(38,706)
    $LblPositionRow.Text = 1
    $LblPositionRow.AutoSize = $true
    $mainForm.Controls.Add($LblPositionRow)
    
    $BtnMoveUp = New-Object System.Windows.Forms.Button
    $BtnMoveUp.Add_EnabledChanged({
        if ( $this.Enabled -eq $false ) {
            $this.FlatAppearance.BorderColor = 'LightGray'
            $this.FlatAppearance.BorderSize = 1
        }
        else {
            $this.FlatAppearance.BorderColor = 'LightBlue'
            $this.FlatAppearance.BorderSize = 2
        }
    })
    $BtnMoveUp.FlatStyle = 0
    $BtnMoveUp.FlatAppearance.BorderColor = 'LightBlue'
    $BtnMoveUp.FlatAppearance.BorderSize = 2
    $BtnMoveUp.Location = New-Object System.Drawing.Point(75,702)
    $BtnMoveUp.Width = 100
    $BtnMoveUp.Text = "Move &up"
    $BtnMoveUp.Add_Click({Move-SelectedItem -Direction Up})
    $BtnMoveUp.Enabled = $false
    $mainForm.Controls.Add($BtnMoveUp)
    
    $BtnMoveDown = New-Object System.Windows.Forms.Button
    $BtnMoveDown.Add_EnabledChanged({
       if ( $this.Enabled -eq $false ) {
            $this.FlatAppearance.BorderColor = 'LightGray'
            $this.FlatAppearance.BorderSize = 1
        }
        else {
            $this.FlatAppearance.BorderColor = 'LightBlue'
            $this.FlatAppearance.BorderSize = 2
        }
    })
    $BtnMoveDown.FlatStyle = 0
    $BtnMoveDown.FlatAppearance.BorderColor = 'LightBlue'
    $BtnMoveDown.FlatAppearance.BorderSize = 2
    $BtnMoveDown.Enabled = $false
    $BtnMoveDOwn.FlatStyle = 0
    $BtnMoveDown.Location = New-Object System.Drawing.Point(180,702)
    $BtnMoveDown.Width = 100
    $BtnMoveDown.Text = "Move &down"
    $BtnMoveDown.Add_Click({Move-SelectedItem -Direction Down})
    $mainForm.Controls.Add($BtnMoveDown)
    
    $BtnInsertNewItem = New-Object System.Windows.Forms.Button
    $BtnInsertNewItem.Text = "Create &item"
    $BtnInsertNewItem.Add_EnabledChanged({
       if ( $this.Enabled -eq $false ) {
            $this.FlatAppearance.BorderColor = 'LightGray'
            $this.FlatAppearance.BorderSize = 1
        }
        else {
            $this.FlatAppearance.BorderColor = 'LightBlue'
            $this.FlatAppearance.BorderSize = 2
        }
    })
    $BtnInsertNewItem.FlatStyle = 0
    $BtnInsertNewItem.FlatAppearance.BorderColor = 'LightBlue'
    $BtnInsertNewItem.FlatAppearance.BorderSize = 2
    $BtnInsertNewItem.Enabled = $false
    $BtnInsertNewItem.FlatStyle = 0
    $BtnInsertNewItem.Width = 100
    $BtnInsertNewItem.Location = New-Object System.Drawing.Point(285,702)
    $BtnInsertNewItem.Add_Click({Insert-NewItem})
    $mainForm.Controls.Add($BtnInsertNewItem)

    $BtnRemoveItem = New-Object System.Windows.Forms.Button
    $BtnRemoveItem.Text = "&Remove"
    $BtnRemoveItem.Add_EnabledChanged({
       if ( $this.Enabled -eq $false ) {
            $this.FlatAppearance.BorderColor = 'LightGray'
            $this.FlatAppearance.BorderSize = 1
        }
        else {
            $this.FlatAppearance.BorderColor = 'LightBlue'
            $this.FlatAppearance.BorderSize = 2
        }
    })
    $BtnRemoveItem.FlatStyle = 0
    $BtnRemoveItem.FlatAppearance.BorderColor = 'LightBlue'
    $BtnRemoveItem.FlatAppearance.BorderSize = 2
    $BtnRemoveItem.Enabled = $false
    $BtnRemoveItem.FlatStyle = 0
    $BtnRemoveItem.Width = 100
    $BtnRemoveItem.Location = New-Object System.Drawing.Point(390,702)
    $BtnRemoveItem.Add_Click({Remove-Item})
    $mainForm.Controls.Add($BtnRemoveItem)
    
    $BtnRemoveAll = New-Object System.Windows.Forms.Button
    $BtnRemoveAll.Text = "Remove All"
    $BtnRemoveAll.FlatStyle = 0
    $BtnRemoveAll.FlatAppearance.BorderColor = 'LightBlue'
    $BtnRemoveAll.FlatAppearance.BorderSize = 2
    $BtnRemoveAll.Visible = $false
    $BtnRemoveAll.FlatStyle = 0
    $BtnRemoveAll.Width = 150
    $BtnRemoveAll.Location = New-Object System.Drawing.Point(495,702)
    $BtnRemoveAll.Add_Click({Remove-All})
    $mainForm.Controls.Add($BtnRemoveAll)

    $BtnTextViewApply = New-Object System.Windows.Forms.Button
    $BtnTextViewApply.Text = "Save changes"
    $BtnTextViewApply.Add_EnabledChanged({
       if ( $this.Enabled -eq $false ) {
            $this.FlatAppearance.BorderColor = 'LightGray'
            $this.FlatAppearance.BorderSize = 1
        }
        else {
            $this.FlatAppearance.BorderColor = 'LightBlue'
            $this.FlatAppearance.BorderSize = 2
        }
    })
    $BtnTextViewApply.FlatStyle = 0
    $BtnTextViewApply.FlatAppearance.BorderColor = 'LightBlue'
    $BtnTextViewApply.FlatAppearance.BorderSize = 2
    $BtnTextViewApply.Enabled = $false
    $BtnTextViewApply.Visible = $false
    $BtnTextViewApply.FlatStyle = 0
    $BtnTextViewApply.Width = 100
    $BtnTextViewApply.Location = New-Object System.Drawing.Point(1040,702)
    $BtnTextViewApply.Add_Click({ Apply-TextViewResult })
    $mainForm.Controls.Add($BtnTextViewApply)
    
    $BtnChangeView = New-Object System.Windows.Forms.Button
    $BtnChangeView.Text = "Text-&view"
    $BtnChangeView.FlatStyle = 0
    $BtnChangeView.Width = 100
    $BtnChangeView.Location = New-Object System.Drawing.Point(1150,702)
    $BtnChangeView.Add_Click({
        if ( $BtnChangeView.Text -eq 'Text-&view' ) {
            Show-DesignView
        }
        else { Hide-DesignView }
    })
    $mainForm.Controls.Add($BtnChangeView)

    $mainTxtBox = New-Object System.Windows.Forms.RichTextBox
    $mainTxtBox.Location = New-Object System.Drawing.Point(10,27)
    $mainTxtBox.WordWrap = $false
    $mainTxtBox.BorderStyle = "Fixed3D"
    $mainTxtBox.Width = 1240
    $mainTxtBox.Height = 670
    $mainTxtBox.Enabled = $false
    $mainTxtBox.Visible = $false
    $mainTxtBox.Add_TextChanged({$BtnTextViewApply.Enabled = $true})
    $mainForm.Controls.Add($mainTxtBox)

    $ListBox = New-Object System.Windows.Forms.ListBox
    $ListBox.Location = New-Object System.Drawing.Point(242,27)
    #$ListBox.HorizontalScrollbar = $true
    $ListBox.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
    $ListBox.add_DrawItem({
        param([object]$s, [System.Windows.Forms.DrawItemEventArgs]$e)
        if ( $e.Index -gt -1 ) {
            if ( $e.Index % 2 -eq 0) {
                $backcolor = [System.Drawing.Color]::WhiteSmoke
            }
            else {
                $backcolor = [System.Drawing.Color]::White
            }

            if ( $($s.items[$e.index]) -like "*<start:Group*" -or $($s.items[$e.index]) -like "*</start:Group*" ) {
                $backcolor = [System.Drawing.Color]::Honeydew
            }
            if ( $($s.items[$e.index]) -like "*<start:Folder*" -or $($s.items[$e.index]) -like "*</start:Folder*" ) {
                $backcolor = [System.Drawing.Color]::Ivory
            }
            if(($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -eq [System.Windows.Forms.DrawItemState]::Selected) {
                #$color = [System.Drawing.SystemColors]::WindowText
                $backcolor = [System.Drawing.Color]::LightBlue
                $forecolor = [System.Drawing.Color]::Black
                $textBrush = New-Object System.Drawing.SolidBrush $forecolor

            }
            else {
                $forecolor = [System.Drawing.Color]::Black
                $textBrush = New-Object System.Drawing.SolidBrush $e.ForeColor
            }
            $backgroundBrush = New-Object System.Drawing.SolidBrush $backcolor
            $e.Graphics.FillRectangle($backgroundBrush, $e.Bounds)
            $e.Graphics.DrawString($s.Items[$e.Index], $e.Font, $textBrush, $e.Bounds.Left, $e.Bounds.Top, [System.Drawing.StringFormat]::GenericDefault)
            $backgroundBrush.Dispose()
            $textBrush.Dispose()
        }
        #$e.DrawFocusRectangle()
    })
    $ListBox.BorderStyle = "Fixed3D"
    $ListBox.Width = 1010
    $ListBox.Height = 670
    $ListBox.Add_SelectedIndexChanged({Change-ListBoxRow})
    if ( $DefaultContent -ne $Null ) {
        if ( $DefaultContent -like '*<CustomTaskbarLayoutCollection*' ) {
            $menuOptTaskbar.Checked = $true
        }
        else {
            $menuOptTaskbar.Checked = $false
        }
        foreach ( $Line in $DefaultContent ) {
            $ListBox.Items.Add($Line) | out-null
        }
    }
    if ( $ListBox.Items.Count -gt 0 ) { $ListBox.SelectedIndex = 0 }
    $mainForm.Controls.Add($ListBox)
#endregion

#region Panels
    #region PanelFolder
        $PanelFolder = New-Object System.Windows.Forms.Panel
        $PanelFolder.Size = New-Object Drawing.Size @(220,630)
        $PanelFolder.Location = New-Object System.Drawing.Point(10,65)
        $mainForm.Controls.Add($PanelFolder)
    #endregion

    #region PanelGroup
        $PanelGroup = New-Object System.Windows.Forms.Panel
        $PanelGroup.Size = New-Object Drawing.Size @(220,630)
        $PanelGroup.Location = New-Object System.Drawing.Point(10,65)
        $mainForm.Controls.Add($PanelGroup)
    #endregion

    #region PanelTIle
        $PanelTile = New-Object System.Windows.Forms.Panel
        $PanelTile.Size = New-Object Drawing.Size @(220,630)
        $PanelTile.Location = New-Object System.Drawing.Point(10,65)
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
        $LblAppUserModelID = New-Object System.Windows.Forms.Label
        $LblAppUserModelID.Text = "AppUserModelID"
        $LblAppUserModelID.Width = '100'
        $LblAppUserModelID.Location = New-Object System.Drawing.Point(0,105)
        $PanelTile.Controls.Add($LblAppUserModelID)
        $ComboBoxAppUserModelID = New-Object System.Windows.Forms.ComboBox
        $ComboBoxAppUserModelID.Location = New-Object System.Drawing.Point(0,130)
        $ComboBoxAppUserModelID.DropDownHeight= 473
        $ComboBoxAppUserModelID.DropDownWidth = 1237
        $ComboBoxAppUserModelID.Width = 218
        try {
            $InitialAllXPackages = Get-AppxPackage -AllUsers
            $InitialAllXPackages += Get-AppxPackage
        }
        catch {
            try { $InitialAllXPackages = Get-AppxPackage }
            catch {}
        }
        $AllXPackages = @()
        foreach ( $app in $InitialAllXPackages ) {
            foreach ( $id in (Get-AppxPackageManifest $app).package.applications.application.id ) {
                $AllXPackages += $app.packagefamilyname + "!" + $id
            }
        }
        $AllXPackages = $AllXPackages | Select -Unique | Sort-Object
        if ( $AllXPackages.Count -gt 0 ) {
            ForEach ( $Package in $AllXPackages ) {
                $ComboBoxAppUserModelID.Items.Add($Package) | out-null
            }
        }
        $PanelTile.Controls.Add($ComboBoxAppUserModelID)
        
    #endregion

    #region PanelLayoutModificationTemplate
        $PanelLayoutModificationTemplate = New-Object System.Windows.Forms.Panel
        $PanelLayoutModificationTemplate.Size = New-Object Drawing.Size @(220,630)
        $PanelLayoutModificationTemplate.Location = New-Object System.Drawing.Point(10,65)
        $mainForm.Controls.Add($PanelLayoutModificationTemplate)
    #endregion

    #region PanelLayoutOptions
        $PanelLayoutOptions = New-Object System.Windows.Forms.Panel
        $PanelLayoutOptions.Size = New-Object Drawing.Size @(220,630)
        $PanelLayoutOptions.Location = New-Object System.Drawing.Point(10,65)
        $mainForm.Controls.Add($PanelLayoutOptions)
    #endregion

    #region PanelDefaultLayoutOverride
        $PanelDefaultLayoutOverride = New-Object System.Windows.Forms.Panel
        $PanelDefaultLayoutOverride.Size = New-Object Drawing.Size @(220,630)
        $PanelDefaultLayoutOverride.Location = New-Object System.Drawing.Point(10,65)
        $mainForm.Controls.Add($PanelDefaultLayoutOverride)
    #endregion

    #region PanelStartLayoutCollection
        $PanelStartLayoutCollection = New-Object System.Windows.Forms.Panel
        $PanelStartLayoutCollection.Size = New-Object Drawing.Size @(220,630)
        $PanelStartLayoutCollection.Location = New-Object System.Drawing.Point(10,65)
        $mainForm.Controls.Add($PanelStartLayoutCollection)
    #endregion

    #region PanelStartLayout
        $PanelStartlayout = New-Object System.Windows.Forms.Panel
        $PanelStartlayout.Size = New-Object Drawing.Size @(220,630)
        $PanelStartlayout.Location = New-Object System.Drawing.Point(10,65)
        $mainForm.Controls.Add($PanelStartlayout)
    #endregion

    #region PanelDesktopApplicationTile
        $PanelDAT = New-Object System.Windows.Forms.Panel
        $PanelDAT.Size = New-Object Drawing.Size @(220,630)
        $PanelDAT.Location = New-Object System.Drawing.Point(10,65)
        $mainForm.Controls.Add($PanelDAT)
        $LblDATTileSize = New-Object System.Windows.Forms.Label
        $LblDATTileSize.Location = New-Object System.Drawing.Point(0,5)
        $LblDATTileSize.Text = "Size"
        $LblDATTileSize.Width = '50'
        $PanelDAT.Controls.Add($LblDATTileSize)
        $ComboDATSize = New-Object System.Windows.Forms.ComboBox
        $ComboDATSize.Location = New-Object System.Drawing.Point(50,0)
        $ComboDATSize.DropDownStyle = 'DropDownList'
        $ComboDATSize.Width = 170
        $SizeItems = @('1x1','2x2','2x4','4x4')
        foreach ( $SizeItem in $SizeItems ) {
            $ComboDATSize.Items.Add($SizeItem) | out-null
        }
        $PanelDAT.Controls.Add($ComboDATSize)
        $LblDATColumn = New-Object System.Windows.Forms.Label
        $LblDATColumn.Text = "Column"
        $LblDATColumn.Width = '50'
        $LblDATColumn.Location = New-Object System.Drawing.Point(0,35)
        $PanelDAT.Controls.Add($LblDATColumn)
        $NumericDATCol = New-Object System.Windows.Forms.NumericUpDown
        $NumericDATCol.TextAlign = "Center"
        $NumericDATCol.Width = 170
        $NumericDATCol.Location = New-Object System.Drawing.Point(50,32)
        $PanelDAT.Controls.Add($NumericDATCol)
        $LblDATRow = New-Object System.Windows.Forms.Label
        $LblDATRow.Text = "Row"
        $LblDATRow.Width = '50'
        $LblDATRow.Location = New-Object System.Drawing.Point(0,70)
        $PanelDAT.Controls.Add($LblDATRow)
        $NumericDATRow = New-Object System.Windows.Forms.NumericUpDown
        $NumericDATRow.TextAlign = "Center"
        $NumericDATRow.Width = 170
        $NumericDATRow.Location = New-Object System.Drawing.Point(50,67)
        $PanelDAT.Controls.Add($NumericDATRow)
        $LblDesktopApplicationTile = New-Object System.Windows.Forms.Label
        $LblDesktopApplicationTile.Text = "DesktopApplicationLinkPath"
        $LblDesktopApplicationTile.Width = '150'
        $LblDesktopApplicationTile.Location = New-Object System.Drawing.Point(0,105)
        $PanelDAT.Controls.Add($LblDesktopApplicationTile)
        $ComboBoxDAT = New-Object System.Windows.Forms.ComboBox
        $ComboBoxDAT.Location = New-Object System.Drawing.Point(0,130)
        $ComboBoxDAT.DropDownHeight = 473
        $ComboBoxDAT.DropDownWidth = 1237
        $ComboBoxDAT.Width = 218
        $AllLinks = @()
        $AllUserLinks = $(Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\*.lnk" -Recurse).FullName
    	$AllUserLinks = $AllUserLinks.Substring($($AllUserLinks[0].IndexOf($("Roaming\"))+8))
        $AllUserLinks = $AllUserLinks | ForEach-Object {"%APPDATA%\$_"}
        $AllComputerLinks = Get-ChildItem "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\*.lnk" -Recurse
        $AllLinks += $AllUserLinks
        $AllLinks += $AllComputerLinks.FullName
        $AllLinks = $AllLinks | Sort-Object

        $AllLinks = $AllLinks.replace("C:\ProgramData", "%ALLUSERSPROFILE%")
        if ( $AllLinks.Count -gt 0 ) {
            ForEach ( $Item in $AllLinks ) {
                $ComboBoxDAT.Items.Add($Item) | out-null
            }
        }
        $PanelDAT.Controls.Add($ComboBoxDAT)

    #endregion

    #region PanelNewItem
        $PanelNewItem = New-Object System.Windows.Forms.Panel
        $PanelNewItem.Size = New-Object Drawing.Size @(220,630)
        $PanelNewItem.Location = New-Object System.Drawing.Point(10,65)
        $mainForm.Controls.Add($PanelNewItem)
    #endregion
#endregion

$mainForm.ShowDialog()