#############################################################################
#                   Exchange_OwaMailboxPolicy.ps1							#
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
$ErrorText = "Exchange_OwaMailboxPolicy " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "O365DC"
Try{$ErrorLog.WriteEntry($ErrorText,"Error", 100)}catch{}
}

set-location -LiteralPath $location
$output_location = $location + "\output\Exchange"

if ((Test-Path -LiteralPath $output_location) -eq $false)
    {New-Item -Path $output_location -ItemType directory -Force}

$Exchange_OwaMailboxPolicy_outputfile = $output_location + "\Exchange_OwaMailboxPolicy.txt"

@(Get-OwaMailboxPolicy) | ForEach-Object `
{
	$output_Exchange_OwaMailboxPolicy = $_.Name + "`t" + `
		$_.OneDriveAttachmentsEnabled + "`t" + `
		$_.ThirdPartyFileProvidersEnabled + "`t" + `
		$_.ClassicAttachmentsEnabled + "`t" + `
		$_.ReferenceAttachmentsEnabled + "`t" + `
		$_.SaveAttachmentsToCloudEnabled + "`t" + `
		$_.InternalSPMySiteHostURL + "`t" + `
		$_.ExternalSPMySiteHostURL + "`t" + `
		$_.DirectFileAccessOnPublicComputersEnabled + "`t" + `
		$_.DirectFileAccessOnPrivateComputersEnabled + "`t" + `
		$_.WebReadyDocumentViewingOnPublicComputersEnabled + "`t" + `
		$_.WebReadyDocumentViewingOnPrivateComputersEnabled + "`t" + `
		$_.ForceWebReadyDocumentViewingFirstOnPublicComputers + "`t" + `
		$_.ForceWebReadyDocumentViewingFirstOnPrivateComputers + "`t" + `
		$_.WacViewingOnPublicComputersEnabled + "`t" + `
		$_.WacViewingOnPrivateComputersEnabled + "`t" + `
		$_.ForceWacViewingFirstOnPublicComputers + "`t" + `
		$_.ForceWacViewingFirstOnPrivateComputers + "`t" + `
		$_.ActionForUnknownFileAndMIMETypes + "`t" + `
		$_.WebReadyDocumentViewingForAllSupportedTypes + "`t" + `
		$_.PhoneticSupportEnabled + "`t" + `
		$_.DefaultTheme + "`t" + `
		$_.IsDefault + "`t" + `
		$_.DefaultClientLanguage + "`t" + `
		$_.LogonAndErrorLanguage + "`t" + `
		$_.UseGB18030 + "`t" + `
		$_.UseISO885915 + "`t" + `
		$_.OutboundCharset + "`t" + `
		$_.GlobalAddressListEnabled + "`t" + `
		$_.OrganizationEnabled + "`t" + `
		$_.ExplicitLogonEnabled + "`t" + `
		$_.OWALightEnabled + "`t" + `
		$_.DelegateAccessEnabled + "`t" + `
		$_.IRMEnabled + "`t" + `
		$_.CalendarEnabled + "`t" + `
		$_.ContactsEnabled + "`t" + `
		$_.TasksEnabled + "`t" + `
		$_.JournalEnabled + "`t" + `
		$_.NotesEnabled + "`t" + `
		$_.OnSendAddinsEnabled + "`t" + `
		$_.RemindersAndNotificationsEnabled + "`t" + `
		$_.PremiumClientEnabled + "`t" + `
		$_.SpellCheckerEnabled + "`t" + `
		$_.SearchFoldersEnabled + "`t" + `
		$_.SignaturesEnabled + "`t" + `
		$_.ThemeSelectionEnabled + "`t" + `
		$_.JunkEmailEnabled + "`t" + `
		$_.UMIntegrationEnabled + "`t" + `
		$_.WSSAccessOnPublicComputersEnabled + "`t" + `
		$_.WSSAccessOnPrivateComputersEnabled + "`t" + `
		$_.ChangePasswordEnabled + "`t" + `
		$_.UNCAccessOnPublicComputersEnabled + "`t" + `
		$_.UNCAccessOnPrivateComputersEnabled + "`t" + `
		$_.ActiveSyncIntegrationEnabled + "`t" + `
		$_.AllAddressListsEnabled + "`t" + `
		$_.RulesEnabled + "`t" + `
		$_.PublicFoldersEnabled + "`t" + `
		$_.SMimeEnabled + "`t" + `
		$_.RecoverDeletedItemsEnabled + "`t" + `
		$_.InstantMessagingEnabled + "`t" + `
		$_.TextMessagingEnabled + "`t" + `
		$_.ForceSaveAttachmentFilteringEnabled + "`t" + `
		$_.SilverlightEnabled + "`t" + `
		$_.InstantMessagingType + "`t" + `
		$_.DisplayPhotosEnabled + "`t" + `
		$_.AllowOfflineOn + "`t" + `
		$_.SetPhotoURL + "`t" + `
		$_.PlacesEnabled + "`t" + `
		$_.WeatherEnabled + "`t" + `
		$_.LocalEventsEnabled + "`t" + `
		$_.InterestingCalendarsEnabled + "`t" + `
		$_.AllowCopyContactsToDeviceAddressBook + "`t" + `
		$_.PredictedActionsEnabled + "`t" + `
		$_.UserDiagnosticEnabled + "`t" + `
		$_.FacebookEnabled + "`t" + `
		$_.LinkedInEnabled + "`t" + `
		$_.WacExternalServicesEnabled + "`t" + `
		$_.WacOMEXEnabled + "`t" + `
		$_.ReportJunkEmailEnabled + "`t" + `
		$_.GroupCreationEnabled + "`t" + `
		$_.SkipCreateUnifiedGroupCustomSharepointClassification + "`t" + `
		$_.WebPartsFrameOptionsType + "`t" + `
		$_.UserVoiceEnabled + "`t" + `
		$_.SatisfactionEnabled + "`t" + `
		$_.FreCardsEnabled + "`t" + `
		$_.ConditionalAccessPolicy + "`t" + `
		$_.OutlookBetaToggleEnabled

	$output_Exchange_OwaMailboxPolicy | Out-File -FilePath $Exchange_OwaMailboxPolicy_outputfile -append 
}

$EventText = "Exchange_OwaMailboxPolicy " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n" 

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
