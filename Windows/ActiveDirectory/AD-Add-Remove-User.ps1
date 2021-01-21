import-module activedirectory

#caches Admin Credentials for use in script.
$adminaccount = Get-Credential

#Name of GroupMembership file.
$filename = read-host -Prompt 'Input First and Last name of user that is being disabled in format of FirstName_LastName'

#SAM Account of user to be disabled
$username = read-host -prompt 'Input SAMAccountName to be Disabled'
$NewPassword = read-host -prompt 'Input New Password for disabled user account' -AsSecureString

#Stores the current Description
$aduser = get-aduser -identity $username -Properties ObjectGUID, Description -Server <DomainControllerFQDN>
$Date = get-date -UFormat "%m/%d/%Y"

#Takes Old description field and appends the date.
$newDescription = $aduser.description + " - Separated $Date"

#Exports AD Group Membership to location specified
get-ADPrincipalGroupMembership $username -Server <DomainControllerFQDN> | export-csv "\\Fileserver\Pathname\$filename.csv"

#Disables ad account
Disable-ADAccount -Identity $username -Server <DomainControllerFQDN> -Credential $adminaccount

#Removes AD Member from All groups Except Domain User, because Domain User is not part of memberof property
get-aduser -identity $username -Properties memberof -Server <DomainControllerFQDN> | select -ExpandProperty memberof | %{Remove-ADGroupMember $_ -member "$username" -Confirm:$false -Credential $adminaccount}

#Sets new Ad account password
set-adaccountpassword -Identity $username -Reset -NewPassword $NewPassword -Credential $adminaccount -Server <DomainControllerFQDN>

#Move AD account to Newly Disabled OU
Move-ADObject -Identity $aduser.ObjectGUID -Server <DomainControllerFQDN> -credential $adminaccount -TargetPath "ou=<ChildOU>,ou=<ParentOU> org,dc=contoso,dc=com"

#Changes the description to include the date the user Separated
get-aduser $username -server <DomainControllerFQDN> -Credential $adminaccount | set-aduser -Description $newDescription

#Clears the Manager field
get-aduser $username -server <DomainControllerFQDN> -Credential $adminaccount | set-aduser -Manager $null
