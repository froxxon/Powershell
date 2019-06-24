#region DeclarationOfVariables
    Add-Type -AssemblyName System.Windows.Forms
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
        $MessageBody  = 'There are unsaved changes to the document.`n`nDo you want to save them before closing?'
        $MessageTitle = 'Unsaved changes'
        $Choice       = [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,"YesNoCancel","Warning")
    }
    else { $Choice = 'No' }
    return $Choice
}

function Manage-Taskbarsettings {
    if ( $menuOptTaskbar.Checked -eq $true ) {
        $LBxMain.Items.Insert($($LBxMain.Items.Count -1),'    <CustomTaskbarLayoutCollection PinListPlacement="Replace">')
        $LBxMain.Items.Insert($($LBxMain.Items.Count -1),'      <defaultlayout:TaskbarLayout>')
        $LBxMain.Items.Insert($($LBxMain.Items.Count -1),'        <taskbar:TaskbarPinList>')
        $LBxMain.Items.Insert($($LBxMain.Items.Count -1),'        </taskbar:TaskbarPinList>')
        $LBxMain.Items.Insert($($LBxMain.Items.Count -1),'      </defaultlayout:TaskbarLayout>')
        $LBxMain.Items.Insert($($LBxMain.Items.Count -1),'    </CustomTaskbarLayoutCollection>')
        $LBxMain.Items[0] = "$($LBxMain.Items[0].Substring(0,$($LBxMain.Items[0].Length -1))) xmlns:taskbar=""http://schemas.microsoft.com/Start/2014/TaskbarLayout"">"
        $TxtLMTTaskbar.Visible = $true
        $LblLMTTaskbar.Visible = $true
        $global:Modified = $true
    }
    else {
        $MessageBody  = 'All parts of the custom taskbar will be removed.`n`nAre you sure?'
        $MessageTitle = 'Removing custom Taskbar'

        $Choice       = [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,'YesNo','Warning')
        If ( $Choice -eq 'Yes' ) {
            $AssocRow = $Null
            $AssocRows = 0
            foreach ( $item in $LBxMain.Items ) {
                if ( $Item.TrimStart() -like '<CustomTaskbarLayoutCollection*' ) {
                    $AssocRow = $LBxMain.Items.IndexOf($Item)
                }
            }

            $Counter = 0
            $TempRow = $AssocRow
            do {
                if ( $LBxMain.Items.Item($TempRow) -like '*</CustomTaskbarLayoutCollection*' ) { $EndFound = $true }
                else {
                    $TempRow++
                    if ( $TempRow -eq $LBxMain.Items.Count ) { $Endfound = $true }
                }
                $AssocRows++
            } until ( $Endfound -eq $true )         
        
            [int]$Temp = $LblPositionRow.Text - 1
            $LBxMain.BeginUpdate()
            $Counter = 0
            do {
                $Counter++
                try {
                    $LBxMain.Items.RemoveAt($AssocRow)
                }
                catch {}
                try {
                    $LBxMain.SelectedIndex = $Temp
                }
                catch {}
            }
            until ( $Counter -eq $AssocRows )
            $LBxMain.Items[0] = $LBxMain.Items[0].Replace(' xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"','')
            $LBxMain.EndUpdate()
            $global:Modified = $true
            $TxtLMTTaskbar.Visible = $false
            $LblLMTTaskbar.Visible = $false
        }
        Else {
            $menuOptTaskbar.Checked = $true
            $TxtLMTTaskbar.Visible = $true
            $LblLMTTaskbar.Visible = $true
        }
    }
}

function Insert-NewItem {
    if ( $LBxMain.SelectedItem.TrimStart() -like '<taskbar*' ) {
        $CBxTypeItems = @('Taskbar link')
    }
    else {
        $CBxTypeItems = @('DesktopApplicationTile','Folder','Group','Tile')
    }
    $CBxType.Items.Clear()
    foreach ( $CBxTypeItem in $CBxTypeItems ) {
        $CBxType.Items.Add($CBxTypeItem) | out-null
    }
    $CBxType.SelectedIndex = 0
    $PnlNewItem.BringToFront()
}

function Remove-Item {
    $AssocRow = $Null
    if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Folder*' ) {
        $AssocRow = $LBxMain.SelectedIndex
        do {
            if ( $LBxMain.Items.Item($AssocRow) -like '*</start:Folder*' ) { $EndFound = $true }
            else {
                $AssocRow++
                if ( $AssocRow -eq $LBxMain.Items.Count ) { $Endfound = $true }
            }
        } until ( $Endfound -eq $true ) 
        $AssocRow = $AssocRow - 1
    }
    if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Group*' ) {
        $AssocRow = $LBxMain.SelectedIndex
        do {
            if ( $LBxMain.Items.Item($AssocRow) -like '*</start:Group*' ) { $EndFound = $true }
            else {
                $AssocRow++
                if ( $AssocRow -eq $LBxMain.Items.Count ) { $Endfound = $true }
            }
        } until ( $Endfound -eq $true ) 
        $AssocRow = $AssocRow - 1
    }

    [int]$Temp = $LblPositionRow.Text - 1
    $LBxMain.BeginUpdate()
    try {
        $LBxMain.Items.RemoveAt($LBxMain.SelectedIndex)
    }
    catch {
        if ( $AssocRow -ne $Null ) {
            $LBxMain.Items.RemoveAt($AssocRow)
        }
    }
    $LBxMain.EndUpdate()
    try {
        $LBxMain.SelectedIndex = $Temp
    }
    catch {}
    $global:Modified = $true
}

function Remove-All {
    if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Folder*' ) { $RemoveAllType = 'folder' }
    if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Group*' ) { $RemoveAllType = 'group' }
    $MessageBody  = "All parts of the selected $RemoveAllType will be removed.`n`nAre you sure?"
    $MessageTitle = "Removing entire $RemoveAllType"
    $Choice       = [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,'YesNo','Warning')
    If ( $Choice -eq 'Yes' ) {
        $AssocRow = $Null
        $AssocRows = 0
        if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Folder*' ) {
            $AssocRow = $LBxMain.SelectedIndex
            do {
                if ( $LBxMain.Items.Item($AssocRow) -like '*</start:Folder*' ) { $EndFound = $true }
                else {
                    $AssocRow++
                    if ( $AssocRow -eq $LBxMain.Items.Count ) { $Endfound = $true }
                }
                $AssocRows++
            } until ( $Endfound -eq $true )
            $AssocRow = $AssocRow - 1
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Group*' ) {
            $AssocRow = $LBxMain.SelectedIndex
            do {
                if ( $LBxMain.Items.Item($AssocRow) -like '*</start:Group*' ) { $EndFound = $true }
                else {
                    $AssocRow++
                    if ( $AssocRow -eq $LBxMain.Items.Count ) { $Endfound = $true }
                }
                $AssocRows++
            } until ( $Endfound -eq $true )         
            $AssocRow = $AssocRow - 1
        }

        [int]$Temp = $LblPositionRow.Text - 1
        $LBxMain.BeginUpdate()
        $Counter = 0
        do {
            $Counter++
            try {
                $LBxMain.Items.RemoveAt($LBxMain.SelectedIndex)
            }
            catch {}
            try {
                $LBxMain.SelectedIndex = $Temp
            }
            catch {}
        }
        until ( $Counter -eq $AssocRows )
        $LBxMain.EndUpdate()
        $global:Modified = $true
    }
}

function Move-SelectedItem ([string]$Direction) {
    $LBxMain.BeginUpdate()
    $pos = $LBxMain.SelectedIndex
    if ( $Direction -eq 'Up' ) {
        $LBxMain.items.insert($pos -1,$LBxMain.Items.Item($pos))
        $LBxMain.SelectedIndex = ($pos -1)
        $LBxMain.Items.RemoveAt($pos +1)
    }
    else {
        $LBxMain.items.insert($pos,$LBxMain.Items.Item($pos +1))
        $LBxMain.SelectedIndex = ($pos +1)
        $LBxMain.Items.RemoveAt($pos +2)
    }
    $LBxMain.EndUpdate()
    Change-ListBoxRow
    $global:Modified = $true
}

function Change-ListBoxRow {
    $SelectionTabExist = $false
    if ( $LBxMain.SelectedItem ) {
        if ( $LBxMain.SelectedItem.TrimStart() -like '<LayoutModificationTemplate*' ) {
            If ( $PnlLayoutModificationTemplate ) {
                $PnlLayoutModificationTemplate.BringToFront()
                $SelectedItem = $LBxMain.SelectedItem.Split('"')
                $Counter = 0
                foreach ( $Item in $SelectedItem ) {
                    if ( $Item -like '*xmlns:defaultlayout=*' ) { $TxtLMTDefaultLayout.Text = $SelectedItem[$Counter +1] }
                    if ( $Item -like '*xmlns:start=*' ) { $TxtLMTStart.Text = $SelectedItem[$Counter +1] }
                    if ( $Item -like '*xmlns=*' ) { $TxtLMTxlmns.Text = $SelectedItem[$Counter +1] }
                    if ( $Item -like '*xmlns:taskbar=*' ) { $TxtLMTTaskbar.Text = $SelectedItem[$Counter +1] }
                    if ( $Item -like '*version=*' ) { $TxtLMTVersion.Text = $SelectedItem[$Counter +1] }
                    $Counter++
                }
            }
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<LayoutOptions*' ) {
            $PnlLayoutOptions.BringToFront()
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<DefaultLayoutOverride*' ) {
            $PnlDefaultLayoutOverride.BringToFront()
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<StartLayoutCollection*' ) {
            $PnlStartLayoutCollection.BringToFront()
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<defaultlayout:StartLayout*' ) {
            $PnlStartlayout.BringToFront()
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Group*' ) {
            $PnlGroup.BringToFront()
            $SelectedItem = $LBxMain.SelectedItem.Split('"')
            $Counter = 0
            foreach ( $Item in $SelectedItem ) {
                if ( $Item -like '*Name=*' ) { $TxtGroupName.Text = $SelectedItem[$Counter +1] }
                $Counter++
            }
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Folder*' ) {
            $PnlFolder.BringToFront()
            $SelectedItem = $LBxMain.SelectedItem.Split('"')
            $Counter = 0
            foreach ( $Item in $SelectedItem ) {
                if ( $Item -like '*Size=*' ) { $CBxFolderSize.SelectedItem = $SelectedItem[$Counter +1] }
                if ( $Item -like '*Row=*' ) { $NumFolderRow.Text = $SelectedItem[$Counter +1] }
                if ( $Item -like '*Column=*' ) { $NumFolderCol.Text = $SelectedItem[$Counter +1] }
                if ( $Item -like '*Name=*' ) { $TxtFolderName.Text = $SelectedItem[$Counter +1] }
                $Counter++
            }
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Tile*' ) {
            $PnlTile.BringToFront()
            $SelectedItem = $LBxMain.SelectedItem.Split('"')
            $Counter = 0
            foreach ( $Item in $SelectedItem ) {
                if ( $Item -like '*Size=*' ) { $CBxTileSize.SelectedItem = $SelectedItem[$Counter +1] }
                if ( $Item -like '*Row=*' ) { $NumTileRow.Text = $SelectedItem[$Counter +1] }
                if ( $Item -like '*Column=*' ) { $NumTileCol.Text = $SelectedItem[$Counter +1] }
                if ( $Item -like '*AppUserModelID=*' ) {
                    if ( $CBxBoxAppUserModelID.Items -contains $SelectedItem[$Counter +1] ) {
                        $CBxBoxAppUserModelID.SelectedItem = $SelectedItem[$Counter +1]
                    }
                        else { $CBxBoxAppUserModelID.Text = $SelectedItem[$Counter +1]
                    }
                }
                $Counter++
            }
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<start:DesktopApplicationTile*' ) {
            $PnlDAT.BringToFront()
            $SelectedItem = $LBxMain.SelectedItem.Split('"')
            $Counter = 0
            foreach ( $Item in $SelectedItem ) {
                if ( $Item -like '*Size=*' ) { $CBxDATSize.SelectedItem = $SelectedItem[$Counter +1] }
                if ( $Item -like '*Row=*' ) { $NumDATRow.Text = $SelectedItem[$Counter +1] }
                if ( $Item -like '*Column=*' ) { $NumDATCol.Text = $SelectedItem[$Counter +1] }
                if ( $Item -like '*DesktopApplicationLinkPath=*' ) {
                    if ( $CBxBoxDAT.Items -contains $SelectedItem[$Counter +1] ) {
                        $CBxBoxDAT.SelectedItem = $SelectedItem[$Counter +1]
                    }
                        else { $CBxBoxDAT.Text = $SelectedItem[$Counter +1]
                    }
                }
                $Counter++
            }
            $SelectionTabExist = $true
        }
        $LblPositionRow.Text = "$($LBxMain.SelectedIndex + 1)"

        if ( $SelectionTabExist -eq $false ) {
            $PnlEmpty.BringToFront()
        }

        if ( $LBxMain.SelectedItem.TrimStart() -like '<start:*' -or $LBxMain.SelectedItem.TrimStart() -like '</start:*' -or $LBxMain.SelectedItem.TrimStart() -like '<defaultlayout:Start*' -or $LBxMain.SelectedItem.TrimStart() -like '<taskbar:*' ) {
            $BtnMoveUp.Enabled = $true
            $BtnMoveDown.Enabled = $true
            $BtnRemoveItem.Enabled = $true
            $BtnInsertNewItem.Enabled = $true
            if ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1)  -like '*<defaultlayout:Start*' -or $LBxMain.Items.Item($LBxMain.SelectedIndex-1)  -like '*<taskbar:taskBarPinList*' ) { $BtnMoveUp.Enabled = $false }
            else { $BtnMoveUp.Enabled = $true }
            if ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*</defaultlayout:Start*' -or $LBxMain.Items.Item($LBxMain.SelectedIndex+1)  -like '*</taskbar:*' ) { $BtnMoveDown.Enabled = $false }
            else { $BtnMoveDown.Enabled = $true }
            if ( $LBxMain.SelectedItem.TrimStart() -like '</start:Folder*' ) {
                $BtnRemoveItem.Enabled = $false
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1) -like '*<start:Folder*' ) { $BtnMoveUp.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*<start:Folder*' ) { $BtnMoveDown.Enabled = $false }
            }
            if ( $LBxMain.SelectedItem.TrimStart() -like '</start:Group*' ) {
                $BtnRemoveItem.Enabled = $false
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1) -like '*<start:Group*' ) { $BtnMoveUp.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*<start:Group*' ) { $BtnMoveDown.Enabled = $false }
            }
            if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Folder*' ) {
                $BtnRemoveItem.Enabled = $false
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1) -like '*</start:Folder*' ) { $BtnMoveUp.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*</start:Folder*' ) { $BtnMoveDown.Enabled = $false }
            }
            if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Group*' ) {
                $BtnRemoveItem.Enabled = $false
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1) -like '*</start:Group*' ) { $BtnMoveUp.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*</start:Group*' ) { $BtnMoveDown.Enabled = $false }
            }
            if ( $LBxMain.SelectedItem.TrimStart() -like '<defaultlayout:*' -or $LBxMain.SelectedItem.TrimStart() -like '<taskbar:TaskbarPinList*') {
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

        if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Folder*' -or $LBxMain.SelectedItem.TrimStart() -like '<start:Group*' ) {
            $BtnRemoveAll.Visible = $true
            if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Folder*' ) {
                $BtnRemoveAll.Text = 'Remove &entire Folder'
            }
            else {
                $BtnRemoveAll.Text = 'Remove &entire Group'
            }
        }
        else {
            $BtnRemoveAll.Visible = $false
        }
    }
}

function Show-DesignView {
    $BtnChangeView.Text = '&Cancel'
    $LBxMain.Visible = $false
    $LBxMain.Enabled = $false
    $TxtMain.Visible = $true
    $TxtMain.Enabled = $true
    $menuOptTaskbar.Enabled = $false
    $CBxType.Visible = $false
    $BtnTextViewApply.Visible = $true
    $TxtMain.BringToFront()
    $TxtMain.Clear()
    $PnlButtons.Visible = $false
    foreach ( $item in $LBxMain.Items ) {
        $TxtMain.Text += "$Item`n"
    }
    $BtnTextViewApply.Enabled = $false
    $TxtMain.Focus()
}

function Hide-DesignView {
    $BtnChangeView.Text = 'Text-&view'
    $BtnTextViewApply.Visible = $false
    $LBxMain.Visible = $true
    $LBxMain.Enabled = $true
    $TxtMain.Visible = $false
    $TxtMain.Enabled = $false
    $menuOptTaskbar.Enabled = $true
    $PnlButtons.Visible = $true
    $LBxMain.SelectedIndex = 0
}

function Apply-TextViewResult {
            $LBxMain.Items.Clear()
            if ( $TxtMain.Text -contains '<CustomTaskbarLayoutCollection' ) {
                $menuOptTaskbar.Checked = $true
            }
            else {
                $menuOptTaskbar.Checked = $false
            }

            foreach ( $Line in $TxtMain.Text.Split("`n") ) {
                if ( $Line -ne '' ) {
                    $LBxMain.Items.Add($Line.TrimEnd()) | out-null
                }
            }
            Hide-DesignView
}

#region mainForm
    $FrmMain = New-Object system.Windows.Forms.Form -Property @{
        Text            = 'Start Menu (Layout) Customizer - Untitled1.xml'
        Font            = 'MS Sans Serif,10,style=Regular'
        FormBorderStyle = 'Fixed3D'
        BackColor       = '#ffffff'
        MaximizeBox     = $false
        Icon            = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHOME + '\powershell_ise.exe')
        StartPosition   = 'CenterScreen'
        Size            = New-Object System.Drawing.Size(1280,768)
    }
    $FrmMain.add_FormClosing({
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
    if ( $(Test-Path variable:global:psISE) -eq $False ) {
        $FrmMain.Size = New-Object System.Drawing.Size(1290,778)
    }
#endregion

#region Menu
    function New-LayoutFile {
        $SaveChanges = Verify-CloseUnsavedChanges
        if ( $SaveChanges -eq 'No' ) {
            $LBxMain.Items.Clear()
            if ( $DefaultContent -like '*<CustomTaskbarLayoutCollection*' ) {
                $menuOptTaskbar.Checked = $true
            }
            else {
                $menuOptTaskbar.Checked = $false
            }
            foreach ( $Line in $DefaultContent ) {
                $LBxMain.Items.Add($Line) | out-null
            }
            $FrmMain.Text = 'Start Menu (Layout) Customizer - Untitled1.xml'
            $global:CurrentFileName = ''
            $LBxMain.SelectedIndex = 0
            $global:Modified = $false
            Hide-DesignView
        }
        if ( $SaveChanges -eq 'Yes' ) {
            if ( $CurrentFileName -ne '' ) {
                Out-File $CurrentFileName
                foreach ( $Line in $LBxMain.Items ) {
                    Add-Content -Path $CurrentFileName -Value $Line -Encoding UTF8 -Force
                }
                $LBxMain.Items.Clear()
                foreach ( $Line in $DefaultContent ) {
                    $LBxMain.Items.Add($Line) | out-null
                }
                $FrmMain.Text = 'Start Menu (Layout) Customizer - Untitled1.xml'
                $global:CurrentFileName = '.\Untitled1.xml'
                $LBxMain.SelectedIndex = 0
                $global:Modified = $false
                Hide-DesignView
            }
            else {
                $Result = Save-As
                if ( $Result -eq 'OK' ) {
                    $LBxMain.Items.Clear()
                    if ( $DefaultContent -like '*<CustomTaskbarLayoutCollection*' ) {
                        $menuOptTaskbar.Checked = $true
                    }
                    else {
                        $menuOptTaskbar.Checked = $false
                    }
                    foreach ( $Line in $DefaultContent ) {
                        $LBxMain.Items.Add($Line) | out-null
                    }
                    $FrmMain.Text = 'Start Menu (Layout) Customizer - Untitled1.xml'
                    $global:CurrentFileName = '.\Untitled1.xml'
                    $LBxMain.SelectedIndex = 0
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
            $selectOpenForm = New-Object System.Windows.Forms.OpenFileDialog -Property @{
                Filter           = "XML-files (*.xml)|*.xml"
                InitialDirectory = ".\"
                Title            = "Select a File to Open"
            }
            $Result = $selectOpenForm.ShowDialog()
            if ( $Result -eq 'OK' ) {
                $inputFileName = $selectOpenForm.FileName
                $Content = Get-Content $inputFileName -Encoding UTF8
                if ( $Content -like '*<CustomTaskbarLayoutCollection*' ) {
                    $menuOptTaskbar.Checked = $true
                }
                else {
                    $menuOptTaskbar.Checked = $false
                }
                if ( $Content[0] -like '<LayoutModificationTemplate *' ) {
                    $LBxMain.Items.Clear()
                    foreach ( $Line in $Content ) {
                        $LBxMain.Items.Add($Line) | out-null
                    }
                    $global:CurrentFileName = $inputFileName
                    $global:Modified = $false
                    $FrmMain.Text = "Start Menu (Layout) Customizer - $CurrentFileName"
                }
                else {
                    $MessageBody  = 'This document is an invalid Start menu XML-file.`n`nAborting operation!'
                    $MessageTitle = 'Unable to open XML-file'
                    $Choice       = [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,'OK','Error')
                }      
                Hide-DesignView
            }
        }
        if ( $SaveChanges -eq 'Yes' ) {
            if ( $CurrentFileName -ne '' ) {
                Out-File $CurrentFileName
                foreach ( $Line in $LBxMain.Items ) {
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
            foreach ( $Line in $LBxMain.Items ) {
                Add-Content -Path $CurrentFileName -Value $Line -Encoding UTF8 -Force
            }
            $global:Modified = $false
            $FrmMain.Text = "Start Menu (Layout) Customizer - $CurrentFileName"
        }
        else { Save-As-NewLayoutFile }
    }
    
    function Save-As-NewLayoutFile {
        $outputFileName = $Null
        $selectSaveAsForm = New-Object System.Windows.Forms.SaveFileDialog -Property @{
            Filter           = 'XML-file (*.xml)|*.xml'
            InitialDirectory = '.\'
            Title            = 'Select a File to Save'
        }
        $Result = $selectSaveAsForm.ShowDialog()
        if ( $Result -eq 'OK' ) {
            $outputFileName = $selectSaveAsForm.FileName
            if ( $outputFileName -ne $Null ) {
                Out-File $outputFileName
                foreach ( $Line in $LBxMain.Items ) {
                    Add-Content -Path $outputFileName -Value $Line -Encoding UTF8 -Force
                }
                $global:CurrentFileName = $outputFileName
                $global:Modified = $false
                $FrmMain.Text = "Start Menu (Layout) Customizer - $CurrentFileName"
            }
        }
        return $Result
    }

    function About_SMLC {
        $aboutForm          = New-Object System.Windows.Forms.Form -Property @{
            AcceptButton    = $aboutFormExit
            CancelButton    = $aboutFormExit
            ClientSize      = '350, 115'
            BackColor       = '#ffffff'
            ControlBox      = $false
            FormBorderStyle = 'Fixed3D'
            ShowInTaskBar   = $false
            StartPosition   = 'CenterParent'
            Text            = 'StartMenuCustomizer.ps1'
        }
        $aboutForm.Add_Load($aboutForm_Load)

        $aboutFormNameLabel = New-Object System.Windows.Forms.Label -Property @{    
            Font     = New-Object Drawing.Font('Microsoft Sans Serif', 9, [System.Drawing.FontStyle]::Bold)
            Location = '80, 20'
            Size     = '200, 18'
            Text     = 'Start Menu (Layout) Customizer'
        }
        $aboutForm.Controls.Add($aboutFormNameLabel)
     
        $aboutFormText      = New-Object System.Windows.Forms.Label -Property @{
            Location = '100, 40'
            Size     = '300, 30'
            Text     = '          Fredrik Bergman `n`r www.onpremproblems.com'
        }
        $aboutForm.Controls.Add($aboutFormText)
     
        $aboutFormExit      = New-Object System.Windows.Forms.Button -Property @{
            Location = '135, 75'
            Text     = 'OK'
        }
        $aboutForm.Controls.Add($aboutFormExit)
     
        [void]$aboutForm.ShowDialog()
    }

#region Menuitems
    $menuMain = New-Object System.Windows.Forms.MenuStrip
    $menuMain.ResetBackColor()
    [void]$FrmMain.Controls.Add($menuMain)

    $menuFile = New-Object System.Windows.Forms.ToolStripMenuItem -Property @{
        Text = 'File'
    }
    [void]$menuMain.Items.Add($menuFile)

    $menuNew = New-Object System.Windows.Forms.ToolStripMenuItem -Property @{
        Text         = 'New'
        ShortcutKeys = 'Ctrl+N'
    }
    $menuNew.Add_Click({New-LayoutFile})
    [void]$menuFile.DropDownItems.Add($menuNew)

    $menuOpen = New-Object System.Windows.Forms.ToolStripMenuItem -Property @{
        Text         = 'Open...'
        ShortcutKeys = 'Ctrl+O'
    }
    $menuOpen.Add_Click({Open-LayoutFile})
    [void]$menuFile.DropDownItems.Add($menuOpen)

    $menuSave = New-Object System.Windows.Forms.ToolStripMenuItem -Property @{
        Text         = 'Save'
        ShortcutKeys = 'Ctrl+S'
    }
    $menuSave.Add_Click({Save-LayoutFile})
    [void]$menuFile.DropDownItems.Add($menuSave)

    $menuSaveAs = New-Object System.Windows.Forms.ToolStripMenuItem -Property @{
        Text         = 'Save As...'
        ShortcutKeys = 'Shift+Ctrl+S'
    }
    $menuSaveAs.Add_Click({Save-As-NewLayoutFile})
    [void]$menuFile.DropDownItems.Add($menuSaveAs)

    $menuOptions = New-Object System.Windows.Forms.ToolStripMenuItem -Property @{
        Text = 'Options'
    }
    [void]$menuMain.Items.Add($menuOptions)
    
    $menuOptTaskbar = New-Object System.Windows.Forms.ToolStripMenuItem -Property @{
        Text         = 'Include taskbar'
        CheckOnClick = $true
    }
    $menuOptTaskbar.Add_Click({Manage-Taskbarsettings})
    [void]$menuOptions.DropDownItems.Add($menuOptTaskbar)
        
    $menuAbout = New-Object System.Windows.Forms.ToolStripMenuItem -Property @{
        Text = 'About'
    }
    $menuAbout.Add_Click({About_SMLC})
    [void]$menuMain.Items.Add($menuAbout)    
#endregion
#endregion

#region controls in mainForm
    #region ButtonPanel
        $PnlButtons = New-Object System.Windows.Forms.Panel -Property @{
            BorderStyle = 0
            Size     = New-Object Drawing.Size @(1000,35)
            Location = New-Object System.Drawing.Point(0,703)
        }
        $FrmMain.Controls.Add($PnlButtons)
    #endregion
 
    $LblRow = New-Object System.Windows.Forms.Label -Property @{
        Location = New-Object System.Drawing.Point(10,3)
        Text = 'Line:'
        Width = 35
    }
    $PnlButtons.Controls.Add($LblRow)
    
    $LblPositionRow = New-Object System.Windows.Forms.Label -Property @{
        Location = New-Object System.Drawing.Point(45,3)
        Text = 1
        AutoSize = $true
    }
    $PnlButtons.Controls.Add($LblPositionRow)
    
    $BtnMoveUp = New-Object System.Windows.Forms.Button -Property @{
        FlatStyle = 0
        Location  = New-Object System.Drawing.Point(75,0)
        Width     = 100
        Text      = 'Move &up'
    }
    $BtnMoveUp.FlatAppearance.BorderColor = 'LightBlue'
    $BtnMoveUp.FlatAppearance.BorderSize = 2
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
    $BtnMoveUp.Enabled = $false
    $BtnMoveUp.Add_Click({Move-SelectedItem -Direction Up})
    $PnlButtons.Controls.Add($BtnMoveUp)
    
    $BtnMoveDown = New-Object System.Windows.Forms.Button -Property @{
        FlatStyle = 0
        Location  = New-Object System.Drawing.Point(180,0)
        Width     = 100
        Text      = 'Move &down'
    }
    $BtnMoveDown.FlatAppearance.BorderColor = 'LightBlue'
    $BtnMoveDown.FlatAppearance.BorderSize = 2
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
    $BtnMoveDown.Enabled = $false
    $BtnMoveDown.Add_Click({Move-SelectedItem -Direction Down})
    $PnlButtons.Controls.Add($BtnMoveDown)
    
    $BtnInsertNewItem = New-Object System.Windows.Forms.Button -Property @{
        Text = 'Create &item'
        FlatStyle = 0
        Width = 100
        Location = New-Object System.Drawing.Point(285,0)
    }
    $BtnInsertNewItem.FlatAppearance.BorderColor = 'LightBlue'
    $BtnInsertNewItem.FlatAppearance.BorderSize = 2
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
    $BtnInsertNewItem.Enabled = $false
    $BtnInsertNewItem.Add_Click({Insert-NewItem})
    $PnlButtons.Controls.Add($BtnInsertNewItem)

    $BtnRemoveItem = New-Object System.Windows.Forms.Button -Property @{
        Text = '&Remove'
        FlatStyle = 0
        Width = 100
        Location = New-Object System.Drawing.Point(390,0)
    }
    $BtnRemoveItem.FlatAppearance.BorderColor = 'LightBlue'
    $BtnRemoveItem.FlatAppearance.BorderSize = 2
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
    $BtnRemoveItem.Enabled = $false
    $BtnRemoveItem.Add_Click({Remove-Item})
    $PnlButtons.Controls.Add($BtnRemoveItem)
    
    $BtnRemoveAll = New-Object System.Windows.Forms.Button -Property @{
        Text      = 'Remove All'
        FlatStyle = 0
        Visible   = $false
        Width     = 150
        Location  = New-Object System.Drawing.Point(495,0)
    }
    $BtnRemoveAll.FlatAppearance.BorderColor = 'LightBlue'
    $BtnRemoveAll.FlatAppearance.BorderSize = 2
    $BtnRemoveAll.Add_Click({Remove-All})
    $PnlButtons.Controls.Add($BtnRemoveAll)

    $BtnTextViewApply = New-Object System.Windows.Forms.Button -Property @{
        Text      = 'Save changes'
        FlatStyle = 0
        Enabled   = $false
        Visible   = $false
        Width     = 100
        Location  = New-Object System.Drawing.Point(1040,702)
    }
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
    $BtnTextViewApply.FlatAppearance.BorderColor = 'LightBlue'
    $BtnTextViewApply.FlatAppearance.BorderSize = 2
    $BtnTextViewApply.Add_Click({ Apply-TextViewResult })
    $FrmMain.Controls.Add($BtnTextViewApply)
    
    $BtnChangeView = New-Object System.Windows.Forms.Button -Property @{
        Text      = 'Text-&view'
        FlatStyle = 0
        Width     = 100
        Location  = New-Object System.Drawing.Point(1150,702)
    }
    $BtnChangeView.Add_Click({
        if ( $BtnChangeView.Text -eq 'Text-&view' ) {
            Show-DesignView
        }
        else { Hide-DesignView }
    })
    $FrmMain.Controls.Add($BtnChangeView)

    $TxtMain = New-Object System.Windows.Forms.RichTextBox -Property @{
        Location    = New-Object System.Drawing.Point(0,27)
        WordWrap    = $false
        BorderStyle = 'None'
        Width       = $FrmMain.Width - 10
        Height      = 670
        Enabled     = $false
        Visible     = $false
    }
    $TxtMain.Add_TextChanged({$BtnTextViewApply.Enabled = $true})
    $FrmMain.Controls.Add($TxtMain)

    $LbxMain = New-Object System.Windows.Forms.ListBox -Property @{
        Location    = New-Object System.Drawing.Point(242,27)
        DrawMode    = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
        BorderStyle = 'Fixed3D'
        Width       = 1010
        Height      = 670
    }
    $LBxMain.HorizontalScrollbar = $true
    $LBxMain.HorizontalExtent = 2250
    $LBxMain.add_DrawItem({
        param([object]$s, [System.Windows.Forms.DrawItemEventArgs]$e)
        if ( $e.Index -gt -1 ) {
            if ( $e.Index % 2 -eq 0) {
                $backcolor = [System.Drawing.Color]::WhiteSmoke
            }
            else {
                $backcolor = [System.Drawing.Color]::White
            }

            if ( $($s.items[$e.index]) -like '*<start:Group*' -or $($s.items[$e.index]) -like '*</start:Group*' ) {
                $backcolor = [System.Drawing.Color]::Honeydew
            }
            if ( $($s.items[$e.index]) -like '*<start:Folder*' -or $($s.items[$e.index]) -like '*</start:Folder*' ) {
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
    $LBxMain.Add_SelectedIndexChanged({Change-ListBoxRow})
    if ( $DefaultContent -ne $Null ) {
        if ( $DefaultContent -like '*<CustomTaskbarLayoutCollection*' ) {
            $menuOptTaskbar.Checked = $true
        }
        else {
            $menuOptTaskbar.Checked = $false
        }
        foreach ( $Line in $DefaultContent ) {
            $LBxMain.Items.Add($Line) | out-null
        }
    }
    if ( $LBxMain.Items.Count -gt 0 ) { $LBxMain.SelectedIndex = 0 }
    $FrmMain.Controls.Add($LbxMain)
#endregion

#region Panels
    #region PanelLayoutModificationTemplate
        $PnlLayoutModificationTemplate = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlLayoutModificationTemplate)

        $YAxis = 10
        $LblTypeLMT = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Type: LayoutModificationTemplate'
            AutoSize = $true
        }
        $PnlLayoutModificationTemplate.Controls.Add($LblTypeLMT)

        $YAxis = $YAxis + 30
        $LblLMTDefaultLayout = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'xmlns:defaultlayout'
            Autosize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlLayoutModificationTemplate.Controls.Add($LblLMTDefaultLayout)
        
        $YAxis = $YAxis + 20
        $TxtLMTDefaultLayout = New-Object System.Windows.Forms.TextBox -Property @{
            BackColor   = 'White'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlLayoutModificationTemplate.Controls.Add($TxtLMTDefaultLayout)

        $YAxis = $YAxis + 30
        $LblLMTStart = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'xmlns:start'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlLayoutModificationTemplate.Controls.Add($LblLMTStart)

        $YAxis = $YAxis + 20
        $TxtLMTStart = New-Object System.Windows.Forms.TextBox -Property @{
            BackColor   = 'White'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlLayoutModificationTemplate.Controls.Add($TxtLMTStart)

        $YAxis = $YAxis + 30
        $LblLMTxmlns = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'xmlns'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlLayoutModificationTemplate.Controls.Add($LblLMTxmlns)

        $YAxis = $YAxis + 20
        $TxtLMTxlmns = New-Object System.Windows.Forms.TextBox -Property @{
            BackColor   = 'White'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlLayoutModificationTemplate.Controls.Add($TxtLMTxlmns)

        $YAxis = $YAxis + 30
        $LblLMTVersion = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'Version'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlLayoutModificationTemplate.Controls.Add($LblLMTVersion)

        $YAxis = $YAxis + 20
        $TxtLMTVersion = New-Object System.Windows.Forms.TextBox -Property @{
            BackColor   = 'White'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlLayoutModificationTemplate.Controls.Add($TxtLMTVersion)

        $YAxis = $YAxis + 30
        $LblLMTTaskbar = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'xmlns:taskbar'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlLayoutModificationTemplate.Controls.Add($LblLMTTaskbar)

        $YAxis = $YAxis + 20
        $TxtLMTTaskbar = New-Object System.Windows.Forms.TextBox -Property @{
            BackColor   = 'White'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlLayoutModificationTemplate.Controls.Add($TxtLMTTaskbar)

        if ( $menuOptTaskbar.Checked -eq $true ) {
            $LblLMTTaskbar.Visible = $true
            $TxtLMTTaskbar.Visible = $true
        }
        else {
            $LblLMTTaskbar.Visible = $false
            $TxtLMTTaskbar.Visible = $false
        }
        Change-ListBoxRow
    #endregion

    #region PanelLayoutOptions
        $PnlLayoutOptions = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlLayoutOptions)

        $LblTypeLayoutOptions = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,5)
            Text     = 'Type: LayoutOptions'
            AutoSize = $true
        }
        $PnlLayoutOptions.Controls.Add($LblTypeLayoutOptions)
    #endregion

    #region PanelDefaultLayoutOverride
        $PnlDefaultLayoutOverride = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlDefaultLayoutOverride)

        $LblTypeDefaultLayoutOverride = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,5)
            Text     = 'Type: DefaultLayoutOverride'
            AutoSize = $true
        }
        $PnlDefaultLayoutOverride.Controls.Add($LblTypeDefaultLayoutOverride)
    #endregion

    #region PanelStartLayoutCollection
        $PnlStartLayoutCollection = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlStartLayoutCollection)

        $LblTypeStartLayoutCollection = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,5)
            Text     = 'Type: StartLayoutCollection'
            AutoSize = $true
        }
        $PnlStartLayoutCollection.Controls.Add($LblTypeStartLayoutCollection)
    #endregion

    #region PanelStartLayout
        $PnlStartlayout = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlStartlayout)

        $LblTypeStartLayout = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,5)
            Text     = 'Type: StartLayout'
            AutoSize = $true
        }
        $PnlStartlayout.Controls.Add($LblTypeStartLayout)
    #endregion

    #region PanelFolder
        $PnlFolder = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlFolder)

        $YAxis = 10
        $LblTypeFolder = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,5)
            Text     = 'Type: Folder'
            AutoSize = $true
        }
        $PnlFolder.Controls.Add($LblTypeFolder)

        $YAxis = $YAxis + 30
        $LblFolderSize = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Size'
            AutoSize = $true
        }
        $PnlFolder.Controls.Add($LblFolderSize)

        $YAxis = $YAxis + 20
        $CBxFolderSize = New-Object System.Windows.Forms.ComboBox -Property @{
            Location      = New-Object System.Drawing.Point(0,$YAxis)
            DropDownStyle = 'DropDownList'
            Width         = 220
        }
        $SizeItems = @('1x1','2x2','2x4','4x4')
        foreach ( $SizeItem in $SizeItems ) {
            $CBxFolderSize.Items.Add($SizeItem) | out-null
        }
        $PnlFolder.Controls.Add($CBxFolderSize)

        $YAxis = $YAxis + 30
        $LblFolderColumn = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'Column'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlFolder.Controls.Add($LblFolderColumn)
        
        $YAxis = $YAxis + 20
        $NumFolderCol = New-Object System.Windows.Forms.NumericUpDown -Property @{
            BackColor   = 'White'
            Maximum     = 5
            ReadOnly    = $true        
            TextAlign   = "Center"
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlFolder.Controls.Add($NumFolderCol)

        $YAxis = $YAxis + 30
        $LblFolderRow = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'Row'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlFolder.Controls.Add($LblFolderRow)

        $YAxis = $YAxis + 20
        $NumFolderRow = New-Object System.Windows.Forms.NumericUpDown -Property @{
            BackColor   = 'White'
            Maximum     = 20
            ReadOnly    = $true
            TextAlign   = 'Center'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlFolder.Controls.Add($NumFolderRow)

        $YAxis = $YAxis + 30
        $LblFolderName = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'Name'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlFolder.Controls.Add($LblFolderName)

        $YAxis = $YAxis + 20
        $TxtFolderName = New-Object System.Windows.Forms.TextBox -Property @{
            BackColor   = 'White'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlFolder.Controls.Add($TxtFolderName)
    #endregion

    #region PanelGroup
        $PnlGroup = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlGroup)

        $YAxis = 10
        $LblTypeGroup = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,5)
            Text     = 'Type: Group'
            AutoSize = $true
        }
        $PnlGroup.Controls.Add($LblTypeGroup)

        $YAxis = $YAxis + 30
        $LblGroupName = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'Name'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlGroup.Controls.Add($LblGroupName)

        $YAxis = $YAxis + 20
        $TxtGroupName = New-Object System.Windows.Forms.TextBox -Property @{
            BackColor   = 'White'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlGroup.Controls.Add($TxtGroupName)
    #endregion

    #region PanelTIle
        $PnlTile = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlTIle)

        $YAxis = 10
        $LblTypeTile = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Type: Tile'
            AutoSize = $true
        }
        $PnlTIle.Controls.Add($LblTypeTile)
        
        $YAxis = $YAxis + 30
        $LblTileSize = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Size'
            AutoSize = $true
        }
        $PnlTile.Controls.Add($LblTileSize)

        $YAxis = $YAxis + 20
        $CBxTileSize = New-Object System.Windows.Forms.ComboBox -Property @{
            Location      = New-Object System.Drawing.Point(0,$YAxis)
            DropDownStyle = 'DropDownList'
            Width         = 220
        }
        $SizeItems = @('1x1','2x2','2x4','4x4')
        foreach ( $SizeItem in $SizeItems ) {
            $CBxTileSize.Items.Add($SizeItem) | out-null
        }
        $PnlTile.Controls.Add($CBxTileSize)

        $YAxis = $YAxis + 30
        $LblTileColumn = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'Column'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlTile.Controls.Add($LblTileColumn)
        
        $YAxis = $YAxis + 20
        $NumTileCol = New-Object System.Windows.Forms.NumericUpDown -Property @{
            BackColor   = 'White'
            Maximum     = 5
            ReadOnly    = $true        
            TextAlign   = "Center"
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlTile.Controls.Add($NumTileCol)

        $YAxis = $YAxis + 30
        $LblTileRow = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'Row'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlTile.Controls.Add($LblTileRow)

        $YAxis = $YAxis + 20
        $NumTileRow = New-Object System.Windows.Forms.NumericUpDown -Property @{
            BackColor   = 'White'
            Maximum     = 20
            ReadOnly    = $true
            TextAlign   = 'Center'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlTile.Controls.Add($NumTileRow)

        $YAxis = $YAxis + 30
        $LblAppUserModelID = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'AppUserModelID'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlTile.Controls.Add($LblAppUserModelID)

        $YAxis = $YAxis + 20
        $CBxBoxAppUserModelID = New-Object System.Windows.Forms.ComboBox -Property @{
            Location       = New-Object System.Drawing.Point(0,$YAxis)
            DropDownHeight = 473
            DropDownWidth  = 1237            
            Width          = 220
        }
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
                $CBxBoxAppUserModelID.Items.Add($Package) | out-null
            }
        }
        $PnlTile.Controls.Add($CBxBoxAppUserModelID)        
    #endregion

    #region PanelDesktopApplicationTile
        $PnlDAT = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlDAT)

        $YAxis = 10
        $LblTypeDAT = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Type: DesktopApplicationTile'
            AutoSize = $true
        }
        $PnlDAT.Controls.Add($LblTypeDAT)

        $YAxis = $YAxis + 30
        $LblDATTileSize = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Size'
            AutoSize = $true
        }
        $PnlDAT.Controls.Add($LblDATTileSize)

        $YAxis = $YAxis + 20
        $CBxDATSize = New-Object System.Windows.Forms.ComboBox -Property @{
            Location      = New-Object System.Drawing.Point(0,$YAxis)
            DropDownStyle = 'DropDownList'
            Width         = 220
        }
        $SizeItems = @('1x1','2x2','2x4','4x4')
        foreach ( $SizeItem in $SizeItems ) {
            $CBxDATSize.Items.Add($SizeItem) | out-null
        }
        $PnlDAT.Controls.Add($CBxDATSize)
        
        $YAxis = $YAxis + 30
        $LblDATColumn = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'Column'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlDAT.Controls.Add($LblDATColumn)

        $YAxis = $YAxis + 20
        $NumDATCol = New-Object System.Windows.Forms.NumericUpDown -Property @{
            BackColor   = 'White'
            Maximum     = 5
            ReadOnly    = $true
            TextAlign   = 'Center'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlDAT.Controls.Add($NumDATCol)

        $YAxis = $YAxis + 30
        $LblDATRow = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'Row'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlDAT.Controls.Add($LblDATRow)

        $YAxis = $YAxis + 20
        $NumDATRow = New-Object System.Windows.Forms.NumericUpDown -Property @{
            BackColor   = 'White'
            Maximum     = 20
            ReadOnly    = $true
            TextAlign   = 'Center'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlDAT.Controls.Add($NumDATRow)

        $YAxis = $YAxis + 30
        $LblDesktopApplicationTile = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'DesktopApplicationLinkPath'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlDAT.Controls.Add($LblDesktopApplicationTile)

        $YAxis = $YAxis + 20
        $CBxBoxDAT = New-Object System.Windows.Forms.ComboBox -Property @{
            Location       = New-Object System.Drawing.Point(0,$YAxis)
            DropDownHeight = 473
            DropDownWidth  = 1237
            Width          = 220
        }
        $AllLinks = @()
        $AllUserLinks = $(Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\*.lnk" -Recurse).FullName
    	$AllUserLinks = $AllUserLinks.Substring($($AllUserLinks[0].IndexOf($('Roaming\'))+8))
        $AllUserLinks = $AllUserLinks | ForEach-Object {"%APPDATA%\$_"}
        $AllLinks += $AllUserLinks
        $AllLinks += $(Get-ChildItem "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\*.lnk" -Recurse).FullName
        $AllLinks = $AllLinks.replace('C:\ProgramData','%ALLUSERSPROFILE%')
        $AllLinks = $AllLinks | Sort-Object
        if ( $AllLinks.Count -gt 0 ) {
            ForEach ( $Item in $AllLinks ) {
                $CBxBoxDAT.Items.Add($Item) | out-null
            }
        }
        $PnlDAT.Controls.Add($CBxBoxDAT)
    #endregion

    #region PanelNewItem
        $PnlNewItem = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlNewItem)

        $LblType = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,10)
            Text = 'Type:'
            Autosize = $true
        }
        $PnlNewItem.Controls.Add($LblType)
        
        $CBxType = New-Object System.Windows.Forms.ComboBox -Property @{
            Location = New-Object System.Drawing.Point(50,10)
            DropDownStyle = 'DropDownList'
            Width = 170
            #FlatStyle = 0
        }
        $PnlNewItem.Controls.Add($CBxType)
    #endregion

    #region PanelEmpty
        $PnlEmpty = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlEmpty)
    #endregion
#endregion

$FrmMain.ShowDialog()