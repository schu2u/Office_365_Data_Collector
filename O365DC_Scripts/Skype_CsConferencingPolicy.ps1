#############################################################################
#                    Skype_CsConferencingPolicy.ps1		 					#
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
$ErrorText = "Skype_CsConferencingPolicy " + "`n" + $server + "`n"
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

$Skype_CsConferencingPolicy_outputfile = $output_location + "\Skype_CsConferencingPolicy.txt"

@(Get-CsConferencingPolicy -include all) | ForEach-Object `
{
	$output_Skype_CsConferencingPolicy = [string]$_.Identity + "`t" + `
	$_.AllowAnnotations + "`t" + `
	$_.AllowAnonymousParticipantsInMeetings + "`t" + `
	$_.AllowAnonymousUsersToDialOut + "`t" + `
	$_.AllowConferenceRecording + "`t" + `
	$_.AllowExternalUserControl + "`t" + `
	$_.AllowExternalUsersToRecordMeeting + "`t" + `
	$_.AllowExternalUsersToSaveContent + "`t" + `
	$_.AllowFederatedParticipantJoinAsSameEnterprise + "`t" + `
	$_.AllowIPAudio + "`t" + `
	$_.AllowIPVideo + "`t" + `
	$_.AllowLargeMeetings + "`t" + `
	$_.AllowMultiView + "`t" + `
	$_.AllowNonEnterpriseVoiceUsersToDialOut + "`t" + `
	$_.AllowOfficeContent + "`t" + `
	$_.AllowParticipantControl + "`t" + `
	$_.AllowPolls + "`t" + `
	$_.AllowQandA + "`t" + `
	$_.AllowSharedNotes + "`t" + `
	$_.AllowUserToScheduleMeetingsWithAppSharing + "`t" + `
	$_.ApplicationSharingMode + "`t" + `
	$_.AppSharingBitRateKb + "`t" + `
	$_.AudioBitRateKb + "`t" + `
	$_.Description + "`t" + `
	$_.DisablePowerPointAnnotations + "`t" + `
	$_.EnableAppDesktopSharing + "`t" + `
	$_.EnableDataCollaboration + "`t" + `
	$_.EnableDialInConferencing + "`t" + `
	$_.EnableFileTransfer + "`t" + `
	$_.EnableMultiViewJoin + "`t" + `
	$_.EnableOnlineMeetingPromptForLyncResources + "`t" + `
	$_.EnableP2PFileTransfer + "`t" + `
	$_.EnableP2PRecording + "`t" + `
	$_.EnableP2PVideo + "`t" + `
	$_.EnableReliableConferenceDeletion + "`t" + `
	$_.FileTransferBitRateKb + "`t" + `
	$_.MaxMeetingSize + "`t" + `
	$_.MaxVideoConferenceResolution + "`t" + `
	$_.TotalReceiveVideoBitRateKb + "`t" + `
	$_.VideoBitRateKb
	$output_Skype_CsConferencingPolicy | Out-File -FilePath $Skype_CsConferencingPolicy_outputfile -append
}

$EventText = "Skype_CsConferencingPolicy " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n"

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
