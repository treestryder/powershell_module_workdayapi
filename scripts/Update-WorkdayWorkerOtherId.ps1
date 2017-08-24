function Update-WorkdayWorkerOtherId {
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
        [ValidateNotNullOrEmpty()]
		[string]$Type,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Id,
        [ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		$WID,
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

    Write-Debug "OtherIds: $otherIds"

    $current = $otherIds | Where-Object {$PSBoundParameters.ContainsKey('WID') -and $_.WID -eq $WID} | Select-Object -First 1
    # Default to the first of the requsted type.
    if ($current -eq $null) {
        $current = $otherIds | Where-Object {$_.Type -eq $Type} | Select-Object -First 1
    }
    
    $currentIdDisplay = $null
    $issuedCurrentDisplay = $null
    $expirationCurrentDisplay = $null
    $issuedProposedDisplay = $IssuedDate
    $expirationProposedDisplay = $ExpirationDate
    # Defaults to not matching.
    $idMatched = $false
    $issuedDateMatched = $true
    $expirationDateMatched = $true
    # Throw an error for an invalid date, default to the current value when no date is specified.
    if ($IssuedDate -ne $null) {
        try {
            $d = Get-Date $IssuedDate -ErrorAction Stop
            $IssuedDate = $d
            $issuedProposedDisplay = $IssuedDate.ToString('g')
        }
        catch {
            throw "Invalid IssuedDate [$IssuedDate]"
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
        Write-Debug "Current: $current"
        $currentIdDisplay = $current.Id
        $idMatched = $current.Id -eq $Id
        $WID = $current.Wid

        $issuedCurrentDisplay = $current.Issued_Date
        if (-not [string]::IsNullOrWhiteSpace($current.Issued_Date)) {
            try {
                $d = Get-Date $current.Issued_Date -ErrorAction Stop
                $issuedCurrentDisplay = $d.ToString('g')
                if ($IssuedDate -is [datetime]){
                    $IssuedDateMatched = ($d - $IssuedDate).Days -eq 0
                }
                else {
                    $IssuedDate = $d
                    $issuedProposedDisplay = $issuedCurrentDisplay
                }
            }
            catch {
                $IssuedDateMatched = $false
            }
        }

        $expirationCurrentDisplay = $current.Expiration_Date
        if (-not [string]::IsNullOrWhiteSpace($current.Expiration_Date)) {
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
    }

    $msg = '{{0}} Current [{0} valid from {1} to {2}] Proposed [{3} valid from {4} to {5}]' -f $currentIdDisplay, $issuedCurrentDisplay, $expirationCurrentDisplay, $Id, $issuedProposedDisplay, $expirationProposedDisplay

    Write-Debug "idMatched=$idMatched; issuedDateMatched=$issuedDateMatched; expirationDateMatched=$expirationDateMatched"
    if ( 
        $idMatched -and
        $issuedDateMatched -and
        $expirationDateMatched
    ) {
        $output.Message = $msg -f 'Matched'
        $output.Success = $true
    } elseif ($WhatIf) {
        $output.Success = $true
        $output.Message = $msg -f 'Would change'
    } else {
        $params = @{
            WorkerId = $WorkerId
            WorkerType = $WorkerType
            Type = $Type
            Id = $Id
        }
        if (-not [string]::IsNullOrWhiteSpace($WID)) {
            $params['WID'] = $WID
        }

        $response = Set-WorkdayWorkerOtherId @params -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password -IssuedDate:$IssuedDate -ExpirationDate:$ExpirationDate
        $output.Xml = $response.Xml
        
        if ($response -ne $null -and $response.Success) {
            $output.Success = $true
            $output.Message = $msg -f 'Changed'
        }
    }

    Write-Verbose $output.Message
    Write-Output $output
}
