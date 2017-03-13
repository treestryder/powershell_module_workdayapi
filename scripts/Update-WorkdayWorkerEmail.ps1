function Update-WorkdayWorkerEmail {
<#
.SYNOPSIS
    Updates a Worker's email in Workday, only if it is different.

.DESCRIPTION
    Updates a Worker's email in Workday, only if it is different.
    Change requests are always recorded in Workday's audit log even when
    the email is the same. Unlike Set-WorkdayWorkerEmail, this cmdlet
    first checks the current email before requesting a change. 

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

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
    
Update-WorkdayWorkerEmail -WorkerId 123 -WorkEmail test@example.com

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
        [Alias('EmailAddress')]
		[string]$WorkEmail
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'NoSearch') {
        $current = Get-WorkdayWorkerEmail -WorkerXml $WorkerXml
        $WorkerType = 'WID'
        $WorkerId = $WorkerXml.Worker.Worker_Reference.ID | where {$_.type -eq 'WID'} | select -ExpandProperty '#text'
    } else {
        $current = Get-WorkdayWorkerEmail -WorkerId $WorkerId -WorkerType $WorkerType -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password
    }

    $currentWorkEmail = $current | where { $_.Type -eq 'Work' -and $_.Primary } | Select -First 1 -ExpandProperty Email

    Write-Verbose "Current: $currentWorkEmail Proposed: $WorkEmail"

    $output = [pscustomobject][ordered]@{
        Success = $true
        Message = "No change necessary for current Workday email [$currentWorkEmail]."
        Xml     = $null
    }
    if ($currentWorkEmail -ne $WorkEmail) {
        $output = Set-WorkdayWorkerEmail -WorkerId $WorkerId -WorkerType $WorkerType -WorkEmail $WorkEmail -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password
        if ($output.Success) {
            $output.Message = "Email changed at Workday from [$currentWorkEmail] to [$WorkEmail]."
        }
    }
    Write-Output $output
}
