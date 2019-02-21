<#
.Synopsis
Example script to push Active Directory values to Workday, when they differ.

This version starts with requesting Workers from Workday.

.Example
.\Sync_AD_to_Workday.ps1 -Path output\results.csv

.NOTES

Properties in AD True Up file: Active Status	Employee ID	Legal Name - First Name	Legal Name - Last Name	Worker Type	Employee Type	Manager ID	User Name	Business Title	Location	Work Space from Worker Primary Job	Workspace	Division	SubDivision	Cost Center

Properties used:
Employee ID
Business Title
Location
Division
SubDivision
Workspace
Manager ID
~Employee Type


	if ([string]::IsNullOrWhiteSpace($In.'Business Title')) {
		$adUser.Title       = $null
		$adUser.Description = $null
	} else {
		$Title = $In.'Business Title' -replace '^TM-|^ST-',''
		$adUser.Title       = $Title
		$adUser.Description = $Title
	}
	$adUser.Office = if ([string]::IsNullOrWhiteSpace($In.'Location')) { $null } else {$In.'Location'}
	$adUser.Department = if ([string]::IsNullOrWhiteSpace($In.'Division')) { $null } else {$In.'Division'}
	$adUser.extensionattribute4 = if ([string]::IsNullOrWhiteSpace($In.'SubDivision')) { $null } else {$In.'SubDivision'}
	$adUser.extensionattribute5 = if ([string]::IsNullOrWhiteSpace($In.'Workspace')) { $null } else {$In.'Workspace'}
    $adUser.extensionattribute7 = if ([string]::IsNullOrWhiteSpace($In.'Employee Type')) { $null } else {$In.'Employee Type'.Replace(' ','_')}

	# Get Manager.
	$manager = $null
	If ([string]::IsNullOrWhiteSpace($In.'Manager ID') -eq $false) {
		$manager = try {
			Get-ADUser -Filter "ExtensionAttribute1 -eq '$($In.'Manager ID')'" -ErrorAction Stop |
			 Select-Object -First 1 -ExpandProperty DistinguishedName
		} catch {}
    }
    

    public void CommitChanges (); https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.directoryentry.commitchanges?view=netframework-4.7.2

    $properties = 'title','description','physicalDeliveryOfficeName','department','extensionattribute4','extensionattribute5','extensionattribute7'
    
#>

# Requires -Module WorkdayApi

[CmdletBinding()]
param (
    # Path to a Results file.
    [string]$Path,
    # A special validation to ensure the worker ID matches the value in AD extensionAttribute1.
    [switch]$MatchExtensionAttribute1,
    # Specifies how many workers to process. Used primarily for testing.
    [int]$Limit = 0
)
Import-Module WorkdayApi

function Main {
    $count = 0
    $ldapProperties = 'userPrincipalName', 'mail', 'telephoneNumber', 'mobile','extensionAttribute1'

    Write-Verbose 'Requesting Workday Workers.'
    
    Get-WorkdayWorker -IncludePersonal | ForEach-Object {
        $worker = $_
        $count++
        if ($Limit -gt 0 -and $count -ge $Limit) { return }
        $out = $outputTemplate.PsObject.Copy()
        $out.Success = $true
        $out.WorkerType = $worker.WorkerType
        $out.WorkerId   = $worker.WorkerId
        $out.UserPrincipalName = $worker.UserId

        $adUser = @()
        if ($null -ne $worker.UserId) {
            $LDAPFilter = '(&(objectCategory=person)(objectClass=user)(userPrincipalName={0}))' -f $worker.UserId
            $adUser = @(Get-DsAdUsers -LDAPFilter $LDAPFilter -Properties $ldapProperties)
        }

        $adStatus = 'UserPrincipalName [{0}] returned {1} AD User(s).' -f $worker.UserId, $adUser.Count
        Write-Verbose ('{0} {1}' -f $worker.WorkerDescriptor, $adStatus)
        if ($AdUser.Count -ne 1) {
            $out.UserPrincipalName = $adStatus
            # It is OK if an AD user is not found. It is not OK if more than one is found.
            if ($AdUser.Count -gt 1) {
                $out.Success = $false
            }
            Write-Output $out
            continue
        }

        # We keep the worker ID in extensionAttribute1.
        if ($MatchExtensionAttribute1 -and $worker.WorkerId -ne $AdUser.extensionAttribute1) {
            $out.UserPrincipalName = 'Workday WorkerId [{0}] did not match AD ExtensionAttribute1 [{1}] for UserPrincipalName [{2}].' -f $worker.WorkerId, $AdUser.extensionAttribute1, $worker.UserId
            $out.Success = $false
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
                $out.Success = $false
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
                $out.Success = $false
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
                $out.Success = $false
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
        Success             = $null
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
    $expandedPath = $Path -f (Get-Date)
    Write-Host "Writing results to: $expandedPath"
    Main | Export-Csv -Path $expandedPath -NoTypeInformation
}
