function Update-WorkdayWorkerEmail {
<#
.SYNOPSIS
    Updates a Worker's email in Workday, only if it is different.

.DESCRIPTION
    Updates a Worker's email in Workday, only if it is different.
    Change requests are always recorded in Workday's audit log even when
    the email is the same. Unlike Set-WorkdayWorkerEmail, this cmdlet
    first checks the current email before requesting a change. 

.PARAMETER EmployeeId
    The Worker's Employee Id at Workday. This cmdlet does not currently
    support Contengent Workers or referencing workers by WID.

.PARAMETER WorkEmail
    Sets the Workday primary, public, Work email for a Worker. This cmdlet does not
    currently support other email types. Also excepts the alias EmailAddress.

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
    
Update-WorkdayWorkerEmail -EmpoyeeId 123 -WorkEmail test@example.com

#>

	[CmdletBinding(DefaultParametersetName='Search')]
	param (
		[Parameter(Mandatory = $true,
            ParameterSetName="Search")]
		[ValidateNotNullOrEmpty()]
		[string]$EmployeeId,
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
        [Alias('EmailAddress')]
		[string]$WorkEmail
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'NoSearch') {
        $current = Get-WorkdayWorkerEmail -WorkerXml $WorkerXml
        $EmployeeId = $WorkerXml.Get_Workers_Response.Response_Data.Worker.Worker_Data.Worker_ID
    } else {
        $current = Get-WorkdayWorkerEmail -EmployeeId $EmployeeId -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password
    }

    $currentWorkEmail = $current | where { $_.Type -eq 'Work' -and $_.Primary } | Select -First 1 -ExpandProperty Email

    Write-Verbose "Current: $currentWorkEmail Proposed: $WorkEmail"
    if ($currentWorkEmail -ne $WorkEmail) {
        Set-WorkdayWorkerEmail -EmployeeId $EmployeeId -WorkEmail $WorkEmail -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password | Write-Output
    } else {
        Write-Verbose 'Email matches Workday, no update necessary.'
    }
}
