function Get-WorkdayWorkerOtherId {
<#
.SYNOPSIS
    Returns a Worker's Id information.

.DESCRIPTION
    Returns a Worker's Id information as custom Powershell objects.

.PARAMETER EmployeeId
    The Worker's Employee Id at Workday. This cmdlet does not currently
    support Contengent Workers or referencing workers by WID.

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
    
Get-WorkdayWorkerOtherId -EmpoyeeId 123


#>

	[CmdletBinding(DefaultParametersetName='Search')]
    [OutputType([PSCustomObject])]
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
        [Parameter(ParameterSetName="NoSearch")]
        [xml]$WorkerXml
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'NoSearch') {
        $w = $WorkerXml
    } else {
        try {
            $w = Get-WorkdayWorker -EmployeeId $EmployeeId -IncludePersonal -Passthru -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -ErrorAction Stop
        }
        catch {
            throw
        }
    }

    $numberTemplate = [pscustomobject][ordered]@{
        Type       = $null
        Id         = $null
        Descriptor = $null
    }

    $w.Get_Workers_Response.Response_Data.Worker.Worker_Data.Personal_Data.Identification_Data.National_ID | foreach {
        $o = $numberTemplate.PsObject.Copy()
        $typeXml = $_.National_ID_Data.ID_Type_Reference.ID | where {$_.type -eq 'National_ID_Type_Code'}
        $o.Type = 'National_ID/{0}' -f $typeXml.'#text'
        $o.Id = $_.National_ID_Data.ID
        $o.Descriptor = $_.National_ID_Reference.Descriptor
        Write-Output $o
    }

    $w.Get_Workers_Response.Response_Data.Worker.Worker_Data.Personal_Data.Identification_Data.Custom_ID | foreach {
        $o = $numberTemplate.PsObject.Copy()
        $typeXml = $_.Custom_ID_Data.ID_Type_Reference.ID | where {$_.type -eq 'Custom_ID_Type_ID'}
        $o.Type = 'Custom_ID/{0}' -f $typeXml.'#text'
        $o.Id = $_.Custom_ID_Data.ID
        $o.Descriptor = $_.Custom_ID_Data.ID_Type_Reference.Descriptor
        Write-Output $o
    }
<#
        $badgeIdXml = $response.Get_Workers_Response.Response_Data.Worker.Worker_Data.Personal_Data.Identification_Data.Custom_ID.Custom_ID_Data | where { $_.ID_Type_Reference.ID  | where {$_.type -eq 'Custom_ID_Type_ID' -and $_.'#text' -eq 'Badge_ID'}}
        $worker.BadgeId = $badgeIdXml.ID
#>

}
