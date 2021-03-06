#############################################################################
#                  Skype_CsTenant.ps1		 			#
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
$ErrorText = "Skype_CsTenant " + "`n" + $server + "`n"
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

$OutputFile = $output_location + "\Skype_CsTenant.txt"

@(Get-CsTenant) | ForEach-Object `
{
	If ($_.AssignedPlan -ne $null){$AssignedPlan = "True"}
		else{$AssignedPlan = "False"}
	If ($_.ProvisionedPlan -ne $null){$ProvisionedPlan = "True"}
		else{$ProvisionedPlan = "False"}

	$output_Skype_CsTenant = [string]$_.Name + "`t" + `
	$_.AdminDescription + "`t" + `
	$_.AllowedDataLocation + "`t" + `
	$AssignedPlan + "`t" + `
	$_.City + "`t" + `
	#$_.CompanyPartnership + "`t" + `
	#$_.CompanyTags + "`t" + `
	$_.CountryAbbreviation + "`t" + `
	$_.CountryOrRegionDisplayName + "`t" + `
	$_.Description + "`t" + `
	$_.DirSyncEnabled + "`t" + `
	$_.DisableExoPlanProvisioning + "`t" + `
	$_.DisableTeamsProvisioning + "`t" + `
	$_.DisplayName + "`t" + `
	$_.DistinguishedName + "`t" + `
	$_.Domains + "`t" + `
	$_.DomainUrlMap + "`t" + `
	$_.ExperiencePolicy + "`t" + `
	$_.Guid + "`t" + `
	$_.Id + "`t" + `
	$_.Identity + "`t" + `
	$_.IsByPassValidation + "`t" + `
	$_.IsMNC + "`t" + `
	$_.IsReadinessUploaded + "`t" + `
	$_.IsUpgradeReady + "`t" + `
	$_.IsValid + "`t" + `
	$_.LastProvisionTimeStamp + "`t" + `
	$_.LastPublishTimeStamp + "`t" + `
	$_.LastSubProvisionTimeStamp + "`t" + `
	$_.LastSyncTimeStamp + "`t" + `
	$_.MNCEnableTimeStamp + "`t" + `
	$_.MNCReady + "`t" + `
	$_.NonPrimaryResource + "`t" + `
	$_.ObjectCategory + "`t" + `
	$_.ObjectClass + "`t" + `
	$_.ObjectId + "`t" + `
	$_.ObjectState + "`t" + `
	$_.OcoDomainsTracked + "`t" + `
	$_.OriginalRegistrarPool + "`t" + `
	$_.OriginatingServer + "`t" + `
	$_.PendingDeletion + "`t" + `
	$_.Phone + "`t" + `
	$_.PostalCode + "`t" + `
	$_.PreferredLanguage + "`t" + `
	$ProvisionedPlan + "`t" + `
	$_.ProvisioningCounter + "`t" + `
	$_.ProvisioningStamp + "`t" + `
	$_.PublicProvider + "`t" + `
	$_.PublishingCounter + "`t" + `
	$_.PublishingStamp + "`t" + `
	$_.RegistrarPool + "`t" + `
	$_.ServiceInfo + "`t" + `
	$_.ServiceInstance + "`t" + `
	$_.StateOrProvince + "`t" + `
	$_.Street + "`t" + `
	$_.SubProvisioningCounter + "`t" + `
	$_.SubProvisioningStamp + "`t" + `
	$_.SyncingCounter + "`t" + `
	$_.TeamsUpgradeEffectiveMode + "`t" + `
	$_.TeamsUpgradeEligible + "`t" + `
	$_.TeamsUpgradeNotificationsEnabled + "`t" + `
	$_.TeamsUpgradeOverridePolicy + "`t" + `
	$_.TeamsUpgradePolicyIsReadOnly + "`t" + `
	$_.TenantId + "`t" + `
	$_.TenantNotified + "`t" + `
	$_.TenantPoolExtension + "`t" + `
	$_.UpgradeRetryCounter + "`t" + `
	$_.UserRoutingGroupIds + "`t" + `
	$_.WhenChanged + "`t" + `
	$_.WhenCreated + "`t" + `
	$_.XForestMovePolicy
	$output_Skype_CsTenant | Out-File -FilePath $OutputFile -append
}

$EventText = "Skype_CsTenant " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n"

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
