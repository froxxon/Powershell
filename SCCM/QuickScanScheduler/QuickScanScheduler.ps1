Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
cd a01:

Function Write-Log ($LogInput) {
    If ($LogInput -eq $Null) {	
        " " | Out-File -File $LogFile -Append
    }
    Else {
        $CurrentDateTime = Get-Date -format "yyyy-MM-dd HH:mm"
	    $CurrentDateTime + “ - " + $LogInput | Out-File -File $LogFile -Append
    }
}

$SiteServer = "" # <- Enter Site Server
$SiteCode = "" # <- Enter Site Code
$Date = Get-Date -format "yyyy-MM-dd"
$LogFile = "C:\Temp\QuickScanScheduler\QuickScanScheduler $Date.log"
$CollectionName = "SHD.EPSS#No QuickScan Collection"
$NoQuickScanCollectionName = "SHD.EPSS#No QuickScan Collection"
$StandardCollection = $False

$AddedToCollectionCount = 0
$AddedEarlierCount = 0

Write-Log
Write-Log "--- Start of log ---"
Write-Log

$QuickScanCollections = Get-WMIObject -ComputerName $siteServer -NameSpace "ROOT\SMS\site_$SiteCode" -Class SMS_Collection | where {$_.Name -like "*SHD.EPSS#Servers - QuickScan - *"}
Write-Log "Found QuickScan-collections:"

$Counter = 0 ; $IndexCounter = 0 ; $LowestCount = 0 

ForEach ($QuickScanCollection in $QuickScanCollections) {
	$QuickScanCollectionCount = Get-WmiObject -ComputerName $SiteServer -Namespace "ROOT\SMS\site_$SiteCode" -Query "SELECT * FROM SMS_FullCollectionMembership WHERE CollectionID='$($QuickScanCollection.CollectionID)' order by name" | select Name
	If ($IndexCounter -eq 0) {$LowestCount = $QuickScanCollectionCount.Count}
	If ($QuickScanCollectionCount.Count -lt $LowestCount) {$Counter = $IndexCounter}
	If ($QuickScanCollectionCount.Count -lt $LowestCount) {$LowestCount = $QuickScanCollectionCount.Count}
	$IndexCounter++
	Write-Log $QuickScanCollection.Name
}

Write-Log

If ( $CollectionName -eq $NoQuickScanCollectionName ) {
	Write-Log '$CollectionName and $NoQuickScanCollectionName is the same, skip to check for members in $NoQuickScanCollectionName'
	Write-Log
	$StandardCollection = $True
	$AlreadyInQuickScanCollection = $False
}

$Temp = 'The variable $StandardCollection is: ' + $StandardCollection
Write-Log $Temp

Write-Log
Write-Log "This collection contains the least amount of members and will be used first: "
Write-Log $QuickScanCollections[$Counter].Name
Write-Log

If ( $StandardCollection -eq $False ) {
    Write-Log "Gets the objects of collection: $NoQuickScanCollectionName"
    $NoQuickScanCollectionMembers = Get-WmiObject -ComputerName $SiteServer -Namespace "ROOT\SMS\site_$SiteCode" -Query "SELECT * FROM SMS_FullCollectionMembership WHERE CollectionID='A0100171' order by name" | select name
	$Temp = "Object count: " + $NoQuickScanCollectionMembers.Count
	Write-Log $Temp
	Write-Log
}

Write-Log "Gets the objects of collection: $CollectionName"
$GetCollectionID = get-wmiobject -ComputerName $siteServer -NameSpace "ROOT\SMS\site_$SiteCode" -Class SMS_Collection | where {$_.Name -like "$CollectionName*"} | select CollectionID
$CollectionMembers = Get-WmiObject -ComputerName $SiteServer -Namespace "ROOT\SMS\site_$SiteCode" -Query "SELECT * FROM SMS_FullCollectionMembership WHERE CollectionID='$($GetCollectionID.CollectionID)' order by name" | select Name, ResourceID
$Temp = "Object count: " + $CollectionMembers.Count
Write-Log $Temp
Write-Log

remove-variable QuickScanCollectionsMembers
$GetCollectionIDs = get-wmiobject -ComputerName $siteServer -NameSpace "ROOT\SMS\site_$SiteCode" -Class SMS_Collection | where {$_.Name -like "SHD.EPSS#Servers - QuickScan - *"} | select CollectionID
ForEach ($QuickScanCollectionID in $GetCollectionIDs) {
    $QuickScanCollectionsMembers += (Get-WmiObject -ComputerName $SiteServer -Namespace "ROOT\SMS\site_$SiteCode" -Query "SELECT * FROM SMS_FullCollectionMembership WHERE CollectionID='$($QuickScanCollectionID.CollectionID)' order by name" | select Name)
}

Write-Log "Added servers:"
ForEach ($Computer in $CollectionMembers) {
    $AlreadyInQuickScanCollection = $False
	If ( $StandardCollection -eq $False ) {
		If ($QuickScanCollectionsMembers.Name -contains $Computer.Name) {
			$AlreadyInQuickScanCollection = $True
        }
        Else {
            $AlreadyInQuickScanCollection = $False
        }
    }
	If ( $AlreadyInQuickScanCollection -eq $False ) {
		Add-CMDeviceCollectionDirectMembershipRule -CollectionName $QuickScanCollections[$Counter].Name -ResourceID $Computer.ResourceID
		$Temp =  $Computer.Name + " is added to the collection: " + $QuickScanCollections[$Counter].Name
		Write-Log $Temp
        $AddedToCollectionCount++
	}
	Else {
        $AddedEarlierCount++
        Continue
	}
	If ($Counter -lt $QuickScanCollections.Count) {$Counter++}
	If ($Counter -eq $QuickScanCollections.Count) {$Counter = 0}
}

Write-Log
Write-Log "Count of servers added to QuickScan collections: $AddedToCollectionCount"
Write-Log "Count of servers added earlier to QuickScan collections: $AddedEarlierCount"
Write-Log
Write-Log "--- End of log ---"
Write-Log