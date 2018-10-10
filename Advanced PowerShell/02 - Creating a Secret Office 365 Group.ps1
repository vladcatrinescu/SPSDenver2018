New-UnifiedGroup -DisplayName "SPFestSEA2018-ReorgPrivate" `
	-Alias "O365Group-SPFestSEA2018-ReorgPrivate" `
	-EmailAddresses "SPFestSEA2018-ReorgPrivate@globomantics.org" `
	-AccessType Private `
	-HiddenGroupMembershipEnabled

Set-UnifiedGroup -Identity "O365Group-SPFestSEA2018-ReorgPrivate" -HiddenFromAddressListsEnabled $true
