################################################################################################
# POPADD.psm1
# 
# AUTHOR: Robin Granberg (robin.granberg@microsoft.com)
#
# THIS CODE-SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED 
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR 
# FITNESS FOR A PARTICULAR PURPOSE.
#
# This sample is not supported under any Microsoft standard support program or service. 
# The script is provided AS IS without warranty of any kind. Microsoft further disclaims all
# implied warranties including, without limitation, any implied warranties of merchantability
# or of fitness for a particular purpose. The entire risk arising out of the use or performance
# of the sample and documentation remains with you. In no event shall Microsoft, its authors,
# or anyone else involved in the creation, production, or delivery of the script be liable for 
# any damages whatsoever (including, without limitation, damages for loss of business profits, 
# business interruption, loss of business information, or other pecuniary loss) arising out of 
# the use of or inability to use the sample or documentation, even if Microsoft has been advised 
# of the possibility of such damages.
################################################################################################

#PowerShell module for POP - Active Directory Delegation (POPADD)

############ Functions Collection Start ##################

Add-Type -Path "$($PSScriptRoot)\EPPlus.dll"
. $PSScriptRoot\Export-Excel.ps1


$global:dicSidToName = @{"Seed" = "xxx"} 
$global:dicWellKnownSids = @{"S-1-0"="Null Authority";`
"S-1-0-0"="Nobody";`
"S-1-1"="World Authority";`
"S-1-1-0"="Everyone";`
"S-1-2"="Local Authority";`
"S-1-2-0"="Local ";`
"S-1-2-1"="Console Logon ";`
"S-1-3"="Creator Authority";`
"S-1-3-0"="Creator Owner";`
"S-1-3-1"="Creator Group";`
"S-1-3-2"="Creator Owner Server";`
"S-1-3-3"="Creator Group Server";`
"S-1-3-4"="Owner Rights";`
"S-1-4"="Non-unique Authority";`
"S-1-5"="NT Authority";`
"S-1-5-1"="Dialup";`
"S-1-5-2"="Network";`
"S-1-5-3"="Batch";`
"S-1-5-4"="Interactive";`
"S-1-5-6"="Service";`
"S-1-5-7"="Anonymous";`
"S-1-5-8"="Proxy";`
"S-1-5-9"="Enterprise Domain Controllers";`
"S-1-5-10"="Principal Self";`
"S-1-5-11"="Authenticated Users";`
"S-1-5-12"="Restricted Code";`
"S-1-5-13"="Terminal Server Users";`
"S-1-5-14"="Remote Interactive Logon";`
"S-1-5-15"="This Organization";`
"S-1-5-17"="IUSR";`
"S-1-5-18"="Local System";`
"S-1-5-19"="NT Authority";`
"S-1-5-20"="NT Authority";`
"S-1-5-22"="ENTERPRISE READ-ONLY DOMAIN CONTROLLERS BETA";`
"S-1-5-32-544"="Administrators";`
"S-1-5-32-545"="Users";`
"S-1-5-32-546"="Guests";`
"S-1-5-32-547"="Power Users";`
"S-1-5-32-548"="BUILTIN\Account Operators";`
"S-1-5-32-549"="Server Operators";`
"S-1-5-32-550"="Print Operators";`
"S-1-5-32-551"="Backup Operators";`
"S-1-5-32-552"="Replicator";`
"S-1-5-32-554"="BUILTIN\Pre-Windows 2000 Compatible Access";`
"S-1-5-32-555"="BUILTIN\Remote Desktop Users";`
"S-1-5-32-556"="BUILTIN\Network Configuration Operators";`
"S-1-5-32-557"="BUILTIN\Incoming Forest Trust Builders";`
"S-1-5-32-558"="BUILTIN\Performance Monitor Users";`
"S-1-5-32-559"="BUILTIN\Performance Log Users";`
"S-1-5-32-560"="BUILTIN\Windows Authorization Access Group";`
"S-1-5-32-561"="BUILTIN\Terminal Server License Servers";`
"S-1-5-32-562"="BUILTIN\Distributed COM Users";`
"S-1-5-32-568"="BUILTIN\IIS_IUSRS";`
"S-1-5-32-569"="BUILTIN\Cryptographic Operators";`
"S-1-5-32-573"="BUILTIN\Event Log Readers ";`
"S-1-5-32-574"="BUILTIN\Certificate Service DCOM Access";`
"S-1-5-32-575"="BUILTIN\RDS Remote Access Servers";`
"S-1-5-32-576"="BUILTIN\RDS Endpoint Servers";`
"S-1-5-32-577"="BUILTIN\RDS Management Servers";`
"S-1-5-32-578"="BUILTIN\Hyper-V Administrators";`
"S-1-5-32-579"="BUILTIN\Access Control Assistance Operators";`
"S-1-5-32-580"="BUILTIN\Remote Management Users";`
"S-1-5-33"="Write Restricted Code";`
"S-1-5-64-10"="NTLM Authentication";`
"S-1-5-64-14"="SChannel Authentication";`
"S-1-5-64-21"="Digest Authentication";`
"S-1-5-65-1"="This Organization Certificate";`
"S-1-5-80"="NT Service";`
"S-1-5-84-0-0-0-0-0"="User Mode Drivers";`
"S-1-5-113"="Local Account";`
"S-1-5-114"="Local Account And Member Of Administrators Group";`
"S-1-5-1000"="Other Organization";`
"S-1-15-2-1"="All App Packages";`
"S-1-16-0"="Untrusted Mandatory Level";`
"S-1-16-4096"="Low Mandatory Level";`
"S-1-16-8192"="Medium Mandatory Level";`
"S-1-16-8448"="Medium Plus Mandatory Level";`
"S-1-16-12288"="High Mandatory Level";`
"S-1-16-16384"="System Mandatory Level";`
"S-1-16-20480"="Protected Process Mandatory Level";`
"S-1-16-28672"="Secure Process Mandatory Level";`
"S-1-18-1"="Authentication Authority Asserted Identityl";`
"S-1-18-2"="Service Asserted Identity"}
#==========================================================================
# Function		: GetAllDomains
# Arguments     : n/a
# Returns   	: list of domains in the forest
# Description   : Searches in configuration partition for domains and return the DN of all domains.
#==========================================================================
Function GetAllDomains
{

$arrPartitions = New-Object System.Collections.ArrayList
$arrPartitions.Clear()

$LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection("")
$LDAPConnection.SessionOptions.ReferralChasing = "None"
$request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
[void]$request.Attributes.Add("dnshostname")
[void]$request.Attributes.Add("supportedcapabilities")
[void]$request.Attributes.Add("namingcontexts")
[void]$request.Attributes.Add("defaultnamingcontext")
[void]$request.Attributes.Add("schemanamingcontext")
[void]$request.Attributes.Add("configurationnamingcontext")
[void]$request.Attributes.Add("rootdomainnamingcontext")
[void]$request.Attributes.Add("isGlobalCatalogReady")                
try
{
    $response = $LDAPConnection.SendRequest($request)
    $bolLDAPConnection = $true
}
catch
{
	$bolLDAPConnection = $false
}
if($bolLDAPConnection -eq $true)
{
    $global:ForestRootDomainDN = $response.Entries[0].attributes.rootdomainnamingcontext[0]
    $global:SchemaDN = $response.Entries[0].attributes.schemanamingcontext[0]
    $global:ConfigDN = $response.Entries[0].attributes.configurationnamingcontext[0]
    $global:strDomainDNName = $response.Entries[0].attributes.defaultnamingcontext[0]
    $global:IS_GC = $response.Entries[0].Attributes.isglobalcatalogready[0]
}

#Get all NC and Domain partititons
$request = New-Object System.directoryServices.Protocols.SearchRequest("CN=Partitions,$global:ConfigDN ", "(&(cn=*)(systemFlags:1.2.840.113556.1.4.803:=3))", "Onelevel")
[void]$request.Attributes.Add("ncname")
[void]$request.Attributes.Add("dnsroot")
$response = $LDAPConnection.SendRequest($request)
$colResults = $response.Entries

foreach ($objResult in $colResults)
{
     [VOID]$arrPartitions.add($objResult.attributes.ncname[0])
}

return $arrPartitions

}
#==========================================================================
# Function		: GetSchemaObjectGUID
# Arguments     : Object Guid or Rights Guid
# Returns   	: LDAPDisplayName or DisplayName
# Description   : Searches  in Schema for the name of the object or attribute then return the name guid.
#==========================================================================
Function GetSchemaObjectGUID
{
Param([string] $CN)


    $PageSize=100
    $TimeoutSeconds = 120
    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $LDAPConnection.SessionOptions.ReferralChasing = "None"
    $request = New-Object System.directoryServices.Protocols.SearchRequest("$global:SchemaDN", "(&(cn=$CN))", "Subtree")
    [System.DirectoryServices.Protocols.PageResultRequestControl]$pagedRqc = new-object System.DirectoryServices.Protocols.PageResultRequestControl($pageSize)
    $request.Controls.Add($pagedRqc) | Out-Null
    [void]$request.Attributes.Add("schemaidguid")
    while ($true)
    {
        $response = $LdapConnection.SendRequest($request, (new-object System.Timespan(0,0,$TimeoutSeconds))) -as [System.DirectoryServices.Protocols.SearchResponse];
                
        #for paged search, the response for paged search result control - we will need a cookie from result later
        if($pageSize -gt 0) {
            [System.DirectoryServices.Protocols.PageResultResponseControl] $prrc=$null;
            if ($response.Controls.Length -gt 0)
            {
                foreach ($ctrl in $response.Controls)
                {
                    if ($ctrl -is [System.DirectoryServices.Protocols.PageResultResponseControl])
                    {
                        $prrc = $ctrl;
                        break;
                    }
                }
            }
            if($null -eq $prrc) {
                #server was unable to process paged search
                throw "Find-LdapObject: Server failed to return paged response for request $SearchFilter"
            }
        }
        #now process the returned list of distinguishedNames and fetch required properties using ranged retrieval
        $colResults = $response.Entries
	    foreach ($objResult in $colResults)
	    {             
		    $guidGUID = [System.GUID] $objResult.attributes.schemaidguid[0]
            $strGUID = $guidGUID.toString().toUpper()

				
	    }
        if($pageSize -gt 0) {
            if ($prrc.Cookie.Length -eq 0) {
                #last page --> we're done
                break;
            }
            #pass the search cookie back to server in next paged request
            $pagedRqc.Cookie = $prrc.Cookie;
        } else {
            #exit the processing for non-paged search
            break;
        }
    }

	          
        
	return $strGUID
}
#==========================================================================
# Function		: Get-DomainDN
# Arguments     : string AD object distinguishedName
# Returns   	: Domain DN
# Description   : Take dinstinguishedName as input and returns Domain name 
#                  in DN
#==========================================================================
function Get-DomainDN
{
Param($strADObjectDN)

        $strADObjectDNModified= $strADObjectDN.Replace(",DC=","*")

        [array]$arrDom = $strADObjectDNModified.split("*") 
        $intSplit = ($arrDom).count -1
        $strDomDN = ""
        for ($i=$intSplit;$i -ge 1; $i-- )
        {
            if ($i -eq 1)
            {
                $strDomDN="DC="+$arrDom[$i]+$strDomDN
            }
            else
            {
                $strDomDN=",DC="+$arrDom[$i]+$strDomDN
            }
        }

    return $strDomDN
}
#==========================================================================
# Function: Rem-Perm
# Arguments     : OU Path
# Returns   : N/A
# Description   : Remove Authenticated Users group Read permissions on the ou
#==========================================================================
Function Rem-Perm {
Param([string]$OUdn, 
[string]$strTrustee,
[System.DirectoryServices.ActiveDirectoryRights]$adRights,
[System.DirectoryServices.ActiveDirectorySecurityInheritance]$InheritanceType,
$ObjectTypeGUID,
$InheritedObjectTypeGUID,
$ObjectFlags,
$AccessControlType,
$IsInherited,
$InheritedFlags,
$PropFlags)

    [string] $LDAP_SERVER_SHOW_DELETED_OID = "1.2.840.113556.1.4.417"

    $rootDSE = [adsi]"LDAP://RootDSE"
    $LdapServer = $rootDSE.dnsHostName
    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($LdapServer)
    $request = New-Object System.directoryServices.Protocols.SearchRequest($OUdn, "(name=*)", "Base")
    $SecurityMasks = [System.DirectoryServices.Protocols.SecurityMasks]'Owner' -bor [System.DirectoryServices.Protocols.SecurityMasks]'Group'-bor [System.DirectoryServices.Protocols.SecurityMasks]'Dacl' -bor [System.DirectoryServices.Protocols.SecurityMasks]'Sacl'
    $control = New-Object System.DirectoryServices.Protocols.SecurityDescriptorFlagControl($SecurityMasks)
    [void]$request.Controls.Add($control)
    [void]$request.Controls.Add((New-Object "System.DirectoryServices.Protocols.DirectoryControl" -ArgumentList "$LDAP_SERVER_SHOW_DELETED_OID",$null,$false,$true ))
    [void]$request.Attributes.Add("ntsecuritydescriptor")
    [void]$request.Attributes.Add("name")
    [void]$request.Attributes.Add("distinguishedName")
    $response = $LDAPConnection.SendRequest($request)
    $adObject = $response.Entries


    if(($AccessControlType -eq "Failure") -or ($AccessControlType -eq "Success") -or ($AccessControlType -eq "Success, Failure"))
    {
        $NTsd=[byte[]]$adObject.Attributes.ntsecuritydescriptor[0]
        $sec = New-Object System.DirectoryServices.ActiveDirectorySecurity
        $sec.SetSecurityDescriptorBinaryForm($NTsd)

        If ($strTrustee.contains("S-1-5"))
        {
            $identity = New-Object System.Security.Principal.SecurityIdentifier($strTrustee)
        }   
        else
        {
                $identity = New-Object System.Security.Principal.NTAccount("",$strTrustee)
        }


        ## set the rights and control type
        $newrule1 = New-Object System.DirectoryServices.ActiveDirectoryAuditRule($identity, $adRights, $AccessControlType, [guid]$ObjectTypeGUID, $InheritanceType, [guid]$InheritedObjectTypeGUID)

        $rsl =  $sec.RemoveAuditRuleSpecific($newrule1)  

        [byte[]]$NTsecDescr = $sec.GetSecurityDescriptorBinaryForm()
    
        $rsl = CommitSecurityDescriptor $LdapServer $OUdn $NTsecDescr -bolSacl -Replace
    }
    else
    {
        $NTsd=[byte[]]$adObject.Attributes.ntsecuritydescriptor[0]
        $sec = New-Object System.DirectoryServices.ActiveDirectorySecurity
        $sec.SetSecurityDescriptorBinaryForm($NTsd)

        If ($strTrustee.contains("S-1-5"))
        {
            $identity = New-Object System.Security.Principal.SecurityIdentifier($strTrustee)
        }   
        else
        {
                $identity = New-Object System.Security.Principal.NTAccount("",$strTrustee)
        }


        ## set the rights and control type
        $newrule1 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity, $adRights, $AccessControlType, [guid]$ObjectTypeGUID, $InheritanceType, [guid]$InheritedObjectTypeGUID)

        $rsl =  $sec.RemoveAccessRuleSpecific($newrule1)


        [byte[]]$NTsecDescr = $sec.GetSecurityDescriptorBinaryForm()
    
        $rsl = CommitSecurityDescriptor $LdapServer $OUdn $NTsecDescr -bolDacl -Replace
    }


       


    if ($rsl -ne [System.directoryServices.Protocols.ResultCode]::Success) 
    {
        write-output "Failed!"
        write-output ("ResultCode: " + $modifyResponse.ResultCode)
        write-output ("Message: " + $modifyResponse.ErrorMessage)
    }
    else
    {
        if($identity -match "S-1-")
        {
            $strPrincipalName = ConvertSidTo-Name -server $global:strDomainLongName -Sid $identity
        }
        else
        {
            $strPrincipalName = $identity
        }
            
        Write-Host "Removed:$strPrincipalName on $OUdn " -ForegroundColor Red

    }


}
Function GenerateDiagramMembers
{
Param($DomainGroups)
$_html = ""
$_html += "<table width=`"100%`" style=`"background-color:#ffffff`" cellspacing=`"8`">`n"
 
# limit for display set to 80
$_html_barlimitdisplay = 80
#Write-Debug "Limit for the graphic: $_html_barlimitdisplay members"
    #Go for listing each group
    ForEach ($Group in $DomainGroups)
    {
        $_html += "<tr>`n"
        $_html += "<td align=`"right`" width=`"25%`">$($Group.GroupName)</td>`n"
        $_html += "<td align=`"left`" width=`"75%`">`n"
        #Write-Debug "Writing line for: $($_.Value.ActualName)"
        # Determine the color
        If ( $_.Value.LimitError -lt 0 ) {
            $_html_cellbackground = "#0080c0" #There is no limit -1 in the value
        } ElseIf ( $Group.Members -gt $_.Value.LimitError ) {
            $_html_cellbackground = "#f00000"
        } ElseIf ( $Group.Members -gt $_.Value.LimitWarning ) {
            $_html_cellbackground = "#ffd800"
        } Else {
            $_html_cellbackground = "#0080c0"
        }
        # Plurial management
        If ( $Group.Members -gt 1 ) {
            $_html_cellplurial = "s"
        } Else {
            $_html_cellplurial = ""
        }
        $_html += "<table border=`"0`" cellpadding=`"0`" cellspacing=`"0`">`n"
        $_html += "<tr>`n"
 
        for ($_i = 0; $_i -lt $Group.Members -and $_i -lt $_html_barlimitdisplay ; $_i++) { 
            $_html += "<td style=`"background-color:$_html_cellbackground`"><font color=`"$_html_cellbackground`">##</font></td>`n"
        }
        $_html += "<td style=`"background-color:#ffffff`">&nbsp;$($Group.Members)&nbsp;"
        $_html += "</td>`n"
        $_html += "</tr>`n"
        $_html += "</table>`n"
 
        $_html += "</td>`n"
        $_html += "</tr>`n"
    }

    $_html += "</table>`n"



return $_html
}
#==========================================================================
# Function		: CheckOccurance 
# Arguments     : array of members, distinguishedName of member
# Returns   	: Number of occurance
# Description   : Report the number of occurance in a list
#==========================================================================
Function CheckOccurance($arrMember,$strMemberDNToCheck)
{

$intCountOccurence = 1
    Foreach($strOccurence in $arrMember)
    {
        if($strMemberDNToCheck -eq $strOccurence)
        {
            $intCountOccurence++
        }
    }

return $intCountOccurence
}
#==========================================================================
# Function		: getMemberExpanded 
# Arguments     : n/a
# Returns   	: List of distinguishedName for members
# Description   : List members
#==========================================================================
function getMemberExpanded
{
param ($dn)


$global:bolSuccessReadMember = $true     
$adobject = [adsi]"LDAP://$dn"



# Try to connect to the Domain root
try
{
    $global:colMembers = $adobject.properties.item("member")}
catch
{

    write-output "Error - Could not enumerate $dn";
    $global:bolSuccessReadMember = $false 
             

}

if($global:bolSuccessReadMember -eq $true)
{

             
    Foreach ($objMember in $global:colMembers)
    {
        
        $global:bolMemberobjClass = $true 
        $objMembermod = $objMember.replace("/","\/")

        $objAD=new-object directoryservices.directoryentry("LDAP://$objmembermod")
        Try
        {
            $global:attObjClass = $objAD.properties.item("objectClass")[$($objAD.Properties.Item("objectClass")).count-1]
        }
        catch
        {

            write-output "Error - Could not read objectClass $objMembermod";
            $global:bolMemberobjClass = $false
            continue;

        }

        if($global:bolMemberobjClass -eq $true)
        {
            Switch ($global:attObjClass)
            {
            "group"
            {


                getmemberexpanded $objMember    
                

            }   
            "user"
            {
             

             
                If ($global:colOfMembersExpanded.ContainsKey($objMember))
                {
                    $intOccur = $global:colOfMembersExpanded."$objMember"
                    $global:colOfMembersExpanded.Remove($objMember)
                    [void]$global:colOfMembersExpanded.add($objMember,$intOccur+1)
                }
                else
                {                
                    [void]$global:colOfMembersExpanded.add($objMember,1)
                }

            }
            default
             {
             
    
              
                
                [void]$global:colOfMembersExpanded.add($objMember,1)

            }
            }
        }
    }
}    


} 
#==========================================================================
# Function		: Get-PivGroups 
# Arguments     : n/a
# Returns   	: List of distinguishedName for Privilege groups
# Description   : List Priviliged groups
#==========================================================================
Function Get-PivGroups
{

#$arrPrivGroups = New-Object System.Collections.ArrayList
$dicPrivGroups = @{}
$global:dicProtectedWellKnownGroupSids = @{"S-1-5-32-544"="BUILTIN\Account Operators";`
"S-1-5-32-548"="BUILTIN\Account Operators";`
"S-1-5-32-549"="Server Operators";`
"S-1-5-32-550"="Print Operators";`
"S-1-5-32-551"="Backup Operators";`
"S-1-5-32-569"="BUILTIN\Cryptographic Operators";`
"S-1-5-32-573"="BUILTIN\Event Log Readers "}

#Arrays of wellknow groups for a domain
$DomainWellKnownGroups = (512,517,520,521)

#Arrays of wellknow groups for a forest root
$RorestRootDomainWellKnownGroups = (518,519)


#Connect to domain and get NC
$LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection("")
$LDAPConnection.SessionOptions.ReferralChasing = "None"
$request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
[void]$request.Attributes.Add("defaultnamingcontext")
try
{
    $response = $LDAPConnection.SendRequest($request)
    $global:strDomainDNName = $response.Entries[0].Attributes.defaultnamingcontext[0]
    $global:bolLDAPConnection = $true
}
catch
{
	$global:bolLDAPConnection = $false
    $global:observableCollection.add(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
}

if($global:bolLDAPConnection)
{
    $global:strDomainPrinDNName = $global:strDomainDNName
    $global:strDomainLongName = $global:strDomainDNName.Replace("DC=","")
    $global:strDomainLongName = $global:strDomainLongName.Replace(",",".")
    $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strDomainLongName )
    $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
    $global:strDC = $($ojbDomain.FindDomainController()).name
    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $LDAPConnection.SessionOptions.ReferralChasing = "None"
    $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
    [void]$request.Attributes.Add("defaultnamingcontext")
    [void]$request.Attributes.Add("schemanamingcontext")
    [void]$request.Attributes.Add("configurationnamingcontext")
    [void]$request.Attributes.Add("rootdomainnamingcontext")
  
                    
    try
    {
        $response = $LDAPConnection.SendRequest($request)
        $global:bolLDAPConnection = $true
    }
    catch
    {
    	$global:bolLDAPConnection = $false
        $global:observableCollection.add(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
    }
    if($global:bolLDAPConnection -eq $true)
    {
        $global:ForestRootDomainDN = $response.Entries[0].attributes.rootdomainnamingcontext[0]
        $global:SchemaDN = $response.Entries[0].attributes.schemanamingcontext[0]
        $global:ConfigDN = $response.Entries[0].attributes.configurationnamingcontext[0]
        $global:strDomainDNName = $response.Entries[0].attributes.defaultnamingcontext[0]

    }

    $global:DirContext = Get-DirContext $global:strDC $global:CREDS
    $global:strDomainShortName = GetDomainShortName $global:strDomainDNName $global:ConfigDN
}

# Connect to RootDSE to get current domain names and DC.
$LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
$LDAPConnection.SessionOptions.ReferralChasing = "None"
$request = New-Object System.directoryServices.Protocols.SearchRequest($global:strDomainDNName, "(&(objectClass=*))", "base")
[void]$request.Attributes.Add("objectsid")

$response = $LDAPConnection.SendRequest($request)
$global:DomainSID = GetSidStringFromSidByte $response.Entries[0].attributes.objectsid[0]

if($global:ForestRootDomainDN -ne $global:strDomainDNName)
{
    # Connect to RootDSE to get current domain names and DC.
    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $LDAPConnection.SessionOptions.ReferralChasing = "None"
    $request = New-Object System.directoryServices.Protocols.SearchRequest($global:ForestRootDomainDN, "(&(objectClass=*))", "base")
    [void]$request.Attributes.Add("objectsid")

    $response = $LDAPConnection.SendRequest($request)
    $global:ForestRootDomainSID = GetSidStringFromSidByte $response.Entries[0].attributes.objectsid[0]


    #Since the forest root is different that the current we would like to add the forest root domain specific sids
    Foreach($rid in $DomainWellKnownGroups)
    {
        [void]$RorestRootDomainWellKnownGroups.add($rid)
    }
}
else
{
    #Current Doamin is Forest Root
    $global:ForestRootDomainSID = $global:DomainSID


}



#Get all WellKnownGroups in Domain
Foreach($rid in $DomainWellKnownGroups)
{
    # Connect to RootDSE to get current domain names and DC.
    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $LDAPConnection.SessionOptions.ReferralChasing = "None"
    $request = New-Object System.directoryServices.Protocols.SearchRequest("<SID=$global:DomainSID-$rid>", "(&(objectClass=*))", "base")
    [void]$request.Attributes.Add("samaccountname")
    $response = $LDAPConnection.SendRequest($request) 
    $objPrivGroup = [pscustomobject][ordered]@{                    GroupName=  $response.Entries[0].DistinguishedName}
    #[void]$arrPrivGroups.add($objPrivGroup)
     $dicPrivGroups.Add($response.Entries[0].DistinguishedName,$response.Entries[0].Attributes.samaccountname[0])	
}

#Get all WellKnownGroups in Forest Root
Foreach($rid in $RorestRootDomainWellKnownGroups)
{
    # Connect to RootDSE to get current domain names and DC.
    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $LDAPConnection.SessionOptions.ReferralChasing = "None"
    $request = New-Object System.directoryServices.Protocols.SearchRequest("<SID=$global:ForestRootDomainSID-$rid>", "(&(objectClass=*))", "base")
    [void]$request.Attributes.Add("samaccountname")
    $response = $LDAPConnection.SendRequest($request)
    $objPrivGroup = [pscustomobject][ordered]@{                    GroupName=  $response.Entries[0].DistinguishedName}
    #[void]$arrPrivGroups.add($objPrivGroup)
    $dicPrivGroups.Add($response.Entries[0].DistinguishedName,$response.Entries[0].Attributes.samaccountname[0])	
}
# Protected Groups
Foreach($groupSid in $global:dicProtectedWellKnownGroupSids.Keys)
{
    # Connect to RootDSE to get current domain names and DC.
    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $LDAPConnection.SessionOptions.ReferralChasing = "None"
    $request = New-Object System.directoryServices.Protocols.SearchRequest("<SID=$groupSid>", "(&(objectClass=*))", "base")
    [void]$request.Attributes.Add("samaccountname")
    $response = $LDAPConnection.SendRequest($request)
    $objPrivGroup = [pscustomobject][ordered]@{                    GroupName=  $response.Entries[0].DistinguishedName}
    #[void]$arrPrivGroups.add($objPrivGroup)
    $dicPrivGroups.Add($response.Entries[0].DistinguishedName,$response.Entries[0].Attributes.samaccountname[0])	
}
return $dicPrivGroups
}
#==========================================================================
# Function		: GetSidStringFromSidByte
# Arguments     : SID Value in Byte[]
# Returns   	: SID in String format
# Description   : Convert SID from Byte[] to String
#==========================================================================
Function GetSidStringFromSidByte
{
Param([byte[]] $SidByte)

    $objectSid = [byte[]]$SidByte
    $sid = New-Object System.Security.Principal.SecurityIdentifier($objectSid,0)  
    $sidString = ($sid.value).ToString() 
    return $sidString
}
#==========================================================================
# Function		: getUserAccountAttribs
# Arguments     : 
# Returns   	: n/a
# Description   : Writes the SD to a text file.
#==========================================================================
Function getUserAccountAttribs
{
                param($objADUser,$parentGroup,$strGrpDomainName,$intOccurance)

		$objADUser = $objADUser.replace("/","\/")
                
                $adsientry=new-object directoryservices.directoryentry("LDAP://$objADUser")
                


                $adsisearcher=new-object directoryservices.directorysearcher($adsientry)
                $adsisearcher.pagesize=1000
                $adsisearcher.searchscope="base"
                $colUsers=$adsisearcher.findall()
                foreach($objuser in $colUsers)
                {
                	$dn=$objuser.properties.item("distinguishedname")
	                $sam=$objuser.properties.item("samaccountname")
                    $sn=$objuser.properties.item("sn")
                    $givenName=$objuser.properties.item("givenName")
        	        $attObjClass = $objuser.properties.item("objectClass")
			If ($attObjClass -eq "user")
			{
                $global:UniqueUserCount++
                $description=$objuser.properties.item("description")
                $lastlogontimestamp=$objuser.properties.item("lastlogontimestamp")
                $accountexpiration=$objuser.properties.item("accountexpires")
                $pwdLastSet=$objuser.properties.item("pwdLastSet")
                if ($pwdLastSet -gt 0)
                {
                    $pwdLastSet=[datetime]::fromfiletime([int64]::parse($pwdLastSet))
                    $PasswordAge=((get-date) - $pwdLastSet).days
                }
                Else {$PasswordAge = "<Not Set>"}                                                                        
                $uac=$objuser.properties.item("useraccountcontrol")
                $uac=$uac.item(0)
                if (($uac -bor 0x0002) -eq $uac) {$disabled="TRUE"}
                else {$disabled = "FALSE"}
                if (($uac -bor 0x0032) -eq $uac) {$Pwd_Not_Req="TRUE"}
                else {$Pwd_Not_Req = "FALSE"}
                if (($uac -bor 0x10000) -eq $uac) {$passwordneverexpires="TRUE"}
                else {$passwordNeverExpires = "FALSE"}
                if ($uac -band 1048576) {$accsensitive="TRUE"}
                else {$accsensitive = "FALSE"}

                $usermail=$objuser.properties.item("mail")
                if ($usermail -gt "") {$mail="TRUE"}
                else {$mail = "FALSE"}
            }                                                        

                $adsientry.psbase.RefreshCache("msDS-PrincipalName")
                $strPrinName = $($adsientry.psbase.Properties.Item("msDS-PrincipalName"))
                if(!($sam.length -gt 0))
                {
                    $sam  = $strPrinName.Split("\")[1]

                }
                if($strPrinName.Split("\")[0] -eq "NT AUTHORITY")
                {
                         $strDomDNFromObj = Get-DomainDN $dn

                         $strPrinDom = $(GetDomainShortName $strDomDNFromObj $global:ConfigDN)

                }
                else
                {
                    $strPrinDom = $strPrinName.Split("\")[0]
                }                                      

                $record = "" | select-object "Priviledged Group",GroupDomain,UserDomain,Occurance,SAM,Name,DN,Type,'Password Age',disabled,'Password Never Expires','No Delegation','Password Not Required',MailAddress
                $record."Priviledged Group" = [string]$parentGroup
                $record."GroupDomain" = [string]$strGrpDomainName
                $adsientry.psbase.RefreshCache("msDS-PrincipalName")
                $strPrinName = $($adsientry.psbase.Properties.Item("msDS-PrincipalName"))
                $record.UserDomain = $strPrinDom
                $record.Occurance = $intOccurance
                $record.SAM = [string]$sam
                $record.Name = [string]$sn + [string]$givenName
                $record.DN = [string]$dn
                $record.Type = $objuser.properties.item("objectClass")[$($objuser.Properties.Item("objectClass")).count-1]
                $record.'Password Age' = $PasswordAge
                $record.disabled= $disabled
                $record.'Password Never Expires' = $passwordNeverExpires
                $record.'No Delegation' = $accsensitive
                $record.'Password Not Required' = $Pwd_Not_Req
                $record.MailAddress = $mail
                                
        } 
$record
}
#==========================================================================
# Function		: WriteTargetCSV
# Arguments     : IdentityReference, OU distinguishedName, Ou put text file
# Returns   	: n/a
# Description   : Writes the SD to a text file.
#==========================================================================
function WriteTargetCSV
{
    Param($strIdentityReference,[string]$ou,[string] $fileout)

    [char]34+$ou+[char]34+","+[char]34+`
    $strIdentityReference+[char]34 | Out-File -Append -FilePath $fileout 
    
}
#==========================================================================
# Function		: WritePermCSV
# Arguments     : Security Descriptor, OU distinguishedName, Ou put text file
# Returns   	: n/a
# Description   : Writes the SD to a text file.
#==========================================================================
function WritePermCSV
{
    Param($sd,[string]$ou,[string]$objType,[string] $fileout)
$sd  | foreach {

        $strTranslatedInheritObjType = $($_.InheritedObjectType.toString())
        $strTranslatedObjType = $($_.ObjectType.toString())
        $strMetaData = ","+[char]34+[char]34+","+[char]34+[char]34+","
        $strLegendText = [char]34 +","

        [char]34+$ou+[char]34+","+[char]34+`
        $objType+[char]34+","+[char]34+`
	    $_.IdentityReference.toString()+[char]34+","+[char]34+`
	    $_.ActiveDirectoryRights.toString()+[char]34+","+[char]34+`
	    $_.InheritanceType.toString()+[char]34+","+[char]34+`
	    $strTranslatedObjType+[char]34+","+[char]34+`
	    $strTranslatedInheritObjType+[char]34+","+[char]34+`
	    $_.ObjectFlags.toString()+[char]34+","+[char]34+`
        $(if($null -ne $_.AccessControlType)
        {
        $_.AccessControlType.toString()+[char]34+","+[char]34
        }
        else
        {
        $_.AuditFlags.toString()+[char]34+","+[char]34
        })+`
	    $_.IsInherited.toString()+[char]34+","+[char]34+`
	    $_.InheritanceFlags.toString()+[char]34+","+[char]34+`
        $_.PropagationFlags.toString()+[char]34+`
        $strMetaData+[char]34+`
        $strLegendText |  Out-File -Append -FilePath $fileout 



    } 
}
#==========================================================================
# Function		: ConvertSidTo-Name
# Arguments     : SID string
# Returns   	: Friendly Name of Security Object
# Description   : Try to translate the SID if it fails it try to match a Well-Known.
#==========================================================================
function ConvertSidTo-Name
{
    Param($server,$sid)
$global:strAccNameTranslation = ""     
$ID = New-Object System.Security.Principal.SecurityIdentifier($sid)

&{#Try
	$User = $ID.Translate( [System.Security.Principal.NTAccount])
	$global:strAccNameTranslation = $User.Value
}
Trap [SystemException]
{
	If ($global:dicWellKnownSids.ContainsKey($sid))
	{
		$global:strAccNameTranslation = $global:dicWellKnownSids.Item($sid)
		return $global:strAccNameTranslation
	}
	;Continue
}

if ($global:strAccNameTranslation -eq "")
{

    If ($global:dicSidToName.ContainsKey($sid))
    {
	    $global:strAccNameTranslation =$global:dicSidToName.Item($sid)
    }
    else
    {

        $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC,$global:CREDS)
        $LDAPConnection.SessionOptions.ReferralChasing = "None"
        $request = New-Object System.directoryServices.Protocols.SearchRequest
        [string] $LDAP_SERVER_SHOW_DELETED_OID = "1.2.840.113556.1.4.417"
        [void]$request.Controls.Add((New-Object "System.DirectoryServices.Protocols.DirectoryControl" -ArgumentList "$LDAP_SERVER_SHOW_DELETED_OID",$null,$false,$true ))
        $request.DistinguishedName = "<SID=$sid>"
        $request.Filter = "(name=*)"
        $request.Scope = "Base"
        [void]$request.Attributes.Add("samaccountname")
        [void]$request.Attributes.Add("distinguishedname")
        $response = $LDAPConnection.SendRequest($request)
        $result = $response.Entries[0]
        try
        {
	        $global:strAccNameTranslation =  $result.attributes.samaccountname[0]
        }
        catch
        {
        }

	    if(!($global:strAccNameTranslation))
        {
            $global:strAccNameTranslation =  $result.attributes.distinguishedname[0]
        }
        $global:dicSidToName.Add($sid,$global:strAccNameTranslation)
    }

}

If (($global:strAccNameTranslation -eq $nul) -or ($global:strAccNameTranslation -eq ""))
{
	$global:strAccNameTranslation =$sid
}

return $global:strAccNameTranslation
}
#==========================================================================
# Function		: Get-AceTrustee
# Arguments     : List of OU Path, filter string, output file path
# Returns   	: Number [int] matching trustess
# Description   : Enumerates all access control entries on a speficied object
#==========================================================================
Function Get-AceTrustee
{
    Param([System.Collections.ArrayList]$ALOUdn,[string] $txtFilterTrustee,[string] $strFileCSV)

$acecount = 0
$count = 0

while($count -le $ALOUdn.count -1)
{
    $i = 0
    $ADObjDN = $($ALOUdn[$count])
 
    
    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $LDAPConnection.SessionOptions.ReferralChasing = "None"
    $request = New-Object System.directoryServices.Protocols.SearchRequest("$ADObjDN", "(name=*)", "Base")
    [void]$request.Attributes.Add("objectclass")
    [void]$request.Attributes.Add("ntsecuritydescriptor")
    [void]$request.Attributes.Add("distinguishedname")

    $SecurityMasks = [System.DirectoryServices.Protocols.SecurityMasks]'Owner' -bor [System.DirectoryServices.Protocols.SecurityMasks]'Group'-bor [System.DirectoryServices.Protocols.SecurityMasks]'Dacl' #-bor [System.DirectoryServices.Protocols.SecurityMasks]'Sacl'
    $control = New-Object System.DirectoryServices.Protocols.SecurityDescriptorFlagControl($SecurityMasks)
    [void]$request.Controls.Add($control)

    $response = $LDAPConnection.SendRequest($request)
    $firstNode = $response.Entries[0]

    
    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $LDAPConnection.SessionOptions.ReferralChasing = "None"
    
    $request = New-Object System.directoryServices.Protocols.SearchRequest("$ADObjDN", "(&(objectClass=*)(!msds-nctype=*)(!adminCount=1))", "subtree")

    [void]$request.Attributes.Add("objectclass")
    [void]$request.Attributes.Add("ntsecuritydescriptor")
    [void]$request.Attributes.Add("distinguishedname")
  
    $PageSize=100
    $TimeoutSeconds = 120

    $SecurityMasks = [System.DirectoryServices.Protocols.SecurityMasks]'Owner' -bor [System.DirectoryServices.Protocols.SecurityMasks]'Group'-bor [System.DirectoryServices.Protocols.SecurityMasks]'Dacl' #-bor [System.DirectoryServices.Protocols.SecurityMasks]'Sacl'
    $control = New-Object System.DirectoryServices.Protocols.SecurityDescriptorFlagControl($SecurityMasks)
    [void]$request.Controls.Add($control)

    [string] $LDAP_SERVER_SHOW_DELETED_OID = "1.2.840.113556.1.4.417"
    [void]$request.Controls.Add((New-Object "System.DirectoryServices.Protocols.DirectoryControl" -ArgumentList "$LDAP_SERVER_SHOW_DELETED_OID",$null,$false,$true ))

    [System.DirectoryServices.Protocols.PageResultRequestControl]$pagedRqc = new-object System.DirectoryServices.Protocols.PageResultRequestControl($pageSize)
    $request.Controls.Add($pagedRqc) | Out-Null
    $response = $LDAPConnection.SendRequest($request)
    while ($true)
    {
        $response = $LdapConnection.SendRequest($request, (new-object System.Timespan(0,0,$TimeoutSeconds))) -as [System.DirectoryServices.Protocols.SearchResponse];
                
        #for paged search, the response for paged search result control - we will need a cookie from result later
        if($pageSize -gt 0) {
            [System.DirectoryServices.Protocols.PageResultResponseControl] $prrc=$null;
            if ($response.Controls.Length -gt 0)
            {
                foreach ($ctrl in $response.Controls)
                {
                    if ($ctrl -is [System.DirectoryServices.Protocols.PageResultResponseControl])
                    {
                        $prrc = $ctrl;
                        break;
                    }
                }
            }
            if($prrc -eq $null) {
                #server was unable to process paged search
                throw "Find-LdapObject: Server failed to return paged response for request $SearchFilter"
            }
        }
        #now process the returned list of distinguishedNames and fetch required properties using ranged retrieval
        $colResults = $response.Entries
	    foreach ($DSobject in $colResults)
	    {             
            if($i -eq 0 )
            {

                if($DSobject.DistinguishedName -ne $firstNode.DistinguishedName)
                {
                    $sd =  New-Object System.Collections.ArrayList
                    $global:secd = ""
                    $global:GetSecErr = $false
                    $strObjectClass = $firstNode.Attributes.objectclass[$firstNode.Attributes.objectclass.count-1]
                    $sec = New-Object System.DirectoryServices.ActiveDirectorySecurity
                    $sec.SetSecurityDescriptorBinaryForm($firstNode.Attributes.ntsecuritydescriptor[0])
                    &{#Try
                        $global:secd = $sec.GetAccessRules($true,  $false, [System.Security.Principal.NTAccount])

                    }
                    Trap [SystemException]
                    { 
                
                        &{#Try
                            $global:secd = $sec.GetAccessRules($true,  $false, [System.Security.Principal.SecurityIdentifier])
                        }
                        Trap [SystemException]
                        { 

                            Continue
                            $global:GetSecErr = $true

                        }
                        Continue
                    }
        
                    if(($global:GetSecErr -ne $true) -or ($global:secd -ne ""))
                    {
            
                        $sd.clear()

   
                        if ($txtFilterTrustee.Length -gt 0)
                        {
                            #$global:secd = @($global:secd | select-object -Property IdentityReference -Unique | ?{if($_.IdentityReference -like "S-1-*"){`
                            $global:secd = @($global:secd | ?{if($_.IdentityReference -like "S-1-*"){`
                            $(ConvertSidTo-Name -server $global:strDomainLongName -Sid $_.IdentityReference) -like $txtFilterTrustee}`
                            else{$_.IdentityReference -like $txtFilterTrustee}})

                        }
 
                        $intSDCount =  $sd.count
                
                        if (!($global:secd -eq $null))
                        {
    	                    $index=0

                            if ($intSDCount -gt 0)
                            {        

		                        while($index -le @($global:secd).count -1) 
		                        {
                                    $strNTAccount = $global:secd[$index].IdentityReference.ToString()
                        
	                                If ($strNTAccount.contains("S-1-"))
	                                {
	                                    $strNTAccount = ConvertSidTo-Name -server $global:strDomainLongName -Sid $strNTAccount
	                                }  


				                    WritePermCSV $global:secd[$index] $firstNode.Attributes.distinguishedname[0].toString() $strObjectClass $strFileCSVPerm
                                    WriteTargetCSV $strNTAccount $firstNode.Attributes.distinguishedname[0].toString() $strFileCSV
                                    #Count Number of ACE's
                                    $acecount++

				                    $index++
		                        }# End while

                            }#End if array        

                        }#End if $SD  not null
                    }#End $global:GetSecErr
                }
            }
            $sd =  New-Object System.Collections.ArrayList
            $global:secd = ""

            $global:GetSecErr = $false
            $strObjectClass = $DSobject.Attributes.objectclass[$DSobject.Attributes.objectclass.count-1]
            $sec = New-Object System.DirectoryServices.ActiveDirectorySecurity
            
                    &{#Try
                        $sec.SetSecurityDescriptorBinaryForm($DSobject.Attributes.ntsecuritydescriptor[0])

                    }
                    Trap [SystemException]
                    {
                        #write-host "Failed to read:"$DSobject.DistinguishedName"." $_
                        Continue
                        $global:GetSecErr = $true

                    }
            &{#Try
                $global:secd = $sec.GetAccessRules($true,  $false, [System.Security.Principal.NTAccount])

            }
            Trap [SystemException]
            { 
                
                &{#Try
                    $global:secd = $sec.GetAccessRules($true,  $false, [System.Security.Principal.SecurityIdentifier])
                }
                Trap [SystemException]
                { 

                    Continue
                    $global:GetSecErr = $true

                }
                Continue
            }
        
            if(($global:GetSecErr -ne $true) -or ($global:secd -ne ""))
            {
            

   
                if ($txtFilterTrustee.Length -gt 0)
                {
                    #$global:secd = @($global:secd | select-object -Property IdentityReference -Unique | ?{if($_.IdentityReference -like "S-1-*"){`
                    $global:secd = @($global:secd | ?{if($_.IdentityReference -like "S-1-*"){`
                    $(ConvertSidTo-Name -server $global:strDomainLongName -Sid $_.IdentityReference) -like $txtFilterTrustee}`
                    else{$_.IdentityReference -like $txtFilterTrustee}})

                }
 
                $intSDCount =  $global:secd.count
                
                if (!($global:secd -eq $null))
                {
    	            $index=0

                    if ($intSDCount -gt 0)
                    {        

		                while($index -le $global:secd.count -1) 
		                {
                            $strNTAccount = $global:secd[$index].IdentityReference.ToString()
                        
	                        If ($strNTAccount.contains("S-1-"))
	                        {
	                            $strNTAccount = ConvertSidTo-Name -server $global:strDomainLongName -Sid $strNTAccount
	                        }  


				            #WritePermCSV $sd[$index] $DSobject.Attributes.distinguishedname[0].toString() $strObjectClass $strFileCSV $false $objLastChange $strOrigInvocationID $strOrigUSN
                            WritePermCSV $global:secd[$index] $DSobject.Attributes.distinguishedname[0].toString() $strObjectClass $strFileCSVPerm
                            WriteTargetCSV $strNTAccount $DSobject.Attributes.distinguishedname[0].toString() $strFileCSV
                            #Count Number of ACE's
                            $acecount++

				            $index++
		                }# End while

                    }#End if array        

                }#End if $SD  not null
            }#End $global:GetSecErr
	        $i++
        }
        if($pageSize -gt 0) {
            if ($prrc.Cookie.Length -eq 0) {
                #last page --> we're done
                break;
            }
            #pass the search cookie back to server in next paged request
            $pagedRqc.Cookie = $prrc.Cookie;
        } else {
            #exit the processing for non-paged search
            break;
        }
        
    }#End While
    $count++
}# End while
    




$i = $null
Remove-Variable -Name "i"
$secd = $null
return $acecount


}
#==========================================================================
# Function		: Get-DirContext 
# Arguments     : string domain controller,credentials
# Returns   	: Directory context
# Description   : Get Directory Context
#==========================================================================
function Get-DirContext
{
Param($DomainController,
[System.Management.Automation.PSCredential] $DIRCREDS)

	if($global:CREDS)
		{
		$Context = new-object DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$DomainController,$DIRCREDS.UserName,$DIRCREDS.GetNetworkCredential().Password)
	}
	else
	{
		$Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$DomainController)
	}
	

    return $Context
}
#==========================================================================
# Function		: Add-Perm
# Arguments     : OU Path ,Trustee Name,Right,Allow/Deny,object guid,Inheritance,Inheritance object guid
# Returns   	: N/A
# Description   : Grants a trustee defined permissions on a supplied object
#==========================================================================
Function Add-Perm{
Param([string]$OUdn, 
[string]$strTrustee,
[System.DirectoryServices.ActiveDirectoryRights]$adRights,
[System.DirectoryServices.ActiveDirectorySecurityInheritance]$InheritanceType,
$ObjectTypeGUID,
$InheritedObjectTypeGUID,
$ObjectFlags,
$AccessControlType,
$IsInherited,
$InheritedFlags,
$PropFlags)


    If ($strTrustee.contains("S-1-5"))
    {
        $identity = New-Object System.Security.Principal.SecurityIdentifier($strTrustee)
    }   
    else
    {
        $identity = New-Object System.Security.Principal.NTAccount("",$strTrustee)
    }
    #Check if it is an audit rule or access rule
    if(($AccessControlType -eq "Failure") -or ($AccessControlType -eq "Success") -or ($AccessControlType -eq "Success, Failure"))
    {
        $ACE = New-Object System.DirectoryServices.ActiveDirectoryAuditRule($identity, $adRights, $AccessControlType, [guid]$ObjectTypeGUID, $InheritanceType, [guid]$InheritedObjectTypeGUID)
    }
    else
    {
        $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity, $adRights, $AccessControlType, [guid]$ObjectTypeGUID, $InheritanceType, [guid]$InheritedObjectTypeGUID)
    }

    [string] $LDAP_SERVER_SHOW_DELETED_OID = "1.2.840.113556.1.4.417"

    $rootDSE = [adsi]"LDAP://RootDSE"
    $LdapServer = $rootDSE.dnsHostName
    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($LdapServer)
    $request = New-Object System.directoryServices.Protocols.SearchRequest($OUdn, "(name=*)", "Base")
    $SecurityMasks = [System.DirectoryServices.Protocols.SecurityMasks]'Owner' -bor [System.DirectoryServices.Protocols.SecurityMasks]'Group'-bor [System.DirectoryServices.Protocols.SecurityMasks]'Dacl' -bor [System.DirectoryServices.Protocols.SecurityMasks]'Sacl'
    $control = New-Object System.DirectoryServices.Protocols.SecurityDescriptorFlagControl($SecurityMasks)
    [void]$request.Controls.Add($control)
    [void]$request.Controls.Add((New-Object "System.DirectoryServices.Protocols.DirectoryControl" -ArgumentList "$LDAP_SERVER_SHOW_DELETED_OID",$null,$false,$true ))
    [void]$request.Attributes.Add("ntsecuritydescriptor")
    [void]$request.Attributes.Add("name")
    [void]$request.Attributes.Add("distinguishedName")
    $response = $LDAPConnection.SendRequest($request)
    $adObject = $response.Entries

if($adObject[0].attributes.AttributeNames -contains "ntsecuritydescriptor")
{
  if(($AccessControlType -eq "Failure") -or ($AccessControlType -eq "Success") -or ($AccessControlType -eq "Success, Failure"))
  {
    $NTsd=[byte[]]$adObject.Attributes.ntsecuritydescriptor[0]
    $sec = New-Object System.DirectoryServices.ActiveDirectorySecurity
    $sec.SetSecurityDescriptorBinaryForm($NTsd)

    $rsl = $sec.AddAuditRule($ACE)
    $rsl =$sec.GetAuditRules($true, $false, [System.Security.Principal.NTAccount])
    [byte[]]$NTsecDescr = $sec.GetSecurityDescriptorBinaryForm()

    $rsl = CommitSecurityDescriptor $LdapServer $OUdn $NTsecDescr -bolSacl -Replace   
  }
  else
  {
    $NTsd=[byte[]]$adObject.Attributes.ntsecuritydescriptor[0]
    $sec = New-Object System.DirectoryServices.ActiveDirectorySecurity
    $sec.SetSecurityDescriptorBinaryForm($NTsd)    

    $rsl = $sec.AddAccessRule($ACE)
    $rsl =$sec.GetAccessRules($true, $false, [System.Security.Principal.NTAccount])
    [byte[]]$NTsecDescr = $sec.GetSecurityDescriptorBinaryForm()        

    $rsl = CommitSecurityDescriptor $LdapServer $OUdn $NTsecDescr -bolDacl -Replace   
  }
}
else
{
  if(($AccessControlType -eq "Failure") -or ($AccessControlType -eq "Success") -or ($AccessControlType -eq "Success, Failure"))
  {

    $sec = New-Object System.DirectoryServices.ActiveDirectorySecurity
    $rsl = $sec.AddAuditRule($ACE)
    $rsl =$sec.GetAuditRules($true, $false, [System.Security.Principal.NTAccount])
    [byte[]]$NTsecDescr = $sec.GetSecurityDescriptorBinaryForm()

    $rsl = CommitSecurityDescriptor $LdapServer $OUdn $NTsecDescr -bolSacl -Replace   
  }
  else
  {
    $sec = New-Object System.DirectoryServices.ActiveDirectorySecurity
    $rsl = $sec.AddAccessRule($ACE)
    $rsl =$sec.GetAccessRules($true, $false, [System.Security.Principal.NTAccount])
    [byte[]]$NTsecDescr = $sec.GetSecurityDescriptorBinaryForm()  
    
    $rsl = CommitSecurityDescriptor $LdapServer $OUdn $NTsecDescr -bolDacl -Replace      
  }
}


   






    if ($rsl -ne [System.directoryServices.Protocols.ResultCode]::Success) 
    {
        write-output "Failed!"
        write-output ("ResultCode: " + $modifyResponse.ResultCode)
        write-output ("Message: " + $modifyResponse.ErrorMessage)
    }
    else
    {
        if($strTrustee -match "S-1-")
        {
            $strPrincipalName = ConvertSidTo-Name -server $global:strDomainLongName -Sid $strTrustee
        }
        else
        {
            $strPrincipalName = $strTrustee
        }
        Write-Host "Granted: $strPrincipalName - Rights for $OUdn " -ForegroundColor Green

    }


}
#==========================================================================
# Function		: Check-OwnerShipDeletedObjects
# Arguments     : Object Path, string security principal
# Returns   	: N/A
# Description   : Check if able to read permissions on Deleted Objects Container
#==========================================================================
Function Check-OwnerShipDeletedObjects{
Param([string]$OUdn)
$global:DeletedObjectSDResult = $true
$Identity = "$strTrustee"


  
    [string] $LDAP_SERVER_SHOW_DELETED_OID = "1.2.840.113556.1.4.417"


    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $request = New-Object System.directoryServices.Protocols.SearchRequest($OUdn, "(name=*)", "Base")
    $SecurityMasks = [System.DirectoryServices.Protocols.SecurityMasks]'Owner'
    $control = New-Object System.DirectoryServices.Protocols.SecurityDescriptorFlagControl($SecurityMasks)
    [void]$request.Controls.Add($control)
    [void]$request.Controls.Add((New-Object "System.DirectoryServices.Protocols.DirectoryControl" -ArgumentList "$LDAP_SERVER_SHOW_DELETED_OID",$null,$false,$true ))
    [void]$request.Attributes.Add("ntsecuritydescriptor")
    [void]$request.Attributes.Add("name")
    [void]$request.Attributes.Add("distinguishedName")
    $response = $LDAPConnection.SendRequest($request)
    $adObject = $response.Entries

    
    &{#Try
        $NTsd=[byte[]]$adObject.Attributes.ntsecuritydescriptor[0]
    }
    Trap [SystemException]
    {
    $global:DeletedObjectSDResult = $false
        continue
    }

  
    If($global:DeletedObjectSDResult)
    {
        if($Add)
        {
            Write-Host Deleted Objects Owner already set $OUdn  -ForegroundColor Yellow
        }
    }
    else
    {
        Write-Host Could not read permissions on $OUdn  -ForegroundColor Yellow
    }
    return $global:DeletedObjectSDResult


}
#==========================================================================
# Function		: Take-OwnerShipDeletedObjects
# Arguments     : Object Path
# Returns   	: N/A
# Description   : Set Group as owner on Deleted Objects Container
#==========================================================================
Function Take-OwnerShipDeletedObjects{
Param([string]$OUdn
)


    [string] $LDAP_SERVER_SHOW_DELETED_OID = "1.2.840.113556.1.4.417"


    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $request = New-Object System.directoryServices.Protocols.SearchRequest($OUdn, "(name=*)", "Base")
    $SecurityMasks = [System.DirectoryServices.Protocols.SecurityMasks]'Owner' 
    $control = New-Object System.DirectoryServices.Protocols.SecurityDescriptorFlagControl($SecurityMasks)
    [void]$request.Controls.Add($control)
    [void]$request.Controls.Add((New-Object "System.DirectoryServices.Protocols.DirectoryControl" -ArgumentList "$LDAP_SERVER_SHOW_DELETED_OID",$null,$false,$true ))
    [void]$request.Attributes.Add("ntsecuritydescriptor")
    [void]$request.Attributes.Add("name")
    [void]$request.Attributes.Add("distinguishedName")
    $response = $LDAPConnection.SendRequest($request)
    $adObject = $response.Entries

    $sec = New-Object System.DirectoryServices.ActiveDirectorySecurity
    &{#Try
        $sec.SetOwner()
    }
    Trap [SystemException]
    {
        continue
    }

    $sec.GetAccessRules($true, $false, [System.Security.Principal.NTAccount])
    [byte[]]$NTsecDescr = $sec.GetSecurityDescriptorBinaryForm()

    $rsl = CommitSecurityDescriptor $global:strDC $OUdn $NTsecDescr -bolOwner -Replace
    if ($rsl -ne [System.directoryServices.Protocols.ResultCode]::Success) 
    {
        write-output "Failed!"
        write-output ("ResultCode: " + $modifyResponse.ResultCode)
        write-output ("Message: " + $modifyResponse.ErrorMessage)
    }
    else
    {
        Write-Host "Owner Successfully modified on $OUdn" -ForegroundColor Green
    }




}
#==========================================================================
# Function		: Take-OwnerShip
# Arguments     : OU Path ,Trustee Name,Right,Allow/Deny,object guid,Inheritance,Inheritance object guid
# Returns   	: N/A
# Description   : Grants a trustee defined permissions on a supplied object
#==========================================================================
Function Take-OwnerShip{
Param([string]$OUdn, 
[string]$strTrustee
)

    If ($strTrustee.contains("S-1-5"))
    {
        $identity = New-Object System.Security.Principal.SecurityIdentifier($strTrustee)
    }   
    else
    {
        $identity = "" #= New-Object System.Security.Principal.NTAccount("",$strTrustee)
    }

    [string] $LDAP_SERVER_SHOW_DELETED_OID = "1.2.840.113556.1.4.417"


    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $request = New-Object System.directoryServices.Protocols.SearchRequest($OUdn, "(name=*)", "Base")
    $SecurityMasks = [System.DirectoryServices.Protocols.SecurityMasks]'Owner' 
    $control = New-Object System.DirectoryServices.Protocols.SecurityDescriptorFlagControl($SecurityMasks)
    [void]$request.Controls.Add($control)
    [void]$request.Controls.Add((New-Object "System.DirectoryServices.Protocols.DirectoryControl" -ArgumentList "$LDAP_SERVER_SHOW_DELETED_OID",$null,$false,$true ))
    [void]$request.Attributes.Add("ntsecuritydescriptor")
    [void]$request.Attributes.Add("name")
    [void]$request.Attributes.Add("distinguishedName")
    $response = $LDAPConnection.SendRequest($request)
    $adObject = $response.Entries

    $sec = New-Object System.DirectoryServices.ActiveDirectorySecurity

    $sec.SetOwner($identity)


    $sec.GetAccessRules($true, $false, [System.Security.Principal.NTAccount])
    [byte[]]$NTsecDescr = $sec.GetSecurityDescriptorBinaryForm()

    $rsl = CommitSecurityDescriptor $global:strDC $OUdn $NTsecDescr -bolOwner -Replace
    if ($rsl -ne [System.directoryServices.Protocols.ResultCode]::Success) 
    {
        write-output "Failed!"
        write-output ("ResultCode: " + $modifyResponse.ResultCode)
        write-output ("Message: " + $modifyResponse.ErrorMessage)
    }
    else
    {
        write-output "Owner Successfully modified!"
    }




}

#==========================================================================
# Function		: Check-Owner
# Arguments     : OU Path ,Trustee Name
# Returns   	: N/A
# Description   : Check if the current owner is the same
#==========================================================================
Function Check-Owner{
Param([string]$OUdn, 
[string]$strTrustee)
$SDResult = $false
$Identity = "$strTrustee"


  
    [string] $LDAP_SERVER_SHOW_DELETED_OID = "1.2.840.113556.1.4.417"


    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $request = New-Object System.directoryServices.Protocols.SearchRequest($OUdn, "(name=*)", "Base")
    $SecurityMasks = [System.DirectoryServices.Protocols.SecurityMasks]'Owner'
    $control = New-Object System.DirectoryServices.Protocols.SecurityDescriptorFlagControl($SecurityMasks)
    [void]$request.Controls.Add($control)
    [void]$request.Controls.Add((New-Object "System.DirectoryServices.Protocols.DirectoryControl" -ArgumentList "$LDAP_SERVER_SHOW_DELETED_OID",$null,$false,$true ))
    [void]$request.Attributes.Add("ntsecuritydescriptor")
    [void]$request.Attributes.Add("name")
    [void]$request.Attributes.Add("distinguishedName")
    $response = $LDAPConnection.SendRequest($request)
    $adObject = $response.Entries

    $NTsd=[byte[]]$adObject.Attributes.ntsecuritydescriptor[0]
    $sec = New-Object System.DirectoryServices.ActiveDirectorySecurity
    $sec.SetSecurityDescriptorBinaryForm($NTsd)
    $strOwner = $sec.getOwner([System.Security.Principal.NTAccount])
 


    If ($strOwner -eq $Identity)
    {
        $SDResult = $true
    }
  
    If($SDResult)
    {
        if($Add)
        {
            Write-Host Owner already exist: $strTrustee - Owner for $OUdn  -ForegroundColor Yellow
        }
    }
    else
    {
        Write-Host Owner is missing on $OUdn  -ForegroundColor Yellow
    }
    return $SDResult


}
#==========================================================================
# Function		: Check-Perm
# Arguments     : OU Path ,Trustee Name,Right,Allow/Deny,object guid,Inheritance,Inheritance object guid
# Returns   	: N/A
# Description   : Grants a trustee defined permissions on a supplied object
#==========================================================================
Function Check-Perm{
Param([string]$OUdn, 
[string]$strTrustee,
[string]$adRights,
[string]$InheritanceType,
[string]$ObjectTypeGUID,
[string]$InheritedObjectTypeGUID,
[string]$ObjectFlags,
[string]$AccessControlType,
[string]$IsInherited,
[string]$InheritedFlags,
[string]$PropFlags)
$Script:SDResult = $false
$Script:ErrCheck = $false
$Identity = "$strTrustee"

&{#Try
  
    [string] $LDAP_SERVER_SHOW_DELETED_OID = "1.2.840.113556.1.4.417"

    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $request = New-Object System.directoryServices.Protocols.SearchRequest($OUdn, "(name=*)", "Base")
    $SecurityMasks = [System.DirectoryServices.Protocols.SecurityMasks]'Owner' -bor [System.DirectoryServices.Protocols.SecurityMasks]'Group'-bor [System.DirectoryServices.Protocols.SecurityMasks]'Dacl' -bor [System.DirectoryServices.Protocols.SecurityMasks]'Sacl'
    $control = New-Object System.DirectoryServices.Protocols.SecurityDescriptorFlagControl($SecurityMasks)
    [void]$request.Controls.Add($control)
    [void]$request.Controls.Add((New-Object "System.DirectoryServices.Protocols.DirectoryControl" -ArgumentList "$LDAP_SERVER_SHOW_DELETED_OID",$null,$false,$true ))
    [void]$request.Attributes.Add("ntsecuritydescriptor")
    [void]$request.Attributes.Add("name")
    [void]$request.Attributes.Add("distinguishedName")
    $response = $LDAPConnection.SendRequest($request)
    $adObject = $response.Entries

    $NTsd=[byte[]]$adObject.Attributes.ntsecuritydescriptor[0]
    $sec = New-Object System.DirectoryServices.ActiveDirectorySecurity
    $sec.SetSecurityDescriptorBinaryForm($NTsd)
    $sd = $sec.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier])


  $rar = $sd |? {($_.IdentityReference -eq $Identity) -and ($_.ActiveDirectoryRights -eq $adRights) -and ($_.AccessControlType -eq $AccessControlType) -and ($_.ObjectType -eq $ObjectTypeGUID) -and ($_.InheritanceType -eq $InheritanceType) -and ($_.InheritedObjectType -eq $InheritedObjectTypeGUID)}
  if ($rar -is [array])
  {
	foreach($sdObject in $rar)
	{

		If ($sdObject.IdentityReference.value -eq $Identity)
		{
			$Script:SDResult = $true
		}
	}
  }
  else
  {
    If ($rar.IdentityReference.value -eq $Identity)
    {
    	$Script:SDResult = $true
    }
  }
}

Trap [SystemException]
{
        
    $strErrMsg = $($_.Exception.InnerException.Message)
    $Script:ErrCheck = $true
    $Script:SDResult = $true
    $_
    If ($($strErrMsg.ToString()) -ne "The object does not exist.")
    {
        $strErrMsg
    }

    continue
}
If($Script:SDResult)
{
    if($Script:ErrCheck)
    {
        Write-host  "Path does not exist: $OUdn"

        $global:bolFailedlOperation = $true

        $newMessageObject = New-Object psObject | `
        Add-Member NoteProperty TaskID "$global:strTaskID" -PassThru |`
        Add-Member NoteProperty Task "$global:strTaskName" -PassThru |`
        Add-Member NoteProperty Group "$global:strGrpName" -PassThru |`
        Add-Member NoteProperty Target "$OUdn" -PassThru |`
        Add-Member NoteProperty Message "Path not exist $OUdn" -PassThru

        [void]$global:arrFailedDelegationList.Add($newMessageObject)

    }
    else
    {
        if($Add)
        {
        if($strTrustee -match "S-1-")
        {
            $strPrincipalName = ConvertSidTo-Name -server $global:strDomainLongName -Sid $strTrustee
        }
        else
        {
            $strPrincipalName = $strTrustee
        }
        Write-Host Permission already granted: $strPrincipalName - Rights for $OUdn  -ForegroundColor Yellow
        }
    }
}
else
{

    Write-Host Permission is missing on $OUdn  -ForegroundColor Yellow
}
   return $Script:SDResult


}
#==========================================================================
# Function		: CommitSecurityDescriptor 
# Arguments     : string fqdn , string distinguishedname, byte[]ntSecurityDescriptor
# Returns   	: Boolean
# Description   : Check If distinguishedName exist
#==========================================================================
Function CommitSecurityDescriptor()
{
param(
$LdapServer,
$Dn,
$NTsecDescr,
[switch]$Add=$false,
[switch]$Replace=$false,
[switch]$Delete=$false,
[switch]$bolOwner=$false,
[switch]$bolGroup=$false,
[switch]$bolDacl=$false,
[switch]$bolSacl=$false
)



$SecurityMasks = ""
$LdapAttrDn = New-Object -TypeName System.DirectoryServices.Protocols.DirectoryAttributeModification
$LdapAttrDn.Name ="ntsecuritydescriptor"
[void]$LdapAttrDn. Add($NTsecDescr) 

if((!$Add) -and (!$bolOwner) -and (!$Replace) -and (!$Delete)){$attrOperation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Add }
if($Delete){$attrOperation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Delete}
if($Replace){$attrOperation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace}
if($Add){$attrOperation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Add}

# Set type of operation
$LdapAttrDn.Operation = $attrOperation

 
# Create modify request
$LdapModifyRequest = New-Object -TypeName System.DirectoryServices.Protocols.ModifyRequest($Dn,$LdapAttrDn)
$SD = New-Object System.DirectoryServices.Protocols.SecurityDescriptorFlagControl
# Build security mask to modify
if((!$bolDacl) -and (!$bolOwner) -and (!$bolSacl) -and (!$bolGroup))
{
    $SecurityMasks =  [System.DirectoryServices.Protocols.SecurityMasks]::('Dacl') 
}
if($bolDacl)
{
   if(!$SecurityMasks)
   {
    $SecurityMasks =  [System.DirectoryServices.Protocols.SecurityMasks]::('Dacl')
   }
   else
   {
   $SecurityMasks =  $SecurityMasks -bor [System.DirectoryServices.Protocols.SecurityMasks]::('Dacl')
   }
}
if($bolOwner)
{
   if(!$SecurityMasks)
   {
    $SecurityMasks =  [System.DirectoryServices.Protocols.SecurityMasks]::('Owner')
   }
   else
   {
   $SecurityMasks =  $SecurityMasks -bor [System.DirectoryServices.Protocols.SecurityMasks]::('Owner')
   }
}
if($bolSacl)
{
   if(!$SecurityMasks)
   {
    $SecurityMasks =  [System.DirectoryServices.Protocols.SecurityMasks]::('Sacl')
   }
   else
   {
   $SecurityMasks =  $SecurityMasks -bor [System.DirectoryServices.Protocols.SecurityMasks]::('Sacl')
   }
}
if($bolGroup)
{
   if(!$SecurityMasks)
   {
    $SecurityMasks =  [System.DirectoryServices.Protocols.SecurityMasks]::('Group')
   }
   else
   {
   $SecurityMasks =  $SecurityMasks -bor [System.DirectoryServices.Protocols.SecurityMasks]::('Group')
   }
}
$SD.SecurityMasks = $SecurityMasks
$SD.IsCritical = $false
[void]$LdapModifyRequest.Controls.Add($SD)

[void]$LdapModifyRequest.Controls.Add((New-Object "System.DirectoryServices.Protocols.DirectoryControl" -ArgumentList "$LDAP_SERVER_SHOW_DELETED_OID",$null,$false,$true ))
# Establish connection to Active Directory
$LdapConnection = new-object System.DirectoryServices.Protocols.LdapConnection(new-object System.DirectoryServices.Protocols.LdapDirectoryIdentifier($LdapServer))
 
# Send modify request
[System.DirectoryServices.Protocols.DirectoryResponse]$modifyResponse = $ldapConnection.SendRequest($ldapModifyRequest)



Return $modifyResponse.ResultCode

}
#==========================================================================
# Function		: GetDomainShortName
# Arguments     : domain name 
# Returns   	: N/A
# Description   : Search for short domain name
#==========================================================================
function GetDomainShortName
{ 
Param($strDomain,
[string]$strConfigDN)

    $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
    $LDAPConnection.SessionOptions.ReferralChasing = "None"
    $request = New-Object System.directoryServices.Protocols.SearchRequest("CN=Partitions,$strConfigDN", "(&(objectClass=crossRef)(nCName=$strDomain))", "Subtree")
    [void]$request.Attributes.Add("netbiosname")
    $response = $LDAPConnection.SendRequest($request)
    $adObject = $response.Entries[0]

    if($null -ne $adObject)
    {

        $ReturnShortName = $adObject.Attributes.netbiosname[0]
	}
	else
	{
		$ReturnShortName = ""
	}
 
return $ReturnShortName
}
#==========================================================================
# Function		: Get-Forest 
# Arguments     : string domain controller,credentials
# Returns   	: Forest
# Description   : Get AD Forest
#==========================================================================
function Get-Forest
{
Param($DomainController,[Management.Automation.PSCredential]$Credential)
	if(!$DomainController)
	{
		[DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
		return
	  }
	if($Creds)
		{
		$Context = new-object DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$DomainController,$Creds.UserName,$Creds.GetNetworkCredential().Password)
	}
	else
	{
		$Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$DomainController)
	}
	$ojbForest =[DirectoryServices.ActiveDirectory.Forest]::GetForest($Context)

    return $ojbForest
}
#==========================================================================
# Function		: Get-DomainDNfromFQDN
# Arguments     : Domain FQDN
# Returns   	: Domain DN
# Description   : Take domain FQDN as input and returns Domain name 
#                  in DN
#==========================================================================
function Get-DomainDNfromFQDN
{
Param($strDomainFQDN)

        $strADObjectDNModified= $strDomainFQDN.tostring().Replace(".",",DC=")

        $strDomDN="DC="+$strADObjectDNModified


    return $strDomDN
}
#==========================================================================
# Function		: CheckDNExist 
# Arguments     : string distinguishedName
# Returns   	: Boolean
# Description   : Check If distinguishedName exist
#==========================================================================
function CheckDNExist
{
Param (
  $sADobjectName
  )

  $sADobjectName = "LDAP://" + $sADobjectName
    $ADobject =  [ADSI] $sADobjectName
    If($ADobject.distinguishedName -eq $null)
    {return $false}
    else
    {return $true}

}

#==========================================================================
# Function		: CreateOU 
# Arguments     : string distinguishedName
# Returns   	: Boolean
# Description   : Create an OU
#==========================================================================
function CreateOU
{
Param ([string]$strCN,
  [string]$strDN
  )

  if($strCN -eq "")
  {
    $strCN = $strDN.split(",")[0]
    $strDN = $strDN.Replace($strCN+",","")
    $strCN = $strCN.split("=")[1]
  }
$script:boolFail = $false
    &{#Try
        New-ADOrganizationalUnit -Name:"$strCN" -Path:"$strDN" -ProtectedFromAccidentalDeletion:$true 
        Set-ADObject -Identity:"OU=$strCN,$strDN" -ProtectedFromAccidentalDeletion:$true 
    }
    TRAP
    {
        $_
        $script:boolFail = $true
    }
    if($script:boolFail -eq $false)
    {
     Write-Host "Created OU=$strCN,$strDN" -ForegroundColor Green
    }

}
#==========================================================================
# Function		: GetGroupDN
# Arguments     : samaccountName 
# Returns   	: N/A
# Description   : Search for a group and returns distinguishedName
#==========================================================================
function GetGroupDN { 
Param($groupName)
    $root = [adsi]"LDAP://RootDSE"
	$ads = New-Object System.DirectoryServices.DirectorySearcher($root.defaultNamingContext)
	$ads.filter = "(&(objectClass=group)(samAccountName=$groupName))"
	$s = $ads.FindOne()
	If ($s)
	{
		return $($s.GetDirectoryEntry().DistinguishedName).toString()
	}
	else
	{
		return ""
	}

}
#==========================================================================
# Function		: TestCSVColumns
# Arguments     : CSV import 
# Returns   	: Boolean
# Description   : Search for all requried column names in CSV and return true or false
#==========================================================================
function TestCSVColumns{param($CSVImport)$bolColumExist = $false$colHeaders = ( $CSVImport | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name')
$bolTaskID = $false
$bolTask = $false
$bolGroupName = $false
$bolType = $false
$bolTargetPath = $false
$bolShortNameTarget = $false

Foreach ($ColumnName in $colHeaders )
{

    if($ColumnName.Trim() -eq "TaskID")
    {
        $bolTaskID = $true
    }
    if($ColumnName.Trim() -eq "Task")
    {
        $bolTask = $true
    }
    if($ColumnName.Trim() -eq "GroupName")
    {
        $bolGroupName = $true
    }
#    if($ColumnName.Trim() -eq "Type")
#    {
#        $bolType = $true
#    }
    if($ColumnName.Trim() -eq "Target")
    {
        $bolTargetPath = $true
    }
    if($ColumnName.Trim() -eq "ShortName")
    {
        $bolShortNameTarget = $true
    }
 

}
#if test column names exist
#if($bolTaskID -and $bolTask -and $bolGroupName -and $bolType -and $bolTargetPath -and $bolShortNameTarget)
if($bolTaskID -and $bolTask -and $bolGroupName -and $bolTargetPath -and $bolShortNameTarget)
{    $bolColumExist = $true}return $bolColumExist}
#==========================================================================
# Function		: DisplayTaskIDXMLFileInfo
# Arguments     : file path string 
# Returns   	: 
# Description   : Display File name and version number of TaskID XML file.
#==========================================================================
function DisplayTaskIDXMLFileInfo{param($strFilePathXML)Write-host "======================= Task ID XML File ================================" -ForegroundColor Yellow$XMLTaskIdData = New-Object XML
$XMLTaskIdData = [xml]$(Get-Content $strFilePathXML)
Write-host "TaskID Version:  $($XMLTaskIdData.Tasks.Version)" -ForegroundColor YellowWrite-host "Number of Tasks: $(($XMLTaskIdData.Tasks).ChildNodes.Count)" -ForegroundColor YellowWrite-host "Path: $strFilePathXML" -ForegroundColor YellowWrite-host "=========================================================================" -ForegroundColor Yellow}
############ Functions Collection End ####################

<#
.Synopsis
   Create OUs for storing roles and tasks. 
.DESCRIPTION
   This function will create the necessary OU structure to separate service management roles from data management roles.

.PARAMETER Tier0OU
 The name of the OU where you would like to store the Tier 0 delegation objects. An Account OU,Roles OU and a Task OU will be created as child objectgs.
 Default = "Tier 0"

.PARAMETER Tier1OU
 The name of the OU where you would like to store the Tier 1 delegation objects. An Account OU and Roles OU will be created as child objectgs.
 Default = "Tier 1"

 .PARAMETER Tier2OU
 The name of the OU where you would like to store the Tier 2 delegation objects. An Account OU and Roles OU will be created as child objectgs.
 Default = "Tier 2"

.PARAMETER DelegationRootDN
 The distinguishedName of the OU where you would like to store the Tier 0 and Tier 1 OU's.
 Default = "OU=Admin,<domain root>"

.EXAMPLE
 Add-DelegationOUs
 Create OU structure for roles. An Admin OU at the root with the sub-OU's Tier 0 and Tier 1.
 OU's created:
    OU=Admin,DC=contoso,DC=com
    OU=Tier 0,OU=Admin,DC=contoso,DC=com
    OU=Accounts,OU=Tier 0,OU=Admin,DC=contoso,DC=com
    OU=Roles,OU=Tier 0,OU=Admin,DC=contoso,DC=com
    OU=Tasks,OU=Tier 0,OU=Admin,DC=contoso,DC=com
    OU=Tier 1,OU=Admin,DC=contoso,DC=com
    OU=Accounts,OU=Tier 1,OU=Admin,DC=contoso,DC=com
    OU=Roles,OU=Tier 1,OU=Admin,DC=contoso,DC=com

.EXAMPLE
 Add-DelegationOUs -DelegationRootDN "OU=CORP,DC=contoso,DC=com"
 Create OU structure for roles. Instead of creating OU=Admin,DC=contoso,DC=com, this OU=CORP,DC=contoso,DC=com will be created if it does not exist. 
 OU's created:
    OU=CORP,DC=contoso,DC=com
    OU=Tier 0,OU=CORP,DC=contoso,DC=com
    OU=Accounts,OU=Tier 0,OU=CORP,DC=contoso,DC=com
    OU=Roles,OU=Tier 0,OU=CORP,DC=contoso,DC=com
    OU=Tasks,OU=Tier 0,OU=CORP,DC=contoso,DC=com
    OU=Tier 1,OU=CORP,DC=contoso,DC=com
    OU=Accounts,OU=Tier 1,OU=CORP,DC=contoso,DC=com
    OU=Roles,OU=Tier 1,OU=CORP,DC=contoso,DC=com
.EXAMPLE
 Add-DelegationOUs -Tier0OU "ServiceMGMT"
 Create OU structure for roles. Instead of creating OU=Tier 0,OU=Admin,DC=contoso,DC=com, this OU=ServiceMMGT,OU=Admin,DC=contoso,DC=com will be created if it does not exist. 
 OU's created:
    OU=Admin,DC=contoso,DC=com
    OU=SvcMGMT,OU=Admin,DC=contoso,DC=com
    OU=Accounts,OU=SvcMGMT,OU=Admin,DC=contoso,DC=com
    OU=Roles,OU=SvcMGMT0,OU=Admin,DC=contoso,DC=com
    OU=Tasks,OU=SvcMGMT,OU=Admin,DC=contoso,DC=com
    OU=Tier 1,OU=Admin,DC=contoso,DC=com
    OU=Accounts,OU=Tier 1,OU=Admin,DC=contoso,DC=com
    OU=Roles,OU=Tier 1,OU=Admin,DC=contoso,DC=com
.EXAMPLE
 Add-DelegationOUs -Tier0OU "ServiceMGMT" -Tier0OU "DataMGMT" -DelegationRootDN "OU=Delegation,DC=contoso,DC=com"
 Create OU structure for roles. Instead of creating OU=Tier 1,OU=Admin,DC=contoso,DC=com, this OU=DataMGMT,OU=Delegation,DC=contoso,DC=com will be created if it does not exist. 
 OU's created:
    OU=Delegation,DC=contoso,DC=com
    OU=SvcMGMT,OU=Delegation,DC=contoso,DC=com
    OU=Accounts,OU=SvcMGMT,OU=Delegation,DC=contoso,DC=com
    OU=Roles,OU=SvcMGMT0,OU=Delegation,DC=contoso,DC=com
    OU=Tasks,OU=SvcMGMT,OU=Delegation,DC=contoso,DC=com
    OU=DataMGMT,OU=Delegation,DC=contoso,DC=com
    OU=Accounts,OU=DataMGMT,OU=Delegation,DC=contoso,DC=com
    OU=Roles,OU=DataMGMT,OU=Delegation,DC=contoso,DC=com
.INPUTS
.OUTPUTS
.COMPONENT
.ROLE
#>
function Add-DelegationOUs
{


    [CmdletBinding(DefaultParameterSetName='Filters', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Param1 Service Managment Delegation OU Name
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Tier0OU = "Tier 0",
        # Param1 Data Managment Delegation OU Name
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Tier1OU = "Tier 1",
        # Param1 Data Managment Delegation OU Name
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Tier2OU = "Tier 2",
        # Param1 BU OU Name
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=1,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $DelelgationRootDN
    )

    Begin
    {
        [void][Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.Protocols")
        if ($(Get-Module -name ActiveDirectory -ListAvailable) -eq $null)
        {
            Write-Output  "Powershell module for ActiveDirectory not installed! This functions requires the ActiveDirectory Powershell module to be available" 
        }
        else
        {
            if ($(Get-Module -name ActiveDirectory) -eq $null)
            {
                #Load ActiveDirectory Module
                Import-Module -Name ActiveDirectory
                #Write-Output "ActiveDirectory Powershell module imported" 
            }



        }

        #Connect to domain 
        $LDAPConnection = $null
        $request = $null
        $response = $null
        $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection("")
        $LDAPConnection.SessionOptions.ReferralChasing = "None"
        $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
        [void]$request.Attributes.Add("defaultnamingcontext")
        try
	    {
            $response = $LDAPConnection.SendRequest($request)
            $global:strDomainDNName = $response.Entries[0].Attributes.defaultnamingcontext[0]
            $global:bolLDAPConnection = $true
	    }
	    catch
	    {
		    $global:bolLDAPConnection = $false
            $global:observableCollection.add(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
	    }

        if($global:bolLDAPConnection)
        {
            $global:strDomainPrinDNName = $global:strDomainDNName
            $global:strDomainLongName = $global:strDomainDNName.Replace("DC=","")
            $global:strDomainLongName = $global:strDomainLongName.Replace(",",".")
            $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strDomainLongName )
            $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
            $global:strDC = $($ojbDomain.FindDomainController()).name
            $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
            $LDAPConnection.SessionOptions.ReferralChasing = "None"
            $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
            [void]$request.Attributes.Add("dnshostname")
            [void]$request.Attributes.Add("namingcontexts")
            [void]$request.Attributes.Add("defaultnamingcontext")
            [void]$request.Attributes.Add("schemanamingcontext")
            [void]$request.Attributes.Add("configurationnamingcontext")
            [void]$request.Attributes.Add("rootdomainnamingcontext")
                    
            try
    	    {
                $response = $LDAPConnection.SendRequest($request)
                $global:bolLDAPConnection = $true
    	    }
    	    catch
    	    {
    		    $global:bolLDAPConnection = $false
                Write-host "Failed! Domain does not exist or can not be connected" -
    	    }
            if($global:bolLDAPConnection -eq $true)
            {
                $global:ForestRootDomainDN = $response.Entries[0].attributes.rootdomainnamingcontext[0]
                $global:SchemaDN = $response.Entries[0].attributes.schemanamingcontext[0]
                $global:ConfigDN = $response.Entries[0].attributes.configurationnamingcontext[0]
                $global:strDomainDNName = $response.Entries[0].attributes.defaultnamingcontext[0]
            }

            $global:DirContext = Get-DirContext $global:strDC $global:CREDS
            $global:strDomainShortName = GetDomainShortName $global:strDomainDNName $global:ConfigDN
            $global:strRootDomainShortName = GetDomainShortName $global:ForestRootDomainDN $global:ConfigDN
        }
    
        $strBU = ""

 

    }
    Process
    {

        if ($pscmdlet.ShouldProcess($global:strDomainDNName, "Create OU Structure for delegation:"))
        {
            $bolBUError = $false            if($DelelgationRootDN)
            {
                $strBU = $DelelgationRootDN
                Write-Host "Verify Delegation OU: $strBU"
                If (CheckDNExist ($strBU))
                {    

                }
                else
                {
	                Write-Host "Delegation OU does not exist: $strBU" -ForegroundColor Yellow
                    
                    CreateOU "" $strBU
                    If ($script:boolFail)
                    {    
                        $bolBUError = $true
                    }
                }  
            }
            else
            {
                $strBU = "OU=Admin,$global:strDomainDNName"
                Write-Host "Verify Delegation OU: $strBU"
                If (CheckDNExist ($strBU))
                {    

                }
                else
                {
	                Write-Host "Delegation OU does not exist: $strBU" -ForegroundColor Yellow
                    CreateOU "Admin" $global:strDomainDNName
                    If ($script:boolFail)
                    {    
                        $bolBUError = $true
                    }
                }  
            }
            if($bolBUError -eq $false)
            {
                #Adding auditing on to OU: Everyone Create/Delete,Modify Dacl, Write Owner, Write Property
                Write-host "Adding auditing on to OU: Everyone Create/Delete,Modify Dacl, Write Owner, Write Property"
                Add-Perm $strBU "Everyone" "CreateChild, DeleteChild, Self, WriteProperty, DeleteTree, ExtendedRight, Delete, WriteDacl, WriteOwner" "All" "00000000-0000-0000-0000-000000000000" "00000000-0000-0000-0000-000000000000" "None" "Success" "False" "ContainerInherit" "None"
                #
                if($strBU -ne "")
                {
                    $strDelegationRootDN = $strBU
                }
                else
                {
                    $strDelegationRootDN = $global:strDomainDNName
                }
                $strOUName = $Tier0OU
                $Tier0OUPrefix = "T0-"
                $strPath = $strDelegationRootDN
                If (CheckDNExist ("OU=$strOUName,$strPath"))
                {    
	                Write-Host "OU already exist: OU=$strOUName,$strPath" -ForegroundColor Yellow
                }
                else
                {
                    CreateOU $strOUName $strPath
                }
                $strOUName = $Tier0OUPrefix+"Roles"
                $strPath = "OU="+$Tier0OU+","+$strDelegationRootDN
                If (CheckDNExist ("OU=$strOUName,$strPath"))
                {    
	                Write-Host "OU already exist: OU=$strOUName,$strPath" -ForegroundColor Yellow
                }
                else
                {
                    CreateOU $strOUName $strPath
                }
                $strOUName = $Tier0OUPrefix+"Tasks"
                $strPath = "OU="+$Tier0OU+","+$strDelegationRootDN
                If (CheckDNExist ("OU=$strOUName,$strPath"))
                {    
	                Write-Host "OU already exist: OU=$strOUName,$strPath" -ForegroundColor Yellow
                }
                else
                {
                    CreateOU $strOUName $strPath
                }
                $strOUName = $Tier0OUPrefix+"Accounts"
                $strPath = "OU="+$Tier0OU+","+$strDelegationRootDN
                If (CheckDNExist ("OU=$strOUName,$strPath"))
                {    
	                Write-Host "OU already exist: OU=$strOUName,$strPath" -ForegroundColor Yellow
                }
                else
                {
                    CreateOU $strOUName $strPath
                }


                $strOUName = $Tier1OU
                $Tier1OUPrefix = "T1-"
                $strPath = $strDelegationRootDN
                If (CheckDNExist ("OU=$strOUName,$strPath"))
                {    
	                Write-Host "OU already exist: OU=$strOUName,$strPath" -ForegroundColor Yellow
                }
                else
                {
                    CreateOU $strOUName $strPath
                }
                $strOUName = $Tier1OUPrefix+"Roles"
                $strPath = "OU="+$Tier1OU+","+$strDelegationRootDN
                If (CheckDNExist ("OU=$strOUName,$strPath"))
                {    
	                Write-Host "OU already exist: OU=$strOUName,$strPath" -ForegroundColor Yellow
                }
                else
                {
                    CreateOU $strOUName $strPath
                }
                $strOUName = $Tier1OUPrefix+"Accounts"
                $strPath = "OU="+$Tier1OU+","+$strDelegationRootDN
                If (CheckDNExist ("OU=$strOUName,$strPath"))
                {    
	                Write-Host "OU already exist: OU=$strOUName,$strPath" -ForegroundColor Yellow
                }
                else
                {
                    CreateOU $strOUName $strPath
                }

                $strOUName = $Tier2OU
                $Tier2OUPrefix = "T2-"
                $strPath = $strDelegationRootDN
                If (CheckDNExist ("OU=$strOUName,$strPath"))
                {    
	                Write-Host "OU already exist: OU=$strOUName,$strPath" -ForegroundColor Yellow
                }
                else
                {
                    CreateOU $strOUName $strPath
                }
                $strOUName = $Tier2OUPrefix+"Roles"
                $strPath = "OU="+$Tier2OU+","+$strDelegationRootDN
                If (CheckDNExist ("OU=$strOUName,$strPath"))
                {    
	                Write-Host "OU already exist: OU=$strOUName,$strPath" -ForegroundColor Yellow
                }
                else
                {
                    CreateOU $strOUName $strPath
                }
                $strOUName = $Tier2OUPrefix+"Accounts"
                $strPath = "OU="+$Tier2OU+","+$strDelegationRootDN
                If (CheckDNExist ("OU=$strOUName,$strPath"))
                {    
	                Write-Host "OU already exist: OU=$strOUName,$strPath" -ForegroundColor Yellow
                }
                else
                {
                    CreateOU $strOUName $strPath
                }
            }

        } #End if ShouldProcess
       
    }#End Process
    End 
    {

    } #End of End
}

<#
.Synopsis
   Create all role and task groups. Memberships will be set too.
.DESCRIPTION
 This function will create the necessary OU structure to separate service management roles from data management roles.
.PARAMETER Template
 The path and file name of the CSV file used as a template for the delegation model. 
.PARAMETER DelelgationRootDN
 The distinguishedName of the OU where you would like to store the delegation objects.
.PARAMETER Roleprefix
 The prefix of the role groups names. Default "Role".
.PARAMETER Tier0OU
 If the Tier 0 objects is not located in an OU called Tier 0 you have defined the new name of that OU.
 Default "Tier 0"    
.PARAMETER Tier1OU
 If the Tier 1 objects is not located in an OU called Tier 0 you have defined the new name of that OU.
 Default "Tier 1"
.EXAMPLE
 Add-RolesAndTasks  -Template C:\temp\POPADD_Role_Task_Matrix.csv 
 This command will create all roles and task groups when the DataMgmtDelegation OU is under the domain root.
.EXAMPLE
 Add-RolesAndTasks  -Template C:\temp\POPADD_Role_Task_Matrix.csv -Roleprefix MYROLES
 This command will create all roles and task groups when the DataMgmtDelegation OU is under the domain root.
 The roles in the template all have the group name prefix MYROLES.
.EXAMPLE
 Add-RolesAndTasks  -Template C:\temp\POPADD_Role_Task_Matrix.csv  -DelelgationRootDN "OU=CORP,DC=contoso,DC=com"
 This command will create all roles and task groups when the delegation objects are under an OU named CORP.
.INPUTS
.OUTPUTS
.COMPONENT
.ROLE
#>
function Add-RolesAndTasks
{


    [CmdletBinding(DefaultParameterSetName='Filters', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Param1 Template path
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$false, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Template,
        # Param2 BU OU Name
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=1,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $DelelgationRootDN,
        # Param3 Role Prefix
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=2,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Roleprefix = "Role",
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=3,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Tier0OU = "Tier 0",
        # Param1 Data Managment Delegation OU Name
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=4,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Tier1OU = "Tier 1",
        # Param1 Data Managment Delegation OU Name
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=5,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Tier2OU = "Tier 2"
    )

    Begin
    {
        [void][Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.Protocols")
        if ($(Get-Module -name ActiveDirectory -ListAvailable) -eq $null)
        {
            Write-Output  "Powershell module for ActiveDirectory not installed! This functions requires the ActiveDirectory Powershell module to be available" 
        }
        else
        {
            if ($(Get-Module -name ActiveDirectory) -eq $null)
            {
                #Load ActiveDirectory Module
                Import-Module -Name ActiveDirectory
                #Write-Output "ActiveDirectory Powershell module imported" 
            }
        }
        

        #Connect to domain 
        $LDAPConnection = $null
        $request = $null
        $response = $null
        $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection("")
        $LDAPConnection.SessionOptions.ReferralChasing = "None"
        $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
        [void]$request.Attributes.Add("defaultnamingcontext")
        try
	    {
            $response = $LDAPConnection.SendRequest($request)
            $global:strDomainDNName = $response.Entries[0].Attributes.defaultnamingcontext[0]
            $global:bolLDAPConnection = $true
	    }
	    catch
	    {
		    $global:bolLDAPConnection = $false
            $global:observableCollection.add(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
	    }

        if($global:bolLDAPConnection)
        {
            $global:strDomainPrinDNName = $global:strDomainDNName
            $global:strDomainLongName = $global:strDomainDNName.Replace("DC=","")
            $global:strDomainLongName = $global:strDomainLongName.Replace(",",".")
            $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strDomainLongName )
            $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
            $global:strDC = $($ojbDomain.FindDomainController()).name
            $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
            $LDAPConnection.SessionOptions.ReferralChasing = "None"
            $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
            [void]$request.Attributes.Add("dnshostname")
            [void]$request.Attributes.Add("namingcontexts")
            [void]$request.Attributes.Add("defaultnamingcontext")
            [void]$request.Attributes.Add("schemanamingcontext")
            [void]$request.Attributes.Add("configurationnamingcontext")
            [void]$request.Attributes.Add("rootdomainnamingcontext")
                    
            try
    	    {
                $response = $LDAPConnection.SendRequest($request)
                $global:bolLDAPConnection = $true
    	    }
    	    catch
    	    {
    		    $global:bolLDAPConnection = $false
                Write-host "Failed! Domain does not exist or can not be connected" -
    	    }
            if($global:bolLDAPConnection -eq $true)
            {
                $global:ForestRootDomainDN = $response.Entries[0].attributes.rootdomainnamingcontext[0]
                $global:SchemaDN = $response.Entries[0].attributes.schemanamingcontext[0]
                $global:ConfigDN = $response.Entries[0].attributes.configurationnamingcontext[0]
                $global:strDomainDNName = $response.Entries[0].attributes.defaultnamingcontext[0]
            }

            $global:DirContext = Get-DirContext $global:strDC $global:CREDS
            $global:strDomainShortName = GetDomainShortName $global:strDomainDNName $global:ConfigDN
            $global:strRootDomainShortName = GetDomainShortName $global:ForestRootDomainDN $global:ConfigDN
        }
        #If BU is supplied set to the variable for BU
        $strBU = ""

        



    }
    Process
    {

        if ($pscmdlet.ShouldProcess($global:strDomainDNName, "Create Roles and Tasks for delegation:"))
        {
            #Test if Tempalte exist
            if(($Template -eq "") -or !(Test-Path $Template))
            {
                Write-Output "Can not find the template file: $Template"
            }
            else
            {            
                #Import Template
                $csv = import-csv $Template -Encoding UTF8
                $arrRoles = New-Object System.Collections.ArrayList 
                if(TestCSVColumns $csv)
                {
                    Write-Output "Template verified!" 
                    $colHeaders = ( $csv | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name')
                    Foreach ($RoleColumnName in $colHeaders )
                    {
                        if($RoleColumnName -like "$Roleprefix*"){ [void]$arrRoles.add($RoleColumnName.Trim())}
                    }

                    #Check if any role was found in template
                    if($arrRoles.Count -gt 0)
                    {

                        $bolBUError = $false
                        if($DelelgationRootDN)
                        {
                            $strBU = $DelelgationRootDN
                            Write-Host "Verify Delegation OU: $strBU"
                            If (CheckDNExist ($strBU))
                            {    

                            }
                            else
                            {
	                            Write-Host "Delegation OU does not exist: $strBU" -ForegroundColor Yellow
                                $bolBUError = $true
                            }  
                        }
                        else
                        {
                            $strBU = "OU=Admin,$global:strDomainDNName"
                            Write-Host "Verify Delegation OU: $strBU"
                            If (CheckDNExist ($strBU))
                            {    

                            }
                            else
                            {
	                            Write-Host "Delegation OU does not exist: $strBU" -ForegroundColor Yellow
                                $bolBUError = $true

                            }  
                        }


                        if($bolBUError -eq $false)
                        {
                            #Enumerating all Roles in Matrix
                            Foreach($Role in $arrRoles)
                            {
                                $bolSvcmMgmt = $false
                                Write-Output "Creating Role: $Role"

                                #Test For which Teir the Role belong to
                                if($Role -match "-T0-")
                                {
                                    $strRoleOUDst = "OU=T0-Roles,OU=$Tier0OU," + $strBU
                                }
                                else
                                {
                                    if($Role -match "-T1-")
                                    {
                                    $strRoleOUDst = "OU=T1-Roles,OU=$Tier1OU," + $strBU 
                                    }
                                    else
                                    {
                                        $strRoleOUDst = "OU=T2-Roles,OU=$Tier2OU," + $strBU 
                                    }
                                }
                                # Check if Role alredy exist
                                if(CheckDNExist ($strRoleOUDst))
                                {
                                    if(!(CheckDNExist ("CN="+$Role+","+$strRoleOUDst)))
                                    {
                                        $script:boolFail = $false
                                        &{#Try
                                            New-ADGroup -GroupCategory:"Security" -GroupScope:"Global" -Name:"$Role" -Path:"$strRoleOUDst" -SamAccountName:"$Role" -Description:""
                                        }
                                        Trap [SystemException]
                                        {
                                            if($_.Exception.Message.ToString() -ne "The specified group already exists")
                                            {
                                                Write-Host "Failed while creating $Role .. $_" -ForegroundColor Red
                                                $script:boolFail = $true
                                            }
                                                    
                                            Continue
                                        }
                                        if($script:boolFail -eq $false)
                                        {

                                         Write-Host "Created $Role" -ForegroundColor Green
                                        }
                                    }
                                    else
                                    {
                                        Write-Host "Role already exist: $Role" -ForegroundColor Yellow
                                    }
                                }
                                else
                                {
	                                Write-Host "Role OU does not exist: $strRoleOUDst" -ForegroundColor Red
                                } 

                            } # End foreach Role

                            #Enumerating all Roles in Matrix
                            Foreach($Role in $arrRoles)
                            {
                                $strRoleGroupPath = GetGroupDN $Role
                                Write-Output "Processing Task Groups for Role: $Role"

                                foreach($line in $csv )
                                {
                                    #If the role got an "x" in the matrix create the task for the same.
                                    if($line.$($Role) -eq "x")
                                    {
                                        #Check if "Short Name" got data , if it do add it to the group name
                                        if (($line.ShortName) -ne "")
                                        {
                                            $strGrpName = ($line.GroupName.Trim())+"-"+($line.ShortName)
                                        }
                                        else
                                        {
                                            $strGrpName = ($line.GroupName.Trim())
                                        }

                                        #Create the description info
                                        $strDescrption = $line.'Task'.Trim()
                                        $strTaskID = $line.'TaskID'.Trim()
                                        $strTaskOUDst = "OU=T0-Tasks,OU=$Tier0OU," + $strBU


                                        if(CheckDNExist ($strTaskOUDst))
                                        {
                                            #Create all Task groups as Domain Local Security Groups 
                                            if(!(CheckDNExist ("CN="+$strGrpName+","+$strTaskOUDst)))
                                            {
                                                $script:boolFail = $false
                                                &{#Try
                                                    Write-Output "Creating $strGrpName"
                                                    #Command to create the group as a domain locla group
                                                    New-ADGroup -GroupCategory:"Security" -GroupScope:"DomainLocal" -Name:"$strGrpName" -Path:"$strTaskOUDst" -SamAccountName:"$strGrpName" -Description:"$strDescrption"
                                                    $Group = Get-ADGroup -Identity "CN=$strGrpName,$strTaskOUDst"
                                                    $Group.info = $strTaskID 
                                                    $Return = Set-adgroup -Instance $Group -passthru 

                                                }
                                                Trap [SystemException]
                                                {
                                                   if($_.Exception.Message.ToString() -ne "The specified local group already exists")
                                                   {
                                                        Write-Host "Failed while creating $strGrpName .. $_" -ForegroundColor Red
                                                        $script:boolFail = $true
                                                    }
                                                    
                                                   Continue
                                                }
                                                if($script:boolFail -eq $false)
                                                {

                                                 Write-Host "Created $strGrpName" -ForegroundColor Green
                                                }
                                            }
                                            else
                                            {
                                                Write-Host "Task already exist: $strGrpName" -ForegroundColor Yellow
                                            }
                                            #Add  Role group to Task Group
                                            &{#Try
                                                #Command to create the group as a domain locla group
                                                $strGroupPath = GetGroupDN $strGrpName
                                                Add-ADPrincipalGroupMembership -Identity:"$strRoleGroupPath" -MemberOf:"$strGroupPath"
                                            }
                                            Trap [SystemException]
                                            {
            
                                               Write-Host "Failed while adding  $Role to $strGrpName .. $_" -ForegroundColor Red
                                               Continue
                                            }
                                        }
                                        else
                                        {
	                                        Write-Host "Task OU does not exist: $strTaskOUDst" -ForegroundColor Red
                                        } 
                                    } # if line marked with "x"

                                }# End foreach line
                            } # End foreach Role
                        } #End if $bolBUErorr
                    }#else if test column names exist
                    else
                    {
                        Write-Host "No Roles with the prefix """$RolePrefix*""" was identified in $Template" -ForegroundColor Red
                    }#End if roles count larger than 0
                   
                } 
                else
                {
                    Write-Output "Wrong format on CSV file:$Template" 
                } #End if test column names exist  
            }
        } #End if ShouldProcess
       
    }#End Process
    End 
    {

    } #End of End
}


<#
.Synopsis
   Delegating permissions for Task groups. 
.DESCRIPTION
   This function will add permissions to task groups in AD.

.PARAMETER Template
 The path and file name of the CSV file used as a template for the delegation model

.PARAMETER Roleprefix
 The prefix of the role groups names. Default "Role".

.PARAMETER XML
 The path and file name of the XML file used as instructions for setting permissions.
 Defaults to the TaskID.xml file in the same folder as the POPADD PowerShell module.

.EXAMPLE
 Add-TaskPermissions -Template C:\temp\POPADD_Role_Task_Matrix.csv 
 Using the template for the delegatin model this function will set the permissions needed fot each task as long as the task is defnied in the TaskID.xml file.

.EXAMPLE
 Add-TaskPermissions -Template C:\temp\POPADD_Role_Task_Matrix.csv -Roleprefix MYROLES
 Using the template for the delegatin model this function will set the permissions needed fot each task as long as the task is defnied in the TaskID.xml file.
 The roles in the template all have the group name prefix MYROLES.

.EXAMPLE
 Add-TaskPermissions -Template C:\temp\POPADD_Role_Task_Matrix -XML C:\temp\TaskID.xml
 Using the template and the user defined XML file for the delegatin model this function will set the permissions needed fot each task as long as the task is defnied in the TaskID.xml file.

.INPUTS
.OUTPUTS
.COMPONENT
.ROLE
#>
function Add-TaskPermissions
{


    [CmdletBinding(DefaultParameterSetName='Filters', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Param1 Template path
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Template,
        # Param3 Role Prefix
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=1,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Roleprefix = "Role",
        # Param4 XML file
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=2,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $XML,
        # Param5 Creat Missing OU switch
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=2,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch] 
        $CreateMissingOU
        

    )

    Begin
    {
        [void][Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.Protocols")
        $CurrentFSPath = $(Get-Module popadd).ModuleBase
        #$ErrorActionPreference = "SilentlyContinue"

        #Connect to domain 
        $LDAPConnection = $null
        $request = $null
        $response = $null
        $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection("")
        $LDAPConnection.SessionOptions.ReferralChasing = "None"
        $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
        [void]$request.Attributes.Add("defaultnamingcontext")
        try
	    {
            $response = $LDAPConnection.SendRequest($request)
            $global:strDomainDNName = $response.Entries[0].Attributes.defaultnamingcontext[0]
            $global:bolLDAPConnection = $true
	    }
	    catch
	    {
		    $global:bolLDAPConnection = $false
            $global:observableCollection.add(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
	    }

        if($global:bolLDAPConnection)
        {
            $global:strDomainPrinDNName = $global:strDomainDNName
            $global:strDomainLongName = $global:strDomainDNName.Replace("DC=","")
            $global:strDomainLongName = $global:strDomainLongName.Replace(",",".")
            $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strDomainLongName )
            $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
            $global:strDC = $($ojbDomain.FindDomainController()).name
            $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
            $LDAPConnection.SessionOptions.ReferralChasing = "None"
            $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
            [void]$request.Attributes.Add("dnshostname")
            [void]$request.Attributes.Add("namingcontexts")
            [void]$request.Attributes.Add("defaultnamingcontext")
            [void]$request.Attributes.Add("schemanamingcontext")
            [void]$request.Attributes.Add("configurationnamingcontext")
            [void]$request.Attributes.Add("rootdomainnamingcontext")
                    
            try
    	    {
                $response = $LDAPConnection.SendRequest($request)
                $global:bolLDAPConnection = $true
    	    }
    	    catch
    	    {
    		    $global:bolLDAPConnection = $false
                Write-host "Failed! Domain does not exist or can not be connected" -
    	    }
            if($global:bolLDAPConnection -eq $true)
            {
                $global:ForestRootDomainDN = $response.Entries[0].attributes.rootdomainnamingcontext[0]
                $global:SchemaDN = $response.Entries[0].attributes.schemanamingcontext[0]
                $global:ConfigDN = $response.Entries[0].attributes.configurationnamingcontext[0]
                $global:strDomainDNName = $response.Entries[0].attributes.defaultnamingcontext[0]
            }

            $global:DirContext = Get-DirContext $global:strDC $global:CREDS
            $global:strDomainShortName = GetDomainShortName $global:strDomainDNName $global:ConfigDN
            $global:strRootDomainShortName = GetDomainShortName $global:ForestRootDomainDN $global:ConfigDN
        }

        #If no xml file supplied in command search for the latest version in module folder
        if($XML -eq "")
        {
            $CurrentFSPath = $(Get-Module popadd).ModuleBase
            $objTaskIDFile = ls $CurrentFSPath -Filter TaskID_*.*.xml | sort { [version]($_.BaseName -replace '^.*_(\d+(\.\d+){1,3})$', '$1') } -Descending | select -Index 0
            if($objTaskIDFile -eq $null)
            {
                $TaskIDXMLPath = ""
            }
            else
            {
                $TaskIDXMLPath = $objTaskIDFile.FullName
            }
        }
        else
        {
            $TaskIDXMLPath = $XML
        }
        $strLogFile = ".\SetPermLog.log"
        $strLogCSV = ".\SetPermLog.csv"
        $strErrorLogFile = ".\SetPermErrorLog.csv"
        $Add = $true




        $global:bolManaulOperation = $false
        $global:bolFailedlOperation = $false

        $global:arrManualDelegationList = New-Object System.Collections.ArrayList
        $global:arrFailedDelegationList  = New-Object System.Collections.ArrayList
        $arrRoles = New-Object System.Collections.ArrayList
        $arrACEs = New-Object System.Collections.ArrayList



    }
    Process
    {

        if ($pscmdlet.ShouldProcess($global:strDomainDNName, "Create OU Structure for delegation:"))
        {
            #Make sure the XML file exist.
            if(($TaskIDXMLPath -ne "") -and (Test-Path $TaskIDXMLPath))
            {
                $XMLData = New-Object XML
                $XMLData = $([xml](Get-Content $TaskIDXMLPath))
                #Test if Tempalte exist
                #Test if Tempalte exist
                if(($Template -eq "") -or !(Test-Path $Template))
                {
                    Write-Output "Can not find the template file: $Template"
                }
                else
                {            
                    $csv = import-csv $Template -Encoding UTF8
                    if(TestCSVColumns $csv)
                    {
                        $colHeaders = ( $csv | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name')
                        Foreach ($RoleColumnName in $colHeaders )
                        {
                            if($RoleColumnName -like "$Roleprefix*"){ [void]$arrRoles.add($RoleColumnName.Trim())}
                        }
                        Write-host "Verifing all targets.." -ForegroundColor Yellow
                        $bolTargetExists = $true
                        foreach($line in $csv )
                        {
                                if (($line.Target) -ne "")
                                {
                                    Foreach($Role in $arrRoles)
                                    {
            
                                        #If the role got an "x" in the matrix create the task for the same.
                                        if($line.$($Role).Trim() -eq "x")
                                        {
                                        $bolGotCheck = $true

                                        }
                                    }
                                    if($bolGotCheck)
                                    {
                                        $global:strTaskID = $line.'TaskID'.ToString().Trim()
                                        $strTaskType = $line.'Type'.ToString().Trim()
                                        $strTarget  = $line.Target
                                        if($strTaskType -eq "ACE")
                                        {    
                                            [void]$arrACEs.Clear()
                                            $strXMLQuery = "//Tasks//"+$global:strTaskID
            
                                            #Search for the TaskID in the XML file to verify that it exist
                                            if(Select-Xml -Content $XMLData.InnerXml -XPath $strXMLQuery)
                                            {
            
                                                $arrTaskACE = ($XMLData.Tasks.$global:strTaskID| Get-member -MemberType 'Property').Name
                                                foreach ($strPropertyName in $arrTaskACE)
                                                {
                                                    if ($strPropertyName -like "ACE*"){[void]$arrACEs.add($strPropertyName)}
                                                }

                                                if($arrACEs.Count -gt 0)
                                                {
                                                    if(!(CheckDNExist $strTarget))
                                                    {
                                                        if($CreateMissingOU)
                                                        {
                                                            if($strTarget.Substring(0,3) -match "OU=")
                                                            {
                                                                $arrOUs = $strTarget.Split(",")
                                                                $intOUs =  $($arrOUs | foreach($_){if($_ -match"OU="){$_}}).count
                                                                $intI = 0
                                                                for ($i=$intOUs-1;$i -ge 0; $i-- )
                                                                {
                                                                    if($intI -eq 0)
                                                                    {
                                                                        $strTestTarget = $arrOUs[$i] + "," + $global:strDomainDNName
                                                                    }
                                                                    else
                                                                    {
                                                                        $strTestTarget = $arrOUs[$i] + "," + $strTempOU
                                                                    }# End if $intI 
                                                                    if(!(CheckDNExist $strTestTarget))
                                                                    {
                                                                        CreateOU "" $strTestTarget
                                                                    } #End if DN  
                                                                    $strTempOU = $strTestTarget
                                                                    $intI++
                                                                } #End For $intOUs

                                                            }#End If Substring match OU=
                                                        }
                                                        else
                                                        {
                                                            $bolTargetExists = $fale
                                                            Write-host "Did not find: $($strTarget)" -ForegroundColor Yellow
                                                        }#End if CreateMissing
                                                    } #End if DN exist
                                                } # if arrACEs count
                                            } # End if select-xml
                                        } #if ACE Type
                                    } # if GotCheck
                                }
                        }
                        if(!($bolTargetExists))
                        {
                            Write-Host "Some targets does not exist! Verify the distinguishedNames" -ForegroundColor Red
	                        $a = Read-Host "Do you want to continue? Press Y[Yes] or N[NO]:"
	                        If ($a -eq "Y")
	                        {
                                $bolTargetExists = $true
                            }

                        }
                        else
                        {
                            Write-host "All targets OK!" -ForegroundColor green
                        }
                        if($bolTargetExists)
                        {
                            #Check if any role was found in template
                            if($arrRoles.Count -gt 0)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            {
                            #Display info on the TaskID.xml file
                            DisplayTaskIDXMLFileInfo $TaskIDXMLPath

                            foreach($line in $csv )
                            {
                                $bolGotCheck = $false
                                #Check if "Short Name" got data , if it do add it to the group name
                                if (($line.Target) -ne "")
                                {
                                    $global:strTaskName = $line.'Task'.ToString().Trim()
                                    $global:strTaskID = $line.'TaskID'.ToString().Trim()
                                    $strTaskType = $line.'Type'.ToString().Trim()
                                    if($strTaskType -eq "ACE")
                                    {                                    
                                        Foreach($Role in $arrRoles)
                                        {
            
                                            #If the role got an "x" in the matrix create the task for the same.
                                            if($line.$($Role).Trim() -eq "x")
                                            {
                                            $bolGotCheck = $true

                                            }
                                        }

                                        if($bolGotCheck)
                                        {
                                            $strTarget = ($line.Target.Trim())
                                            $global:strGrpName = ""
                                            if (($line.ShortName.Trim()) -ne "")
                                            {
                                                $global:strGrpName = ($line.GroupName.Trim())+"-"+($line.ShortName.Trim())
                                            }
                                            else
                                            {
                                                $global:strGrpName = ($line.GroupName.Trim())
                                            }
                                            $global:strGrpName = $global:strDomainShortName + "\" + $global:strGrpName 

                                                #Write-host $global:strTaskID
                                                [void]$arrACEs.Clear()
                                                $strXMLQuery = "//Tasks//"+$global:strTaskID
            
                                                #Search for the TaskID in the XML file to verify that it exist
                                                if(Select-Xml -Content $XMLData.InnerXml -XPath $strXMLQuery)
                                                                                                                                                                                                                                                                                                                                                                                                                                                        {
            
                                                $arrTaskACE = ($XMLData.Tasks.$global:strTaskID| Get-member -MemberType 'Property').Name
                                                foreach ($strPropertyName in $arrTaskACE)
                                                {
                                                    if ($strPropertyName -like "ACE*"){[void]$arrACEs.add($strPropertyName)}
                                                }

                                                if($arrACEs.Count -gt 0)
                                                {
                                                    Foreach($colACE in $arrACEs)
                                                    {
                                                        $strTarget = ($line.Target.Trim())
                                                        $strACE = $XMLData.Tasks.$global:strTaskID.$colACE.ACE
                                                        $strTrustee = $XMLData.Tasks.$global:strTaskID.$colACE.Trustee
                                                        $strAceTarget = $XMLData.Tasks.$global:strTaskID.$colACE.Target
                                                        if( $strAceTarget -ne "")
                                                        {
                                                            $strTarget = "$strAceTarget$global:strDomainDNName"
                                                        }
                                                        #
                                                        # Function Processing ACE
                                                        #
                
                                                        $splitACE = $strACE.Split(";")
                                                        $strRights = $splitACE[0]				
				                                        $strInheritanceType = $splitACE[1]				
				                                        $strObjectTypeGUID = $splitACE[2]
                                                        if($strObjectTypeGUID -match "GUID:")
                                                        {
                                                            $strObjectTypeGUID = GetSchemaObjectGUID $strObjectTypeGUID.Split(":")[1]
                                                        }
				                                        $strInheritedObjectTypeGUID = $splitACE[3]
                                                        if($strInheritedObjectTypeGUID -match "GUID:")
                                                        {
                                                            $strInheritedObjectTypeGUID = GetSchemaObjectGUID $strInheritedObjectTypeGUID.Split(":")[1]
                                                        }
				                                        $strObjectFlags = $splitACE[4]
				                                        $strAccessControlType = $splitACE[5]
				                                        $strIsInherited = $splitACE[6]
				                                        $strInheritedFlags = $splitACE[7]
				                                        $strPropFlags = $splitACE[8]
						
                                                        if($Add)
                                                        {
                                                            if($strTarget -match "CN=Deleted Objects")
                                                            {
                                                                If(!(Check-OwnerShipDeletedObjects $strTarget))
						                                        {
                                                                    #Take-OwnerShip $strTarget "contoso\canix" 
                                                                    Take-OwnerShipDeletedObjects $strTarget
                                                                }
                                                            }
                                                            if($strAccessControlType -eq "Owner")
                                                            {
                                                                If(!(Check-Owner $strTarget $global:strGrpName))
						                                        {
                                                                    Take-OwnerShip $strTarget $global:strGrpName 
                                                                }
                                                            }
                                                            else
                                                            {
                                                                #Check if the permission is already given,if not set it
						                                        If(!(Check-Perm $strTarget $global:strGrpName $strRights $strInheritanceType $strObjectTypeGUID $strInheritedObjectTypeGUID $strObjectFlags $strAccessControlType $strIsInherited $strInheritedFlags $strPropFlags))
						                                        {
							                                        #Add Permissions on OU 			
							                                        Add-Perm $strTarget $global:strGrpName $strRights $strInheritanceType $strObjectTypeGUID $strInheritedObjectTypeGUID $strObjectFlags $strAccessControlType $strIsInherited $strInheritedFlags $strPropFlags
						                                        }
                                                            }
		                                                }
                                                    #Write-host "$strTarget   $global:strGrpName $strACE"
                                                    }
                                                }
                                                else
                                                {
                                                    $strTaskInstruction = ""
                                                    $strTaskInstruction = ($XMLData.Tasks.$global:strTaskID).Instruction
                                                    #Write-host $arrTaskInstruction # `n Manually (No ACE Defined) $global:strGrpName $global:strTaskID" -ForegroundColor Cyan
                                                    $global:bolManaulOperation = $true
                                                    if($strTaskInstruction -eq "")
                                                    {
                                                        $newMessageObject = New-Object psObject | `
                                                        Add-Member NoteProperty TaskID "$global:strTaskID" -PassThru |`
                                                        Add-Member NoteProperty Task "$global:strTaskName" -PassThru |`
                                                        Add-Member NoteProperty Group "$global:strGrpName" -PassThru |`
                                                        Add-Member NoteProperty Target "$strTarget" -PassThru |`
                                                        Add-Member NoteProperty Message "No ACE Defined" -PassThru
                                                    }
                                                    else
                                                    {
                                                        $newMessageObject = New-Object psObject | `
                                                        Add-Member NoteProperty TaskID "$global:strTaskID" -PassThru |`
                                                        Add-Member NoteProperty Task "$global:strTaskName" -PassThru |`
                                                        Add-Member NoteProperty Group "$global:strGrpName" -PassThru |`
                                                        Add-Member NoteProperty Target "$strTarget" -PassThru |`
                                                        Add-Member NoteProperty Message $strTaskInstruction -PassThru
                                                    }
                                                    [void]$global:arrManualDelegationList.Add($newMessageObject)
                                                }
                                            }
                                            else
                                            {
                                                #Write-host "Manually (Not in XML) $global:strGrpName $global:strTaskID" -ForegroundColor Cyan
                                                $global:bolManaulOperation = $true

                                                $newMessageObject = New-Object psObject | `
                                                Add-Member NoteProperty TaskID "$global:strTaskID" -PassThru |`
                                                Add-Member NoteProperty Task "$global:strTaskName" -PassThru |`
                                                Add-Member NoteProperty Group "$global:strGrpName" -PassThru |`
                                                Add-Member NoteProperty Target "$strTarget" -PassThru |`
                                                Add-Member NoteProperty Message "Missing in TaskID.xml" -PassThru

                                                [void]$global:arrManualDelegationList.Add($newMessageObject)
                                            }
                                        
                                        }
                                        else
                                        {
                                            Write-Host "This target got no Role checked $($line.Target.Trim()) " -ForegroundColor Red
                                        }
                                    }#End if ACE

                                }
                                else
                                {
                                    if (($line.'GroupName') -ne "")
                                    {
                                        Write-host "No Target defined for: $($line.'GroupName')" -ForegroundColor Yellow
                                    }
                                }

                                }
                            if($global:bolFailedlOperation -eq $true)
                            {
                                $objErrorLogfile = New-Item -ItemType file $strErrorLogFile -Force
                                $global:arrFailedDelegationList | Export-Csv -Path $objErrorLogfile.FullName -NoTypeInformation -Encoding UTF8
                                Write-host "`nSome tasks failed to be delegated! See log file: $($objErrorLogfile.FullName)" -ForegroundColor Red
                            }
                            if($global:bolManaulOperation -eq $true)
                            {
                                $objLogfile = New-Item -ItemType file $strLogFile -Force
                                $objLogCSVfile = New-Item -ItemType file $strLogCSV -Force
                                $global:arrManualDelegationList | Out-File -FilePath $objLogfile.FullName 
                                $global:arrManualDelegationList | Export-Csv -Path $objLogCSVfile.FullName  -NoTypeInformation -Encoding UTF8
                                Write-host "`nSome tasks needs to be delegated manually! See log file: $($objLogfile.FullName)" -ForegroundColor Red
                            }
                        }
                            else
                            {
                                Write-Host "No Roles with the prefix """$RolePrefix*""" was identified in $Template" -ForegroundColor Red
                            }#End if roles count larger than 0
                        }

                    } 
                    else
                    {
                        Write-Output "Wrong format on CSV file:$Template" 
                    } #End if test column names exist  
                }
            }
            else
            {
                Write-host "Can not find the XML file: $TaskIDXMLPath `nMake sure the XML file is located in the same folder as the module or specify the -XML parameter." -ForegroundColor Red
            }# End Test-path $TaskIDXMLPath

        } #End if ShouldProcess
       
    }#End Process
    End 
    {

    } #End of End
}
<#
.Synopsis
   Show information about TaskID XML file. 
.DESCRIPTION
   This function will display information about the XML file for POPADD.

.PARAMETER XML
 The path and file name of the XML file used as instructions for setting permissions.
 Defaults to the TaskID.xml file in the same folder as the POPADD PowerShell module.

.EXAMPLE
 Get-TaskIDXMLInfo  
 Show version number, number of tasks and file name of the latest TaskID XML file in the PowerShell Module POPADD folder.

.EXAMPLE
 Get-TaskIDXMLInfo -XML C:\temp\TaskID.xml
 Show version number, number of tasks and file name of the user defined XML file.

.INPUTS
.OUTPUTS
.COMPONENT
.ROLE
#>
function Get-TaskIDXMLInfo
{


    [CmdletBinding(DefaultParameterSetName='Filters', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Param1 XML path
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $XML

    )

    Begin
    {

        #$CurrentFSPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\POPADD"
        $CurrentFSPath = $(Get-Module popadd).ModuleBase
        #If no xml file supplied in command search for the latest version in module folder
        if($XML -eq "")
        {
            #$CurrentFSPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\POPADD"
            $CurrentFSPath = $(Get-Module popadd).ModuleBase
            $objTaskIDFile = ls $CurrentFSPath -Filter TaskID_*.*.xml | sort { [version]($_.BaseName -replace '^.*_(\d+(\.\d+){1,3})$', '$1') } -Descending | select -Index 0
            if($objTaskIDFile -eq $null)
            {
                $TaskIDXMLPath = ""
            }
            else
            {
                $TaskIDXMLPath = $objTaskIDFile.FullName
            }
        }
        else
        {
            $TaskIDXMLPath = $XML
        }
   



    }
    Process
    {

            #Make sure the XML file exist.
            if(($TaskIDXMLPath -ne "") -and (Test-Path $TaskIDXMLPath))
            {
               DisplayTaskIDXMLFileInfo $TaskIDXMLPath
               $XMLData = New-Object XML
               $XMLData = $([xml](Get-Content $TaskIDXMLPath))  
               $arrTasks = $XMLData.SelectSingleNode("//Tasks")
               $arrTasks.ChildNodes | Format-Table -Property id,name,Level -AutoSize                            
            }
            else
            {
                Write-host "Can not find the XML file: $TaskIDXMLPath `nMake sure the XML file is located in the same folder as the module or specify the -XML parameter." -ForegroundColor Red
            }# End Test-path $TaskIDXMLPath

       
    }#End Process
    End 
    {

    } #End of End
}

<#
.Synopsis
 Export Roles and Tasks to CSV
.DESCRIPTION
 This cmd-let will export your delegation model to a CSV template you can use for import.
.PARAMETER CSV
 Output CSV Path.
.PARAMETER Roleprefix
 The prefix of the role groups names. Default "Role".
.EXAMPLE
 Add-DelegationExport -CSV C:\temp\POPADD_Role_Task_Matrix.csv 
 This command will create all roles and task groups when the DataMgmtDelegation OU is under the domain root.
.EXAMPLE
 Add-RolesAndTasks  -CSV C:\temp\POPADD_Role_Task_Matrix.csv -Roleprefix MYROLES
 This command will create all roles and task groups when the DataMgmtDelegation OU is under the domain root.
 The roles in the template all have the group name prefix MYROLES.
.INPUTS
.OUTPUTS
.COMPONENT
.ROLE
#>
function Export-ADDelegation
{


    [CmdletBinding(DefaultParameterSetName='Filters', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Param1 CSV File path
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$false, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $File,
        # Param2 Role Prefix
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=1,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Roleprefix = "Role",
        # Param3 Task Prefix
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=2,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $TaskPrefix = "Task",
        
        # Param4 Switch for adding delegated paths in AD
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=1,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch] 
        $IncludeDelegatedPath,
        
        # Param5 Switch for scaning only the domain partion
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=1,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch] 
        $OnlyDompainNC=$false,
        
        # Param6 Switch for scaning all domain in the forest
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=1,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch] 
        $Forest=$false
    )

    Begin
    {
        if($File -eq "")
        {
            #Exit if no path defined
            Write-host "You must specify a file path!" 
            break
        }
        else
        {
            if(Test-Path($File))
            {
                Write-host "$File alredy exist! Do you want to overwrite the file?" -ForegroundColor Yellow
                $a = Read-Host "Do you want to continue? Press Y[Yes] or N[NO]:" 
	            If (!($a -eq "Y"))
	            {
                    break
                }
                Remove-Item $File -Force
            }
            if($IncludeDelegatedPath)
            {
                #Exit if user don't want to search AD for task groups
                Write-Host "`n**********************************************************************************************************"  -ForegroundColor Yellow
                Write-Host "Adding delegated paths for task groups requires the script to touch almost all AD objects in the domain!.`n" -ForegroundColor Yellow
                Write-Host "This is a very long running job and might effect performance on your Domain Controller." -ForegroundColor red
                Write-Host "`n**********************************************************************************************************"  -ForegroundColor Yellow
	            $a = Read-Host "Do you want to continue? Press Y[Yes] or N[NO]:"
	            If (!($a -eq "Y"))
	            {
                    break
                }
$strCSVHeader = @"
"OU","ObjectClass","IdentityReference","ActiveDirectoryRights","InheritanceType","ObjectType","InheritedObjectType","ObjectFlags","AccessControlType","IsInherited","InheritanceFlags","PropagationFlags","SDDate","InvocationID","OrgUSN","LegendText"
"@
            }
            if ($(Get-Module -name ActiveDirectory -ListAvailable) -eq $null)
            {
                Write-Output  "Powershell module for ActiveDirectory not installed! This functions requires the ActiveDirectory Powershell module to be available" 
            }
            else
            {
                if ($(Get-Module -name ActiveDirectory) -eq $null)
                {
                    #Load ActiveDirectory Module
                    Import-Module -Name ActiveDirectory
                    #Write-Output "ActiveDirectory Powershell module imported" 
                }
            }
        

            #Connect to domain 
            $LDAPConnection = $null
            $request = $null
            $response = $null
            $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection("")
            $LDAPConnection.SessionOptions.ReferralChasing = "None"
            $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
            [void]$request.Attributes.Add("defaultnamingcontext")
            try
	        {
                $response = $LDAPConnection.SendRequest($request)
                $global:strDomainDNName = $response.Entries[0].Attributes.defaultnamingcontext[0]
                $global:bolLDAPConnection = $true
	        }
	        catch
	        {
		        $global:bolLDAPConnection = $false
                $global:observableCollection.add(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
	        }

            if($global:bolLDAPConnection)
            {
                $global:strDomainPrinDNName = $global:strDomainDNName
                $global:strDomainLongName = $global:strDomainDNName.Replace("DC=","")
                $global:strDomainLongName = $global:strDomainLongName.Replace(",",".")
                $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strDomainLongName )
                $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
                $global:strDC = $($ojbDomain.FindDomainController()).name
                $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
                $LDAPConnection.SessionOptions.ReferralChasing = "None"
                $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
                [void]$request.Attributes.Add("dnshostname")
                [void]$request.Attributes.Add("namingcontexts")
                [void]$request.Attributes.Add("defaultnamingcontext")
                [void]$request.Attributes.Add("schemanamingcontext")
                [void]$request.Attributes.Add("configurationnamingcontext")
                [void]$request.Attributes.Add("rootdomainnamingcontext")
                    
                try
    	        {
                    $response = $LDAPConnection.SendRequest($request)
                    $global:bolLDAPConnection = $true
    	        }
    	        catch
    	        {
    		        $global:bolLDAPConnection = $false
                    Write-host "Failed! Domain does not exist or can not be connected" -
    	        }
                if($global:bolLDAPConnection -eq $true)
                {
                    $global:ForestRootDomainDN = $response.Entries[0].attributes.rootdomainnamingcontext[0]
                    $global:SchemaDN = $response.Entries[0].attributes.schemanamingcontext[0]
                    $global:ConfigDN = $response.Entries[0].attributes.configurationnamingcontext[0]
                    $global:strDomainDNName = $response.Entries[0].attributes.defaultnamingcontext[0]
                }

                $global:DirContext = Get-DirContext $global:strDC $global:CREDS
                $global:strDomainShortName = GetDomainShortName $global:strDomainDNName $global:ConfigDN
                $global:strRootDomainShortName = GetDomainShortName $global:ForestRootDomainDN $global:ConfigDN
            }
        }
        #break



    }
    Process
    {

        if ($pscmdlet.ShouldProcess($global:strDomainDNName, "Export Roles and Tasks for delegation:"))
        {
                #If delegated paths should be populated do this
                if($IncludeDelegatedPath)
                {
                    $strFileCSV = ".\FilterScanTmp.csv"
                    
                    $strFileCSVPerm = $($File.Remove([int]$file.Length-4,4)+"Perm.csv")

                    $txtFilterTrustee = "*"+$($TaskPrefix.replace("*",""))+"*"

$strCSVHeaderOU = @"
"OU","IdentityReference"
"@
                If ((Test-Path $strFileCSVPerm) -eq $true)
                {
                    Remove-Item $strFileCSVPerm
                    $objFileCSVPerm = New-Item -ItemType file $strFileCSVPerm -Force
                    $strFileCSVPerm = $objFileCSVPerm.FullName
                }
                $strCSVHeader | Out-File -FilePath $strFileCSVPerm
                If ((Test-Path $strFileCSV) -eq $true)
                {
                    Remove-Item $strFileCSV
                    $objFileCSV = New-Item -ItemType file $strFileCSV -Force
                    $strFileCSV = $objFileCSV.FullName
                }
                $strCSVHeaderOU | Out-File -FilePath $strFileCSV
                Write-host "`nSearching Naming Context: $global:strDomainDNName" -ForegroundColor yellow
                
                $intMatchingTrustee = Get-AceTrustee $global:strDomainDNName $txtFilterTrustee $strFileCSV  $strFileCSVPerm
                Write-host "Found $intMatchingTrustee matching delegations"
                
                #If user want to scan the whole forest
                if($Forest)
                {
                    $arrDomains = GetAllDomains
                    if($arrDomains.count -gt 0)
                    {
                    Foreach ($Domain in $arrDomains)
                    {
                        if($Domain -ne $global:strDomainDNName)
                        {
                            Write-host "`nSearching Naming Context: $Domain" -ForegroundColor yellow
                            $intMatchingTrustee = Get-AceTrustee $Domain $txtFilterTrustee $strFileCSV $strFileCSVPerm
                            Write-host "Found $intMatchingTrustee matching delegations"
                        }#End if domain not eq to current domain
                    }#End foreach Domain
                    }#Enf if gt 0

                }

                
                #If user only want to scan the domain partition skip Config and Schema NC
                if(!$OnlyDompainNC)
                {
                    Write-host "`nSearching Naming Context: $global:ConfigDN" -ForegroundColor yellow
                    $intMatchingTrustee = Get-AceTrustee $global:ConfigDN $txtFilterTrustee $strFileCSV $strFileCSVPerm
                    Write-host "Found $intMatchingTrustee matching delegations"

                    Write-host "`nSearching Naming Context: $global:SchemaDN" -ForegroundColor yellow
                    $intMatchingTrustee = Get-AceTrustee $global:SchemaDN $txtFilterTrustee $strFileCSV $strFileCSVPerm
                    Write-host "Found $intMatchingTrustee matching delegations"
                }
                
                $arrTaskPaths = ""
                $arrTaskPaths = import-csv $strFileCSV -Encoding UTF8
                If ((Test-Path $strFileCSV) -eq $true)
                {
                    Remove-Item $strFileCSV
                }
            }

         
            $arrTaskList = New-Object System.Collections.ArrayList
            $arrMatrix = New-Object System.Collections.ArrayList
            $arrAssingedTaskList = New-Object System.Collections.ArrayList

            #Search for all Role Groups that match the prefix Role or custom value
            $arrRole = Get-ADGroup -Filter "samAccountName -like '$RolePrefix*'" 

            #Extract all Task Groups that are assinged to a role aka task groups that are used
            Foreach ($Role in $arrRole)
            {
                #Expand the memberof value and add it to the list
                $MemberOF = $Role | Get-ADObject -Properties memberof | select -Property memberof -ExpandProperty memberof
                Foreach ($MemberShip in $MemberOF)
                {
                    #if($MemberShip -match "CN="+$TaskPrefix)
                    #{
                        [Void]$arrAssingedTaskList.Add($MemberShip)
                    #}
                }
            }

            #Remove duplicate task groups
            $arrAssingedTaskList = $arrAssingedTaskList | select -Unique

            #Export all tasks to a object and add it to a list
            Foreach ($Task in $arrAssingedTaskList)
            {
                #Get more properties for the task group object

                $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
                $LDAPConnection.SessionOptions.ReferralChasing = "All"
                $request = New-Object System.directoryServices.Protocols.SearchRequest("$Task", "(name=*)", "Base")
                [void]$request.Attributes.Add("Description")
                [void]$request.Attributes.Add("info")
                [void]$request.Attributes.Add("samAccountName")
                [void]$request.Attributes.Add("distinguishedname")
                $response = $LDAPConnection.SendRequest($request)
                $ADTask = $response.Entries[0]

                #Get group name
                $strTaskGroupName = $ADTask.attributes.samaccountname[0]
                #Get the description
                
                if($ADTask.attributes.description)
                {
                    $strDescription = $ADTask.attributes.description[0]
                    
                }
                else
                {
                    $strDescription = ""
                }
                #If the description field contains a hyphen pich the most right part of the string
                if($strDescription.Contains("-"))
                {
                    $strTask = ($strDescription.Split("-")[1]).Trim()
                }
                else
                {
                    if($strDescription)
                    {
                        $strTask = $strDescription
                    }
                }
                $strTargetPath = ""
                if($IncludeDelegatedPath)
                {
                    Foreach($Trustee in $arrTaskPaths)
                    {
                        if($Trustee.IdentityReference -match $strTaskGroupName)
                        {
                            $strTargetPath = $Trustee.OU  
                        }
                    }
                }
                #Check if the task got a TaskID
                if($ADTask.attributes.info)
                {
                    $strTaskID = $ADTask.attributes.info[0]
                    if(!($strTaskID -match "AD\d{4}"))
                    {
                        $strTaskID = ""
                    }
                }
                else
                {
                    $strTaskID = ""
                }
                #Create a custom object that will be exported to a XLSX.
                #The oject is ordred accordingly GroupName,<Role Names>                if($IncludeDelegatedPath)
                {                    $objMatrix = [pscustomobject][ordered]@{                    GroupName= $strTaskGroupName;`
                    Target="$strTargetPath"}
                }
                else
                {
                    $objMatrix = [pscustomobject][ordered]@{                    GroupName= $strTaskGroupName}
                }
                

                #Create a custom object that will be exported to a CSV.
                #The oject is ordred accordingly TaskID,Task,GroupName,Type,Target/Path,Short Name Target,<Role Names>                $objTask = [pscustomobject][ordered]@{                TaskID=$strTaskID ;`
                Task="$strTask";`                GroupName= $strTaskGroupName;`                Type="";`                Target="$strTargetPath";`                ShortName="";}

                #Add a each role as a property (member) to the new custo object
                Foreach ($Role in $arrRole)
                {
                    Add-Member -InputObject $objTask $Role.Name ""
                    Add-Member -InputObject $objMatrix $Role.Name ""
                }

                #Enumareate membership in Tasks
                $TaskMembers = Get-ADGroupMember -Identity $Task 
    
                #Mark assinged Task with a "x" for each role 
                Foreach($AssignedRole in $TaskMembers)
                {
                    if($AssignedRole -like "CN=$RolePrefix*")
                    {
                        $MemberValue = $AssignedRole.Name.ToString()
                        $objTask.$MemberValue = "x"
                        $objMatrix.$MemberValue = "x"
                    }
                }

                #Add all Tasks to an array "CSV"
                [void]$arrTaskList.Add($objTask)
                #Add all Tasks to an array "Matrix"
                [void]$arrMatrix.Add($objMatrix)

            }

            #Export all Roles and Task Excel Sheet

            $arrMatrix | select-object  | Export-Excel -path $File -WorkSheetname "Matrix" -BoldTopRow -TableStyle Medium2 -TableName "matrixtbl" -NoLegend -AutoSize -FreezeTopRow
          
            #Export all Roles and Task to a CSV
            $arrTaskList  |Export-Csv $($File.Remove([int]$file.Length-4,4)+"csv") -NoTypeInformation -Encoding UTF8

            ### Enumerate Role Group Members and Empty Roles
            $arrRoleGroupResults = New-Object System.Collections.ArrayList
            $arrRoleMembersList = New-Object System.Collections.ArrayList
            $arrRoleMembersObjects = New-Object System.Collections.ArrayList
            $arrEmptyRoles = New-Object System.Collections.ArrayList
            $arrEmptyRoleReport = New-Object System.Collections.ArrayList
            foreach($Role in $arrRole)
            {

            
                #Enumareate membership in Tasks
                $global:colOfMembersExpanded =  @{}
                getMemberExpanded $Role.DistinguishedName
                $Members = $global:colOfMembersExpanded.Keys

                if($Members.Count -gt 0)
                {
                     Foreach ($uniqueMember in $Members)
                    {
                        [void]$arrRoleMembersList.add($uniqueMember)
                    }
                }
                else
                {
                     $objEmptyRole = [pscustomobject][ordered]@{                    'Role Task Group'= $Role.DistinguishedName}
                    [void]$arrEmptyRoles.add($objEmptyRole)
                }
            }

            #If any empty roles exist export the list to excel
             if(($arrEmptyRoles).count -gt 0)
            {
                $arrEmptyRoles | Select-Object  | Export-Excel -path $File -WorkSheetname "Empty Role Groups" -BoldTopRow -TableStyle Dark3 -TableName "emptyroletbl" -NoLegend -AutoSize -FreezeTopRow
                                $objEmptyRoles = [pscustomobject][ordered]@{                GroupName=  "Empty Roles";
                Members =  $(($arrEmptyRoles).count)}
                [void]$arrEmptyRoleReport.Add($objEmptyRoles)
                #Generate HTLM table of members
                $htmlEmptyRoletable = GenerateDiagramMembers $arrEmptyRoleReport
                $strHTMLText = $strHTMLText + "<h2>Empty Role </h2>`n"
                $strHTMLText = $strHTMLText + $htmlEmptyRoletable
            }


            ### Enumerate Empty Task Groups

            $arrEmptyTasks = New-Object System.Collections.ArrayList
            $arrEmptyTaskReport = New-Object System.Collections.ArrayList
            #Search for all Task Groups that match the prefix Task or custom value
            $arrTask = Get-ADGroup -Filter "samAccountName -like '$TaskPrefix*'" 

            #Extract all Task Groups that are assinged to a role aka task groups that are used
            Foreach ($Task in $arrTask)
            {
                #Expand the memberof value and add it to the list
                $Members = $Task | Get-ADGroupMember
                if ($Members -eq $null)
                {
                    $objEmptyTask = [pscustomobject][ordered]@{                    'Empty Task Group'= $Task.DistinguishedName}
                                        
                    [void]$arrEmptyTasks.Add($objEmptyTask)
                }
            }
            if(($arrEmptyTasks).count -gt 0)
            {
                $arrEmptyTasks | Select-Object  | Export-Excel -path $File -WorkSheetname "Empty Task Groups" -BoldTopRow -TableStyle Dark3 -TableName "emptytasktbl" -NoLegend -AutoSize -FreezeTopRow
                                $objEmptyTasks = [pscustomobject][ordered]@{                GroupName=  "Empty Tasks";
                Members =  $(($arrEmptyTasks).count)}
                [void]$arrEmptyTaskReport.Add($objEmptyTasks)
                #Generate HTLM table of members
                $htmlEmptyTasktable = GenerateDiagramMembers $arrEmptyTaskReport
                $strHTMLText = $strHTMLText + "<h2>Empty Tasks </h2>`n"
                $strHTMLText = $strHTMLText + $htmlEmptyTasktable
            }


            #Filter out unique members
            $arrRoleMembersList = $arrRoleMembersList | Select-Object -Unique

            # Create object for each member and add roles as attributes/properties
            Foreach ($strRoleUser in $arrRoleMembersList)
            {
                $objRoleUser = [pscustomobject][ordered]@{                User= $strRoleUser}
                #Add a each role as a property (member) to the new custo object
                Foreach ($Role in $arrRole)
                {
                    Add-Member -InputObject $objRoleUser $Role.Name ""
                }
                [void]$arrRoleMembersObjects.add($objRoleUser)

            }
            $arrRoleGroupReport = new-object System.Collections.ArrayList
            #Update each member object with info on role membership and account attributes
            foreach($Role in $arrRole)
            {
                #Enumareate membership in Tasks
                $global:colOfMembersExpanded =  @{}
                getMemberExpanded $Role.DistinguishedName
                $Members = $global:colOfMembersExpanded.Keys

                if($Members.Count -gt 0)
                {
                     Foreach ($uniqueMember in $Members)
                    {
                        Foreach ($RoleMember in $arrRoleMembersObjects)
                        {
                            if($RoleMember.User -eq $uniqueMember)
                            {
                                $RoleMember.$($Role.Name) = "x"
                                $RoleMemberAttribs = getUserAccountAttribs $uniqueMember $Role.DistinguishedName $strDomainShortName $global:colOfMembersExpanded."$uniqueMember"
                                if($RoleMember.GroupDomain -ne $RoleMemberAttribs.GroupDomain)
                                {
                                    Add-Member -InputObject $RoleMember GroupDomain $RoleMemberAttribs.GroupDomain
                                    Add-Member -InputObject $RoleMember UserDomain $RoleMemberAttribs.UserDomain
                                    Add-Member -InputObject $RoleMember SAM $RoleMemberAttribs.SAM
                                    Add-Member -InputObject $RoleMember Name $RoleMemberAttribs.Name
                                    Add-Member -InputObject $RoleMember Type $RoleMemberAttribs.Type 
                                    Add-Member -InputObject $RoleMember 'Password Age' $RoleMemberAttribs.'Password Age'
                                    Add-Member -InputObject $RoleMember Disabled $RoleMemberAttribs.Disabled
                                    Add-Member -InputObject $RoleMember 'Password Never Expires' $RoleMemberAttribs.'Password Never Expires'
                                    Add-Member -InputObject $RoleMember 'No Delegation' $RoleMemberAttribs.'No Delegation'
                                    Add-Member -InputObject $RoleMember 'Password Not Required' $RoleMemberAttribs.'Password Not Required'
                                Add-Member -InputObject $RoleMember 'MailAddress' $RoleMemberAttribs.'MailAddress'
                                }
                            }
                        }

                    }
                   
                }# End if Members count is zero
                $objRoleGroup = [pscustomobject][ordered]@{                GroupName=  $Role.Name;
                Members =  $Members.Count}
                [void]$arrRoleGroupReport.Add($objRoleGroup)
            }#End For each Role in arrRole
            
   
            #Generate HTLM table of members
            $htmlRoletable = GenerateDiagramMembers $arrRoleGroupReport
            $strHTMLText = $strHTMLText + "<h2>Role Group Membership </h2>`n"
            $strHTMLText = $strHTMLText + $htmlRoletable

            if($arrRoleMembersObjects.Count -gt 0)
            {
                #Export Role Members to Excel
                $arrRoleMembersObjects | Select-Object  | Export-Excel -path $File -WorkSheetname "Role Memberships" -BoldTopRow -TableStyle Dark2 -TableName "rolemembers" -NoLegend -AutoSize -FreezeTopRow
            }
           
            
            ### Enumerate Privileged Groups
            $arrPrivGroupReport = new-object System.Collections.ArrayList
            $arrPrivGroupReturned = Get-PivGroups
            foreach($strPrivGroup in $arrPrivGroupReturned.Keys)
            {
                $arrPrivGroupResults = New-Object System.Collections.ArrayList
                #Enumareate membership in Tasks
                $global:colOfMembersExpanded =  @{}
                getMemberExpanded $strPrivGroup
                $Members = $global:colOfMembersExpanded.Keys

                if($Members.Count -gt 0)
                {
                    Foreach ($uniqueMember in $Members)
                    {
 
                        $PrivUser = getUserAccountAttribs $uniqueMember $($arrPrivGroupReturned.Item($strPrivGroup)) $strDomainShortName $global:colOfMembersExpanded."$uniqueMember"
                        [void]$arrPrivGroupResults.add($PrivUser)    
                    }
                    $arrPrivGroupResults | Select-Object  | Export-Excel -path $File -WorkSheetname "$($arrPrivGroupReturned.Item($strPrivGroup))" -BoldTopRow -TableStyle Dark2 -TableName $(($arrPrivGroupReturned.Item($strPrivGroup)).Replace(" ","")) -NoLegend -AutoSize -FreezeTopRow
                }
                $objPrivGroup = [pscustomobject][ordered]@{                    GroupName=   $($arrPrivGroupReturned.Item($strPrivGroup));
                    Members =  $Members.Count}
                [void]$arrPrivGroupReport.Add($objPrivGroup)
                
            }

        } #End if ShouldProcess

        #Generate HTLM table of members
        $htmlPrivtable = GenerateDiagramMembers $arrPrivGroupReport


        $strHTMLText = $strHTMLText + "<h2>Privileged Group Membership </h2>`n"
        $strHTMLText = $strHTMLText + $htmlPrivtable
        $strHTMLText | Out-File -FilePath $($File.Remove([int]$file.Length-4,4)+"html") -Force
       
    }#End Process
    End 
    {

    } #End of End
}
<#
.Synopsis
   Remover Permissions using CSV template. 
.DESCRIPTION
   This function will remove permissions in AD.

.PARAMETER Template
 The path and file name of the CSV file used as a template for the delegation model
 
.EXAMPLE
 Rem-Permissions -Template C:\temp\DelegatedPerm.csv 
 Using the template as input for which and where to remove permissions.

.INPUTS
.OUTPUTS
.COMPONENT
.ROLE
#>
function Remove-Permissions
{


    [CmdletBinding(DefaultParameterSetName='Filters', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Param1 Template path
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Template,
        # Param2 Destination Domain 
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $DstDomain,
        # Param3 Old Domain DN 
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $OldDomDN,
        # Param4 New DN to replace with
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $NewDN,
        # Param5 OLD DN to replace 
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $OldDN,
        # Param5 OLD Netbios Name to replace
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $OldNETBIOS
    )

    Begin
    {
        [void][Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.Protocols")
        $CurrentFSPath = $(Get-Module popadd).ModuleBase
        #$ErrorActionPreference = "SilentlyContinue"

        #Connect to domain 
        $LDAPConnection = $null
        $request = $null
        $response = $null
        $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection("")
        $LDAPConnection.SessionOptions.ReferralChasing = "None"
        $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
        [void]$request.Attributes.Add("defaultnamingcontext")
        try
	    {
            $response = $LDAPConnection.SendRequest($request)
            $global:strDomainDNName = $response.Entries[0].Attributes.defaultnamingcontext[0]
            $global:bolLDAPConnection = $true
	    }
	    catch
	    {
		    $global:bolLDAPConnection = $false
            $global:observableCollection.add(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
	    }

        if($global:bolLDAPConnection)
        {
            $global:strDomainPrinDNName = $global:strDomainDNName
            $global:strDomainLongName = $global:strDomainDNName.Replace("DC=","")
            $global:strDomainLongName = $global:strDomainLongName.Replace(",",".")
            $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strDomainLongName )
            $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
            $global:strDC = $($ojbDomain.FindDomainController()).name
            $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
            $LDAPConnection.SessionOptions.ReferralChasing = "None"
            $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
            [void]$request.Attributes.Add("dnshostname")
            [void]$request.Attributes.Add("namingcontexts")
            [void]$request.Attributes.Add("defaultnamingcontext")
            [void]$request.Attributes.Add("schemanamingcontext")
            [void]$request.Attributes.Add("configurationnamingcontext")
            [void]$request.Attributes.Add("rootdomainnamingcontext")
                    
            try
    	    {
                $response = $LDAPConnection.SendRequest($request)
                $global:bolLDAPConnection = $true
    	    }
    	    catch
    	    {
    		    $global:bolLDAPConnection = $false
                Write-host "Failed! Domain does not exist or can not be connected" -
    	    }
            if($global:bolLDAPConnection -eq $true)
            {
                $global:ForestRootDomainDN = $response.Entries[0].attributes.rootdomainnamingcontext[0]
                $global:SchemaDN = $response.Entries[0].attributes.schemanamingcontext[0]
                $global:ConfigDN = $response.Entries[0].attributes.configurationnamingcontext[0]
                $global:strDomainDNName = $response.Entries[0].attributes.defaultnamingcontext[0]
            }

            $global:DirContext = Get-DirContext $global:strDC $global:CREDS
            $global:strDomainShortName = GetDomainShortName $global:strDomainDNName $global:ConfigDN
            $global:strRootDomainShortName = GetDomainShortName $global:ForestRootDomainDN $global:ConfigDN
        }



    }
    Process
    {

        if ($pscmdlet.ShouldProcess($global:strDomainDNName, "Remove Permissions:"))
        {
   
            if($Template) 
            {
                Write-Host "***********************************************************" -ForegroundColor Red
                Write-Host "****************** Running in Removal Mode ****************" -ForegroundColor Red
                Write-Host "***********************************************************" -ForegroundColor Red
                $a = Read-Host "Do you want to continue? Press Y[Yes] or N[NO]:"
                If (!($a -eq "Y"))
                {
	                break
                }
                $bolReplaceDom = $false

                if (($OldNETBIOS) -and (!(($OldDomDN) -and ($DstDomain)))) 
                {
	            funHelp  
                }
                if (($OldDomDN) -and (!(($OldNETBIOS) -and ($DstDomain)))) 
                {
	            funHelp  
                }
                if (($DstDomain) -and (!(($OldNETBIOS) -and ($OldDomDN)))) 
                {
	            funHelp  
                }
                if (($OldDN) -and (!($NewDN)) )
                {
	            funHelp  
                } 
                if (($NewDN) -and (!($OldDN)) )
                {
	            funHelp  
                }             

                if (($DstDomain) -and ($OldNETBIOS) -and ($OldDomDN))
                {
                    $global:strTemplateDomainLongName = $DstDomain
                    $global:strTemplateDomainDNName = "DC=$($DstDomain.Replace(".",",DC="))"
        
                    
                    #Check if the domain from the tempalte differ from the current connected domain.
                    if(!($global:strDomainDNName -eq $global:strTemplateDomainDNName))
                    {
                        Write-host "`nTrying to connect to domain: $global:strTemplateDomainDNName" -ForegroundColor Yellow
                        #Check if connection to the template domain can be done.
                        If (!(CheckDNExist ($global:strTemplateDomainDNName)))
                        {    
                            Write-Host Domain $global:strTemplateDomainDNName can not be found! -ForegroundColor red
                            break
                        }
                        
                        $global:strTemplateDomainLongName = $global:strTemplateDomainDNName.Replace("DC=","")
                        $global:strTemplateDomainLongName = $global:strTemplateDomainLongName.Replace(",",".")
                
                        $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strTemplateDomainLongName )
                        $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
                        $global:strDC  = $($ojbDomain.FindDomainController()).name
                        $global:Forest = Get-Forest $global:strDC
                        $global:ForestRootDomainDN = Get-DomainDNfromFQDN $global:Forest.RootDomain
   
                        $global:strTemplateDomainShortName = GetDomainShortName $global:strTemplateDomainDNName $("CN=Configuration,"+$global:ForestRootDomainDN)
                    }
                    else
                    {
                        $global:strTemplateDomainShortName = $global:strDomainShortName
                    }
                    #Now the domain will be replaced in the temlate
                    $bolReplaceDom = $true   
                }
                $int = 0
                $TempString
                #$fs = [System.IO.File]::OpenText($Template) 
                $global:bolCSVLoaded = $false
                &{#Try
                    $global:bolCSVLoaded = $true
                    $global:csvHistACLs = import-Csv $Template -Encoding UTF8
                }
                Trap [SystemException]
                {
                    $strCSVErr = $_.Exception.Message
                    $global:bolCSVLoaded = $false
                    continue
                }   
                    $index = 0
                while($index -le @($global:csvHistACLs).count -1) 
                {
		            $strOU = $global:csvHistACLs[$index].OU

                    $strTrustee = $global:csvHistACLs[$index].IdentityReference
                        
                    if ($bolReplaceDom -eq $false)
                    {
		                    
                        if (($strOU -match "cn=") -or ($strOU -match "ou="))
                        {
                            $global:strTemplateDomainDNName =  Get-DomainDN $strOU
                        }
                        else
                        {
                            $global:strTemplateDomainDNName = $strOU
                        }
                        #Check if the domain from the tempalte differ from the current connected domain.
                        if(!($global:strDomainDNName -eq $global:strTemplateDomainDNName))
                        {
                            Write-host "`nTrying to connect to domain: $global:strTemplateDomainDNName" -ForegroundColor Yellow
                            #Check if connection to the template domain can be done.
                            If (!(CheckDNExist ($global:strTemplateDomainDNName)))
                            {    
                                Write-Host Domain $global:strTemplateDomainDNName can not be found! -ForegroundColor red
                                break
                            }
                        
                            $global:strTemplateDomainLongName = $global:strTemplateDomainDNName.Replace("DC=","")
                            $global:strTemplateDomainLongName = $global:strTemplateDomainLongName.Replace(",",".")
                
                            $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strTemplateDomainLongName )
                            $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
                            $global:strDC  = $($ojbDomain.FindDomainController()).name
                            $global:Forest = Get-Forest $global:strDC
                            $global:ForestRootDomainDN = Get-DomainDNfromFQDN $global:Forest.RootDomain
   
                            $global:strTemplateDomainShortName = GetDomainShortName $global:strTemplateDomainDNName $("CN=Configuration,"+$global:ForestRootDomainDN)
                        }
                        else
                        {
                            $global:strTemplateDomainShortName = $global:strDomainShortName
                        }
                    }
                    else
                    {
                        $strOU = ($strOU.ToLower().replace($OldDomDN.ToLower(),$strTemplateDomainDNName))

                        if($strTrustee.Contains("\"))
                        {
                            $strTrustee = ($strTrustee.Split("\")[0].ToLower().replace($OldNETBIOS.ToLower(),$global:strTemplateDomainShortName)+"\"+$strTrustee.Split("\")[1])
                        }
                    }

                    if (($NewDN) -and ($OldDN) )
                    {
                        $strOU = ($strOU.ToLower().replace($OldDN.ToLower(),$NewDN))
                    }
					
                    $strRights = $global:csvHistACLs[$index].ActiveDirectoryRights				
                    $strInheritanceType = $global:csvHistACLs[$index].InheritanceType				
                    $strObjectTypeGUID =  $global:csvHistACLs[$index].ObjectType
                    if($strObjectTypeGUID -match "GUID:")
                    {
                        $strObjectTypeGUID = GetSchemaObjectGUID $strObjectTypeGUID.Split(":")[1]
                    }
                    $strInheritedObjectTypeGUID = $global:csvHistACLs[$index].InheritedObjectType
                    if($strInheritedObjectTypeGUID -match "GUID:")
                    {
                        $strInheritedObjectTypeGUID = GetSchemaObjectGUID $strInheritedObjectTypeGUID.Split(":")[1]
                    }
                    $strObjectFlags = $global:csvHistACLs[$index].ObjectFlags
                    $strAccessControlType = $global:csvHistACLs[$index].AccessControlType
                    $strIsInherited = $global:csvHistACLs[$index].IsInherited
                    $strInheritedFlags = $global:csvHistACLs[$index].InheritanceFlags
                    $strPropFlags = $global:csvHistACLs[$index].PropagationFlags
						

                    if($strAccessControlType -eq "Owner")
                    {
                        Write-Output "Skip line: Owner - Cannot remove owner!"
                    }
                    else
                    {
                        #Check if the permission exist
						If(Check-Perm $strOU $strTrustee $strRights $strInheritanceType $strObjectTypeGUID $strInheritedObjectTypeGUID $strObjectFlags $strAccessControlType $strIsInherited $strInheritedFlags $strPropFlags)
						{
							#Add Permissions on OU 			
							Rem-Perm $strOU $strTrustee $strRights $strInheritanceType $strObjectTypeGUID $strInheritedObjectTypeGUID $strObjectFlags $strAccessControlType $strIsInherited $strInheritedFlags $strPropFlags
						}
                    }

			
                    $index++	    
				}#End While
              }
            else 
            {
	            Write-host "No Template defined!" -ForegroundColor Red
            }
        } #End if ShouldProcess
       
    }#End Process
    End 
    {

    } #End of End
}
<#
.Synopsis
   Remover Permissions using CSV template. 
.DESCRIPTION
   This function will add permissions in A using a template file.

.PARAMETER Template
 The path and file name of the CSV file used as a template for the delegation model
 
.EXAMPLE
 Add-Permissions -Template C:\temp\DelegatedPerm.csv 
 Using the template as input for which and where to add permissions.

.INPUTS
.OUTPUTS
.COMPONENT
.ROLE
#>
function Add-Permissions
{


    [CmdletBinding(DefaultParameterSetName='Filters', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Param1 Template path
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $Template,
        # Param2 Destination Domain 
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $DstDomain,
        # Param3 Old Domain DN 
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $OldDomDN,
        # Param4 New DN to replace with
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $NewDN,
        # Param5 OLD DN to replace 
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $OldDN,
        # Param5 OLD Netbios Name to replace
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parms')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String] 
        $OldNETBIOS
    )

    Begin
    {
        [void][Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.Protocols")
        $CurrentFSPath = $(Get-Module popadd).ModuleBase
        #$ErrorActionPreference = "SilentlyContinue"

        #Connect to domain 
        $LDAPConnection = $null
        $request = $null
        $response = $null
        $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection("")
        $LDAPConnection.SessionOptions.ReferralChasing = "None"
        $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
        [void]$request.Attributes.Add("defaultnamingcontext")
        try
	    {
            $response = $LDAPConnection.SendRequest($request)
            $global:strDomainDNName = $response.Entries[0].Attributes.defaultnamingcontext[0]
            $global:bolLDAPConnection = $true
	    }
	    catch
	    {
		    $global:bolLDAPConnection = $false
            $global:observableCollection.add(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
	    }

        if($global:bolLDAPConnection)
        {
            $global:strDomainPrinDNName = $global:strDomainDNName
            $global:strDomainLongName = $global:strDomainDNName.Replace("DC=","")
            $global:strDomainLongName = $global:strDomainLongName.Replace(",",".")
            $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strDomainLongName )
            $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
            $global:strDC = $($ojbDomain.FindDomainController()).name
            $LDAPConnection = New-Object System.DirectoryServices.Protocols.LDAPConnection($global:strDC, $global:CREDS)
            $LDAPConnection.SessionOptions.ReferralChasing = "None"
            $request = New-Object System.directoryServices.Protocols.SearchRequest($null, "(objectClass=*)", "base")
            [void]$request.Attributes.Add("dnshostname")
            [void]$request.Attributes.Add("namingcontexts")
            [void]$request.Attributes.Add("defaultnamingcontext")
            [void]$request.Attributes.Add("schemanamingcontext")
            [void]$request.Attributes.Add("configurationnamingcontext")
            [void]$request.Attributes.Add("rootdomainnamingcontext")
                    
            try
    	    {
                $response = $LDAPConnection.SendRequest($request)
                $global:bolLDAPConnection = $true
    	    }
    	    catch
    	    {
    		    $global:bolLDAPConnection = $false
                Write-host "Failed! Domain does not exist or can not be connected" -
    	    }
            if($global:bolLDAPConnection -eq $true)
            {
                $global:ForestRootDomainDN = $response.Entries[0].attributes.rootdomainnamingcontext[0]
                $global:SchemaDN = $response.Entries[0].attributes.schemanamingcontext[0]
                $global:ConfigDN = $response.Entries[0].attributes.configurationnamingcontext[0]
                $global:strDomainDNName = $response.Entries[0].attributes.defaultnamingcontext[0]
            }

            $global:DirContext = Get-DirContext $global:strDC $global:CREDS
            $global:strDomainShortName = GetDomainShortName $global:strDomainDNName $global:ConfigDN
            $global:strRootDomainShortName = GetDomainShortName $global:ForestRootDomainDN $global:ConfigDN
        }



    }
    Process
    {

        if ($pscmdlet.ShouldProcess($global:strDomainDNName, "Remove Permissions:"))
        {
   
            if($Template) 
            {
                #Write-Host "***********************************************************" -ForegroundColor Red
                #Write-Host "****************** Running in Add  Mode ****************" -ForegroundColor Red
                #Write-Host "***********************************************************" -ForegroundColor Red
                #$a = Read-Host "Do you want to continue? Press Y[Yes] or N[NO]:"
                #If (!($a -eq "Y"))
                #{
	            #    break
                #}
                $bolReplaceDom = $false

                if (($OldNETBIOS) -and (!(($OldDomDN) -and ($DstDomain)))) 
                {
	            funHelp  
                }
                if (($OldDomDN) -and (!(($OldNETBIOS) -and ($DstDomain)))) 
                {
	            funHelp  
                }
                if (($DstDomain) -and (!(($OldNETBIOS) -and ($OldDomDN)))) 
                {
	            funHelp  
                }
                if (($OldDN) -and (!($NewDN)) )
                {
	            funHelp  
                } 
                if (($NewDN) -and (!($OldDN)) )
                {
	            funHelp  
                }             

                if (($DstDomain) -and ($OldNETBIOS) -and ($OldDomDN))
                {
                    $global:strTemplateDomainLongName = $DstDomain
                    $global:strTemplateDomainDNName = "DC=$($DstDomain.Replace(".",",DC="))"
        
                    
                    #Check if the domain from the tempalte differ from the current connected domain.
                    if(!($global:strDomainDNName -eq $global:strTemplateDomainDNName))
                    {
                        Write-host "`nTrying to connect to domain: $global:strTemplateDomainDNName" -ForegroundColor Yellow
                        #Check if connection to the template domain can be done.
                        If (!(CheckDNExist ($global:strTemplateDomainDNName)))
                        {    
                            Write-Host Domain $global:strTemplateDomainDNName can not be found! -ForegroundColor red
                            break
                        }
                        
                        $global:strTemplateDomainLongName = $global:strTemplateDomainDNName.Replace("DC=","")
                        $global:strTemplateDomainLongName = $global:strTemplateDomainLongName.Replace(",",".")
                
                        $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strTemplateDomainLongName )
                        $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
                        $global:strDC  = $($ojbDomain.FindDomainController()).name
                        $global:Forest = Get-Forest $global:strDC
                        $global:ForestRootDomainDN = Get-DomainDNfromFQDN $global:Forest.RootDomain
   
                        $global:strTemplateDomainShortName = GetDomainShortName $global:strTemplateDomainDNName $("CN=Configuration,"+$global:ForestRootDomainDN)
                    }
                    else
                    {
                        $global:strTemplateDomainShortName = $global:strDomainShortName
                    }
                    #Now the domain will be replaced in the temlate
                    $bolReplaceDom = $true   
                }
                $int = 0
                $TempString
                #$fs = [System.IO.File]::OpenText($Template) 
                $global:bolCSVLoaded = $false
                &{#Try
                    $global:bolCSVLoaded = $true
                    $global:csvHistACLs = import-Csv $Template -Encoding UTF8
                }
                Trap [SystemException]
                {
                    $strCSVErr = $_.Exception.Message
                    $global:bolCSVLoaded = $false
                    continue
                }   
                $index = 0
                while($index -le @($global:csvHistACLs).count -1) 
                {
                    $strOU = $global:csvHistACLs[$index].OU

                    $strTrustee = $global:csvHistACLs[$index].IdentityReference
                        
                    if ($bolReplaceDom -eq $false)
                    {
		                    
                        if (($strOU -match "cn=") -or ($strOU -match "ou="))
                        {
                            $global:strTemplateDomainDNName =  Get-DomainDN $strOU
                        }
                        else
                        {
                            $global:strTemplateDomainDNName = $strOU
                        }
                        #Check if the domain from the tempalte differ from the current connected domain.
                        if(!($global:strDomainDNName -eq $global:strTemplateDomainDNName))
                        {
                            Write-host "`nTrying to connect to domain: $global:strTemplateDomainDNName" -ForegroundColor Yellow
                            #Check if connection to the template domain can be done.
                            If (!(CheckDNExist ($global:strTemplateDomainDNName)))
                            {    
                                Write-Host Domain $global:strTemplateDomainDNName can not be found! -ForegroundColor red
                                break
                            }
                        
                            $global:strTemplateDomainLongName = $global:strTemplateDomainDNName.Replace("DC=","")
                            $global:strTemplateDomainLongName = $global:strTemplateDomainLongName.Replace(",",".")
                
                            $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strTemplateDomainLongName )
                            $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
                            $global:strDC  = $($ojbDomain.FindDomainController()).name
                            $global:Forest = Get-Forest $global:strDC
                            $global:ForestRootDomainDN = Get-DomainDNfromFQDN $global:Forest.RootDomain
   
                            $global:strTemplateDomainShortName = GetDomainShortName $global:strTemplateDomainDNName $("CN=Configuration,"+$global:ForestRootDomainDN)
                        }
                        else
                        {
                            $global:strTemplateDomainShortName = $global:strDomainShortName
                        }
                    }
                    else
                    {
                        $strOU = ($strOU.ToLower().replace($OldDomDN.ToLower(),$strTemplateDomainDNName))

                        if($strTrustee.Contains("\"))
                        {
                            $strTrustee = ($strTrustee.Split("\")[0].ToLower().replace($OldNETBIOS.ToLower(),$global:strTemplateDomainShortName)+"\"+$strTrustee.Split("\")[1])
                        }
                    }

                    if (($NewDN) -and ($OldDN) )
                    {
                        $strOU = ($strOU.ToLower().replace($OldDN.ToLower(),$NewDN))
                    }
					
                    $strRights = $global:csvHistACLs[$index].ActiveDirectoryRights				
                    $strInheritanceType = $global:csvHistACLs[$index].InheritanceType				
                    $strObjectTypeGUID =  $global:csvHistACLs[$index].ObjectType
                    if($strObjectTypeGUID -match "GUID:")
                    {
                        $strObjectTypeGUID = GetSchemaObjectGUID $strObjectTypeGUID.Split(":")[1]
                    }
                    $strInheritedObjectTypeGUID = $global:csvHistACLs[$index].InheritedObjectType
                    if($strInheritedObjectTypeGUID -match "GUID:")
                    {
                        $strInheritedObjectTypeGUID = GetSchemaObjectGUID $strInheritedObjectTypeGUID.Split(":")[1]
                    }
                    $strObjectFlags = $global:csvHistACLs[$index].ObjectFlags
                    $strAccessControlType = $global:csvHistACLs[$index].AccessControlType
                    $strIsInherited = $global:csvHistACLs[$index].IsInherited
                    $strInheritedFlags = $global:csvHistACLs[$index].InheritanceFlags
                    $strPropFlags = $global:csvHistACLs[$index].PropagationFlags
						

                    if($strAccessControlType -eq "Owner")
                    {
                        Write-Output "Skip line: Owner - Cannot remove owner!"
                    }
                    else
                    {
                        $Add = $true
                        #Check if the permission exist
						If(!(Check-Perm $strOU $strTrustee $strRights $strInheritanceType $strObjectTypeGUID $strInheritedObjectTypeGUID $strObjectFlags $strAccessControlType $strIsInherited $strInheritedFlags $strPropFlags))
						{
                            #Add Permissions on OU 			
                            Add-Perm $strOU $strTrustee $strRights $strInheritanceType $strObjectTypeGUID $strInheritedObjectTypeGUID $strObjectFlags $strAccessControlType $strIsInherited $strInheritedFlags $strPropFlags
						}
                    }

			
                    $index++	    
				}#End While
              }
            else 
            {
	            Write-host "No Template defined!" -ForegroundColor Red
            }
        } #End if ShouldProcess
       
    }#End Process
    End 
    {

    } #End of End
}