#############################################################################
#                  Skype_CsVoicePolicy.ps1		 			#
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
$ErrorText = "Skype_CsVoicePolicy " + "`n" + $server + "`n"
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

$OutputFile = $output_location + "\Skype_CsVoicePolicy.txt"

@(Get-CsVoicePolicy) | ForEach-Object `
{
	$output_Skype_CsVoicePolicy = [string]$_.Name + "`t" + `
	$_.Identity + "`t" + `
	$_.AllowCallForwarding + "`t" + `
	$_.AllowPSTNReRouting + "`t" + `
	$_.AllowSimulRing + "`t" + `
	$_.BusinessVoiceEnabled + "`t" + `
	$_.CallForwardingSimulRingUsageType + "`t" + `
	$_.CustomCallForwardingSimulRingUsages + "`t" + `
	$_.Description + "`t" + `
	$_.EnableBusyOptions + "`t" + `
	$_.EnableBWPolicyOverride + "`t" + `
	$_.EnableCallPark + "`t" + `
	$_.EnableCallTransfer + "`t" + `
	$_.EnableDelegation + "`t" + `
	$_.EnableMaliciousCallTracing + "`t" + `
	$_.EnableTeamCall + "`t" + `
	$_.EnableVoicemailEscapeTimer + "`t" + `
	$_.PreventPSTNTollBypass + "`t" + `
	$_.PstnUsages + "`t" + `
	$_.PSTNVoicemailEscapeTimer + "`t" + `
	$_.TenantAdminEnabled + "`t" + `
	$_.VoiceDeploymentMode
	$output_Skype_CsVoicePolicy | Out-File -FilePath $OutputFile -append
}

$EventText = "Skype_CsVoicePolicy " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n"

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
