#############################################################################
#                    Core_Assemble_ExDoc_Word.ps1		 					#
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
Param($RunLocation)

$ErrorActionPreference = "stop"
Trap {
$ErrorText = "Core_Assemble_ExDoc_Word " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "O365DC"
#$ErrorLog.WriteEntry($ErrorText,"Error", 100)
}

#region Functions

#region Writedoc
Function Write-Doc
{
	Param($body,$Head,$type)

    Write-Host "Starting Section $($Head)" -ForegroundColor Green
	$Word_ExDoc_documents.Activate()
	$selection=$Word_ExDoc.Selection
	$selection.EndOf(6) | Out-Null
	$selection.TypeText("$([char]13)")
	$selection.Style = $type
	$selection.TypeText($Head)
	$selection.TypeParagraph()
	$selection.Style = "no spacing"
	$selection.Font.Name="Segoe UI"
	$selection.Font.Size=10
	$selection.TypeText($body)
	$selection.TypeParagraph()
	$selection.EndOf(6) | Out-Null
	$selection.TypeParagraph()
}
#endregion Writedoc

#region Update Table
Function Update-Table
{
	Param([Array]$TableContent,[int]$HeaderAlignment,[int]$HeaderHeight,[string]$PrimarySort,[string]$SecondarySort)

    # Exit if TableContent is null
	#If ($TableContent -eq $null)
	If ($TableContent.count -eq 0)
	{
	    write-host "No content present.  No table will be created." -ForegroundColor Yellow
	    return
	}

	$ErrorActionPreference = "SilentlyContinue"
	$wdColor = 14121227
	$TableRange = $Word_ExDoc_documents.application.selection.range
	$Columns = @($TableContent[0] | Get-Member -MemberType NoteProperty).count
	$Rows = ($TableContent.Count)+1   #Add 1 for Column header
	$Table = $Word_ExDoc_documents.Tables.Add($TableRange, $Rows, $Columns)
	$table.AutoFitBehavior(2)
	$table.Style = "Table Grid"
	$table.Borders.InsideLineStyle = 1
	$table.Borders.OutsideLineStyle = 1

	$HeaderReaders = @()
	$HeaderReaders += $PrimarySort
    if ($SecondarySort -ne $null)
    {
        $HeaderReaders += $SecondarySort
    }
	Foreach ($Header in ($TableContent[0] | Get-Member -MemberType NoteProperty).Name)
	{
	    If (($Header -ne $PrimarySort) -and ($Header -ne $SecondarySort))
	    {
	        $HeaderReaders += $Header
	    }
	}
	$Cindex = 1 #Cell Index
	Foreach ($Header in $HeaderReaders )
	{
        if ($Header -ne "")
        {
            $xRow = 1
            $trow = 2
            $Table.Cell($xRow,$Cindex).Range.Orientation = $HeaderAlignment
            $Table.Cell($xRow,$Cindex).Shading.BackgroundPatternColor = $wdColor
            $Table.Cell($xRow,$Cindex).Range.Font.size = 8
            $Table.Cell($xRow,$Cindex).Range.Font.Bold = $True
            $Table.Cell($xRow,$Cindex).Range.Font.Color = "0000000"
            $Table.Cell($xRow,$Cindex).Range.Text = $Header
            If ($HeaderAlignment -gt 0)
            {
                $Table.Rows.Item(1).Height = $HeaderHeight
            }
            Foreach ($item in $TableContent )
            {
                #Make sure that the cell starts off empty
                $CellData = @()
                Try
                {
                    If ($item.$($Header).gettype().basetype.name -eq "array")
                    {
                        foreach ($object in $item.$($Header))
                        {
                            $CellData += $object
                            $CellData += "`r"
                        }
                    }
                    else
                    {
                        $CellData = [string]$item.$($Header)
                    }
                }
                catch {}
                $Table.Cell($tRow,$Cindex).Range.Font.size = 8
                $Table.Cell($tRow,$Cindex).Range.Text = "$CellData"
                $tRow++
            }
            $Cindex++
        }
	}

	#Autofit to Content
	$table.AutoFitBehavior(1)
	$table.Sort($true,1)
	$selection.EndOf(6) | Out-Null
	$selection.TypeParagraph()
}
#endregion Update Table

#region Update Table - Vertical Array
Function Update-TableVertical
{
	Param([Array]$TableContent,[int]$HeaderAlignment,[int]$HeaderHeight,[string]$PrimarySort,[string]$SecondarySort)

	# Exit if TableContent is null
	If ($TableContent -eq $null)
	{
	    write-host "No content present.  No table will be created." -ForegroundColor Yellow
	    return
	}

	$ErrorActionPreference = "SilentlyContinue"
	$wdColor = 14121227
	$TableRange = $Word_ExDoc_documents.application.selection.range
	$Columns = ($TableContent.count) + 1
	$Rows = (@($TableContent[0] | Get-Member -MemberType NoteProperty).count)
	$Table = $Word_ExDoc_documents.Tables.Add($TableRange, $Rows, $Columns)
	$table.AutoFitBehavior(2)
	$table.Style = "Table Grid"
	$table.Borders.InsideLineStyle = 1
	$table.Borders.OutsideLineStyle = 1

	#$HeaderReaders = $TableContent[0] | Get-Member -MemberType NoteProperty | select Name
	$HeaderReaders = @()
	$HeaderReaders += $PrimarySort
    if ($SecondarySort -ne $null)
    {
        $HeaderReaders += $SecondarySort
    }
	Foreach ($Header in ($TableContent[0] | Get-Member -MemberType NoteProperty).Name)
	{
	    If (($Header -ne $PrimarySort) -and ($Header -ne $SecondarySort))
	    {
	        $HeaderReaders += $Header
	    }
	}

	$Table.Cell(1,1).Shading.BackgroundPatternColor = $wdColor
	$Table.Cell(1,1).Range.Font.size = 8
	$Table.Cell(1,1).Range.Font.Bold = $True
	$Table.Cell(1,1).Range.Font.Color = "0000000"
	$Table.Cell(1,1).Range.Text = "Property"
	# Build the far left column
	$RowNumber = 2
	Foreach ($row in $HeaderReaders)
	{
		If (($Row -ne $PrimarySort) -and ($Row -ne $SecondarySort))
		{
			$Table.Cell($RowNumber,1).Range.font.size = 8
			$Table.Cell($RowNumber,1).Range.Text = $Row
			$RowNumber++
        }
	}

	$Column = 2
	Foreach ($Entry in $TableContent)
	{
		$Row = 1
		Foreach ($Header in $HeaderReaders )
		{
            if ($Header -ne "")
            {
                $Table.Cell($Row,$Column).Range.Font.size = 8
                $Table.Cell($Row,$Column).Range.Text = $Entry.($Header)
                If ($Row -eq 1)
                {
                    $Table.Cell($Row,$Column).Shading.BackgroundPatternColor = $wdColor
                    $Table.Cell($Row,$Column).Range.Font.size = 8
                    $Table.Cell($Row,$Column).Range.Font.Bold = $True
                    $Table.Cell($Row,$Column).Range.Font.Color = "0000000"
                }
                $Row++
            }
		}
		$Column++
	}
	#Autofit to Content
	$table.AutoFitBehavior(1)
	$table.Sort($true,1)
	$selection.EndOf(6) | Out-Null
	$selection.TypeParagraph()
}
#endregion Update Table - Vertical Array

#endregion Functions

set-location -LiteralPath $RunLocation

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
#$EventLog.WriteEntry("Starting Core_Assemble_Exchange_Excel","Information", 42)

Try
{
	$ErrorActionPreference = "Stop"
	$O365DC_ExDoc_DOC = $RunLocation + "\Output\O365DC_ExchangeEnvironmentalReport_$(get-date -Format ddMMyyhhmm).docx"
    Copy-Item ($RunLocation + "\Templates\Template.docx") $O365DC_ExDoc_DOC -ErrorAction Stop
}
Catch [system.exception]
{
	Write-Host $_.Message -ForegroundColor Red
}

Write-Host -Object "---- Creating com object for Word"
$Word_ExDoc = New-Object -ComObject Word.application
Write-Host -Object "---- Hiding Word"
$Word_ExDoc.visible = $false
#Write-Host -Object "---- Setting ShowStartupDialog to false"
#$Word_ExDoc.ShowStartupDialog = $false
Write-Host -Object "---- Checking Word version"
$Word_Version = $Word_ExDoc.version
if ($Word_Version -ge 12)
{
	$Word_ExDoc.DefaultSaveFormat = 51
	$Word_Extension = ".docx"
}
else
{
	$Word_ExDoc.DefaultSaveFormat = 56
	$Word_Extension = ".doc"
}
Write-Host -Object "---- Word version $Word_Version and DefaultSaveFormat $Word_Extension"
$Word_ExDoc_documents = $Word_ExDoc.Documents.open($O365DC_ExDoc_DOC)

#Write-Host -Object "---- Setting workbook properties"
#$Excel_Exchange_workbook.author = "Exchange Data Collector v4 (O365DC v4)"
#$Excel_Exchange_workbook.title = "O365DC v4 - Exchange Organization"
#$Excel_Exchange_workbook.comments = "O365DC v4.0.2"

Write-Host -Object "---- Building initial document for environment"
#$Word_ExDoc.Activate()
$selection=$Word_ExDoc.Selection

Write-Host -Object "---- Populating data fields"
# Re-using Koos's variable names

#region Load the Exchange XMLs
#region Load Exchange Text
Write-Host "---- Loading the Exchange XML content"
$ExchangeXml = Import-Clixml "$RunLocation\Templates\ExchangeContent.xml"
#endregion Load Exchange Text

#region Load Hybrid Text
	# Add stuff from line 275-277 of main.ps1 when hybrid is supported
#endregion Load Hybrid Text
#endregion Load the Exchange XMLs

#region Load WMI Text
Write-Host "---- Loading the WMI XML content"
$WmiXml = @(Import-Clixml "$RunLocation\Templates\wmiContent.xml")

#endregion Load WMI Text

#region Populate the Exchange variables from the O365DC text files
Write-Host "---- Populating our Exchange variables from the O365DC output files"

Write-Host "---- Populating Exchange"
#region Exchange
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_OrgConfig.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_OrgConfig.txt")
	$Exchange = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Organization Name"     -Value $DataField[0]
        $Exchange += $Data
	}
}
#endregion Exchange

Write-Host "---- Populating Fsmo"
#region Get-Fsmo
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_Misc_Fsmo.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_Misc_Fsmo.txt")
	$Fsmo = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "DNS Root"              -Value $DataField[0]
        $Data | Add-Member NoteProperty -Name "PDC Emulator"          -Value $DataField[1]
        $Data | Add-Member NoteProperty -Name "RID Master"            -Value $DataField[2]
        $Data | Add-Member NoteProperty -Name "Infrastructure Master" -Value $DataField[3]
        $Data | Add-Member NoteProperty -Name "Domain Naming Master"  -Value $DataField[4]
        $Data | Add-Member NoteProperty -Name "Schema Master"         -Value $DataField[5]
        $Fsmo += $Data
	}
}
#endregion Get-Fsmo

#region Populate the variable
Write-Host "---- Populating Schema"
#region Get-Schema
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_Schema.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_Schema.txt")
	$Schema = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Exchange Schema Version" -Value $DataField[0]
        $Schema += $Data
	}
}
#endregion Get-Schema

Write-Host "---- Populating AdSite"
#region Get-AdSite
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AdSite.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AdSite.txt")
	$AdSite = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Site Name"                     -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Hub Site Enabled"              -Value $DataField[2] -Force
        $AdSite += $Data
	}
}
#endregion Get-AdSite

Write-Host "---- Populating Site Links"
#region Get-SiteLinks
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AdSiteLink.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AdSiteLink.txt")
	$AdSiteLinks = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"              -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Cost"              -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "AD Cost"           -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Exchange Cost"     -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Max Message Size"  -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Sites"             -Value $DataField[5] -Force
        $AdSiteLinks += $Data
	}
}
#endregion Get-SiteLinks

Write-Host "---- Populating Exchange Server"
#region Get-ExchangeServer
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_ExchangeSvr.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_ExchangeSvr.txt")
	$ExchangeServers = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                   	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Edition"                	-Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Admin Display Version"	-Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Site"                   	-Value $DataField[11] -Force
        $ExchangeServers += $Data
	}
}
#endregion Get-ExchangeServers

Write-Host "---- Populating Accepted Domain"
#region Get-AcceptedDomain
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AcceptedDomain.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AcceptedDomain.txt")
	$AcceptedDomain = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Domain Name"     -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Domain Type"     -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Default"        	-Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Name"           	-Value $DataField[3] -Force
        $AcceptedDomain += $Data
	}
}
#endregion Get-ExchangeServers

Write-Host "---- Populating Remote Domain"
#region Get-RemoteDomain
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_RemoteDomain.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_RemoteDomain.txt")
	$RemoteDomain = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Identity"                              	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Domain Name"                            	-Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Allowed OOF Type"                        -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Auto Forward Enabled"                    -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Auto Reply Enabled"                      -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "Delivery Report Enabled"                 -Value $DataField[8] -Force
        $Data | Add-Member NoteProperty -Name "Meeting Forward Notification Enabled" 	-Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "NDR Enabled"                            	-Value $DataField[10] -Force
        $Data | Add-Member NoteProperty -Name "Display Sender Name"                     -Value $DataField[11] -Force
        $Data | Add-Member NoteProperty -Name "Character Set"                          	-Value $DataField[12] -Force
        $Data | Add-Member NoteProperty -Name "NonMime Character Set"                   -Value $DataField[13] -Force
        $Data | Add-Member NoteProperty -Name "Content Type"                           	-Value $DataField[14] -Force
        $Data | Add-Member NoteProperty -Name "TNEF Enabled"                           	-Value $DataField[15] -Force
        $Data | Add-Member NoteProperty -Name "Line Wrap Size"                          -Value $DataField[16] -Force
        $Data | Add-Member NoteProperty -Name "Use Simple Display Name"                 -Value $DataField[17] -Force
        $RemoteDomain += $Data
	}
}
#endregion Get-RemoteDomain

Write-Host "---- Populating Availabilty"
#region Get-AvailabilityAddressSpace
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AvailabilityAddressSpace.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AvailabilityAddressSpace.txt")
	$Availability = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                      	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Forest Name"                 -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "User Name"                   -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Use Service Account"         -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Access Method"               -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Proxy Url"                   -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Target Autodiscover Epr"     -Value $DataField[6] -Force
        $Availability += $Data
	}
}
#endregion Get-AvailabilityAddressSpace

Write-Host "---- Populating Transport Config"
#region Get-TransportConfig - Vertical Format
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_TransportConfig.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_TransportConfig.txt")
	$Transport = @()
	#Vertical Format
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "AdminDisplayName"                      -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "ClearCategories"                       -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "ConvertDisclaimerWrapperToEml"         -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "ConvertReportToMessage"                -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "DSNConversionMode"                     -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "ExternalDelayDsnEnabled"               -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "ExternalDsnDefaultLanguage"            -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "ExternalDsnLanguageDetectionEnabled"   -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "ExternalDsnMaxMessageAttachSize"       -Value $DataField[8] -Force
        $Data | Add-Member NoteProperty -Name "ExternalDsnReportingAuthority"         -Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "ExternalDsnSendHtml"                   -Value $DataField[10] -Force
        $Data | Add-Member NoteProperty -Name "ExternalPostmasterAddress"             -Value $DataField[11] -Force
        $Data | Add-Member NoteProperty -Name "GenerateCopyOfDSNFor"                  -Value $DataField[12] -Force
        $Data | Add-Member NoteProperty -Name "Guid"                                  -Value $DataField[13] -Force
        $Data | Add-Member NoteProperty -Name "HeaderPromotionModeSetting"            -Value $DataField[14] -Force
        $Data | Add-Member NoteProperty -Name "HygieneSuite"                          -Value $DataField[15] -Force
        $Data | Add-Member NoteProperty -Name "Identity"                              -Value $DataField[16] -Force
        $Data | Add-Member NoteProperty -Name "InternalDelayDsnEnabled"               -Value $DataField[17] -Force
        $Data | Add-Member NoteProperty -Name "InternalDsnDefaultLanguage"            -Value $DataField[18] -Force
        $Data | Add-Member NoteProperty -Name "InternalDsnLanguageDetectionEnabled"   -Value $DataField[19] -Force
        $Data | Add-Member NoteProperty -Name "InternalDsnMaxMessageAttachSize"       -Value $DataField[20] -Force
        $Data | Add-Member NoteProperty -Name "InternalDsnReportingAuthority"         -Value $DataField[21] -Force
        $Data | Add-Member NoteProperty -Name "InternalDsnSendHtml"                   -Value $DataField[22] -Force
        $Data | Add-Member NoteProperty -Name "InternalSMTPServers"                   -Value $DataField[23] -Force
        $Data | Add-Member NoteProperty -Name "JournalingReportNdrTo"                 -Value $DataField[24] -Force
        $Data | Add-Member NoteProperty -Name "LegacyJournalingMigrationEnabled"      -Value $DataField[25] -Force
        $Data | Add-Member NoteProperty -Name "MaxDumpsterSizePerDatabase"            -Value $DataField[26] -Force
        $Data | Add-Member NoteProperty -Name "MaxDumpsterTime"                       -Value $DataField[27] -Force
        $Data | Add-Member NoteProperty -Name "MaxReceiveSize"                        -Value $DataField[28] -Force
        $Data | Add-Member NoteProperty -Name "MaxRecipientEnvelopeLimit"             -Value $DataField[29] -Force
        $Data | Add-Member NoteProperty -Name "MaxSendSize"                           -Value $DataField[30] -Force
        $Data | Add-Member NoteProperty -Name "MigrationEnabled"                      -Value $DataField[31] -Force
        $Data | Add-Member NoteProperty -Name "OpenDomainRoutingEnabled"              -Value $DataField[32] -Force
        $Data | Add-Member NoteProperty -Name "OrganizationFederatedMailbox"          -Value $DataField[33] -Force
        $Data | Add-Member NoteProperty -Name "OrganizationId"                        -Value $DataField[34] -Force
        $Data | Add-Member NoteProperty -Name "OriginatingServer"                     -Value $DataField[35] -Force
        $Data | Add-Member NoteProperty -Name "OtherWellKnownObjects"                 -Value $DataField[36] -Force
        $Data | Add-Member NoteProperty -Name "PreserveReportBodypart"                -Value $DataField[37] -Force
        $Data | Add-Member NoteProperty -Name "Rfc2231EncodingEnabled"                -Value $DataField[38] -Force
        $Data | Add-Member NoteProperty -Name "ShadowHeartbeatRetryCount"             -Value $DataField[29] -Force
        $Data | Add-Member NoteProperty -Name "ShadowHeartbeatTimeoutInterval"        -Value $DataField[40] -Force
        $Data | Add-Member NoteProperty -Name "ShadowMessageAutoDiscardInterval"      -Value $DataField[41] -Force
        $Data | Add-Member NoteProperty -Name "ShadowRedundancyEnabled"               -Value $DataField[42] -Force
        $Data | Add-Member NoteProperty -Name "SupervisionTags"                       -Value $DataField[43] -Force
        $Data | Add-Member NoteProperty -Name "TLSReceiveDomainSecureList"            -Value $DataField[44] -Force
        $Data | Add-Member NoteProperty -Name "TLSSendDomainSecureList"               -Value $DataField[45] -Force
        $Data | Add-Member NoteProperty -Name "VerifySecureSubmitEnabled"             -Value $DataField[46] -Force
        $Data | Add-Member NoteProperty -Name "VoicemailJournalingEnabled"            -Value $DataField[47] -Force
        $Data | Add-Member NoteProperty -Name "WhenChangedUTC"                        -Value $DataField[48] -Force
        #$Data | Add-Member NoteProperty -Name "WhenCreatedUTC"                        -Value $DataField[49] -Force
        $Data | Add-Member NoteProperty -Name "Xexch50Enabled"                        -Value $DataField[50] -Force
        $Transport += $Data
	}
}
#endregion Get-TransportConfig - Vertical Format

Write-Host "---- Populating Exchange Roles"
#region Get-ExchangeRoles
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_ExchangeSvr.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_ExchangeSvr.txt")
	$Roles = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                      -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "ServerRole"                -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "AdminDisplayVersion"       -Value $DataField[6] -Force
        $Roles += $Data
	}
}
#endregion Get-ExchangeRoles

Write-Host "---- Populating Rollups"
#region Get-Rollups
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_Misc_ExchangeBuilds.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_Misc_ExchangeBuilds.txt")
	$Rollups = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Build Number"       	-Value $DataField[1] -Force
        $Rollups += $Data
	}
}
#endregion Get-Rollups

Write-Host "---- Populating from Mailbox Database files"
#region Get-MbxDb
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetMbxDb") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetMbxDb" | Where-Object {$_.name -match "~~GetMbxDb"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetMbxDb\" + $file)
	}
	$Journal = @()
	$Retention = @()
	$Quota = @()
	$MbxDb = @()
	$MailboxCount = @()
	Foreach ($DataRow in $DataFile)
	{
		$JournalData = New-Object PSObject
		$RetentionData = New-Object PSObject
		$QuotaData = New-Object PSObject
		$MbxDbData = New-Object PSObject
		$MailboxCountData = New-Object PSObject

        $DataField = $DataRow.Split("`t")

        $JournalData | Add-Member NoteProperty -Name "ServerName"                   -Value $DataField[0] -Force
        $JournalData | Add-Member NoteProperty -Name "Name"                         -Value $DataField[1] -Force
        $JournalData | Add-Member NoteProperty -Name "JournalRecipient"             -Value $DataField[43] -Force

        $RetentionData | Add-Member NoteProperty -Name "ServerName"                 -Value $DataField[0] -Force
        $RetentionData | Add-Member NoteProperty -Name "Name"                       -Value $DataField[1] -Force
        $RetentionData | Add-Member NoteProperty -Name "MailboxRetention"           -Value $DataField[19] -Force
        $RetentionData | Add-Member NoteProperty -Name "DeletedItemRetention"       -Value $DataField[20] -Force

        $QuotaData | Add-Member NoteProperty -Name "Server Name"                    -Value $DataField[0] -Force
        $QuotaData | Add-Member NoteProperty -Name "Name"                           -Value $DataField[1] -Force
        $QuotaData | Add-Member NoteProperty -Name "Issue Warning Quota"            -Value $DataField[8] -Force
        $QuotaData | Add-Member NoteProperty -Name "Prohibit Send Quota"            -Value $DataField[9] -Force
        $QuotaData | Add-Member NoteProperty -Name "Prohibit SendReceive Quota"     -Value $DataField[10] -Force

        $MbxDbData | Add-Member NoteProperty -Name "ServerName"                     -Value $DataField[0] -Force
        $MbxDbData | Add-Member NoteProperty -Name "Name"                           -Value $DataField[1] -Force
        $MbxDbData | Add-Member NoteProperty -Name "EdbFilePath"                    -Value $DataField[3] -Force
        $MbxDbData | Add-Member NoteProperty -Name "LogFolderPath"                  -Value $DataField[4] -Force
        $MbxDbData | Add-Member NoteProperty -Name "Circular Logging Enabled"       -Value $DataField[24] -Force

        $MailboxCountData | Add-Member NoteProperty -Name "ServerName" 			    -Value $DataField[0] -Force
        $MailboxCountData | Add-Member NoteProperty -Name "Database Name"           -Value $DataField[1] -Force
        $MailboxCountData | Add-Member NoteProperty -Name "Mailbox Count"           -Value $DataField[30] -Force

        $Journal += $JournalData
        $Retention += $RetentionData
        $Quota += $QuotaData
        $MbxDb += $MbxDbData
        $MailboxCount += $MailboxCountData
	}
}
#endregion Get-Get-MbxDb

Write-Host "---- Populating SCP"
#region Get-SCP
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_ClientAccessSvr.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_ClientAccessSvr.txt")
	$Scp = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                                 	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Outlook Anywhere Enabled"               	-Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "AutoDiscover Service InternalUri"       	-Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "AutoDiscover SiteScope"                	-Value $DataField[5] -Force
        $Scp += $Data
	}
}
#endregion Get-SCP

Write-Host "---- Populating OWA VDir"
#region Get-OwaVdir
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetOWAVirtualDirectory") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetOWAVirtualDirectory" | Where-Object {$_.name -match "~~GetOWAVirtualDirectory"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetOWAVirtualDirectory\" + $file)
	}
	$OwaVdir = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Server"                               	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Name"                                 	-Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Basic Authentication"                  	-Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Digest Authentication"                 	-Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Forms Authentication"                  	-Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "Windows Authentication"                	-Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Internalurl"                          	-Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "Externalurl"                          	-Value $DataField[11] -Force
        $OwaVdir += $Data
	}
}
#endregion Get-OwaVdir

Write-Host "---- Populating OAB Vdir"
#region Get-OabVdir
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetOABVirtualDirectory") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetOABVirtualDirectory" | Where-Object {$_.name -match "~~GetOABVirtualDirectory"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetOABVirtualDirectory\" + $file)
	}
	$OabVdir = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Server"                             	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Name"                               	-Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Basic Authentication"                -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Windows Authentication"              -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Internalurl"                        	-Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "Externalurl"                        	-Value $DataField[9] -Force
        $OabVdir += $Data
	}
}
#endregion Get-OabVdir

Write-Host "---- Populating WebServices Vdir"
#region Get-WebServicesVdir
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetWebServicesVirtualDirectory") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetWebServicesVirtualDirectory" | Where-Object {$_.name -match "~~GetWebServicesVirtualDirectory"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetWebServicesVirtualDirectory\" + $file)
	}
	$EwsVdir = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Server"                           	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Name"                             	-Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Basic Authentication"              	-Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Digest Authentication"             	-Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Windows Authentication"            	-Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Internalurl"                      	-Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "Externalurl"                      	-Value $DataField[9] -Force
        $EwsVdir += $Data
	}
}
#endregion Get-WebServicesVdir

Write-Host "---- Populating ActiveSync Vdir"
#region Get-ActiveSyncVdir
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetActiveSyncVirtualDirectory") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetActiveSyncVirtualDirectory" | Where-Object {$_.name -match "~~GetActiveSyncVirtualDirectory"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetActiveSyncVirtualDirectory\" + $file)
	}
	$ActiveSyncVdir = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Server"                         	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Name"                           	-Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "BasicAuth Enabled"               -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "WindowsAuth Enabled"             -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "ClientCert Auth"                 -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "Internalurl"                    	-Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "Externalurl"                    	-Value $DataField[11] -Force
        $ActiveSyncVdir += $Data
	}
}
#endregion Get-ActiveSyncVdir

Write-Host "---- Populating Autodiscover Vdir"
#region Get-AutodiscoverVdir
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetAutoDiscoverVirtualDirectory") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetAutoDiscoverVirtualDirectory" | Where-Object {$_.name -match "~~GetAutoDiscoverVirtualDirectory"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetAutoDiscoverVirtualDirectory\" + $file)
	}
	$AutodiscoverVdir = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Server"                       	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Name"                         	-Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Basic Authentication"          	-Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Digest Authentication"         	-Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Windows Authentication"        	-Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Internalurl"                  	-Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "Externalurl"                  	-Value $DataField[9] -Force
        $AutodiscoverVdir += $Data
	}
}
#endregion Get-AutodiscoverVdir

Write-Host "---- Populating ECP Vdir"
#region Get-EcpVdir
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetECPVirtualDirectory") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetECPVirtualDirectory" | Where-Object {$_.name -match "~~GetECPVirtualDirectory"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetECPVirtualDirectory\" + $file)
	}
	$EcpVdir = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Server"                     	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Name"                       	-Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Basic Authentication"        -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Digest Authentication"       -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Forms Authentication"        -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Windows Authentication"      -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "Internalurl"                	-Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "Externalurl"                	-Value $DataField[11] -Force
        $EcpVdir += $Data
	}
}
#endregion Get-EcpVdir

Write-Host "---- Populating Outlook Anywhere"
#regionGet-OutlookAnywhere
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_OutlookAnywhere.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_OutlookAnywhere.txt")
	$OutlookAnywhere = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "ServerName"                              -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "External Hostname"                       -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Internal Hostname"                       -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Client Authentication Method (Ex2010)"   -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Internal Client Authentication Method"   -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "External Client Authentication Method"   -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "IIS Authentication Methods"              -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "ExchangeVersion"                         -Value $DataField[9] -Force
        $OutlookAnywhere += $Data
	}
}
#endregion Get-OutlookAnywhere

Write-Host "---- Populating Client Access Array"
#region Get-ClientAccessArray
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_ClientAccessArray.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_ClientAccessArray.txt")
	$CasArray = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                             -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Fqdn"                             -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Site"                             -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Members"                          -Value $DataField[4] -Force
        $CasArray += $Data
	}
}
#endregion Get-ClientAccessArray

Write-Host "---- Populating DAG Network"
#region Get-DatabaseAvailabilityGroupNetwork
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_DatabaseAvailabilityGroupNetwork.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_DatabaseAvailabilityGroupNetwork.txt")
	$DagNetwork = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Subnets"                             -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Interfaces"                          -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Mapi Access Enabled"                 -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Replication Enabled"                 -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Ignore Network"                      -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Identity"                            -Value $DataField[6] -Force
        $DagNetwork += $Data
	}
}
#endregion Get-DatabaseAvailabilityGroupNetwork

Write-Host "---- Populating DAG"
#region Get-DatabaseAvailabilityGroup
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_Dag.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_Dag.txt")
	$Dag = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                                    -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Witness Server"                          -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Witness Directory"                       -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Alternate Witness Server"                -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Alternate Witness Directory"             -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Datacenter Activation Mode"              -Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "AutoDag Database Copies Per Volume"      -Value $DataField[10] -Force
        $Data | Add-Member NoteProperty -Name "AutoDag Database Copies Per Database"    -Value $DataField[11] -Force
        $Data | Add-Member NoteProperty -Name "AutoDag Databases Root Folder Path"      -Value $DataField[12] -Force
        $Data | Add-Member NoteProperty -Name "AutoDag Volumes Root Folder Path"        -Value $DataField[13] -Force
        $Data | Add-Member NoteProperty -Name "Stopped Mailbox Servers"                 -Value $DataField[14] -Force
        $Dag += $Data
	}
}
#endregion Get-DatabaseAvailabilityGroup

Write-Host "---- Populating Database Copy Status"
#region Get-MailboxDatabaseCopyStatus
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetMbxDatabaseCopyStatus") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetMbxDatabaseCopyStatus" | Where-Object {$_.name -match "~~GetMbxDatabaseCopyStatus"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetMbxDatabaseCopyStatus\" + $file)
	}
	$DagDistribution = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Mailbox Server"                               -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Database Name"                                -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Active Database Copy"                         -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Incoming Log Copying Network"                 -Value $DataField[13] -Force
        $Data | Add-Member NoteProperty -Name "Seeding Network"                              -Value $DataField[14] -Force
        $Data | Add-Member NoteProperty -Name "Activation Preference"                        -Value $DataField[15] -Force
        $Data | Add-Member NoteProperty -Name "AutoActivation Policy"                        -Value $DataField[17] -Force
        $DagDistribution += $Data
	}
}
#endregion Get-MailboxDatabaseCopyStatus

Write-Host "---- Populating Receive Connector"
#region Get-ReceiveConnector
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_ReceiveConnector.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_ReceiveConnector.txt")
	$ReceiveConnector = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Server"                	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Name"                  	-Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Enabled"               	-Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Max Message Size"        -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Permission Groups"      	-Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "Remote IP Ranges"        -Value $DataField[10] -Force
        $ReceiveConnector += $Data
	}
}
#endregion Get-ReceiveConnector

Write-Host "---- Populating Send Connector"
#region Get-SendConnector
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_SendConnector.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_SendConnector.txt")
	$SendConnector = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                                -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Enabled"                             -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Address Spaces"                      -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Is Smtp Connector"                   -Value $DataField[10] -Force
        $Data | Add-Member NoteProperty -Name "Max Message Size"                    -Value $DataField[11] -Force
        $Data | Add-Member NoteProperty -Name "Port"                                -Value $DataField[12] -Force
        $Data | Add-Member NoteProperty -Name "Smart Host Auth Mechanism"           -Value $DataField[15] -Force
        $Data | Add-Member NoteProperty -Name "Smart Hosts"                         -Value $DataField[16] -Force
        $Data | Add-Member NoteProperty -Name "Source Transport Servers"            -Value $DataField[19] -Force
        $SendConnector += $Data
	}
}
#endregion Get-SendConnector

Write-Host "---- Populating Transport Rule"
#region Get-TransportRule
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_TransportRule.xml") -eq $true)
{
	$DataFile = Import-Clixml "$RunLocation\output\Exchange\Exchange_TransportRule.xml"
	$TransportRule = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $Data | Add-Member NoteProperty -Name "Identity" 		-Value $([string]$DataRow.Identity) -Force
        $Data | Add-Member NoteProperty -Name "Priority"        -Value $([string]$DataRow.Priority) -Force
        $Data | Add-Member NoteProperty -Name "Comments"        -Value $([string]$DataRow.Comments) -Force
        $Data | Add-Member NoteProperty -Name "Description"     -Value $([string]$DataRow.Description) -Force
        $Data | Add-Member NoteProperty -Name "Rule Version"    -Value $([string]$DataRow.RuleVersion) -Force
        $Data | Add-Member NoteProperty -Name "State"           -Value $([string]$DataRow.State) -Force
	    $TransportRule += $Data
    }
}


#endregion Get-TransportRule

Write-Host "---- Populating Address List"
#region Get-AddressList
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AddressList.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AddressList.txt")
	$AddressList = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Display Name"                        -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Path"                                -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Recipient Filter"                    -Value $DataField[2] -Force
        $AddressList += $Data
	}
}
#endregion Get-AddressList

Write-Host "---- Populating OAB"
#region Get-OfflineAddressBook
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_OfflineAddressBook.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_OfflineAddressBook.txt")
	$Oab = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                                    -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Server"                                  -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "AddressLists"                            -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Versions"                                -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "IsDefault"                               -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Public Folder Database"                  -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Public Folder Distribution Enabled"      -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "Web Distribution Enabled"                -Value $DataField[8] -Force
        $Data | Add-Member NoteProperty -Name "Virtual Directories"                     -Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "Schedule"                                -Value $DataField[10] -Force
        $Oab += $Data
	}
}
#endregion Get-OfflineAddressBook

Write-Host "---- Populating Retention Policy"
#region Get-RetentionPolicy
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_RetentionPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_RetentionPolicy.txt")
	$RetentionPolicy = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                                -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "RetentionPolicyTagLinks"             -Value $DataField[1] -Force
        $RetentionPolicy += $Data
	}
}
#endregion Get-RetentionPolicy

Write-Host "---- Populating Retention Policy Tag"
#region Get-RetentionPolicyTag
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_RetentionPolicyTag.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_RetentionPolicyTag.txt")
	$RetentionPolicyTag = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                        	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Message Class Display Name"      -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Message Class"                   -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Retention Enabled"               -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Retention Action"                -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Age Limit For Retention"         -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Move To Destination Folder"      -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Trigger For Retention"           -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "Type"                            -Value $DataField[8] -Force
        $RetentionPolicyTag += $Data
	}
}
#endregion Get-RetentionPolicyTag

Write-Host "---- Populating Email Address Policy"
#region Get-EmailAddressPolicy
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_EmailAddressPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_EmailAddressPolicy.txt")
	$EmailAddressPolicy = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                                 -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "IsValid"                              -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "RecipientFilter"                      -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "LdapRecipientFilter"                  -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "LastUpdatedRecipientFilter"           -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "RecipientFilterApplied"               -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "IncludedRecipients"                   -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalDepartment"                -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCompany"                   -Value $DataField[8] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalStateOrProvince"           -Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute1"          -Value $DataField[10] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute2"          -Value $DataField[11] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute3"          -Value $DataField[12] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute4"          -Value $DataField[13] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute5"          -Value $DataField[14] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute6"          -Value $DataField[15] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute7"          -Value $DataField[16] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute8"          -Value $DataField[17] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute9"          -Value $DataField[18] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute10"         -Value $DataField[19] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute11"         -Value $DataField[20] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute12"         -Value $DataField[21] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute13"         -Value $DataField[22] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute14"         -Value $DataField[23] -Force
        $Data | Add-Member NoteProperty -Name "ConditionalCustomAttribute15"         -Value $DataField[24] -Force
        $Data | Add-Member NoteProperty -Name "RecipientContainer"                   -Value $DataField[25] -Force
        $Data | Add-Member NoteProperty -Name "RecipientFilterType"                  -Value $DataField[26] -Force
        $Data | Add-Member NoteProperty -Name "Priority"                             -Value $DataField[27] -Force
        $Data | Add-Member NoteProperty -Name "EnabledPrimarySMTPAddressTemplate"    -Value $DataField[28] -Force
        $Data | Add-Member NoteProperty -Name "EnabledEmailAddressTemplates"         -Value $DataField[29] -Force
        $Data | Add-Member NoteProperty -Name "DisabledEmailAddressTemplates"        -Value $DataField[30] -Force
        $Data | Add-Member NoteProperty -Name "HasEmailAddressSetting"               -Value $DataField[31] -Force
        $Data | Add-Member NoteProperty -Name "HasMailboxManagerSetting"             -Value $DataField[32] -Force
        $Data | Add-Member NoteProperty -Name "NonAuthoritativeDomains"              -Value $DataField[33] -Force
        $Data | Add-Member NoteProperty -Name "ExchangeVersion"                      -Value $DataField[34] -Force
        $EmailAddressPolicy += $Data
	}
}
#endregion Get-EmailAddressPolicy

Write-Host "---- Populating Address Book Policy"
#region Get-AddressBookPolicy
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AddressBookPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AddressBookPolicy.txt")
	$AddressBookPolicy = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                                 -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "AddressLists"                         -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "GlobalAddressList"                    -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "RoomList"                             -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "OfflineAddressBook"                   -Value $DataField[4] -Force
        $AddressBookPolicy += $Data
	}
}
#endregion Get-AddressBookPolicy

Write-Host "---- Populating ActiveSync Mailbox Policy"
#region Get-ActiveSyncMbxPolicy
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_ActiveSyncMbxPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_ActiveSyncMbxPolicy.txt")
	$ActiveSyncMailboxPolicy = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                                       -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "AllowNonProvisionableDevices"               -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "AlphanumericPasswordRequired"               -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "AttachmentsEnabled"                         -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "DeviceEncryptionEnabled"                    -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "RequireStorageCardEncryption"               -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "DevicePasswordEnabled"                      -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "PasswordRecoveryEnabled"                    -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "DevicePolicyRefreshInterval"                -Value $DataField[8] -Force
        $Data | Add-Member NoteProperty -Name "AllowSimpleDevicePassword"                  -Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "MaxAttachmentSize"                          -Value $DataField[10] -Force
        $Data | Add-Member NoteProperty -Name "WSSAccessEnabled"                           -Value $DataField[11] -Force
        $Data | Add-Member NoteProperty -Name "UNCAccessEnabled"                           -Value $DataField[12] -Force
        $Data | Add-Member NoteProperty -Name "MinDevicePasswordLength"                    -Value $DataField[13] -Force
        $Data | Add-Member NoteProperty -Name "MaxInactivityTimeDeviceLock"                -Value $DataField[14] -Force
        $Data | Add-Member NoteProperty -Name "MaxDevicePasswordFailedAttempts"            -Value $DataField[15] -Force
        $Data | Add-Member NoteProperty -Name "DevicePasswordExpiration"                   -Value $DataField[16] -Force
        $Data | Add-Member NoteProperty -Name "DevicePasswordHistory"                      -Value $DataField[17] -Force
        $Data | Add-Member NoteProperty -Name "IsDefaultPolicy"                            -Value $DataField[18] -Force
        $Data | Add-Member NoteProperty -Name "AllowApplePushNotifications"                -Value $DataField[19] -Force
        $Data | Add-Member NoteProperty -Name "AllowMicrosoftPushNotifications"            -Value $DataField[20] -Force
        $Data | Add-Member NoteProperty -Name "AllowStorageCard"                           -Value $DataField[21] -Force
        $Data | Add-Member NoteProperty -Name "AllowCamera"                                -Value $DataField[22] -Force
        $Data | Add-Member NoteProperty -Name "RequireDeviceEncryption"                    -Value $DataField[23] -Force
        $Data | Add-Member NoteProperty -Name "AllowUnsignedApplications"                  -Value $DataField[24] -Force
        $Data | Add-Member NoteProperty -Name "AllowUnsignedInstallationPackages"          -Value $DataField[25] -Force
        $Data | Add-Member NoteProperty -Name "AllowWiFi"                                  -Value $DataField[26] -Force
        $Data | Add-Member NoteProperty -Name "AllowTextMessaging"                         -Value $DataField[27] -Force
        $Data | Add-Member NoteProperty -Name "AllowPOPIMAPEmail"                          -Value $DataField[28] -Force
        $Data | Add-Member NoteProperty -Name "AllowIrDA"                                  -Value $DataField[29] -Force
        $Data | Add-Member NoteProperty -Name "RequireManualSyncWhenRoaming"               -Value $DataField[30] -Force
        $Data | Add-Member NoteProperty -Name "AllowDesktopSync"                           -Value $DataField[31] -Force
        $Data | Add-Member NoteProperty -Name "AllowHTMLEmail"                             -Value $DataField[32] -Force
        $Data | Add-Member NoteProperty -Name "RequireSignedSMIMEMessages"                 -Value $DataField[33] -Force
        $Data | Add-Member NoteProperty -Name "RequireEncryptedSMIMEMessages"              -Value $DataField[34] -Force
        $Data | Add-Member NoteProperty -Name "AllowSMIMESoftCerts"                        -Value $DataField[35] -Force
        $Data | Add-Member NoteProperty -Name "AllowBrowser"                               -Value $DataField[36] -Force
        $Data | Add-Member NoteProperty -Name "AllowConsumerEmail"                         -Value $DataField[37] -Force
        $Data | Add-Member NoteProperty -Name "AllowRemoteDesktop"                         -Value $DataField[38] -Force
        $Data | Add-Member NoteProperty -Name "AllowInternetSharing"                       -Value $DataField[39] -Force
        $Data | Add-Member NoteProperty -Name "AllowBluetooth"                             -Value $DataField[40] -Force
        $Data | Add-Member NoteProperty -Name "MaxCalendarAgeFilter"                       -Value $DataField[41] -Force
        $Data | Add-Member NoteProperty -Name "MaxEmailAgeFilter"                          -Value $DataField[42] -Force
        $Data | Add-Member NoteProperty -Name "RequireSignedSMIMEAlgorithm"                -Value $DataField[43] -Force
        $Data | Add-Member NoteProperty -Name "RequireEncryptionSMIMEAlgorithm"            -Value $DataField[44] -Force
        $Data | Add-Member NoteProperty -Name "AllowSMIMEEncryptionAlgorithmNegotiation"   -Value $DataField[45] -Force
        $Data | Add-Member NoteProperty -Name "MinDevicePasswordComplexCharacters"         -Value $DataField[46] -Force
        $Data | Add-Member NoteProperty -Name "MaxEmailBodyTruncationSize"                 -Value $DataField[47] -Force
        $Data | Add-Member NoteProperty -Name "MaxEmailHTMLBodyTruncationSize"             -Value $DataField[48] -Force
        $Data | Add-Member NoteProperty -Name "UnapprovedInROMApplicationList"             -Value $DataField[49] -Force
        $Data | Add-Member NoteProperty -Name "ApprovedApplicationList"                    -Value $DataField[50] -Force
        $Data | Add-Member NoteProperty -Name "AllowExternalDeviceManagement"              -Value $DataField[51] -Force
        $Data | Add-Member NoteProperty -Name "MobileOTAUpdateMode"                        -Value $DataField[52] -Force
        $Data | Add-Member NoteProperty -Name "AllowMobileOTAUpdate"                       -Value $DataField[53] -Force
        $Data | Add-Member NoteProperty -Name "IrmEnabled"                                 -Value $DataField[54] -Force
        $ActiveSyncMailboxPolicy += $Data
	}
}
#endregion Get-ActiveSyncMbxPolicy

Write-Host "---- Populating OWA Mailbox Policy"
#region Get-OwaMailboxPolicy
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_OwaMailboxPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_OwaMailboxPolicy.txt")
	$OwaMailboxPolicy = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                                                  -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "DirectFileAccessOnPublicComputersEnabled"              -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "DirectFileAccessOnPrivateComputersEnabled"             -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "WebReadyDocumentViewingOnPublicComputersEnabled"       -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "WebReadyDocumentViewingOnPrivateComputersEnabled"      -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "ForceWebReadyDocumentViewingFirstOnPublicComputers"    -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "ForceWebReadyDocumentViewingFirstOnPrivateComputers"   -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "ActionForUnknownFileAndMIMETypes"                      -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "WebReadyDocumentViewingForAllSupportedTypes"           -Value $DataField[8] -Force
        $Data | Add-Member NoteProperty -Name "PhoneticSupportEnabled"                                -Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "DefaultTheme"                                          -Value $DataField[10] -Force
        $Data | Add-Member NoteProperty -Name "DefaultClientLanguage"                                 -Value $DataField[11] -Force
        $Data | Add-Member NoteProperty -Name "LogonAndErrorLanguage"                                 -Value $DataField[12] -Force
        $Data | Add-Member NoteProperty -Name "UseGB18030"                                            -Value $DataField[13] -Force
        $Data | Add-Member NoteProperty -Name "UseISO885915"                                          -Value $DataField[14] -Force
        $Data | Add-Member NoteProperty -Name "OutboundCharset"                                       -Value $DataField[15] -Force
        $Data | Add-Member NoteProperty -Name "GlobalAddressListEnabled"                              -Value $DataField[16] -Force
        $Data | Add-Member NoteProperty -Name "OrganizationEnabled"                                   -Value $DataField[17] -Force
        $Data | Add-Member NoteProperty -Name "ExplicitLogonEnabled"                                  -Value $DataField[18] -Force
        $Data | Add-Member NoteProperty -Name "OWALightEnabled"                                       -Value $DataField[19] -Force
        $Data | Add-Member NoteProperty -Name "OWAMiniEnabled"                                        -Value $DataField[20] -Force
        $Data | Add-Member NoteProperty -Name "DelegateAccessEnabled"                                 -Value $DataField[21] -Force
        $Data | Add-Member NoteProperty -Name "IRMEnabled"                                            -Value $DataField[22] -Force
        $Data | Add-Member NoteProperty -Name "CalendarEnabled"                                       -Value $DataField[23] -Force
        $Data | Add-Member NoteProperty -Name "ContactsEnabled"                                       -Value $DataField[24] -Force
        $Data | Add-Member NoteProperty -Name "TasksEnabled"                                          -Value $DataField[25] -Force
        $Data | Add-Member NoteProperty -Name "JournalEnabled"                                        -Value $DataField[26] -Force
        $Data | Add-Member NoteProperty -Name "NotesEnabled"                                          -Value $DataField[27] -Force
        $Data | Add-Member NoteProperty -Name "RemindersAndNotificationsEnabled"                      -Value $DataField[28] -Force
        $Data | Add-Member NoteProperty -Name "PremiumClientEnabled"                                  -Value $DataField[29] -Force
        $Data | Add-Member NoteProperty -Name "SpellCheckerEnabled"                                   -Value $DataField[30] -Force
        $Data | Add-Member NoteProperty -Name "SearchFoldersEnabled"                                  -Value $DataField[31] -Force
        $Data | Add-Member NoteProperty -Name "SignaturesEnabled"                                     -Value $DataField[32] -Force
        $Data | Add-Member NoteProperty -Name "ThemeSelectionEnabled"                                 -Value $DataField[33] -Force
        $Data | Add-Member NoteProperty -Name "JunkEmailEnabled"                                      -Value $DataField[34] -Force
        $Data | Add-Member NoteProperty -Name "UMIntegrationEnabled"                                  -Value $DataField[35] -Force
        $Data | Add-Member NoteProperty -Name "WSSAccessOnPublicComputersEnabled"                     -Value $DataField[36] -Force
        $Data | Add-Member NoteProperty -Name "WSSAccessOnPrivateComputersEnabled"                    -Value $DataField[37] -Force
        $Data | Add-Member NoteProperty -Name "ChangePasswordEnabled"                                 -Value $DataField[38] -Force
        $Data | Add-Member NoteProperty -Name "UNCAccessOnPublicComputersEnabled"                     -Value $DataField[39] -Force
        $Data | Add-Member NoteProperty -Name "UNCAccessOnPrivateComputersEnabled"                    -Value $DataField[40] -Force
        $Data | Add-Member NoteProperty -Name "ActiveSyncIntegrationEnabled"                          -Value $DataField[41] -Force
        $Data | Add-Member NoteProperty -Name "AllAddressListsEnabled"                                -Value $DataField[42] -Force
        $Data | Add-Member NoteProperty -Name "RulesEnabled"                                          -Value $DataField[43] -Force
        $Data | Add-Member NoteProperty -Name "PublicFoldersEnabled"                                  -Value $DataField[44] -Force
        $Data | Add-Member NoteProperty -Name "SMimeEnabled"                                          -Value $DataField[45] -Force
        $Data | Add-Member NoteProperty -Name "RecoverDeletedItemsEnabled"                            -Value $DataField[46] -Force
        $Data | Add-Member NoteProperty -Name "InstantMessagingEnabled"                               -Value $DataField[47] -Force
        $Data | Add-Member NoteProperty -Name "TextMessagingEnabled"                                  -Value $DataField[48] -Force
        $Data | Add-Member NoteProperty -Name "ForceSaveAttachmentFilteringEnabled"                   -Value $DataField[49] -Force
        $Data | Add-Member NoteProperty -Name "SilverlightEnabled"                                    -Value $DataField[50] -Force
        $Data | Add-Member NoteProperty -Name "InstantMessagingType"                                  -Value $DataField[51] -Force
        $OwaMailboxPolicy += $Data
	}
}
#endregion Get-OwaMailboxPolicy

Write-Host "---- Populating RBAC"
#region Get-RBAC
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_Rbac.xml") -eq $true)
{
	$DataFile = Import-Clixml "$RunLocation\output\Exchange\Exchange_Rbac.xml"
	$Rbac = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
		$RbacMembers = @($DataRow.members)
		$RbacRoles = @($DataRow.roles)
		$RbacMemberArray = @()
		$RbacRolesArray = @()
		Foreach ($RbacMember in $RbacMembers)
		{
			$RbacMemberArray += $RbacMember
		}
		Foreach ($RbacRole in $RbacRoles)
		{
			$RbacRolesArray += $RbacRole
		}
        $Data | Add-Member NoteProperty -Name "Role Group Name" 	-Value $DataRow.name -Force
        $Data | Add-Member NoteProperty -Name "Members"             -Value $RbacMemberArray -Force
        $Data | Add-Member NoteProperty -Name "Roles"               -Value $RbacRolesArray -Force
	    $Rbac += $Data

    }
}
#endregion Get-RBAC

Write-Host "---- Populating UM Dial Plan"
#region Get-UmDialPlan
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_UmDialPlan.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_UmDialPlan.txt")
	$UmDialPlan = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                                     -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "NumberOfDigitsInExtension"                -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "LogonFailuresBeforeDisconnect"            -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "AccessTelephoneNumbers"                   -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "FaxEnabled"                               -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "InputFailuresBeforeDisconnect"            -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "OutsideLineAccessCode"                    -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "DialByNamePrimary"                        -Value $DataField[8] -Force
        $Data | Add-Member NoteProperty -Name "DialByNameSecondary"                      -Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "AudioCodec"                               -Value $DataField[10] -Force
        $Data | Add-Member NoteProperty -Name "AvailableLanguages"                       -Value $DataField[11] -Force
        $Data | Add-Member NoteProperty -Name "DefaultLanguage"                          -Value $DataField[12] -Force
        $Data | Add-Member NoteProperty -Name "VoIPSecurity"                             -Value $DataField[13] -Force
        $Data | Add-Member NoteProperty -Name "MaxCallDuration"                          -Value $DataField[14] -Force
        $Data | Add-Member NoteProperty -Name "MaxRecordingDuration"                     -Value $DataField[15] -Force
        $Data | Add-Member NoteProperty -Name "RecordingIdleTimeout"                     -Value $DataField[16] -Force
        $Data | Add-Member NoteProperty -Name "PilotIdentifierList"                      -Value $DataField[17] -Force
        $Data | Add-Member NoteProperty -Name "UMServers"                                -Value $DataField[18] -Force
        $Data | Add-Member NoteProperty -Name "UMMailboxPolicies"                        -Value $DataField[19] -Force
        $Data | Add-Member NoteProperty -Name "UMAutoAttendants"                         -Value $DataField[20] -Force
        $Data | Add-Member NoteProperty -Name "WelcomeGreetingEnabled"                   -Value $DataField[21] -Force
        $Data | Add-Member NoteProperty -Name "AutomaticSpeechRecognitionEnabled"        -Value $DataField[22] -Force
        $Data | Add-Member NoteProperty -Name "PhoneContext"                             -Value $DataField[23] -Force
        $Data | Add-Member NoteProperty -Name "WelcomeGreetingFilename"                  -Value $DataField[24] -Force
        $Data | Add-Member NoteProperty -Name "InfoAnnouncementFilename"                 -Value $DataField[25] -Force
        $Data | Add-Member NoteProperty -Name "OperatorExtension"                        -Value $DataField[26] -Force
        $Data | Add-Member NoteProperty -Name "DefaultOutboundCallingLineId"             -Value $DataField[27] -Force
        $Data | Add-Member NoteProperty -Name "Extension"                                -Value $DataField[28] -Force
        $Data | Add-Member NoteProperty -Name "MatchedNameSelectionMethod"               -Value $DataField[29] -Force
        $Data | Add-Member NoteProperty -Name "InfoAnnouncementEnabled"                  -Value $DataField[30] -Force
        $Data | Add-Member NoteProperty -Name "InternationalAccessCode"                  -Value $DataField[31] -Force
        $Data | Add-Member NoteProperty -Name "NationalNumberPrefix"                     -Value $DataField[32] -Force
        $Data | Add-Member NoteProperty -Name "InCountryOrRegionNumberFormat"            -Value $DataField[33] -Force
        $Data | Add-Member NoteProperty -Name "InternationalNumberFormat"                -Value $DataField[34] -Force
        $Data | Add-Member NoteProperty -Name "CallSomeoneEnabled"                       -Value $DataField[35] -Force
        #$Data | Add-Member NoteProperty -Name "UMIntegrationEnabled"                     -Value $DataField[??] -Force
        $Data | Add-Member NoteProperty -Name "SendVoiceMsgEnabled"                      -Value $DataField[38] -Force
        $Data | Add-Member NoteProperty -Name "UMAutoAttendant"                          -Value $DataField[39] -Force
        $Data | Add-Member NoteProperty -Name "AllowDialPlanSubscribers"                 -Value $DataField[40] -Force
        $Data | Add-Member NoteProperty -Name "AllowExtensions"                          -Value $DataField[41] -Force
        $Data | Add-Member NoteProperty -Name "AllowedInCountryOrRegionGroups"           -Value $DataField[42] -Force
        $Data | Add-Member NoteProperty -Name "AllowedInternationalGroups"               -Value $DataField[43] -Force
        $Data | Add-Member NoteProperty -Name "ConfiguredInCountryOrRegionGroups"        -Value $DataField[44] -Force
        $Data | Add-Member NoteProperty -Name "LegacyPromptPublishingPoint"              -Value $DataField[45] -Force
        $Data | Add-Member NoteProperty -Name "ConfiguredInternationalGroups"            -Value $DataField[46] -Force
        $Data | Add-Member NoteProperty -Name "UMIPGateway"                              -Value $DataField[47] -Force
        $Data | Add-Member NoteProperty -Name "URIType"                                  -Value $DataField[48] -Force
        $Data | Add-Member NoteProperty -Name "SubscriberType"                           -Value $DataField[49] -Force
        $Data | Add-Member NoteProperty -Name "GlobalCallRoutingScheme"                  -Value $DataField[50] -Force
        $Data | Add-Member NoteProperty -Name "TUIPromptEditingEnabled"                  -Value $DataField[51] -Force
        $Data | Add-Member NoteProperty -Name "CallAnsweringRulesEnabled"                -Value $DataField[52] -Force
        $Data | Add-Member NoteProperty -Name "SipResourceIdentifierRequired"            -Value $DataField[53] -Force
        $Data | Add-Member NoteProperty -Name "FDSPollingInterval"                       -Value $DataField[54] -Force
        $Data | Add-Member NoteProperty -Name "EquivalentDialPlanPhoneContexts"          -Value $DataField[55] -Force
        $Data | Add-Member NoteProperty -Name "NumberingPlanFormats"                     -Value $DataField[56] -Force
        $Data | Add-Member NoteProperty -Name "AllowHeuristicADCallingLineIdResolution"  -Value $DataField[57] -Force
        $Data | Add-Member NoteProperty -Name "CountryOrRegionCode"                      -Value $DataField[58] -Force
        $Data | Add-Member NoteProperty -Name "ExchangeVersion"                          -Value $DataField[59] -Force
        $UmDialPlan += $Data
	}
}
#endregion Get-UmDialPlan

Write-Host "---- Populating UM IP Gateway"
#region Get-UmIpGateway
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_UmIpGateway.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_UmIpGateway.txt")
	$UmIpGateway = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                             -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Address"                          -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "OutcallsAllowed"                  -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Status"                           -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Port"                             -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Simulator"                        -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "DelayedSourcePartyInfoEnabled"    -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "MessageWaitingIndicatorAllowed"   -Value $DataField[8] -Force
        $Data | Add-Member NoteProperty -Name "HuntGroups"                       -Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "GlobalCallRoutingScheme"          -Value $DataField[10] -Force
        $Data | Add-Member NoteProperty -Name "ForwardingAddress"                -Value $DataField[11] -Force
        $Data | Add-Member NoteProperty -Name "NumberOfDigitsInExtension"        -Value $DataField[12] -Force
        $UmIpGateway += $Data
	}
}
#endregion Get-Data

Write-Host "---- Populating UM Mailbox Policy"
#region Get-UmMailboxPolicy
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_UmMailboxPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_UmMailboxPolicy.txt")
	$UmMailboxPolicy = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                                         -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "MaxGreetingDuration"                          -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "MaxLogonAttempts"                             -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "AllowCommonPatterns"                          -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "PINLifetime"                                  -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "PINHistoryCount"                              -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "AllowSMSNotification"                         -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "ProtectUnauthenticatedVoiceMail"              -Value $DataField[8] -Force
        $Data | Add-Member NoteProperty -Name "ProtectAuthenticatedVoiceMail"                -Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "ProtectedVoiceMailText"                       -Value $DataField[10] -Force
        $Data | Add-Member NoteProperty -Name "RequireProtectedPlayOnPhone"                  -Value $DataField[11] -Force
        $Data | Add-Member NoteProperty -Name "MinPINLength"                                 -Value $DataField[12] -Force
        $Data | Add-Member NoteProperty -Name "FaxMessageText"                               -Value $DataField[13] -Force
        $Data | Add-Member NoteProperty -Name "UMEnabledText"                                -Value $DataField[14] -Force
        $Data | Add-Member NoteProperty -Name "ResetPINText"                                 -Value $DataField[15] -Force
        $Data | Add-Member NoteProperty -Name "SourceForestPolicyNames"                      -Value $DataField[16] -Force
        $Data | Add-Member NoteProperty -Name "VoiceMailText"                                -Value $DataField[17] -Force
        $Data | Add-Member NoteProperty -Name "UMDialPlan"                                   -Value $DataField[18] -Force
        $Data | Add-Member NoteProperty -Name "FaxServerURI"                                 -Value $DataField[19] -Force
        $Data | Add-Member NoteProperty -Name "AllowedInCountryOrRegionGroups"               -Value $DataField[20] -Force
        $Data | Add-Member NoteProperty -Name "AllowedInternationalGroups"                   -Value $DataField[21] -Force
        $Data | Add-Member NoteProperty -Name "AllowDialPlanSubscribers"                     -Value $DataField[22] -Force
        $Data | Add-Member NoteProperty -Name "AllowExtensions"                              -Value $DataField[23] -Force
        $Data | Add-Member NoteProperty -Name "LogonFailuresBeforePINReset"                  -Value $DataField[24] -Force
        $Data | Add-Member NoteProperty -Name "AllowMissedCallNotifications"                 -Value $DataField[25] -Force
        $Data | Add-Member NoteProperty -Name "AllowFax"                                     -Value $DataField[26] -Force
        $Data | Add-Member NoteProperty -Name "AllowTUIAccessToCalendar"                     -Value $DataField[27] -Force
        $Data | Add-Member NoteProperty -Name "AllowTUIAccessToEmail"                        -Value $DataField[28] -Force
        $Data | Add-Member NoteProperty -Name "AllowSubscriberAccess"                        -Value $DataField[29] -Force
        $Data | Add-Member NoteProperty -Name "AllowTUIAccessToDirectory"                    -Value $DataField[30] -Force
        $Data | Add-Member NoteProperty -Name "AllowTUIAccessToPersonalContacts"             -Value $DataField[31] -Force
        $Data | Add-Member NoteProperty -Name "AllowAutomaticSpeechRecognition"              -Value $DataField[32] -Force
        $Data | Add-Member NoteProperty -Name "AllowPlayOnPhone"                             -Value $DataField[33] -Force
        $Data | Add-Member NoteProperty -Name "AllowVoiceMailPreview"                        -Value $DataField[34] -Force
        $Data | Add-Member NoteProperty -Name "AllowCallAnsweringRules"                      -Value $DataField[35] -Force
        $Data | Add-Member NoteProperty -Name "AllowMessageWaitingIndicator"                 -Value $DataField[36] -Force
        $Data | Add-Member NoteProperty -Name "AllowPinlessVoiceMailAccess"                  -Value $DataField[37] -Force
        $Data | Add-Member NoteProperty -Name "AllowVoiceResponseToOtherMessageTypes"        -Value $DataField[38] -Force
        $Data | Add-Member NoteProperty -Name "AllowVoiceMailAnalysis"                       -Value $DataField[39] -Force
        $Data | Add-Member NoteProperty -Name "AllowVoiceNotification"                       -Value $DataField[40] -Force
        $Data | Add-Member NoteProperty -Name "InformCallerOfVoiceMailAnalysis"              -Value $DataField[41] -Force
        $Data | Add-Member NoteProperty -Name "VoiceMailPreviewPartnerAddress"               -Value $DataField[42] -Force
        $Data | Add-Member NoteProperty -Name "VoiceMailPreviewPartnerAssignedID"            -Value $DataField[43] -Force
        $Data | Add-Member NoteProperty -Name "VoiceMailPreviewPartnerMaxMessageDuration"    -Value $DataField[44] -Force
        $Data | Add-Member NoteProperty -Name "VoiceMailPreviewPartnerMaxDeliveryDelay"      -Value $DataField[45] -Force
        $Data | Add-Member NoteProperty -Name "IsDefault"                                    -Value $DataField[46] -Force
        $UmMailboxPolicy += $Data
	}
}
#endregion Get-UmMailboxPolicy

Write-Host "---- Populating UM Auto Attendant"
#region Get-UmAutoAttendant
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_UmAutoAttendant.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_UmAutoAttendant.txt")
	$UmAutoAttendant = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Name"                                         -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "SpeechEnabled"                                -Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "AllowDialPlanSubscribers"                     -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "AllowExtensions"                              -Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "AllowedInCountryOrRegionGroups"               -Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "AllowedInternationalGroups"                   -Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "CallSomeoneEnabled"                           -Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "ContactScope"                                 -Value $DataField[8] -Force
        $Data | Add-Member NoteProperty -Name "ContactAddressList"                           -Value $DataField[9] -Force
        $Data | Add-Member NoteProperty -Name "SendVoiceMsgEnabled"                          -Value $DataField[10] -Force
        $Data | Add-Member NoteProperty -Name "BusinessHourSchedule"                         -Value $DataField[11] -Force
        $Data | Add-Member NoteProperty -Name "PilotIdentifierList"                          -Value $DataField[12] -Force
        $Data | Add-Member NoteProperty -Name "UmDialPlan"                                   -Value $DataField[13] -Force
        $Data | Add-Member NoteProperty -Name "DtmfFallbackAutoAttendant"                    -Value $DataField[14] -Force
        $Data | Add-Member NoteProperty -Name "HolidaySchedule"                              -Value $DataField[15] -Force
        $Data | Add-Member NoteProperty -Name "TimeZone"                                     -Value $DataField[16] -Force
        $Data | Add-Member NoteProperty -Name "TimeZoneName"                                 -Value $DataField[17] -Force
        $Data | Add-Member NoteProperty -Name "MatchedNameSelectionMethod"                   -Value $DataField[18] -Force
        $Data | Add-Member NoteProperty -Name "BusinessLocation"                             -Value $DataField[19] -Force
        $Data | Add-Member NoteProperty -Name "WeekStartDay"                                 -Value $DataField[20] -Force
        $Data | Add-Member NoteProperty -Name "Status"                                       -Value $DataField[21] -Force
        $Data | Add-Member NoteProperty -Name "Language"                                     -Value $DataField[22] -Force
        $Data | Add-Member NoteProperty -Name "OperatorExtension"                            -Value $DataField[23] -Force
        $Data | Add-Member NoteProperty -Name "InfoAnnouncementFilename"                     -Value $DataField[24] -Force
        $Data | Add-Member NoteProperty -Name "InfoAnnouncementEnabled"                      -Value $DataField[25] -Force
        $Data | Add-Member NoteProperty -Name "NameLookupEnabled"                            -Value $DataField[26] -Force
        $Data | Add-Member NoteProperty -Name "StarOutToDialPlanEnabled"                     -Value $DataField[27] -Force
        $Data | Add-Member NoteProperty -Name "ForwardCallsToDefaultMailbox"                 -Value $DataField[28] -Force
        $Data | Add-Member NoteProperty -Name "DefaultMailbox"                               -Value $DataField[29] -Force
        $Data | Add-Member NoteProperty -Name "BusinessName"                                 -Value $DataField[30] -Force
        $Data | Add-Member NoteProperty -Name "BusinessHoursWelcomeGreetingFilename"         -Value $DataField[31] -Force
        $Data | Add-Member NoteProperty -Name "BusinessHoursWelcomeGreetingEnabled"          -Value $DataField[32] -Force
        $Data | Add-Member NoteProperty -Name "BusinessHoursMainMenuCustomPromptFilename"    -Value $DataField[33] -Force
        $Data | Add-Member NoteProperty -Name "BusinessHoursMainMenuCustomPromptEnabled"     -Value $DataField[34] -Force
        $Data | Add-Member NoteProperty -Name "BusinessHoursTransferToOperatorEnabled"       -Value $DataField[35] -Force
        $Data | Add-Member NoteProperty -Name "BusinessHoursKeyMapping"                      -Value $DataField[36] -Force
        $Data | Add-Member NoteProperty -Name "BusinessHoursKeyMappingEnabled"               -Value $DataField[37] -Force
        $Data | Add-Member NoteProperty -Name "AfterHoursWelcomeGreetingFilename"            -Value $DataField[38] -Force
        $Data | Add-Member NoteProperty -Name "AfterHoursWelcomeGreetingEnabled"             -Value $DataField[39] -Force
        $Data | Add-Member NoteProperty -Name "AfterHoursMainMenuCustomPromptFilename"       -Value $DataField[40] -Force
        $Data | Add-Member NoteProperty -Name "AfterHoursMainMenuCustomPromptEnabled"        -Value $DataField[41] -Force
        $Data | Add-Member NoteProperty -Name "AfterHoursTransferToOperatorEnabled"          -Value $DataField[42] -Force
        $Data | Add-Member NoteProperty -Name "AfterHoursKeyMapping"                         -Value $DataField[43] -Force
        $Data | Add-Member NoteProperty -Name "AfterHoursKeyMappingEnabled"                  -Value $DataField[44] -Force
        $UmAutoAttendant += $Data
	}
}
#endregion Get-UmAutoAttendant

#endregion Populate the Exchange variables from the O365DC text files

#region Populate the WMI variables from the O365DC text files
Write-Host "---- Populating our WMI variables from the O365DC output files"

Write-Host "---- Populating Win32_BIOS"
#region BIOS
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exch_W32_bios") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exch_w32_bios" | Where-Object {$_.name -match "~~Exch_W32_bios"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exch_w32_bios\" + $file)
	}
	$Bios = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Computer"     	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Manufacturer"    -Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Name"        	-Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Serial Number"   -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Version"         -Value $DataField[4] -Force
        $Bios += $Data
	}
}
#endregion BIOS

Write-Host "---- Populating Physical Memory"
#region RAM
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exch_W32_pm") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exch_w32_pm" | Where-Object {$_.name -match "~~Exch_W32_pm"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exch_w32_pm\" + $file)
	}
	$Ram = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Computer"    -Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Tag"        	-Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Capacity"    -Value $DataField[3] -Force
        $Ram += $Data
	}
}
#endregion RAM

Write-Host "---- Populating Page File Usage"
#region Page File Usage
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exch_W32_pfu") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exch_w32_pfu" | Where-Object {$_.name -match "~~Exch_W32_pfu"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exch_w32_pfu\" + $file)
	}
	$PageFile = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Computer"    			-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Allocated Base Size"   	-Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Caption"        			-Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Description"        		-Value $DataField[5] -Force
        $PageFile += $Data
	}
}
#endregion Page File Usage

Write-Host "---- Populating Computer System"
#region Computer System
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exch_W32_cs") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exch_w32_cs" | Where-Object {$_.name -match "~~Exch_W32_cs"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exch_w32_cs\" + $file)
	}
	$ComputerSystem = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Computer"    					-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Model"   						-Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Number Of Logical Processors"    -Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Number Of Processors"        	-Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Total Physical Memory"        	-Value $DataField[5] -Force
        $ComputerSystem += $Data
	}
}
#endregion Computer System

Write-Host "---- Populating Network Adapter"
#region Network Adapters
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exch_W32_na") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exch_w32_na" | Where-Object {$_.name -match "~~Exch_W32_na"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exch_w32_na\" + $file)
	}
	$NetworkAdapter = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Computer"    	-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Manufacturer"   	-Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Name"   			-Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Speed"        	-Value $DataField[8] -Force
        $NetworkAdapter += $Data
	}
}
#endregion Network Adapters

Write-Host "---- Populating Network Adapter Configuration"
#region Network Adapter Configuration
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exch_W32_nac") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exch_w32_nac" | Where-Object {$_.name -match "~~Exch_W32_nac"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exch_w32_nac\" + $file)
	}
	$NetworkAdapterConfiguration = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Computer"    						-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Default IP Gateway"   				-Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "DNS Host Name"   					-Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "IP Address"        					-Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "IP Subnet"        					-Value $DataField[8] -Force
        $Data | Add-Member NoteProperty -Name "Domain DNS Registration Enabled"		-Value $DataField[13] -Force
        $NetworkAdapterConfiguration += $Data
	}
}
#endregion Network Adapter Configuration

Write-Host "---- Populating Operating System"
#region Operating System
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exch_W32_os") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exch_w32_os" | Where-Object {$_.name -match "~~Exch_W32_os"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exch_w32_os\" + $file)
	}
	$Os = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Computer"    					-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Version"        					-Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Service Pack Major Version" 		-Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "OS Architecture"        			-Value $DataField[5] -Force
        $Data | Add-Member NoteProperty -Name "Max Process Memory Size"   		-Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Caption"   						-Value $DataField[7] -Force
        $Os += $Data
	}
}
#endregion Operating System

Write-Host "---- Populating Processor"
#region Processor
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exch_W32_proc") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exch_W32_proc" | Where-Object {$_.name -match "~~Exch_W32_proc"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exch_W32_proc\" + $file)
	}
	$Processor = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Computer"    					-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Device ID"        				-Value $DataField[1] -Force
        $Data | Add-Member NoteProperty -Name "Current Clock Speed"   			-Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Description"   					-Value $DataField[3] -Force
        $Data | Add-Member NoteProperty -Name "Manufacturer"        			-Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Number Of Cores"        			-Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "Number Of Logical Processors" 	-Value $DataField[8] -Force
        $Processor += $Data
	}
}
#endregion Processor

Write-Host "---- Populating Logical Disk"
#region Logical Disk
$DataFile = @()
if ((Test-Path -LiteralPath "$RunLocation\output\Exch_W32_ld") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exch_W32_ld" | Where-Object {$_.name -match "~~Exch_W32_ld"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exch_W32_ld\" + $file)
	}
	$LogicalDisk = @()
	Foreach ($DataRow in $DataFile)
	{
		$Data = New-Object PSObject
        $DataField = $DataRow.Split("`t")
        $Data | Add-Member NoteProperty -Name "Computer"    		-Value $DataField[0] -Force
        $Data | Add-Member NoteProperty -Name "Caption"   			-Value $DataField[2] -Force
        $Data | Add-Member NoteProperty -Name "Description"   		-Value $DataField[4] -Force
        $Data | Add-Member NoteProperty -Name "Name"   				-Value $DataField[6] -Force
        $Data | Add-Member NoteProperty -Name "Volume Name"   		-Value $DataField[7] -Force
        $Data | Add-Member NoteProperty -Name "Size (GB)"        	-Value $DataField[10] -Force
        $Data | Add-Member NoteProperty -Name "FreeSpace (GB)"		-Value $DataField[11] -Force
        $LogicalDisk += $Data
	}
}
#endregion Logical Disk

#endregion Populate the WMI variables from the O365DC text files

#endregion Populate the variable


# Go to start of document
write-host -Object "Creating the document" -ForegroundColor Green

$selection.startof(6) | Out-Null

$selection.GoToNext([microsoft.office.interop.word.wdgotoitem]::wdGoToLine) | Out-Null

# Font color enumerations
# https://msdn.microsoft.com/en-us/library/bb237558%28v=office.12%29.aspx?f=255&MSPPError=-2147217396

$selection.font.Bold = $false

# Advance to get to beginning of author section
$selection.GoToNext([microsoft.office.interop.word.wdgotoitem]::wdGoToLine) | Out-Null
$selection.GoToNext([microsoft.office.interop.word.wdgotoitem]::wdGoToLine) | Out-Null
$selection.Endof(5) | out-null

$selection.Font.Italic = $true
$selection.Font.Size=10
$selection.ParagraphFormat.Alignment = [microsoft.office.interop.word.WdParagraphAlignment]::wdAlignParagraphLeft
$selection.TypeText("Prepared for$([char]13)")
$selection.Font.Italic = $false
$selection.font.Bold = $false
try
{
   $Date = Get-date -DisplayHint Date
   $selection.TypeText("$($Exchange."organization name")$([char]13)")
   $selection.TypeText("$Date$([char]13)")
   $selection.TypeText("Version 0.1 Draft $([char]13)")
   $selection.TypeParagraph()
   $selection.Font.Italic = $true
   $selection.TypeText("Prepared by$([char]13)")
   $selection.Font.Italic = $false
   $selection.font.Bold = $true
   $selection.TypeText("[Name]$([char]13)" )
   $selection.font.Bold = $false
   $selection.TypeText("[Title]$([char]13)" )
   $selection.TypeText("[Email]$([char]13)" )
   $selection.TypeParagraph()
   $selection.Font.Italic = $true
   $selection.TypeText("Contributors$([char]13)" )
   $selection.Font.Italic = $false
   $selection.font.Bold = $true
   $selection.TypeText("[Name]$([char]13)" )
   $selection.font.Bold = $false
   #$selection.TypeText("$([char]13)")
   $selection.ParagraphFormat.Alignment = 0
   $selection.EndOf(6) | Out-Null
}
Catch
{}

#Start writing Disclaimer information - Content extracted from disclaimer.txt in templates folder
#$Disclaimer = (Get-Content -Path "$RunLocation\Templates\Disclaimer.txt")
$DisclaimerText = ""
Get-Content -Path "$RunLocation\Templates\Disclaimer.txt" | ForEach-Object `
{
	if ($_ -like "#*")
	{
		# Ignore lines that start with # character
	}
	else
	{
		$DisclaimerText += $_
	}
}

If ($DisclaimerText -ne "" -and $DisclaimerText -ne $null)
{
    $selection.InsertNewPage()
    $selection.Font.Size=16
    $selection.Style = "Bold"
    $selection.Font.Name="Segoe UI"
    $selection.TypeText("Disclaimer: ")
    $selection.TypeParagraph()

    $selection.Font.Size=10
    $selection.Style = "Normal"
    $selection.Font.Name="Segoe UI"
    $selection.TypeText([string]$DisclaimerText)
    $selection.TypeParagraph()
    $selection.EndOf(6) | Out-Null
}

#region Add Table of Contents

# Start writing Table of Contents
$selection.InsertNewPage()
$selection.Font.Size=18
$selection.Style = "Heading 1"
$selection.Font.Name="Segoe UI"
$selection.TypeText("Table of Contents")
$selection.Font.Size=10
#$selection.Style = "Normal"

#TOC - Table of content Settings
$tocrange = $Word_ExDoc_documents.application.selection.range
$useHeadingStyles = $true
$upperHeadingLevel = 1
$lowerHeadingLevel = 2
$useFields = $false
$tableID = "TOC1"
$rightAlignPageNumbers = $true
$includePageNumbers = $true
$addedStyles = $null
$useHyperlinks = $true
$hidePageNumbersInWeb = $true
$useOutlineLevels = $true
$toc = $Word_ExDoc_documents.TablesOfContents.Add($tocrange, $useHeadingStyles,$upperHeadingLevel, $lowerHeadingLevel, `
$useFields, $tableID,$rightAlignPageNumbers, $includePageNumbers, $addedStyles,$useHyperlinks, $hidePageNumbersInWeb, $useOutlineLevels)
$selection.InsertNewPage()
$selection.EndOf(6) | Out-Null
#endregion Add Table of Contents


#region Write the body of the doc


#region Update Exchange data

$index = 0
#region Overview
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
$index++
#endregion Overview

#region Active Directory
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
$index++
#endregion Active Directory

#region Fsmo Roles
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $Fsmo $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "DNS Root"
$index++
#endregion Fsmo Roles

#region Exchange Schema
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $Schema $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Exchange Schema Version"
$index++
#endregion Exchange Schema

#region Active Directory Sites
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $AdSite $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Site Name"
$index++
#endregion Active Directory Sites

#region Active Directory Site Links
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $AdSiteLinks $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Active Directory Site Links

#region Exchange Servers
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $ExchangeServers $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Exchange Servers

#region Accepted Domain
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $AcceptedDomain $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Accepted Domain

#region Remote Domain
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $RemoteDomain $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Identity"
$index++
#endregion Remote Domain

#region Availability Address Space
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $Availability $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Availability Address Space

#region Transport Config
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-TableVertical $Transport $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "AdminDisplayName"
$index++
#endregion Transport Config

#region Exchange Server Roles
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $Roles $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Exchange Server Roles

#region Exchange Rollups
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $Rollups $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Exchange Rollups

#region Journaling Information
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $Journal $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "ServerName" "Name"
$index++
#endregion Journaling Information

#region Retention
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $Retention $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "ServerName" "Name"
$index++
#endregion Retention

#region Database Quotas
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $Quota $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Server Name" "Name"
$index++
#endregion Database Quotas

#region Mailbox Database
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $MbxDb $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "ServerName" "Name"
$index++
#endregion Mailbox Database

#region Mailbox Count
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $MailboxCount $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "ServerName" "Database Name"
$index++
#endregion Mailbox Count

#region SCP Records
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $SCP $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion SCP Records

#region IIS Vdir
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
$index++
#endregion IIS VDir

#region Autodiscover Vdir
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $AutodiscoverVdir $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Server" "Name"
$index++
#endregion Autodiscover Vdir

#region ECP Vdir
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $EcpVdir $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Server" "Name"
$index++
#endregion ECP Vdir

#region EWS Vdir
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $EwsVdir $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Server" "Name"
$index++
#endregion EWS Vdir

#region ActiveSync Vdir
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $ActiveSyncVdir $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Server" "Name"
$index++
#endregion ActiveSync Vdir

#region OAB Vdir
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $OabVdir $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Server" "Name"
$index++
#endregion OAB Vdir

#region OWA Vdir
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $OwaVdir $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Server" "Name"
$index++
#endregion OWA Vdiir

#region Outlook Anywhere
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $OutlookAnywhere $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "ServerName"
$index++
#endregion Outlook Anywhere

#region Client Access Array
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $CasArray $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Client Access Array

#region Database Availability Group Networks
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $DagNetwork $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Identity"
$index++
#endregion Database Availability Group Networks

#region Database Availability Group
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $Dag $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Database Availability Group

#region Database Availability Group Distributions
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $DagDistribution $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Database Name"
$index++
#endregion Database Availability Group Distribution

#region Receive Connectors
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $ReceiveConnector $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Server" "Name"
$index++
#endregion Receive Connectors

#region Send Connectors
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $SendConnector $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Send Connectors

#region Transport Rule
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $TransportRule $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Identity"
$index++
#endregion Transport Rule

#region Address List
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $AddressList $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Display Name"
$index++
#endregion Address List

#region Offline Address Book
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-TableVertical $Oab $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Offline Address Book

#region Retention Tags and Policies
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
$index++
#endregion Retention Tags and Policies

#region Retention Policy
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $RetentionPolicy $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Retention Policy

#region Retention Policy Tag
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $RetentionPolicyTag $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Retention Policy Tag

#region Email Address Policy
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-TableVertical $EmailAddressPolicy $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Email Address Policy

#region Address Book Policy
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-TableVertical $AddressBookPolicy $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion Address Book Policy

#region ActiveSync Mailbox Policy
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-TableVertical $ActiveSyncMailboxPolicy $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion ActiveSync Device Policy

#region OWA Mailbox Policy
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-TableVertical $OwaMailboxPolicy $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion OWA Mailbox Policy

#region Role-Based Access Controls
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-Table $Rbac $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Role Group Name"
$index++
#endregion Role-Based Access Controls

#region Unified Messaging
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
$index++
#endregion Unified Messaging

#region UM Dial Plan
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-TableVertical $UmDialPlan $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion UM Dial Plan

#region UM IP Gateway
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-TableVertical $UmIpGateway $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion UM IP Gateway

#region UM Mailbox Policies
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-TableVertical $UmMailboxPolicy $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion UM Mailbox Policies

#region UM Auto Attendant
Write-Doc $ExchangeXml[$index].TextPara $ExchangeXml[$index].Heading $ExchangeXml[$index].HeadingFormat
Update-TableVertical $UmAutoAttendant $ExchangeXml[$index].HeaderDirection $ExchangeXml[$index].HeaderHeight "Name"
$index++
#endregion UM Auto Attendant

#endregion Update Exchange Data

#region Update WMI Data
$index = 0

#region Hardware Configuration
Write-Doc $WmiXml[$index].TextPara $WmiXml[$index].Heading $WmiXml[$index].HeadingFormat
$index++
#endregion Hardware Configuration

#region BIOS
Write-Doc $WmiXml[$index].TextPara $WmiXml[$index].Heading $WmiXml[$index].HeadingFormat
Update-Table $Bios $WmiXml[$index].HeaderDirection $WmiXml[$index].HeaderHeight "Computer"
$index++
#endregion BIOS

#region RAM
Write-Doc $WmiXml[$index].TextPara $WmiXml[$index].Heading $WmiXml[$index].HeadingFormat
Update-Table $Ram $WmiXml[$index].HeaderDirection $WmiXml[$index].HeaderHeight "Computer" "Tag"
$index++
#endregion RAM

#region Page File Usage
Write-Doc $WmiXml[$index].TextPara $WmiXml[$index].Heading $WmiXml[$index].HeadingFormat
Update-Table $PageFile $WmiXml[$index].HeaderDirection $WmiXml[$index].HeaderHeight "Computer" "Caption"
$index++
#endregion Page File Usage

#region Computer System
Write-Doc $WmiXml[$index].TextPara $WmiXml[$index].Heading $WmiXml[$index].HeadingFormat
Update-Table $ComputerSystem $WmiXml[$index].HeaderDirection $WmiXml[$index].HeaderHeight "Computer"
$index++
#endregion Computer System

#region Network Adapter
Write-Doc $WmiXml[$index].TextPara $WmiXml[$index].Heading $WmiXml[$index].HeadingFormat
Update-Table $NetworkAdapter $WmiXml[$index].HeaderDirection $WmiXml[$index].HeaderHeight "Computer" "Name"
$index++
#endregion Network Adapter

#region Network Adapter Configuration
Write-Doc $WmiXml[$index].TextPara $WmiXml[$index].Heading $WmiXml[$index].HeadingFormat
Update-Table $NetworkAdapterConfiguration $WmiXml[$index].HeaderDirection $WmiXml[$index].HeaderHeight "Computer" "IP Address"
$index++
#endregion Network Adapter Configuration

#region Operating System
Write-Doc $WmiXml[$index].TextPara $WmiXml[$index].Heading $WmiXml[$index].HeadingFormat
Update-Table $Os $WmiXml[$index].HeaderDirection $WmiXml[$index].HeaderHeight "Computer"
$index++
#endregion Operating System

#region Processor
Write-Doc $WmiXml[$index].TextPara $WmiXml[$index].Heading $WmiXml[$index].HeadingFormat
Update-Table $Processor $WmiXml[$index].HeaderDirection $WmiXml[$index].HeaderHeight "Computer" "Description"
$index++
#endregion Processor

#region Logical Disk
Write-Doc $WmiXml[$index].TextPara $WmiXml[$index].Heading $WmiXml[$index].HeadingFormat
Update-Table $LogicalDisk $WmiXml[$index].HeaderDirection $WmiXml[$index].HeaderHeight "Computer" "Name"
$index++
#endregion Logical Disk


#endregion Update WMI Data

#region Finish up the Word Doc

# Update the TOC
$Word_ExDoc_documents.TablesOfContents.Item(1).update()
# Select the entire document
$Word_ExDoc_documents.select()
# Make sure all fonts are set to Segoe UI
$Word_ExDoc.Selection.font.name="Segoe UI"
# Save the final doc
$Word_ExDoc_documents.Save()
$Word_ExDoc.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Word_ExDoc) | Out-Null
Remove-Variable -Name Word_ExDoc
[gc]::collect()
[gc]::WaitForPendingFinalizers()
#endregion Finish up the Word Doc
