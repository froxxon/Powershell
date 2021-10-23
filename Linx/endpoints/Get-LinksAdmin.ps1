param ( $RequestArgs )

#region Get user information
    $CurrentUser = $null
    $CurrentUser = $($context.User.Identity.Name -replace ("$($ScriptVariables.Domain)\\",''))
    
    if ( $ScriptVariables.AllowPersonalTheme -eq $true ) {
        $PersonalCSSLink = (Get-ChildItem ($ScriptVariables.PersonalPath + '\' + $CurrentUser + '-*.css_link')).BaseName
    }
    else { $PersonalCSSLink = $null }
    if ( $PersonalCSSLink ) { $CSS = Get-Content ($ScriptVariables.ScriptPath + 'style\' + ($PersonalCSSLink -replace "$CurrentUser-",'') + '.css' ) }
    else { $CSS = Get-Content $ScriptVariables.CSSpath }
    
    $HTML = Get-HTMLHead $CSS
    $MainUser = Get-MainUser $CurrentUser
    if ( !$MainUser ) {
        $HTML += '<br>' + $ScriptVariables.Text.AccessDenied 
        return $HTML
    }
#endregion
#region Get additional rights in Linx
    foreach ( $group in $EditMembers ) {
        if ( $group -in $MainUser.memberof -or $group -eq $MainUser.distinguishedname ) {
            $Edit = '<th width="5%"></th>'
            $EditLinks += '<a href="' + $ScriptVariables.ServerURL + '/">' + $ScriptVariables.Text.StartPage + '</a><a href="' + $ScriptVariables.ServerURL + '/Admin">' + $ScriptVariables.Text.AdmOverview + '</a><a href="' + $ScriptVariables.ServerURL + '/Admin?Log">' + $ScriptVariables.Text.AdmLog + '</a>'
        }
    }
    foreach ( $group in $AdminMembers ) {
        if ( $group -in $MainUser.memberof -or $group -eq $MainUser.distinguishedname ) {
            $Edit = '<th width="5%"></th>'
            $Admin = "<th></th>"
            $AdminLinks += '<a href="' + $ScriptVariables.ServerURL + '/Admin?CSS">CSS</a><a href="' + $ScriptVariables.ServerURL + '/Admin?Text">Text</a><a href="' + $ScriptVariables.ServerURL + '/Admin?Regex">Regex</a><a href="' + $ScriptVariables.ServerURL + '/Admin?Settings">' + $ScriptVariables.Text.AdmSettings + '</a>'
        }
    }
#endregion
#region Get Links
    $Links      = Import-CSV $ScriptVariables.LinksFilePath -Delimiter $ScriptVariables.CSVDelimiter
    $Categories = @()
#endregion
$SelectThemes = Get-ThemeOptions $CurrentUser

$HTML += '<header>'
$HTML += '<nav align="left"><a href="' + $ScriptVariables.ServerURL + '/Admin?new">' + $ScriptVariables.Text.AdmNewLink + '</a>' + $EditLinks + $AdminLinks + '</nav>'
if ( $ScriptVariables.AllowPersonalTheme -eq $true ) {
    $HTML += '<div><select name="Theme" style="width: 200px;" class="SelTheme" onChange="SetTheme(this.value)">' + $SelectThemes + '</select></div>'
}
$HTML += '</header>'
$HTML += '<table id="main" align="center">'
$HTML += '<tr><td>'
$HTML += '<table align="center" class="innerTable">'
if ( !$RequestArgs ) {
    if ( ! $Edit ) { exit }
    $HTML += @"
    <tr><td><input type="text" id="inputFilter" onkeyup="filterFunctionMultiTables(5)" placeholder="$($ScriptVariables.Text.FilterText)" autofocus></td></tr>
    <tr><td>
      <table align="center" data-name="mytable" id="filteredTable" class="hover innerTable">
        <thead><tr><th align="left" width="30%" onclick="sortTableByAREF(0)">$($ScriptVariables.Text.LblName)</th><th width="30%" onclick="sortTable(1)">$($ScriptVariables.Text.LblDescription)</th><th width="15%" onclick="sortTable(2)">$($ScriptVariables.Text.LblCategory)</th><th width="15%" onclick="sortTable(3)">$($ScriptVariables.Text.LblRole)</th><th width="5%" onclick="sortTable(4)">$($ScriptVariables.Text.LblShowLink)</th>$Edit</tr></thead>
          <tbody>
"@
    foreach ( $Link in $Links | Sort-Object Name -Descending ) {
        if ( $Link.Disabled -match "^true$" ) {
            $Enabled = '<font class="admlinkdisabled">' + $ScriptVariables.Text.IsNo + '</font>'
        }
        else { $Enabled = '<font class="admlinkenabled">' + $ScriptVariables.Text.IsYes + '</font>' }
        $EditColumn = '<td><a href="' + $ScriptVariables.ServerURL + '/Admin?' + $Link.ID + '">' + $ScriptVariables.Text.Edit + '</a></td>'
        if ( $Link.Role -ne '' ) { $RoleTips = '<br><br><b>' + $ScriptVariables.Text.DisplayFor + ':</b><br>' + $($Link.Role -replace ',','<br>') }
        else { $RoleTips = '<br><br><b>' + $ScriptVariables.Text.DisplayFor + ':</b><br>' + $ScriptVariables.Text.Everyone }
        if ( $Link.Tags -ne '' ) { $TagTips = '<br><br><b>' + $ScriptVariables.Text.LblTags + ':</b><br>' + $($Link.Tags) }
        else { $TagTips = '<br><br><b>' + $ScriptVariables.Text.LblTags + ':</b><br><font class="tooltipempty"><i>-</i></font>' }
        if ( $Link.Contact -ne '' ) { $ContactTips = '<br><br><b>' + $ScriptVariables.Text.LblContact + ':</b><br>' + $($Link.Contact) }
        else { $ContactTips = '<br><br><b>' + $ScriptVariables.Text.LblContact + ':</b><br><font class="tooltipempty"><i>-</i></font>' }
        if ( $Link.Notes -ne '' ) { $NotesTips = '<br><br><b>' + $ScriptVariables.Text.LblNotes + ':</b><br>' + $($Link.Notes) }
        else { $NotesTips = '<br><br><b>' + $ScriptVariables.Text.LblNotes + ':</b><br><font class="tooltipempty"><i>-</i></font>' }
        $TooltipText = "$RoleTips$TagTips$ContactTips$NotesTips"
        $HTML += '<tr><td width="10%" align="left"><div class="tooltip"><a href="' + $Link.URL + '" target="_blank"/>' + $Link.Name + '</a><span class="tooltiptext">' + $TooltipText + '</span></div></td><td>' + $Link.Description + '</td><td>' + $Link.Category + '</td><td>' + $Link.Role + '</td><td>' + $($Enabled) + '</td><td class="hiddenColumn">' + $Link.Name + $Link.Tags + '</td>' + $EditColumn + '</tr>'
    }
    $HTML += '</tbody>'
    $HTML += '</table>'
    $HTML += '</td></tr>'
}
elseif ( $RequestArgs -match '^Log$' ) {
    if ( ! $Edit ) { exit }
    $HTML += @"
    <tr><td><input type="text" id="inputFilter" class="inputFilter" onkeyup="filterFunctionLogTable()" placeholder="$($ScriptVariables.Text.FilterText)" autofocus></td></tr>
    <tr><td>
      <table align="center" data-name="mytable" id="filteredTable" class="hover innerTable">
        <tr><th>$($ScriptVariables.LogRows) $($ScriptVariables.Text.LogText):</th></tr>
"@
    [array]$Logs = Get-Content "$($ScriptVariables.LogChangesPath)" -tail $ScriptVariables.LogRows -Encoding $($ScriptVariables.Charset -replace '-','') | Select -Skip 1 | sort -Descending
    foreach ( $Log in $Logs ) {
        if ( $Log -match " created " ) { $Log = $Log -replace (' created ','<font class="logobjCreated"> <b>created</b> </font>') }
        elseif ( $Log -match " modified " ) { $Log = $Log -replace (' modified ','<font class="logobjModified"> <b>modified</b> </font>') }
        elseif ( $Log -match " removed " ) { $Log = $Log -replace (' removed ','<font class="logobjRemoved"> <b>removed</b> </font>') }
        $HTML += '<tr><td align="left">' + $Log + '</td></tr>'
    }
    $HTML += '</table>'
    $HTML += '</td></tr>'
}
elseif ( $RequestArgs -match '^[0-9]{8}$' ) {
    if ( ! $Edit ) { exit }
    $Link = Select-String -Path $ScriptVariables.LinksFilePath -Pattern $RequestArgs -Encoding $($ScriptVariables.Charset -replace '-','') | Select-Object -ExpandProperty Line | convertfrom-csv -Delimiter $ScriptVariables.CSVDelimiter -Header $((Get-Content $ScriptVariables.LinksFilePath -First 1).Split($ScriptVariables.CSVDelimiter))
    $Categories = @{}
    $($Links.Category | Sort-Object -Unique).ForEach({
        $currCat = $_
        $Categories.Add($currCat,@{ 
            ItemCount = $( $Links.Category | Where { $_ -match $currCat }).Count
            Short = $($currCat -Replace "$($ScriptVariables.Regex.RgxShortCategory)","")
        })
    })
    $SelectCats = '<option value=""></option>'
    foreach ( $Cat in $Categories.Keys | Sort ) {
        $SelectCats += '<option value="' + $Cat + '">' + $Cat + '</option>'
    }
    if ( $Link.Disabled -match "^true$" ) {
        $Enabled = ''
    }
    else { $Enabled = 'checked' }
    $HTML += '<tr><td>'
    $HTML += '<table class="innerTable">'
    $HTML += '<form name="SaveLink" action="/ManageLink" method="POST" enctype="multipart/form-data" accept-charset="' + $ScriptVariables.Charset + '">'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblName + '</td><td width="100%"><input type=text name="Name" value="' + $Link.Name + '" class="inputFilter" placeholder="' + $ScriptVariables.Text.PhdName + '" maxlength="128" pattern="' + $ScriptVariables.Regex.RgxName + '" required></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblURL + '</td><td><input type=url name="URL" value="' + $Link.URL + '" class="inputFilter" placeholder="' + $ScriptVariables.Text.PhdURL + '" required></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblDescription + '</td><td><input type=text value="' + $Link.Description + '" name="Description" class="inputFilter" placeholder="' + $ScriptVariables.Text.PhdDescription + '" pattern="' + $ScriptVariables.Regex.RgxDescription + '"></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblCategory + '</td><td><input type="text" value="' + $Link.Category + '" class="inputFilter" name="Category" list="Categories" pattern="' + $ScriptVariables.Regex.RgxCategory + '" placeholder="' + $ScriptVariables.Text.PhdCategory + '" required/><datalist id="Categories">' + $SelectCats + '</datalist></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblRole + '</td><td><input type="text" value="' + $Link.Role + '" class="inputFilter" name="Role" pattern="' + $ScriptVariables.Regex.RgxRole + '" placeholder="' + $ScriptVariables.Text.PhdRole + '"/></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblTags + '</td><td><input type="text" value="' + $Link.Tags + '" class="inputFilter" name="Tags" pattern="' + $ScriptVariables.Regex.RgxTags + '" placeholder="' + $ScriptVariables.Text.PhdTags + '"/></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblContact + '</td><td><input type="text" value="' + $Link.Contact + '" class="inputFilter" name="Contact" pattern="' + $ScriptVariables.Regex.RgxContact + '" placeholder="' + $ScriptVariables.Text.PhdContact + '"/></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblNotes + '</td><td><input type="text" value="' + $Link.Notes + '" class="inputFilter" name="Notes" pattern="' + $ScriptVariables.Regex.RgxNotes + '" placeholder="' + $ScriptVariables.Text.PhdNotes + '"/></td></tr>'
    $HTML += '<tr><td></td><td align="right"><label for="Enabled">' + $ScriptVariables.Text.LblShowLink + '</label><input type=checkbox name="Enabled" value="checked" ' + $Enabled + '></td></tr>'
    $HTML += '<input hidden name="Type" value="update" type="text"/>'
    $HTML += '<input hidden name="ID" value="' + $RequestArgs + '" type="text"/>'
    $HTML += '</form>'
    $HTML += '</table>'
    $HTML += '</td></tr>'
    $HTML += '<table class="innertable">'
    $HTML += '<tr><td><a title="' + $ScriptVariables.Text.RemoveLinkWarning + '" href="/Admin?remove' + $RequestArgs + '" align="center" class="removelink">' + $ScriptVariables.Text.RemoveLink + '</a></td><td align="right"><button class="btn" type="button" onclick="window.location.href=`/`">' + $ScriptVariables.Text.CancelBtn + '</button><input class="btn" type="Submit" value="' + $ScriptVariables.Text.UpdateBtn + '"></td></tr>'
    $HTML += '</table>'
    $HTML += '</td></tr>'
}
elseif ( $RequestArgs -match '^new$' ) {
    $Categories = @{}
    $($Links.Category | Sort-Object -Unique).ForEach({
        $currCat = $_
        $Categories.Add($currCat,@{ 
            ItemCount = $( $Links.Category | Where { $_ -match $currCat }).Count
            Short = $($currCat -Replace "$($ScriptVariables.Regex.RgxShortCategory)","")
        })
    })
    $SelectCats = '<option value=""></option>'
    foreach ( $Cat in $Categories.Keys | Sort ) {
        $SelectCats += '<option value="' + $Cat + '">' + $Cat + '</option>'
    }
    $HTML += '<tr><td>'
    $HTML += '<table class="innerTable">'
    $HTML += '<form name="SaveLink" action="/ManageLink" method="POST" enctype="multipart/form-data" accept-charset="' + $ScriptVariables.Charset + '">'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblName + '</td><td width="100%"><input type=text name="Name" class="inputFilter" placeholder="' + $ScriptVariables.Text.PhdName + '" maxlength="128" pattern="' + $ScriptVariables.Regex.RgxName + '" required></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblURL + '</td><td><input type=url name="URL" class="inputFilter" placeholder="' + $ScriptVariables.Text.PhdURL + '" required></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblDescription + '</td><td><input type=text name="Description" class="inputFilter" placeholder="' + $ScriptVariables.Text.PhdDescription + '" pattern="' + $ScriptVariables.Regex.RgxDescription + '"></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblCategory + '</td><td><input type="text" class="inputFilter" name="Category" list="Categories" pattern="' + $ScriptVariables.Regex.RgxCategory + '" placeholder="' + $ScriptVariables.Text.PhdCategory + '" required/><datalist id="Categories">' + $SelectCats + '</datalist></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblRole + '</td><td><input type="text" class="inputFilter" name="Role" pattern="' + $ScriptVariables.Regex.RgxRole + '" placeholder="' + $ScriptVariables.Text.PhdRole + '"/></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblTags + '</td><td><input type="text" class="inputFilter" name="Tags" pattern="' + $ScriptVariables.Regex.RgxTags + '" placeholder="' + $ScriptVariables.Text.PhdTags + '"/></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblContact + '</td><td><input type="text" class="inputFilter" name="Contact" pattern="' + $ScriptVariables.Regex.RgxContact + '" placeholder="' + $ScriptVariables.Text.PhdContact + '"/></td></tr>'
    $HTML += '<tr><td align="left" style="width: 25%;">' + $ScriptVariables.Text.LblNotes + '</td><td><input type="text" class="inputFilter" name="Notes" pattern="' + $ScriptVariables.Regex.RgxNotes + '" placeholder="' + $ScriptVariables.Text.PhdNotes + '"/></td></tr>'
    if ( $ScriptVariables.AllowPersonalLinks -eq $true ) {
        $PersonalLink += '<label for="Personal" title="' + $ScriptVariables.Text.PersonalText + '" >' + $ScriptVariables.Text.LblPersonal + '</label><input type=checkbox id="chkPersonal" onclick="enableDisableFields()"  title="' + $ScriptVariables.Text.PersonalText + '" name="Personal" value="checked"><pre>   </pre>'
    } else { $PersonalLink = $null }
    $HTML += '<tr><td></td><td align="right">' + $PersonalLink + '<label for="Enabled">' + $ScriptVariables.Text.LblShowLink + '</label><input type=checkbox name="Enabled" value="checked" checked></td></tr>'
    $HTML += '<input hidden name="Type" value="new" type="text"/>'
    $HTML += '</form>'
    $HTML += '</table>'
    $HTML += '</td></tr>'
    $HTML += '<tr><td align="right"><button class="btn" type="button" onclick="window.location.href=`/`">' + $ScriptVariables.Text.CancelBtn + '</button><pre>  </pre><input class="btn" type="Submit" value="' + $ScriptVariables.Text.SaveBtn + '">'
}
elseif ( $RequestArgs -match '^remove[0-9]{8}$' ) {
    if ( ! $Edit ) { exit }
    $CurrentContent = $(Get-Content -Path $ScriptVariables.LinksFilePath | Select-String -Pattern "^$($RequestArgs -replace 'remove','')\$($ScriptVariables.CSVDelimiter)" -Encoding $($ScriptVariables.Charset -replace '-','')).Line
    $CurrentContent | Out-File -FilePath $ScriptVariables.RemovedLinksPath -Append
    $LinkName = $($CurrentContent.Split($ScriptVariables.CSVDelimiter).Trim())[1]
    Set-Content -Path $ScriptVariables.LinksFilePath -Encoding $($ScriptVariables.Charset -replace '-','') -Value (Get-Content -Path $ScriptVariables.LinksFilePath -Encoding $($ScriptVariables.Charset -replace '-','') | Select-String -Pattern "$($RequestArgs -replace 'remove','')" -Encoding $($ScriptVariables.Charset -replace '-','') -NotMatch)
    Write-Log -Message "$CurrentUser removed ID $($RequestArgs -replace 'remove','') : $LinkName"
    $CurrentContent = $null
    $HTML += @"
  <form id="AutoSubmit" action="/Admin" method="get" enctype="multipart/form-data" accept-charset="$($ScriptVariables.Charset)"></form>"
  <script type="text/javascript">
    function formAutoSubmit () {
      var frm = document.getElementById("AutoSubmit");
      frm.submit();
    }
    window.onload = formAutoSubmit;
  </script>
"@
}
elseif ( $RequestArgs -match '^CSS$' -or $RequestArgs -match '^CSS&theme-.*') {
    if ( ! $Admin ) { exit }
    if ( $RequestArgs -match '^CSS&theme-.*' ) {
        $SelectedThemeToEdit = $RequestArgs -replace 'CSS&',''
    }
    else { $SelectedThemeToEdit = $ScriptVariables.Theme }
    if ( $PersonalCSSLink ) {
        $DisplayedTheme = [regex]::match($PersonalCSSLink,"theme-.[^\.]*")
    }
    else { $DisplayedTheme = $ScriptVariables.Theme }
    $ConvertedCSS = ConvertFrom-CSS -Theme $SelectedThemeToEdit
    $ConvertedActiveCSS = ConvertFrom-CSS -CurrentUserTheme $DisplayedTheme
    $HTML += '<tr><td align="left"><b>' + $ScriptVariables.Text.AwarenessText + '</b><br><label for="ColorPicker">' + $ScriptVariables.Text.ColorPicker + '<pre>  </pre></label><input id="ColorPicker" style="background: transparent; border: 0; user-select: all;" type="color" value="#eeeeee"/></td></tr>'
    $HTML += '<tr><td>'
    $HTML += '<form id="frmUpdateCSS" action="/ManageLink?UpdateCSS" method="POST" enctype="multipart/form-data" accept-charset="' + $ScriptVariables.Charset + '">'
    $HTML += '<table class="innertable">'
    $HTML += '<tr><td align="left"><label for "EditTheme">' + $ScriptVariables.Text.SelectTheme + '</td><td align="right"><select name="EditTheme" style="width: 200px;" class="SelLang" onChange="ChooseThemeToEdit(this.value)">' + $(Get-ThemeOptions -List -SelectedThemeToEdit $SelectedThemeToEdit) + '</select></td></tr>'
    $HTML += '</table>'
    $HTML += '</td></tr>'
    $HTML += '<tr><td>'
    $HTML += '<table align="center" data-name="mytable" id="filteredTable" class="hover innerTable">'
    foreach ( $obj in $ConvertedCSS.Keys | Sort ) {
        $Type = $null
        if ( $obj.trim() -match "^\." ) { $Type = ' <i><font color="#aaa">(class)</font></i>' }
        if ( $obj.trim() -match "^#" ) { $Type += ' <i><font color="#aaa">(id)</font></i>' }
        if ( $obj.trim() -match "^[a-z0-9]+" ) { $Type += ' <i><font color="#aaa">(element)</font></i>' }
        if ( $obj.trim() -match "^[a-z0-9]*[\s]([a-z0-9]\s?){0,5}" ) { $Type += ' <i><font color="#aaa">(combinator)</font></i>' }
        if ( $obj.trim() -match "[^:]:{1}[^:]" ) { $Type += ' <i><font color="#aaa">(pseudo class)</font></i>' }
        if ( $obj.trim() -match "::" ) { $Type += ' <i><font color="#aaa">(pseudo element)</font></i>' }
        if ( $obj.trim() -match "\[.*\]" ) { $Type += ' <i><font color="#aaa">(attribute)</font></i>' }
        $HTML += '<tr><td colspan=2 id="CSSHeader"><b>' + $obj.trim() + $Type + '</b></td></tr>'
        foreach ( $childobj in $ConvertedCSS.$obj.Keys | Sort ) {
            if ( $childobj.trim() -notmatch "(\/\*|\*\/)" ) {
                if ( $ConvertedCSS.$obj.$childobj.trim() -match "#[0-9a-f]{3,6}" ) {
                    $ColorMatches = ([regex]::matches($($ConvertedCSS.$obj.$childobj.trim()),"#[0-9a-f]{3,6}")).Value
                    $BackgroundCOlor = $ConvertedActiveCSS.($ConvertedActiveCSS.keys | where { $_ -match "input\[type\=text\],\sinput\[type\=select\]" }).background
                    if ( $ColorMatches.Count -eq 1 )  {
                        $Color = 'style="background: linear-gradient(0.33turn, ' + $BackgroundCOlor + ' 85%, ' + $ColorMatches + ');"'
                    }
                    elseif ( $ColorMatches.Count -eq 2 ) {
                        $Color = 'style="background: linear-gradient(0.33turn, ' + $BackgroundCOlor + ' 85%, ' + $ColorMatches[1] + ' 50%, ' + $ColorMatches[0] + ');"'
                    }
                }
                else { $Color = $null }
                $HTML += '<tr><td style="width: 50%;" align="left" id="cssValue">' + $childobj.trim() + '</td><td style="width: 50%;" align="right"><input ' + $Color + ' type="text" name="' + $obj + '_____' + $childobj + '" value="' + $ConvertedCSS.$obj.$childobj.trim() + '"/></td></tr>'
            }
        }
    }
    $HTML += '</td></tr>'
    $HTML += '<tr><td style="width: 50%;" align="left"><b>' + $ScriptVariables.Text.NewCSSTheme + '</b></td><td style="width: 50%;" align="right"><input type="text" name="NewCSSTheme" placeholder="' + $ScriptVariables.Text.PhdNewCSSTheme + '" pattern="' + $ScriptVariables.Regex.RgxNewCSSName + '"/></td></tr>'
    $HTML += '</form>'
    $HTML += '</table>'
    $HTML += '<tr><td align="right"><input class="btn" form="frmUpdateCSS" type="Submit" value="' + $ScriptVariables.Text.SaveBtn + '"></td></tr>'
}
elseif ( $RequestArgs -match '^Text$' ) {
    if ( ! $Admin ) { exit }
    $HTML += '<tr><td><input type="text" id="inputFilter" onkeyup="filterFunctionMultiTables(0)" placeholder="' + $ScriptVariables.Text.FilterText + '" autofocus></td></tr>'
    $HTML += '<tr><td align="left"><b>' + $ScriptVariables.Text.AwarenessText + '<br><br></b></td></tr>'
    $HTML += '<tr><td>'
    $HTML += '<table with="100%" align="center" data-name="mytable" id="filteredTable" class="hover innerTable">'
    $HTML += '<form id="frmUpdateText" action="/ManageLink?UpdateText" method="POST" enctype="multipart/form-data" accept-charset="' + $ScriptVariables.Charset + '">'
    foreach ( $obj in $ScriptVariables.Text.Keys | Sort ) {
        $HTML += '<tr><td width="50%" align="left">' + $obj.trim() + '</td><td width="50%" align="right"><input type="text" name="' + $obj.trim() + '" value="' + $ScriptVariables.Text.$obj.trim() + '"/></td></tr>'
    }
    $HTML += '</form>'
    $HTML += '<form id="frmResetText" action="/ManageLink?ResetText" method="POST" enctype="multipart/form-data" accept-charset="' + $ScriptVariables.Charset + '"/>'
    $HTML += '</table>'
    $HTML += '</td></tr><tr><td>'
    $HTML += '<table class="innertable">'
    $HTML += '<tr><td style="width: 50%;" align="left"><button class="btn reset" form="frmResetText" type="Submit">' + $ScriptVariables.Text.ResetBtn + '</button></td><td style="width: 50%;" align="right"><input class="btn" align="right" form="frmUpdateText" type="Submit" value="' + $ScriptVariables.Text.SaveBtn + '"/></td></tr>'
    $HTML += '</table>'
}
elseif ( $RequestArgs -match '^Regex$' ) {
    if ( ! $Admin ) { exit }
    $HTML += '<tr><td colspan="2" align="left"><b>' + $ScriptVariables.Text.AwarenessText + '<br><br></b></td></tr>'
    $HTML += '<tr><td>'
    $HTML += '<table width="100%" align="center" data-name="mytable" id="filteredTable" class="hover innerTable">'
    $HTML += '<form id="frmUpdateRegex" action="/ManageLink?UpdateRegex" method="POST" enctype="multipart/form-data" accept-charset="' + $ScriptVariables.Charset + '">'
    foreach ( $obj in $ScriptVariables.Regex.Keys | Sort ) {
        $HTML += '<tr><td style="width: 50%;" align="left">' + $obj.trim() + '</td><td style="width: 50%;" align="right"><input type="text" name="' + $obj.trim() + '" value="' + $ScriptVariables.Regex.$obj.trim() + '"/></td></td></tr>'
    }
    $HTML += '</form>'
    $HTML += '</table>'
    $HTML += '<form id="frmResetRegex" action="/ManageLink?ResetRegex" method="POST" enctype="multipart/form-data" accept-charset="' + $ScriptVariables.Charset + '"/>'
    $HTML += '</td></tr><tr><td>'
    $HTML += '<table class="innertable">'
    $HTML += '<tr><td align="left"><button class="btn reset" form="frmResetRegex" type="Submit">' + $ScriptVariables.Text.ResetBtn + '</button></td><td align="right"><input class="btn" form="frmUpdateRegex" type="Submit" value="' + $ScriptVariables.Text.SaveBtn + '"></td></tr>'
    $HTML += '</table>'
}
elseif ( $RequestArgs -match '^Settings$' ) {
    if ( ! $Admin ) { exit }
    $HTML += '<form id="frmUpdateSettings" action="/ManageLink?UpdateSettings" method="POST" enctype="multipart/form-data" accept-charset="' + $ScriptVariables.Charset + '">'
    $BaseSettings = Get-Content ($($ScriptVariables.ScriptPath) + 'base_settings.json') | ConvertFrom-Json
    $HTML += '<tr><td id="cssheader"><b>' + $ScriptVariables.Text.SettingsServer + '</b></td></tr>'
    $HTML += '<tr><td>'
    $HTML += '<table align="center" class="hover innerTable">'
    foreach ( $Setting in $BaseSettings.PSObject.Properties ) {
        if ( $Setting.Name -eq 'Language' ) {
            $AvailableLangs = (Get-Childitem $ScriptVariables.LanguagePath -Exclude '*_default.json').BaseName
            $SelectLangs = @()
            foreach ( $Lang in $AvailableLangs | Sort -Unique ) {
                if ( $ScriptVariables.Language -eq $Lang ) {
                    $SelectLangs += '<option value="' + $Lang + '" selected>' + $Lang + '</option>'
                }
                else {
                    $SelectLangs += '<option value="' + $Lang + '">' + $Lang + '</option>'
                }
            }
            $HTML += '<tr><td style="width: 50%;" align="left"><label>' + $Setting.Name + '</label></td><td style="width: 50%;" align="right"><select class="selLang" name="Language"/>' + $SelectLangs -join '' + '</select></td></tr>'
        }
        else {
            $HTML += '<tr><td style="width: 50%;" align="left"><label>' + $Setting.Name + '</label></td><td style="width: 50%;" align="right"><input name="' + $Setting.Name + '" type="text" value="' + $Setting.Value + '" disabled/></td></tr>'
        }
    }
    $HTML += '</table>'
    $HTML += '</td></tr>'
    $CustomSettings = Get-Content "$($ScriptVariables.SettingsPath)\custom_settings.json" | ConvertFrom-Json
    $HTML += '<tr><td id="cssheader" colspan="2"><b>' + $ScriptVariables.Text.SettingsCustom + '</b></td></tr>'
    $HTML += '<tr><td>'
    $HTML += '<table align="center" class="hover innerTable">'
    foreach ( $Setting in $CustomSettings.PSObject.Properties ) {
        if ( $Setting.Name -match "(LogRows|LogoWidth)" ) {
            $HTML += '<tr><td style="width: 50%;" align="left"><label>' + $Setting.Name + '</label></td><td style="width: 50%;" align="right"><input type="text" name="' + $Setting.Name + '" value="' + $Setting.Value + '"/></td></tr>'
        }
        elseif ( $Setting.Name -eq 'Theme' ) {
            $AvailableThemes = (Get-ChildItem ($ScriptVariables.ScriptPath + 'style\theme*')).BaseName
            $HTML += '<tr><td style="width: 50%;" align="left">' + $ScriptVariables.Text.SelectTheme + ' (<i>' + $ScriptVariables.Text.DefaultText +  '</i>)</td>'
            $SelectThemes = @()
            foreach ( $Theme in $AvailableThemes | Sort -Unique ) {
                if ( $Theme -eq $ScriptVariables.Theme ) { $Selected = 'Selected' } else { $Selected = $null }
                $SelectThemes += '<option value="' + $Theme + '" ' + $Selected + '>' + ($Theme -replace '_',' ' -replace 'theme-','') + '</option>'
            }
            $HTML += '<td style="width: 50%;" align="right"><select class="selLang" name="Theme"/>' + $SelectThemes -join '' + '</select></td></tr>'
        }
        elseif ( $Setting.Name -eq 'AllowPersonalLinks' ) {
            if ( $ScriptVariables.AllowPersonalLinks -eq $True ) {
                $CurrentStatus = '<option value="True" selected>' + $ScriptVariables.Text.IsYes + '</option><option value="False">' + $ScriptVariables.Text.IsNo + '</option>'
            }
            else {
                $CurrentStatus = '<option value="True">' + $ScriptVariables.Text.IsYes + '</option><option value="False" selected>' + $ScriptVariables.Text.IsNo + '</option>'
            }
            $HTML += '<tr><td style="width: 50%;" align="left">' + $Setting.Name + '</td><td style="width: 50%;" align="right"><select class="selLang" name="AllowPersonalLinks"/>' + $CurrentStatus + '</select></td></tr>'
        }
        elseif ( $Setting.Name -eq 'AllowPersonalTheme' ) {
            if ( $ScriptVariables.AllowPersonalTheme -eq $True ) {
                $CurrentStatus = '<option value="True" selected>' + $ScriptVariables.Text.IsYes + '</option><option value="False">' + $ScriptVariables.Text.IsNo + '</option>'
            }
            else {
                $CurrentStatus = '<option value="True">' + $ScriptVariables.Text.IsYes + '</option><option value="False" selected>' + $ScriptVariables.Text.IsNo + '</option>'
            }
            $HTML += '<tr><td style="width: 50%;" align="left">' + $Setting.Name + '</td><td style="width: 50%;" align="right"><select class="selLang" name="AllowPersonalTheme"/>' + $CurrentStatus + '</select></td></tr>'
        }
        elseif ( $Setting.Name -eq 'ShowFooter' ) {
            if ( $ScriptVariables.ShowFooter -eq $True ) {
                $CurrentStatus = '<option value="True" selected>' + $ScriptVariables.Text.IsYes + '</option><option value="False">' + $ScriptVariables.Text.IsNo + '</option>'
            }
            else {
                $CurrentStatus = '<option value="True">' + $ScriptVariables.Text.IsYes + '</option><option value="False" selected>' + $ScriptVariables.Text.IsNo + '</option>'
            }
            $HTML += '<tr><td style="width: 50%;" align="left">' + $Setting.Name + '</td><td style="width: 50%;" align="right"><select class="selLang" name="ShowFooter"/>' + $CurrentStatus + '</select></td></tr>'
        }
        else {
            $HTML += '<tr><td style="width: 50%;" align="left"><label>' + $Setting.Name + '</label></td><td style="width: 50%;" align="right"><input type="text" value="' + $Setting.Value + '" disabled/></td></tr>'
        }
    }
    $HTML += '</table>'
    $HTML += '</td></tr>'
    $HTML += '<tr><td>'
    $HTML += '<table with="100%" align="center" data-name="mytable" id="filteredTable" class="hover innerTable">'
    $HTML += '<tr><td align="left"><label style="vertical-align: top;">' + $ScriptVariables.Text.LblChooseLogo + '</label></td><td align="right"><input type="button" style="align: right;" class="btn" value="' + $ScriptVariables.Text.UploadLogoBtn + '" onclick="document.getElementById(''filLogo'').click();" /></td></tr>'
    $HTML += '</table>'
    $HTML += '</td></tr>'
    $HTML += '<tr><td align="right"><input type="text" id="base64area" name="Logo" placeholder="' + $ScriptVariables.Text.PhdUploadLogo + '" hidden/><img id="tempLogo" src="data:image/png;base64, ' + $ScriptVariables.Logo + '" height="75em" /></td></tr>'
    $HTML += '<input type="file" id="filLogo" accept=".jpg,.gif,.png,.svg" hidden/>'
    $HTML += '</form>'
    $HTML += @"
<script type="text/javascript">
  var handleFileSelect = function(evt) {
    var files = evt.target.files;
    var file = files[0];
    if (files && file) {
      var reader = new FileReader();
      reader.onload = function(readerEvt) {
        var binaryString = readerEvt.target.result;
        document.getElementById("base64area").value = btoa(binaryString);
        document.getElementById("tempLogo").src = "data:image/png;base64," + btoa(binaryString);
      };
      reader.readAsBinaryString(file);
    }
  };
  if (window.File && window.FileReader && window.FileList && window.Blob) {
    document.getElementById('filLogo').addEventListener('change', handleFileSelect, false);
  } else { alert('The File APIs are not fully supported in this browser.'); }
</script>
"@
    $HTML += '<form id="frmResetLogo" action="/ManageLink?ResetLogo" method="POST" enctype="multipart/form-data" accept-charset="' + $ScriptVariables.Charset + '"/>'
    $HTML += '<tr><td>'
    $HTML += '<table class="innerTable">'
    $HTML += '<tr><td align="left"><button class="btn reset" form="frmResetLogo" type="Submit">' + $ScriptVariables.Text.ResetLogo + '</button></td><td align="right"><input class="btn" id="SubmitBtn" form="frmUpdateSettings" type="Submit" value="' + $ScriptVariables.Text.SaveBtn + '"></td></tr>'
    $HTML += '</table>'
}
else { exit }
$HTML += @"
      </table>
    </td></tr>
  </table>
  $( if ( $ScriptVariables.ShowFooter -eq $true ) { '<img width="50em" style="vertical-align: middle;" src="data:image/png;base64, ' + $(Get-Content ($ScriptVariables.ScriptPath + 'images\linx_base64.txt')) + '"/><pre style="vertical-align: middle;"> version ' + $($ScriptVariables.Version) + '</pre>' })
  <script>
    // Send with RequestArg when changing private Theme
    function SetTheme(theme){location.href = "/?SelectTheme&" + theme + "&Admin";}

    // Send with RequestArg what Theme to edit
    function ChooseThemeToEdit(theme){location.href = "/Admin?CSS&" + theme;}

    function filterFunctionMultiTables(n) {
      var input, filter, table, tr, td, i,alltables;
      alltables = document.querySelectorAll("table[data-name=mytable]");
      input = document.getElementById("inputFilter");
      filter = input.value.toUpperCase();
      alltables.forEach(function(table){
        tr = table.getElementsByTagName("tr");
        for (i = 0; i < tr.length; i++) {
          td = tr[i].getElementsByTagName("td")[n];
          if (td) {
            if (td.innerHTML.toUpperCase().indexOf(filter) > -1) {
              tr[i].style.display = "";
            } else {
              tr[i].style.display = "none";
            }
          }       
        }
      });
    }

    // filter log page
    function filterFunctionLogTable() {
      var input, filter, table, tr, td, i,alltables;
      alltables = document.querySelectorAll("table[data-name=mytable]");
      input = document.getElementById("inputFilter");
      filter = input.value.toUpperCase();
      alltables.forEach(function(table){
        tr = table.getElementsByTagName("tr");
        for (i = 0; i < tr.length; i++) {
          td = tr[i].getElementsByTagName("td")[0];
          if (td) {
            if (td.innerHTML.toUpperCase().indexOf(filter) > -1) {
              tr[i].style.display = "";
            } else {
              tr[i].style.display = "none";
            }
          }       
        }
      });
    }

    function sortTable(n) {
      var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
      table = document.getElementById("filteredTable");
      switching = true;
      dir = "asc";
      while (switching) {
        switching = false;
        rows = table.rows;
        for (i = 1; i < (rows.length - 1); i++) {
          shouldSwitch = false;
          x = rows[i].getElementsByTagName("TD")[n];
          y = rows[i + 1].getElementsByTagName("TD")[n];
          if (dir == "asc") {
            if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {
              shouldSwitch = true;
              break;
            }
          } else if (dir == "desc") {
            if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {
              shouldSwitch = true;
              break;
            }
          }
        }
        if (shouldSwitch) {
          rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
          switching = true;
          switchcount ++;
        } else {
          if (switchcount == 0 && dir == "asc") {
            dir = "desc";
            switching = true;
          }
        }
      }
    }

    function sortTableByAREF(n) {
      var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
      table = document.getElementById("filteredTable");
      switching = true;
      dir = "asc";
      while (switching) {
        switching = false;
        rows = table.rows;
        for (i = 1; i < (rows.length - 1); i++) {
          shouldSwitch = false;
          x = rows[i].getElementsByTagName("A")[n];
          y = rows[i + 1].getElementsByTagName("A")[n];
          if (dir == "asc") {
            if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {
              shouldSwitch = true;
              break;
            }
          } else if (dir == "desc") {
            if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {
              shouldSwitch = true;
              break;
            }
          }
        }
        if (shouldSwitch) {
          rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
          switching = true;
          switchcount ++;
        } else {
          if (switchcount == 0 && dir == "asc") {
            dir = "desc";
            switching = true;
          }
        }
      }
    }
    sortTableByAREF(0);

    function enableDisableFields() {    
        if (document.getElementById('chkPersonal').checked) {
            document.getElementsByName('Role')[0].disabled = true;
            document.getElementsByName('Contact')[0].disabled = true;
        }
        else {
            document.getElementsByName('Role')[0].disabled = false;
            document.getElementsByName('Contact')[0].disabled = false;
        }
    }
  </script>
</body>
</html>
"@
$HTML