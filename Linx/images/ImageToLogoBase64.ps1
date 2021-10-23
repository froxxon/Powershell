$FilePath = "C:\RestPS\Linx\images\logo_default.png"
$([convert]::ToBase64String((get-content $FilePath -encoding byte))) | out-file C:\restps\linx\bin\linx_base64.txt