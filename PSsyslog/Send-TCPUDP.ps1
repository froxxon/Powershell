function Send-UDPMessage
{
    param (
        [string] $EndPoint, 
        [int] $Port, 
        [string] $Message
    )
    $IP = [System.Net.Dns]::GetHostAddresses($EndPoint) 
    $Address = [System.Net.IPAddress]::Parse($IP) 
    $EndPoints = New-Object System.Net.IPEndPoint($Address, $Port) 
    $Socket = New-Object System.Net.Sockets.UDPClient 
    $EncodedText = [Text.Encoding]::ASCII.GetBytes($Message) 
    $SendMessage = $Socket.Send($EncodedText, $EncodedText.Length, $EndPoints) 
    $Socket.Close() 
} 

function Send-TCPMessage { 
    param ( 
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()] 
        [string]$EndPoint, 
        [Parameter(Mandatory=$true, Position=1)]
        [int]$Port, 
        [Parameter(Mandatory=$true, Position=2)]
        [string]$Message
    )
    process {
        $IP = [System.Net.Dns]::GetHostAddresses($EndPoint) 
        $Address = [System.Net.IPAddress]::Parse($IP) 
        $Socket = New-Object System.Net.Sockets.TCPClient($Address,$Port)    
        $Stream = $Socket.GetStream() 
        $Writer = New-Object System.IO.StreamWriter($Stream)
        $Message | % {
            $Writer.WriteLine($_)
            $Writer.Flush()
        }    
        $Stream.Close()
        $Socket.Close()
    }
}

Send-UDPMessage -Port 5516 -EndPoint 192.168.2.192 -Message "My first UDP message !"
#Send-TCPMessage -Port 5516 -Endpoint 192.168.2.192 -message "My first TCP message !"
