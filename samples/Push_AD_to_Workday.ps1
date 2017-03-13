#REQUIRES -Modules ActiveDirectory, WorkdayApi

[CmdletBinding()]
param (
    [datetime]$LastSyncronized,
    [switch]$All
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
$filter = 'extensionAttribute1 -like "*" -and (EmailAddress -like "*" -or OfficePhone -like "*")'
if ($LastSyncronized -is [DateTime] -and -not $All) {
    $filter += ' -and Modified -ge "{0:o}"' -f $LastSyncronized
}

Write-Progress -Activity 'Pushing AD User email and phone values to Workday' -Status "Gathering AD Users using filter: $filter"
$AdUsers = Get-ADUser -Filter $filter -ResultSetSize $null -Properties extensionAttribute1, EmailAddress, OfficePhone -Verbose

$outputTemplate = [pscustomobject][ordered]@{
        Name                = $null
        extensionAttribute1 = $null
        WID                 = $null
        WorkEmailStatus     = $null
        WorkPhoneStatus     = $null
}

$count = 0
foreach ($AdUser in $AdUsers) {
    $count++
    Write-Progress -Activity 'Pushing AD User email and phone values to Workday' -Status "$count of $($AdUsers.Count)" -CurrentOperation "processing $($AdUser.Name)" -PercentComplete ($count/$AdUsers.Count*100)
    $o = $outputTemplate.PsObject.Copy()
    $o.Name = $AdUser.DistinguishedName
    $o.extensionAttribute1 = $AdUser.extensionAttribute1
    $worker = Get-WorkdayWorker -WorkerId $AdUser.extensionAttribute1 -WorkerType Employee_ID -IncludePersonal
    if ($worker.psobject.TypeNames[0] -eq 'WorkdayWorker') {
        $o.WID = $worker.WorkerWid

        if ([string]::IsNullOrWhiteSpace($ADUser.EmailAddress)) {
            $o.WorkEmailStatus = 'No EmailAddress in AD.'
        } else {
            $response = Update-WorkdayWorkerEmail -WorkerXml $worker.Xml -WorkEmail $ADUser.EmailAddress
            $o.WorkEmailStatus = $response.Message
        }

        if ([string]::IsNullOrWhiteSpace($ADUser.OfficePhone)) {
            $o.WorkPhoneStatus = 'No OfficePhone in AD.'
        } else {
            $response = Update-WorkdayWorkerPhone -WorkerXml $worker.Xml -WorkPhone $ADUser.OfficePhone
            $o.WorkPhoneStatus = $response.Message
        }
    } else {
        $o.WID = $worker.Message
    }
    Write-Output $o
}

# Save last ran time
$StartTime | Export-CliXml -Path $LastRanFile

Write-Progress -Activity 'Pushing AD User email and phone values to Workday' -Completed