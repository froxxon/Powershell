$DC = Get-ADDomainController -Discover -Domain $Domain
$global:Domain = $( Get-ADDomain ).DNSRoot # domain.domain.com
$QueryGPOs = "Task-Server-Local*"
$GPOs = get-gpo -all | where { $_.DisplayName -like $QueryGPOs }
ForEach ( $GPO in $GPOs ) {
    $GPTINI= "\\$DC\SYSVOL\$Domain\Policies\{$($GPO.ID)}\GPT.INI"
    $GPTINIContent = Get-Content $GPTINI
    If ( $GPTINIContent -like "*New*" ) {
        "$($GPO.Displayname) - " | out-file C:\temp\LocalRightsGPOs.log -Append
        $GPTINI | out-file C:\temp\LocalRightsGPOs.log -Append
    }
}