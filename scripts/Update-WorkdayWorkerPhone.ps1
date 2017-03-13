<#
.SYNOPSIS
    Updates a Worker's phone number in Workday, only if it is different.

.DESCRIPTION
    Updates a Worker's phone number in Workday, only if it is different.
    Change requests are always recorded in Workday's audit log even when
    the number is the same. Unlike Set-WorkdayWorkerPhone, this cmdlet
    first checks the current phone number before requesting a change. 

.PARAMETER EmployeeId
    The Worker's Employee Id at Workday. This cmdlet does not currently
    support Contengent Workers or referencing workers by WID.

.PARAMETER WorkPhone
    Sets the Workday primary Work Landline for a Worker. This cmdlet does not
    currently support other phone types. Also excepts the alias OfficePhone.

.PARAMETER Human_ResourcesUri
    Human_Resources Endpoint Uri for the request. If not provided, the value
    stored with Set-WorkdayEndpoint -Endpoint Human_Resources is used.


.PARAMETER Username
    Username used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.PARAMETER Password
    Password used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.EXAMPLE
    
Update-WorkdayWorkerPhone -EmpoyeeId 123 -WorkPhone 1234567890

#>

function Update-WorkdayWorkerPhone {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$EmployeeId,
		[Parameter(Mandatory = $true)]
        [Alias('OfficePhone')]
		[string]$WorkPhone,
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password,
        [switch]$Passthru
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }
    
    $current = Get-WorkdayWorkerPhone -EmployeeId $EmployeeId -Uri $Uri -Username $Username -Password $Password

    function scrub ([string]$PhoneNumber) { $PhoneNumber -replace '[^\d]','' -replace '^1','' }

    $scrubbedCurrent = scrub ( $current | where { $_.Type -eq 'Work/Landline' -and $_.Primary -eq 0 } | Select -First 1 -ExpandProperty Number)
    $scrubbedProposed = scrub $WorkPhone

    Write-Verbose "Current: $scrubbedCurrent Proposed: $scrubbedProposed"
    if ($scrubbedCurrent -ne $scrubbedProposed) {
        Set-WorkdayWorkerPhone -EmployeeId $EmployeeId -WorkPhone $WorkPhone -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password | where {$Passthru} | Write-Output
        Write-Verbose "     Number updated."
    }
}
