Clear-Host
Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
cd a01:
$Subnets = @("Bound01")
$SiteSystemServer = @("server01.domain.local","server02.domain.local")

ForEach ( $Subnet in $Subnets ) {
    Try {
        Set-CMBoundaryGroup -Name "Production - Central content - $Subnet" -AddSiteSystemServerName $SiteSystemServer
        Write-host "Added servers to boundary group for subnet $Subnet"
    }
    Catch {
        Write-host "Failed to add servers to boundary group for subnet $Subnet"
    }
}