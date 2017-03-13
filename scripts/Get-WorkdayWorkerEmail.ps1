﻿function Get-WorkdayWorkerEmail {
<#
.SYNOPSIS
    Returns a Worker's email addresses.

.DESCRIPTION
    Returns a Worker's email addresses as custom Powershell objects.

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
    
Get-WorkdayWorkerEmail -EmpoyeeId 123

Type Email                        Primary Public
---- -----                        ------- ------
Home home@example.com                True  False
Work work@example.com                True   True

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
        Type             = $null
        Email            = $null
        Primary          = $null
        Public           = $null
    }

    $w.Get_Workers_Response.Response_Data.FirstChild.Worker_Data.Personal_Data.Contact_Data.Email_Address_Data | foreach {
        $o = $numberTemplate.PsObject.Copy()
        $o.Type = $_.Usage_Data.Type_Data.Type_Reference.Descriptor
        $o.Email = $_.Email_Address
        $o.Primary = $_.Usage_Data.Type_Data.Primary -match '1|true'
        $o.Public = $_.Usage_Data.Public -match '1|true'
        Write-Output $o
    }
}
