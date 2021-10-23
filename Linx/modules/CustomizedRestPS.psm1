#$global:ScriptVariables = @{ ScriptPath = $PSCommandPath }
$global:ScriptVariables += @{ 
    LinksFilePath    = $ScriptVariables.ScriptPath + 'bin\links.csv'
    RemovedLinksPath = $ScriptVariables.ScriptPath + 'bin\removed_links.csv'
    PersonalPath     = $ScriptVariables.ScriptPath + 'bin\personal'
    LogChangesPath   = $ScriptVariables.ScriptPath + 'logs\changes.log'
    LogRestPSPath    = $ScriptVariables.ScriptPath + 'logs\RestPS.log'
    SettingsPath     = $ScriptVariables.ScriptPath + 'settings\'
    RegExpsPath      = $ScriptVariables.ScriptPath + 'settings\regexps.json'
    LanguagePath     = $ScriptVariables.ScriptPath + 'lang\'
    Logo             = Get-Content ($ScriptVariables.ScriptPath + 'images\logo_base64.txt')
}
(Get-Content ($($ScriptVariables.ScriptPath) + 'base_settings.json') | ConvertFrom-Json).PSObject.Properties | foreach { $ScriptVariables[$_.Name] = $_.Value }
(Get-Content ($($ScriptVariables.ScriptPath) + 'settings\custom_settings.json') | ConvertFrom-Json).PSObject.Properties | foreach { $ScriptVariables[$_.Name] = $_.Value }
$ScriptVariables.CSSpath = $ScriptVariables.ScriptPath + 'style\' + $ScriptVariables.Theme + '.css'
$ScriptVariables.Text = $ScriptVariables.Text = @{} ; (Get-Content ($ScriptVariables.LanguagePath + $ScriptVariables.Language + '.json') | ConvertFrom-Json).PSObject.Properties | foreach { $ScriptVariables.Text[$_.Name] = $_.Value } | Sort Name
$ScriptVariables.Regex = $ScriptVariables.Regex = @{} ; (Get-Content $ScriptVariables.RegExpsPath | ConvertFrom-Json).PSObject.Properties | foreach { $ScriptVariables.Regex[$_.Name] = $_.Value } | Sort Name
$global:Logfile = $ScriptVariables.LogChangesPath
[array]$Global:EditMembers = (New-Object adsisearcher([adsi]"LDAP://$($ScriptVariables.OU_Group)","(name=$($ScriptVariables.EditGroup))")).FindOne().Properties.member
[array]$Global:AdminMembers = (New-Object adsisearcher([adsi]"LDAP://$($ScriptVariables.OU_Group)","(name=$($ScriptVariables.AdminGroup))")).FindOne().Properties.member

function Import-RouteSet {
    [CmdletBinding()]
    [OutputType([Hashtable])]

    param(
        [Parameter(Mandatory = $true)][String]$RoutesFilePath
    )

    if (Test-Path -Path $RoutesFilePath) {
        $script:Routes = Get-Content -Raw $RoutesFilePath | ConvertFrom-Json
    }
    else {
        Throw "Import-RouteSet - Could not validate Path $RoutesFilePath"
    }
}

function Invoke-GetBody {
    if ($script:Request.HasEntityBody) {
        $script:RawBody = $script:Request.InputStream
        $Reader = New-Object System.IO.StreamReader @($script:RawBody, [System.Text.Encoding]::UTF8)
        $script:Body = $Reader.ReadToEnd()
        $Reader.close()
        $script:Body
    }
    else {
        $script:Body = "null"
        $script:Body
    }
}

function Invoke-GetContext {
    $script:context = $listener.GetContext()
    $Request = $script:context.Request
    $Request
}

function Invoke-RequestRouter {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", '')]
    [OutputType([boolean])]
    [OutputType([Hashtable])]
    param(
        [Parameter(Mandatory = $true)][String]$RequestType,
        [Parameter(Mandatory = $true)][String]$RequestURL,
        [Parameter(Mandatory = $false)][String]$RequestArgs,
        [Parameter()][String]$RoutesFilePath
    )
    # Import Routes each pass, to include new routes.
    Import-RouteSet -RoutesFilePath $RoutesFilePath
    $Route = ($Routes | Where-Object {$_.RequestType -eq $RequestType -and $_.RequestURL -eq $RequestURL})

    if ($null -ne $Route) {
        # Process Request
        $RequestCommand = $Route.RequestCommand
        set-location $PSScriptRoot
        if ($RequestCommand -like "*.ps1") {
            # Execute Endpoint Script
            $CommandReturn = . $RequestCommand -RequestArgs $RequestArgs -Body $script:Body
        }
        else {
            # Execute Endpoint Command (No body allowed.)
            $Command = $RequestCommand + " " + $RequestArgs
            $CommandReturn = Invoke-Expression -Command "$Command" -ErrorAction SilentlyContinue
        }

        if ($null -eq $CommandReturn) {
            # Not a valid response
            $script:StatusDescription = "Bad Request"
            $script:StatusCode = 400
        }
        else {
            # Valid response
            $script:result = $CommandReturn
            $script:StatusDescription = "OK"
            $script:StatusCode = 200
        }
    }
    else {
        # No matching Routes
        $script:StatusDescription = "Not Found"
        $script:StatusCode = 404
    }
    $script:result
}

function Invoke-StartListener {
    param(
        [Parameter(Mandatory = $true)][String]$Port,
        [Parameter()][String]$SSLThumbprint #,
    )
    if ($SSLThumbprint) {
        # Verify the Certificate with the Specified Thumbprint is available.
        $CertificateListCount = ((Get-ChildItem -Path Cert:\LocalMachine -Recurse | Where-Object {$_.Thumbprint -eq "$SSLThumbprint"}) | Measure-Object).Count
        if ($CertificateListCount -ne 0)
        {
            # SSL Thumbprint present, enabling SSL
            #netsh http delete sslcert ipport=0.0.0.0:$Port
            #netsh http add sslcert ipport=0.0.0.0:$Port certhash=$SSLThumbprint "appid={$AppGuid}"
            # the above steps is run manually beforehand to skip adminprivileges
            $Prefix = "https://"
        }
        else {
            Throw "Invoke-StartListener: Could not find Matching Certificate in CertStore: Cert:\LocalMachine"
        }
    }
    else {
        # No SSL Thumbprint present
        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Invoke-StartListener: No SSL Thumbprint present"
        $Prefix = "http://"
    }

    try {
        $listener.Prefixes.Add("$($Prefix)$($ScriptVariables.ShortURL):$Port/")
        $listener.Start()
        $Host.UI.RawUI.WindowTitle = "RestPS - $Prefix - Port: $Port"
        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-StartListener: Starting: $Prefix Listener on Port: $Port"
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Throw "Invoke-StartListener: $ErrorMessage $FailedItem"
    }
}

function Invoke-StopListener {
    param(
        [Parameter()][String]$Port = 8080
    )
    Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-StopListener: Stopping HTTP Listener on port: $Port ..."
    $listener.Stop()
}

function Invoke-StreamOutput {
    # Setup a placeholder to deliver a response
    $script:Response = $script:context.Response
    # Convert the returned data to JSON and set the HTTP content type to JSON
    #$script:Response.ContentType = 'application/json'
    $script:Response.ContentType = 'text/html'   # Modified to be able to output as HTML
    $script:Response.StatusCode = $script:StatusCode
    $script:Response.StatusDescription = $script:StatusDescription
    # Process the Return data to send Json message back.
    #$message = $script:result | ConvertTo-Json
    $message = $script:result  # Modified to be able to output as HTML
    # Convert the data to UTF8 bytes
    [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes("$message")
    # Set length of response
    $script:Response.ContentLength64 = $buffer.length
    # Write response out and close
    $script:Response.OutputStream.Write($buffer, 0, $buffer.length)
    $script:Response.Close()
}

function Start-RestPSListener {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Low"
    )]
    [OutputType([boolean])]
    [OutputType([Hashtable])]
    [OutputType([String])]
    param(
        [Parameter()][String]$RoutesFilePath = "$env:SystemDrive/RestPS/endpoints/RestPSRoutes.json",
        [Parameter()][String]$RestPSLocalRoot = "$env:SystemDrive/RestPS",
        [Parameter()][String]$Port = 8080,
        [Parameter()][String]$SSLThumbprint,
        [Parameter()][String]$Logfile = "$env:SystemDrive/RestPS/RestPS.log",
        [ValidateSet("ALL", "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "CONSOLEONLY", "OFF")]
        [Parameter()][String]$LogLevel = "INFO"
    )
    # Set a few Flags
    $script:Status = $true
    $script:ValidateClient = $true
    if ($pscmdlet.ShouldProcess("Starting .Net.HttpListener.")) {
        $script:listener = New-Object System.Net.HttpListener
        $listener.AuthenticationSchemes = 'Negotiate'
        $listener.UnsafeConnectionNtlmAuthentication = $true
        $listener.IgnoreWriteExceptions = $true

        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Calling Invoke-StartListener"
        Invoke-StartListener -Port $Port -SSLThumbPrint $SSLThumbprint #-AppGuid $AppGuid
        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Finished Calling Invoke-StartListener"
        # Run until you send a GET request to /shutdown
        Do {
            # Capture requests as they come in (not Asyncronous)
            # Routes can be configured to be Asyncronous in Nature.
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Captured incoming request"
            $script:Request = Invoke-GetContext
            $script:ProcessRequest = $true
            $script:result = $null

            # Determine if a Body was sent with the Client request
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Executing Invoke-GetBody"
            $script:Body = Invoke-GetBody

            # Request Handler Data
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Determining Method and URL"
            $RequestType = $script:Request.HttpMethod
            $RawRequestURL = $script:Request.RawUrl
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Start-RestPSListener: New Request - Method: $RequestType URL: $RawRequestURL"
            # Specific args will need to be parsed in the Route commands/scripts
            $RequestURL, $RequestArgs = $RawRequestURL.split("?")

            if ($script:ProcessRequest -eq $true) {
                # Break from loop if GET request sent to /shutdown
                Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Processing Request, Checking for Shutdown Command"
                if ($RequestURL -match '/EndPoint/Shutdown$') {
                    Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Shutting down RestEndpoint"
                    $script:result = "Shutting down RESTPS Endpoint."
                    $script:Status = $false
                    $script:StatusCode = 200
                }
                else {
                    # Attempt to process the Request.
                    Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Start-RestPSListener: Processing RequestType: $RequestType URL: $RequestURL Args: $RequestArgs"
                    $script:result = Invoke-RequestRouter -RequestType "$RequestType" -RequestURL "$RequestURL" -RoutesFilePath "$RoutesFilePath" -RequestArgs "$RequestArgs"
                    Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Start-RestPSListener: Finished request. StatusCode: $script:StatusCode StatusDesc: $Script:StatusDescription"
                }
            }
            else {
                Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Start-RestPSListener: Unauthorized (401) NOT Processing RequestType: $RequestType URL: $RequestURL Args: $RequestArgs"
                $script:StatusDescription = "Unauthorized"
                $script:StatusCode = 401
            }
            # Stream the output back to requestor.
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Streaming response back to requestor."
            Invoke-StreamOutput
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Streaming response is complete."
        } while ($script:Status -eq $true)
        #Terminate the listener
        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Stopping Listener."
        Invoke-StopListener -Port $Port
        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Listener Stopped."
    }
    else {
        # -WhatIf was used.
        return $false
    }
}

function Compare-Weekday {
    <#
	.DESCRIPTION
		Determine if the day of the week has changed since the last check.
    .PARAMETER Weekday
        A valid Day of the week is required.
	.EXAMPLE
        Compare-Weekday -Weekday Tuesday
	.NOTES
        It will return boolean
    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param(
        $Weekday = $null
    )
    
    if ($null -eq $Weekday) {
        # No day was passed in (This is acceptable.)
        Return $false
    }
    else {
        $CurrentDay = (Get-Date).DayOfWeek
        if ($CurrentDay -eq $Weekday) {
            # The days match.
            $true
        }
        else {
            # The days do not match.
            $false
        }
    }
}

function Get-Timestamp {
    try {
        return $(get-date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Throw "Get-Timestamp: $ErrorMessage $FailedItem"
    }
}

function Write-Message {
    <#
	.SYNOPSIS
		Function to write log files, option to print to console.
	.DESCRIPTION
		Writes messages to log file and optional console.
	.PARAMETER Message
		Please Specify a message.
	.PARAMETER Logfile
		Please Specify a valid logfile.
	.PARAMETER OutputStyle
		Please specify an output OutputStyle.
	.EXAMPLE
		Write-Message -Message "I love lamp" -Logfile "C:\temp\mylog.log" -OutputStyle noConsole
	.EXAMPLE
		Write-Message -Message "I love lamp" -Logfile "C:\temp\mylog.log" -OutputStyle both
	.EXAMPLE
		Write-Message -Message "I love lamp" -Logfile "C:\temp\mylog.log" -OutputStyle consoleOnly
	.EXAMPLE
		Write-Message -Message "I love lamp" -Logfile "C:\temp\mylog.log"
	.EXAMPLE
		Write-Message -Message "I love lamp" -OutputStyle ConsoleOnly
	.NOTES
		No Additional information about the function or script.
	#>
    [CmdletBinding(DefaultParameterSetName = 'LogFileFalse')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'LogFileTrue')]
        [Parameter(Mandatory = $true, ParameterSetName = 'LogFileFalse')]
        [string]$Message,
        [Parameter(Mandatory = $true, ParameterSetName = 'LogFileTrue')]
        [string]$Logfile,
        [Parameter(Mandatory = $false, ParameterSetName = 'LogFileTrue')]
        [Parameter(Mandatory = $true, ParameterSetName = 'LogFileFalse')]
        [validateset('ConsoleOnly', 'Both', 'noConsole','None', IgnoreCase = $true)]
        [string]$OutputStyle
    )
    
    try {
        $dateNow = Get-Timestamp
        switch ($OutputStyle) {
            ConsoleOnly {
                Write-Output ""
                Write-Output "$dateNow $Message"
            }
            None {
                # Do Nothing
            }
            Both {
                Write-Output ""
                Write-Output "$dateNow $Message"
                if (!(Test-Path $logfile -ErrorAction SilentlyContinue)) {
                    Write-Warning "Logfile does not exist."
                    New-Log -Logfile $Logfile
                }
                Write-Output "$dateNow $Message" | Out-File $Logfile -append -encoding utf8
            }
            noConsole {
                if (!(Test-Path $logfile -ErrorAction SilentlyContinue)) {
                    Write-Warning "Logfile does not exist."
                    New-Log -Logfile $Logfile
                }
                Write-Output "$dateNow $Message" | Out-File $Logfile -append -encoding utf8
            }
            default {
                Write-Output ""
                Write-Output "$dateNow $Message"
                if (!(Test-Path $logfile -ErrorAction SilentlyContinue)) {
                    Write-Warning "Logfile does not exist."
                    New-Log -Logfile $Logfile
                }
                Write-Output "$dateNow $Message" | Out-File $Logfile -append -encoding utf8
            }
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Throw "Write-Message: $ErrorMessage $FailedItem"
    }
}

function Clear-LogDirectory {
    <#
	.SYNOPSIS
		Clears logs in a directory older than the specified number of days.
	.DESCRIPTION
		Clears logs in a directory older than the specified number of days.
	.PARAMETER Path
		Please Specify a valid path.
	.PARAMETER Daysback
		Please Specify a number of daysback.
	.EXAMPLE
		Clear-LogDirectory -Path "c:\temp" -DaysBack 3
	.NOTES
		No Additional information about the function or script.
	#>
    param(
        [cmdletbinding()]
        [Parameter(Mandatory = $true)]
        [ValidateScript( {Test-Path $_ })]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [int]$DaysBack
    )
    
    try {
        $DatetoDelete = (Get-Date).AddDays( - $Daysback)
        if (! (Get-ChildItem $Path)) {
            Write-Message -Message "Path is not valid" -OutputStyle consoleOnly
        }
        else {
            Get-ChildItem $Path -Recurse  | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item -Recurse -Confirm:$false
            Write-Message -Message "Logs older than $DaysBack have been cleared!" -OutputStyle consoleOnly
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Throw "Clear-LogDirectory: $ErrorMessage $FailedItem"
    }
}

function Invoke-RollLog {
    <#
	.DESCRIPTION
		This function will Roll the log file if it is a new week day.
    .PARAMETER LogFile
        A valid file path is required.
    .PARAMETER Weekday
        A valid Weekday in datetime format is required.
	.EXAMPLE
        Invoke-RollLogs -LogFile "c:\temp\test.log" -Weekday Tuesday
	.NOTES
        It's pretty simple.
    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param(
        [Parameter(Mandatory = $true)][string]$Logfile,
        [Parameter(Mandatory = $true)][string]$Weekday

    )

    try {
        if (!(Test-Path -Path $Logfile)) {
            Write-Message -Message "#################### New Log created #####################" -Logfile $logfile -OutputStyle both
            Throw "LogFile path: $Logfile does not exist."
        }
        else {
            # Determine if its a new day
            if (Compare-Weekday -Weekday $Script:Weekday) {
                # The Day of the week has not changed.
                Return $true
            }
            else {
                # The day of the week has changed.
                $CurrentTime = Get-Date -Format MMddHHmm
                $OldLogName = "$currentTime.log"
                Rename-Item -Path $logfile -NewName $OldLogName -Force -Confirm:$false
                # Create a new log.
                Write-Message -Message "#################### New Log created #####################" -Logfile $logfile
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Throw "Invoke-RollLog: $ErrorMessage $FailedItem"
    }
}

function New-Log {
    <#
	.SYNOPSIS
		Clears logs in a directory older than the specified number of days.
	.DESCRIPTION
		Clears logs in a directory older than the specified number of days.
	.PARAMETER Logfile
		Please Specify a valid path and file name.
	.EXAMPLE
		New-Log -Logfile c:\temp\new.log
	.NOTES
		No Additional information about the function or script.
	#>
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Logfile
    )
    
    try {
        if ( !(Split-Path -Path $Logfile -ErrorAction SilentlyContinue)) {
            Write-Message -Message "Creating new Directory." -OutputStyle consoleOnly
            if ($PSCmdlet.ShouldProcess("Creating new Directory")) {New-Item (Split-Path -Path $Logfile) -ItemType Directory -Force}
        }
        Write-Message -Message "Creating new file." -OutputStyle consoleOnly
        if ($PSCmdlet.ShouldProcess("Creating new File")) {New-Item $logfile -type file -force -value "New file created."}
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Throw "New-Log: $ErrorMessage $FailedItem"
    }
}

function Write-Log {
    <#
	.SYNOPSIS
		Function to write information to  log files, based on a set LogLevel.
	.DESCRIPTION
        Writes messages to log file based on a set LogLevel.
        -LogLevel is the System Wide setting.
        -MsgType is specific to a message.
	.PARAMETER Message
		Please Specify a message.
	.PARAMETER Logfile
		Please Specify a valid logfile.
	.PARAMETER LogLevel
		Please specify a Running Log Level.
	.PARAMETER MsgType
		Please specify a Message Log Level.
	.EXAMPLE
		Write-Log -Message "I love lamp" -Logfile "C:\temp\mylog.log" -LogLevel All -MsgType TRACE
	.EXAMPLE
		Write-Log -Message "I love lamp" -Logfile "C:\temp\mylog.log" -LogLevel TRACE -MsgType TRACE
	.EXAMPLE
		Write-Log -Message "I love lamp" -Logfile "C:\temp\mylog.log" -LogLevel DEBUG -MsgType DEBUG
	.EXAMPLE
		Write-Log -Message "I love lamp" -Logfile "C:\temp\mylog.log" -LogLevel INFO -MsgType INFO
	.EXAMPLE
		Write-Log -Message "I love lamp" -Logfile "C:\temp\mylog.log" -LogLevel WARN -MsgType WARN
	.EXAMPLE
		Write-Log -Message "I love lamp" -Logfile "C:\temp\mylog.log" -LogLevel ERROR -MsgType ERROR
	.EXAMPLE
		Write-Log -Message "I love lamp" -Logfile "C:\temp\mylog.log" -LogLevel FATAL -MsgType FATAL
	.EXAMPLE
		Write-Log -Message "I love lamp" -Logfile "C:\temp\mylog.log" -LogLevel CONSOLEONLY -MsgType CONSOLEONLY
	.EXAMPLE
		Write-Log -Message "I love lamp" -Logfile "C:\temp\mylog.log" -LogLevel OFF -MsgType OFF
	.NOTES
		No Additional information about the function or script.
	#>
    [CmdletBinding(DefaultParameterSetName = 'LogFileFalse')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'LogFileTrue')]
        [Parameter(Mandatory = $true, ParameterSetName = 'LogFileFalse')]
        [string]$Message,
        [Parameter(Mandatory = $true, ParameterSetName = 'LogFileTrue')]
        [string]$Logfile = $global:Logfile,
        [Parameter(ParameterSetName = 'LogFileTrue')]
        [Parameter(ParameterSetName = 'LogFileFalse')]
        [ValidateSet("ALL", "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "CONSOLEONLY", "OFF")]
        [string]$LogLevel = "INFO",
        [Parameter(ParameterSetName = 'LogFileTrue')]
        [Parameter(ParameterSetName = 'LogFileFalse')]
        [ValidateSet("TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "CONSOLEONLY")]
        [string]$MsgType = "INFO"
    )

    try {
        $Message = $MsgType + ": " + $Message
        if (($Logfile -eq "") -or ($null -eq $logfile)) {
            Write-Message -Message $Message -OutputStyle $OutPutStyle
        }
        else {
            Write-Message -Message $Message -Logfile $Logfile -OutputStyle noConsole
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Throw "Write-Log: $ErrorMessage $FailedItem"
    }
}