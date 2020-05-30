$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$data = get-content "$ScriptDir\*.log"

$objTemplateObject = New-Object psobject
$objTemplateObject | Add-Member -MemberType NoteProperty -Name Time -Value $null
$objTemplateObject | Add-Member -MemberType NoteProperty -Name Source -Value $null
$objTemplateObject | Add-Member -MemberType NoteProperty -Name Source_Port -Value $null
$objTemplateObject | Add-Member -MemberType NoteProperty -Name Destination -Value $null
$objTemplateObject | Add-Member -MemberType NoteProperty -Name Destination_Port -Value $null

$objResult = @()
$rows = $data.split("`r`n")
foreach ( $row in $rows ) {
    if ( $row -ne "" ) {
        $objTemp = $objTemplateObject | Select-Object *
        $objTemp.Time = $row.split(" ")[2]
        foreach ( $item in $row.split(" ") ) {
            $matches.clear | out-null
            if ( $item -like 'SRC=*' ) {
                $item -match '(?<=SRC=).*' | out-null
                $objTemp.Source = $matches[0]
            }
            if ( $item -like 'SPT=*' ) {
                $item -match '(?<=SPT=).*' | out-null
                $objTemp.Source_Port = $matches[0]
            }
            if ( $item -like 'DST=*' ) {
                $item -match '(?<=DST=).*' | out-null
                $objTemp.Destination = $matches[0]
            }
            if ( $item -like 'DPT=*' ) {
                $item -match '(?<=DPT=).*' | out-null
                $objTemp.Destination_Port = $matches[0]
            }
        }
        $objResult += $objTemp
    }
}
$objResult | Sort-Object Time -Descending | Out-GridView -Wait