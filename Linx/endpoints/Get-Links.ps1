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
        if ( $group -in $MainUser.memberof ) { $AdminLink = '<a href="' + $ScriptVariables.ServerURL + '/Admin">Admin</a>' }
    }
    if ( $MainUser.memberof -match "$($ScriptVariables.EditGroup)" ) { $AdminLink = '<a href="' + $ScriptVariables.ServerURL + '/Admin">Admin</a>' }
#endregion
#region Get Links
    $Links = Import-CSV $ScriptVariables.LinksFilePath -Delimiter $ScriptVariables.CSVDelimiter
    if ( $ScriptVariables.AllowPersonalLinks -eq $true ) {
        $PersonalPath = "$($ScriptVariables.PersonalPath)\$CurrentUser.csv"
        if ( Test-Path $PersonalPath ) {
            if ( ( Get-Content $PersonalPath -first 2).count -gt 1 ) {
                $Links += Import-CSV $PersonalPath -Delimiter $ScriptVariables.CSVDelimiter
                $PersonalLinks = $true
            }
        }
        if ( $PersonalLinks ) { $PersonalLink = '<a href="' + $ScriptVariables.ServerURL + '/Personal">' + $ScriptVariables.Text.PersonalLink + '</a>' }
    }
#endregion

$SelectThemes = Get-ThemeOptions $CurrentUser

$HTML += '<header>'
$HTML += '<nav align="left"><a href="' + $ScriptVariables.ServerURL + '/Admin?new">' + $ScriptVariables.Text.AdmNewLink + '</a>' + $PersonalLink + $AdminLink + '</nav>'
if ( $ScriptVariables.AllowPersonalTheme -eq $true ) {
    $HTML += '<div><select name="Theme" style="width: 200px;" class="SelTheme" onChange="SetTheme(this.value)"><option style="display:none;" selected="true" disabled="disabled">' + $ScriptVariables.Text.SelectTheme + '</option>' + $SelectThemes + '</select></div>'
}
$HTML += '</header>'
$HTML += '<table id="main" align="center">'
$HTML += '<tr><td>'
$HTML += '<table align="center" class="innerTable">'
if ( !$RequestArgs ) {
    $Categories = @{}
    $($Links.Category | Sort-Object -Unique).ForEach({
        $currCat = $_
        $Categories.Add($currCat,@{ 
            ItemCount = $( $Links.Category | Where { $_ -match $currCat }).Count
            Short = $($currCat -Replace "$($ScriptVariables.Regex.RgxShortCategory)","")
        })
    })    
    $HTML += '<tr><td><input type="text" id="inputFilter" onkeyup="filterFunctionMultiTables()" placeholder="' + $ScriptVariables.Text.FilterText + '" autofocus><br>'
    $HTML += '<select class="selCats" onfocus="this.selectedIndex = 0;" onclick="window.location.hash = this.value;this.selectedIndex = 0;"><option style="display:none;" selected="true" disabled="disabled">' + $ScriptVariables.Text.JumpToCatText + '</option>'
    $HTML += $( foreach ( $Cat in $Categories.Keys | Sort ) { '<option value="anchor-' + $Categories.$Cat.Short + '">' + $Cat + ' (' + $Categories.$Cat.ItemCount + ')</option>' })
    $HTML += '</select>'
    $HTML += '</td></tr>'
    if ( $ScriptVariables.Text.UserPageText ) {
        $HTML += '<tr><td><i>' + $ScriptVariables.Text.UserPageText + '</i></td></tr>'
    }
    $HTML += '<tr><td>'
    $HTML += '<table align="center" data-name="mytable" id="filteredTable" class="hover innerTable">'    
    foreach ( $Cat in $Categories.Keys | Sort ) {
        if ( $Cat -ne "" ) {
            $HTML += '<tr class="header expand"><th colspan="3" class="category"><a class="catheader" name="anchor-' + $Categories.$Cat.Short + '">' + $Cat + '<span class="sign"/></a></th></tr>'
            foreach ( $Link in $Links | Where { $_.Category -eq $Cat } | Sort-Object Name ) {
                if ( $Link.Disabled -notmatch "^true$" ) {
                    if ( $Link.ID.Length -eq 8 ) {
                        if ( $Link.Role -ne '' ) { $RoleTips = '<br><br><b>' + $ScriptVariables.Text.DisplayFor + ':</b><br>' + $Link.Role -replace ',','<br>' }
                        else { $RoleTips = '<br><br><b>' + $ScriptVariables.Text.DisplayFor + ':</b><br>' + $ScriptVariables.Text.Everyone }
                    }
                    else { $RoleTips = '' }
                    if ( $Link.Tags -ne '' ) { $TagTips = '<br><br><b>' + $ScriptVariables.Text.LblTags + ':</b><br>' + $Link.Tags }
                    else { $TagTips = '<br><br><b>' + $ScriptVariables.Text.LblTags + ':</b><br><font class="tooltipempty"><i>-</i></font>' }
                    if ( $Link.ID.Length -eq 8 ) {
                        if ( $Link.Contact -ne '' ) { $ContactTips = '<br><br><b>' + $ScriptVariables.Text.LblContact + ':</b><br>' + $Link.Contact }
                        else { $ContactTips = '<br><br><b>' + $ScriptVariables.Text.LblContact + ':</b><br><font class="tooltipempty"><i>-</i></font>' }
                    }
                    else { $ContactTips = '' }
                    if ( $Link.Notes -ne '' ) { $NotesTips = '<br><br><b>' + $ScriptVariables.Text.LblNotes + ':</b><br>' + $Link.Notes }
                    else { $NotesTips = '<br><br><b>' + $ScriptVariables.Text.LblNotes + ':</b><br><font class="tooltipempty"><i>-</i></font>' }
                    $TooltipText = "$RoleTips$TagTips$ContactTips$NotesTips"
                    if ( $Link.Role -ne '' ) {
                        foreach ( $Role in $($Link.Role.Split(",")) ) {
                            if ( $MainUser.memberof -match "$Role" ) {
                                $HTML += '<tr><td width="40%" align="left"><div class="tooltip"><a href="' + $Link.URL + '" target="_blank"/>' + $Link.Name + '</a><span class="tooltiptext">' + $TooltipText + '</span></div></td><td align="right">' + $Link.Description + '</td><td class="hiddenColumn">' + $Link.Name + $Link.Tags + '</td></tr>'
                                break
                            }
                        }
                    }
                    else {
                        if ( $Link.ID.Length -ne 8 ) {
                            $PersonalTip   = '<b><i><font class="personal">' + $($ScriptVariables.Text.LblPersonal) + '</font></i></b>'
                            $PersonalClass = 'class="Personal"'
                        }
                        else {
                            $PersonalTip = $null
                            $PersonalClass    = $null
                        }
                        $HTML += '<tr><td width="40%" align="left"><div class="tooltip"><a href="' + $Link.URL + '" target="_blank"/><font ' + $PersonalClass + '>' + $Link.Name + '</font></a><span class="tooltiptext">' + $PersonalTip + $TooltipText + '</span></div></td><td align="right">' + $Link.Description + '</td><td class="hiddenColumn">' + $Link.Name + $Link.Tags + '</td></tr>'
                    }
                }
            }
        }
        $AvailableThemes = (Get-ChildItem ($ScriptVariables.ScriptPath + 'style\theme*')).BaseName
        $CurrentTheme = (Get-ChildItem ($ScriptVariables.PersonalPath + '\' + $CurrentUser + '-*.css_link')).BaseName
        $SelectThemes = @()
        foreach ( $Theme in $AvailableThemes ) {
            if ( $CurrentTheme -match ($Theme -replace 'theme-','') ) {
                $Selected = 'Selected'
            }
            else {
                if ( !$CurrentTheme -and $Theme -eq $ScriptVariables.Theme ) {
                    $Selected = 'selected'
                }
                else {
                    $Selected = $null
                }
            }
            if ( $Theme -eq $ScriptVariables.Theme ) {
                $DefaultTheme = " ($($ScriptVariables.Text.DefaultText))"
            }
            else {
                $DefaultTheme = $null
            }
            $SelectThemes += '<option value="' + $Theme + '" ' + $Selected + '>' + ($Theme -replace '_',' ' -replace 'theme-','') + $DefaultTheme + '</option>'
        }
        $CurrentTheme = $null
        $SelectThemes = $SelectThemes -join ''
    }
    $HTML += '</table>'
    $HTML += '</td></tr>'
}
elseif ( $RequestArgs -match '^SelectTheme' ) {
    $SelectedTheme = [regex]::match($RequestArgs,"(?<=&).[^&]*")#$RequestArgs -replace 'SelectTheme&',''
    $Source = [regex]::match($RequestArgs,"(?<=&.*&).*$")
    if ( $SelectedTheme -eq $ScriptVariables.Theme ) {
        Remove-Item ($ScriptVariables.PersonalPath + '\' + $CurrentUser + '-*.css_link') -Force
    }
    else {
        Remove-Item ($ScriptVariables.PersonalPath + '\' + $CurrentUser + '-*.css_link') -Force
        '' | Out-File ($ScriptVariables.PersonalPath + '\' + $CurrentUser + '-' + $SelectedTheme + '.css_link') -Force
    }
    $HTML =  '<html><body>' + $RequestArgs
    $HTML += '<form id="AutoSubmit" action="/' + $Source + '" method="get" enctype="multipart/form-data" accept-charset="' + $ScriptVariables.Charset + '"></form>'
    $HTML += '<script type="text/javascript">'
    $HTML += 'function formAutoSubmit(){document.getElementById("AutoSubmit").submit();}'
    $HTML += 'window.onload = formAutoSubmit;'
    $HTML += '</script></body></html>'
    return $HTML
}
$HTML += @"
      </table>
    </td></tr>
  </table>
  $( if ( $ScriptVariables.ShowFooter -eq $true ) { '<img width="50em" style="vertical-align: middle;" src="data:image/png;base64, ' + $(Get-Content ($ScriptVariables.ScriptPath + 'images\linx_base64.txt')) + '"/><pre style="vertical-align: middle;"> version ' + $($ScriptVariables.Version) + '</pre>' })
  <script>
    // Send with RequestArg when changing private Theme
    function SetTheme(theme){location.href = "/?SelectTheme&" + theme + "&";}

    // filter column 2 in the table filterTable based on the inputbox inputFilter
    function filterFunctionMultiTables() {
      var input, filter, table, tr, td, i,alltables;
      alltables = document.querySelectorAll("table[data-name=mytable]");
      input = document.getElementById("inputFilter");
      filter = input.value.toUpperCase();
      alltables.forEach(function(table){
      tr = table.getElementsByTagName("tr");
        for (i = 0; i < tr.length; i++) {
          td = tr[i].getElementsByTagName("td")[2];
            if (td) {
              if (td.innerHTML.toUpperCase().indexOf(filter) > -1) {
                tr[i].style.display = "";
              } else {
                tr[i].style.display = "none";
              }
            }       
          }
        }
      );
    }
  </script>
</body>
</html>
"@
$HTML