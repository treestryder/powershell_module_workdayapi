<#
.Synopsis
Example script to push Active Directory values to Workday, when they differ.

.Example
.\Sync_AD_to_Workday.ps1 | Export-Csv -Path Report.csv -NoTypeInformation
#>

[CmdletBinding()]
param (
    [int]$Limit = -1
)

Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Write-Progress -Activity 'Pushing AD User email and phone values to Workday' -Status 'Initializing...'

function Get-DsAdUsers {
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.ResultPropertyCollection])]
    param (
        [string]$LDAPFilter = '(&(objectCategory=person)(objectClass=user))',
        [string[]]$Properties
    )
    $objDomain = New-Object System.DirectoryServices.DirectoryEntry
    $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
    $objSearcher.SearchRoot = $objDomain
    $objSearcher.PageSize = 1000
    $objSearcher.Filter = $LDAPFilter
    $objSearcher.SearchScope = "Subtree"
    
    $Properties | ForEach-Object {
        $null = $objSearcher.PropertiesToLoad.Add($_)
    }
    $objSearcher.FindAll() | Select-Object -ExpandProperty Properties
}

$outputTemplate = [pscustomobject][ordered]@{
        DistinguishedName   = $null
        extensionAttribute1 = $null
        WID                 = $null
        WorkEmailStatus     = $null
        WorkPhoneStatus     = $null
        MobilePhoneStatus   = $null
}

# We use extensionAttribute1 for employee ID, though AD now has the properties EmployeeID, EmployeeNumber.
# NOT Disabled (!(useraccountcontrol:1.2.840.113556.1.4.803:=2))
$filter = '(&(objectCategory=person)(objectClass=user)(extensionAttribute1=*)(!(useraccountcontrol:1.2.840.113556.1.4.803:=2)))'
$properties = 'name','DistinguishedName','extensionAttribute1', 'mail', 'telephoneNumber', 'mobile'

Write-Progress -Activity 'Pushing AD User email and phone values to Workday' -Status "Gathering AD Users using filter: $filter"
$AdUsers = Get-DsAdUsers -LDAPFilter $filter -Properties $properties

Write-Debug "Total AD Users Returned: $($ADUsers.Count)"
$count = 0
foreach ($AdUser in $AdUsers) {
    if ($count -ge $Limit -and $Limit -ne -1) { return }
    $count++
    Write-Progress -Activity 'Pushing AD User email and phone values to Workday' -Status "$count of $($AdUsers.Count)" -CurrentOperation "processing $($AdUser['name'])" -PercentComplete ($count/$AdUsers.Count*100)
    $o = $outputTemplate.PsObject.Copy()
    $o.DistinguishedName = $AdUser['DistinguishedName'] | Select-Object -First 1
    $o.extensionAttribute1 = $AdUser['extensionAttribute1'] | Select-Object -First 1
    $email = $ADUser['mail'] | Select-Object -First 1
    $phone = $ADUser['telephoneNumber'] | Select-Object -First 1
    $mobile = $ADUser['mobile'] | Select-Object -First 1
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

            if ([string]::IsNullOrWhiteSpace($email)) {
                $o.WorkEmailStatus = 'No EmailAddress in AD.'
            } else {
                try {
                    $response = Update-WorkdayWorkerEmail -WorkerXml $worker.Xml -WorkEmail $email
                    $o.WorkEmailStatus = $response.Message
                }
                catch {
                    $o.WorkEmailStatus = "Error: $_"
                }
            }

            if ([string]::IsNullOrWhiteSpace($phone)) {
                $o.WorkPhoneStatus = 'No OfficePhone in AD.'
            } else {
                try {
                    $response = Update-WorkdayWorkerPhone -WorkerXml $worker.Xml -Number $phone -UsageType WORK -DeviceType Landline
                    $o.WorkPhoneStatus = $response.Message
                }
                catch {
                    $o.WorkPhoneStatus = "Error: $_"
                }
            }

           if ([string]::IsNullOrWhiteSpace($mobile)) {
                $o.MobilePhoneStatus = 'No MobilePhone in AD.'
            } else {
                try {
                    $response = Update-WorkdayWorkerPhone -WorkerXml $worker.Xml -Number $mobile -UsageType WORK -DeviceType Cell
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

Write-Progress -Activity 'Pushing AD User email and phone values to Workday' -Completed
