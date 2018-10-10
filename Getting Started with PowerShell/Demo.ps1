$cred = Get-Credential

#AzureAD

Connect-AzureAD -Credential $cred
Get-AzureADUser
Get-AzureADUser | Where {$_.UserType -eq "Member"}
Get-AzureADUser | Where { $_.Department -eq "Research"} 
Get-AzureADUser -ObjectId jeff.collins@globomantics.org | Format-List

#Creating New Users

$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = "SPSDEN18"
$PasswordProfile.ForceChangePasswordNextLogin = $true

New-AzureADUser -GivenName "Ben" `
				-Surname "King" `
				-DisplayName "Ben King" `
				-UserPrincipalName "Ben@globomantics.org" `
				-MailNickName "Ben" `
				-AccountEnabled $true `
				-PasswordProfile $PasswordProfile `
				-JobTitle "IT Manager" `
				-Department "IT"
				
Set-AzureADUserManager -ObjectId Ben@globomantics.org -RefObjectId (Get-AzureADUser -ObjectId vlad@globomantics.org).ObjectId 


#Viewing Licenses

Get-AzureADSubscribedSku 
Get-AzureADSubscribedSku | Select-Object  -Property ObjectId, SkuPartNumber, ConsumedUnits -ExpandProperty PrepaidUnits

Get-AzureADSubscribedSku -ObjectId fa17dd8f-73cb-4300-9dfd-265b06fd8901_6fd2c87f-b296-42f0-b197-1e91e994b900 | Select-Object -ExpandProperty ServicePlans

#Setting a License to a User
$User = Get-AzureADUser -ObjectId Ben@globomantics.org

Set-AzureADUser -ObjectId $User.ObjectId -UsageLocation CA

$Sku = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense

$Sku.SkuId = "6fd2c87f-b296-42f0-b197-1e91e994b900"

$Licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses

$Licenses.AddLicenses = $Sku

Set-AzureADUserLicense -ObjectId $User.ObjectId -AssignedLicenses $License

#SharePoint

Connect-SPOService -Url https://globomanticsorg-admin.sharepoint.com/ -Credential $cred
New-SPOSite -Url https://globomanticsorg.sharepoint.com/teams/SPSDEN18 -Owner vlad@globomantics.org -StorageQuota 1024 -LocaleID 1033 -Template "STS#0" -Title "IT Team Site"
Remove-SPOSite `
    -Identity https://globomanticsorg.sharepoint.com/teams/SPSDEN18 `
    -Confirm:$false
	
Get-SPODeletedSite 

Restore-SPODeletedSite -Identity https://globomanticsorg.sharepoint.com/teams/SPSDEN18

$site = Get-SPOSite -Identity https://globomanticsorg.sharepoint.com/teams/SPSDEN18

Set-SPOSite $site -Title "Information Technology Team Site"

Set-SPOSite $site -SharingCapability ExternalUserSharingOnly

#Disabled							Don't allow sharing outside your organization
#ExternalUserSharingOnly			Allow external users who accept sharing invitations and sign in as authenticated users
#ExternalUserAndGuestSharing		Allow sharing with all external users, and by using anonymous access links
#ExistingExternalUserSharingOnly	Allow sharing only with the external users that already exist in your organization's directory

Get-SPOSite | Where {$_.SharingCapability -eq "ExternalUserAndGuestSharing"} | Select Url

$Groups = Get-SPOSiteGroup -Site $site
foreach ($Group in $Groups)
    {
        Write-Host $Group.Title -ForegroundColor "Blue"
        Get-SPOSiteGroup -Site $site -Group $Group.Title |    Select-Object -ExpandProperty Users
        Write-Host
    }


Set-SPOBrowserIdleSignOut `
    -Enabled $true `
    -WarnAfter (New-TimeSpan -Minutes 5) `
    -SignOutAfter (New-TimeSpan -Minutes 10)


#SPO PNP
Connect-PnPOnline -Url https://globomanticsorg.sharepoint.com/teams/SPSDEN18 -Credentials $cred

New-PnPWeb -Url Managers `
	-Title "Managers Only Site" `
	-Template "STS#0" `
	-BreakInheritance `
	-Locale 1033 `
	-Description "Use this subsite to communication about sensitive information between managers"

New-PnPList -Title "Team Announcements" -Template Announcements
Get-PnPList


#Exchange

$Session = New-PSSession -ConfigurationName Microsoft.Exchange `
	-ConnectionUri https://outlook.office365.com/powershell-liveid/ `
	-Credential $cred `
	-Authentication Basic `
	-AllowRedirection

Import-PSSession $Session


Get-User | Select UserPrincipalName, RecipientType, RecipientTypeDetails | Format-Table -Wrap

Get-Mailbox | Select DisplayName, RecipientTypeDetails,ProhibitSendReceiveQuota | Format-Table -autosize

New-MailContact -Name "401K Questions" -ExternalEmailAddress companyname@financialcompany.com 
Set-MailContact -Identity "401K Questions" -MailTip "Do not send confidential information to this mailbox!"

Set-Mailbox -Identity jeff.collins `
	-HiddenFromAddressListsEnabled $true `
	-DeliverToMailboxAndForward $false `
	-ForwardingAddress vlad@globomantics.org
	
	
$Body = @"
"Hello </br> </br>
Please Note I am not currently working for Globomantics anymore. </br> </br>  
Please contact Vlad Catrinescu <a href="mailto:vlad@globomantics.org">vlad@globomantics.org</a> for any questions. </br> </br>
Thanks!"
"@

Set-MailboxAutoReplyConfiguration `
	-Identity jeff.collins@globomantics.org `
	-ExternalMessage $body `
	-InternalMessage $body `
	-AutoReplyState Enabled

Get-DistributionGroup
Add-DistributionGroupMember -Identity "Marketing" -Member "jeff.collins@globomantics.org"
Set-DistributionGroup -Identity "All Company" -AcceptMessagesOnlyFrom "vlad@globomantics.org"
Get-MailboxStatistics -Identity vlad@globomantics.org | Select DisplayName, DeletedItemCount, ItemCount, TotalItemSize, LastLogonTime


Get-UnifiedGroup
Get-UnifiedGroup  | Select Alias, PrimarySmtpAddress, WhenCreated, WhenChanged

New-UnifiedGroup -DisplayName "SPSDEN18" -Alias "O365Group-SPSDEN18" -EmailAddresses "SPSDEN18@globomantics.org" -AccessType Private

New-UnifiedGroup -DisplayName "SPSDEN18-ReorgPrivate" `
	-Alias "O365Group-SPSDEN18-ReorgPrivate" `
	-EmailAddresses "SPSDEN18-ReorgPrivate@globomantics.org" `
	-AccessType Private `
	-HiddenGroupMembershipEnabled

Set-UnifiedGroup -Identity "O365Group-SPSDEN18-ReorgPrivate" -HiddenFromAddressListsEnabled $true


Get-UnifiedGroupLinks -Identity "O365Group-SPSDEN18" -LinkType "Members"

Add-UnifiedGroupLinks -Identity "O365Group-SPSDEN18" -LinkType "Members" -Links @("Jonathan@globomantics.org","alex.west@globomantics.org")

Add-UnifiedGroupLinks -Identity "O365Group-SPSDEN18" -LinkType "Owners" -Links "Jonathan@globomantics.org"

Get-UnifiedGroupLinks -Identity "O365Group-SPSDEN18" -LinkType "Owners"

Remove-UnifiedGroupLinks -Identity "O365Group-SPSDEN18" -LinkType "Owners" -Links Jonathan@globomantics.org -Confirm:$false
Remove-UnifiedGroupLinks -Identity "O365Group-SPSDEN18" -LinkType "Members" -Links Jonathan@globomantics.org -Confirm:$false

Remove-UnifiedGroup -Identity O365Group-SPSDEN18 -Confirm:$false

Get-AzureADMSDeletedGroup
Get-AzureADMSDeletedGroup | Select Id, DisplayName, DeletedDateTime | Sort-Object DeletedDateTime

