# PSSyslog

This is a quick and dirty solution to get syslogs to your computer through Powershell, combined some own additions with already working scripts from the web.

**Start-PSSyslog.ps1** is used to start the actual socket to be able to receive the syslogs, port number, log file location etc. should be modified in this script.

**Get-PSSyslog.ps1** gets the data from alla the log-files in the script directory, using Out-gridview to display result, should be modified for miscellanious values. Another alternative could be to use Notepad++ or CMTrace for example.

**Send-TCPUDP.ps1** is used to send a test message by TCP or UDP to a receiving syslog server, the on started with '*Start-PSSyslog*' for example. ;)
