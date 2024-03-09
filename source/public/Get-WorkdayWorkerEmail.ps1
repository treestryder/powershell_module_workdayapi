﻿function Get-WorkdayWorkerEmail {
<#
.SYNOPSIS
    Returns a Worker's email addresses.

.DESCRIPTION
    Returns a Worker's email addresses as custom Powershell objects.

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

Get-WorkdayWorkerEmail -WorkerId 123

Type Email                        Primary Public
---- -----                        ------- ------
Home home@example.com                True  False
Work work@example.com                True   True

#>

	[CmdletBinding(DefaultParametersetName='Search')]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true,
            Position=0,
            ParameterSetName='Search')]
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
        [Parameter(ParameterSetName="NoSearch")]
        [xml]$WorkerXml,
        [Alias("Force")]
        [switch]$IncludeInactive

	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'Search') {
        $response = Get-WorkdayWorker -WorkerId $WorkerId -WorkerType $WorkerType -IncludePersonal -Passthru -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive -ErrorAction Stop
        $WorkerXml = $response.Xml
    }

    if ($null -eq $WorkerXml) {
        Write-Warning 'Unable to get Email information, Worker not found.'
        return
    }

    $numberTemplate = [pscustomobject][ordered]@{
        UsageType        = $null
        Email            = $null
        Primary          = $null
        Public           = $null
    }

    $WorkerXml.GetElementsByTagName('wd:Email_Address_Data') | ForEach-Object {
        $o = $numberTemplate.PsObject.Copy()
        $o.UsageType = $_.SelectSingleNode('wd:Usage_Data/wd:Type_Data/wd:Type_Reference/wd:ID[@wd:type="Communication_Usage_Type_ID"]', $NM).InnerText
        $o.Email = $_.Email_Address
        $o.Primary = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Type_Data.Primary )
        $o.Public = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Public )
        Write-Output $o
    }
}
