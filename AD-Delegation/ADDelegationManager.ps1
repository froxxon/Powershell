#region ModulesAndVariables - Load different modules etc
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);' # Part of the process to hide the Powershellwindow if it is not run through ISE
    Add-Type -name win -member $t -namespace native # Part of the process to hide the Powershellwindow if it is not run through ISE
    $Domain = $( Get-ADDomain ).DNSRoot # domain.domain.com
    $LogonServer = $env:LOGONSERVER -Replace "\\",""
    if ( $LogonServer -eq "" ) {
        $DC = Get-ADDomainController -Discover -Domain $Domain
    }
    else { $DC = "$LogonServer.$Domain" }
    $DomainDN = $( Get-ADDomain ).DistinguishedName # Get the DistinguishedName of the current domain in the format of 'DC=x,DC=x,DC=x'
    $UserPrefix = "T" # Sets the prefix (if needed) that will be used for the AD-delegation useraccounts so they differ from the standard accounts
    $UserSuffix = "adm" # Sets the suffix (if needed) that will be used for the AD-delegation useraccounts so they differ from the standard accounts
    $ServersRoot = "OU=Servers,$DomainDN"
    if ( $(Test-Path variable:global:psISE) -eq $False ) { [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0) } # This hides the Powershellwindow in the background if ISE isn't running
#endregion

#region AccessLevel - Verifies what role is being used and assigns rights to use the script based on that
    $AccessLevel = $Null # Sets AccessLevel to $Null, primarly for testingpurposes cause its only loaded once in a script outside of ISE
    if ( $($env:UserName).Substring(0,2) -eq "$($UserPrefix)0" ) { $AccessLevel = 0 } # Grants the role that has access to manage Tasks and T0-users for example the highest rights in the script
    if ( $AccessLevel -eq $Null ) {
        if ( $(Get-ADPrincipalGroupMembership $env:UserName).Name -contains "Role-T1-Infrastructure" -or $(Get-ADPrincipalGroupMembership $env:UserName).Name -contains "Role-T1-Operations" ) { $AccessLevel = 1 } # Grants the role(s) that has access to manage T1- and T2-Users for example that required rights in the script, which is to create T1- and T2-users.
        if ( $AccessLevel -eq $Null ) { # If the current account isn't a member of any of the above groups, then inform about this and exit the script
            $MessageBody = "You don't have permission to start this application."
            $MessageTitle = "$($Form.Text) - Access denied"
            [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Error")
            exit
        }
    }
#endregion

#region ADGathering # collect all the roles initally for faster switching in cmbRoles, Group policies etc.
    if ( $AccessLevel -eq 0 ) { $T0Roles = $(Get-ADGroup -filter * -SearchBase "OU=T0-Roles,OU=Tier 0,OU=Admin,$DomainDN" | Sort Name ).Name } # Only load the T0-Roles if the current account has this access and if so list those by Name and export only the Name-attribute
    $T1Roles = $(Get-ADGroup -Server $DC -filter * -SearchBase "OU=T1-Roles,OU=Tier 1,OU=Admin,$DomainDN" | Sort Name ).Name # List those roles by Name and export only the Name-attribute
    $T2Roles = $(Get-ADGroup -Server $DC -filter * -SearchBase "OU=T2-Roles,OU=Tier 2,OU=Admin,$DomainDN" | Sort Name ).Name # List those roles by Name and export only the Name-attribute
    $Tiers = $($(Get-ADOrganizationalUnit -Server $DC -filter * -SearchBase "OU=Admin,$DomainDN" -SearchScope OneLevel).Name).Replace("Tier ","")
    #$AllTaskGroups = $(Get-ADGroup -Server $DC -filter ('Name -like "Task-Server-Local*"') -SearchBase "OU=T0-Tasks,OU=Tier 0,OU=Admin,$DomainDN").Name
    $AllTaskGPOs = $(Get-GPO -Server $DC -All | Where {$_.displayName -like "Task-Server-Local*"} ).DisplayName
    $AllRoles = $(Get-ADGroup -Server $DC -filter * -SearchBase "OU=Admin,$DomainDN" | Where { $_.name -like "Role-T*" } | Sort Name ).Name # List those roles by Name and export only the Name-attribute
    $AllTaskGroups = $(Get-ADGroup -Server $DC -filter * -SearchBase "OU=T0-Tasks,OU=Tier 0,OU=Admin,$DomainDN" | Where { $_.name -like "Task-*" } | Sort Name ).Name
    [string]$global:StrOriginalTasks = ""
    $global:OriginalTasks = @()
    $global:RemoveTasks = New-Object System.Collections.ArrayList
#endregion

#region Functions - A region to gather all functions in one place
    Function VerifyComplexPassword ($Password) # Verify that atleast three out of four conditions for a complex password is reached
    {
        if ($Password –cmatch "[^a-zA-Z0-9]") { $PWContainSpecial = $True } else { $PWContainSpecial = $False } # Checks if any (special) characters exists in the string, that is other (^) characters than a-z, A-Z or 0-9
        if ($Password –cmatch "[a-z]") { $PWContainLower = $True } else { $PWContainLower = $False } # Checks that the password contains atleast one lowercase alpabethical letter
        if ($Password –cmatch "[A-Z]") { $PWContainUpper = $True } else { $PWContainUpper = $False } # Checks that the password contains atleast one uppercase alpabethical letter
        if ($Password –cmatch "[0-9]") { $PWContainDigit = $True } else { $PWContainDigit = $False } # Checks that the password contains atleast one digit
        if ( $PWContainSpecial + $PWContainLower + $PWContainUpper + $PWContainDigit -ge 3 ) { # Verifies how many of the above conditions was reached and it returns $True if its greater or equal to three
            Return $True
        }
        else {
            Return $False # Returns $False if atleast three out of four conditions wasn't reached
        }
    }

    Function CheckIfUserExists($Tier,$Username) # Checks if useraccount exists in Active Directory or not
    {
        if ( $(Get-ADUser -LDAPFilter "(sAMAccountName=$($UserPrefix)$($Tier)$($Username)$($UserSuffix)") -eq $Null ) { Return $False } # Check if the user exists in Active Directory by looking for samAccountName and if no user is found it returns $False
        else { Return $True } # Returns $True if the user already exists in Active Directory
    }

    Function CheckNewUserFields($Username,$Givenname,$Surname,$Password) # Verifies the input on the New User tab when changed
    {
        if ( $TabControl.SelectedTab.Name -eq "tabNewUser" ) { # Checks that the tab New User is selected
            if ( $Username.Length -eq 5 -and $Givenname.Length -ge 1 -and $Surname.Length -ge 1 -and $Password.Length -ge 8 ) { # Checks the different inputvalues in the fields and then enables or disables the Create Users button based on the result
                $btnCreateUser.Enabled = $True
            }
            else {
                $btnCreateUser.Enabled = $False
            }
        }

        if ( $TabControl.SelectedTab.Name -eq "tabNewUsers" ) { # Checks that the tab New Users (multiple) is selected
            if ( $txtNewUsersPassword.Text.Length -ge 8 -and $txtNewUsersRetypePassword.Text.Length -ge 8 ) { # Checks that the passwordfields contains atleast eight characters each and then enables or disables the Create Users button based on the result
                $btnCreateUsers.Enabled = $True
            }
            else {
                $btnCreateUsers.Enabled = $False
            }
        }

    }

    Function Create-NewUser($Username,$Givenname,$Surname,$Password,$Tier,$Role) # Creates new user(s)
    {
        $OtherAttributes = @{'Comment'=$Username}
        $Username = "$UserPrefix$Tier$($Username.ToLower())$UserSuffix" # Sets the difference from the new users username to the standard username for the same user
        if ($Tier -eq "2") { $Description = "Klientadministratör" } else { $Description = "Serveradministratör" } # Sets $Description to one thing if its a Tier 2-account being created and another thing if it's a Tier 0 or Tier 1
        $Password = ConvertTo-SecureString -AsPlainText $Password -force # Converts the password to securestring to be able to use it in New-ADUser
        $OUPath = "OU=T$Tier-Accounts,OU=Tier $Tier,OU=Admin,$DomainDN" # Which OU to create the account in
        $UserPrincipalName = "$Username@$Domain" # Sets the UPN of the user being created
        $DisplayName = "$($GivenName) $($Surname) $($UserPrefix)$Tier" # Sets the DisplayName to (for example) 'Testing Testingson T1'

        Try {
            New-ADUser $Username -Path $OUPath -GivenName $GivenName -Surname $Surname -DisplayName $DisplayName -Description $Description -UserPrincipalName $UserPrincipalName -Enabled $True -OtherAttributes $OtherAttributes -AccountPassword $Password -Server $DC # Creates the new user in Active Directory
            if ( $Role -ne $Null ) { Add-ADGroupMember $Role $Username -Server $DC } # If $Role contains any role then add the created useraccount to this
            Return $True # If the creation of the useraccount works successfully then return $True
        }
        Catch { Return $False } # If something generates an error during above process then return $False
    }

    Function SetCheckBoxStatus ( $SelectedNode ) # Sets the checkboxes on the ServerOUs-tab based what OU is choosen in the Treeviwe
    {
        if ( $AllTaskGPOs -contains "Task-Server-LocalAdmin-$SelectedNode" ) { $chkAdminGPO.Checked = $True } else { $chkAdminGPO.Checked = $False }
        if ( $AllTaskGPOs -contains "Task-Server-LocalUser-$SelectedNode" ) { $chkUserGPO.Checked = $True } else { $chkUserGPO.Checked = $False }
        if ( $AllTaskGroups -contains "Task-Server-LocalAdmin-$SelectedNode" ) { $chkAdminTask.Checked = $True } else { $chkAdminTask.Checked = $False }
        if ( $AllTaskGroups -contains "Task-Server-LocalUser-$SelectedNode" ) { $chkUserTask.Checked = $True } else { $chkUserTask.Checked = $False }
        if ( $chkAdminGPO.Checked -eq $True ) { $chkAdminGPO.Enabled = $False } else { $chkAdminGPO.Enabled = $True }
        if ( $chkUserGPO.Checked -eq $True ) { $chkUserGPO.Enabled = $False } else { $chkUserGPO.Enabled = $True }
        if ( $chkAdminTask.Checked -eq $True ) { $chkAdminTask.Enabled = $False } else { $chkAdminTask.Enabled = $True }
        if ( $chkUserTask.Checked -eq $True ) { $chkUserTask.Enabled = $False } else { $chkUserTask.Enabled = $True }
        $lblSelectedOU.Text = $SelectedNode
    }

    Function CreateGPO ($OUName,$Type,$OU) # Creates and links a LocalRights GPO
    {

        $GPO = "Task-Server-Local$Type-$OUName"
        
        Try {
            $ErrorState = " - Creating the GPO: $GPO"
            New-GPO -Server $DC -Name $GPO | out-null # Creates new Group policy

            $ErrorState = " - Changing GPOStatus to ""UserSettingsDisabled"""
            (get-gpo $GPO -server $DC).gpostatus = "UserSettingsDisabled" # Sets the new policy to User Settings Disabled

            $ErrorState = " - Gets the GUID for the created GPO"
            $GPOGuid = "{$($(Get-GPO $GPO -Server $DC).id)}" # Gathers the GUID of the Group policy

            $ErrorState = " - Gets the SID for the group being added to Restricted groups"
            $SecGroupSid = (Get-ADGroup $GPO -Server $DC).SID.Value # Gather the SID of the restricted group being added

            # Creates the path to and the file GptTmpl.inf to be able to set the Restricted group
            $ErrorState = " - Creating the path to and the GptTmpl.inf file"
            if (!(Test-Path "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft")) { New-Item "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\" -type Directory | out-null }
            if (!(Test-Path "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\Windows NT")) { New-Item "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\Windows NT\" -type Directory | out-null }
            if (!(Test-Path "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\Windows NT\SecEdit")) { New-Item "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\Windows NT\SecEdit" -type Directory | out-null }
            $infFile="\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\Machine\Microsoft\Windows NT\SecEdit\GptTmpl.inf"
            New-Item $infFile -ItemType File | out-null

            # Adding information to the GptTmp.inf file
            $ErrorState = " - Adding info to GptTmp.inf"
            $MemberOf = "*$($SecGroupSid)__Memberof = *S-1-5-32-544"
            if ( $GPO -like "*LocalUser*" ) {
                $MemberOf = "*$($SecGroupSid)__Memberof = *S-1-5-32-555"
            }
            $Members = "*$($SecGroupSid)__Members ="
            $fileContents = "[Unicode]","Unicode=yes","[Version]",'signature="$CHICAGO$"',"Revision=1","[Group Membership]",$MemberOf,$Members
            Set-Content $infFile $fileContents

            # Increasing Versionnumber in GPT.INI
            $ErrorState = " - Increasing versionnumber in GPT.INI"
            $GPTINI= "\\$DC\SYSVOL\$Domain\Policies\$GPOGuid\GPT.INI"
            $GPTINIContent = Get-Content $GPTINI
            $ErrorState = " - Increasing versionnumber in GPT.INI, before ForEach"
            foreach ( $GPTINIRow in $GPTINIContent ) {
                if ( $GPTINIRow -like "Version=*" ) {
                    $TempNumber = $GPTINIRow.Substring(8,1)
                    [int]$VersionNumber = $TempNumber
                    $VersionNumber++
                    break
                }
            }
            $Version = "Version=$VersionNumber"
            $DisplayName = "displayName=$GPO"
            $fileContents="[General]",$Version,$DisplayName
            Set-Content $GPTINI $fileContents
    
            # Sets the gPCMachineExtensionNames to include Restricted groups
            $ErrorState = " - Changes the ""GPCMachineExtensionNames""-attribute for the GPO"
            Set-ADObject -Server $DC "CN=$GPOGuid,CN=Policies,CN=System,$DomainDN" -Replace @{gPCMachineExtensionNames="[{827D319E-6EAC-11D2-A4EA-00C04F79F83A}{803E14A0-B4FB-11D0-A0D0-00A0C90F574B}]"}

            # Sets versionNumber to same as GPT.INI
            $ErrorState = " - Sets the versionnumber in GPT.INI"
            Set-ADObject -Server $DC "CN=$GPOGuid,CN=Policies,CN=System,$DomainDN" -Replace @{versionNumber=$VersionNumber}

            # Links the GPO
            $ErrorState = " - Links the GPO to the Organizational Unit"
            New-GPLink -Server $DC -Name $GPO -Target $OU | out-null

            $ErrorState = " - GPO is created and linked successfully"
            Return $ErrorState
        }
        Catch {
            Return $ErrorState
        }
    }
#endregion

#region Form - The baseform of the entire GUI
    $Form = New-Object system.Windows.Forms.Form 
    $Form.Text = " AD Delegation Manager"
    $Form.BackColor = "#ffffff"
    $Form.BackgroundImageLayout = "None"
    $Form.FormBorderStyle = "FixedDialog"
    $Form.MaximizeBox = $False
    $Form.MinimizeBox = $False
    $Form.Width = 405
    $Form.Height = 280
    $Form.StartPosition = "CenterScreen"
#endregion

#region TabControl - The TabControl to hold the tabs showing on Form
    $TabControl = New-Object system.Windows.Forms.TabControl

    $tabNewUser = New-Object 'System.Windows.Forms.TabPage'
    $tabNewUser.Size = '390, 215'
    $tabNewUser.TabIndex = 0
    $tabNewUser.Name = "tabNewUser"
    $tabNewUser.Text = 'Create single user'
    $tabNewUser.UseVisualStyleBackColor = $True

    $tabNewUsers = New-Object 'System.Windows.Forms.TabPage'
    $tabNewUsers.Size = '390, 215'
    $tabNewUsers.TabIndex = 1
    $tabNewUsers.Name = "tabNewUsers"
    $tabNewUsers.Text = 'Create multiple users'
    $tabNewUsers.UseVisualStyleBackColor = $True

    $tabRoles = New-Object 'System.Windows.Forms.TabPage'
    $tabRoles.Size = '390, 215'
    $tabRoles.TabIndex = 2
    $tabRoles.Name = "tabRoles"
    $tabRoles.Text = 'Roles'
    $tabRoles.UseVisualStyleBackColor = $True

    $tabServerOUs = New-Object 'System.Windows.Forms.TabPage'
    $tabServerOUs.Size = '390, 215'
    $tabServerOUs.TabIndex = 3
    $tabServerOUs.Name = "tabServerOUs"
    $tabServerOUs.Text = 'Server OU:s'
    $tabServerOUs.UseVisualStyleBackColor = $True

    $TabControl.Controls.Add($tabNewUser)
    $TabControl.Controls.Add($tabNewUsers)
    $TabControl.Controls.Add($tabRoles)
    $TabControl.Controls.Add($tabServerOUs)
    $TabControl.Width = $Form.Width
    $TabControl.Height = $Form.Height
    $Form.controls.Add($TabControl)
#endregion

#region Tab NewUser - Creates all the elements and conditions of the tab New User
    $lblUserName = New-Object system.windows.Forms.Label
    $lblUserName.Width = 150
    $lblUserName.location = new-object system.drawing.point(25,10)
    $lblUserName.Text = "Username:"
    $tabNewUser.controls.Add($lblUserName)
    $txtUserName = New-Object system.windows.Forms.TextBox 
    $txtUserName.Width = 150
    $txtUserName.location = new-object system.drawing.point(200,10)
    $txtUserName.MaxLength = 5 # This will contain the standard username, which in our organization is of five characters in length
    $txtUserNameChange = { $this.Text = $this.Text -replace '[^a-zA-Z]','' ; CheckNewUserFields -Username $txtUsername.Text -Givenname $txtFirstName.Text -Surname $txtSurname.Text -Password $txtPassword.Text } # Only allows alphanumeric characters to be entered into this field, then checks if its possible to enable the Create User button
    $txtUserName.Add_TextChanged($txtUserNameChange)
    $tabNewUser.controls.Add($txtUserName)

    $lblFirstName= New-Object system.windows.Forms.Label
    $lblFirstName.Width = 150
    $lblFirstName.location = new-object system.drawing.point(25,35)
    $lblFirstName.Text = "Firstname:"
    $tabNewUser.controls.Add($lblFirstName)
    $txtFirstName= New-Object system.windows.Forms.TextBox 
    $txtFirstName.Width = 150
    $txtFirstName.location = new-object system.drawing.point(200,35)
    $txtFirstNameChange = { $this.Text = $this.Text -replace '[^a-zA-Zéáåäö -]','' ; CheckNewUserFields -Username $txtUsername.Text -Givenname $txtFirstName.Text -Surname $txtSurname.Text -Password $txtPassword.Text } # Only allows alphanumeric characters (and also the characters 'å','ä','ö','é','á','-' and ' ') to be entered into this field, then checks if its possible to enable the Create User button
    $txtFirstName.Add_TextChanged($txtFirstNameChange)
    $tabNewUser.controls.Add($txtFirstName)

    $lblSurName= New-Object system.windows.Forms.Label
    $lblSurName.Width = 150
    $lblSurName.location = new-object system.drawing.point(25,60)
    $lblSurName.Text = "Surname:"
    $tabNewUser.controls.Add($lblSurName)
    $txtSurName= New-Object system.windows.Forms.TextBox 
    $txtSurName.Width = 150
    $txtSurName.location = new-object system.drawing.point(200,60)
    $txtSurNameChange = { $this.Text = $this.Text -replace '[^a-zA-Zéáåäö -]','' ; CheckNewUserFields -Username $txtUsername.Text -Givenname $txtFirstName.Text -Surname $txtSurname.Text -Password $txtPassword.Text } # Only allows alphanumeric characters (and also the characters 'å','ä','ö','é','á','-' and ' ') to be entered into this field, then checks if its possible to enable the Create User button
    $txtSurName.Add_TextChanged($txtSurNameChange)
    $tabNewUser.controls.Add($txtSurName)

    $lblPassword= New-Object system.windows.Forms.Label
    $lblPassword.Width = 150
    $lblPassword.location = new-object system.drawing.point(25,85)
    $lblPassword.Text = "Password:"
    $tabNewUser.controls.Add($lblPassword)
    $txtPassword = New-Object system.windows.Forms.TextBox 
    $txtPassword.PasswordChar = '●'
    $txtPassword.Width = 150
    $txtPasswordChange = { CheckNewUserFields -Username $txtUsername.Text -Givenname $txtFirstName.Text -Surname $txtSurname.Text -Password $txtPassword.Text }  # On every change this checks if it's possible to enable the Create User button
    $txtPassword.Add_TextChanged($txtPasswordChange)
    $txtPassword.location = new-object system.drawing.point(200,85)
    $tabNewUser.controls.Add($txtPassword)

    $lblRetypePassword= New-Object system.windows.Forms.Label
    $lblRetypePassword.Width = 150
    $lblRetypePassword.location = new-object system.drawing.point(25,110)
    $lblRetypePassword.Text = "Re-type password:"
    $tabNewUser.controls.Add($lblRetypePassword)
    $txtRetypePassword = New-Object system.windows.Forms.TextBox 
    $txtRetypePassword.PasswordChar = '●'
    $txtRetypePassword.Width = 150
    $txtRetypePasswordChange = { CheckNewUserFields -Username $txtUsername.Text -Givenname $txtFirstName.Text -Surname $txtSurname.Text -Password $txtRetypePassword.Text } # On every change this checks if it's possible to enable the Create User button
    $txtRetypePassword.Add_TextChanged($txtRetypePasswordChange)
    $txtRetypePassword.location = new-object system.drawing.point(200,110)
    $tabNewUser.controls.Add($txtRetypePassword)

    $lblLevel= New-Object system.windows.Forms.Label
    $lblLevel.Width = 150
    $lblLevel.location = new-object system.drawing.point(25,135)
    $lblLevel.Text = "Tier:"
    $tabNewUser.controls.Add($lblLevel)
    $cmbTier = New-Object system.windows.Forms.ComboBox 
    $cmbTier.DropDownStyle = "DropDownList"
    $cmbTier.Width = 150
    $cmbTier.location = new-object system.drawing.point(200,135)
    foreach ( $Tier in $Tiers ) {
        if ( $Tier -eq 0 ) {
            if ( $AccessLevel -eq 0 ) { $cmbTier.Items.Add($Tier) | out-null }
        }
        else { $cmbTier.Items.Add($Tier) | out-null }
    }
    $cmbTier.SelectedIndex = 0
    $cmbTierChange = {
        $cmbRoles.Items.Clear() # Clears the Roles Combobox when the Tier Combobox change
        $cmbRoles.Items.Add("") # Adds an empty line for the possibility to set this to nothing once somethingelse has been selected
        if ( $AccessLevel -eq 0 ) { if ( $cmbTier.SelectedItem -eq "0" ) { foreach ( $Role in $T0Roles ) { $cmbRoles.Items.Add($Role) | out-null } } } # Adds the roles from this tier if the current user has appropiate rights when this value is selected
        if ( $cmbTier.SelectedItem -eq "1" ) { foreach ( $Role in $T1Roles ) { $cmbRoles.Items.Add($Role) | out-null } } # Adds the roles from this tier when this value is selected
        if ( $cmbTier.SelectedItem -eq "2" ) { foreach ( $Role in $T2Roles ) { $cmbRoles.Items.Add($Role) | out-null } } # Adds the roles from this tier when this value is selected
    }
    $cmbTier.Add_SelectedIndexChanged($cmbTierChange)
    $tabNewUser.controls.Add($cmbTier)

    $lblRoles= New-Object system.windows.Forms.Label
    $lblRoles.Width = 150
    $lblRoles.location = new-object system.drawing.point(25,160)
    $lblRoles.Text = "Add to role:"
    $tabNewUser.controls.Add($lblRoles)
    $cmbRoles = New-Object system.windows.Forms.ComboBox 
    $cmbRoles.DropDownStyle = "DropDownList"
    $cmbRoles.Width = 150
    $cmbRoles.location = new-object system.drawing.point(200,160)
    
    $cmbRoles.Items.Clear() # Clears the Roles Combobox when the Tier Combobox change
    $cmbRoles.Items.Add("") | Out-null # Adds an empty line for the possibility to set this to nothing once somethingelse has been selected
    if ( $AccessLevel -eq 0 ) { if ( $cmbTier.SelectedItem -eq "0" ) { foreach ( $Role in $T0Roles ) { $cmbRoles.Items.Add($Role) | out-null } } } # Adds the roles from this tier if the current user has appropiate rights when this value is selected
    if ( $cmbTier.SelectedItem -eq "1" ) { foreach ( $Role in $T1Roles ) { $cmbRoles.Items.Add($Role) | out-null } } # Adds the roles from this tier when this value is selected
    if ( $cmbTier.SelectedItem -eq "2" ) { foreach ( $Role in $T2Roles ) { $cmbRoles.Items.Add($Role) | out-null } } # Adds the roles from this tier when this value is selected
    
    $cmbRoles.Text = $cmbRoles.Items[0]
    $tabNewUser.controls.Add($cmbRoles)

    $btnCreateUser = New-Object system.windows.Forms.Button
    $btnCreateUser.Width = 150
    $btnCreateUser.location = new-object system.drawing.point(200,185)
    $btnCreateUser.Text = "Create user"
    $btnCreateUser.Enabled = $False
    $btnCreateUser.Add_Click{
        if ( $txtPassword.Text -eq $txtRetypePassword.Text ) { # Check if passwordfields match
            if ( $(VerifyComplexPassword -Password $txtPassword.Text) -eq $True ) {  # Check if the entered password fullfils the requirements of a complex password
                if ( $(CheckIfUserExists -Username $txtuserName.Text -Tier $cmbTier.SelectedItem) -eq $False ) { # Check if the user already exists 
                    $MessageBody = "The following user is being created:`n`n$($UserPrefix)$($cmbTier.SelectedItem)$($txtuserName.Text)$($UserSuffix)`n`nBased on the following values:`n`nUsername: $($txtUsername.Text)`nGivenname: $($txtFirstname.Text)`nSurname: $($txtSurname.Text)`n`nAre you sure you want to create this user?"
                    $MessageTitle = "$($Form.Text) - Create user"
                    $Choice = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"YesNo","Information")
                    if ( $Choice -eq "Yes" ) { # Tries to create the new user if every check has been successful
                        $CreateUser = Create-NewUser -Username $txtUsername.Text -Givenname $txtFirstName.Text -Surname $txtSurName.Text -Password $txtPassword.Text -Tier $cmbTier.SelectedItem -Role $cmbRoles.SelectedItem
                        if ( $CreateUser -eq $True ) {
                            $MessageBody = "Successfully created the user: $Username"
                            $MessageTitle = "$($Form.Text) - Create user"
                            [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Information")
                        }
                        else {
                            $MessageBody = "An error occured when trying to create the user: $Username"
                            $MessageTitle = "$($Form.Text) - Create user"
                            [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Error")                
                        }
                    }
                }
                else {
                    $MessageBody = "The user $($UserPrefix)$($cmbTier.SelectedItem)$($txtuserName.Text)$($UserSuffix) already exists!"
                    $MessageTitle = "$($Form.Text) - Create user"
                    [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Error")
                }
            }
            else {
                $MessageBody = "The password doesn't meet atleast three out of four of the complexity requirements listed below:`n`n- Atleast one lowercase aphanumeric character (a-z)`n- Atleast one uppercasecase aphanumeric character (A-Z)`n- Atleast one digit (0-9)`n- Atleast one specialcharacter (examples are @#$%^&*-_+)"
                $MessageTitle = "$($Form.Text) - Invalid password"
                [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Warning")
            }
        }
        else {
            $MessageBody = "Passwords must match, please re-type them"
            $MessageTitle = "$($Form.Text) - Missmatching passwords"
            [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Error")
        }
    }
    $tabNewUser.controls.Add($btnCreateUser)
#endregion

#region Tab NewUsers
    $lblNewUsers= New-Object system.windows.Forms.Label
    $lblNewUsers.Width = 325
    $lblNewUsers.Height = 40
    $lblNewUsers.location = new-object system.drawing.point(25,10)
    $lblNewUsers.Text = "Create multiple users at the same time by providing information in a comma-separated format like for example:`nberfe,Fredrik,Bergman,1,Role-T1-Operations"
    $tabNewUsers.controls.Add($lblNewUsers)
    $txtNewUsers = New-Object System.Windows.Forms.TextBox
    $txtNewUsers.Scrollbars = "Vertical"
    $txtNewUsers.Width = 325
    $txtNewUsers.Multiline = $True
    $txtNewUsers.Height = 75
    $txtNewUsers.location = new-object system.drawing.point(25,55)
    $tabNewUsers.controls.Add($txtNewUsers)

    $lblNewUsersPassword= New-Object system.windows.Forms.Label
    $lblNewUsersPassword.Width = 150
    $lblNewUsersPassword.location = new-object system.drawing.point(25,135)
    $lblNewUsersPassword.Text = "Password:"
    $tabNewUsers.controls.Add($lblNewUsersPassword)
    $txtNewUsersPassword = New-Object system.windows.Forms.TextBox 
    $txtNewUsersPassword.PasswordChar = '●'
    $txtNewUsersPassword.Width = 150
    $txtNewUsersPasswordChange = { CheckNewUserFields }
    $txtNewUsersPassword.Add_TextChanged($txtNewUsersPasswordChange)
    $txtNewUsersPassword.location = new-object system.drawing.point(200,135)
    $tabNewUsers.controls.Add($txtNewUsersPassword)

    $lblNewUsersRetypePassword= New-Object system.windows.Forms.Label
    $lblNewUsersRetypePassword.Width = 150
    $lblNewUsersRetypePassword.location = new-object system.drawing.point(25,160)
    $lblNewUsersRetypePassword.Text = "Re-type password:"
    $tabNewUsers.controls.Add($lblNewUsersRetypePassword)
    $txtNewUsersRetypePassword = New-Object system.windows.Forms.TextBox 
    $txtNewUsersRetypePassword.PasswordChar = '●'
    $txtNewUsersRetypePassword.Width = 150
    $txtNewUsersRetypePasswordChange = { CheckNewUserFields }
    $txtNewUsersRetypePassword.Add_TextChanged($txtNewUsersRetypePasswordChange)
    $txtNewUsersRetypePassword.location = new-object system.drawing.point(200,160)
    $tabNewUsers.controls.Add($txtNewUsersRetypePassword)
    
    $btnCreateUsers = New-Object system.windows.Forms.Button
    $btnCreateUsers.Width = 150
    $btnCreateUsers.location = new-object system.drawing.point(200,185)
    $btnCreateUsers.Enabled = $False
    $btnCreateUsers.Text = "Create users"
    $btnCreateUsers.Add_Click{
        if ( $txtNewUsersPassword.Text -eq $txtNewUsersRetypePassword.Text ) {
            if ( $(VerifyComplexPassword -Password $txtNewUsersPassword.Text) -eq $True ) { 
                $NewUsers = $txtNewUsers.Text.Split("`n") | % {$_.trim()}
                $Check1 = $False # Validates some input properties for Username, Givenname, Surname and Tier
                $Check2 = $False # Validates if the role exists or not
                $Check3 = $False # Validates that the role is actually an AD delegation role
                $Check4 = $False # Validates if useraccount exists or not
                $Check5 = $False # Validates a minimum of 14 characters in the password for T0-account
                $Check6 = $False # Validates if the user has the AccessLevel to create T0-account
                $Createdusers = @() # Creates empty array to add successfully created users to
                $FailedUsers = @() # Creates empty array to add unsuccessfully created users to
                foreach ( $NewUser in $NewUsers ) {
                    $NewUserProps = $NewUser | ConvertFrom-Csv -Header userName,Firstname,Surname,Tier,Role
                    if ( $NewUserProps.Username -like "?????" -and $NewUserProps.Firstname.Length -ge 1 -and $NewUserProps.Surname.Length -ge 1 -and $NewUserProps.Tier.Length -eq 1 -and $NewUserProps.Tier -match "[0-2]" ) { $Check1 = $True } else { $Check1 = $False }
                    if ( $NewUserProps.Role -ne $Null ) { 
                        if ( $(Get-ADGroup -LDAPFilter "(sAMAccountName=$($NewUserProps.Role))") -ne $Null ) { $Check2 = $True } else { $Check2 = $False }
                        if ( $($NewUserProps.Role) -like "Role-T$($NewUserProps.Tier)*" -eq $True ) { $Check3 = $True } else { $Check3 = $False }
                    }
                    else {
                        $Check2 = $True
                        $Check3 = $True
                    }
                    if ( $(Get-ADUser -LDAPFilter "(sAMAccountName=$UserPrefix$($NewUserProps.Tier)$($NewUserProps.Username)$UserSuffix)") -eq $Null ) { $Check4 = $True } else { $Check4 = $False }
                    if ( $NewUserProps.Tier -eq 0 -and $txtNewUsersPassword.Text.Length -lt 14 ) { $Check5 = $False } else { $Check5 = $True }
                    if ( $NewUserProps.Tier -eq 0 ) {
                        if ( $AccessLevel -eq 0 ) { $Check6 = $True } #else { $Check6 = $False }
                    }
                    else { $Check6 = $True }
                    if ( $Check1 -eq $True -and $Check2 -eq $True -and $Check3 -eq $True -and $Check4 -eq $True -and $Check5 -eq $True -and $Check6 -eq $True ) {
                        $CreateUser = Create-NewUser -Username $NewUserProps.userName -Givenname $NewUserProps.Firstname -Surname $NewUserProps.Surname -Password $txtNewUsersPassword.Text -Tier $NewUserProps.Tier -Role $NewUserProps.Role
                        if ( $CreateUser -eq $True ) {
                            $CreatedUsers += "$UserPrefix$($NewUserProps.Tier)$($NewUserProps.Username)$UserSuffix`n"
                        }
                        else {
                            $FailedUsers += "$UserPrefix$($NewUserProps.Tier)$($NewUserProps.Username)$UserSuffix - Error during creation, check manually in ADUC`n"
                        }
                    }
                    else {
                        if ( $Check1 -eq $False ) { $FailedUsers += "$UserPrefix$($NewUserProps.Tier)$($NewUserProps.Username)$UserSuffix - Check inputvariables`n" }
                        if ( $Check2 -eq $False ) { $FailedUsers += "$UserPrefix$($NewUserProps.Tier)$($NewUserProps.Username)$UserSuffix - Role doesn't exists`n" }
                        if ( $Check3 -eq $False ) { $FailedUsers += "$UserPrefix$($NewUserProps.Tier)$($NewUserProps.Username)$UserSuffix - Tier and Role-number not matching`n" }
                        if ( $Check4 -eq $False ) { $FailedUsers += "$UserPrefix$($NewUserProps.Tier)$($NewUserProps.Username)$UserSuffix - User already exist`n" }
                        if ( $Check5 -eq $False ) { $FailedUsers += "$UserPrefix$($NewUserProps.Tier)$($NewUserProps.Username)$UserSuffix - The minimum passwordlength is 14 characters for Tier 0-accounts`n" }
                        if ( $Check6 -eq $False ) { $FailedUsers += "$UserPrefix$($NewUserProps.Tier)$($NewUserProps.Username)$UserSuffix - Access denied to create Tier 0-accounts`n" }
                    }
                }
                if ( $FailedUsers.Count -eq 0 -and $Createdusers.Count -gt 0 ) {
                    $MessageBody = "Created the users listed below successfully:`n`n$CreatedUsers"
                    $MessageTitle = "$($Form.Text) - Create Users"
                    [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Information")
                }
                if ( $FailedUsers.Count -gt 0 -and $Createdusers.Count -gt 0 ) {
                    $MessageBody = "Created the user(s) listed below successfully:`n`n$CreatedUsers`nFailed to create the user(s) listed below`n(check input parameters):`n`n$FailedUsers"
                    $MessageTitle = "$($Form.Text) - Create Users"
                    [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Warning")
                }
                if ( $FailedUsers.Count -gt 0 -and $Createdusers.Count -eq 0 ) {
                    $MessageBody = "Failed to create the users listed below`n(check input parameters):`n`n$FailedUsers"
                    $MessageTitle = "$($Form.Text) - Create Users"
                    [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Error")
                }
            }
            else {
                $MessageBody = "The password doesn't meet atleast three out of four of the complexity requirements listed below:`n`n- Atleast one lowercase aphanumeric character (a-z)`n- Atleast one uppercasecase aphanumeric character (A-Z)`n- Atleast one digit (0-9)`n- Atleast one specialcharacter (examples are @#$%^&*-_+)"
                $MessageTitle = "$($Form.Text) - Invalid password"
                [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Warning")
            }
        }
        else {
            $MessageBody = "Passwords must match, please re-type them"
            $MessageTitle = "$($Form.Text) - Missmatching passwords"
            [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Error")
        }
    }
    $tabNewUsers.controls.Add($btnCreateUsers)
#endregion

#region Tab Roles

    $lblRole = New-Object system.windows.Forms.Label
    $lblRole.Width = 150
    $lblRole.location = new-object system.drawing.point(25,10)
    $lblRole.Text = "Roles:"
    $tabRoles.controls.Add($lblRole)

    $btnNewRole = New-Object system.windows.Forms.Button
    $btnNewRole.Width = 23
    $btnNewRole.Height = 23
    $btnNewRole.location = new-object system.drawing.point(330,9)
    $btnNewRole.Text = "+"
    if ( $AccessLevel -ne 0 ) { $btnNewRole.Enabled = $False }
    $btnNewRole.Add_Click{
        $lstAvailableTasks.Visible = $False
        $lstAssignedTasks.Visible = $False
        $btnAddTask.Visible = $False
        $btnRemoveTask.Visible = $False
        $lblRole.Visible = $False
        $cmbRole.Visible = $False
        $btnApplyTasks.Visible = $False
        $lblAssignedTasks.Visible = $False
        $lblAssignedCount.Visible = $False
        $lblAvailableTasks.Visible = $False
        $lblAvailableCount.Visible = $False
        $btnNewRole.Visible = $False
        $lblNewRole.Visible = $True
        $lblNewRoleTier.Visible = $True
        $cmbNewRoleTier.Visible = $True
        $lblNewRoleName.Visible = $True
        $txtNewRoleName.Visible = $True
        $btnNewRoleCancel.Visible = $True
        $btnCreateNewRole.Visible = $True
    }
    $tabRoles.controls.Add($btnNewRole)

    $lblNewRole = New-Object system.windows.Forms.Label
    $lblNewRole.Width = 325
    $lblNewRole.Height = 40
    $lblNewRole.location = new-object system.drawing.point(25,10)
    $lblNewRole.Text = "Create a new role by choosing a Tier from the combobox below and then enter a name that should be used for the new role, the generated result will look like: ""Role-T<Tier>-<Name>""."
    $lblNewRole.Visible = $False
    $tabRoles.controls.Add($lblNewRole)

    $lblNewRoleName= New-Object system.windows.Forms.Label
    $lblNewRoleName.Width = 150
    $lblNewRoleName.location = new-object system.drawing.point(25,85)
    $lblNewRoleName.Text = "Name:"
    $lblNewRoleName.Visible = $False
    $tabRoles.controls.Add($lblNewRoleName)
    $txtNewRoleName = New-Object system.windows.Forms.TextBox
    $txtNewRoleName.Width = 150
    $txtNewRoleName.location = new-object system.drawing.point(200,85)
    $txtNewRoleName.Visible = $False
    $txtNewRoleNameChange = { $this.Text = $this.Text -replace '[^a-zA-Zåäö0123456789 -]','' } # Only allows alphanumeric characters (and also the characters 'å','ä','ö','-' and ' ') to be entered into this field.
    $txtNewRoleName.Add_TextChanged($txtNewRoleNameChange)
    $tabRoles.controls.Add($txtNewRoleName)

    $lblNewRoleTier= New-Object system.windows.Forms.Label
    $lblNewRoleTier.Width = 150
    $lblNewRoleTier.location = new-object system.drawing.point(25,110)
    $lblNewRoleTier.Text = "Tier:"
    $lblNewRoleTier.Visible = $False
    $tabRoles.controls.Add($lblNewRoleTier)
    $cmbNewRoleTier = New-Object system.windows.Forms.ComboBox
    $cmbNewRoleTier.Width = 150
    $cmbNewRoleTier.location = new-object system.drawing.point(200,110)
    $cmbNewRoleTier.DropDownStyle = "DropDownList"
    foreach ( $Tier in $Tiers ) {
        if ( $Tier -eq 0 ) {
            if ( $AccessLevel -eq 0 ) { $cmbNewRoleTier.Items.Add($Tier) | out-null }
        }
        else { $cmbNewRoleTier.Items.Add($Tier) | out-null }
        
        $cmbNewRoleTier.SelectedItem = "1"
    }
    $cmbNewRoleTier.Visible = $False
    $tabRoles.controls.Add($cmbNewRoleTier)

    $btnNewRoleCancel= New-Object system.windows.Forms.Button
    $btnNewRoleCancel.Width = 150
    $btnNewRoleCancel.Height = 25
    $btnNewRoleCancel.location = new-object system.drawing.point(25,185)
    $btnNewRoleCancel.Text = "Cancel"
    $btnNewRoleCancel.Visible = $False
    $btnNewRoleCancel.Add_Click{
        $lstAvailableTasks.Visible = $True
        $lstAssignedTasks.Visible = $True
        $btnAddTask.Visible = $True
        $btnRemoveTask.Visible = $True
        $lblRole.Visible = $True
        $cmbRole.Visible = $True
        $btnApplyTasks.Visible = $True
        $lblAssignedTasks.Visible = $True
        $lblAssignedCount.Visible = $True
        $lblAvailableTasks.Visible = $True
        $lblAvailableCount.Visible = $True
        $btnNewRole.Visible = $True
        $lblNewRole.Visible = $False
        $lblNewRoleTier.Visible = $False
        $cmbNewRoleTier.Visible = $False
        $cmbNewRoleTier.SelectedItem = "1"
        $lblNewRoleName.Visible = $False
        $txtNewRoleName.Visible = $False
        $txtNewRoleName.Text = ""
        $btnNewRoleCancel.Visible = $False
        $btnCreateNewRole.Visible = $False
    }
    $tabRoles.controls.Add($btnNewRoleCancel)

    $btnCreateNewRole = New-Object system.windows.Forms.Button
    $btnCreateNewRole.Width = 150
    $btnCreateNewRole.Height = 25
    $btnCreateNewRole.location = new-object system.drawing.point(200,185)
    $btnCreateNewRole.Text = "Create new role"
    $btnCreateNewRole.Visible = $False
    $btnCreateNewRole.Add_Click{
        $RoleName = "Role-T$($cmbNewRoleTier.SelectedItem)-$($txtNewRoleName.Text)"
        $MessageBody = "The following role will be created:`n`n$RoleName`n`nAre you sure?"
        $MessageTitle = "$($Form.Text) - Create new role"
        $Choice = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"YesNo","Question")
        if ( $Choice -eq "Yes" ) {
            Try {
                $OU = "OU=T$($cmbNewRoleTier.SelectedItem)-Roles,OU=Tier $($cmbNewRoleTier.SelectedItem),OU=Admin,$DomainDN"
                New-ADGroup -Server $DC -Name $RoleName -GroupCategory Security -GroupScope Global -Path $OU
                $txtNewRoleName.Text = ""
                $cmbNewRoleTier.SelectedItem = "1"
                $cmbRole.Items.Clear()
                $AllRoles = $(Get-ADGroup -Server $DC -filter * -SearchBase "OU=Admin,$DomainDN" | Where { $_.name -like "Role-T*" } | Sort Name ).Name # List those roles by Name and export only the Name-attribute
                foreach ( $Role in $AllRoles ) {
                    $cmbRole.Items.Add($Role) | out-null
                }
                $MessageBody = "Successfully created the new role: $RoleName"
                $MessageTitle = "$($Form.Text) - Create new role"
                [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Information")
            }
            Catch {
                $MessageBody = "An error occured when creating the role: $RoleName"
                $MessageTitle = "$($Form.Text) - Create new role"
                [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Error")
            }
        }
    }
    $tabRoles.controls.Add($btnCreateNewRole)
    
    $cmbRole = New-Object system.windows.Forms.ComboBox
    $cmbRole.Width = 150
    $cmbRole.location = new-object system.drawing.point(180,10)
    $cmbRole.DropDownStyle = "DropDownList"
    $cmbRoleChange = {
        $lstAvailableTasks.Items.Clear()
        $lstAssignedTasks.Items.Clear()

        # Using this method instead of Get-ADPrincipalGroupMembership because of error 1244 when running with other accounts
        $ADMemberOf = ([ADSISEARCHER]"samaccountname=$($cmbRole.SelectedItem)").Findone().Properties.memberof
        $CurrentTasks = @()
        foreach ( $Member in $ADMemberOf ) {
            if ( $Member -like "*Task-*" ) {
                $Member = $Member.Replace("CN=","")
                $Member = $Member.Substring(0,$($Member.IndexOf(",")))
                $CurrentTasks += $Member
            }
        }
        $CurrentTasks = $CurrentTasks | Sort
        foreach ( $Task in $CurrentTasks ) {
            $lstAssignedTasks.Items.Add($Task.Replace("Task-","")) | out-null
        }
        foreach ( $TaskGroup in $AllTaskGroups ) {
            if ( $CurrentTasks -notcontains $TaskGroup ) {
                $lstAvailableTasks.Items.Add($TaskGroup.Replace("Task-","")) | out-null
            }
        }
        $lblAvailableCount.Text = $lstAvailableTasks.Items.Count
        $lblAssignedCount.Text = $lstAssignedTasks.Items.Count
        $global:OriginalTasks = $lstAssignedTasks.Items
        $global:StrOriginalTasks = $lstAssignedTasks.Items
        $btnApplyTasks.Enabled = $False
    }
    $cmbRole.Add_SelectedIndexChanged($cmbRoleChange)
    $tabRoles.controls.Add($cmbRole)
    foreach ( $Role in $AllRoles ) {
        $cmbRole.Items.Add($Role) | out-null
    }

    $lblAvailableTasks = New-Object system.windows.Forms.Label
    $lblAvailableTasks.Width = 100
    $lblAvailableTasks.location = new-object system.drawing.point(25,37)
    $lblAvailableTasks.Text = "Available tasks:"
    $tabRoles.controls.Add($lblAvailableTasks)

    $lblAvailableCount = New-Object system.windows.Forms.Label
    $lblAvailableCount.Width = 60
    $lblAvailableCount.AutoSize = $False
    $lblAvailableCount.Text = "0"
    $lblAvailableCount.TextAlign ="TopRight"
    $lblAvailableCount.location = new-object system.drawing.point(115,37)
    $tabRoles.controls.Add($lblAvailableCount)

    $lblAssignedTasks = New-Object system.windows.Forms.Label
    $lblAssignedTasks.Width = 100
    $lblAssignedTasks.location = new-object system.drawing.point(200,37)
    $lblAssignedTasks.Text = "Assigned tasks:"
    $tabRoles.controls.Add($lblAssignedTasks)

    $lblAssignedCount = New-Object system.windows.Forms.Label
    $lblAssignedCount.Width = 60
    $lblAssignedCount.AutoSize = $False
    $lblAssignedCount.Text = "0"
    $lblAssignedCount.TextAlign ="TopRight"
    $lblAssignedCount.location = new-object system.drawing.point(290,37)
    $tabRoles.controls.Add($lblAssignedCount)

    $lstAvailableTasks= New-Object system.windows.Forms.Listbox
    $lstAvailableTasks.Height = 130    
    $lstAvailableTasks.Width = 150
    $lstAvailableTasks.HorizontalScrollbar = $True
    $lstAvailableTasks.location = new-object system.drawing.point(25,60)
    $lstAvailableTasksChange = { $btnAddTask.Enabled = $True ; $btnRemoveTask.Enabled = $False }
    $lstAvailableTasks.Add_SelectedIndexChanged($lstAvailableTasksChange)
    $tabRoles.controls.Add($lstAvailableTasks)

    $lstAssignedTasks= New-Object system.windows.Forms.Listbox
    $lstAssignedTasks.Height = 130
    $lstAssignedTasks.Width = 150
    $lstAssignedTasks.HorizontalScrollbar = $True
    $lstAssignedTasks.location = new-object system.drawing.point(200,60)
    $lstAssignedTasksChange = { $btnAddTask.Enabled = $False ; $btnRemoveTask.Enabled = $True }
    $lstAssignedTasks.Add_SelectedIndexChanged($lstAssignedTasksChange)
    $tabRoles.controls.Add($lstAssignedTasks)

    $btnAddTask = New-Object system.windows.Forms.Button
    $btnAddTask.Width = 15
    $btnAddTask.Height = 25
    $btnAddTask.location = new-object system.drawing.point(180,95)
    $btnAddTask.Text = ">"
    $btnAddTask.Enabled = $False
    $btnAddTask.Add_Click{
        $lstAssignedTasks.Items.Add($lstAvailableTasks.SelectedItem)
        if ( $global:RemoveTasks -contains $lstAvailableTasks.SelectedItem ) {
            if ( $global:RemoveTasks.Count -gt 1 ) { $global:RemoveTasks.Remove($lstAvailableTasks.SelectedItem) }
            else { $global:RemoveTasks.Clear() }
        }
        $lstAvailableTasks.Items.RemoveAt($lstAvailableTasks.SelectedIndex)
        $lblAvailableCount.Text = $lstAvailableTasks.Items.Count
        $lblAssignedCount.Text = $lstAssignedTasks.Items.Count
        $lstAssignedTasks.Sorted = $True
        $btnAddTask.Enabled = $False
        if ( $AccessLevel -eq 0 ) {
            $btnApplyTasks.Enabled = $True
        }

        [string]$AssignedTasks = $lstAssignedTasks.Items
        if ( ($global:StrOriginalTasks -eq $AssignedTasks) -or $lstAssignedTasks.Items.Count -eq 0 ) {
            $btnApplyTasks.Enabled = $False
        }
        else {
            if ( $AccessLevel -eq 0 ) {
                $btnApplyTasks.Enabled = $True
            }
        }
    }
    $tabRoles.controls.Add($btnAddTask)

    $btnRemoveTask = New-Object system.windows.Forms.Button
    $btnRemoveTask.Width = 15
    $btnRemoveTask.Height = 25
    $btnRemoveTask.location = new-object system.drawing.point(180,125)
    $btnRemoveTask.Text = "<"
    $btnRemoveTask.Enabled = $False
    $btnRemoveTask.Add_Click{
        $lstAvailableTasks.Items.Add($lstAssignedTasks.SelectedItem)
        if ( $global:RemoveTasks -notcontains $lstAssignedTasks.SelectedItem ) { $global:RemoveTasks.Add($lstAssignedTasks.SelectedItem) }
        $lstAssignedTasks.Items.RemoveAt($lstAssignedTasks.SelectedIndex)
        $lblAvailableCount.Text = $lstAvailableTasks.Items.Count
        $lblAssignedCount.Text = $lstAssignedTasks.Items.Count
        $lstAvailableTasks.Sorted = $True
        $btnRemoveTask.Enabled = $False
        
        [string]$AssignedTasks = $lstAssignedTasks.Items
        if ( ($global:StrOriginalTasks -eq $AssignedTasks) -or $lstAssignedTasks.Items.Count -eq 0 ) {
            $btnApplyTasks.Enabled = $False
        }
        else {
            if ( $AccessLevel -eq 0 ) {
                $btnApplyTasks.Enabled = $True
            }
        }
    }
    $tabRoles.controls.Add($btnRemoveTask)

    $btnApplyTasks = New-Object system.windows.Forms.Button
    $btnApplyTasks.Width = 150
    $btnApplyTasks.location = new-object system.drawing.point(200,185)
    $btnApplyTasks.Text = "Apply selected tasks"
    $btnApplyTasks.Enabled = $False
    $btnApplyTasks.Add_Click{

        $AddTasks = @()
        foreach ( $Task in $lstAssignedTasks.Items ) {
            if ( $global:StrOriginalTasks -notlike "*$Task*" )  {
                $AddTasks += "Task-$Task`n"
            }
        }
        
        if ( $AddTasks.Count -gt 0 ) { $AddTaskString = "Added task(s):`n$AddTasks`n" }
        foreach ( $Task in $global:RemoveTasks ) {
            if ( $Task -ne "" ) { $TempString += "Task-$Task`n" }
        }
        if ( $global:RemoveTasks.Count -gt 0 ) { $RemoveTaskstring = "Removed task(s):`n$TempString`n" }

        $MessageBody = "The following change(s) are about to be applied:`n`n$AddTaskString$RemoveTaskstring"
        $MessageTitle = "$($Form.Text) - Apply tasks"
        $Choice = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"YesNo","Information")
        
        if ( $Choice -eq "Yes" ) {
            $TempString = ""
            $AddSuccess = ""
            $AddFail = ""
            $RemoveSuccess = ""
            $RemoveFail = ""
            foreach ( $Task in $AddTasks ) {
                $Task = $Task.Replace("`n","")
                Try {
                    Add-ADGroupMember -Server $DC $Task $($cmbRole.SelectedItem)
                    $AddSuccess += "$Task`n"
                }
                Catch {
                    $AddFail += "$Task`n"
                }
            }
            foreach ( $Task in $global:RemoveTasks ) {
                $Task = "Task-$Task"
                Try {
                    Remove-ADGroupMember -Server $DC $Task $($cmbRole.SelectedItem) -Confirm:$false
                    $RemoveSuccess += "$Task`n"
                }
                Catch {
                    $RemoveFail += "$Task`n"
                }
            }
            
            $Status = "Information"
            if ( $AddSuccess.Length -gt 0 ) { $TempString = "Successfully added task(s):`n$AddSuccess`n" }
            if ( $AddFail.Length -gt 0 ) { $TempString = "$($TempString)Error occured while adding task(s):`n$AddFail`n" ; $Status = "Error" }
            if ( $RemoveSuccess.Length -gt 0 ) { $TempString = "$($TempString)Successfully removed task(s):`n$RemoveSuccess`n" }
            if ( $RemoveFail.Length -gt 0 ) { $TempString = "$($TempString)Error occured while removing task(s):`n$RemoveFail" ; $Status = "Error" }
            
            $MessageBody = "Selected role: $($cmbRole.SelectedItem)`n`n$TempString"
            $MessageTitle = "$($Form.Text) - Modifying assigned tasks"
            [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok",$Status)

            $TempString = ""
            $AddSuccess = ""
            $AddFail = ""
            $RemoveSuccess = ""
            $RemoveFail = ""
            $AddTasks = @()
            $global:RemoveTasks.Clear()

            $lblAvailableCount.Text = $lstAvailableTasks.Items.Count
            $lblAssignedCount.Text = $lstAssignedTasks.Items.Count
            $global:OriginalTasks = $lstAssignedTasks.Items
            $global:StrOriginalTasks = $lstAssignedTasks.Items
            $btnApplyTasks.Enabled = $False
        }

    }
    $tabRoles.controls.Add($btnApplyTasks)
#endregion

#region Tab Server OUs
    $lstServerOUs= New-Object System.Windows.Forms.TreeView
    $lstServerOUs.Width = 165
    $lstServerOUs.Height = 165
    $lstServerOUs.location = new-object system.drawing.point(25,10)
    $lstServerOUs_AfterSelect = { SetCheckBoxStatus $lstServerOUs.SelectedNode.Text ; $btnCreateItems.Enabled = $False }
    $lstServerOUs.Add_AfterSelect($lstServerOUs_AfterSelect)
    $tabServerOUs.controls.Add($lstServerOUs)

    $ServerOUs = Get-ADOrganizationalUnit -filter * -SearchBase $ServersRoot -SearchScope OneLevel -Properties Name,distinguishedName | Select Name, distinguishedName | Sort Name
    foreach ( $ServerOU in $ServerOUs ) {
        $RootNode = new-object System.Windows.Forms.TreeNode
        $RootNode.Name = $ServerOU.distinguishedName
        $RootNode.Text = $ServerOU.Name
        if ( $AllTaskGPOs -contains "Task-Server-LocalAdmin-$($ServerOU.Name)" ) { $AdminPolicy = $True } else { $AdminPolicy = $False }
        if ( $AllTaskGroups -contains "Task-Server-LocalAdmin-$($ServerOU.Name)" ) { $AdminTask = $True } else { $AdminTask = $False }
        if ( $AdminPolicy -eq $False -or $AdminTask -eq $False ) { $RootNode.ForeColor = "White" ; $RootNode.BackColor = "Red" }
        $lstServerOUs.Nodes.Add($RootNode) | out-null
            
        # Going to check for three sublevels in total, this is the first one
        $SubOUsLvl1 = Get-ADOrganizationalUnit -filter * -SearchBase $RootNode.Name -SearchScope OneLevel -Properties Name,distinguishedName | Select Name, distinguishedName | Sort Name
        if ( $SubOUsLvl1.Count -gt 0 ) {
            foreach ( $SubOULvl1 in $SubOUsLvl1 ) {
                $subNodeLvl1 = new-object System.Windows.Forms.TreeNode
                $subNodeLvl1.Name = $SubOULvl1.distinguishedName
                $subNodeLvl1.Text = $SubOULvl1.Name
                if ( $AllTaskGPOs -contains "Task-Server-LocalAdmin-$($SubOULvl1.Name)" ) { $AdminPolicy = $True } else { $AdminPolicy = $False }
                if ( $AllTaskGroups -contains "Task-Server-LocalAdmin-$($SubOULvl1.Name)" ) { $AdminTask = $True } else { $AdminTask = $False }
                if ( $AdminPolicy -eq $False -or $AdminTask -eq $False ) { $subNodeLvl1.ForeColor = "White" ; $subNodeLvl1.BackColor = "Red" }
                $RootNode.Nodes.Add($subNodeLvl1) | out-null

                # Second sublevel
                $SubOUsLvl2 = Get-ADOrganizationalUnit -filter * -SearchBase $subNodeLvl1.Name -SearchScope OneLevel -Properties Name,distinguishedName | Select Name, distinguishedName | Sort Name
                if ( $SubOUsLvl2.Count -gt 0 ) {
                    foreach ( $SubOULvl2 in $SubOUsLvl2 ) {
                        $subNodeLvl2 = new-object System.Windows.Forms.TreeNode
                        $subNodeLvl2.Name = $SubOULvl2.distinguishedName
                        $subNodeLvl2.Text = $SubOULvl2.Name
                        if ( $AllTaskGPOs -contains "Task-Server-LocalAdmin-$($SubOULvl2.Name)" ) { $AdminPolicy = $True } else { $AdminPolicy = $False }
                        if ( $AllTaskGroups -contains "Task-Server-LocalAdmin-$($SubOULvl2.Name)" ) { $AdminTask = $True } else { $AdminTask = $False }
                        if ( $AdminPolicy -eq $False -or $AdminTask -eq $False ) { $subNodeLvl2.ForeColor = "White" ; $subNodeLvl2.BackColor = "Red" }
                        $subNodeLvl1.Nodes.Add($subNodeLvl2) | out-null

                        #Third sublevel
                        $SubOUsLvl3 = Get-ADOrganizationalUnit -filter * -SearchBase $subNodeLvl2.Name -SearchScope OneLevel -Properties Name,distinguishedName | Select Name, distinguishedName | Sort Name
                        if ( $SubOUsLvl3.Count -gt 0 ) {
                            foreach ( $SubOULvl3 in $SubOUsLvl3 ) {
                                $subNodeLvl3 = new-object System.Windows.Forms.TreeNode
                                $subNodeLvl3.Name = $SubOULvl3.distinguishedName
                                $subNodeLvl3.Text = $SubOULvl3.Name
                                if ( $AllTaskGPOs -contains "Task-Server-LocalAdmin-$($SubOULvl3.Name)" ) { $AdminPolicy = $True } else { $AdminPolicy = $False }
                                if ( $AllTaskGroups -contains "Task-Server-LocalAdmin-$($SubOULvl3.Name)" ) { $AdminTask = $True } else { $AdminTask = $False }
                                if ( $AdminPolicy -eq $False -or $AdminTask -eq $False ) { $subNodeLvl3.ForeColor = "White" ; $subNodeLvl3.BackColor = "Red" }
                                $subNodeLvl2.Nodes.Add($subNodeLvl3) | out-null
                            }
                        }
                    }
                }
            }
        }
    }

    $lblSelected = New-Object System.Windows.Forms.Label
    $lblSelected.Width = 100
    $lblSelected.Text = "Currently selected:"
    $lblSelected.location = new-object system.drawing.point(200,10)
    $tabServerOUs.Controls.Add($lblSelected)
    $lblSelectedOU = New-Object System.Windows.Forms.Label
    $lblSelectedOU.Width = 200
    $lblSelectedOU.location = new-object system.drawing.point(200,35)
    $tabServerOUs.Controls.Add($lblSelectedOU)

    $chkAdminTask = New-Object system.windows.Forms.Checkbox
    $chkAdminTask.Text = "Local Admin Task exists"
    $chkAdminTask.Location = new-object system.drawing.point(200,60)
    $chkAdminTask.Width = 150
    $chkAdminTaskClick = {
        if ( $AccessLevel -eq 0 ) { if ( ($(($chkAdminTask.Enabled -eq $True -and $chkAdminTask.Checked -eq $True) + ($chkAdminGPO.Enabled -eq $True -and $chkAdminGPO.Checked -eq $True) + ($chkUserTask.Enabled -eq $True -and $chkUserTask.Checked -eq $True) + ($chkUserGPO.Enabled -eq $True -and $chkUserGPO.Checked -eq $True)) -gt 0)) { $btnCreateItems.Enabled = $True } else { $btnCreateItems.Enabled = $False } }
    }
    $chkAdminTask.Add_Click($chkAdminTaskClick)
    $tabServerOUs.Controls.Add($chkAdminTask)

    $chkAdminGPO = New-Object system.windows.Forms.Checkbox
    $chkAdminGPO.Text = "Local Admin GPO exists"
    $chkAdminGPO.Location = new-object system.drawing.point(200,85)
    $chkAdminGPO.Width = 150
    $chkAdminGPOClick = {
        if ( $AccessLevel -eq 0 ) { if ( ($(($chkAdminTask.Enabled -eq $True -and $chkAdminTask.Checked -eq $True) + ($chkAdminGPO.Enabled -eq $True -and $chkAdminGPO.Checked -eq $True) + ($chkUserTask.Enabled -eq $True -and $chkUserTask.Checked -eq $True) + ($chkUserGPO.Enabled -eq $True -and $chkUserGPO.Checked -eq $True)) -gt 0)) { $btnCreateItems.Enabled = $True } else { $btnCreateItems.Enabled = $False } }
    }
    $chkAdminGPO.Add_Click($chkAdminGPOClick)
    $tabServerOUs.Controls.Add($chkAdminGPO)

    $chkUserTask = New-Object system.windows.Forms.Checkbox
    $chkUserTask.Text = "Local User Task exists"
    $chkUserTask.Location = new-object system.drawing.point(200,110)
    $chkUserTask.Width = 150
    $chkUserTaskClick = {
        if ( $AccessLevel -eq 0 ) { if ( ($(($chkAdminTask.Enabled -eq $True -and $chkAdminTask.Checked -eq $True) + ($chkAdminGPO.Enabled -eq $True -and $chkAdminGPO.Checked -eq $True) + ($chkUserTask.Enabled -eq $True -and $chkUserTask.Checked -eq $True) + ($chkUserGPO.Enabled -eq $True -and $chkUserGPO.Checked -eq $True)) -gt 0)) { $btnCreateItems.Enabled = $True } else { $btnCreateItems.Enabled = $False } }
    }
    $chkUserTask.Add_Click($chkUserTaskClick)
    $tabServerOUs.Controls.Add($chkUserTask)

    $chkUserGPO = New-Object system.windows.Forms.Checkbox
    $chkUserGPO.Text = "Local User GPO exists"
    $chkUserGPO.Location = new-object system.drawing.point(200,135)
    $chkUserGPO.Width = 150
    $chkUserGPOClick = {
        if ( $AccessLevel -eq 0 ) { if ( ($(($chkAdminTask.Enabled -eq $True -and $chkAdminTask.Checked -eq $True) + ($chkAdminGPO.Enabled -eq $True -and $chkAdminGPO.Checked -eq $True) + ($chkUserTask.Enabled -eq $True -and $chkUserTask.Checked -eq $True) + ($chkUserGPO.Enabled -eq $True -and $chkUserGPO.Checked -eq $True)) -gt 0)) { $btnCreateItems.Enabled = $True } else { $btnCreateItems.Enabled = $False } }
    }
    $chkUserGPO.Add_Click($chkUserGPOClick)
    $tabServerOUs.Controls.Add($chkUserGPO)

    $btnCreateItems = New-Object system.windows.Forms.Button
    $btnCreateItems.Width = 150
    $btnCreateItems.location = new-object system.drawing.point(200,185)
    $btnCreateItems.Text = "Create new items"
    $btnCreateItems.Enabled = $False
    $btnCreateItems.Add_Click{
        if ( $chkAdminTask.Enabled -eq $True -and $chkAdminTask.Checked -eq $True ) { $CreateAdminTaskInfo = " - Creates the task for LocalAdmin`n" }
        if ( $chkAdminGPO.Enabled -eq $True -and $chkAdminGPO.Checked -eq $True ) { $CreateAdminGPOInfo = " - Creates and links the GPO for LocalAdmin`n" ; $CreateAdminTaskInfo = " - Creates the task for LocalAdmin`n" ; $chkAdminTask.Checked = $True }
        if ( $chkUserTask.Enabled -eq $True -and $chkUserTask.Checked -eq $True ) { $CreateUserTaskInfo = " - Creates the task LocalUser`n" }
        if ( $chkUserGPO.Enabled -eq $True -and $chkUserGPO.Checked -eq $True ) { $CreateUserGPOInfo = " - Creates and links the GPO for LocalUser`n" ; $CreateUserTaskInfo = " - Creates the task LocalUser`n" ; $chkUserTask.Checked = $True }

        $MessageBody = "Selected Organizational Unit:`n$($lstServerOUs.SelectedNode.Text)`n`nThe following item(s) will be created:`n`n$CreateAdminTaskInfo$CreateAdminGPOInfo$CreateUserTaskInfo$CreateUserGPOInfo`nAre you sure?"
        $MessageTitle = "$($Form.Text) - Create items"
        $Choice = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"YesNo","Information")
        if ( $Choice -eq "Yes" ) { 
            if ( $chkAdminTask.Enabled -eq $True -and $chkAdminTask.Checked -eq $True ) {
                Try {
                    $Description = "Local Server Administrator"
                    $GroupName = "Task-Server-LocalAdmin-$($lstServerOUs.SelectedNode.Text)"
                    New-ADGroup -Path "OU=T0-Tasks,OU=Tier 0,OU=Admin,$DomainDN" -Name $GroupName -GroupScope DomainLocal -GroupCategory Security -Description $Description -Server $DC
                    $chkAdminTask.Enabled = $False
                    $CreateAdminTask = $True
                }
                Catch {
                    $CreateAdminTask = $False
                }
            }
            if ( $chkAdminGPO.Enabled -eq $True -and $chkAdminGPO.Checked -eq $True ) {
                Try {
                    $CreateGPO = CreateGPO -OUName $lstServerOUs.SelectedNode.Text -Type "Admin" -OU $lstServerOUs.SelectedNode.Name
                    $AllTaskGroups = $(Get-ADGroup -Server $DC -filter ('Name -like "Task-Server-Local*"') -SearchBase "OU=T0-Tasks,OU=Tier 0,OU=Admin,$DomainDN").Name
                    $AllTaskGPOs = $(Get-GPO -All -Server $DC | Where {$_.displayName -like "Task-Server-Local*"} ).DisplayName
                    $chkAdminGPO.Enabled = $False
                    $CreateAdminGPO = $True
                }
                Catch {
                    $CreateAdminGPO = $False
                }
            }
            if ( $chkUserTask.Enabled -eq $True -and $chkUserTask.Checked -eq $True ) {
                Try {
                    $Description = "Local Server User"
                    $GroupName = "Task-Server-LocalUser-$($lstServerOUs.SelectedNode.Text)"
                    New-ADGroup -Path "OU=T0-Tasks,OU=Tier 0,OU=Admin,$DomainDN" -Name $GroupName -GroupScope DomainLocal -GroupCategory Security -Description $Description -Server $DC
                    $chkUserTask.Enabled = $False
                    $CreateUserTask = $True
                }
                Catch {
                    $CreateUserTask = $False
                }
            }
            if ( $chkUserGPO.Enabled -eq $True -and $chkUserGPO.Checked -eq $True ) {
                Try {
                    $CreateGPO = CreateGPO -OUName $lstServerOUs.SelectedNode.Text -Type "User" -OU $lstServerOUs.SelectedNode.Name
                    $AllTaskGroups = $(Get-ADGroup -Server $DC -filter ('Name -like "Task-Server-Local*"') -SearchBase "OU=T0-Tasks,OU=Tier 0,OU=Admin,$DomainDN").Name
                    $AllTaskGPOs = $(Get-GPO -All -Server $DC | Where {$_.displayName -like "Task-Server-Local*"} ).DisplayName
                    $chkUserGPO.Enabled = $False
                    $CreateUserGPO = $True
                }
                Catch {
                    $CreateUserGPO = $False
                }
            }

            $CreateAdminTaskInfo = ""
            $CreateAdminGPOInfo = ""
            $CreateUserTaskInfo = ""
            $CreateUserGPOInfo = ""
            
            if ( $CreateAdminTask -eq $True ) { $CreateAdminTaskInfo = "Successfully created the LocalAdmin Task, remember to connect this task to the corresponding role(s)`n" }
            else { if ( $chkAdminTask.Checked -eq $True -and $chkAdminTask.Enabled -eq $True ) { $CreateAdminTaskInfo = " - An error occured while creating the LocalAdmin Task`n" }}
            
            if ( $CreateAdminGPO -eq $True ) { $CreateAdminGPOInfo = "Successfully created and linked the GPO for LocalAdmin`n" }
            else { if ( $chkAdminGPO.Checked -eq $True -and $chkAdminGPO.Enabled -eq $True ) { $CreateAdminGPOInfo = " - An error occured during the creation or linking of the GPO for LocalAdmin`nError occured at: ""$CreateGPO""`n" }}
            
            if ( $CreateUserTask -eq $True ) { $CreateUserTaskInfo = "Successfully created the LocalUser Task, remember to connect this task to the corresponding role(s)`n" }
            else { if ( $chkUserTask.Checked -eq $True -and $chkUserTask.Enabled -eq $True ) { $CreateUserTaskInfo = " - An error occured while creating the LocalUser Task`n" }}
            
            if ( $CreateUserGPO -eq $True ) { $CreateUserGPOInfo = "Successfully created and linked the GPO for LocalUser`n" }
            else { if ( $chkUserGPO.Checked -eq $True -and $chkUserGPO.Enabled -eq $True ) { $CreateUserGPOInfo = " - An error occured during the creation or linking of the GPO for LocalUser`nError occured at: ""$CreateGPO""`n" }}
            
            if ( $($CreateAdminTask + $CreateAdminGPO + $CreateUserTask + $CreateUserGPO) -eq 0 ) {            }
            $MessageBody = "Selected Organizational Unit:`n$($lstServerOUs.SelectedNode.Text)`n`n$CreateAdminTaskInfo$CreateAdminGPOInfo$CreateUserTaskInfo$CreateUserGPOInfo"
            $MessageTitle = "$($Form.Text) - Create items"
            [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,"Ok","Information")
        }
    }
    $tabServerOUs.Controls.Add($btnCreateItems)
#endregion

[void]$Form.ShowDialog() 
$Form.Dispose()
