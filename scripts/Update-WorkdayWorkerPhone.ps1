function Update-WorkdayWorkerPhone {
<#
.SYNOPSIS
    Updates a Worker's phone number in Workday, only if it is different.

.DESCRIPTION
    Updates a Worker's phone number in Workday, only if it is different.
    Change requests are always recorded in Workday's audit log even when
    the number is the same. Unlike Set-WorkdayWorkerPhone, this cmdlet
    first checks the current phone number before requesting a change. 

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

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
    
Update-WorkdayWorkerPhone -WorkerId 123 -WorkPhone 1234567890

#>

	[CmdletBinding(DefaultParametersetName='Search')]
	param (
		[Parameter(Mandatory = $true,
            ParameterSetName="Search",
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
        [Parameter(ParameterSetName="Search")]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
        [Parameter(ParameterSetName="Search")]
		[string]$Human_ResourcesUri,
        [Parameter(ParameterSetName="Search")]
		[string]$Username,
        [Parameter(ParameterSetName="Search")]
		[string]$Password,
        [Parameter(Mandatory = $true,
            ParameterSetName="NoSearch")]
        [xml]$WorkerXml,
        [Parameter(Mandatory = $true)]
        [Alias('OfficePhone')]
		[string]$WorkPhone
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'NoSearch') {
        $current = Get-WorkdayWorkerPhone -WorkerXml $WorkerXml
        $WorkerType = 'WID'
        $workerReference = $WorkerXml.GetElementsByTagName('wd:Worker_Reference') | Select -First 1
        $WorkerId = $workerReference.ID | where {$_.type -eq 'WID'} | select -ExpandProperty InnerText
    } else {
        $current = Get-WorkdayWorkerPhone -WorkerId $WorkerId -WorkerType $WorkerType -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password
    }

    function scrub ([string]$PhoneNumber) { $PhoneNumber -replace '[^\d]','' -replace '^1','' }

    $scrubbedCurrent = scrub ( $current | where { $_.Type -eq 'Work/Landline' -and $_.Primary } | Select -First 1 -ExpandProperty Number)
    $scrubbedProposed = scrub $WorkPhone

    Write-Verbose "Current: $scrubbedCurrent Proposed: $scrubbedProposed"
    $output = [pscustomobject][ordered]@{
        Success = $true
        Message = "No change necessary for current Workday number [$scrubbedCurrent]."
        Xml     = $null
    }
    if ($scrubbedCurrent -ne $scrubbedProposed) {
        $output = Set-WorkdayWorkerPhone -WorkerId $WorkerId -WorkerType $WorkerType -WorkPhone $WorkPhone -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password
        if ($output.Success) {
            $output.Message = "Number changed at Workday from [$scrubbedCurrent] to [$scrubbedProposed]."
        }
    }
    Write-Output $output
}
