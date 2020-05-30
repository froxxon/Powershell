$SysLogPort = 514
$LogFolder = "C:\temp\PSsyslog\"
$LogFile = "PSsyslog-$((Get-Date).ToString("yyyy-MM-dd")).log"

$Socket = New-Object Net.Sockets.Socket([Net.Sockets.AddressFamily]::Internetwork,[Net.Sockets.SocketType]::Dgram,[Net.Sockets.ProtocolType]::Udp)
$ServerIPEndPoint = New-Object Net.IPEndPoint([Net.IPAddress]::Any,$SysLogPort)
try {
    $Socket.Bind($ServerIPEndPoint)
}
catch {
    write-output "Could not bind to socket"
    break
}

$SenderIPEndPoint = New-Object Net.IPEndPoint([Net.IPAddress]::Any, 0)
$SenderEndPoint = [Net.EndPoint]$SenderIPEndPoint

$Buffer = New-Object Byte[] 1024

Write-Output " "
Write-Output " PSSyslog receiving events."
Write-Output " Close this window to shut down the socket"

$ServerRunning = $True
While ($ServerRunning -eq $True) {
    $BytesReceived = $Socket.ReceiveFrom($Buffer, [Ref]$SenderEndPoint)
    $Message = $Buffer[0..$($BytesReceived - 1)]
    $MessageString = "$([Text.Encoding]::ASCII.GetString($Message))"
    if ( $MessageString -match $MsgContains ) {
        $MessageString | Out-File $LogFolder\$LogFile -Encoding utf8 -Append
    }
}