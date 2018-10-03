#############################################################################
#                    ExOrg_GetMbxStatistics.ps1 							#
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

Trap {
$ErrorText = "ExOrg_GetMbxStatistics " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "O365DC"
Try{$ErrorLog.WriteEntry($ErrorText,"Error", 100)}catch{}
}

set-location -LiteralPath $location
$output_location = $location + "\output\ExOrg\GetMbxStatistics"

if ((Test-Path -LiteralPath $output_location) -eq $false)
    {New-Item -Path $output_location -ItemType directory -Force}

@(Get-Content -Path ".\CheckedMailbox.Set$i.txt") | ForEach-Object `
{
	$ExOrg_GetMbxStatistics_outputfile = $output_location + "\\Set$i~~GetMbxStatistics.txt"
    $mailbox = $_
	Get-MailboxStatistics -identity $mailbox | ForEach-Object `
    {
       	If ($_.totalitemsize -ne $null)
        {	
			$MailboxSize = [string]$_.totalitemsize
			$MailboxSizeBytesLeft = $MailboxSize.split("(")
			$MailboxSizeBytesRight = $MailboxSizeBytesLeft[1].split(" bytes)")
			$MailboxSizeBytes = [long]$MailboxSizeBytesRight[0]
			$MailboxSizeMB = [Math]::Round($MailboxSizeBytes/1048576,2)
        }
        If ($_.TotalDeletedItemSize -ne $null)
        {
            $DumpsterSize = [string]$_.TotalDeletedItemSize
			$DumpsterSizeBytesLeft = $DumpsterSize.split("(")
			$DumpsterSizeBytesRight = $DumpsterSizeBytesLeft[1].split(" bytes)")
			$DumpsterSizeBytes = [long]$DumpsterSizeBytesRight[0]
			$DumpsterSizeMB = [Math]::Round($DumpsterSizeBytes/1048576,2)
        }

    	$output_ExOrg_GetMbxStatistics = $mailbox + "`t" + `
    		$_.DisplayName + "`t" + `
    		$_.ServerName + "`t" + `
    	    $_.Database + "`t" + `
    	    $_.ItemCount + "`t" + `
    	    $_.TotalItemSize + "`t" + `
    		$MailboxSizeMB + "`t" + `
    	    $_.TotalDeletedItemSize + "`t" + `
			$DumpsterSizeMB + "`t" + `
    		$_.IsEncrypted + "`t" + `
    		[string]$_.MailboxType + "`t" + ` 			# Without [string] this reports a number
    		[string]$_.MailboxTypeDetail + "`t" + ` 	# Without [string] this reports a number
    		$_.IsArchiveMailbox + "`t" + `
    		$_.FastIsEnabled + "`t" + `
    		$_.BigFunnelIsEnabled + "`t" + `
    		$_.DatabaseIssueWarningQuota + "`t" + `
    		$_.DatabaseProhibitSendQuota + "`t" + `
    		$_.DatabaseProhibitSendReceiveQuota
    	$output_ExOrg_GetMbxStatistics | Out-File -FilePath $ExOrg_GetMbxStatistics_outputfile -append 
    }
}

$EventText = "ExOrg_GetMbxStatistics " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n" 

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
