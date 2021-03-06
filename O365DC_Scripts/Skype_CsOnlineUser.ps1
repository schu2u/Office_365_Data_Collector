#############################################################################
#             		     Skype_CsOnlineUser.ps1		 						#
#                                     			 							#
#                               4.0.2    		 							#
#                                     			 							#
#   This Sample Code is provided for the purpose of illustration only       #
#   and is not intended to be used in a production environment.  THIS       #
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #
#   right to use and modify the Sample Code and to reproduce and distribute #
#   the object code form of the Sample Code, provided that You agree:       #
#   (i) to not use Our name, logo, or trademarks to market Your software    #
#   product in which the Sample Code is embedded; (ii) to include a valid   #
#   copyright notice on Your software product in which the Sample Code is   #
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #
#   Our suppliers from and against any claims or lawsuits, including        #
#   attorneys' fees, that arise or result from the use or distribution      #
#   of the Sample Code.                                                     #
#                                     			 							#
#############################################################################
Param($location,$server,$i,$PSSession)

$a = get-date

$ErrorActionPreference = "Stop"
Trap {
$ErrorText = "Skype_CsOnlineUser " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "O365DC"
Try{$ErrorLog.WriteEntry($ErrorText,"Error", 100)}catch{}
}

set-location -LiteralPath $location
$output_location = $location + "\output\Skype"

if ((Test-Path -LiteralPath $output_location) -eq $false)
    {New-Item -Path $output_location -ItemType directory -Force}

$OutputFile = $output_location + "\Skype_CsOnlineUser.txt"

@(Get-CsOnlineUser) | ForEach-Object `
{
	If ($_.AssignedPlan -ne $null){$AssignedPlan = "True"}
		else{$AssignedPlan = "False"}
	If ($_.ProvisionedPlan -ne $null){$ProvisionedPlan = "True"}
		else{$ProvisionedPlan = "False"}
	If ($_.AcpInfo -ne $null){$AcpInfo = $_.AcpInfo.split("><")}
		else{$AcpInfo = @()}
	$output_Skype_CsOnlineUser = [string]$_.Alias + "`t" + `
	$_.DisplayName + "`t" + `
	#$_.AcpInfo + "`t" + `
	$AcpInfo[1] + "`t" + ` 	# AcpInfo.Default
	$AcpInfo[4] + "`t" + `	# AcpInfo.TollNumber
	$AcpInfo[8] + "`t" + `	# AcpInfo.ParticipantPassCode
	$AcpInfo[12] + "`t" + `	# AcpInfo.domain
	$AcpInfo[16] + "`t" + `	# AcpInfo.name
	$AcpInfo[20] + "`t" + `	# AcpInfo.url
	$_.AddressBookPolicy + "`t" + `
	$_.AdminDescription + "`t" + `
	$_.ArchivingPolicy + "`t" + `
	$AssignedPlan + "`t" + `
	$_.AudioVideoDisabled + "`t" + `
	$_.BaseSimpleUrl + "`t" + `
	$_.BroadcastMeetingPolicy + "`t" + `
	$_.CallerIdPolicy + "`t" + `
	$_.CallingLineIdentity + "`t" + `
	$_.CallViaWorkPolicy + "`t" + `
	$_.City + "`t" + `
	$_.ClientPolicy + "`t" + `
	$_.ClientUpdateOverridePolicy + "`t" + `
	$_.ClientUpdatePolicy + "`t" + `
	$_.ClientVersionPolicy + "`t" + `
	$_.CloudMeetingOpsPolicy + "`t" + `
	$_.CloudMeetingPolicy + "`t" + `
	$_.CloudVideoInteropPolicy + "`t" + `
	$_.Company + "`t" + `
	$_.ConferencingPolicy + "`t" + `
	$_.ContactOptionFlags + "`t" + `
	$_.CountryAbbreviation + "`t" + `
	$_.CountryOrRegionDisplayName + "`t" + `
	$_.Department + "`t" + `
	$_.Description + "`t" + `
	$_.DialPlan + "`t" + `
	$_.DirSyncEnabled + "`t" + `
	$_.DistinguishedName + "`t" + `
	$_.Enabled + "`t" + `
	$_.EnabledForRichPresence + "`t" + `
	$_.EnterpriseVoiceEnabled + "`t" + `
	$_.ExchangeArchivingPolicy + "`t" + `
	$_.ExchUserHoldPolicies + "`t" + `
	$_.ExperiencePolicy + "`t" + `
	$_.ExternalAccessPolicy + "`t" + `
	$_.ExternalUserCommunicationPolicy + "`t" + `
	$_.ExUmEnabled + "`t" + `
	$_.Fax + "`t" + `
	$_.FirstName + "`t" + `
	$_.GraphPolicy + "`t" + `
	$_.Guid + "`t" + `
	$_.HideFromAddressLists + "`t" + `
	$_.HomePhone + "`t" + `
	$_.HomeServer + "`t" + `
	$_.HostedVoiceMail + "`t" + `
	$_.HostedVoicemailPolicy + "`t" + `
	$_.HostingProvider + "`t" + `
	$_.Id + "`t" + `
	$_.Identity + "`t" + `
	$_.InterpretedUserType + "`t" + `
	$_.IPPBXSoftPhoneRoutingEnabled + "`t" + `
	$_.IPPhone + "`t" + `
	$_.IPPhonePolicy + "`t" + `
	$_.IsByPassValidation + "`t" + `
	$_.IsValid + "`t" + `
	$_.LastName + "`t" + `
	$_.LastProvisionTimeStamp + "`t" + `
	$_.LastPublishTimeStamp + "`t" + `
	$_.LastSubProvisionTimeStamp + "`t" + `
	$_.LastSyncTimeStamp + "`t" + `
	$_.LegalInterceptPolicy + "`t" + `
	$_.LicenseRemovalTimestamp + "`t" + `
	$_.LineServerURI + "`t" + `
	$_.LineURI + "`t" + `
	$_.LocationPolicy + "`t" + `
	$_.Manager + "`t" + `
	$_.MCOValidationError + "`t" + `
	$_.MNCReady + "`t" + `
	$_.MobilePhone + "`t" + `
	$_.MobilityPolicy + "`t" + `
	$_.Name + "`t" + `
	$_.NonPrimaryResource + "`t" + `
	$_.ObjectCategory + "`t" + `
	$_.ObjectClass + "`t" + `
	$_.ObjectId + "`t" + `
	$_.ObjectState + "`t" + `
	$_.Office + "`t" + `
	$_.OnlineDialinConferencingPolicy + "`t" + `
	$_.OnlineDialOutPolicy + "`t" + `
	$_.OnlineVoicemailPolicy + "`t" + `
	$_.OnlineVoiceRoutingPolicy + "`t" + `
	$_.OnPremEnterpriseVoiceEnabled + "`t" + `
	$_.OnPremHideFromAddressLists + "`t" + `
	$_.OnPremHostingProvider + "`t" + `
	$_.OnPremLineURI + "`t" + `
	$_.OnPremLineURIManuallySet + "`t" + `
	$_.OnPremOptionFlags + "`t" + `
	$_.OnPremSipAddress + "`t" + `
	$_.OnPremSIPEnabled + "`t" + `
	$_.OptionFlags + "`t" + `
	$_.OriginalPreferredDataLocation + "`t" + `
	$_.OriginatingServer + "`t" + `
	$_.OriginatorSid + "`t" + `
	$_.OtherTelephone + "`t" + `
	$_.OverridePreferredDataLocation + "`t" + `
	$_.OwnerUrn + "`t" + `
	$_.PendingDeletion + "`t" + `
	$_.Phone + "`t" + `
	$_.PinPolicy + "`t" + `
	$_.PostalCode + "`t" + `
	$_.PreferredDataLocation + "`t" + `
	$_.PreferredDataLocationOverwritePolicy + "`t" + `
	$_.PreferredLanguage + "`t" + `
	$_.PresencePolicy + "`t" + `
	$_.PrivateLine + "`t" + `
	$ProvisionedPlan + "`t" + `
	$_.ProvisioningCounter + "`t" + `
	$_.ProvisioningStamp + "`t" + `
	$_.ProxyAddresses + "`t" + `
	$_.PublishingCounter + "`t" + `
	$_.PublishingStamp + "`t" + `
	$_.Puid + "`t" + `
	$_.RegistrarPool + "`t" + `
	$_.RemoteCallControlTelephonyEnabled + "`t" + `
	$_.SamAccountName + "`t" + `
	$_.ServiceInfo + "`t" + `
	$_.ServiceInstance + "`t" + `
	$_.ShadowProxyAddresses + "`t" + `
	$_.Sid + "`t" + `
	$_.SipAddress + "`t" + `
	$_.SipProxyAddress + "`t" + `
	$_.SmsServicePolicy + "`t" + `
	$_.SoftDeletionTimestamp + "`t" + `
	$_.StateOrProvince + "`t" + `
	$_.Street + "`t" + `
	$_.StreetAddress + "`t" + `
	$_.StsRefreshTokensValidFrom + "`t" + `
	$_.SubProvisioningCounter + "`t" + `
	$_.SubProvisioningStamp + "`t" + `
	$_.SubProvisionLineType + "`t" + `
	$_.SyncingCounter + "`t" + `
	$_.TargetRegistrarPool + "`t" + `
	$_.TargetServerIfMoving + "`t" + `
	$_.TeamsAppPermissionPolicy + "`t" + `
	$_.TeamsAppSetupPolicy + "`t" + `
	$_.TeamsCallingPolicy + "`t" + `
	$_.TeamsCortanaPolicy + "`t" + `
	$_.TeamsInteropPolicy + "`t" + `
	$_.TeamsMeetingBroadcastPolicy + "`t" + `
	$_.TeamsMeetingPolicy + "`t" + `
	$_.TeamsMessagingPolicy + "`t" + `
	$_.TeamsOwnersPolicy + "`t" + `
	$_.TeamsUpgradeEffectiveMode + "`t" + `
	$_.TeamsUpgradeNotificationsEnabled + "`t" + `
	$_.TeamsUpgradeOverridePolicy + "`t" + `
	$_.TeamsUpgradePolicy + "`t" + `
	$_.TeamsUpgradePolicyIsReadOnly + "`t" + `
	$_.TeamsVideoInteropServicePolicy + "`t" + `
	$_.TeamsWorkLoadPolicy + "`t" + `
	$_.TenantDialPlan + "`t" + `
	$_.TenantId + "`t" + `
	$_.ThirdPartyVideoSystemPolicy + "`t" + `
	$_.ThumbnailPhoto + "`t" + `
	$_.Title + "`t" + `
	$_.UpgradeRetryCounter + "`t" + `
	$_.UsageLocation + "`t" + `
	$_.UserAccountControl + "`t" + `
	$_.UserPrincipalName + "`t" + `
	$_.UserProvisionType + "`t" + `
	$_.UserRoutingGroupId + "`t" + `
	$_.UserServicesPolicy + "`t" + `
	$_.VoicePolicy + "`t" + `
	$_.VoiceRoutingPolicy + "`t" + `
	$_.WebPage + "`t" + `
	$_.WhenChanged + "`t" + `
	$_.WhenCreated + "`t" + `
	$_.WindowsEmailAddress + "`t" + `
	$_.XForestMovePolicy
	$output_Skype_CsOnlineUser | Out-File -FilePath $OutputFile -append
}

$EventText = "Skype_CsOnlineUser " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n"

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
