Import-Module ActiveDirectory
Clear-Host

$DomainDN = $(Get-ADDomain).DistinguishedName
$ClientPrefix = "*"
$Domain = $(Get-ADDomain).DNSRoot
$DomainShortName = $(Get-ADDomain).NetBIOSName
$SearchBase = "OU=Clients,$DomainDN"
$ServiceAccount = "" # <- Put the DHCP service account that should be owner of DNS records
$Clients = $(Get-ADComputer -Filter "Name -like '$ClientPrefix-*'" -SearchBase $SearchBase).Name
$WithAccount = @()
$WithoutAccount = @()

ForEach ( $Client in $($Clients )) {
    Try {
        $ClientDN = $(Get-DnsServerResourceRecord $Client -ZoneName $Domain -RRType A -ComputerName $Domain -ErrorAction SilentlyContinue ).DistinguishedName
    } Catch {}
    $Owner = $(Get-Acl -Path "ActiveDirectory:://RootDSE/$($ClientDN)" -ErrorAction SilentlyContinue).Owner
    If ( $Owner -ne "$DomainShortName\$ServiceAccount" -and $Owner -ne $Null ) {
        $WithoutAccount += $Client
        #Write-Host "$Counter. Client: $Client`tOwner: $Owner"
        #Remove-DnsServerResourceRecord $Client -ZoneName $Domain -RRType A -ComputerName $Domain -Force
    }
    ElseIf ( $Owner -eq "$DomainShortName\$ServiceAccount" -and $Owner -ne $Null ) {
        $WithAccount += $Client
    }
}
Write-host "Objects WIHTOUT $ServiceAccount as Owner: $($WithoutAccount.Count)"
Write-host "Objects WIHT $ServiceAccount as Owner: $($WithAccount.Count)"