#############################################################################
#                     Exchange_InboundConnector.ps1		 					#
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
$ErrorText = "Exchange_InboundConnector " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "O365DC"
Try{$ErrorLog.WriteEntry($ErrorText,"Error", 100)}catch{}
}

set-location -LiteralPath $location
$output_location = $location + "\output\Exchange"

$Exchange_InCon_outputfile = $output_location + "\Exchange_InboundConnector.txt"

@(Get-InboundConnector) | ForEach-Object `
{
	$output_Exchange_InCon = $_.Name + "`t" + `
		$_.Enabled + "`t" + `
		$_.ConnectorType + "`t" + `
		$_.ConnectorSource + "`t" + `
		$_.Comment + "`t" + `
		$_.SenderIPAddresses + "`t" + `
		$_.SenderDomains + "`t" + `
		$_.AssociatedAcceptedDomains + "`t" + `
		$_.RequireTls + "`t" + `
		$_.RemoteIPRanges + "`t" + `
		$_.RestrictDomainsToIPAddresses  + "`t" + `
		$_.RestrictDomainsToCertificate + "`t" + `
		$_.CloudServicesMailEnabled + "`t" + `
		$_.TreatMessagesAsInternal + "`t" + `
		$_.TlsSenderCertificateName + "`t" + `
		$_.DetectSenderIPBySkippingLastIP + "`t" + `
		$_.DetectSenderIPBySkippingTheseIPs + "`t" + `
		$_.DetectSenderIPRecipientList
	$output_Exchange_InCon | Out-File -FilePath $Exchange_InCon_outputfile -append 
}

$EventText = "Exchange_InboundConnector " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n" 

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
