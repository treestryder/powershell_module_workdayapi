function Update-WorkdayWorkerBadgeId {
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

.PARAMETER Human_ResourcesUri
    Human_Resources Endpoint Uri for the request. If not provided, the value
    stored with Set-WorkdayEndpoint -Endpoint Human_Resources is used.


.PARAMETER Username
    Username used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.PARAMETER Password
    Password used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

#>

	[CmdletBinding()]
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
		[ValidatePattern('^[0-9]+$')]
		[string]$BadgeId,
        $IssuedDate,
        $ExpirationDate,
        [switch]$WhatIf
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    $output = [pscustomobject][ordered]@{
        Success = $false
        Message = $msg -f 'Failed'
        Xml     = $null
    }

    if ($PsCmdlet.ParameterSetName -eq 'NoSearch') {
        $otherIds = Get-WorkdayWorkerOtherId -WorkerXml $WorkerXml
        $WorkerType = 'WID'
        $workerReference = $WorkerXml.GetElementsByTagName('wd:Worker_Reference') | Select-Object -First 1
        $WorkerId = $workerReference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty InnerText
    } else {
        $otherIds = Get-WorkdayWorkerOtherId -WorkerId $WorkerId -WorkerType $WorkerType -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password
    }

    $current = $otherIds | Where-Object {$_.Type -eq 'Custom_ID/Badge_ID'} | Select-Object -First 1
    
    # Throw an error for an invalid date, default to the current value when no date is specified.
    $issueCurrentDisplay = ''
    $expirationCurrentDisplay = ''
    $issueProposedDisplay = $IssuedDate
    $expirationProposedDisplay = $ExpirationDate
    $IssuedDateMatched = $true
    $expirationDateMatched = $true
    if ($IssuedDate -ne $null) {
        try {
            $d = Get-Date $IssuedDate -ErrorAction Stop
            $IssuedDate = $d
            $issueProposedDisplay = $IssuedDate.ToString('g')
        }
        catch {
            throw "Invalid IssueDate [$IssuedDate]"
        }
    }

    if ($ExpirationDate -ne $null) {
        try {
            $d = Get-Date $ExpirationDate -ErrorAction Stop
            $ExpirationDate = $d
            $expirationProposedDisplay = $ExpirationDate.ToString('g')
        }
        catch {
            throw "Invalid ExpirationDate [$ExpirationDate]"
        }
    }

    if ($current -ne $null) {

        $issueCurrentDisplay = $current.Issue_Date
        try {
            $d = Get-Date $current.Issued_Date -ErrorAction Stop
            $issueCurrentDisplay = $d.ToString('g')
            if ($IssuedDate -is [datetime]){
                $IssuedDateMatched = ($d - $IssuedDate).Days -eq 0
            }
            else {
                $IssuedDate = $d
                $issueProposedDisplay = $issueCurrentDisplay
            }
        }
        catch {
            $IssuedDateMatched = $false
        }

        $expirationCurrentDisplay = $current.Expiration_Date
        try {
            $d = Get-Date $current.Expiration_Date -ErrorAction Stop
            $expirationCurrentDisplay = $d.ToString('g')
            if ($ExpirationDate -is [datetime]){
                $ExpirationDateMatched = ($d - $ExpirationDate).Days -eq 0
            }
            else {
                $ExpirationDate = $d
                $expirationProposedDisplay = $expirationCurrentDisplay
            }
        }
        catch {
            $ExpirationDateMatched = $false
        }
    }

    $msg = '{{0}} Current [] Proposed [{0} from {1} to {2}]' -f $BadgeId, $issueProposedDisplay, $expirationProposedDisplay
    if ($current -ne $null) {
        $msg = '{{0}} Current [{0} valid from {1} to {2}] Proposed [{3} valid from {4} to {5}]' -f $current.Id, $issueCurrentDisplay, $expirationCurrentDisplay, $BadgeId, $issueProposedDisplay, $expirationProposedDisplay
    }        

    if ( 
        $current -ne $null -and
        $current.Id -eq $BadgeId -and
        $IssuedDateMatched -and
        $ExpirationDateMatched
    ) {
        $output.Message = $msg -f 'Matched'
        $output.Success = $true
    } elseif ($WhatIf) {
        $output.Success = $true
        $output.Message = $msg -f 'Would change'
    } else {
        $params = $PSBoundParameters
        $null = $params.Remove('WorkerXml')
        $null = $params.Remove('WorkerId')
        $null = $params.Remove('WorkerType')
        $o = Set-WorkdayWorkerBadgeId -WorkerId $WorkerId -WorkerType $WorkerType @params
        
        if ($o -ne $null -and $o.Success) {
            $output.Success = $true
            $output.Message = $msg -f 'Changed'
            $output.Xml = $o.Xml
        }
    }

    Write-Verbose $output.Message
    Write-Output $output
}
