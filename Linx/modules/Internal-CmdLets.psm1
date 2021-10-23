function Get-HTMLHead {
param ( $CSS )
@"
<html>
<head>
  <meta http-equiv="Content-Type" content="multipart/form-data;charset=$($ScriptVariables.Charset)">
</head>
$CSS
<body>
  $(if ( $ScriptVariables.Logo ) { '<br><br><img width="' + $ScriptVariables.LogoWidth + '" src="data:image/png;base64, ' + $ScriptVariables.Logo + '"/>' })<br>
  <h2>$($ScriptVariables.Text.Title)</h2>
"@
}
function Get-MainUser {
    param ( $CurrentUser )

    [array]$MainUser = (New-Object adsisearcher([adsi]"LDAP://$($ScriptVariables.OU_User)","(&(objectCategory=User)(samaccountname=$CurrentUser))")).FindOne().Properties
    if ( ! $MainUser ) {
        [array]$MainUser = (New-Object adsisearcher([adsi]"LDAP://$($ScriptVariables.OU_Admin)","(&(objectCategory=User)(samaccountname=$CurrentUser))")).FindOne().Properties
        if ( $MainUser ) {
            $MainUser
        }
    }
    else { $MainUser }
}
function Get-ThemeOptions {
    param (
        [string]$CurrentUser,
        [string]$SelectedThemeToEdit,
        [switch]$List
    )
    
    $AvailableThemes = (Get-ChildItem ($ScriptVariables.ScriptPath + 'style\theme*')).BaseName
    if ( $CurrentUser ) {
        $CurrentTheme = (Get-ChildItem ($ScriptVariables.PersonalPath + '\' + $CurrentUser + '-*.css_link')).BaseName
    }
    $SelectThemes = @()
    foreach ( $Theme in $AvailableThemes ) {
        if ( !$List ) {
            if ( $CurrentTheme -match ($Theme -replace 'theme-','') ) {
                $Selected = 'Selected'
            }
            else {
                if ( !$CurrentTheme -and $Theme -eq $ScriptVariables.Theme ) {
                    $Selected = 'selected'
                }
                else { $Selected = $null }
            }
            if ( $Theme -eq $ScriptVariables.Theme ) {
                $DefaultTheme = " ($($ScriptVariables.Text.DefaultText))"
            }
            else { $DefaultTheme = $null }
        }
        else {
            if ( $SelectedThemeToEdit -eq $null ) {
                if ( $Theme -eq $ScriptVariables.Theme ) {
                    $Selected = 'selected'
                    $DefaultTheme = " ($($ScriptVariables.Text.DefaultText))"
                }
                else {
                    $Selected = $null
                    $DefaultTheme = $null
                }
            }
            else {
                if ( $Theme -eq $ScriptVariables.Theme ) {
                    $DefaultTheme = " ($($ScriptVariables.Text.DefaultText))"
                }
                else { $DefaultTheme = $null }
                if ( $Theme -eq $SelectedThemeToEdit ) {
                    $Selected = 'selected'
                }
                else { $Selected = $null }
            }
        }
        $SelectThemes += '<option value="' + $Theme + '" ' + $Selected + '>' + ($Theme -replace '_',' ' -replace 'theme-','') + $DefaultTheme + '</option>'
    }
    $SelectThemes = $SelectThemes -join ''
    $SelectThemes
}
function ConvertFrom-CSS {
    
    [CmdletBinding(DefaultParameterSetName = 'Theme')]
    param (
        [Parameter(ParameterSetName = 'Theme')]
        [string]$Theme,
        [Parameter(ParameterSetName = 'CurrentUserTheme')]
        [string]$CurrentUserTheme
    )

    if ( $Theme ) { $UsingTheme = $Theme }
    if ( $CurrentUserTheme ) { $UsingTheme = $CurrentUserTheme }

    $PageCSS = $((Get-Content ($ScriptVariables.ScriptPath + 'style\' + $UsingTheme + '.css')) -Replace "(<style>|</style>)","").trim()
    $pscustomobj = $null
    foreach ( $obj in $PageCSS ) {
        if ( $obj -match "{" -and $Parent -eq $null ) {
            $Parent = [regex]::match($obj,".*[^{]").value.trim().tolower()
            $pscustomobj += @{
                [regex]::match($obj,".*[^{]").value.trim().tolower() = @{}
            }
        }
        elseif ( $obj -match "}" -and $Parent -ne $null ) {
            $Parent = $null
        }
        elseif ( $obj -match ":.*;" -and $Parent -ne $null ) {
            try {
                $pscustomobj.$Parent += @{
                    [regex]::match($obj,".*(?=:)").value.trim() = [regex]::match($obj,"(?<=:).*[^;]").value.trim()
                }
            }
            catch {
                $pscustomobj.$Parent.Remove($([regex]::match($obj,".*(?=:)").value.trim()))
                $pscustomobj.$Parent += @{
                    [regex]::match($obj,".*(?=:)").value.trim() = [regex]::match($obj,"(?<=:).*[^;]").value.trim()
                }
            }
        }
    }
    $pscustomobj
}