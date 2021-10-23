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
    $PersonalPath = "$($ScriptVariables.PersonalPath)\$CurrentUser.csv"
    $Links        = Import-CSV $PersonalPath -Delimiter $ScriptVariables.CSVDelimiter
    $Categories   = @()
#endregion

$SelectThemes = Get-ThemeOptions $CurrentUser

$HTML += '<header>'
$HTML += '<nav align="left"><a href="' + $ScriptVariables.ServerURL + '/Admin?new">' + $ScriptVariables.Text.AdmNewLink + '</a><a href="' + $ScriptVariables.ServerURL + '/">' + $ScriptVariables.Text.StartPage + '</a>' + $AdminLink + '</nav>'
if ( $ScriptVariables.AllowPersonalTheme -eq $true ) {
    $HTML += '<div><select name="Theme" style="width: 200px;" class="SelTheme" onChange="SetTheme(this.value)">' + $SelectThemes + '</select></div>'
}
$HTML += '</header>'
$HTML += '<table id="main" align="center">'
$HTML += '<tr><td>'
$HTML += '<table align="center" class="innerTable">'
if ( !$RequestArgs ) {
    $HTML += @"
    <tr><td><input type="text" id="inputFilter" onkeyup="filterFunctionMultiTables()" placeholder="$($ScriptVariables.Text.FilterText)" autofocus></td></tr>
    <tr><td>
      <table align="center" data-name="mytable" id="filteredTable" class="hover innerTable">
        <tr><th align="left" width="35%" onclick="sortTableByAREF(0)">$($ScriptVariables.Text.LblName)</th><th width="35%" onclick="sortTable(1)">$($ScriptVariables.Text.LblDescription)</th><th width="15%" onclick="sortTable(2)">$($ScriptVariables.Text.LblCategory)</th><th width="15%"></th></tr>
"@
    foreach ( $Link in $Links | Sort-Object Name ) {
        $EditColumn = '<td><a href="' + $ScriptVariables.ServerURL + '/Personal?' + $Link.ID + '">' + $ScriptVariables.Text.Edit + '</a></td>'
        if ( $Link.Tags -ne '' ) { $TagTips = '<br><br><b>' + $ScriptVariables.Text.LblTags + ':</b><br>' + $($Link.Tags) }
        else { $TagTips = '<br><br><b>' + $ScriptVariables.Text.LblTags + ':</b><br><font class="tooltipempty"><i>-</i></font>' }
        if ( $Link.Notes -ne '' ) { $NotesTips = '<br><br><b>' + $ScriptVariables.Text.LblNotes + ':</b><br>' + $($Link.Notes) }
        else { $NotesTips = '<br><br><b>' + $ScriptVariables.Text.LblNotes + ':</b><br><font class="tooltipempty"><i>-</i></font>' }
        $TooltipText = "$TagTips$NotesTips"
        $HTML += '<tr><td align="left"><div class="tooltip"><a href="' + $Link.URL + '" target="_blank"/>' + $Link.Name + '</a><span class="tooltiptext">' + $TooltipText + '</span></div></td><td>' + $Link.Description + '</td><td>' + $Link.Category + '</td><td class="hiddenColumn">' + $Link.Name + $Link.Tags + '</td>' + $EditColumn + '</tr>'
    }
    $HTML += '</table>'
    $HTML += '</td></tr>'
}
elseif ( $RequestArgs -match '^[0-9]{7}$' ) {
    $Link = Select-String -Path $PersonalPath -Pattern $RequestArgs -Encoding $($ScriptVariables.Charset -replace '-','') | Select-Object -ExpandProperty Line | convertfrom-csv -Delimiter $ScriptVariables.CSVDelimiter -Header $((Get-Content $PersonalPath -First 1).Split($ScriptVariables.CSVDelimiter))
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
    $HTML += '<table class="innertable">'
    $HTML += '<form name="SaveLink" action="/ManageLink" method="POST" enctype="multipart/form-data" accept-charset="' + $ScriptVariables.Charset + '">'
    $HTML += '<tr><td>' + $ScriptVariables.Text.LblName + '</td><td width="100%"><input type=text name="Name" value="' + $Link.Name + '" class="inputFilter" placeholder="' + $ScriptVariables.Text.PhdName + '" maxlength="128" pattern="' + $ScriptVariables.Regex.RgxName + '" required></td></tr>'
    $HTML += '<tr><td>' + $ScriptVariables.Text.LblURL + '</td><td><input type=url name="URL" value="' + $Link.URL + '" class="inputFilter" placeholder="' + $ScriptVariables.Text.PhdURL + '" required></td></tr>'
    $HTML += '<tr><td>' + $ScriptVariables.Text.LblDescription + '</td><td><input type=text value="' + $Link.Description + '" name="Description" class="inputFilter" placeholder="' + $ScriptVariables.Text.PhdDescription + '" pattern="' + $ScriptVariables.Regex.RgxDescription + '"></td></tr>'
    $HTML += '<tr><td>' + $ScriptVariables.Text.LblCategory + '</td><td><input type="text" value="' + $Link.Category + '" class="inputFilter" name="Category" list="Categories" pattern="' + $ScriptVariables.Regex.RgxCategory + '" placeholder="' + $ScriptVariables.Text.PhdCategory + '" required/><datalist id="Categories">' + $SelectCats + '</datalist></td></tr>'
    $HTML += '<tr><td>' + $ScriptVariables.Text.LblTags + '</td><td><input type="text" value="' + $Link.Tags + '" class="inputFilter" name="Tags" pattern="' + $ScriptVariables.Regex.RgxTags + '" placeholder="' + $ScriptVariables.Text.PhdTags + '"/></td></tr>'
    $HTML += '<tr><td>' + $ScriptVariables.Text.LblNotes + '</td><td><input type="text" value="' + $Link.Notes + '" class="inputFilter" name="Notes" pattern="' + $ScriptVariables.Regex.RgxNotes + '" placeholder="' + $ScriptVariables.Text.PhdNotes + '"/></td></tr>'
    $HTML += '<input hidden name="Type" value="update" type="text"/>'
    $HTML += '<input hidden name="ID" value="' + $RequestArgs + '" type="text"/>'
    $HTML += '</form>'
    $HTML += '</table>'
    $HTML += '</td></tr>'
    $HTML += '<table class="innertable">'
    $HTML += '<tr><td><a title="' + $ScriptVariables.Text.RemoveLinkWarning + '" href="/Personal?remove' + $RequestArgs + '" align="center" class="removelink">' + $ScriptVariables.Text.RemoveLink + '</a></td><td align="right"><button class="btn" type="button" onclick="window.location.href=`/Personal`">' + $ScriptVariables.Text.CancelBtn + '</button><input class="btn" type="Submit" value="' + $ScriptVariables.Text.UpdateBtn + '"></td></tr>'
    $HTML += '</table>'
    $HTML += '</td></tr>'
}
elseif ( $RequestArgs -match '^remove[0-9]{7}$' ) {
    $CurrentContent = $(Get-Content -Path $PersonalPath | Select-String -Pattern "^$($RequestArgs -replace 'remove','')\$($ScriptVariables.CSVDelimiter)" -Encoding $($ScriptVariables.Charset -replace '-','')).Line
    $LinkName = $($CurrentContent.Split($ScriptVariables.CSVDelimiter).Trim())[1]
    Set-Content -Path $PersonalPath -Encoding $($ScriptVariables.Charset -replace '-','') -Value (Get-Content -Path $PersonalPath -Encoding $($ScriptVariables.Charset -replace '-','') | Select-String -Pattern "$($RequestArgs -replace 'remove','')" -Encoding $($ScriptVariables.Charset -replace '-','') -NotMatch)
    $CurrentContent = $null
    $HTML += @"
  <form id="AutoSubmit" action="/Personal" method="get" enctype="multipart/form-data" accept-charset="$($ScriptVariables.Charset)"></form>"
  <script type="text/javascript">
    function formAutoSubmit () {
      var frm = document.getElementById("AutoSubmit");
      frm.submit();
    }
    window.onload = formAutoSubmit;
  </script>
"@
}
else { exit }
$HTML += @"
      </table>
    </td></tr>
  </table>
  $( if ( $ScriptVariables.ShowFooter -eq $true ) { '<img width="50em" style="vertical-align: middle;" src="data:image/png;base64, ' + $(Get-Content ($ScriptVariables.ScriptPath + 'images\linx_base64.txt')) + '"/><pre style="vertical-align: middle;"> version ' + $($ScriptVariables.Version) + '</pre>' })
  <script>
    // Send with RequestArg when changing private Theme
    function SetTheme(theme){location.href = "/?SelectTheme&" + theme + "&Personal";}

    function filterFunctionMultiTables() {
      var input, filter, table, tr, td, i,alltables;
      alltables = document.querySelectorAll("table[data-name=mytable]");
      input = document.getElementById("inputFilter");
      filter = input.value.toUpperCase();
      alltables.forEach(function(table){
        tr = table.getElementsByTagName("tr");
        for (i = 0; i < tr.length; i++) {
          td = tr[i].getElementsByTagName("td")[3];
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
  </script>
</body>
</html>
"@
$HTML