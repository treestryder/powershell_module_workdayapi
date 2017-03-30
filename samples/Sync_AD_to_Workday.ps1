<#
.Synopsis
Example script to push Active Directory values to Workday, when they differ.

This version starts with requesting Workers from Workday.

.Example
.\Sync_AD_to_Workday2.ps1 -Path output\results.csv
#>

# Requires -Module WorkdayApi

[CmdletBinding()]
param (
    [string]$Path,
    [int]$Limit = 0
)
Import-Module WorkdayApi

function Main {
    $count = 0
    $ldapProperties = 'userPrincipalName', 'mail', 'telephoneNumber', 'mobile'

    Write-Verbose 'Requesting Workday Workers.'
    
    Get-WorkdayWorker -IncludePersonal | ForEach-Object {
        $worker = $_
        $count++
        if ($Limit -gt 0 -and $count -ge $Limit) { return }
        $out = $outputTemplate.PsObject.Copy()
        $out.WorkerType = $worker.WorkerType
        $out.WorkerId   = $worker.WorkerId
        $out.UserPrincipalName = $worker.UserId

        $adUser = @()
        if ($worker.UserId -ne $null) {
            $LDAPFilter = '(&(objectCategory=person)(objectClass=user)(userPrincipalName={0}))' -f $worker.UserId
            $adUser = @(Get-DsAdUsers -LDAPFilter $LDAPFilter -Properties $ldapProperties)
        }

        $adStatus = 'UserPrincipalName [{0}] returned {1} AD User(s).' -f $worker.UserId, $adUser.Count
        Write-Verbose ('{0} {1}' -f $worker.WorkerDescriptor, $adStatus)
        if ($AdUser.Count -ne 1) {
            $out.UserPrincipalName = $adStatus
            Write-Output $out
            continue
        }

        $email = $adUser.mail | Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace($email)) {
            $out.WorkEmailStatus = 'No EmailAddress in AD.'
        } else {
            try {
                $response = Update-WorkdayWorkerEmail -WorkerXml $worker.Xml -Email $email -UsageType WORK -ErrorAction Stop
                $out.WorkEmailStatus = $response.Message
            }
            catch {
                $out.WorkEmailStatus = "Error: $_"
            }
        }

        $workPhone = $adUser.telephoneNumber | Select-Object -First 1
        $mobileSecondary = $true
        if ([string]::IsNullOrWhiteSpace($workPhone)) {
            $out.WorkPhoneStatus = 'No OfficePhone in AD.'
            $mobileSecondary = $false
        } else {
            $workPhone = Add-UsCountryCode $workPhone
            try {
                $response = Update-WorkdayWorkerPhone -WorkerXml $worker.Xml -Number $workPhone -UsageType WORK -DeviceType Landline -ErrorAction Stop
                $out.WorkPhoneStatus = $response.Message
            }
            catch {
                $out.WorkPhoneStatus = "Error: $_"
            }
        }

        $mobilePhone = $adUser.mobile | Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace($mobilePhone)) {
            $out.MobilePhoneStatus = 'No MobilePhone in AD.'
        } else {
            $mobilePhone = Add-UsCountryCode $mobilePhone
            try {
                $response = Update-WorkdayWorkerPhone -WorkerXml $worker.Xml -Number $mobilePhone -UsageType WORK -DeviceType Cell -Secondary:$mobileSecondary -ErrorAction Stop
                $out.MobilePhoneStatus = $response.Message
            }
            catch {
                $out.WorkPhoneStatus = "Error: $_"
            }
        }

        Write-Output $out
    }
}

$outputTemplate = [pscustomobject][ordered]@{
        WorkerType          = $null
        WorkerId            = $null
        UserPrincipalName   = $null
        WorkEmailStatus     = $null
        WorkPhoneStatus     = $null
        MobilePhoneStatus   = $null
}

function Add-UsCountryCode {
    param (
        [string]$PhoneNumber
    )
    $out = $PhoneNumber
    $scrubbed = $PhoneNumber -replace '[^\d]',''
    if ($scrubbed.Length -eq 10) {
        $PhoneNumber = '1' + $PhoneNumber
    }
    Write-Output $PhoneNumber
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

if ([string]::IsNullOrWhiteSpace($Path)) {
    Main | Write-Output
}
else {
    Write-Host "Writing results to: $Path"
    Main | Export-Csv -Path $Path -NoTypeInformation
}
