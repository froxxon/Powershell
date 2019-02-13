Import-module 'C:\temp\SharedCode.psm1'
$LogFile = "C:\temp\Add-GroupsToRoles\Add-GroupsToRoles.log"

$Data = Get-Content "C:\temp\Add-GroupsToRoles\Groups.txt"

ForEach( $AllGroups in $Data ) {
    $Groups = $AllGroups -split ";"
    $DestGroup = $Groups[0]  
    $DestGroup = get-adgroup $DestGroup
    Write-Log
    Write-Log "Destinationgroup is $Destgroup"
    $GroupCount = $Groups.Count - 1
    Write-Log "Antal grupper som ska läggas till: $GroupCount" 
    $i = 0 
    ForEach ( $Group in $Groups ) {
	# Går igenom samtliga grupper i listan förutom den första kolumnen som är gruppen de resterande ska adderas till
        If( $i -ne 0 ) {
            $Group = get-adgroup $Group
            $GroupName = $Group.Name
            Try {
                Add-ADPrincipalGroupMembership -identity:$DestGroup -memberof:$Group
                Write-Log "($i) Addded $GroupName"                
            }
            Catch {
                Write-Log "($i) Couldn't add $GroupName" -LogType ERROR
            }
        }
        $i++
    }
}