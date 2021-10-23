$global:ScriptVariables = @{ ScriptPath = ([regex]::match($PSCommandPath,".*(?:\\)")).Value }
if ( $psISE ) { $ScriptVariables.ScriptPath = ([regex]::match($psISE.CurrentFile.FullPath,".*(?:\\)")).Value }
import-module "$($ScriptVariables.ScriptPath)\modules\CustomizedRestPS.psm1" -force
import-module "$($ScriptVariables.ScriptPath)\modules\Internal-CmdLets.psm1" -force

$RestPSparams = @{
            RestPSLocalRoot  = $ScriptVariables.ScriptPath
            RoutesFilePath   = "$($ScriptVariables.ScriptPath)\endpoints\Routes.json"
            LogFile          = $ScriptVariables.LogRestPSPath
            LogLevel         = 'Info'
            Port             = $ScriptVariables.Port
            SSLThumbprint    = $ScriptVariables.SSLThumbprint
        }

Start-RestPSListener @RestPSparams