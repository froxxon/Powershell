$nssm = "C:\Program Files\NSSM\nssm.exe"
$serviceName = 'Linx'
$powershell = (Get-Command powershell).Source
$scriptPath = 'C:\RestPS\Linx\Start-Service.ps1'
$arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
& $nssm install $serviceName $powershell $arguments
& $nssm status $serviceName
Start-Service $serviceName
Get-Service $serviceName

#& $nssm edit $serviceName
#& $nssm remove $serviceName confirm

$gMSAAccount = 'gmsa-linx'
install-adserviceaccount $gMSAAccount
test-adserviceaccount $gMSAAccount

#netsh http add sslcert ipport=192.168.1.24:443 certhash=CERTHASH "appid={2a81d04e-f236-17a7-b13a-3180fb3d91a5}" certstorename=My disablelegacytls=Enable
#netsh http show sslcert 
#netsh http delete sslcert 192.168.1.24:443