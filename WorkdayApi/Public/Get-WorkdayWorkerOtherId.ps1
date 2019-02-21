function Get-WorkdayWorkerOtherId {
<#
.SYNOPSIS
    Returns a Worker's Id information.

.DESCRIPTION
    Returns a Worker's Id information as custom Powershell objects.

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

.EXAMPLE

Get-WorkdayWorkerOtherId -WorkerId 123

Type                Id        Descriptor
----                --        ----------
Badge_ID            1         Badge ID

#>

	[CmdletBinding(DefaultParametersetName='Search')]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true,
            Position=0,
            ParameterSetName='Search')]
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
        [Parameter(ParameterSetName="NoSearch")]
        [xml]$WorkerXml,
        [Alias("Force")]
        [switch]$IncludeInactive
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'Search') {
        $response = Get-WorkdayWorker -WorkerId $WorkerId -WorkerType $WorkerType -IncludePersonal -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive -ErrorAction Stop
        $WorkerXml = $response.Xml
    }

    if ($WorkerXml -eq $null) {
        Write-Warning 'Unable to get Other Id information, Worker not found.'
        return
    }

    $numberTemplate = [pscustomobject][ordered]@{
        Type       = $null
        Id         = $null
        Descriptor = $null
        Issued_Date = $null
        Expiration_Date = $null
        WID = $null
    }

    $WorkerXml.GetElementsByTagName('wd:Custom_ID') | ForEach-Object {
        $o = $numberTemplate.PsObject.Copy()
        $typeXml = $_.Custom_ID_Data.ID_Type_Reference.ID | Where-Object {$_.type -eq 'Custom_ID_Type_ID'}
        $o.Type = '{0}' -f $typeXml.'#text'
        $o.Id = $_.Custom_ID_Data.ID
        $o.Descriptor = $_.Custom_ID_Data.ID_Type_Reference.Descriptor
        $o.Issued_Date = try { Get-Date $_.Custom_ID_Data.Issued_Date -ErrorAction Stop } catch {}
        $o.Expiration_Date = try { Get-Date $_.Custom_ID_Data.Expiration_Date -ErrorAction Stop } catch {}
        $o.WID = $_.Custom_ID_Shared_Reference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty '#text'
        Write-Output $o
    }

}
