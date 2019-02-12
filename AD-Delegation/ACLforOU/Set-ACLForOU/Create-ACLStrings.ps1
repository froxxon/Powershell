import-module "C:\temp\sharedcode.psm1"
$ACLs = get-content "C:\temp\Get-ACLForOU\Get-ACLForOU.log"
$Logfile = "C:\temp\set-aclforou\Created ACL strings.txt"

ForEach ( $ACL in $ACLs ) {
    $Group = $($ACL -split ";")[0]
    $OU = $($ACL -split ";")[1]
    $ACL = $ACL.TrimStart("$Group;$OU;")
    Write-Log "Set-ACLForOU -Group ""$Group"" -OU ""$OU"" -AccessRights ""$ACL""" -WritePrefix No
}