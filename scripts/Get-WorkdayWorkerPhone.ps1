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
        [xml]$WorkerXml
	)

    if ($PsCmdlet.ParameterSetName -eq 'Search') {
        if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }
        $response = Get-WorkdayWorker -WorkerId $WorkerId -WorkerType $WorkerType -IncludePersonal -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -ErrorAction Stop
        $WorkerXml = $response.Xml
    }

    if ($WorkerXml -eq $null) {
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

    $WorkerXml.GetElementsByTagName('wd:Phone_Data') | foreach {
        $o = $numberTemplate.PsObject.Copy()
        $o.UsageType = $_.Usage_Data.Type_Data.Type_Reference.Descriptor
        $o.DeviceType = $_.Phone_Device_Type_Reference.Descriptor
        $international = $_ | select -ExpandProperty 'International_Phone_Code' -ErrorAction SilentlyContinue
        $areaCode = $_ | select -ExpandProperty 'Area_Code' -ErrorAction SilentlyContinue
        $phoneNumber = $_ | select -ExpandProperty 'Phone_Number' -ErrorAction SilentlyContinue
        $o.Number = '{0} ({1}) {2}' -f $international, $areaCode, $phoneNumber
        $o.Extension = $_ | select -ExpandProperty 'Phone_Extension' -ErrorAction SilentlyContinue
        $o.Primary = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Type_Data.Primary )
        $o.Public = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Public )
        Write-Output $o
    }
}
