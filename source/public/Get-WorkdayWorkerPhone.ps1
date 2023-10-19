function Get-WorkdayWorkerPhone {
<#
.SYNOPSIS
    Returns a Worker's phone numbers.

.DESCRIPTION
    Returns a Worker's phone numbers as custom Powershell objects.

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

Get-WorkdayWorkerPhone -WorkerId 123

Type          Number            Primary Public
----          ------            ------- ------
Home/Cell     +1  5551234567       True   True
Work/Landline +1 (555) 765-4321    True   True

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
        [Parameter(ParameterSetName='Search')]
		[string]$Human_ResourcesUri,
        [Parameter(ParameterSetName='Search')]
		[string]$Username,
        [Parameter(ParameterSetName='Search')]
		[string]$Password,
        [Parameter(ParameterSetName='NoSearch')]
        [xml]$WorkerXml,
        [Alias("Force")]
        [switch]$IncludeInactive
	)

    if ($PsCmdlet.ParameterSetName -eq 'Search') {
        if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }
        $response = Get-WorkdayWorker -WorkerId $WorkerId -WorkerType $WorkerType -IncludePersonal -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive -ErrorAction Stop
        $WorkerXml = $response.Xml
    }

    if ($null -eq $WorkerXml) {
        Write-Warning 'Worker not found.'
        return
    }

    $numberTemplate = [pscustomobject][ordered]@{
        UsageType = $null
        DeviceType = $null
        Number  = $null
        Extension = $null
        Primary = $null
        Public  = $null
    }

    $WorkerXml.GetElementsByTagName('wd:Phone_Data') | ForEach-Object {
        $o = $numberTemplate.PsObject.Copy()
        $o.UsageType = $_.SelectSingleNode('wd:Usage_Data/wd:Type_Data/wd:Type_Reference/wd:ID[@wd:type="Communication_Usage_Type_ID"]', $NM).InnerText
        $o.DeviceType = $_.SelectSingleNode('wd:Phone_Device_Type_Reference/wd:ID[@wd:type="Phone_Device_Type_ID"]', $NM).InnerText
        $international = if ($_ | Get-Member 'International_Phone_Code') { $_.International_Phone_Code }
        $areaCode = if ($_ | Get-Member 'Area_Code') { $_.Area_Code }
        $phoneNumber = if ($_ | Get-Member 'Phone_Number') { $_.Phone_Number }

        $o.Number = '{0} ({1}) {2}' -f $international, $areaCode, $phoneNumber
        $o.Extension = if ($_ | Get-Member 'Phone_Extension') { $_.Phone_Extension }
        $o.Primary = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Type_Data.Primary )
        $o.Public = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Public )
        Write-Output $o
    }
}
