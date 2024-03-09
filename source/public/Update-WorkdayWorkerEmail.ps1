﻿function Update-WorkdayWorkerEmail {
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

.PARAMETER Email
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

Update-WorkdayWorkerEmail -WorkerId 123 -Email test@example.com

.NOTES
    The Set-WorkdayWorkerEmail switch -Append is not supported, as the -Secondary
    switch assumes there is only one non-primary email address. At some point
    it may be nessesary to implement a means to update a specific email WID.

#>

	[CmdletBinding(DefaultParametersetName='Search')]
	param (
		[Parameter(Mandatory = $true,
            ParameterSetName="Search",
            Position=0)]
		[ValidatePattern ('^[a-zA-Z0-9\-]{1,32}$')]
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
		[string]$Email,
		[ValidateSet('HOME','WORK')]
        [string]$UsageType = 'WORK',
        [switch]$Private,
        [switch]$Secondary,
        [Alias("Force")]
        [switch]$IncludeInactive
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'NoSearch') {
        $current = Get-WorkdayWorkerEmail -WorkerXml $WorkerXml
        $WorkerType = 'WID'
        $workerReference = $WorkerXml.GetElementsByTagName('wd:Worker_Reference') | Select-Object -First 1
        $WorkerId = $workerReference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty InnerText
    } else {
        $current = Get-WorkdayWorkerEmail -WorkerId $WorkerId -WorkerType $WorkerType -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive
    }

    $currentEmail = $current |
        Where-Object {
            $_.UsageType -eq $UsageType -and
            (-not $_.Primary) -eq $Secondary
        } | Select-Object -First 1

    $msg = "{0} Current [$($currentEmail.Email)] Proposed [$Email]"
    $output = [pscustomobject][ordered]@{
        WorkerId = $WorkerId
        WorkerType = $WorkerType
        Email = $Email
        UsageType = $UsageType
        Primary = -not $Secondary
        Public = -not $Private
        Success = $false
        Message = $msg -f 'Failed'
    }
    if (
        $null -ne $currentEmail -and
        $currentEmail.Email -eq $Email -and
        $currentEmail.UsageType -eq $UsageType -and
        (-not $currentEmail.Primary) -eq $Secondary -and
        (-not $currentEmail.Public) -eq $Private
    ) {
        $output.Message = $msg -f 'Matched'
        $output.Success = $true
    } else {
        $o = Set-WorkdayWorkerEmail -WorkerId $WorkerId -WorkerType $WorkerType -Email $Email -UsageType:$UsageType -Private:$Private -Secondary:$Secondary -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password
        if ($null -ne $o) {
            if ($o.Success) {
                $output.Success = $true
                $output.Message = $msg -f 'Changed'
            }
            else {
                $output.Success = $false
                $output.Message = $o.Message
            }
        }
    }

    Write-Verbose $output.Message
    Write-Output $output
}
