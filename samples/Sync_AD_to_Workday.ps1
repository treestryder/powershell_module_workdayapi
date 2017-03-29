<#
.Synopsis
Example script to push Active Directory values to Workday, when they differ.

.Example
.\Sync_AD_to_Workday.ps1 -Path output\results.csv
#>

# Requires -Module WorkdayApi

[CmdletBinding()]
param (
    [string]$Path = 'Sync_AD_to_Workday.csv',
    # We use extensionAttribute1 for employee ID, though AD now has the properties EmployeeID, EmployeeNumber.
    # NOT Disabled (!(useraccountcontrol:1.2.840.113556.1.4.803:=2))
    [string]$LDAPFilter = '(&(objectCategory=person)(objectClass=user)(extensionAttribute1=*)(!(useraccountcontrol:1.2.840.113556.1.4.803:=2)))',
    [int]$Limit = -1
)
Import-Module WorkdayApi

$Activity = 'Pushing Active Directory User email and phone values to Workday'

function Main {
    Write-Progress -Activity $Activity -Status 'Initializing...'
    $outputTemplate = [pscustomobject][ordered]@{
            DistinguishedName   = $null
            extensionAttribute1 = $null
            WID                 = $null
            WorkEmailStatus     = $null
            WorkPhoneStatus     = $null
            MobilePhoneStatus   = $null
    }
    $count = 0

    Write-Progress -Activity $Activity -Status "Gathering AD Users using filter: $LDAPFilter"
    $properties = 'name','DistinguishedName','extensionAttribute1', 'mail', 'telephoneNumber', 'mobile'
    $AdUsers = @(Get-DsAdUsers -LDAPFilter $LDAPFilter -Properties $properties)
    Write-Debug "Total AD Users returned: $($ADUsers.Count)"

    foreach ($ADUser in $ADUsers) {
        if ($count -ge $Limit -and $Limit -ne -1) { return }
        $count++
        Write-Progress -Activity $Activity -Status "$count of $($AdUsers.Count)" -CurrentOperation "processing $($AdUser.name)" -PercentComplete ($count/$AdUsers.Count*100)
        $o = $outputTemplate.PsObject.Copy()
        $o.DistinguishedName = $AdUser.DistinguishedName
        $o.extensionAttribute1 = $AdUser.extensionAttribute1
        $email = $ADUser.mail
        $phone = $ADUser.telephoneNumber
        $mobile = $ADUser.mobile
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
                        $response = Update-WorkdayWorkerEmail -WorkerXml $worker.Xml -Email $email -UsageType WORK
                        $o.WorkEmailStatus = $response.Message
                    }
                    catch {
                        $o.WorkEmailStatus = "Error: $_"
                    }
                }

                $mobileSecondary = $true
                if ([string]::IsNullOrWhiteSpace($phone)) {
                    $o.WorkPhoneStatus = 'No OfficePhone in AD.'
                    $mobileSecondary = $false
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
                        $response = Update-WorkdayWorkerPhone -WorkerXml $worker.Xml -Number $mobile -UsageType WORK -DeviceType Cell -Secondary:$mobileSecondary
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
}

function Get-DsAdUsers {
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.ResultPropertyCollection])]
    param (
        [string]$LDAPFilter = '(&(objectCategory=person)(objectClass=user)(!(useraccountcontrol:1.2.840.113556.1.4.803:=2)))',
        [string[]]$Properties = @('name','DistinguishedName')
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
    $outputTemplate = 1 | Select-Object ($Properties + 'LDAPPath')
    
    foreach ($entry in $objSearcher.FindAll()) {
        $output = $outputTemplate.psobject.Copy()
        $output.LDAPPath = $entry.Path
        foreach ($prop in $Properties) {
            $output."$prop" = $entry.Properties[$prop] | Select-Object
        }
        Write-Output $output
    }
}

Main | Export-Csv -Path $Path -NoTypeInformation

Write-Host "Results written to: $Path"
Write-Progress -Activity $Activity -Completed
