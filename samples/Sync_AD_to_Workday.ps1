<#
.Synopsis
Example script to push Active Directory values to Workday, when they differ.

.Example
.\Sync_AD_to_Workday.ps1 | Export-Csv -Path Report.csv -NoTypeInformation
#>

#REQUIRES -Modules ActiveDirectory

[CmdletBinding()]
param (
    [datetime]$LastSyncronized,
    [switch]$Force
)

Import-Module ActiveDirectory
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force

Write-Progress -Activity 'Pushing AD User email and phone values to Workday' -Status 'Initializing...'

$StartTime = Get-Date
$LastRanFile = "$env:LOCALAPPDATA\Sync_AD_to_Workday.CliXml"
if ( $LastSyncronized -eq $null -and (Test-Path $LastRanFile)) {
    $LastSyncronized = Import-CliXml -Path $LastRanFile
}

# We use extensionAttribute1 for employee ID, when AD now has the properties EmployeeID, EmployeeNumber.
$filter = 'enabled -eq $true -and extensionAttribute1 -like "*" -and (EmailAddress -like "*" -or OfficePhone -like "*" -or MobilePhone -like "*")'
if ($LastSyncronized -is [DateTime] -and -not $Force) {
    $filter += ' -and Modified -ge "{0:o}"' -f $LastSyncronized
}

Write-Progress -Activity 'Pushing AD User email and phone values to Workday' -Status "Gathering AD Users using filter: $filter"
$AdUsers = @(Get-ADUser -Filter $filter -ResultSetSize $null -Properties extensionAttribute1, EmailAddress, OfficePhone, MobilePhone -Verbose)

$outputTemplate = [pscustomobject][ordered]@{
        DistinguishedName   = $null
        extensionAttribute1 = $null
        WID                 = $null
        WorkEmailStatus     = $null
        WorkPhoneStatus     = $null
        MobilePhoneStatus   = $null
}

$count = 0
foreach ($AdUser in $AdUsers) {
    $count++
    Write-Progress -Activity 'Pushing AD User email and phone values to Workday' -Status "$count of $($AdUsers.Count)" -CurrentOperation "processing $($AdUser.Name)" -PercentComplete ($count/$AdUsers.Count*100)
    $o = $outputTemplate.PsObject.Copy()
    $o.DistinguishedName = $AdUser.DistinguishedName
    $o.extensionAttribute1 = $AdUser.extensionAttribute1
    if ($o.extensionAttribute1 -match '^[\s0]*([1-9]\d*)\s*$') {
        $workerId = $Matches[1]
        $worker = $null
        try {
            $worker = Get-WorkdayWorker -WorkerId $workerId -WorkerType Employee_ID -IncludePersonal -Force
        }
        catch {
            $o.WID = "Unable to retrieve WorkerID [$workerId] from Workday: $_"
        }
        if ($worker -ne $null -and $worker.psobject.TypeNames[0] -eq 'Workday.Worker') {
            $o.WID = $worker.WorkerWid

            if ([string]::IsNullOrWhiteSpace($ADUser.EmailAddress)) {
                $o.WorkEmailStatus = 'No EmailAddress in AD.'
            } else {
                try {
                    $response = Update-WorkdayWorkerEmail -WorkerXml $worker.Xml -WorkEmail $ADUser.EmailAddress
                    $o.WorkEmailStatus = $response.Message
                }
                catch {
                    $o.WorkEmailStatus = "Error: $_"
                }
            }

            if ([string]::IsNullOrWhiteSpace($ADUser.OfficePhone)) {
                $o.WorkPhoneStatus = 'No OfficePhone in AD.'
            } else {
                try {
                    $response = Update-WorkdayWorkerPhone -WorkerXml $worker.Xml -Number $ADUser.OfficePhone -UsageType WORK -DeviceType Landline
                    $o.WorkPhoneStatus = $response.Message
                }
                catch {
                    $o.WorkPhoneStatus = "Error: $_"
                }
            }

           if ([string]::IsNullOrWhiteSpace($ADUser.MobilePhone)) {
                $o.MobilePhoneStatus = 'No MobilePhone in AD.'
            } else {
                try {
                    $response = Update-WorkdayWorkerPhone -WorkerXml $worker.Xml -Number $ADUser.MobilePhone -UsageType WORK -DeviceType Cell
                    $o.MobilePhoneStatus = $response.Message
                }
                catch {
                    $o.WorkPhoneStatus = "Error: $_"
                }
            }
        } elseif ($worker -ne $null) {
            $o.WID = $worker.Message
        }
    } else {
        $o.WID = 'Invalid Worker ID.'
    }
    Write-Output $o
}

# Save last ran time
$StartTime | Export-CliXml -Path $LastRanFile

Write-Progress -Activity 'Pushing AD User email and phone values to Workday' -Completed