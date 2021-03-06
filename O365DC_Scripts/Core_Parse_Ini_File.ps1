#############################################################################
#                         Core_Parse_Ini_File		 						#
#                                     			 							#
#                               4.0.2    		 							#
#                                     			 							#
#############################################################################
# don't forget...                     			 							#
#   set-executionpolicy unrestricted  			 							#
#                                     			 							#
# Requires:                           			 							#
# 	Exchange Management Shell (or PowerShell)  	 							#
# See O365DC_Instructions.txt for more info									#
#                                     			 							#
# Issues, comments, or suggestions    			 							#
#   mail stemy@microsoft.com          			 							#
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

param($IniFile)
$ArrayIni = @()

Get-Content -Path $IniFile | ForEach-Object `
{
	if ($_ -like "#*")
	{
		#Write-Host "Skipped line " $_
	}	
	elseif ($_ -eq "")
	{
		#Write-Host "Blank line "
	}
	else
	{
		$temp = $_.split(";")
		$ArrayIni += ,@($temp[0],$temp[1])
	}
}

$LineCount = $ArrayIni.count

For ($i=0;$i -lt $LineCount;$i++)
{
	if ($ArrayIni[$i][1] -eq "1")
	{
		$a = $ArrayIni[$i][0]
		#write-host $i $a
		(Invoke-Expression -Command ($a)).checked = $true
	}
	elseif ($ArrayIni[$i][1] -eq "0")
	{
		$a = $ArrayIni[$i][0]
		#write-host $i $a
		(Invoke-Expression -Command ($a)).checked = $false
	}
}
