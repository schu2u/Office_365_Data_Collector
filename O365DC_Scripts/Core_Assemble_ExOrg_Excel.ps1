#############################################################################
#                    Core_Assemble_ExOrg_Excel.ps1		 					#
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

$ErrorActionPreference = "Stop"
Trap {
$ErrorText = "Core_Assemble_ExOrg_Excel " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "ExDC"
#$ErrorLog.WriteEntry($ErrorText,"Error", 100)
}

# Increase this value if adding new sheets
$SheetsInNewWorkbook = 36

function Process-Datafile{
    param ([int]$NumberOfColumns, `
			[array]$DataFromFile, `
			$Wsheet, `
			[int]$ExcelVersion)
		$RowCount = $DataFromFile.Count
        $ArrayRow = 0
        $BadArrayValue = @()
        $DataArray = New-Object 'object[,]' -ArgumentList $RowCount,$NumberOfColumns
		Foreach ($DataRow in $DataFromFile)
        {
            $DataField = $DataRow.Split("`t")
            for ($ArrayColumn = 0 ; $ArrayColumn -lt $NumberOfColumns ; $ArrayColumn++)
            {
                # Excel chokes if field starts with = so we'll try to prepend the ' to the string if it does
                Try{If ($DataField[$ArrayColumn].substring(0,1) -eq "=") {$DataField[$ArrayColumn] = "'"+$DataField[$ArrayColumn]}}
				Catch{}
                # Excel 2003 limit of 1823 characters
                if ($DataField[$ArrayColumn].length -lt 1823)
                    {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
                # Excel 2007 limit of 8203 characters
                elseif (($ExcelVersion -ge 12) -and ($DataField[$ArrayColumn].length -lt 8203))
                    {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
                # No known Excel 2010 limit
                elseif ($ExcelVersion -ge 14)
                    {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
                else
                {
                    Write-Host -Object "Number of characters in array member exceeds the version of limitations of this version of Excel" -ForegroundColor Yellow
                    Write-Host -Object "-- Writing value to temp variable" -ForegroundColor Yellow
                    $DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]
                    $BadArrayValue += "$ArrayRow,$ArrayColumn"
                }
            }
            $ArrayRow++
        }

        # Replace big values in $DataArray
        $BadArrayValue_count = $BadArrayValue.count
        $BadArrayValue_Temp = @()
        for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
        {
            $BadArray_Split = $badarrayvalue[$i].Split(",")
            $BadArrayValue_Temp += $DataArray[$BadArray_Split[0],$BadArray_Split[1]]
            $DataArray[$BadArray_Split[0],$BadArray_Split[1]] = "**TEMP**"
            Write-Host -Object "-- Replacing long value with **TEMP**" -ForegroundColor Yellow
        }

        $EndCellRow = ($RowCount+1)
        $Data_range = $Wsheet.Range("a2","$EndCellColumn$EndCellRow")
        $Data_range.Value2 = $DataArray

        # Paste big values back into the spreadsheet
        for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
        {
            $BadArray_Split = $badarrayvalue[$i].Split(",")
            # Adjust for header and $i=0
            $CellRow = [int]$BadArray_Split[0] + 2
            # Adjust for $i=0
            $CellColumn = [int]$BadArray_Split[1] + 1

            $Range = $Wsheet.cells.item($CellRow,$CellColumn)
            $Range.Value2 = $BadArrayValue_Temp[$i]
            Write-Host -Object "-- Pasting long value back in spreadsheet" -ForegroundColor Yellow
        }
    }

function Get-ColumnLetter{
	param([int]$HeaderCount)

	If ($headercount -ge 27)
	{
		$i = [int][math]::Floor($Headercount/26)
		$j = [int]($Headercount -($i*26))
		# This doesn't work on factors of 26
		# 52 become "b@" instead of "az"
		if ($j -eq 0)
		{
			$i--
			$j=26
		}
		$i_char = [char]($i+64)
		$j_char = [char]($j+64)
	}
	else
	{
		$j_char = [char]($headercount+64)
	}
	return [string]$i_char+[string]$j_char
}

set-location -LiteralPath $RunLocation

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "ExDC"
#$EventLog.WriteEntry("Starting Core_Assemble_ExOrg_Excel","Information", 42)

Write-Host -Object "---- Starting to create com object for Excel"
$Excel_ExOrg = New-Object -ComObject excel.application
Write-Host -Object "---- Hiding Excel"
$Excel_ExOrg.visible = $false
Write-Host -Object "---- Setting ShowStartupDialog to false"
$Excel_ExOrg.ShowStartupDialog = $false
Write-Host -Object "---- Setting DefaultFilePath"
$Excel_ExOrg.DefaultFilePath = $RunLocation + "\output"
Write-Host -Object "---- Setting SheetsInNewWorkbook"
$Excel_ExOrg.SheetsInNewWorkbook = $SheetsInNewWorkbook
Write-Host -Object "---- Checking Excel version"
$Excel_Version = $Excel_ExOrg.version
if ($Excel_version -ge 12)
{
	$Excel_ExOrg.DefaultSaveFormat = 51
	$excel_Extension = ".xlsx"
}
else
{
	$Excel_ExOrg.DefaultSaveFormat = 56
	$excel_Extension = ".xls"
}
Write-Host -Object "---- Excel version $Excel_version and DefaultSaveFormat $Excel_extension"

# Create new Excel workbook
Write-Host -Object "---- Adding workbook"
$Excel_ExOrg_workbook = $Excel_ExOrg.workbooks.add()
Write-Host -Object "---- Setting output file"
$ExDC_ExOrg_XLS = $RunLocation + "\output\ExDC_ExOrg" + $excel_Extension

Write-Host -Object "---- Setting workbook properties"
$Excel_ExOrg_workbook.author = "Office 365 Data Collector v4 (O365DC v4)"
$Excel_ExOrg_workbook.title = "O365DC v4 - Exchange Organization"
$Excel_ExOrg_workbook.comments = "O365DC v4.0.2"

$intSheetCount = 1
$intColorIndex_ClientAccess = 45
$intColorIndex_Global = 11
$intColorIndex_Recipient = 45
$intColorIndex_Transport = 11
$intColorIndex_Um = 45
$intColorIndex_Misc = 11


# Client Access
#Region Get-AvailabilityAddressSpace sheet
Write-Host -Object "---- Starting Get-AvailabilityAddressSpace"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "AvailabilityAddressSpace"
	$Worksheet.Tab.ColorIndex = $intColorIndex_ClientAccess
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "ForestName"
	$header +=  "UserName"
	$header +=  "UseServiceAccount"
	$header +=  "AccessMethod"
	$header +=  "ProxyUrl"
	$header +=  "TargetAutodiscoverEpr"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetAvailabilityAddressSpace.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetAvailabilityAddressSpace.txt")

	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-AvailabilityAddressSpace sheet

#Region Get-MobileDevice sheet
Write-Host -Object "---- Starting Get-MobileDevice"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "MobileDevice"
	$Worksheet.Tab.ColorIndex = $intColorIndex_ClientAccess
	$row = 1
	$header = @()
	$header +=  "FriendlyName"
	$header +=  "DeviceMobileOperator"
	$header +=  "DeviceOS"
	$header +=  "DeviceTelephoneNumber"
	$header +=  "DeviceType"
	$header +=  "DeviceUserAgent"
	$header +=  "DeviceModel"
	$header +=  "FirstSyncTime"		# Column H
	$header +=  "UserDisplayName"
	$header +=  "DeviceAccessState"
	$header +=  "DeviceAccessStateReason"
	$header +=  "ClientVersion"
	$header +=  "Name"
	$header +=  "Identity"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetMobileDevice.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetMobileDevice.txt")

	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# FirstSyncTime
$Column_Range = $Worksheet.Range("H1","H$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"

	#EndRegion Get-MobileDevice sheet

#Region Get-MobileDeviceMailboxPolicy sheet
Write-Host -Object "---- Starting Get-MobileDeviceMailboxPolicy"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "MobileDeviceMailboxPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex_ClientAccess
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "AllowNonProvisionableDevices"
	$header +=  "AlphanumericPasswordRequired"
	$header +=  "AttachmentsEnabled"
	$header +=  "DeviceEncryptionEnabled"
	$header +=  "RequireStorageCardEncryption"
	$header +=  "DevicePasswordEnabled"
	$header +=  "PasswordRecoveryEnabled"
	$header +=  "DevicePolicyRefreshInterval"
	$header +=  "AllowSimpleDevicePassword"
	$header +=  "MaxAttachmentSize"
	$header +=  "WSSAccessEnabled"
	$header +=  "UNCAccessEnabled"
	$header +=  "MinPasswordLength"
	$header +=  "MaxInactivityTimeLock"			# Column O
	$header +=  "MaxPasswordFailedAttempts"
	$header +=  "PasswordExpiration"
	$header +=  "PasswordHistory"
	$header +=  "IsDefault"
	$header +=  "AllowApplePushNotifications"
	$header +=  "AllowMicrosoftPushNotifications"
	$header +=  "AllowGooglePushNotifications"
	$header +=  "AllowStorageCard"
	$header +=  "AllowCamera"
	$header +=  "RequireDeviceEncryption"
	$header +=  "AllowUnsignedApplications"
	$header +=  "AllowUnsignedInstallationPackages"
	$header +=  "AllowWiFi"
	$header +=  "AllowTextMessaging"
	$header +=  "AllowPOPIMAPEmail"
	$header +=  "AllowIrDA"
	$header +=  "RequireManualSyncWhenRoaming"
	$header +=  "AllowDesktopSync"
	$header +=  "AllowHTMLEmail"
	$header +=  "RequireSignedSMIMEMessages"
	$header +=  "RequireEncryptedSMIMEMessages"
	$header +=  "AllowSMIMESoftCerts"
	$header +=  "AllowBrowser"
	$header +=  "AllowConsumerEmail"
	$header +=  "AllowRemoteDesktop"
	$header +=  "AllowInternetSharing"
	$header +=  "AllowBluetooth"
	$header +=  "MaxCalendarAgeFilter"
	$header +=  "MaxEmailAgeFilter"
	$header +=  "RequireSignedSMIMEAlgorithm"
	$header +=  "RequireEncryptionSMIMEAlgorithm"
	$header +=  "AllowSMIMEEncryptionAlgorithmNegotiation"
	$header +=  "MinPasswordComplexCharacters"
	$header +=  "MaxEmailBodyTruncationSize"
	$header +=  "MaxEmailHTMLBodyTruncationSize"
	$header +=  "UnapprovedInROMApplicationList"
	$header +=  "ApprovedApplicationList"
	$header +=  "AllowExternalDeviceManagement"
	$header +=  "MobileOTAUpdateMode"
	$header +=  "AllowMobileOTAUpdate"
	$header +=  "IrmEnabled"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetMobileDeviceMbxPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetMobileDeviceMbxPolicy.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# MaxinActivityTimeDeviceLock
$Column_Range = $Worksheet.Range("O1","O$EndRow")
$Column_Range.cells.NumberFormat = "hh:mm:ss"

	#EndRegion Get-MobileDeviceMailboxPolicy sheet

#Region Get-OwaMailboxPolicy sheet
Write-Host -Object "---- Starting Get-OwaMailboxPolicy"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "OwaMailboxPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex_ClientAccess
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "OneDriveAttachmentsEnabled"
	$header +=  "ThirdPartyFileProvidersEnabled"
	$header +=  "ClassicAttachmentsEnabled"
	$header +=  "ReferenceAttachmentsEnabled"
	$header +=  "SaveAttachmentsToCloudEnabled"
	$header +=  "InternalSPMySiteHostURL"
	$header +=  "ExternalSPMySiteHostURL"
	$header +=  "DirectFileAccessOnPublicComputersEnabled"
	$header +=  "DirectFileAccessOnPrivateComputersEnabled"
	$header +=  "WebReadyDocumentViewingOnPublicComputersEnabled"
	$header +=  "WebReadyDocumentViewingOnPrivateComputersEnabled"
	$header +=  "ForceWebReadyDocumentViewingFirstOnPublicComputers"
	$header +=  "ForceWebReadyDocumentViewingFirstOnPrivateComputers"
	$header +=  "WacViewingOnPublicComputersEnabled"
	$header +=  "WacViewingOnPrivateComputersEnabled"
	$header +=  "ForceWacViewingFirstOnPublicComputers"
	$header +=  "ForceWacViewingFirstOnPrivateComputers"
	$header +=  "ActionForUnknownFileAndMIMETypes"
	$header +=  "WebReadyDocumentViewingForAllSupportedTypes"
	$header +=  "PhoneticSupportEnabled"
	$header +=  "DefaultTheme"
	$header +=  "IsDefault"
	$header +=  "DefaultClientLanguage"
	$header +=  "LogonAndErrorLanguage"
	$header +=  "UseGB18030"
	$header +=  "UseISO885915"
	$header +=  "OutboundCharset"
	$header +=  "GlobalAddressListEnabled"
	$header +=  "OrganizationEnabled"
	$header +=  "ExplicitLogonEnabled"
	$header +=  "OWALightEnabled"
	$header +=  "DelegateAccessEnabled"
	$header +=  "IRMEnabled"
	$header +=  "CalendarEnabled"
	$header +=  "ContactsEnabled"
	$header +=  "TasksEnabled"
	$header +=  "JournalEnabled"
	$header +=  "NotesEnabled"
	$header +=  "OnSendAddinsEnabled"
	$header +=  "RemindersAndNotificationsEnabled"
	$header +=  "PremiumClientEnabled"
	$header +=  "SpellCheckerEnabled"
	$header +=  "SearchFoldersEnabled"
	$header +=  "SignaturesEnabled"
	$header +=  "ThemeSelectionEnabled"
	$header +=  "JunkEmailEnabled"
	$header +=  "UMIntegrationEnabled"
	$header +=  "WSSAccessOnPublicComputersEnabled"
	$header +=  "WSSAccessOnPrivateComputersEnabled"
	$header +=  "ChangePasswordEnabled"
	$header +=  "UNCAccessOnPublicComputersEnabled"
	$header +=  "UNCAccessOnPrivateComputersEnabled"
	$header +=  "ActiveSyncIntegrationEnabled"
	$header +=  "AllAddressListsEnabled"
	$header +=  "RulesEnabled"
	$header +=  "PublicFoldersEnabled"
	$header +=  "SMimeEnabled"
	$header +=  "RecoverDeletedItemsEnabled"
	$header +=  "InstantMessagingEnabled"
	$header +=  "TextMessagingEnabled"
	$header +=  "ForceSaveAttachmentFilteringEnabled"
	$header +=  "SilverlightEnabled"
	$header +=  "InstantMessagingType"
	$header +=  "DisplayPhotosEnabled"
	$header +=  "AllowOfflineOn"
	$header +=  "SetPhotoURL"
	$header +=  "PlacesEnabled"
	$header +=  "WeatherEnabled"
	$header +=  "LocalEventsEnabled"
	$header +=  "InterestingCalendarsEnabled"
	$header +=  "AllowCopyContactsToDeviceAddressBook"
	$header +=  "PredictedActionsEnabled"
	$header +=  "UserDiagnosticEnabled"
	$header +=  "FacebookEnabled"
	$header +=  "LinkedInEnabled"
	$header +=  "WacExternalServicesEnabled"
	$header +=  "WacOMEXEnabled"
	$header +=  "ReportJunkEmailEnabled"
	$header +=  "GroupCreationEnabled"
	$header +=  "SkipCreateUnifiedGroupCustomSharepointClassification"
	$header +=  "WebPartsFrameOptionsType"
	$header +=  "UserVoiceEnabled"
	$header +=  "SatisfactionEnabled"
	$header +=  "FreCardsEnabled"
	$header +=  "ConditionalAccessPolicy"
	$header +=  "OutlookBetaToggleEnabled"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1
if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetOwaMailboxPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetOwaMailboxPolicy.txt")

	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-ActiveSyncMailboxPolicy sheet

# Global
#Region Get-AddressBookPolicy sheet
Write-Host -Object "---- Starting Get-AddressBookPolicy"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "AddressBookPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Global
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "AddressLists"
	$header +=  "GlobalAddressList"
	$header +=  "RoomList"
	$header +=  "OfflineAddressBook"
	$header +=  "IsDefault"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetAddressBookPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetAddressBookPolicy.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-AddressBookPolicy sheet

#Region Get-AddressList sheet
Write-Host -Object "---- Starting Get-AddressList"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "AddressList"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Global
	$row = 1
	$header = @()
	$header +=  "DisplayName"
	$header +=  "Path"
	$header +=  "RecipientFilter"
	$header +=  "WhenCreatedUTC"	# Column D
	$header +=  "WhenChangedUTC"	# Column E
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetAddressList.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetAddressList.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# WhenCreatedUTC
$Column_Range = $Worksheet.Range("D1","D$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# WhenChangedUTC
$Column_Range = $Worksheet.Range("E1","E$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"

	#EndRegion Get-AddressList sheet

#Region Get-EmailAddressPolicy sheet
Write-Host -Object "---- Starting Get-EmailAddressPolicy"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "EmailAddressPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Global
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "IsValid"
	$header +=  "RecipientFilter"
	$header +=  "LdapRecipientFilter"
	$header +=  "LastUpdatedRecipientFilter"
	$header +=  "RecipientFilterApplied"
	$header +=  "IncludedRecipients"
	$header +=  "ConditionalDepartment"
	$header +=  "ConditionalCompany"
	$header +=  "ConditionalStateOrProvince"
	$header +=  "ConditionalCustomAttribute1"
	$header +=  "ConditionalCustomAttribute2"
	$header +=  "ConditionalCustomAttribute3"
	$header +=  "ConditionalCustomAttribute4"
	$header +=  "ConditionalCustomAttribute5"
	$header +=  "ConditionalCustomAttribute6"
	$header +=  "ConditionalCustomAttribute7"
	$header +=  "ConditionalCustomAttribute8"
	$header +=  "ConditionalCustomAttribute9"
	$header +=  "ConditionalCustomAttribute10"
	$header +=  "ConditionalCustomAttribute11"
	$header +=  "ConditionalCustomAttribute12"
	$header +=  "ConditionalCustomAttribute13"
	$header +=  "ConditionalCustomAttribute14"
	$header +=  "ConditionalCustomAttribute15"
	$header +=  "RecipientContainer"
	$header +=  "RecipientFilterType"
	$header +=  "Priority"
	$header +=  "EnabledPrimarySMTPAddressTemplate"
	$header +=  "EnabledEmailAddressTemplates"
	$header +=  "DisabledEmailAddressTemplates"
	$header +=  "HasEmailAddressSetting"
	$header +=  "HasMailboxManagerSetting"
	$header +=  "NonAuthoritativeDomains"
	$header +=  "ExchangeVersion"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetEmailAddressPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetEmailAddressPolicy.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-EmailAddressPolicy sheet


#Region Get-GlobalAddressList sheet
Write-Host -Object "---- Starting Get-GlobalAddressList"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "GlobalAddressList"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Global
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "IsDefaultGlobalAddressList"
	$header +=  "RecipientFilter"
	$header +=  "LdapRecipientFilter"
	$header +=  "RecipientFilterApplied"
	$header +=  "IncludedRecipients"
	$header +=  "ConditionalDepartment"
	$header +=  "ConditionalCompany"
	$header +=  "ConditionalStateOrProvince"
	$header +=  "ConditionalCustomAttribute1"
	$header +=  "ConditionalCustomAttribute10"
	$header +=  "ConditionalCustomAttribute11"
	$header +=  "ConditionalCustomAttribute12"
	$header +=  "ConditionalCustomAttribute13"
	$header +=  "ConditionalCustomAttribute14"
	$header +=  "ConditionalCustomAttribute15"
	$header +=  "ConditionalCustomAttribute2"
	$header +=  "ConditionalCustomAttribute3"
	$header +=  "ConditionalCustomAttribute4"
	$header +=  "ConditionalCustomAttribute5"
	$header +=  "ConditionalCustomAttribute6"
	$header +=  "ConditionalCustomAttribute7"
	$header +=  "ConditionalCustomAttribute8"
	$header +=  "ConditionalCustomAttribute9"
	$header +=  "RecipientContainer"
	$header +=  "RecipientFilterType"
	$header +=  "Identity"
	$header +=  "WhenCreatedUTC"				# Column AB
	$header +=  "WhenChangedUTC"				# Column AC
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount

	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetGlobalAddressList.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetGlobalAddressList.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# WhenCreatedUTC
$Column_Range = $Worksheet.Range("AB1","AB$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# WhenChangedUTC
$Column_Range = $Worksheet.Range("AC1","AC$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
	#EndRegion Get-GlobalAddressList sheet


#Region Get-OfflineAddressBook sheet
Write-Host -Object "---- Starting Get-OfflineAddressBook"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "OfflineAddressBook"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Global
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "Server"
	$header +=  "AddressLists"
	$header +=  "Versions"
	$header +=  "IsDefault"
	$header +=  "PublicFolderDatabase"
	$header +=  "PublicFolderDistributionEnabled"
	$header +=  "WebDistributionEnabled"
	$header +=  "VirtualDirectories"
	$header +=  "Schedule"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetOfflineAddressBook.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetOfflineAddressBook.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-OfflineAddressBook sheet

#Region Get-OrgConfig sheet
Write-Host -Object "---- Starting Get-OrgConfig"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "OrganizationConfig"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Global
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "DefaultPublicFolderAgeLimit"
	$header +=  "DefaultPublicFolderIssueWarningQuota"
	$header +=  "DefaultPublicFolderProhibitPostQuota"
	$header +=  "DefaultPublicFolderMaxItemSize"
	$header +=  "DefaultPublicFolderDeletedItemRetention"
	$header +=  "DefaultPublicFolderMovedItemRetention"
	$header +=  "PublicFoldersLockedForMigration"
	$header +=  "PublicFolderMigrationComplete"
	$header +=  "PublicFolderMailboxesLockedForNewConnections"
	$header +=  "PublicFolderMailboxesMigrationComplete"
	$header +=  "PublicFolderShowClientControl"
	$header +=  "PublicFoldersEnabled"
	$header +=  "ActivityBasedAuthenticationTimeoutInterval"
	$header +=  "ActivityBasedAuthenticationTimeoutEnabled"
	$header +=  "ActivityBasedAuthenticationTimeoutWithSingleSignOnEnabled"
	$header +=  "AppsForOfficeEnabled"
	$header +=  "AppsForOfficeCorpCatalogAppsCount"
	$header +=  "PrivateCatalogAppsCount"
	$header +=  "AVAuthenticationService"
	$header +=  "CustomerFeedbackEnabled"
	$header +=  "DistributionGroupDefaultOU"
	$header +=  "DistributionGroupNameBlockedWordsList"
	$header +=  "DistributionGroupNamingPolicy"
	$header +=  "EwsAllowEntourage"
	$header +=  "EwsAllowList"
	$header +=  "EwsAllowMacOutlook"
	$header +=  "EwsAllowOutlook"
	$header +=  "EwsApplicationAccessPolicy"
	$header +=  "EwsBlockList"
	$header +=  "EwsEnabled"
	$header +=  "IPListBlocked"
	$header +=  "ElcProcessingDisabled"
	$header +=  "AutoExpandingArchiveEnabled"
	$header +=  "ExchangeNotificationEnabled"
	$header +=  "ExchangeNotificationRecipients"
	$header +=  "HierarchicalAddressBookRoot"
	$header +=  "Industry"
	$header +=  "MailTipsAllTipsEnabled"
	$header +=  "MailTipsExternalRecipientsTipsEnabled"
	$header +=  "MailTipsGroupMetricsEnabled"
	$header +=  "MailTipsLargeAudienceThreshold"
	$header +=  "MailTipsMailboxSourcedTipsEnabled"
	$header +=  "ReadTrackingEnabled"
	$header +=  "SCLJunkThreshold"
	$header +=  "MaxConcurrentMigrations"
	$header +=  "IntuneManagedStatus"
	$header +=  "AzurePremiumSubscriptionStatus"
	$header +=  "HybridConfigurationStatus"
	$header +=  "ReleaseTrack"
	$header +=  "CompassEnabled"
	$header +=  "SharePointUrl"
	$header +=  "MapiHttpEnabled"
	$header +=  "RealTimeLogServiceEnabled"
	$header +=  "CustomerLockboxEnabled"
	$header +=  "UnblockUnsafeSenderPromptEnabled"
	$header +=  "IsMixedMode"
	$header +=  "ServicePlan"
	$header +=  "DefaultDataEncryptionPolicy"
	$header +=  "MailboxDataEncryptionEnabled"
	$header +=  "GuestsEnabled"
	$header +=  "GroupsCreationEnabled"
	$header +=  "GroupsNamingPolicy"
	$header +=  "OrganizationSummary"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetOrgConfig.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetOrgConfig.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-OrgConfig sheet

#Region Get-Rbac sheet
Write-Host -Object "---- Starting Get-Rbac"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "Rbac"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Transport
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Members"
	$header +=  "Roles"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetRbac.xml") -eq $true)
{
	$DataFile = Import-Clixml "$RunLocation\output\ExOrg\ExOrg_GetRbac.xml"
	$RowCount = $DataFile.Count
	$ArrayRow = 0
	$BadArrayValue = @()
	$DataArray = New-Object 'object[,]' -ArgumentList $RowCount,$ColumnCount

	Foreach ($DataRow in $DataFile)
	{
		for ($ArrayColumn = 0 ; $ArrayColumn -lt $ColumnCount ; $ArrayColumn++)
        {
            $DataField = $([string]$DataRow.($header[($ArrayColumn)]))

			# Excel 2003 limit of 1823 characters
            if ($DataField.length -lt 1823)
                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField}
			# Excel 2007 limit of 8203 characters
            elseif (($Excel_ExOrg.version -ge 12) -and ($DataField.length -lt 8203))
                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField}
			# No known Excel 2010 limit
            elseif ($Excel_ExOrg.version -ge 14)
                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField}
            else
            {
                Write-Host -Object "Number of characters in array member exceeds the version of limitations of this version of Excel" -ForegroundColor Yellow
				Write-Host -Object "-- Writing value to temp variable" -ForegroundColor Yellow
                $DataArray[$ArrayRow,$ArrayColumn] = $DataField
                $BadArrayValue += "$ArrayRow,$ArrayColumn"
            }
        }
		$ArrayRow++
	}

    # Replace big values in $DataArray
    $BadArrayValue_count = $BadArrayValue.count
    $BadArrayValue_Temp = @()
    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
    {
        $BadArray_Split = $badarrayvalue[$i].Split(",")
        $BadArrayValue_Temp += $DataArray[$BadArray_Split[0],$BadArray_Split[1]]
        $DataArray[$BadArray_Split[0],$BadArray_Split[1]] = "**TEMP**"
		Write-Host -Object "-- Replacing long value with **TEMP**" -ForegroundColor Yellow
    }

	$EndCellRow = ($RowCount+1)
	$Data_range = $Worksheet.Range("a2","$EndCellColumn$EndCellRow")
	$Data_range.Value2 = $DataArray

    # Paste big values back into the spreadsheet
    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
    {
        $BadArray_Split = $badarrayvalue[$i].Split(",")
        # Adjust for header and $i=0
        $CellRow = [int]$BadArray_Split[0] + 2
        # Adjust for $i=0
        $CellColumn = [int]$BadArray_Split[1] + 1

        $Range = $Worksheet.cells.item($CellRow,$CellColumn)
        $Range.Value2 = $BadArrayValue_Temp[$i]
		Write-Host -Object "-- Pasting long value back in spreadsheet" -ForegroundColor Yellow
    }
}

	#EndRegion Get-Rbac sheet

#Region Get-RetentionPolicy sheet
Write-Host -Object "---- Starting Get-RetentionPolicy"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "RetentionPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Global
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "RetentionPolicyTagLinks"
	$header +=  "IsDefault"
	$header +=  "IsDefaultArbitrationMailbox"
	$header +=  "WhenCreatedUTC"
	$header +=  "WhenChangedUTC"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetRetentionPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetRetentionPolicy.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# WhenCreatedUTC
$Column_Range = $Worksheet.Range("C1","C$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# WhenChangedUTC
$Column_Range = $Worksheet.Range("D1","D$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
	#EndRegion Get-RetentionPolicy sheet

#Region Get-RetentionPolicyTag sheet
Write-Host -Object "---- Starting Get-RetentionPolicyTag"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "RetentionPolicyTag"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Global
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "MessageClassDisplayName"
	$header +=  "MessageClass"
	$header +=  "Description"
	$header +=  "RetentionEnabled"
	$header +=  "RetentionAction"
	$header +=  "AgeLimitForRetention"
	$header +=  "MoveToDestinationFolder"
	$header +=  "TriggerForRetention"
	$header +=  "MessageFormatForJournaling"
	$header +=  "JournalingEnabled"
	$header +=  "AddressForJournaling"
	$header +=  "LabelForJournaling"
	$header +=  "Type"
	$header +=  "IsDefaultAutoGroupPolicyTag"
	$header +=  "IsDefaultModeratedRecipientsPolicyTag"
	$header +=  "SystemTag"
	$header +=  "Comment"
	$header +=  "WhenCreatedUTC"
	$header +=  "WhenChangedUTC"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetRetentionPolicyTag.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetRetentionPolicyTag.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# AgeLimitForRetention
$Column_Range = $Worksheet.Range("F1","F$EndRow")
$Column_Range.cells.NumberFormat = "dd:hh:mm:ss"
# WhenCreatedUTC
$Column_Range = $Worksheet.Range("J1","J$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# WhenChangedUTC
$Column_Range = $Worksheet.Range("K1","K$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
	#EndRegion Get-RetentionPolicyTag sheet

# Receipient
#Region Get-CalendarProcessing sheet
Write-Host -Object "---- Starting Get-CalendarProcessing"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "CalendarProcessing"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header +=  "Mailbox"
	$header +=  "Identity"
	$header +=  "MailboxOwnerId"
	$header +=  "AutomateProcessing"
	$header +=  "AllowConflicts"
	$header +=  "BookingType"
	$header +=  "BookingWindowInDays"
	$header +=  "MaximumDurationInMinutes"
	$header +=  "AllowRecurringMeetings"
	$header +=  "ConflictPercentageAllowed"
	$header +=  "MaximumConflictInstances"
	$header +=  "ForwardRequestsToDelegates"
	$header +=  "DeleteAttachments"
	$header +=  "DeleteComments"
	$header +=  "RemovePrivateProperty"
	$header +=  "DeleteSubject"
	$header +=  "DeleteNonCalendarItems"
	$header +=  "TentativePendingApproval"
	$header +=  "ResourceDelegates"
	$header +=  "RequestOutOfPolicy"
	$header +=  "AllRequestOutOfPolicy"
	$header +=  "BookInPolicy"
	$header +=  "AllBookInPolicy"
	$header +=  "RequestInPolicy"
	$header +=  "AllRequestInPolicy"
	$header +=  "RemoveOldMeetingMessages"
	$header +=  "AddNewRequestsTentatively"
	$header +=  "ProcessExternalMeetingMessages"
	$header +=  "RemoveForwardedMeetingNotifications"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\GetCalendarProcessing") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\ExOrg\GetCalendarProcessing" | Where-Object {$_.name -match "~~GetCalendarProcessing"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\GetCalendarProcessing\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-CalendarProcessing sheet

#Region Get-CASMailbox sheet
Write-Host -Object "---- Starting Get-CASMailbox"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "CASMailbox"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "ServerName"
	$header +=  "ActiveSyncMailboxPolicy"
	$header +=  "ActiveSyncEnabled"
	$header +=  "HasActiveSyncDevicePartnership"
	$header +=  "OwaMailboxPolicy"
	$header +=  "OWAEnabled"
	$header +=  "ECPEnabled"
	$header +=  "PopEnabled"
	$header +=  "ImapEnabled"
	$header +=  "MAPIEnabled"
	$header +=  "MAPIBlockOutlookNonCachedMode"
	$header +=  "MAPIBlockOutlookVersions"
	$header +=  "MAPIBlockOutlookRpcHttp"
	$header +=  "EwsEnabled"
	$header +=  "EwsAllowOutlook"
	$header +=  "EwsAllowMacOutlook"
	$header +=  "EwsAllowEntourage"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\GetCASMailbox") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\ExOrg\GetCASMailbox" | Where-Object {$_.name -match "~~GetCASMailbox"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\GetCASMailbox\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-CASMailbox sheet

#Region Get-DistributionGroup sheet
Write-Host -Object "---- Starting Get-DistributionGroup"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "DistributionGroup"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Member Count"
	$header +=  "GroupType"
	$header +=  "IsDirSynced"
	$header +=  "ManagedBy"
	$header +=  "MemberJoinRestriction"
	$header +=  "MemberDepartRestriction"
	$header +=  "MigrationToUnifiedGroupInProgress"
	$header +=  "ExpansionServer"
	$header +=  "ReportToManagerEnabled"
	$header +=  "ReportToOriginatorEnabled"
	$header +=  "SendOofMessageToOriginatorEnabled"
	$header +=  "AcceptMessagesOnlyFrom"
	$header +=  "AcceptMessagesOnlyFromDLMembers"
	$header +=  "AcceptMessagesOnlyFromSendersOrMembers"
	$header +=  "Alias"
	$header +=  "OrganizationalUnit"
	$header +=  "CustomAttribute1"
	$header +=  "CustomAttribute10"
	$header +=  "CustomAttribute11"
	$header +=  "CustomAttribute12"
	$header +=  "CustomAttribute13"
	$header +=  "CustomAttribute14"
	$header +=  "CustomAttribute15"
	$header +=  "CustomAttribute2"
	$header +=  "CustomAttribute3"
	$header +=  "CustomAttribute4"
	$header +=  "CustomAttribute5"
	$header +=  "CustomAttribute6"
	$header +=  "CustomAttribute7"
	$header +=  "CustomAttribute8"
	$header +=  "CustomAttribute9"
	$header +=  "ExtensionCustomAttribute1"
	$header +=  "ExtensionCustomAttribute2"
	$header +=  "ExtensionCustomAttribute3"
	$header +=  "ExtensionCustomAttribute4"
	$header +=  "ExtensionCustomAttribute5"
	$header +=  "DisplayName"
	$header +=  "GrantSendOnBehalfTo"
	$header +=  "HiddenFromAddressListsEnabled"
	$header +=  "MaxSendSize"
	$header +=  "MaxReceiveSize"
	$header +=  "ModeratedBy"
	$header +=  "ModerationEnabled"
	$header +=  "RejectMessagesFrom"
	$header +=  "RejectMessagesFromDLMembers"
	$header +=  "RejectMessagesFromSendersOrMembers"
	$header +=  "RequireSenderAuthenticationEnabled"
	$header +=  "PrimarySmtpAddress"
	$header +=  "RecipientType"
	$header +=  "RecipientTypeDetails"
	$header +=  "WhenCreatedUTC"
	$header +=  "WhenChangedUTC"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetDistributionGroup.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetDistributionGroup.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# WhenCreatedUTC
$Column_Range = $Worksheet.Range("AC1","AC$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# WhenChangedUTC
$Column_Range = $Worksheet.Range("AD1","AD$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
	#EndRegion Get-DistributionGroup sheet

#Region Get-DynamicDistributionGroup sheet
Write-Host -Object "---- Starting Get-DynamicDistributionGroup"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "DynamicDistributionGroup"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "RecipientContainer"
	$header +=  "RecipientFilter"
	$header +=  "LdapRecipientFilter"
	$header +=  "IncludedRecipients"
	$header +=  "ManagedBy"
	$header +=  "ExpansionServer"
	$header +=  "ReportToManagerEnabled"
	$header +=  "ReportToOriginatorEnabled"
	$header +=  "SendOofMessageToOriginatorEnabled"
	$header +=  "AcceptMessagesOnlyFrom"
	$header +=  "AcceptMessagesOnlyFromDLMembers"
	$header +=  "AcceptMessagesOnlyFromSendersOrMembers"
	$header +=  "Alias"
	$header +=  "OrganizationalUnit"
	$header +=  "CustomAttribute1"
	$header +=  "CustomAttribute10"
	$header +=  "CustomAttribute11"
	$header +=  "CustomAttribute12"
	$header +=  "CustomAttribute13"
	$header +=  "CustomAttribute14"
	$header +=  "CustomAttribute15"
	$header +=  "CustomAttribute2"
	$header +=  "CustomAttribute3"
	$header +=  "CustomAttribute4"
	$header +=  "CustomAttribute5"
	$header +=  "CustomAttribute6"
	$header +=  "CustomAttribute7"
	$header +=  "CustomAttribute8"
	$header +=  "CustomAttribute9"
	$header +=  "ExtensionCustomAttribute1"
	$header +=  "ExtensionCustomAttribute2"
	$header +=  "ExtensionCustomAttribute3"
	$header +=  "ExtensionCustomAttribute4"
	$header +=  "ExtensionCustomAttribute5"
	$header +=  "DisplayName"
	$header +=  "GrantSendOnBehalfTo"
	$header +=  "HiddenFromAddressListsEnabled"
	$header +=  "MaxSendSize"
	$header +=  "MaxReceiveSize"
	$header +=  "ModeratedBy"
	$header +=  "ModerationEnabled"
	$header +=  "PrimarySmtpAddress"
	$header +=  "RecipientType"
	$header +=  "RecipientTypeDetails"
	$header +=  "RejectMessagesFrom"
	$header +=  "RejectMessagesFromDLMembers"
	$header +=  "RejectMessagesFromSendersOrMembers"
	$header +=  "RequireSenderAuthenticationEnabled"
	$header +=  "WhenCreatedUTC"
	$header +=  "WhenChangedUTC"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetDynamicDistributionGroup.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetDynamicDistributionGroup.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-DynamicDistributionGroup sheet

#Region Get-Mailbox sheet
Write-Host -Object "---- Starting Get-Mailbox"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "Mailbox"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header +=  "Mailbox"
	$header +=  "Identity"
	$header +=  "Database"
	$header +=  "UseDatabaseRetentionDefaults"
	$header +=  "RetainDeletedItemsUntilBackup"
	$header +=  "DeliverToMailboxAndForward"
	$header +=  "LitigationHoldEnabled"
	$header +=  "SingleItemRecoveryEnabled"
	$header +=  "RetentionHoldEnabled"
	$header +=  "EndDateForRetentionHold"
	$header +=  "StartDateForRetentionHold"
	$header +=  "RetentionComment"
	$header +=  "RetentionUrl"
	$header +=  "LitigationHoldDate"
	$header +=  "LitigationHoldOwner"
	$header +=  "ElcProcessingDisabled"
	$header +=  "ComplianceTagHoldApplied"
	$header +=  "LitigationHoldDuration"
	$header +=  "ManagedFolderMailboxPolicy"
	$header +=  "RetentionPolicy"
	$header +=  "AddressBookPolicy"
	$header +=  "CalendarRepairDisabled"
	$header +=  "ForwardingAddress"
	$header +=  "ForwardingSmtpAddress"
	$header +=  "RetainDeletedItemsFor"
	$header +=  "IsMailboxEnabled"
	$header +=  "ProhibitSendQuota"
	$header +=  "ProhibitSendReceiveQuota"
	$header +=  "RecoverableItemsQuota"
	$header +=  "RecoverableItemsWarningQuota"
	$header +=  "CalendarLoggingQuota"
	$header +=  "IsResource"
	$header +=  "IsLinked"
	$header +=  "IsShared"
	$header +=  "IsRootPublicFolderMailbox"
	$header +=  "RoomMailboxAccountEnabled"
	$header +=  "SCLDeleteThreshold"
	$header +=  "SCLDeleteEnabled"
	$header +=  "SCLRejectThreshold"
	$header +=  "SCLRejectEnabled"
	$header +=  "SCLQuarantineThreshold"
	$header +=  "SCLQuarantineEnabled"
	$header +=  "SCLJunkThreshold"
	$header +=  "SCLJunkEnabled"
	$header +=  "AntispamBypassEnabled"
	$header +=  "ServerName"
	$header +=  "UseDatabaseQuotaDefaults"
	$header +=  "IssueWarningQuota"
	$header +=  "RulesQuota"
	$header +=  "Office"
	$header +=  "UserPrincipalName"
	$header +=  "UMEnabled"
	$header +=  "WindowsLiveID"
	$header +=  "MicrosoftOnlineServicesID"
	$header +=  "RoleAssignmentPolicy"
	$header +=  "DefaultPublicFolderMailbox"
	$header +=  "EffectivePublicFolderMailbox"
	$header +=  "SharingPolicy"
	$header +=  "RemoteAccountPolicy"
	$header +=  "MailboxPlan"
	$header +=  "ArchiveDatabase"
	$header +=  "ArchiveName"
	$header +=  "ArchiveQuota"
	$header +=  "ArchiveWarningQuota"
	$header +=  "ArchiveDomain"
	$header +=  "ArchiveStatus"
	$header +=  "ArchiveState"
	$header +=  "AutoExpandingArchiveEnabled"
	$header +=  "DisabledMailboxLocations"
	$header +=  "RemoteRecipientType"
	$header +=  "UserSMimeCertificate"
	$header +=  "UserCertificate"
	$header +=  "CalendarVersionStoreDisabled"
	$header +=  "SKUAssigned"
	$header +=  "AuditEnabled"
	$header +=  "AuditLogAgeLimit"
	$header +=  "UsageLocation"
	$header +=  "AccountDisabled"
	$header +=  "NonCompliantDevices"
	$header +=  "DataEncryptionPolicy"
	$header +=  "HasPicture"
	$header +=  "HasSpokenName"
	$header +=  "IsDirSynced"
	$header +=  "AcceptMessagesOnlyFrom"
	$header +=  "AcceptMessagesOnlyFromDLMembers"
	$header +=  "AcceptMessagesOnlyFromSendersOrMembers"
	$header +=  "Alias"
	$header +=  "CustomAttribute1"
	$header +=  "CustomAttribute10"
	$header +=  "CustomAttribute11"
	$header +=  "CustomAttribute12"
	$header +=  "CustomAttribute13"
	$header +=  "CustomAttribute14"
	$header +=  "CustomAttribute15"
	$header +=  "CustomAttribute2"
	$header +=  "CustomAttribute3"
	$header +=  "CustomAttribute4"
	$header +=  "CustomAttribute5"
	$header +=  "CustomAttribute6"
	$header +=  "CustomAttribute7"
	$header +=  "CustomAttribute8"
	$header +=  "CustomAttribute9"
	$header +=  "ExtensionCustomAttribute1"
	$header +=  "ExtensionCustomAttribute2"
	$header +=  "ExtensionCustomAttribute3"
	$header +=  "ExtensionCustomAttribute4"
	$header +=  "ExtensionCustomAttribute5"
	$header +=  "DisplayName"
	$header +=  "EmailAddresses"
	$header +=  "GrantSendOnBehalfTo"
	$header +=  "HiddenFromAddressListsEnabled"
	$header +=  "MaxSendSize"
	$header +=  "MaxReceiveSize"
	$header +=  "ModeratedBy"
	$header +=  "ModerationEnabled"
	$header +=  "EmailAddressPolicyEnabled"
	$header +=  "PrimarySmtpAddress"
	$header +=  "RecipientType"
	$header +=  "RecipientTypeDetails"
	$header +=  "RejectMessagesFrom"
	$header +=  "RejectMessagesFromDLMembers"
	$header +=  "RejectMessagesFromSendersOrMembers"
	$header +=  "RequireSenderAuthenticationEnabled"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\GetMbx") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\ExOrg\GetMbx" | Where-Object {$_.name -match "~~GetMbx"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\GetMbx\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-Mailbox sheet

#Region Get-MailboxFolderStatistics sheet
Write-Host -Object "---- Starting Get-MailboxFolderStatistics"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "MailboxFolderStatistics"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header +=  "Mailbox"
	$header +=  "Name"
	$header +=  "FolderType"
	$header +=  "Identity"
	$header +=  "ItemsInFolder"
	$header +=  "FolderSize"
	$header +=  "FolderSize (MB)"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = [int]$header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\GetMbxFolderStatistics") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\ExOrg\GetMbxFolderStatistics" | Where-Object {$_.name -match "~~GetMbxFolderStatistics"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\GetMbxFolderStatistics\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-MailboxFolderStatistics sheet

#Region Get-MailboxPermission sheet
Write-Host -Object "---- Starting Get-MailboxPermission"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "MailboxPermission"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header +=  "Mailbox"
	$header +=  "Identity"
	$header +=  "User (ACL'ed on Mbx)"
	$header +=  "AccessRights"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\GetMbxPermission") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\ExOrg\GetMbxPermission" | Where-Object {$_.name -match "~~GetMbxPerm"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\GetMbxPermission\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-MailboxPermission sheet

#Region Get-MailboxStatistics sheet
Write-Host -Object "---- Starting Get-MailboxStatistics"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "MailboxStatistics"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header +=  "Mailbox"
	$header +=  "DisplayName"
	$header +=  "ServerName"
	$header +=  "Database"
	$header +=  "ItemCount"
	$header +=  "TotalItemSize"
	$header +=  "TotalItemSize (MB)"
	$header +=  "TotalDeletedItemSize"
	$header +=  "TotalDeletedItemSize (MB)"
	$header +=  "IsEncrypted"
	$header +=  "MailboxType"
	$header +=  "MailboxTypeDetail"
	$header +=  "IsArchiveMailbox"
	$header +=  "FastIsEnabled"
	$header +=  "BigFunnelIsEnabled"
	$header +=  "DatabaseIssueWarningQuota"
	$header +=  "DatabaseProhibitSendQuota"
	$header +=  "DatabaseProhibitSendReceiveQuota"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\GetMbxStatistics") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\ExOrg\GetMbxStatistics" | Where-Object {$_.name -match "~~GetMbxStatistics"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\GetMbxStatistics\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-MailboxStatistics sheet

#Region Get-PublicFolder sheet
Write-Host -Object "---- Starting Get-PublicFolder"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "PublicFolder"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "ParentPath"
	$header +=  "AgeLimit"
	$header +=  "HasSubFolders"
	$header +=  "MailEnabled"
	$header +=  "MaxItemSize"
	$header +=  "ContentMailboxName"
	$header +=  "ContentMailboxGuid"
	$header +=  "PerUserReadStateEnabled"
	$header +=  "RetainDeletedItemsFor"
	$header +=  "ProhibitPostQuota"
	$header +=  "IssueWarningQuota"
	$header +=  "FolderSize"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetPublicFolder.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetPublicFolder.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-PublicFolder sheet

#Region Get-PublicFolderStatistics sheet
Write-Host -Object "---- Starting Get-PublicFolderStatistics"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "PublicFolderStatistics"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header +=  "AdminDisplayName"
	$header +=  "FolderPath"
	$header +=  "ItemCount"
	$header +=  "TotalItemSize"
	$header +=  "TotalItemSize (MB)"
	$header +=  "CreationTime"				# Column G
	$header +=  "LastModificationTime"		# Column H
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

	if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetPublicFolderStats.txt") -eq $true)
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetPublicFolderStats.txt")
		# Send the data to the function to process and add to the Excel worksheet
		Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
	}

# Format time/date columns
$EndRow = $DataFile.count + 1
# CreationTime
$Column_Range = $Worksheet.Range("G1","G$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# LastModificationTime
$Column_Range = $Worksheet.Range("H1","H$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
	#EndRegion Get-PublicFolderStatistics sheet

#Region Quota sheet
Write-Host -Object "---- Starting Quota"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "Quota"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header +=  "ServerName"
	$header +=  "Alias"
	$header +=  "UseDatabaseQuotaDefaults"
	$header +=  "IssueWarningQuota"
	$header +=  "ProhibitSendQuota"
	$header +=  "ProhibitSendReceiveQuota"
	$header +=  "RecoverableItemsQuota"
	$header +=  "RecoverableItemsWarningQuota"
	$header +=  "LitigationHoldEnabled"
	$header +=  "RetentionHoldEnabled"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\Quota") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\ExOrg\Quota" | Where-Object {$_.name -match "~~Quota"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\Quota\" + $file)
	}
	$RowCount = $DataFile.Count
	# Not using the Process-Datafile function because Quota needs special data handling for formatting
	$ArrayRow = 0
	$DataArray = New-Object 'object[,]' -ArgumentList $RowCount,$ColumnCount
	Foreach ($DataRow in $DataFile)
	{
		$DataField = $DataRow.Split("`t")
		for ($ArrayColumn=0;$ArrayColumn -le 2;$ArrayColumn++)
		{
            # Excel chokes if field starts with = so we'll prepend the ' to the string if it does
            If ($DataField[$ArrayColumn].substring(0,1) -eq "=") {$DataField[$ArrayColumn] = "'"+$DataField[$ArrayColumn]}

			$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]
		}
		if ($DataField[2] -eq "TRUE")
		{
			$DataArray[$ArrayRow,3] =  "- - -"
			$DataArray[$ArrayRow,4] =  "- - -"
			$DataArray[$ArrayRow,5] =  "- - -"
		}
		else
		{
			$DataArray[$ArrayRow,3] =  $DataField[3]
			$DataArray[$ArrayRow,4] =  $DataField[4]
			$DataArray[$ArrayRow,5] =  $DataField[5]
		}
		for ($ArrayColumn=6;$ArrayColumn -le $ColumnCount-1;$ArrayColumn++)
		{
			$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]
		}
		#write-host $ArrayRow " of " $RowCount

		$ArrayRow++
	}

	$EndCellRow = ($RowCount+1)
	$Data_range = $Worksheet.Range("a2","$EndCellColumn$EndCellRow")
	$Data_range.Value2 = $DataArray
}
	#EndRegion Quota sheet

# Transport
#Region Get-AcceptedDomain sheet
Write-Host -Object "---- Starting Get-AcceptedDomain"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "AcceptedDomain"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Transport
	$row = 1
	$header = @()
	$header +=  "DomainName"
	$header +=  "CatchAllRecipientID"
	$header +=  "DomainType"
	$header +=  "MatchSubDomains"
	$header +=  "AddressBookEnabled"
	$header +=  "Default"
	$header +=  "EmailOnly"
	$header +=  "ExternallyManaged"
	$header +=  "AuthenticationType"
	$header +=  "LiveIdInstanceType"
	$header +=  "PendingRemoval"
	$header +=  "PendingCompletion"
	$header +=  "FederatedOrganizationLink"
	$header +=  "MailFlowPartner"
	$header +=  "OutboundOnly"
	$header +=  "PendingFederatedAccountNamespace"
	$header +=  "PendingFederatedDomain"
	$header +=  "IsCoexistenceDomain"
	$header +=  "PerimeterDuplicateDetected"
	$header +=  "IsDefaultFederatedDomain"
	$header +=  "EnableNego2Authentication"
	$header +=  "InitialDomain"
	$header +=  "Name"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetAcceptedDomain.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetAcceptedDomain.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#endRegion Get-AcceptedDomain sheet

#Region Get-InboundConnector sheet
Write-Host -Object "---- Starting Get-InboundConnector"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "InboundConnector"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Transport
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Enabled"
	$header +=  "ConnectorType"
	$header +=  "ConnectorSource"
	$header +=  "Comment"
	$header +=  "SenderIPAddresses"
	$header +=  "SenderDomains"
	$header +=  "AssociatedAcceptedDomains"
	$header +=  "RequireTls"
	$header +=  "RemoteIPRanges"
	$header +=  "RestrictDomainsToIPAddresses"
	$header +=  "RestrictDomainsToCertificate"
	$header +=  "CloudServicesMailEnabled"
	$header +=  "TreatMessagesAsInternal"
	$header +=  "TlsSenderCertificateName"
	$header +=  "DetectSenderIPBySkippingLastIP"
	$header +=  "DetectSenderIPBySkippingTheseIPs"
	$header +=  "DetectSenderIPRecipientList"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetInboundConnector.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetInboundConnector.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-InboundConnector sheet

#Region Get-OutboundConnector sheet
Write-Host -Object "---- Starting Get-OutboundConnector"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "OutboundConnector"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Transport
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Enabled"
	$header +=  "UseMXRecord"
	$header +=  "Comment"
	$header +=  "ConnectorType"
	$header +=  "ConnectorSource"
	$header +=  "RecipientDomains"
	$header +=  "SmartHosts"
	$header +=  "TlsDomain"
	$header +=  "TlsSettings"
	$header +=  "IsTransportRuleScoped"
	$header +=  "RouteAllMessagesViaOnPremises"
	$header +=  "CloudServicesMailEnabled"
	$header +=  "AllAcceptedDomains"
	$header +=  "IsValidated"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetOutboundConnector.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetOutboundConnector.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

#EndRegion Get-OutboundConnector sheet

#Region Get-RemoteDomain sheet
Write-Host -Object "---- Starting Get-RemoteDomain"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "RemoteDomain"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Transport
	$row = 1
	$header = @()
	$header +=  "Identity"
	$header +=  "DomainName"
	$header +=  "IsInternal"
	$header +=  "TargetDeliveryDomain"
	$header +=  "CharacterSet"
	$header +=  "NonMimeCharacterSet"
	$header +=  "AllowedOOFType"
	$header +=  "AutoReplyEnabled"
	$header +=  "AutoForwardEnabled"
	$header +=  "DeliveryReportEnabled"
	$header +=  "NDREnabled"
	$header +=  "MeetingForwardNotificationEnabled"
	$header +=  "ContentType"
	$header +=  "DisplaySenderName"
	$header +=  "TNEFEnabled"
	$header +=  "LineWrapSize"
	$header +=  "TrustedMailOutboundEnabled"
	$header +=  "TrustedMailInboundEnabled"
	$header +=  "UseSimpleDisplayName"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetRemoteDomain.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetRemoteDomain.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-RemoteDomain sheet

#Region Get-TransportConfig sheet
Write-Host -Object "---- Starting Get-TransportConfig"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "TransportConfig"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Transport
	$row = 1
	$header = @()
	$header += "AdminDisplayName"
    $header += "ClearCategories"
    $header += "ConvertDisclaimerWrapperToEml"
    $header += "ConvertReportToMessage"
   	$header += "DSNConversionMode"
    $header += "ExternalDelayDsnEnabled"
    $header += "ExternalDsnDefaultLanguage"
    $header += "ExternalDsnLanguageDetectionEnabled"
    $header += "ExternalDsnMaxMessageAttachSize"
    $header += "ExternalDsnReportingAuthority"
    $header += "ExternalDsnSendHtml"
    $header += "ExternalPostmasterAddress"
    $header += "GenerateCopyOfDSNFor"
    $header += "Guid"
    $header += "HeaderPromotionModeSetting"
    $header += "HygieneSuite"
    $header += "Identity"
    $header += "InternalDelayDsnEnabled"
    $header += "InternalDsnDefaultLanguage"
    $header += "InternalDsnLanguageDetectionEnabled"
    $header += "InternalDsnMaxMessageAttachSize"
    $header += "InternalDsnReportingAuthority"
    $header += "InternalDsnSendHtml"
    $header += "InternalSMTPServers"
    $header += "JournalingReportNdrTo"
    $header += "LegacyJournalingMigrationEnabled"
    $header += "MaxDumpsterSizePerDatabase"
    $header += "MaxDumpsterTime"
    $header += "MaxReceiveSize"
    $header += "MaxRecipientEnvelopeLimit"
    $header += "MaxSendSize"
    $header += "MigrationEnabled"
    $header += "OpenDomainRoutingEnabled"
    $header += "OrganizationFederatedMailbox"
    $header += "OrganizationId"
    $header += "OriginatingServer"
    $header += "OtherWellKnownObjects"
    $header += "PreserveReportBodypart"
    $header += "Rfc2231EncodingEnabled"
    $header += "ShadowHeartbeatRetryCount"
    $header += "ShadowHeartbeatTimeoutInterval"
    $header += "ShadowMessageAutoDiscardInterval"
    $header += "ShadowRedundancyEnabled"
    $header += "SupervisionTags"
    $header += "TLSReceiveDomainSecureList"
    $header += "TLSSendDomainSecureList"
    $header += "VerifySecureSubmitEnabled"
    $header += "VoicemailJournalingEnabled"
    $header += "WhenChangedUTC"
    $header += "WhenCreatedUTC"
    $header += "Xexch50Enabled"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetTransportConfig.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetTransportConfig.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# ShadowHeartbeatTimeoutInterval
$Column_Range = $Worksheet.Range("AO1","AO$EndRow")
$Column_Range.cells.NumberFormat = "hh:mm:ss"
# ShadowMessageAutoDiscardInterval
$Column_Range = $Worksheet.Range("AP1","AP$EndRow")
$Column_Range.cells.NumberFormat = "dd:hh:mm:ss"
# WhenCreatedUTC
$Column_Range = $Worksheet.Range("AW1","AW$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# WhenChangedUTC
$Column_Range = $Worksheet.Range("AX1","AX$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
	#EndRegion Get-TransportConfig sheet

#Region Get-TransportRule sheet
Write-Host -Object "---- Starting Get-TransportRule"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "TransportRule"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Transport
	$row = 1
	$header = @()
	$header +=  "Identity"
	$header +=  "Priority"
	$header +=  "Comments"
	$header +=  "Description"
	$header +=  "RuleVersion"
	$header +=  "State"
	$header +=  "WhenChanged"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetTransportRule.xml") -eq $true)
{
	$DataFile = Import-Clixml "$RunLocation\output\ExOrg\ExOrg_GetTransportRule.xml"
	$RowCount = $DataFile.Count
	$ArrayRow = 0
	$BadArrayValue = @()
	$DataArray = New-Object 'object[,]' -ArgumentList $RowCount,$ColumnCount

	Foreach ($DataRow in $DataFile)
	{
		for ($ArrayColumn = 0 ; $ArrayColumn -lt $ColumnCount ; $ArrayColumn++)
        {
            $DataField = $([string]$DataRow.($header[($ArrayColumn)]))

			# Excel 2003 limit of 1823 characters
            if ($DataField.length -lt 1823)
                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField}
			# Excel 2007 limit of 8203 characters
            elseif (($Excel_ExOrg.version -ge 12) -and ($DataField.length -lt 8203))
                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField}
			# No known Excel 2010 limit
            elseif ($Excel_ExOrg.version -ge 14)
                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField}
            else
            {
                Write-Host -Object "Number of characters in array member exceeds the version of limitations of this version of Excel" -ForegroundColor Yellow
				Write-Host -Object "-- Writing value to temp variable" -ForegroundColor Yellow
                $DataArray[$ArrayRow,$ArrayColumn] = $DataField
                $BadArrayValue += "$ArrayRow,$ArrayColumn"
            }
        }
		$ArrayRow++
	}

    # Replace big values in $DataArray
    $BadArrayValue_count = $BadArrayValue.count
    $BadArrayValue_Temp = @()
    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
    {
        $BadArray_Split = $badarrayvalue[$i].Split(",")
        $BadArrayValue_Temp += $DataArray[$BadArray_Split[0],$BadArray_Split[1]]
        $DataArray[$BadArray_Split[0],$BadArray_Split[1]] = "**TEMP**"
		Write-Host -Object "-- Replacing long value with **TEMP**" -ForegroundColor Yellow
    }

	$EndCellRow = ($RowCount+1)
	$Data_range = $Worksheet.Range("a2","$EndCellColumn$EndCellRow")
	$Data_range.Value2 = $DataArray

    # Paste big values back into the spreadsheet
    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
    {
        $BadArray_Split = $badarrayvalue[$i].Split(",")
        # Adjust for header and $i=0
        $CellRow = [int]$BadArray_Split[0] + 2
        # Adjust for $i=0
        $CellColumn = [int]$BadArray_Split[1] + 1

        $Range = $Worksheet.cells.item($CellRow,$CellColumn)
        $Range.Value2 = $BadArrayValue_Temp[$i]
		Write-Host -Object "-- Pasting long value back in spreadsheet" -ForegroundColor Yellow
    }
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# WhenChangedUTC
$Column_Range = $Worksheet.Range("G1","G$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"

	#EndRegion Get-TransportRule sheet

# Um
#Region Get-UmAutoAttendant sheet
Write-Host -Object "---- Starting Get-UmAutoAttendant"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "UmAutoAttendant"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Um
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "SpeechEnabled"
	$header +=  "AllowDialPlanSubscribers"
	$header +=  "AllowExtensions"
	$header +=  "AllowedInCountryOrRegionGroups"
	$header +=  "AllowedInternationalGroups"
	$header +=  "CallSomeoneEnabled"
	$header +=  "ContactScope"
	$header +=  "ContactAddressList"
	$header +=  "SendVoiceMsgEnabled"
	$header +=  "BusinessHourSchedule"
	$header +=  "PilotIdentifierList"
	$header +=  "UmDialPlan"
	$header +=  "DtmfFallbackAutoAttendant"
	$header +=  "HolidaySchedule"
	$header +=  "TimeZone"
	$header +=  "TimeZoneName"
	$header +=  "MatchedNameSelectionMethod"
	$header +=  "BusinessLocation"
	$header +=  "WeekStartDay"
	$header +=  "Status"
	$header +=  "Language"
	$header +=  "OperatorExtension"
	$header +=  "InfoAnnouncementFilename"
	$header +=  "InfoAnnouncementEnabled"
	$header +=  "NameLookupEnabled"
	$header +=  "StarOutToDialPlanEnabled"
	$header +=  "ForwardCallsToDefaultMailbox"
	$header +=  "DefaultMailbox"
	$header +=  "BusinessName"
	$header +=  "BusinessHoursWelcomeGreetingFilename"
	$header +=  "BusinessHoursWelcomeGreetingEnabled"
	$header +=  "BusinessHoursMainMenuCustomPromptFilename"
	$header +=  "BusinessHoursMainMenuCustomPromptEnabled"
	$header +=  "BusinessHoursTransferToOperatorEnabled"
	$header +=  "BusinessHoursKeyMapping"
	$header +=  "BusinessHoursKeyMappingEnabled"
	$header +=  "AfterHoursWelcomeGreetingFilename"
	$header +=  "AfterHoursWelcomeGreetingEnabled"
	$header +=  "AfterHoursMainMenuCustomPromptFilename"
	$header +=  "AfterHoursMainMenuCustomPromptEnabled"
	$header +=  "AfterHoursTransferToOperatorEnabled"
	$header +=  "AfterHoursKeyMapping"
	$header +=  "AfterHoursKeyMappingEnabled"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetUmAutoAttendant.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetUmAutoAttendant.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-UmAutoAttendant sheet

#Region Get-UmDialPlan sheet
Write-Host -Object "---- Starting Get-UmDialPlan"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "UmDialPlan"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Um
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "NumberOfDigitsInExtension"
	$header +=  "LogonFailuresBeforeDisconnect"
	$header +=  "AccessTelephoneNumbers"
	$header +=  "FaxEnabled"
	$header +=  "InputFailuresBeforeDisconnect"
	$header +=  "OutsideLineAccessCode"
	$header +=  "DialByNamePrimary"
	$header +=  "DialByNameSecondary"
	$header +=  "AudioCodec"
	$header +=  "AvailableLanguages"
	$header +=  "DefaultLanguage"
	$header +=  "VoIPSecurity"
	$header +=  "MaxCallDuration"
	$header +=  "MaxRecordingDuration"
	$header +=  "RecordingIdleTimeout"
	$header +=  "PilotIdentifierList"
	$header +=  "UMServers"
	$header +=  "UMMailboxPolicies"
	$header +=  "UMAutoAttendants"
	$header +=  "WelcomeGreetingEnabled"
	$header +=  "AutomaticSpeechRecognitionEnabled"
	$header +=  "PhoneContext"
	$header +=  "WelcomeGreetingFilename"
	$header +=  "InfoAnnouncementFilename"
	$header +=  "OperatorExtension"
	$header +=  "DefaultOutboundCallingLineId"
	$header +=  "Extension"
	$header +=  "MatchedNameSelectionMethod"
	$header +=  "InfoAnnouncementEnabled"
	$header +=  "InternationalAccessCode"
	$header +=  "NationalNumberPrefix"
	$header +=  "InCountryOrRegionNumberFormat"
	$header +=  "InternationalNumberFormat"
	$header +=  "CallSomeoneEnabled"
	$header +=  "ContactScope"
	$header +=  "ContactAddressList"
	$header +=  "SendVoiceMsgEnabled"
	$header +=  "UMAutoAttendant"
	$header +=  "AllowDialPlanSubscribers"
	$header +=  "AllowExtensions"
	$header +=  "AllowedInCountryOrRegionGroups"
	$header +=  "AllowedInternationalGroups"
	$header +=  "ConfiguredInCountryOrRegionGroups"
	$header +=  "LegacyPromptPublishingPoint"
	$header +=  "ConfiguredInternationalGroups"
	$header +=  "UMIPGateway"
	$header +=  "URIType"
	$header +=  "SubscriberType"
	$header +=  "GlobalCallRoutingScheme"
	$header +=  "TUIPromptEditingEnabled"
	$header +=  "CallAnsweringRulesEnabled"
	$header +=  "SipResourceIdentifierRequired"
	$header +=  "FDSPollingInterval"
	$header +=  "EquivalentDialPlanPhoneContexts"
	$header +=  "NumberingPlanFormats"
	$header +=  "AllowHeuristicADCallingLineIdResolution"
	$header +=  "CountryOrRegionCode"
	$header +=  "ExchangeVersion"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetUmDialPlan.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetUmDialPlan.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-UmDialPlan sheet

#Region Get-UmIpGateway sheet
Write-Host -Object "---- Starting Get-UmIpGateway"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "UmIpGateway"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Um
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "Address"
	$header +=  "OutcallsAllowed"
	$header +=  "Status"
	$header +=  "Port"
	$header +=  "Simulator"
	$header +=  "DelayedSourcePartyInfoEnabled"
	$header +=  "MessageWaitingIndicatorAllowed"
	$header +=  "HuntGroups"
	$header +=  "GlobalCallRoutingScheme"
	$header +=  "ForwardingAddress"
	$header +=  "NumberOfDigitsInExtension"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetUmIpGateway.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetUmIpGateway.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-UmIpGateway sheet

#Region Get-UmMailbox sheet
Write-Host -Object "---- Starting Get-UmMailbox"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "UmMailbox"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Um
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "EmailAddresses"
	$header +=  "UMAddresses"
	$header +=  "LegacyExchangeDN"
	$header +=  "LinkedMasterAccount"
	$header +=  "PrimarySmtpAddress"
	$header +=  "SamAccountName"
	$header +=  "ServerLegacyDN"
	$header +=  "ServerName"
	$header +=  "UMDtmfMap"
	$header +=  "UMEnabled"
	$header +=  "TUIAccessToCalendarEnabled"
	$header +=  "FaxEnabled"
	$header +=  "TUIAccessToEmailEnabled"
	$header +=  "SubscriberAccessEnabled"
	$header +=  "MissedCallNotificationEnabled"
	$header +=  "UMSMSNotificationOption"
	$header +=  "PinlessAccessToVoiceMailEnabled"
	$header +=  "AnonymousCallersCanLeaveMessages"
	$header +=  "AutomaticSpeechRecognitionEnabled"
	$header +=  "PlayOnPhoneEnabled"
	$header +=  "CallAnsweringRulesEnabled"
	$header +=  "AllowUMCallsFromNonUsers"
	$header +=  "OperatorNumber"
	$header +=  "PhoneProviderId"
	$header +=  "UMDialPlan"
	$header +=  "UMMailboxPolicy"
	$header +=  "Extensions"
	$header +=  "CallAnsweringAudioCodec"
	$header +=  "SIPResourceIdentifier"
	$header +=  "PhoneNumber"
	$header +=  "AirSyncNumbers"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\GetUmMailbox") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\ExOrg\GetUmMailbox" | Where-Object {$_.name -match "~~GetUmMailbox"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\GetUmMailbox\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-UmMailbox sheet

##Region Get-UmMailboxConfiguration sheet
#Write-Host -Object "---- Starting Get-UmMailboxConfiguration"
#	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
#	$Worksheet.name = "UmMailboxConfiguration"
#	$Worksheet.Tab.ColorIndex = $intColorIndex_Um
#	$row = 1
#	$header = @()
#	$header +=  "Identity"
#	$header +=  "Greeting"
#	$header +=  "HasCustomVoicemailGreeting"
#	$header +=  "HasCustomAwayGreeting"
#	$header +=  "IsValid"
#	$a = [int][char]'a' -1
#	if ($header.GetLength(0) -gt 26)
#	{$EndCellColumn = [char]([int][math]::Floor($header.GetLength(0)/26) + $a) + [char](($header.GetLength(0)%26) + $a)}
#	else
#	{$EndCellColumn = [char]($header.GetLength(0) + $a)}
#	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
#	$Header_range.value2 = $header
#	$Header_range.cells.interior.colorindex = 45
#	$Header_range.cells.font.colorindex = 0
#	$Header_range.cells.font.bold = $true
#	$row++
#	$intSheetCount++
#	$ColumnCount = $header.Count
#	$DataFile = @()
#	$EndCellRow = 1
#
#if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\GetUmMailboxConfiguration") -eq $true)
#{
#	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\ExOrg\GetUmMailboxConfiguration" | Where-Object {$_.name -match "~~GetUmMailboxConfiguration"}))
#	{
#		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\GetUmMailboxConfiguration\" + $file)
#	}
#	$RowCount = $DataFile.Count
#	$ArrayRow = 0
#	$BadArrayValue = @()
#	$DataArray = New-Object 'object[,]' -ArgumentList $RowCount,$ColumnCount
#	Foreach ($DataRow in $DataFile)
#	{
#		$DataField = $DataRow.Split("`t")
#		for ($ArrayColumn = 0 ; $ArrayColumn -lt $ColumnCount ; $ArrayColumn++)
#		{
#			# Excel 2003 limit of 1823 characters
#            if ($DataField[$ArrayColumn].length -lt 1823)
#                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
#			# Excel 2007 limit of 8203 characters
#            elseif (($Excel_ExOrg.version -ge 12) -and ($DataField[$ArrayColumn].length -lt 8203))
#                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
#			# No known Excel 2010 limit
#            elseif ($Excel_ExOrg.version -ge 14)
#                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
#            else
#            {
#                Write-Host -Object "Number of characters in array member exceeds the version of limitations of this version of Excel" -ForegroundColor Yellow
#				Write-Host -Object "-- Writing value to temp variable" -ForegroundColor Yellow
#                $DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]
#                $BadArrayValue += "$ArrayRow,$ArrayColumn"
#            }
#		}
#		$ArrayRow++
#	}
#
#    # Replace big values in $DataArray
#    $BadArrayValue_count = $BadArrayValue.count
#    $BadArrayValue_Temp = @()
#    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
#    {
#        $BadArray_Split = $badarrayvalue[$i].Split(",")
#        $BadArrayValue_Temp += $DataArray[$BadArray_Split[0],$BadArray_Split[1]]
#        $DataArray[$BadArray_Split[0],$BadArray_Split[1]] = "**TEMP**"
#		Write-Host -Object "-- Replacing long value with **TEMP**" -ForegroundColor Yellow
#    }
#
#	$EndCellRow = ($RowCount+1)
#	$Data_range = $Worksheet.Range("a2","$EndCellColumn$EndCellRow")
#	$Data_range.Value2 = $DataArray
#
#    # Paste big values back into the spreadsheet
#    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
#    {
#        $BadArray_Split = $badarrayvalue[$i].Split(",")
#        # Adjust for header and $i=0
#        $CellRow = [int]$BadArray_Split[0] + 2
#        # Adjust for $i=0
#        $CellColumn = [int]$BadArray_Split[1] + 1
#
#        $Range = $Worksheet.cells.item($CellRow,$CellColumn)
#        $Range.Value2 = $BadArrayValue_Temp[$i]
#		Write-Host -Object "-- Pasting long value back in spreadsheet" -ForegroundColor Yellow
#    }
#}
#	#EndRegion Get-UmMailboxConfiguration sheet

##Region Get-UmMailboxPin sheet
#Write-Host -Object "---- Starting Get-UmMailboxPin"
#	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
#	$Worksheet.name = "UmMailboxPin"
#	$Worksheet.Tab.ColorIndex = $intColorIndex_Um
#	$row = 1
#	$header = @()
#	$header +=  "UserID"
#	$header +=  "PinExpired"
#	$header +=  "FirstTimeUser"
#	$header +=  "LockedOut"
#	$header +=  "ObjectState"
#	$header +=  "IsValid"
#	$a = [int][char]'a' -1
#	if ($header.GetLength(0) -gt 26)
#	{$EndCellColumn = [char]([int][math]::Floor($header.GetLength(0)/26) + $a) + [char](($header.GetLength(0)%26) + $a)}
#	else
#	{$EndCellColumn = [char]($header.GetLength(0) + $a)}
#	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
#	$Header_range.value2 = $header
#	$Header_range.cells.interior.colorindex = 45
#	$Header_range.cells.font.colorindex = 0
#	$Header_range.cells.font.bold = $true
#	$row++
#	$intSheetCount++
#	$ColumnCount = $header.Count
#	$DataFile = @()
#	$EndCellRow = 1
#
#if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\GetUmMailboxPin") -eq $true)
#{
#	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\ExOrg\GetUmMailboxPin" | Where-Object {$_.name -match "~~GetUmMailboxPin"}))
#	{
#		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\GetUmMailboxPin\" + $file)
#	}
#	$RowCount = $DataFile.Count
#	$ArrayRow = 0
#	$BadArrayValue = @()
#	$DataArray = New-Object 'object[,]' -ArgumentList $RowCount,$ColumnCount
#	Foreach ($DataRow in $DataFile)
#	{
#		$DataField = $DataRow.Split("`t")
#		for ($ArrayColumn = 0 ; $ArrayColumn -lt $ColumnCount ; $ArrayColumn++)
#		{
#			# Excel 2003 limit of 1823 characters
#            if ($DataField[$ArrayColumn].length -lt 1823)
#                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
#			# Excel 2007 limit of 8203 characters
#            elseif (($Excel_ExOrg.version -ge 12) -and ($DataField[$ArrayColumn].length -lt 8203))
#                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
#			# No known Excel 2010 limit
#            elseif ($Excel_ExOrg.version -ge 14)
#                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
#            else
#            {
#                Write-Host -Object "Number of characters in array member exceeds the version of limitations of this version of Excel" -ForegroundColor Yellow
#				Write-Host -Object "-- Writing value to temp variable" -ForegroundColor Yellow
#                $DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]
#                $BadArrayValue += "$ArrayRow,$ArrayColumn"
#            }
#		}
#		$ArrayRow++
#	}
#
#    # Replace big values in $DataArray
#    $BadArrayValue_count = $BadArrayValue.count
#    $BadArrayValue_Temp = @()
#    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
#    {
#        $BadArray_Split = $badarrayvalue[$i].Split(",")
#        $BadArrayValue_Temp += $DataArray[$BadArray_Split[0],$BadArray_Split[1]]
#        $DataArray[$BadArray_Split[0],$BadArray_Split[1]] = "**TEMP**"
#		Write-Host -Object "-- Replacing long value with **TEMP**" -ForegroundColor Yellow
#    }
#
#	$EndCellRow = ($RowCount+1)
#	$Data_range = $Worksheet.Range("a2","$EndCellColumn$EndCellRow")
#	$Data_range.Value2 = $DataArray
#
#    # Paste big values back into the spreadsheet
#    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
#    {
#        $BadArray_Split = $badarrayvalue[$i].Split(",")
#        # Adjust for header and $i=0
#        $CellRow = [int]$BadArray_Split[0] + 2
#        # Adjust for $i=0
#        $CellColumn = [int]$BadArray_Split[1] + 1
#
#        $Range = $Worksheet.cells.item($CellRow,$CellColumn)
#        $Range.Value2 = $BadArrayValue_Temp[$i]
#		Write-Host -Object "-- Pasting long value back in spreadsheet" -ForegroundColor Yellow
#    }
#}
#	#EndRegion Get-UmMailboxPin sheet

#Region Get-UmMailboxPolicy sheet
Write-Host -Object "---- Starting Get-UmMailboxPolicy"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "UmMailboxPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Um
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "MaxGreetingDuration"
	$header +=  "MaxLogonAttempts"
	$header +=  "AllowCommonPatterns"
	$header +=  "PINLifetime"
	$header +=  "PINHistoryCount"
	$header +=  "AllowSMSNotification"
	$header +=  "ProtectUnauthenticatedVoiceMail"
	$header +=  "ProtectAuthenticatedVoiceMail"
	$header +=  "ProtectedVoiceMailText"
	$header +=  "RequireProtectedPlayOnPhone"
	$header +=  "MinPINLength"
	$header +=  "FaxMessageText"
	$header +=  "UMEnabledText"
	$header +=  "ResetPINText"
	$header +=  "SourceForestPolicyNames"
	$header +=  "VoiceMailText"
	$header +=  "UMDialPlan"
	$header +=  "FaxServerURI"
	$header +=  "AllowedInCountryOrRegionGroups"
	$header +=  "AllowedInternationalGroups"
	$header +=  "AllowDialPlanSubscribers"
	$header +=  "AllowExtensions"
	$header +=  "LogonFailuresBeforePINReset"
	$header +=  "AllowMissedCallNotifications"
	$header +=  "AllowFax"
	$header +=  "AllowTUIAccessToCalendar"
	$header +=  "AllowTUIAccessToEmail"
	$header +=  "AllowSubscriberAccess"
	$header +=  "AllowTUIAccessToDirectory"
	$header +=  "AllowTUIAccessToPersonalContacts"
	$header +=  "AllowAutomaticSpeechRecognition"
	$header +=  "AllowPlayOnPhone"
	$header +=  "AllowVoiceMailPreview"
	$header +=  "AllowCallAnsweringRules"
	$header +=  "AllowMessageWaitingIndicator"
	$header +=  "AllowPinlessVoiceMailAccess"
	$header +=  "AllowVoiceResponseToOtherMessageTypes"
	$header +=  "AllowVoiceMailAnalysis"
	$header +=  "AllowVoiceNotification"
	$header +=  "InformCallerOfVoiceMailAnalysis"
	$header +=  "VoiceMailPreviewPartnerAddress"
	$header +=  "VoiceMailPreviewPartnerAssignedID"
	$header +=  "VoiceMailPreviewPartnerMaxMessageDuration"
	$header +=  "VoiceMailPreviewPartnerMaxDeliveryDelay"
	$header +=  "IsDefault"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\ExOrg\ExOrg_GetUmMailboxPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_GetUmMailboxPolicy.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-UmMailboxPolicy sheet

# Misc
#Region Misc_AdminGroups sheet
Write-Host -Object "---- Starting Misc_AdminGroups"
	$Worksheet = $Excel_ExOrg_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "Misc_AdminGroups"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Misc
	$row = 1
	$header = @()
	$header +=  "Group Name"
	$header +=  "Member Count"
	$header +=  "Member"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "output\ExOrg\ExOrg_Misc_AdminGroups.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\ExOrg\ExOrg_Misc_AdminGroups.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Process-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#endRegion Misc_AdminGroups sheet

# Autofit columns
Write-Host -Object "---- Starting Autofit"
$Excel_ExOrgWorksheetCount = $Excel_ExOrg_workbook.worksheets.count
$AutofitSheetCount = 1
while ($AutofitSheetCount -le $Excel_ExOrgWorksheetCount)
{
	$ActiveWorksheet = $Excel_ExOrg_workbook.worksheets.item($AutofitSheetCount)
	$objRange = $ActiveWorksheet.usedrange
	[Void]	$objRange.entirecolumn.autofit()
	$AutofitSheetCount++
}
$Excel_ExOrg_workbook.saveas($ExDC_ExOrg_XLS)
Write-Host -Object "---- Spreadsheet saved"
$Excel_ExOrg.workbooks.close()
Write-Host -Object "---- Workbook closed"
$Excel_ExOrg.quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel_ExOrg)
Remove-Variable -Name Excel_ExOrg
# If the ReleaseComObject doesn't do it..
#spps -n excel

	$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
	$EventLog.MachineName = "."
	$EventLog.Source = "ExDC"
	try{$EventLog.WriteEntry("Ending Core_Assemble_ExOrg_Excel","Information", 43)}catch{}

