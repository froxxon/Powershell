$global:FileDir = ''
$global:policies = @()

if ($psise) {
    $XamlFile = "$(Split-Path $psise.CurrentFile.FullPath)\MainWindow.xaml"
    $ImgSource =  "$(Split-Path $psise.CurrentFile.FullPath)\images\icon.png"
    $PolicyDir = "$(Split-Path $psise.CurrentFile.FullPath)\ADMX"
}
else {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName System.Windows.Forms
    $t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);' # Part of the process to hide the Powershellwindow if it is not run through ISE
    Add-Type -name win -member $t -namespace native # Part of the process to hide the Powershellwindow if it is not run through ISE
    [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0) # This hides the Powershellwindow in the background if ISE isn't running
    $XamlFile =  "$($PSScriptRoot)\MainWindow.xaml"
    $ImgSource =  "$($PSScriptRoot)\images\icon.png"
}
#region XAML
    $inputXML = Get-Content $xamlFile -Raw
    $inputXML = $inputXML -replace '\s{1}[\w\d_-]+="{x:Null}"',''
    $inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
    $inputXML = $inputXML -replace 'TextChanged="[\w\d-]+\w"',''
    $inputXML = $inputXML -replace 'SelectionChanged="[\w\d-]+\w"',''
    $inputXML = $inputXML -replace ' Selected="[\w\d-]+\w"',''
    $inputXML = $inputXML -replace ' Click="[\w\d-]+"',''
    $inputXML = $inputXML -replace 'Checked="CheckBox_Checked" ',''
    $inputXML = $inputXML -replace '(?<=Source=[\s]?\")[a-z]{1}?\:?[\\\.\w/]+',$($ImgSource.replace('\','/'))

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

Function Open-Dialog {
    $OpenDialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Filter           = "ADMX files (*.admx)|*.admx"
        InitialDirectory = "$env:windir\PolicyDefinitions"
        Title            = "Select which ADMX file to display"
    }
    $Result = $OpenDialog.ShowDialog()
    if ( $Result -eq 'OK' ) {
        if ( $OpenDialog.FileName -match ".admx|.ADMX" ) {
            $txtFile.Text = $OpenDialog.SafeFileName
            $cmbLanguage.Items.Clear()
            $global:FileDir = $OpenDialog.FileName -replace $OpenDialog.SafeFileName,''
            foreach ( $lang in (get-childitem -Path $FileDir -Include $OpenDialog.SafeFileName.Replace('admx','adml') -Recurse).Directory.Name ) {
                $cmbLanguage.Items.Add($lang)
            }
            $cmbLanguage.SelectedIndex = 0
            if ( $cmbLanguage.Items.Count -gt 0 ) {
                $cmbLanguage.IsEnabled = $true
                $btnView.isEnabled = $true
                $lblNoLang.Visibility = 'Hidden'
            }
            else {
                $cmbLanguage.IsEnabled = $false
                $btnView.isEnabled = $false
                $lblNoLang.Visibility = 'Visible'
            }
        }
    }
}

Function Open-TestFile {
    $txtFile.Text = "appv.admx"
    $cmbLanguage.Items.Clear()
    $global:FileDir = "C:\Windows\PolicyDefinitions\"
    $cmbLanguage.Items.Add('en-us') | out-null
    $cmbLanguage.SelectedIndex = 0
    
    [xml]$data = Get-Content "$FileDir\$($txtFile.Text)" -Encoding UTF8
    [xml]$lang = Get-Content "$FileDir$($cmbLanguage.SelectedValue)\$($txtFile.Text.Replace(".admx",".adml"))" -Encoding UTF8
    $policyText = $lang.policyDefinitionResources.resources.stringTable.ChildNodes
    $Categories = Get-Categories
    $global:Policies = Get-Policies
    Build-TreeView
    $btnExpand.Visibility = 'Visible'
    $btnCollapse.Visibility = 'Visible'
    $trvPolicies.Visibility = 'Visible'
    $grdInfo.Visibility = 'Visible'
}

function Get-Categories {
    $categories = @()
    foreach ( $cat in $data.PolicyDefinitions.Categories.ChildNodes ) {
        if ( $cat.Name -ne "#comment" -or $cat -ne $null ) {
            $category = ($policyText | Where-Object id -eq $cat.displayName.Substring(9).TrimEnd(')') -ErrorAction SilentlyContinue ).'#text'
            try {
                $explainText = $null
                $explainText = ($policyText | Where-Object id -eq $cat.explainText.Substring(9).TrimEnd(')') ).'#text' 
            }
            catch {}
            $parentCat =  ($policyText | Where-Object id -eq $cat.parentCategory.ref -ErrorAction SilentlyContinue ).'#text'
            if ( !$parentCat ) {
                $parentCat = ($policyText | Where-Object id -eq $cat.displayName.Substring(9).TrimEnd(')') -ErrorAction SilentlyContinue ).'#text'
            }

            if ( !$cat.parentCategory.ref ) {
                $Root = $true
            }
            else {
                $Root = $false
            }

            $catobj = New-Object System.Object
            $catobj | Add-Member -type NoteProperty -name Category -Value $category
            $catobj | Add-Member -type NoteProperty -name CategoryID -Value $cat.name
            $catobj | Add-Member -type NoteProperty -name ExplainText -Value $ExplainText
            $catobj | Add-Member -type NoteProperty -name ParentCategory -Value $parentCat
            $catobj | Add-Member -type NoteProperty -name ParentCategoryID -Value $cat.parentCategory.ref
            $catobj | Add-Member -type NoteProperty -name Root -Value $Root
            $categories += $catobj
        }
    }
    return $categories
}

function Get-Policies {
    $policies = @()
    $data.PolicyDefinitions.Policies.ChildNodes | ForEach-Object {
    $policy = $_
        if ($policy -ne $null) {
            if ($policy.Name -ne "#comment") {
                $displayName = ($policyText | Where-Object { $_.id -eq $policy.displayName.Substring(9).TrimEnd(')') }).'#text' 
                $explainText = ($policyText | Where-Object { $_.id -eq $policy.explainText.Substring(9).TrimEnd(')') }).'#text' 
    
                if ($policy.SupportedOn.ref.Contains(":")) {        
                    $source=$policy.SupportedOn.ref.Split(":")[0]
                    $valueName=$policy.SupportedOn.ref.Split(":")[1]
                    [xml]$adml = Get-Content "$FileDir$($cmbLanguage.SelectedValue)\$($txtFile.Text.Replace(".admx",".adml"))"
                    $resourceText= $adml.policyDefinitionResources.resources.stringTable.ChildNodes
                    $supportedOn=($resourceText | Where-Object { $_.id -eq $valueName }).'#text'
                }
                else {
                    $supportedOnID = ($data.policyDefinitions.supportedOn.definitions.ChildNodes | Where-Object { $_.Name -eq $policy.supportedOn.ref }).DisplayName
                    $supportedOn = ($policyText | Where-Object { $_.id -eq $supportedOnID.Substring(9).TrimEnd(')') }).'#text'
                }
        
                if ($policy.parentCategory.ref.Contains(":")) {
                    $source=$policy.SupportedOn.ref.Split(":")[0]
                    $valueName=$policy.SupportedOn.ref.Split(":")[1]
                    [xml]$adml = Get-Content "$FileDir$($cmbLanguage.SelectedValue)\$($txtFile.Text.Replace(".admx",".adml"))"
                    $resourceText= $adml.policyDefinitionResources.resources.stringTable.ChildNodes
                    $parentCategoryID=($resourceText | Where-Object { $_.id -eq $valueName } -ErrorAction SilentlyContinue ).Name
                    $parentCategory=($resourceText | Where-Object { $_.id -eq $valueName } -ErrorAction SilentlyContinue ).'#text'
                } 
                else {
                    $parentCategoryID =  ($data.policyDefinitions.categories.ChildNodes | Where-Object { $_.Name -eq $policy.parentCategory.ref } -ErrorAction SilentlyContinue ).Name
                    $parentCategory =  ($policyText | Where-Object { $_.id -eq $parentCategoryID } -ErrorAction SilentlyContinue ).'#text'
                }

                [string]$Elements = ''
                foreach ( $node in $policy.elements.ChildNodes ) {
                    $text = "Type: $($node.Name)"
                    foreach ( $attrib in $node.Attributes ) {
                        $text = "$text $($attrib.Name): $($attrib.value)"
                    }
                    if ( $text -notmatch "#comment" ) {
                        $text = "$text`n"
                        $Elements = "$Elements$text"
                    }
                }
                $Elements

                $polobj = New-Object System.Object
                $polobj | Add-Member -type NoteProperty -name ADMX -Value $file
                $polobj | Add-Member -type NoteProperty -name ParentCategoryName -Value $parentCategory
                $polobj | Add-Member -type NoteProperty -name ParentCategoryID -Value $policy.parentCategory.ref
                $polobj | Add-Member -type NoteProperty -name Name -Value $Policy.name
                $polobj | Add-Member -type NoteProperty -name DisplayName -Value $displayname
                $polobj | Add-Member -type NoteProperty -name Class -Value $Policy.class
                $polobj | Add-Member -type NoteProperty -name ExplainText -Value $explainText
                $polobj | Add-Member -type NoteProperty -name SupportedOn -Value $SupportedOn
                $polobj | Add-Member -type NoteProperty -name Key -Value $Policy.key
                $polobj | Add-Member -type NoteProperty -name ValueName -Value $Policy.ValueName
                $polobj | Add-Member -type NoteProperty -name Elements -Value $Elements
                $polobj | Add-Member -type NoteProperty -name EnabledValue -Value $Policy.EnabledValue.ChildNodes.value
                $polobj | Add-Member -type NoteProperty -name DisabledValue -Value $Policy.DisabledValue.ChildNodes.value
                $policies += $polobj
            }
        }
    }
    return $policies
}

function Add-Node { 
        param ( 
            [Parameter(Mandatory)]
            [object]$Node,
            [Parameter(Mandatory)]
            [string]$DisplayName,
            [string]$Tag,
            [switch]$Policy
        ) 

        $newNode = new-object System.Windows.Controls.TreeViewItem
        $newNode.Header = $DisplayName
        $newNode.Tag = $Tag
        if ( $Policy ) {
            $newNode.Tooltip = $DisplayName
            $lblPolCount.Content = $lblPolCount.Content + 1
        }
        else {
            $lblCatCount.Content = $lblCatCount.Content + 1
        }
        $Node.Items.Add($newNode) | Out-Null 
        $Node.IsExpanded = $true
        return $newNode
} 

function Get-NextLevel {
    param (
        [Parameter(Mandatory)]
        [object]$Node,
        [Parameter(Mandatory)]
        [string]$DisplayName,
        [string]$Tag
    )
    $subcats = $Categories | where ParentCategoryId -eq $Tag

    if ($subcats -eq $null) {
        if ( ($trvPolicies.Items.Header -notcontains $($DisplayName))) {# -or $trvPolicies.Items.Header -notcontains $($Tag)) -and (($trvPolicies.Items.Tag -notcontains $($Tag) -or $trvPolicies.Items.Tag -notcontains $trvPolicies.Items[0].Tag ))) {
            $CurrentNode = Add-Node -Node $Node -DisplayName $DisplayName -Tag $Tag
            foreach ( $pol in $policies | where ParentCategoryId -eq $CurrentNode.Tag | sort DisplayName ) {
                Add-Node -Node $CurrentNode -DisplayName $pol.DisplayName -Tag $pol.ParentCategoryID -policy
            }
        }
        else {
            # Skip to create duplicate top node
            foreach ( $pol in $policies | where ParentCategoryId -eq $Node.Tag | sort DisplayName ) {
                Add-Node -Node $Node -DisplayName $pol.DisplayName -Tag $pol.ParentCategoryID -policy
            }
        }
    }
    else {
        if ( ($trvPolicies.Items.Header -notcontains $($DisplayName) -or $trvPolicies.Items.Header -notcontains $($Tag)) -and (($trvPolicies.Items.Tag -notcontains $($Tag) -or $trvPolicies.Items.Tag -notcontains $trvPolicies.Items[0].Tag ))) {
            $CurrentNode = Add-Node -Node $Node -DisplayName $DisplayName -Tag $Tag
            foreach ( $pol in $policies | where ParentCategoryId -eq $CurrentNode.Tag | sort DisplayName ) {
                Add-Node -Node $CurrentNode -DisplayName $pol.DisplayName -Tag $pol.ParentCategoryID -policy
            }
        }
        else {
            foreach ( $pol in $policies | where ParentCategoryId -eq $Node.Tag | sort DisplayName ) {
                Add-Node -Node $Node -DisplayName $pol.DisplayName -Tag $pol.ParentCategoryID -policy
            }
        }        
        foreach ( $subcat in $subcats ) {
            Get-NextLevel -Node $Node -DisplayName $subcat.Category -Tag $subcat.CategoryID
        }
    }
}

function Build-TreeView { 
    $trvPolicies.Items.Clear()
    $lblCatCount.Content = 0
    $lblPolCount.Content = 0
    if ( $categories.count -ge 1 ) {
        if ( ($Categories | where Root -eq $true).count -gt 0 ) {
            foreach ( $cat in $Categories | where Root -eq $true ) {
                $treeNodes = New-Object System.Windows.Controls.TreeViewItem 
                $treeNodes.Header = $cat.category
                $treeNodes.Tag = $cat.categoryid
                $trvPolicies.Items.Add($treeNodes) | out-null
                $lblCatCount.Content = $lblCatCount.Content + 1
                $subcats = Get-NextLevel -Node $treeNodes -DisplayName $cat.category -Tag $cat.categoryid
            }
        }
        else {
            foreach ( $cat in $Categories | where Category -eq $categories[0].Category ) {
                $treeNodes = New-Object System.Windows.Controls.TreeViewItem 
                $treeNodes.Header = $cat.category
                $treeNodes.Tag = $cat.categoryid
                $trvPolicies.Items.Add($treeNodes) | out-null
                $lblCatCount.Content = $lblCatCount.Content + 1
                $subcats = Get-NextLevel -Node $treeNodes -DisplayName $cat.category -Tag $cat.categoryid
            }
        }
        $lblNoCategories.Visibility = 'Hidden'
    }
    else {
        foreach ( $pol in $policies | sort DisplayName ) {
            $treeNodes = New-Object System.Windows.Controls.TreeViewItem 
            $treeNodes.Header = $pol.DisplayName
            $treeNodes.Tooltip = $pol.DisplayName
            $treeNodes.Tag = $pol.DisplayName
            $trvPolicies.Items.Add($treeNodes) | out-null
            $lblPolCount.Content = $lblPolCount.Content + 1
            $lblNoCategories.Visibility = 'Visible'
        }
    }
}

$trvPolicies.Add_SelectedItemChanged({
    [array]$item = $global:policies | where { $_.DisplayName -like $trvPolicies.SelectedItem.Header -and $_.ParentCategoryID -eq $trvPolicies.SelectedItem.Tag }
    $SupportedOn = ''
    if ( $item.SupportedOn -match "\w+" ) {
        $SupportedOn = "`n`nSupported on:`n$($item.SupportedOn)"
    }
    $txtExplainText.Text = "$($item.ExplainText)$SupportedOn"
    $txtKey.Text = $item.Key
    $txtValueName.Text = $item.ValueName
    $txtClass.Text = $item.Class
    $txtElements.Text = $($item.Elements)
    $txtDisabledValue.Text = $item.DisabledValue
    $txtEnabledValue.Text = $item.EnabledValue

    if ( $txtExplainText.Text ) {
        $lblInfoExplainText.Visibility = 'Visible'
        $txtExplainText.Visibility = 'Visible'
    }
    else {
        $lblInfoExplainText.Visibility = 'Collapsed'
        $txtExplainText.Visibility = 'Collapsed'
    }

    if ( $txtKey.Text ) {
        $lblInfoKey.Visibility = 'Visible'
        $txtKey.Visibility = 'Visible'
    }
    else {
        $lblInfoKey.Visibility = 'Collapsed'
        $txtKey.Visibility = 'Collapsed'
    }

    if ( $txtValueName.Text ) {
        $lblInfoValueName.Visibility = 'Visible'
        $txtValueName.Visibility = 'Visible'
    }
    else {
        $lblInfoValueName.Visibility = 'Collapsed'
        $txtValueName.Visibility = 'Collapsed'
    }

    if ( $txtClass.Text ) {
        $lblInfoClass.Visibility = 'Visible'
        $txtClass.Visibility = 'Visible'
    }
    else {
        $lblInfoClass.Visibility = 'Collapsed'
        $txtClass.Visibility = 'Collapsed'
    }

    if ( $txtDisabledValue.Text ) {
        $lblInfoDisabledValue.Visibility = 'Visible'
        $txtDisabledValue.Visibility = 'Visible'
    }
    else {
        $lblInfoDisabledValue.Visibility = 'Collapsed'
        $txtDisabledValue.Visibility = 'Collapsed'
    }

    if ( $txtEnabledValue.Text ) {
        $lblInfoEnabledValue.Visibility = 'Visible'
        $txtEnabledValue.Visibility = 'Visible'
    }
    else {
        $lblInfoEnabledValue.Visibility = 'Collapsed'
        $txtEnabledValue.Visibility = 'Collapsed'
    }

    if ( $txtElements.Text ) {
        $lblInfoElements.Visibility = 'Visible'
        $txtElements.Visibility = 'Visible'
    }
    else {
        $lblInfoElements.Visibility = 'Collapsed'
        $txtElements.Visibility = 'Collapsed'
    }

})
$btnFile.Add_Click({ Open-Dialog })
$btnView.Add_Click({
    [xml]$data = Get-Content "$FileDir\$($txtFile.Text)" -Encoding UTF8
    [xml]$lang = Get-Content "$FileDir$($cmbLanguage.SelectedValue)\$($txtFile.Text.Replace(".admx",".adml"))" -Encoding UTF8
    $policyText = $lang.policyDefinitionResources.resources.stringTable.ChildNodes
    $Categories = Get-Categories
    $global:Policies = Get-Policies
    Build-TreeView
    $btnExpand.Visibility = 'Visible'
    $btnCollapse.Visibility = 'Visible'
    $trvPolicies.Visibility = 'Visible'
    $grdInfo.Visibility = 'Visible'
})

$btnCollapse.Add_Click({
    foreach ( $item in $trvPolicies.Items ) {
        $item.isexpanded = $false
    }
})

$btnExpand.Add_Click({
    foreach ( $item in $trvPolicies.Items ) {
        $item.isexpanded = $true
    }
})

$btnExpand.Visibility = 'Hidden'
$btnCollapse.Visibility = 'Hidden'
$trvPolicies.Visibility = 'Hidden'
$grdInfo.Visibility = 'Hidden'

#open-testfile
$Form.ShowDialog() | out-null