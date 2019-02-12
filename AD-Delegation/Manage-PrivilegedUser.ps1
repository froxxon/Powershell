Function VerifyComplexPassword ($Password) # Verify that atleast three out of four conditions for a complex password is reached
{
    $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
    If ($Password –cmatch "[^a-zA-Z0-9]") { $PWContainSpecial = $True } Else { $PWContainSpecial = $False } # Checks if any (special) characters exists in the string, that is other (^) characters than a-z, A-Z or 0-9
    If ($Password –cmatch "[a-z]") { $PWContainLower = $True } Else { $PWContainLower = $False } # Checks that the password contains atleast one lowercase alpabethical letter
    If ($Password –cmatch "[A-Z]") { $PWContainUpper = $True } Else { $PWContainUpper = $False } # Checks that the password contains atleast one uppercase alpabethical letter
    If ($Password –cmatch "[0-9]") { $PWContainDigit = $True } Else { $PWContainDigit = $False } # Checks that the password contains atleast one digit
    If ( $PWContainSpecial + $PWContainLower + $PWContainUpper + $PWContainDigit -ge 3 ) { # Verifies how many of the above conditions was reached and it returns $True if its greater or equal to three
        Return $True
    }
    Else {
        Return $False # Returns $False if atleast three out of four conditions wasn't reached
    }
}

Function VerifyMatchingPassword ($Password, $Password2) # Verify that the two passwords entered match
{
    $Password_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
    $Password2_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password2))
    If ( $Password_text -ceq $Password2_text ) {
        Return $True
    }
    Else {
        Return $False
    }
}

$LookupDomains = @("domain1","domain2")
$UserPrefix = "T"
$UserSuffix = "adm"
$FoundUsers = @()

Do {
    Clear-Host
    Write-Host "Manage Privileged Users"
    Write-Host "-----------------------"
    Write-Host ""
    Write-Host "Use this script to set password, enable or unlock`nprivileged account(s) for a specific user."
    Write-Host "Enter the standard username (5 letters, ex: berfe)`nto find its related privileged account(s)."
    Write-Host ""
    Write-Host "When the window with the different accounts shows up,`npress Ctrl to select specific rows while clicking or Shift`nto select multiple in a row, or just select a single one..."
    Write-Host ""
    $Username = Read-host "Username"
}
While ($Username -notmatch "^[a-zA-Z]{5}$")

Write-Host ""
Write-Host "- Searching for privileged account(s) related to $Username"

ForEach ( $LookupDOmain in $LookupDomains ) {
    Write-host "- Querying domain: $LookupDomain"
    $DomainDN = $(Get-ADDomain -Server $LookupDomain).DistinguishedName
    If ( $env:UserName.ToUpper() -notlike "L0*" )  {
        $FoundUsers += Get-ADUser -Filter "samAccountName -like '$("$UserPrefix`1$Username$UserSuffix")' -or samAccountName -like '$("$UserPrefix`2$Username$UserSuffix")'" -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree -Properties samAccountName,LockedOut,Enabled -Server $LookupDomain | Select samAccountName,LockedOut,Enabled | Add-Member @{Domain="$LookupDomain"} -PassThru
    }
    Else {
        $FoundUsers += Get-ADUser -Filter "samAccountName -like '$("$UserPrefix*$Username$UserSuffix")'" -SearchBase "OU=Admin,$DomainDN" -SearchScope Subtree -Properties samAccountName,LockedOut,Enabled -Server $LookupDomain | Select samAccountName,LockedOut,Enabled | Add-Member @{Domain="$LookupDomain"} -PassThru
    }
    
}

Write-Host "- Found $($FoundUsers.Count) account(s)"

[array]$SelectedUsers = $FoundUsers | Select samAccountName, Domain, LockedOut, Enabled | Sort Domain, samAccountName | Out-GridView -OutputMode Multiple
Write-Host "- You have selected $($SelectedUsers.Count) account(s)"
$SelectedUsers = $SelectedUsers | Sort samAccountName

If ( $SelectedUsers.LockedOut -contains $True ) {
    $Question = [System.Windows.MessageBox]::Show("Some of the users you have selected are locked, you are about to Unlock them.`n`nAre you sure?",' Unlock users','YesNo')
    If ( $Question -eq "Yes" ) {
        Write-Host ""
        Write-host "Unlocking the selected accounts"
        ForEach ( $SelectedUser in $( $SelectedUsers | Where LockedOut -eq $True )) {
            Try {
                Unlock-ADAccount $SelectedUser.samAccountName -Server $SelectedUser.Domain
                Write-host "- " -NoNewLine ; Write-Host "Successfully" -ForegroundColor Green -NoNewline ; Write-host " unlocked: $($SelectedUser.Domain)\$($SelectedUser.samAccountName)"
            }
            Catch {
                Write-host "- " -NoNewline ; Write-Host "Failed" -ForegroundColor Red -NoNewline ; Write-host " to unlock: $($SelectedUser.Domain)\$($SelectedUser.samAccountName)"
            }
        }
    }
}

If ( $SelectedUsers.Enabled -contains $False ) {
    $Question = [System.Windows.MessageBox]::Show("Some of the users you have selected are disabled, you are about to Enable them.`n`nAre you sure?",' Enable users','YesNo')
    If ( $Question -eq "Yes" ) {
        Write-Host ""
        Write-host "Enabling the selected accounts"
        ForEach ( $SelectedUser in $( $SelectedUsers | Where Enabled -eq $False )) {
            Try {
                Enable-ADAccount $SelectedUser.samAccountName -Server $SelectedUser.Domain
                Write-host "- " -NoNewLine ; Write-Host "Successfully" -ForegroundColor Green -NoNewline ; Write-host " enabled: $($SelectedUser.Domain)\$($SelectedUser.samAccountName)"
            }
            Catch {
                Write-host "- " -NoNewline ; Write-Host "Failed" -ForegroundColor Red -NoNewline ; Write-host " to enable: $($SelectedUser.Domain)\$($SelectedUser.samAccountName)"
            }
        }
    }
}

If ( $SelectedUsers.Count -gt 0 ) {
    $Question = [System.Windows.MessageBox]::Show("Do you want to set a new password for all the selected users?",' Set new password for users','YesNo')
    If ( $Question -eq "Yes" ) {
        Write-host ""
        Write-Host "Provide New Password.`n`nRemember that you have to use at least 3 out of 4 of the requirements below:`n`n- Minimum length of 8 characters (14 for Tier 0-accounts)`n- 1 lower case character (a-z)`n- 1 upper case character (A-Z)`n- 1 numeric or special character (0-9, !#¤%_ etc.)"
        $Userlevels = @()
        ForEach ( $SelectedUser in $SelectedUsers ) {
            If ( $UserLevels -notcontains $($SelectedUser.samAccountName.Substring(1,1)) ) { $UserLevels += $SelectedUser.samAccountName.Substring(1,1) }
        }
        ForEach ( $UserLevel in $UserLevels ) {
            Do {
                Write-Host ""
                Write-Host "Enter the new password for the selected $UserPrefix$UserLevel-accounts"
                $NewPassword = Read-Host -Prompt "Password" -AsSecureString
                $NewPassword2 = Read-Host -Prompt "Re-enter passowrd" -AsSecureString
                $PWComplexTest = VerifyComplexPassword -Password $NewPassword
                If ( $PWComplexTest -eq $False ) { Write-Host "The password is not complex, try again!" }
                $PWMatchTest = VerifyMatchingPassword $NewPassword $NewPassword2
                If ( $PWMatchTest -eq $False ) { Write-Host "The passwords entered does not match, try again!" }
            }
            Until ( $PWComplexTest -eq $True -and $PWMatchTest -eq $True )
            If ( $UserLevel -eq 0 ) { $NewPasswordT0 = $NewPassword ; $NewPassword2T0 = $NewPassword2 }
            If ( $UserLevel -eq 1 ) { $NewPasswordT1 = $NewPassword ; $NewPassword2T1 = $NewPassword2 }
            If ( $UserLevel -eq 2 ) { $NewPasswordT2 = $NewPassword ; $NewPassword2T2 = $NewPassword2 }
        }

        Write-host ""
        Write-host "Sets the new password for the selected accounts"
        $SelectedUsers = $SelectedUsers | Sort Domain, samAccountName
        ForEach ( $SelectedUser in $SelectedUsers ) {
            Try {
                If ( $SelectedUser.samAccountName.Substring(1,1) -eq 0 ) { $NewPassword = $NewPasswordT0 }
                If ( $SelectedUser.samAccountName.Substring(1,1) -eq 1 ) { $NewPassword = $NewPasswordT1 }
                If ( $SelectedUser.samAccountName.Substring(1,1) -eq 2 ) { $NewPassword = $NewPasswordT2 }
                Set-ADAccountPassword $SelectedUser.samAccountName -NewPassword $NewPassword -Reset -Server $SelectedUser.Domain
                Write-host "- " -NoNewLine ; Write-Host "Successfully" -ForegroundColor Green -NoNewline ; Write-host " set password for: $($SelectedUser.Domain)\$($SelectedUser.samAccountName)"
            }
            Catch {
                Write-host "- " -NoNewline ; Write-Host "Failed" -ForegroundColor Red -NoNewline ; Write-host " to set password for: $($SelectedUser.Domain)\$($SelectedUser.samAccountName)"
            }
        }
    }
}

If ( $(Test-Path variable:global:psISE) -eq $False ) { # This hides the Powershellwindow in the background if ISE isn't running
Write-host ""
Read-host "Press Enter to exit..."
}