clear-host
#region DeclarationOfVariables
    Add-Type -AssemblyName System.Windows.Forms
    $HidePSWindow = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);' # Part of the process to hide the Powershellwindow if it is not run through ISE
    Add-Type -name win -member $HidePSWindow -namespace native # Part of the process to hide the Powershellwindow if it is not run through ISE
    if ( $(Test-Path variable:global:psISE) -eq $False ) { [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0) } # This hides the Powershellwindow in the background if ISE isn't running
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  
    [string]$global:CurrentFileName = ''
    [bool]$global:Modified = $false

Try {
    $DefaultContent = Get-Content "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml"
}
Catch {
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
#$DefaultContent = @"
#<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout">
#  <LayoutOptions StartTileGroupCellWidth="6" StartTileGroupsColumnCount="1" />
#  <DefaultLayoutOverride LayoutCustomizationRestrictionType="OnlySpecifiedGroups">
#    <StartLayoutCollection>
#      <defaultlayout:StartLayout GroupCellWidth="6">
#        <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Flashplayer.lnk" />
#        <start:Group Name="Rekommenderat">
#          <start:Folder Size="2x2" Column="0" Row="0">
#            <start:Tile Size="2x2" Column="0" Row="0" AppUserModelID="Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge" />
#            <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk" />
#            <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk" />
#          </start:Folder>
#          <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
#          <start:Folder Size="2x2" Column="0" Row="2">
#            <start:Tile Size="2x2" Column="0" Row="0" AppUserModelID="Microsoft.WindowsMaps_8wekyb3d8bbwe!App" />
#            <start:Tile Size="2x2" Column="2" Row="0" AppUserModelID="Microsoft.Windows.Photos_8wekyb3d8bbwe!App" />
#            <start:Tile Size="2x2" Column="4" Row="0" AppUserModelID="Microsoft.BingWeather_8wekyb3d8bbwe!App" />
#            <start:Tile Size="2x2" Column="0" Row="2" AppUserModelID="Microsoft.WindowsCalculator_8wekyb3d8bbwe!App" />
#          </start:Folder>
#        </start:Group>
#        <start:Group Name="Office">
#          <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Outlook.lnk" />
#          <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Outlook 2016.lnk" />
#          <start:DesktopApplicationTile Size="1x1" Column="2" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Word.lnk" />
#          <start:DesktopApplicationTile Size="1x1" Column="2" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Word 2016.lnk" />
#          <start:DesktopApplicationTile Size="1x1" Column="3" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk" />
#          <start:DesktopApplicationTile Size="1x1" Column="3" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\PowerPoint 2016.lnk" />
#          <start:DesktopApplicationTile Size="1x1" Column="2" Row="1" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Excel.lnk" />
#          <start:DesktopApplicationTile Size="1x1" Column="2" Row="1" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Excel 2016.lnk" />
#          <start:DesktopApplicationTile Size="1x1" Column="3" Row="1" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\OneNote.lnk" />
#          <start:DesktopApplicationTile Size="1x1" Column="3" Row="1" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\OneNote 2016.lnk" />
#          <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Skype for Business 2016.lnk" />
#          <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Skype för företag 2016.lnk" />
#          <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Skype för företag.lnk" />
#        </start:Group>
#      </defaultlayout:StartLayout>
#    </StartLayoutCollection>
#  </DefaultLayoutOverride>
#    <CustomTaskbarLayoutCollection PinListPlacement="Replace">
#      <defaultlayout:TaskbarLayout>
#        <taskbar:TaskbarPinList>
#          <taskbar:UWA AppUserModelID="Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge" />
#          <taskbar:DesktopApp DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk" />
#          <taskbar:DesktopApp DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
#          <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Outlook.lnk" />
#          <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Outlook 2016.lnk" />
#        </taskbar:TaskbarPinList>
#      </defaultlayout:TaskbarLayout>
#    </CustomTaskbarLayoutCollection>
#</LayoutModificationTemplate>
#"@
    $DefaultContent = $DefaultContent.Replace("`r","")
    $DefaultContent = $DefaultContent.Split("`n")
}
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
        $BtnLayoutModificationTemplateApply.Location = New-Object System.Drawing.Point(0,$($BtnLayoutModificationTemplateApply.Location.Y + 50))
        $TxtLMTTaskbar.Visible = $true
        $LblLMTTaskbar.Visible = $true
        $LBxMain.Items.Insert($($LBxMain.Items.Count -1),'    <CustomTaskbarLayoutCollection PinListPlacement="Replace">')
        $LBxMain.Items.Insert($($LBxMain.Items.Count -1),'      <defaultlayout:TaskbarLayout>')
        $LBxMain.Items.Insert($($LBxMain.Items.Count -1),'        <taskbar:TaskbarPinList>')
        $LBxMain.Items.Insert($($LBxMain.Items.Count -1),'        </taskbar:TaskbarPinList>')
        $LBxMain.Items.Insert($($LBxMain.Items.Count -1),'      </defaultlayout:TaskbarLayout>')
        $LBxMain.Items.Insert($($LBxMain.Items.Count -1),'    </CustomTaskbarLayoutCollection>')
        $LBxMain.Items[0] = "$($LBxMain.Items[0].Substring(0,$($LBxMain.Items[0].Length -1))) xmlns:taskbar=""http://schemas.microsoft.com/Start/2014/TaskbarLayout"">"
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
            $BtnLayoutModificationTemplateApply.Location = New-Object System.Drawing.Point(0,$($BtnLayoutModificationTemplateApply.Location.Y - 50))
        }
        Else {
            $menuOptTaskbar.Checked = $true
            $TxtLMTTaskbar.Visible = $true
            $LblLMTTaskbar.Visible = $true
        }
    }
}

function Apply-Changes {
    $Whitespace = ''
    if ( $LBXMain.SelectedIndex -ne 0 ) {
        if ( $LBxMain.SelectedItem -like '*<start:Group*' -or $LBxMain.SelectedItem -like '*<start:Folder*' -or $LBxMain.SelectedItem -like '*<defaultlayout:Start*' -or $LBxMain.SelectedItem -like '*<taskbar:TaskbarPinList*' ) {
            $Whitespace = '  '
        }
        1..$($LBxMain.SelectedItem.IndexOf('<')) | % {
        $Whitespace = "$Whitespace "
    }
        $CBxDAT.Add_TextChanged({
            if ( $this.Text -ne '' ) {
                $BtnDesktopApplicationTileApply.Enabled = $true
            }
            else {
                $BtnDesktopApplicationTileApply.Enabled = $false
            }
        })
    }

    if ( $LBxMain.Enabled -eq $true ) {
        if ( $LBxMain.SelectedItem -like '*LayoutModificationTemplate*' ) {
            if ( $menuOptTaskbar.Checked -eq $true ) {
                $TaskbarXMLNSExist = " xmlns:taskbar=""$($TxtLMTTaskbar.Text)"""
            }
            $Line = "<LayoutModificationTemplate xmlns:defaultlayout=""$($TxtLMTDefaultLayout.Text)"" xmlns:start=""$($TxtLMTStart.Text)"" Version=""$($NumLMTVersion.Text)"" xmlns=""$($TxtLMTxlmns.Text)""$TaskbarXMLNSExist>"
        }
        if ( $LBxMain.SelectedItem -like '*LayoutOptions*' ) {
            if ( $CBxLayoutOptionsFullScreen.SelectedItem -eq 'True' ) {
                $FullScreenOn = "FullScreenStart=""true"""
            }
            $Line = "  <LayoutOptions StartTileGroupCellWidth=""$($CbxLayoutOptionsStartTileGroupCellWidth.Text)"" StartTileGroupsColumnCount=""$($NumLayoutOptionsStartTileGroupsColumnCount.Text)"" $FullScreenOn />"
        }
        if ( $LBxMain.SelectedItem -like '*DefaultLayoutOverride*' ) {
            if ( $CBxDefaultLayoutOverrideLCRT.SelectedItem -ne 'Off' ) {
                $OnlySpecifiedGroups = " LayoutCustomizationRestrictionType=""OnlySpecifiedGroups"""
            }
            $Line = "  <DefaultLayoutOverride$OnlySpecifiedGroups>"
        }
        if ( $LBxMain.SelectedItem -like '*defaultlayout:StartLayout*' ) {
            if ( $CbxStartLayoutGroupCellWidth.SelectedItem -ne 'Off' ) {
                $GroupCellWidth = " GroupCellWidth=""$($CbxStartLayoutGroupCellWidth.SelectedItem)"""
            }
            $Line = "      <defaultlayout:StartLayout$GroupCellWidth>"
        }
        if ( $LBxMain.SelectedItem -like '*DesktopApplicationTile*' ) {
            $Line = "$Whitespace<start:DesktopApplicationTile Size=""$($CBxDATSize.Text)"" Column=""$($NumDATCol.Text)"" Row=""$($NumDATRow.Text)"" DesktopApplicationLinkPath=""$($CBxDAT.Text)"" />"
        }
        if ( $LBxMain.SelectedItem -like '*start:Folder*' ) {
            if ( $TxtFolderName.Text -ne '' ) {
                $FolderName = "Name=""$($TxtFolderName.Text)"""
            }
            $Line = "$Whitespace<start:Folder $FolderName Size=""$($CBxFolderSize.Text)"" Column=""$($NumFolderCol.Text)"" Row=""$($NumFolderRow.Text)"">"
        }
        if ( $LBxMain.SelectedItem -like '*start:Group*' ) {
            $Line = "$Whitespace<start:Group Name=""$($TxtGroupName.Text)"" />"
        }
        if ( $LBxMain.SelectedItem -like '*start:Tile*' ) {
            $Line = "$Whitespace<start:Tile Size=""$($CBxTileSize.Text)"" Column=""$($NumTileCol.Text)"" Row=""$($NumTileRow.Text)"" AppUserModelID=""$($CBxTileAppUserModelID.Text)"" />"
        }
        if ( $LBxMain.SelectedItem -like '*<CustomTaskbarLayoutCollection*' ) {
            if ( $CbxTaskbarLayoutCollectionPinListPlacement.SelectedItem -ne 'Off' ) {
                $PinListPlacement = " PinListPlacement=""$($CbxTaskbarLayoutCollectionPinListPlacement.SelectedItem)"">"
            }
            $Line = "    <CustomTaskbarLayoutCollection$PinListPlacement"
        }
        if ( $LBxMain.SelectedItem -like '*taskbar:DesktopApp*' ) {
            $Line = "$Whitespace<taskbar:DesktopApp DesktopApplicationLinkPath=""$($CBxTaskbarDesktopApp.Text)"" />"
        }
        if ( $LBxMain.SelectedItem -like '*taskbar:UWA*' ) {
            $Line = "$Whitespace<taskbar:UWA AppUserModelID=""$($CBxTaskbarUWA.Text)"" />"
        }
        $LBxMain.Items[$LbxMain.SelectedIndex] = $Line
    }
    else {
        if ( $CBxInsertNewItem.SelectedItem -eq 'DesktopApplicationTile' ) {
            $BtnDesktopApplicationTileApply.Enabled = $false
            $BtnDesktopApplicationTileCancel.Visible = $false
            Enable-ControlsWhenNewItemDone
            $Line = "$Whitespace<start:DesktopApplicationTile Size=""$($CBxDATSize.Text)"" Column=""$($NumDATCol.Text)"" Row=""$($NumDATRow.Text)"" DesktopApplicationLinkPath=""$($CBxDAT.Text)"" />"
            $LBxMain.Items.Insert($LBxMain.SelectedIndex+1,$Line)
            $PnlDesktopApplicationTile.BringToFront()
        }
        if ( $CBxInsertNewItem.SelectedItem -eq 'Folder' ) {
            $BtnFolderApply.Enabled = $false
            $BtnFolderCancel.Visible = $false
            Enable-ControlsWhenNewItemDone
            $Line = "$Whitespace</start:Folder>"
            $LBxMain.Items.Insert($LBxMain.SelectedIndex+1,$Line)
            if ( $TxtFolderName.Text -ne '' ) {
                $FolderName = "Name=""$($TxtFolderName.Text)"""
            }
            $Line = "$Whitespace<start:Folder $FolderName Size=""$($CBxFolderSize.Text)"" Column=""$($NumFolderCol.Text)"" Row=""$($NumFolderRow.Text)"">"
            $LBxMain.Items.Insert($LBxMain.SelectedIndex+1,$Line)
            $PnlFolder.BringToFront()
        }
        if ( $CBxInsertNewItem.SelectedItem -eq 'Group' ) {
            $BtnGroupApply.Enabled = $false
            $BtnGroupCancel.Visible = $false
            Enable-ControlsWhenNewItemDone
            $Line = "$Whitespace</start:Group>"
            $LBxMain.Items.Insert($LBxMain.SelectedIndex+1,$Line)
            $Line = "$Whitespace<start:Group Name=""$($TxtGroupName.Text)"" />"
            $LBxMain.Items.Insert($LBxMain.SelectedIndex+1,$Line)
            $PnlGroup.BringToFront()
        }
        if ( $CBxInsertNewItem.SelectedItem -eq 'Tile' ) {
            $BtnTileApply.Enabled = $false
            $BtnTileCancel.Visible = $false
            Enable-ControlsWhenNewItemDone
            $Line = "$Whitespace<start:Tile Size=""$($CBxTileSize.Text)"" Column=""$($NumTileCol.Text)"" Row=""$($NumTileRow.Text)"" AppUserModelID=""$($CBxTileAppUserModelID.Text)"" />"
            $LBxMain.Items.Insert($LBxMain.SelectedIndex+1,$Line)
            $PnlTile.BringToFront()
        }
        if ( $CBxInsertNewItem.SelectedItem -eq 'DesktopApp' ) {
            $BtnTaskbarDesktopAppApply.Enabled = $false
            $BtnTaskbarDesktopAppCancel.Visible = $false
            Enable-ControlsWhenNewItemDone
            $Line = "$Whitespace<taskbar:DesktopApp DesktopApplicationLinkPath=""$($CBxTaskbarDesktopApp.Text)"" />"
            $LBxMain.Items.Insert($LBxMain.SelectedIndex+1,$Line)
            $PnlTaskbarDesktopApp.BringToFront()
        }
        if ( $CBxInsertNewItem.SelectedItem -eq 'UWA' ) {
            $BtnTaskbarUWAApply.Enabled = $false
            $BtnTaskbarUWACancel.Visible = $false
            Enable-ControlsWhenNewItemDone
            $Line = "$Whitespace<taskbar:UWA AppUserModelID=""$($CBxTaskbarUWA.Text)"" />"
            $LBxMain.Items.Insert($LBxMain.SelectedIndex+1,$Line)
            $PnlTaskbarUWA.BringToFront()
        }
        Change-ListBoxRow
    }
    $global:Modified = $true
}

function Open-NewItemPanel {
    if ( $CBxInsertNewItem.SelectedItem -eq 'DesktopApplicationTile' ) {
        $CBxDATSize.SelectedIndex = 1
        $NumDATCol.Text = 0
        $NumDATRow.Text = 0
        $CBxDAT.Text = ''
        $CBXDATSize.Focus()
        $BtnDesktopApplicationTileApply.Enabled = $false
        $BtnDesktopApplicationTileCancel.Visible = $true
        Disable-ControlsWhenNewItemSelected
        $PnlDesktopApplicationTile.BringToFront()
    }
    if ( $CBxInsertNewItem.SelectedItem -eq 'Folder' ) {
        $CBxFolderSize.SelectedIndex = 1
        $NumFolderCol.Text = 0
        $NumFolderRow.Text = 0
        $TxtFolderName.Text = ''
        $CBxFolderSize.Focus()
        $BtnFolderApply.Enabled = $true
        $BtnFolderCancel.Visible = $true
        Disable-ControlsWhenNewItemSelected
        $PnlFolder.BringToFront()
    }
    if ( $CBxInsertNewItem.SelectedItem -eq 'Group' ) {
        $TxtGroupName.Text = ''
        $TxtGroupName.Focus()
        $BtnGroupApply.Enabled = $true
        $BtnGroupCancel.Visible = $true
        Disable-ControlsWhenNewItemSelected
        $PnlGroup.BringToFront()
    }
    if ( $CBxInsertNewItem.SelectedItem -eq 'Tile' ) {
        $CBxTileSize.SelectedIndex = 1
        $NumTileCol.Text = 0
        $NumTileRow.Text = 0
        $CBxTileAppUserModelID.Text = ''
        $CBxTileSize.Focus()
        $BtnTileApply.Enabled = $false
        $BtnTileCancel.Visible = $true
        Disable-ControlsWhenNewItemSelected
        $PnlTile.BringToFront()
    }
    if ( $CBxInsertNewItem.SelectedItem -eq 'DesktopApp' ) {
        $CBxTaskbarDesktopApp.Text = ''
        $CBxTaskbarDesktopApp.Focus()
        $BtnTaskbarDesktopAppApply.Enabled = $false
        $BtnTaskbarDesktopAppCancel.Visible = $true
        Disable-ControlsWhenNewItemSelected
        $PnlTaskbarDesktopApp.BringToFront()
    }
    if ( $CBxInsertNewItem.SelectedItem -eq 'UWA' ) {
        $CBxTaskbarUWA.Text = ''
        $CBxTaskbarUWA.Focus()
        $BtnTaskbarUWAApply.Enabled = $false
        $BtnTaskbarUWACancel.Visible = $true
        Disable-ControlsWhenNewItemSelected
        $PnlTaskbarUWA.BringToFront()
    }
}

function Disable-ControlsWhenNewItemSelected {
    $PnlButtons.Enabled = $false
    $LBxMain.Enabled = $false
    $menuMain.Enabled = $false
    $CBxInsertNewItem.Enabled = $false
    $BtnInsertNewItem.Enabled = $false
    $BtnChangeView.Enabled = $false
}

function Enable-ControlsWhenNewItemDone {
    $PnlButtons.Enabled = $true
    $LBxMain.Enabled = $true
    $menuMain.Enabled = $true
    $CBxInsertNewItem.Enabled = $true
    $BtnInsertNewItem.Enabled = $true
    $BtnChangeView.Enabled = $true
}

function Get-AllLinks {
    $AllLinks = @()
    $AllUserLinks = $(Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\*.lnk" -Recurse).FullName
    $AllUserLinks = $AllUserLinks.Substring($($AllUserLinks[0].IndexOf($('Roaming\'))+8))
    $AllUserLinks = $AllUserLinks | ForEach-Object {"%APPDATA%\$_"}
    $AllLinks += $AllUserLinks
    $AllLinks += $(Get-ChildItem "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\*.lnk" -Recurse).FullName
    $AllLinks = $AllLinks.replace('C:\ProgramData','%ALLUSERSPROFILE%')
    $AllLinks = $AllLinks | Sort-Object

    $CBxDAT.Items.Clear()
    $CBxTaskbarDesktopApp.Items.Clear()
    if ( $AllLinks.Count -gt 0 ) {
        ForEach ( $Item in $AllLinks ) {
            [void]$CBxDAT.Items.Add($Item)
            if ( $menuOptTaskbar.Checked -eq $true ) {
                [void]$CBxTaskbarDesktopApp.Items.Add($Item)
            }
        }
    }
}

function Get-AllXPackages {
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

    $CBxTileAppUserModelID.Items.Clear()
    $CBxTaskbarUWA.Items.Clear()
    $Cbx
    if ( $AllXPackages.Count -gt 0 ) {
        ForEach ( $Package in $AllXPackages ) {
            [void]$CBxTileAppUserModelID.Items.Add($Package)
            if ( $menuOptTaskbar.Checked -eq $true ) {
                [void]$CBxTaskbarUWA.Items.Add($Package)
            }
        }
    }
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
    $pos = $LBxMain.SelectedIndex
    if ( $Direction -eq 'Up' ) {
        $LBxMain.items.insert($pos -1,$LBxMain.Items.Item($pos))
        if ( $LBxMain.SelectedItem -like '*<start:Group*' -or $LBxMain.SelectedItem -like '*<start:Folder*' ) {
            $LBxMain.Items[$LBxMain.SelectedIndex-1] = "  $($LBxMain.Items[$LBxMain.SelectedIndex-1])"
        }
        if ( $LBxMain.SelectedItem -like '*</start:Group*' -or $LBxMain.SelectedItem -like '*</start:Folder*' ) {
            $LBxMain.Items[$LBxMain.SelectedIndex-1] = $LBxMain.Items[$LBxMain.SelectedIndex-1].Substring(2)
        }
        if ( $LBxMain.SelectedItem -notlike '*</start:Group*' -and $LBxMain.SelectedItem -notlike '*</start:Folder*' -and $LBxMain.SelectedItem -notlike '*<start:Group*' -and $LBxMain.SelectedItem -notlike '*<start:Folder*' ) {
            if ( $LBxMain.Items[($LBxMain.SelectedIndex -1)] -like '*</start:Group*' -or $LBxMain.Items[($LBxMain.SelectedIndex -1)] -like '*</start:Folder*' ) {
                $LBxMain.Items[$LBxMain.SelectedIndex-2] = "  $($LBxMain.Items[$LBxMain.SelectedIndex-2])"
            }
            if ( $LBxMain.Items[($LBxMain.SelectedIndex -1)] -like '*<start:Group*' -or $LBxMain.Items[($LBxMain.SelectedIndex -1)] -like '*<start:Folder*' ) {
                $LBxMain.Items[$LBxMain.SelectedIndex-2] = $LBxMain.Items[$LBxMain.SelectedIndex-2].Substring(2)
            }
        }
        $LBxMain.SelectedIndex = ($pos -1)
        $LBxMain.Items.RemoveAt($pos +1)
    }
    else {
        $LBxMain.items.insert($pos,$LBxMain.Items.Item($pos +1))
        if ( $LBxMain.SelectedItem -like '*<start:Group*' -or $LBxMain.SelectedItem -like '*<start:Folder*' ) {
            $LBxMain.Items[$LBxMain.SelectedIndex-1] = $LBxMain.Items[$LBxMain.SelectedIndex-1].Substring(2)
            if ( $LBxMain.Items[$LBxMain.SelectedIndex -1] -like '*<start:Group*' -or $LBxMain.Items[$LBxMain.SelectedIndex -1] -like '*<start:Folder*' ) {
                $LBxMain.Items[$LBxMain.SelectedIndex] = "  $($LBxMain.Items[$LBxMain.SelectedIndex])"
            }
        }
        if ( $LBxMain.SelectedItem -like '*</start:Group*' -or $LBxMain.SelectedItem -like '*</start:Folder*' ) {
            $LBxMain.Items[$LBxMain.SelectedIndex-1] = "  $($LBxMain.Items[$LBxMain.SelectedIndex-1])"
        }
        if ( $LBxMain.SelectedItem -notlike '*</start:Group*' -and $LBxMain.SelectedItem -notlike '*</start:Folder*' -and $LBxMain.SelectedItem -notlike '*<start:Group*' -and $LBxMain.SelectedItem -notlike '*<start:Folder*' ) {
            if ( $LBxMain.Items[($LBxMain.SelectedIndex+1)] -like '*<start:Group*' -or $LBxMain.Items[($LBxMain.SelectedIndex+1)] -like '*<start:Folder*' ) {
                $LBxMain.Items[$LBxMain.SelectedIndex] = "  $($LBxMain.Items[$LBxMain.SelectedIndex])"
            }
            if ( $LBxMain.Items[($LBxMain.SelectedIndex+1)] -like '*</start:Group*' -or $LBxMain.Items[($LBxMain.SelectedIndex+1)] -like '*</start:Folder*' ) {
                $LBxMain.Items[$LBxMain.SelectedIndex] = $LBxMain.Items[$LBxMain.SelectedIndex].Substring(2)
            }
        }
        $LBxMain.SelectedIndex = ($pos +1)
        $LBxMain.Items.RemoveAt($pos +2)
    }
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
                    if ( $Item -like '*version=*' ) { $NumLMTVersion.Text = $SelectedItem[$Counter +1] }
                    $Counter++
                }
            }
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<LayoutOptions*' ) {
            $PnlLayoutOptions.BringToFront()
            $SelectedItem = $LBxMain.SelectedItem.Split('"')
            $Counter = 0
            if ( $LBxMain.SelectedItem.TrimStart() -like '*FullScreenStart="true"*' ) {
                $CBxLayoutOptionsFullScreen.SelectedItem = 'True'
            }
            else {
                $CBxLayoutOptionsFullScreen.SelectedItem = 'Off'
            }
            foreach ( $Item in $SelectedItem ) {
                if ( $Item -like '*StartTileGroupCellWidth=*' ) { $CBxLayoutOptionsStartTileGroupCellWidth.SelectedItem = $SelectedItem[$Counter +1] }
                if ( $Item -like '*StartTileGroupsColumnCount=*' ) { $NumLayoutOptionsStartTileGroupsColumnCount.Text = $SelectedItem[$Counter +1] }
                $Counter++
            }
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<DefaultLayoutOverride*' ) {
            $PnlDefaultLayoutOverride.BringToFront()
            $SelectedItem = $LBxMain.SelectedItem.Split('"')
            if ( $LBxMain.SelectedItem.TrimStart() -like '*LayoutCustomizationRestrictionType="OnlySpecifiedGroups"*' ) {
                $CBxDefaultLayoutOverrideLCRT.SelectedItem = 'OnlySpecifiedGroups'
            }
            else {
                $CBxDefaultLayoutOverrideLCRT.SelectedItem = 'Off'
            }
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<defaultlayout:StartLayout*' ) {
            $PnlStartlayout.BringToFront()
            if ( $LBxMain.SelectedItem -like '*GroupCellWidth*' ) {
                $SelectedItem = $LBxMain.SelectedItem.Split('"')
                $Counter = 0
                foreach ( $Item in $SelectedItem ) {
                    if ( $Item -like '*GroupCellWidth=*' ) { $CbxStartLayoutGroupCellWidth.SelectedItem = $SelectedItem[$Counter +1] }
                    $Counter++
                }
            }
            else {
                $CbxStartLayoutGroupCellWidth.SelectedItem = 'Off'
            }
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
                    if ( $CBxTileAppUserModelID.Items -contains $SelectedItem[$Counter +1] ) {
                        $CBxTileAppUserModelID.SelectedItem = $SelectedItem[$Counter +1]
                    }
                        else { $CBxTileAppUserModelID.Text = $SelectedItem[$Counter +1]
                    }
                }
                $Counter++
            }
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<start:DesktopApplicationTile*' ) {
            $PnlDesktopApplicationTile.BringToFront()
            $SelectedItem = $LBxMain.SelectedItem.Split('"')
            $Counter = 0
            foreach ( $Item in $SelectedItem ) {
                if ( $Item -like '*Size=*' ) { $CBxDATSize.SelectedItem = $SelectedItem[$Counter +1] }
                if ( $Item -like '*Row=*' ) { $NumDATRow.Text = $SelectedItem[$Counter +1] }
                if ( $Item -like '*Column=*' ) { $NumDATCol.Text = $SelectedItem[$Counter +1] }
                if ( $Item -like '*DesktopApplicationLinkPath=*' ) {
                    if ( $CBxDAT.Items -contains $SelectedItem[$Counter +1] ) {
                        $CBxDAT.SelectedItem = $SelectedItem[$Counter +1]
                    }
                        else { $CBxDAT.Text = $SelectedItem[$Counter +1]
                    }
                }
                $Counter++
            }
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<CustomTaskbarLayoutCollection*' ) {
            $PnlTaskbarLayoutCollection.BringToFront()
            if ( $LBxMain.SelectedItem.TrimStart() -like '*PinListPlacement="Replace"*' ) {
                $CbxTaskbarLayoutCollectionPinListPlacement.SelectedItem = 'Replace'
            }
            else {
                $CbxTaskbarLayoutCollectionPinListPlacement.SelectedItem = 'Off'
            }
            $SelectionTabExist = $true
        }
        if ( $LBxMain.SelectedItem.TrimStart() -like '<taskbar:UWA*' ) {
            $PnlTaskbarUWA.BringToFront()
            $SelectedItem = $LBxMain.SelectedItem.Split('"')
            $Counter = 0
            foreach ( $Item in $SelectedItem ) {
                if ( $Item -like '*AppUserModelID=*' ) {
                    if ( $CBxTaskbarUWA.Items -contains $SelectedItem[$Counter +1] ) {
                        $CBxTaskbarUWA.SelectedItem = $SelectedItem[$Counter +1]
                    }
                        else { $CBxTaskbarUWA.Text = $SelectedItem[$Counter +1]
                    }
                }
            }
            $SelectionTabExist = $true
        }
        $LblPositionRow.Text = "$($LBxMain.SelectedIndex + 1)"

        if ( $LBxMain.SelectedItem.TrimStart() -like '<taskbar:DesktopApp*' ) {
            $PnlTaskbarDesktopApp.BringToFront()
            $SelectedItem = $LBxMain.SelectedItem.Split('"')
            $Counter = 0
            foreach ( $Item in $SelectedItem ) {
                if ( $Item -like '*DesktopApplicationLinkPath=*' ) {
                    if ( $CBxTaskbarDesktopApp.Items -contains $SelectedItem[$Counter +1] ) {
                        $CBxTaskbarDesktopApp.SelectedItem = $SelectedItem[$Counter +1]
                    }
                        else { $CBxTaskbarDesktopApp.Text = $SelectedItem[$Counter +1]
                    }
                }
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
            $CBxInsertNewItem.Enabled = $true
            if ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1)  -like '*<defaultlayout:Start*' -or $LBxMain.Items.Item($LBxMain.SelectedIndex-1)  -like '*<taskbar:taskBarPinList*' ) { $BtnMoveUp.Enabled = $false }
            else { $BtnMoveUp.Enabled = $true }
            if ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*</defaultlayout:Start*' -or $LBxMain.Items.Item($LBxMain.SelectedIndex+1)  -like '*</taskbar:*' ) { $BtnMoveDown.Enabled = $false }
            else { $BtnMoveDown.Enabled = $true }
            if ( $LBxMain.SelectedItem.TrimStart() -like '</start:Folder*' ) {
                $BtnRemoveItem.Enabled = $false
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1) -like '*<start:Folder*' ) { $BtnMoveUp.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*<start:Folder*' ) { $BtnMoveDown.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1) -like '*</start:Group*' ) { $BtnMoveUp.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*</start:Group*' ) { $BtnMoveDown.Enabled = $false }
            }
            if ( $LBxMain.SelectedItem.TrimStart() -like '</start:Group*' ) {
                $BtnRemoveItem.Enabled = $false
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1) -like '*<start:Group*' ) { $BtnMoveUp.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*<start:Group*' ) { $BtnMoveDown.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1) -like '*</start:Folder*' ) { $BtnMoveUp.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*</start:Folder*' ) { $BtnMoveDown.Enabled = $false }
            }
            if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Folder*' ) {
                $BtnRemoveItem.Enabled = $false
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1) -like '*</start:Folder*' ) { $BtnMoveUp.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*</start:Folder*' ) { $BtnMoveDown.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1) -like '*<start:Group*' ) { $BtnMoveUp.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*<start:Group*' ) { $BtnMoveDown.Enabled = $false }
            }
            if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Group*' ) {
                $BtnRemoveItem.Enabled = $false
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1) -like '*</start:Group*' ) { $BtnMoveUp.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*</start:Group*' ) { $BtnMoveDown.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex-1) -like '*<start:Folder*' ) { $BtnMoveUp.Enabled = $false }
                If ( $LBxMain.Items.Item($LBxMain.SelectedIndex+1) -like '*<start:Folder*' ) { $BtnMoveDown.Enabled = $false }
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
            $CBxInsertNewItem.Enabled = $false
            $BtnRemoveItem.Enabled = $false
        }

        if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Folder*' -or $LBxMain.SelectedItem.TrimStart() -like '<start:Group*' ) {
            $BtnRemoveAll.Visible = $true
            if ( $LBxMain.SelectedItem.TrimStart() -like '<start:Folder*' ) {
                $BtnRemoveAll.Text = 'R&emove Folder'
            }
            else {
                $BtnRemoveAll.Text = 'R&emove Group'
            }
        }
        else {
            $BtnRemoveAll.Visible = $false
        }

        if ( $CBxInsertNewItem.Enabled -eq $true ) {
            if ( $LBxMain.SelectedItem.TrimStart() -like '<taskbar*' ) {
                $CBxTypeItems = @('DesktopApp','UWA')
            }
            else {
                $SelectedRow = $LBxMain.SelectedIndex
                $AlreadyInGroup = $false
                Do {
                    if ( $LBxMain.Items[$SelectedRow].TrimStart() -like '</start:Group*' ) {
                        $SelectedRow = 1
                    }
                    if ( $SelectedRow -ne 1 ) {
                        if ( $LBxMain.Items[$SelectedRow].TrimStart() -like '<start:Group*' ) {
                            $AlreadyInGroup = $true
                        }
                    }
                    $SelectedRow = $SelectedRow - 1
                }
                Until ( $SelectedRow -eq 0 -or $AlreadyInGroup -eq $true)

                $SelectedRow = $LBxMain.SelectedIndex
                $AlreadyInFolder = $false
                Do {
                    if ( $LBxMain.Items[$SelectedRow].TrimStart() -like '</start:Folder*' ) {
                        $SelectedRow = 1
                    }
                    if ( $SelectedRow -ne 1 ) {
                        if ( $LBxMain.Items[$SelectedRow].TrimStart() -like '<start:Folder*' ) {
                            $AlreadyInFolder = $true
                        }
                    }
                    $SelectedRow = $SelectedRow - 1
                }
                Until ( $SelectedRow -eq 0 -or $AlreadyInFolder -eq $true)
        
                $CBxTypeItems = @('DesktopApplicationTile','Tile')
                if ( $AlreadyInGroup -eq $false ) { $CBxTypeItems += 'Group' }
                if ( $AlreadyInFolder -eq $false ) { $CBxTypeItems += 'Folder' }
                $CBxTypeItems = $CBxTypeItems | Sort-Object
            }

            $CBxInsertNewItem.Items.Clear()
            foreach ( $CBxTypeItem in $CBxTypeItems ) {
                [void]$CBxInsertNewItem.Items.Add($CBxTypeItem)
            }
            $CBxInsertNewItem.SelectedIndex = 0
        }
        
        Try {
            $BtnTaskbarDesktopAppApply.Enabled = $false
            $BtnTaskbarUWAApply.Enabled = $false
            $BtnFolderApply.Enabled = $false
            $BtnGroupApply.Enabled = $false
            $BtnDesktopApplicationTileApply.Enabled = $false
            $BtnTileApply.Enabled = $false
            $BtnLayoutModificationTemplateApply.Enabled = $false
            $BtnLayoutOptionsApply.Enabled = $false
            $BtnDefaultLayoutOverrideApply.Enabled = $false
            $BtnStartLayoutApply.Enabled = $false
            $BtnTaskbarLayoutCollectionApply.Enabled = $false
        }
        Catch {}
    }
}

function Show-DesignView {
    $BtnChangeView.Text = '&Cancel'
    $LBxMain.Visible = $false
    $LBxMain.Enabled = $false
    $TxtMain.Visible = $true
    $TxtMain.Enabled = $true
    $menuOptTaskbar.Enabled = $false
    $BtnTextViewApply.Visible = $true
    $TxtMain.BringToFront()
    $TxtMain.Clear()
    $PnlButtons.Visible = $false
    $TxtMain.Lines = $LBxMain.Items
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
    $LblPositionRow.Text = 1
}

function Apply-TextViewResult {
    $BadCode = $false
    $Counter = 1
    $Errors = @()
    foreach ( $Line in $TxtMain.Text.Split("`n") ) {
        if ( $Line -eq "" ) {
            $Errors += "Line: $Counter - Remove empty line"
        }
        else {
            if ( $Line.TrimStart().Substring(0,1) -ne '<' ) {
                $Errors += "Line: $Counter - Missing '<' as first character after initial whitespace"
            }
            if ( $Line.TrimEnd().Substring($Line.Length-1,1) -ne '>' ) {
                $Errors += "Line: $Counter - Missing '>' as last character"
            }
            $CharCount = ($Line.Split('"') | measure-object).Count -1
            if ( $CharCount % 2 -ne 0) {
	            $Errors += "Line: $Counter - Odd occurrence of '""'"
            }
        }
        $Counter++
    }

    if ( $Errors.Count -eq 0 ) {
        $LBxMain.Items.Clear()
        if ( $TxtMain.Text -contains '<CustomTaskbarLayoutCollection' ) {
            $menuOptTaskbar.Checked = $true
        }
        else {
            $menuOptTaskbar.Checked = $false
        }

        foreach ( $Line in $TxtMain.Text.Split("`n") ) {
            if ( $Line -ne '' ) {
                [void]$LBxMain.Items.Add($Line.TrimEnd())
            }
        }
        Hide-DesignView
        $global:Modified = $true
    }
    else {
        $LBxErrors.Items.Clear()
        foreach ( $Item in $Errors ) {
            $LBxErrors.Items.Add($Item)
        }
        [void]$FrmError.ShowDialog()
    }
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

#region ErrorForm
    $FrmError = New-Object System.Windows.Forms.Form -Property @{
        ClientSize      = '850, 497'
        BackColor       = 'White'
        FormBorderStyle = 'Fixed3D'
        ShowIcon        = $false
        MaximizeBox     = $false
        MinimizeBox     = $false
        ShowInTaskBar   = $false
        StartPosition   = 'CenterParent'
        Text            = 'Errors to handle before saving'
    }

    $LBxErrors = New-Object System.Windows.Forms.ListBox -Property @{
        Location    = New-Object System.Drawing.Point(0,0)
        DrawMode    = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
        BorderStyle = 'Fixed3D'
        Width       = 850
        Height      = 470
    }
    $LBxErrors.HorizontalScrollbar = $true
    $LBxErrors.HorizontalExtent = 1000
    $LBxErrors.add_DrawItem({
        param([object]$s, [System.Windows.Forms.DrawItemEventArgs]$e)
        if ( $e.Index -gt -1 ) {
            if ( $e.Index % 2 -eq 0) {
                $backcolor = [System.Drawing.Color]::WhiteSmoke
            }
            else {
                $backcolor = [System.Drawing.Color]::White
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
    })
    $FrmError.Controls.Add($LBxErrors)  
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
                [void]$LBxMain.Items.Add($Line)
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
                    [void]$LBxMain.Items.Add($Line)
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
                        [void]$LBxMain.Items.Add($Line)
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
                        [void]$LBxMain.Items.Add($Line)
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
            Text     = "          Fredrik Bergman `n`r www.onpremproblems.com"
        }
        $aboutForm.Controls.Add($aboutFormText)
     
        $aboutFormExit      = New-Object System.Windows.Forms.Button -Property @{
            Location = '135, 75'
            Text     = 'OK'
        }
        $aboutFormExit.Add_Click({ $aboutForm.Close() })
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

    $menuOptRefreshLinksAndPkgs = New-Object System.Windows.Forms.ToolStripMenuItem -Property @{
        Text         = 'Refresh links & packages'
    }
    $menuOptTaskbar.Add_Click({Get-AllLinks ; Get-AllXPackages})
    [void]$menuOptions.DropDownItems.Add($menuOptRefreshLinksAndPkgs)
        
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
            Size     = New-Object Drawing.Size @(750,35)
            Location = New-Object System.Drawing.Point(242,703)
        }
        $FrmMain.Controls.Add($PnlButtons)

    $BtnMoveUp = New-Object System.Windows.Forms.Button -Property @{
        FlatStyle = 0
        Location  = New-Object System.Drawing.Point(0,0)
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
            Location  = New-Object System.Drawing.Point(105,0)
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
    
        $BtnRemoveItem = New-Object System.Windows.Forms.Button -Property @{
            Text = '&Remove'
            FlatStyle = 0
            Width = 100
            Location = New-Object System.Drawing.Point(210,0)
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
            Width     = 125
            Location  = New-Object System.Drawing.Point(315,0)
        }
        $BtnRemoveAll.FlatAppearance.BorderColor = 'LightBlue'
        $BtnRemoveAll.FlatAppearance.BorderSize = 2
        $BtnRemoveAll.Add_Click({Remove-All})
        $PnlButtons.Controls.Add($BtnRemoveAll)
    #endregion
 
    $LblRow = New-Object System.Windows.Forms.Label -Property @{
        Location = New-Object System.Drawing.Point(10,707)
        Text = 'Line:'
        Width = 35
    }
    $FrmMain.Controls.Add($LblRow)
    
    $LblPositionRow = New-Object System.Windows.Forms.Label -Property @{
        Location = New-Object System.Drawing.Point(45,707)
        AutoSize = $true
    }
    $FrmMain.Controls.Add($LblPositionRow)
    
    $BtnTextViewApply = New-Object System.Windows.Forms.Button -Property @{
        Text      = 'Save'
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

    $CBxInsertNewItem = New-Object System.Windows.Forms.ComboBox -Property @{
        Width         = 175
        Location      = New-Object System.Drawing.Point(242,28)
        DropDownStyle = 'DropDownList'
    }
    [void]$CBxInsertNewItem.Items.Add('DesktopApplicationTile')
    $CBxInsertNewItem.SelectedIndex = 0
    $FrmMain.Controls.Add($CBxInsertNewItem)

    $BtnInsertNewItem = New-Object System.Windows.Forms.Button -Property @{
        Text      = 'New &item'
        FlatStyle = 0
        Width     = 100
        Location  = New-Object System.Drawing.Point(422,28)
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
    $BtnInsertNewItem.Add_Click({Open-NewItemPanel})
    $FrmMain.Controls.Add($BtnInsertNewItem)

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
    $TxtMain.Add_SelectionChanged({$LblPositionRow.Text = $TxtMain.GetLineFromCharIndex($TxtMain.SelectionStart)+1})
    $FrmMain.Controls.Add($TxtMain)

    $LBxMain = New-Object System.Windows.Forms.ListBox -Property @{
        Location    = New-Object System.Drawing.Point(242,57)
        DrawMode    = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
        BorderStyle = 'Fixed3D'
        Width       = 1010
        Height      = 645
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
    }
    if ( $LBxMain.Items.Count -gt 0 ) { $LBxMain.SelectedIndex = 0 }
    $FrmMain.Controls.Add($LbxMain)
#endregion

#region Panels
    #region PanelTaskbarUWA
        $PnlTaskbarUWA = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlTaskbarUWA)

        $YAxis = 10
        $LblTaskbarUWA = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Type: Taskbar:UWA'
            AutoSize = $true
        }
        $PnlTaskbarUWA.Controls.Add($LblTaskbarUWA)

        $YAxis = $YAxis + 30
        $LblTaskbarUWA = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'AppUserModelID'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlTaskbarUWA.Controls.Add($LblTaskbarUWA)

        $YAxis = $YAxis + 20
        $CBxTaskbarUWA = New-Object System.Windows.Forms.ComboBox -Property @{
            Location       = New-Object System.Drawing.Point(0,$YAxis)
            DropDownHeight = 473
            DropDownWidth  = 1237
            Width          = 220
        }
        $CBxTaskbarUWA.Add_TextChanged({
            if ( $CBxTaskBarUWA.Text -ne '' ) {
                $BtnTaskbarUWAApply.Enabled = $true
            }
            else {
                $BtnTaskbarUWAApply.Enabled = $false
            }
        })
        $PnlTaskbarUWA.Controls.Add($CBxTaskbarUWA)

        $YAxis = $YAxis + 35
        $BtnTaskbarUWAApply = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Apply'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(0,$YAxis)
        }
        $BtnTaskbarUWAApply.Add_EnabledChanged({
           if ( $this.Enabled -eq $false ) {
                $this.FlatAppearance.BorderColor = 'LightGray'
                $this.FlatAppearance.BorderSize = 1
            }
            else {
                $this.FlatAppearance.BorderColor = 'LightBlue'
                $this.FlatAppearance.BorderSize = 2
            }
        })
        $BtnTaskbarUWAApply.Enabled = $false
        $BtnTaskbarUWAApply.Add_Click({Apply-Changes})
        $PnlTaskbarUWA.Controls.Add($BtnTaskbarUWAApply)

        $BtnTaskbarUWACancel = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Cancel'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(120,$YAxis)
        }
        $BtnTaskbarUWACancel.FlatAppearance.BorderColor = 'LightBlue'
        $BtnTaskbarUWACancel.FlatAppearance.BorderSize = 2
        $BtnTaskbarUWACancel.Visible = $false
        $BtnTaskbarUWACancel.Add_Click({
            $this.Visible = $false
            Enable-ControlsWhenNewItemDone
            Change-ListBoxRow
        })
        $PnlTaskbarUWA.Controls.Add($BtnTaskbarUWACancel)
    #endregion

    #region PanelTaskbarDesktopApp
        $PnlTaskbarDesktopApp = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlTaskbarDesktopApp)

        $YAxis = 10
        $LblTaskbarDesktopApp = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Type: Taskbar:DesktopApp'
            AutoSize = $true
        }
        $PnlTaskbarDesktopApp.Controls.Add($LblTaskbarDesktopApp)

        $YAxis = $YAxis + 30
        $LblTaskbarDesktopApp = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'DesktopApplicationLinkPath'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlTaskbarDesktopApp.Controls.Add($LblTaskbarDesktopApp)

        $YAxis = $YAxis + 20
        $CBxTaskbarDesktopApp = New-Object System.Windows.Forms.ComboBox -Property @{
            Location       = New-Object System.Drawing.Point(0,$YAxis)
            DropDownHeight = 473
            DropDownWidth  = 1237
            Width          = 220
        }
        $CBxTaskbarDesktopApp.Add_TextChanged({
            if ( $CBxTaskbarDesktopApp.Text -ne '' ) {
                $BtnTaskbarDesktopAppApply.Enabled = $true
            }
            else {
                $BtnTaskbarDesktopAppApply.Enabled = $false
            }
        })
        $PnlTaskbarDesktopApp.Controls.Add($CBxTaskbarDesktopApp)

        $YAxis = $YAxis + 35
        $BtnTaskbarDesktopAppApply = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Apply'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(0,$YAxis)
        }
        $BtnTaskbarDesktopAppApply.Add_EnabledChanged({
           if ( $this.Enabled -eq $false ) {
                $this.FlatAppearance.BorderColor = 'LightGray'
                $this.FlatAppearance.BorderSize = 1
            }
            else {
                $this.FlatAppearance.BorderColor = 'LightBlue'
                $this.FlatAppearance.BorderSize = 2
            }
        })
        $BtnTaskbarDesktopAppApply.Enabled = $false
        $BtnTaskbarDesktopAppApply.Add_Click({Apply-Changes})
        $PnlTaskbarDesktopApp.Controls.Add($BtnTaskbarDesktopAppApply)

        $BtnTaskbarDesktopAppCancel = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Cancel'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(120,$YAxis)
        }
        $BtnTaskbarDesktopAppCancel.FlatAppearance.BorderColor = 'LightBlue'
        $BtnTaskbarDesktopAppCancel.FlatAppearance.BorderSize = 2
        $BtnTaskbarDesktopAppCancel.Visible = $false
        $BtnTaskbarDesktopAppCancel.Add_Click({
            $this.Visible = $false
            Enable-ControlsWhenNewItemDone
            Change-ListBoxRow
        })
        $PnlTaskbarDesktopApp.Controls.Add($BtnTaskbarDesktopAppCancel)
    #endregion

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
        $TxtLMTDefaultLayout.Add_TextChanged({
            if ( $this.Text -ne '' ) {
                $BtnLayoutModificationTemplateApply.Enabled = $true
            }
            else {
                $BtnLayoutModificationTemplateApply.Enabled = $false
            }
        })
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
        $TxtLMTStart.Add_TextChanged({
            if ( $this.Text -ne '' ) {
                $BtnLayoutModificationTemplateApply.Enabled = $true
            }
            else {
                $BtnLayoutModificationTemplateApply.Enabled = $false
            }
        })
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
        $TxtLMTxlmns.Add_TextChanged({
            if ( $this.Text -ne '' ) {
                $BtnLayoutModificationTemplateApply.Enabled = $true
            }
            else {
                $BtnLayoutModificationTemplateApply.Enabled = $false
            }
        })
        $PnlLayoutModificationTemplate.Controls.Add($TxtLMTxlmns)

        $YAxis = $YAxis + 30
        $LblLMTVersion = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'Version'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlLayoutModificationTemplate.Controls.Add($LblLMTVersion)

        $YAxis = $YAxis + 20
        $NumLMTVersion = New-Object System.Windows.Forms.NumericUpDown -Property @{
            BackColor   = 'White'
            Minimum     = '1'
            TextAlign   = 'Center'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $NumLMTVersion.Add_TextChanged({
            if ( $this.Text -ne '' ) {
                $BtnLayoutModificationTemplateApply.Enabled = $true
            }
            else {
                $BtnLayoutModificationTemplateApply.Enabled = $false
            }
        })
        $PnlLayoutModificationTemplate.Controls.Add($NumLMTVersion)

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
        $TxtLMTTaskbar.Add_TextChanged({
            if ( $this.Text -ne '' ) {
                $BtnLayoutModificationTemplateApply.Enabled = $true
            }
            else {
                $BtnLayoutModificationTemplateApply.Enabled = $false
            }
        })
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

        $YAxis = $YAxis + 35
        $BtnLayoutModificationTemplateApply = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Apply'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(0,$YAxis)
        }
        if ( $DefaultContent[0] -notlike '*xmlns:taskbar*' ) {
            $BtnLayoutModificationTemplateApply.Location  = New-Object System.Drawing.Point(0,$($BtnLayoutModificationTemplateApply.Location.Y - 50 ))
        }
        $BtnLayoutModificationTemplateApply.Add_EnabledChanged({
           if ( $this.Enabled -eq $false ) {
                $this.FlatAppearance.BorderColor = 'LightGray'
                $this.FlatAppearance.BorderSize = 1
            }
            else {
                $this.FlatAppearance.BorderColor = 'LightBlue'
                $this.FlatAppearance.BorderSize = 2
            }
        })
        $BtnLayoutModificationTemplateApply.Enabled = $false
        $BtnLayoutModificationTemplateApply.Add_Click({Apply-Changes})
        $PnlLayoutModificationTemplate.Controls.Add($BtnLayoutModificationTemplateApply)
    #endregion

    #region PanelLayoutOptions
        $PnlLayoutOptions = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlLayoutOptions)

        $YAxis = 10
        $LblTypeLayoutOptions = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Type: LayoutOptions'
            AutoSize = $true
        }
        $PnlLayoutOptions.Controls.Add($LblTypeLayoutOptions)

        $YAxis = $YAxis + 30
        $LblLayoutOptionsStartTileGroupCellWidth = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'StartTileGroupCellWidth'
            AutoSize = $true
        }
        $PnlLayoutOptions.Controls.Add($LblLayoutOptionsStartTileGroupCellWidth)

        $YAxis = $YAxis + 20
        $CbxLayoutOptionsStartTileGroupCellWidth = New-Object System.Windows.Forms.ComboBox -Property @{
            DropDownStyle = 'DropDownList'
            Width         = 220
            Location      = New-Object System.Drawing.Point(0,$YAxis)
        }
        [void]$CBxLayoutOptionsStartTileGroupCellWidth.Items.Add('6')
        [void]$CBxLayoutOptionsStartTileGroupCellWidth.Items.Add('8')
        $CbxLayoutOptionsStartTileGroupCellWidth.Add_SelectedIndexChanged({
            $BtnLayoutOptionsApply.Enabled = $true
        })
        $PnlLayoutOptions.Controls.Add($CBxLayoutOptionsStartTileGroupCellWidth)

        $YAxis = $YAxis + 30
        $LblLayoutOptionsStartTileGroupsColumnCount = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'StartTileGroupsColumnCount'
            AutoSize = $true
        }
        $PnlLayoutOptions.Controls.Add($LblLayoutOptionsStartTileGroupsColumnCount)

        $YAxis = $YAxis + 20
        $NumLayoutOptionsStartTileGroupsColumnCount = New-Object System.Windows.Forms.NumericUpDown -Property @{
            BackColor   = 'White'
            Minimum     = 1
            Maximum     = 2
            ReadOnly    = $true
            TextAlign   = 'Center'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $NumLayoutOptionsStartTileGroupsColumnCount.Add_TextChanged({
            $BtnLayoutOptionsApply.Enabled = $true
        })
        $PnlLayoutOptions.Controls.Add($NumLayoutOptionsStartTileGroupsColumnCount)

        $YAxis = $YAxis + 30
        $LblLayoutOptionsFullScreen = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'FullScreenStart'
            AutoSize = $true
        }
        $PnlLayoutOptions.Controls.Add($LblLayoutOptionsFullScreen)

        $YAxis = $YAxis + 20
        $CBxLayoutOptionsFullScreen = New-Object System.Windows.Forms.ComboBox -Property @{
            DropDownStyle = 'DropDownList'
            Location       = New-Object System.Drawing.Point(0,$YAxis)
            Width          = 220
        }
        [void]$CBxLayoutOptionsFullScreen.Items.Add('True')
        [void]$CBxLayoutOptionsFullScreen.Items.Add('Off')
        $CBxLayoutOptionsFullScreen.Add_SelectedIndexChanged({
            $BtnLayoutOptionsApply.Enabled = $true
        })
        $PnlLayoutOptions.Controls.Add($CBxLayoutOptionsFullScreen)

        $YAxis = $YAxis + 35
        $BtnLayoutOptionsApply = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Apply'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(0,$YAxis)
        }
        $BtnLayoutOptionsApply.Add_EnabledChanged({
           if ( $this.Enabled -eq $false ) {
                $this.FlatAppearance.BorderColor = 'LightGray'
                $this.FlatAppearance.BorderSize = 1
            }
            else {
                $this.FlatAppearance.BorderColor = 'LightBlue'
                $this.FlatAppearance.BorderSize = 2
            }
        })
        $BtnLayoutOptionsApply.Enabled = $false
        $BtnLayoutOptionsApply.Add_Click({Apply-Changes})
        $PnlLayoutOptions.Controls.Add($BtnLayoutOptionsApply)

    #endregion

    #region PanelDefaultLayoutOverride
        $PnlDefaultLayoutOverride = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlDefaultLayoutOverride)

        $YAxis = 10
        $LblTypeDefaultLayoutOverride = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Type: DefaultLayoutOverride'
            AutoSize = $true
        }
        $PnlDefaultLayoutOverride.Controls.Add($LblTypeDefaultLayoutOverride)

        $YAxis = $YAxis + 30
        $LblDefaultLayoutOverrideLCRT = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'LayoutCustomizationRestrictionType'
            AutoSize = $true
        }
        $PnlDefaultLayoutOverride.Controls.Add($LblDefaultLayoutOverrideLCRT)

        $YAxis = $YAxis + 20
        $CBxDefaultLayoutOverrideLCRT = New-Object System.Windows.Forms.ComboBox -Property @{
            DropDownStyle = 'DropDownList'
            Location       = New-Object System.Drawing.Point(0,$YAxis)
            Width          = 220
        }
        [void]$CBxDefaultLayoutOverrideLCRT.Items.Add('OnlySpecifiedGroups')
        [void]$CBxDefaultLayoutOverrideLCRT.Items.Add('Off')
        $CBxDefaultLayoutOverrideLCRT.Add_SelectedIndexChanged({
            $BtnDefaultLayoutOverrideApply.Enabled = $true
        })
        $PnlDefaultLayoutOverride.Controls.Add($CBxDefaultLayoutOverrideLCRT)

        $YAxis = $YAxis + 35
        $BtnDefaultLayoutOverrideApply = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Apply'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(0,$YAxis)
        }
        $BtnDefaultLayoutOverrideApply.Add_EnabledChanged({
           if ( $this.Enabled -eq $false ) {
                $this.FlatAppearance.BorderColor = 'LightGray'
                $this.FlatAppearance.BorderSize = 1
            }
            else {
                $this.FlatAppearance.BorderColor = 'LightBlue'
                $this.FlatAppearance.BorderSize = 2
            }
        })
        $BtnDefaultLayoutOverrideApply.Enabled = $false
        $BtnDefaultLayoutOverrideApply.Add_Click({Apply-Changes})
        $PnlDefaultLayoutOverride.Controls.Add($BtnDefaultLayoutOverrideApply)
    #endregion

    #region PanelStartLayoutCollection
        $PnlStartLayoutCollection = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlStartLayoutCollection)

        $YAxis = 10
        $LblTypeStartLayoutCollection = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
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

        $YAxis = 10
        $LblTypeStartLayout = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Type: StartLayout'
            AutoSize = $true
        }
        $PnlStartlayout.Controls.Add($LblTypeStartLayout)

        $YAxis = $YAxis + 30
        $LblStartLayoutGroupCellWidth = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'GroupCellWidth'
            AutoSize = $true
        }
        $PnlStartlayout.Controls.Add($LblStartLayoutGroupCellWidth)

        $YAxis = $YAxis + 20
        $CbxStartLayoutGroupCellWidth = New-Object System.Windows.Forms.ComboBox -Property @{
            DropDownStyle = 'DropDownList'
            Width         = 220
            Location      = New-Object System.Drawing.Point(0,$YAxis)
        }
        [void]$CBxStartLayoutGroupCellWidth.Items.Add('6')
        [void]$CBxStartLayoutGroupCellWidth.Items.Add('8')
        [void]$CBxStartLayoutGroupCellWidth.Items.Add('Off')
        $CBxStartLayoutGroupCellWidth.Add_SelectedIndexChanged({
            $BtnStartLayoutApply.Enabled = $true
        })
        $PnlStartlayout.Controls.Add($CBxStartLayoutGroupCellWidth)

        $YAxis = $YAxis + 35
        $BtnStartLayoutApply = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Apply'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(0,$YAxis)
        }
        $BtnStartLayoutApply.Add_EnabledChanged({
           if ( $this.Enabled -eq $false ) {
                $this.FlatAppearance.BorderColor = 'LightGray'
                $this.FlatAppearance.BorderSize = 1
            }
            else {
                $this.FlatAppearance.BorderColor = 'LightBlue'
                $this.FlatAppearance.BorderSize = 2
            }
        })
        $BtnStartLayoutApply.Enabled = $false
        $BtnStartLayoutApply.Add_Click({Apply-Changes})
        $PnlStartLayout.Controls.Add($BtnStartLayoutApply)
    #endregion

    #region PanelFolder
        $PnlFolder = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlFolder)

        $YAxis = 10
        $LblTypeFolder = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
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
            [void]$CBxFolderSize.Items.Add($SizeItem)
        }
        $CBxFolderSize.Add_SelectedIndexChanged({
            $BtnFolderApply.Enabled = $true
        })
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
        $NumFolderCol.Add_TextChanged({
            $BtnFolderApply.Enabled = $true
        })
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
        $NumFolderRow.Add_TextChanged({
            $BtnFolderApply.Enabled = $true
        })
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
        $TxtFolderName.Add_TextChanged({
            $BtnFolderApply.Enabled = $true
        })
        $PnlFolder.Controls.Add($TxtFolderName)

        $YAxis = $YAxis + 35
        $BtnFolderApply = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Apply'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(0,$YAxis)
        }
        $BtnFolderApply.Add_EnabledChanged({
           if ( $this.Enabled -eq $false ) {
                $this.FlatAppearance.BorderColor = 'LightGray'
                $this.FlatAppearance.BorderSize = 1
            }
            else {
                $this.FlatAppearance.BorderColor = 'LightBlue'
                $this.FlatAppearance.BorderSize = 2
            }
        })
        $BtnFolderApply.Enabled = $false
        $BtnFolderApply.Add_Click({Apply-Changes})
        $PnlFolder.Controls.Add($BtnFolderApply)

        $BtnFolderCancel = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Cancel'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(120,$YAxis)
        }
        $BtnFolderCancel.FlatAppearance.BorderColor = 'LightBlue'
        $BtnFolderCancel.FlatAppearance.BorderSize = 2
        $BtnFolderCancel.Visible = $false
        $BtnFolderCancel.Add_Click({
            $this.Visible = $false
            Enable-ControlsWhenNewItemDone
            Change-ListBoxRow
        })
        $PnlFolder.Controls.Add($BtnFolderCancel)
    #endregion

    #region PanelGroup
        $PnlGroup = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlGroup)

        $YAxis = 10
        $LblTypeGroup = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
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
        $TxtGroupName.Add_TextChanged({
            if ( $this.Text -ne '' ) {
                $BtnGroupApply.Enabled = $true
            }
            else {
                $BtnGroupApply.Enabled = $false
            }
        })
        $PnlGroup.Controls.Add($TxtGroupName)

        $YAxis = $YAxis + 35
        $BtnGroupApply = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Apply'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(0,$YAxis)
        }
        $BtnGroupApply.Add_EnabledChanged({
           if ( $this.Enabled -eq $false ) {
                $this.FlatAppearance.BorderColor = 'LightGray'
                $this.FlatAppearance.BorderSize = 1
            }
            else {
                $this.FlatAppearance.BorderColor = 'LightBlue'
                $this.FlatAppearance.BorderSize = 2
            }
        })
        $BtnGroupApply.Enabled = $false
        $BtnGroupApply.Add_Click({Apply-Changes})
        $PnlGroup.Controls.Add($BtnGroupApply)

        $BtnGroupCancel = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Cancel'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(120,$YAxis)
        }
        $BtnGroupCancel.FlatAppearance.BorderColor = 'LightBlue'
        $BtnGroupCancel.FlatAppearance.BorderSize = 2
        $BtnGroupCancel.Visible = $false
        $BtnGroupCancel.Add_Click({
            $this.Visible = $false
            Enable-ControlsWhenNewItemDone
            Change-ListBoxRow
        })
        $PnlGroup.Controls.Add($BtnGroupCancel)
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
            [void]$CBxTileSize.Items.Add($SizeItem)
        }
        $CBxTileSize.Add_SelectedIndexChanged({
            $BtnTileApply.Enabled = $true
        })
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
        $NumTileCol.Add_TextChanged({
            $BtnTileApply.Enabled = $true
        })
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
        $NumTileRow.Add_TextChanged({
            $BtnTileApply.Enabled = $true
        })
        $PnlTile.Controls.Add($NumTileRow)

        $YAxis = $YAxis + 30
        $LblAppUserModelID = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'AppUserModelID'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlTile.Controls.Add($LblAppUserModelID)

        $YAxis = $YAxis + 20
        $CBxTileAppUserModelID = New-Object System.Windows.Forms.ComboBox -Property @{
            Location       = New-Object System.Drawing.Point(0,$YAxis)
            DropDownHeight = 473
            DropDownWidth  = 1237            
            Width          = 220
        }
        Get-AllXPackages
        $CBxTileAppUserModelID.Add_TextChanged({
            if ( $this.Text -ne '' ) {
                $BtnTileApply.Enabled = $true
            }
            else {
                $BtnTileApply.Enabled = $false
            }
        })
        $PnlTile.Controls.Add($CBxTileAppUserModelID)        

        $YAxis = $YAxis + 35
        $BtnTileApply = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Apply'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(0,$YAxis)
        }
        $BtnTileApply.Add_EnabledChanged({
           if ( $this.Enabled -eq $false ) {
                $this.FlatAppearance.BorderColor = 'LightGray'
                $this.FlatAppearance.BorderSize = 1
            }
            else {
                $this.FlatAppearance.BorderColor = 'LightBlue'
                $this.FlatAppearance.BorderSize = 2
            }
        })
        $BtnTileApply.Enabled = $false
        $BtnTileApply.Add_Click({Apply-Changes})
        $PnlTile.Controls.Add($BtnTileApply)

        $BtnTileCancel = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Cancel'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(120,$YAxis)
        }
        $BtnTileCancel.FlatAppearance.BorderColor = 'LightBlue'
        $BtnTileCancel.FlatAppearance.BorderSize = 2
        $BtnTileCancel.Visible = $false
        $BtnTileCancel.Add_Click({
            $this.Visible = $false
            Enable-ControlsWhenNewItemDone
            Change-ListBoxRow
        })
        $PnlTile.Controls.Add($BtnTileCancel)
    #endregion

    #region PanelDesktopApplicationTile
        $PnlDesktopApplicationTile = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlDesktopApplicationTile)

        $YAxis = 10
        $LblTypeDAT = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Type: DesktopApplicationTile'
            AutoSize = $true
        }
        $PnlDesktopApplicationTile.Controls.Add($LblTypeDAT)

        $YAxis = $YAxis + 30
        $LblDATTileSize = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Size'
            AutoSize = $true
        }
        $PnlDesktopApplicationTile.Controls.Add($LblDATTileSize)

        $YAxis = $YAxis + 20
        $CBxDATSize = New-Object System.Windows.Forms.ComboBox -Property @{
            Location      = New-Object System.Drawing.Point(0,$YAxis)
            DropDownStyle = 'DropDownList'
            Width         = 220
        }
        $SizeItems = @('1x1','2x2','2x4','4x4')
        foreach ( $SizeItem in $SizeItems ) {
            [void]$CBxDATSize.Items.Add($SizeItem)
        }
        $CBxDATSize.Add_SelectedIndexChanged({
            $BtnDesktopApplicationTileApply.Enabled = $true
        })
        $PnlDesktopApplicationTile.Controls.Add($CBxDATSize)
        
        $YAxis = $YAxis + 30
        $LblDATColumn = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'Column'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlDesktopApplicationTile.Controls.Add($LblDATColumn)

        $YAxis = $YAxis + 20
        $NumDATCol = New-Object System.Windows.Forms.NumericUpDown -Property @{
            BackColor   = 'White'
            Maximum     = 5
            ReadOnly    = $true
            TextAlign   = 'Center'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $NumDATCol.Add_TextChanged({
            $BtnDesktopApplicationTileApply.Enabled = $true
        })
        $PnlDesktopApplicationTile.Controls.Add($NumDATCol)

        $YAxis = $YAxis + 30
        $LblDATRow = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'Row'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlDesktopApplicationTile.Controls.Add($LblDATRow)

        $YAxis = $YAxis + 20
        $NumDATRow = New-Object System.Windows.Forms.NumericUpDown -Property @{
            BackColor   = 'White'
            Maximum     = 20
            ReadOnly    = $true
            TextAlign   = 'Center'
            Width       = 220
            Location    = New-Object System.Drawing.Point(0,$YAxis)
        }
        $NumDATRow.Add_TextChanged({
            $BtnDesktopApplicationTileApply.Enabled = $true
        })
        $PnlDesktopApplicationTile.Controls.Add($NumDATRow)

        $YAxis = $YAxis + 30
        $LblDesktopApplicationTile = New-Object System.Windows.Forms.Label -Property @{
            Text     = 'DesktopApplicationLinkPath'
            AutoSize = $true
            Location = New-Object System.Drawing.Point(0,$YAxis)
        }
        $PnlDesktopApplicationTile.Controls.Add($LblDesktopApplicationTile)

        $YAxis = $YAxis + 20
        $CBxDAT = New-Object System.Windows.Forms.ComboBox -Property @{
            Location       = New-Object System.Drawing.Point(0,$YAxis)
            DropDownHeight = 473
            DropDownWidth  = 1237
            Width          = 220
        }
        Get-AllLinks
        $CBxDAT.Add_TextChanged({
            if ( $this.Text -ne '' ) {
                $BtnDesktopApplicationTileApply.Enabled = $true
            }
            else {
                $BtnDesktopApplicationTileApply.Enabled = $false
            }
        })
        $PnlDesktopApplicationTile.Controls.Add($CBxDAT)

        $YAxis = $YAxis + 35
        $BtnDesktopApplicationTileApply = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Apply'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(0,$YAxis)
        }
        $BtnDesktopApplicationTileApply.Add_EnabledChanged({
           if ( $this.Enabled -eq $false ) {
                $this.FlatAppearance.BorderColor = 'LightGray'
                $this.FlatAppearance.BorderSize = 1
            }
            else {
                $this.FlatAppearance.BorderColor = 'LightBlue'
                $this.FlatAppearance.BorderSize = 2
            }
        })
        $BtnDesktopApplicationTileApply.Enabled = $false
        $BtnDesktopApplicationTileApply.Add_Click({Apply-Changes})
        $PnlDesktopApplicationTile.Controls.Add($BtnDesktopApplicationTileApply)

        $BtnDesktopApplicationTileCancel = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Cancel'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(120,$YAxis)
        }
        $BtnDesktopApplicationTileCancel.FlatAppearance.BorderColor = 'LightBlue'
        $BtnDesktopApplicationTileCancel.FlatAppearance.BorderSize = 2
        $BtnDesktopApplicationTileCancel.Visible = $false
        $BtnDesktopApplicationTileCancel.Add_Click({
            $this.Visible = $false
            Enable-ControlsWhenNewItemDone
            Change-ListBoxRow
        })
        $PnlDesktopApplicationTile.Controls.Add($BtnDesktopApplicationTileCancel)
    #endregion

    #region PanelTaskbarLayoutCollection
        $PnlTaskbarLayoutCollection = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlTaskbarLayoutCollection)

        $YAxis = 10
        $LblTypeStartLayoutCollection = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'Type: TaskbarLayoutCollection'
            AutoSize = $true
        }
        $PnlTaskbarLayoutCollection.Controls.Add($LblTypeStartLayoutCollection)

        $YAxis = $YAxis + 30
        $LblTaskbarLayoutCollectionPinListPlacement = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text     = 'PinListPlacement'
            AutoSize = $true
        }
        $PnlTaskbarLayoutCollection.Controls.Add($LblTaskbarLayoutCollectionPinListPlacement)

        $YAxis = $YAxis + 20
        $CbxTaskbarLayoutCollectionPinListPlacement = New-Object System.Windows.Forms.ComboBox -Property @{
            DropDownStyle = 'DropDownList'
            Width         = 220
            Location      = New-Object System.Drawing.Point(0,$YAxis)
        }
        [void]$CBxTaskbarLayoutCollectionPinListPlacement.Items.Add('Replace')
        [void]$CBxTaskbarLayoutCollectionPinListPlacement.Items.Add('Off')
        $CBxTaskbarLayoutCollectionPinListPlacement.Add_SelectedIndexChanged({
            $BtnTaskbarLayoutCollectionApply.Enabled = $true
        })
        $PnlTaskbarLayoutCollection.Controls.Add($CbxTaskbarLayoutCollectionPinListPlacement)

        $YAxis = $YAxis + 35
        $BtnTaskbarLayoutCollectionApply = New-Object System.Windows.Forms.Button -Property @{
            Text      = 'Apply'
            FlatStyle = 0
            Width     = 100
            Location  = New-Object System.Drawing.Point(0,$YAxis)
        }
        $BtnTaskbarLayoutCollectionApply.Add_EnabledChanged({
           if ( $this.Enabled -eq $false ) {
                $this.FlatAppearance.BorderColor = 'LightGray'
                $this.FlatAppearance.BorderSize = 1
            }
            else {
                $this.FlatAppearance.BorderColor = 'LightBlue'
                $this.FlatAppearance.BorderSize = 2
            }
        })
        $BtnTaskbarLayoutCollectionApply.Enabled = $false
        $BtnTaskbarLayoutCollectionApply.Add_Click({Apply-Changes})
        $PnlTaskbarLayoutCollection.Controls.Add($BtnTaskbarLayoutCollectionApply)
    #endregion

    #region PanelNewItem
        $PnlNewItem = New-Object System.Windows.Forms.Panel -Property @{
            Size     = New-Object Drawing.Size @(220,666)
            Location = New-Object System.Drawing.Point(10,27)
        }
        $FrmMain.Controls.Add($PnlNewItem)

        $YAxis = 10
        $LblType = New-Object System.Windows.Forms.Label -Property @{
            Location = New-Object System.Drawing.Point(0,$YAxis)
            Text = 'Type:'
            Autosize = $true
        }
        $PnlNewItem.Controls.Add($LblType)
        
        $CBxType = New-Object System.Windows.Forms.ComboBox -Property @{
            Location = New-Object System.Drawing.Point(50,$YAxis)
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

if ( $DefaultContent -ne $Null ) {
    if ( $DefaultContent -like '*<CustomTaskbarLayoutCollection*' ) {
        $menuOptTaskbar.Checked = $true
    }
    else {
        $menuOptTaskbar.Checked = $false
    }
    foreach ( $Line in $DefaultContent ) {
        [void]$LBxMain.Items.Add($Line)
    }
}
$LBxMain.SelectedIndex = 0

[void]$FrmMain.ShowDialog()