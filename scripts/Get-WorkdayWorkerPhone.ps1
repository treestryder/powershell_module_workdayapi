<#
.SYNOPSIS
    Returns a Worker's phone numbers.

.DESCRIPTION
    Returns a Worker's phone numbers as custom Powershell objects.

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
    
Get-WorkdayWorkerPhone -EmpoyeeId 123

Type          Number            Primary Public
----          ------            ------- ------
Home/Landline +1 (123) 456-7890 0        False
Work/Landline +1 (987) 654-3210 1         True

#>

function Get-WorkdayWorkerPhone {
	[CmdletBinding()]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$EmployeeId,
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    try {
        $w = Get-WorkdayWorker -EmployeeId $EmployeeId -IncludePersonal -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -ErrorAction Stop
    }
    catch {
        throw
    }

    $numberTemplate = [pscustomobject][ordered]@{
        Type    = $null
        Number  = $null
        Primary = $null
        Public  = $null
    }

    $w.Get_Workers_Response.Response_Data.FirstChild.Worker_Data.Personal_Data.Contact_Data.Phone_Data | foreach {
        $o = $numberTemplate.PsObject.Copy()
        $o.Type = $_.Usage_Data.Type_Data.Type_Reference.Descriptor + '/' + $_.Phone_Device_Type_Reference.Descriptor
        $o.Number = $_.Formatted_Phone
        $o.Primary = $_.Usage_Data.Type_Data.Primary
        $o.Public = $_.Usage_Data.Public -eq 1
        Write-Output $o
    }
}
