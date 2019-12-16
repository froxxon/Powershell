Added possibility to open an ADMX file directly by association, use below registry setting to achieve this:

HKEY_CURRENT_USER\Software\Classes\.admx_auto_file\shell\open\command

(Default)

powershell.exe -file "<PATH>\ADMXViewer.ps1" "%1"

(if it is ADMX with many settings it might take a while to open, no progress bar at this point showing anything until the window pops up)
