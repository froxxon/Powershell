import-module msonline
#get-command -module msonline

$msolcred = get-credential "" # <- Enter username for Azure
connect-msolservice -credential $msolcred

$SyncedUsers = get-msoluser -MaxResults 10
$AzureUsers = get-msoluser -MaxResults 10

$SyncedUsers.Count
$AzureUsers.Count

$SyncedUsers[1] | fl