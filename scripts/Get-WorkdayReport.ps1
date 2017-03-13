<#
.SYNOPSIS
    Returns the XML result from any Workday report, based on its URI.

.DESCRIPTION
    Returns the XML result from any Workday report, based on its URI.

.PARAMETER Uri
    Uri for the report.

.PARAMETER Username
    Username used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.PARAMETER Password
    Password used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

#>

function Get-WorkdayReport {
	[CmdletBinding()]
    [OutputType([XML])]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Uri,
		[string]$Username,
		[string]$Password
	)

	if ($Uri -match '\/([a-z0-9_]+)(\?|$)') {
		$reportName = $Matches[1]
	} else {
		throw "A valid report name was not found in the Uri: $Uri"
	}

	$request = @'
         <role:Execute_Report xmlns:role="urn:com.workday.report/{0}"></role:Execute_Report>
'@ -f $reportName

	Invoke-WorkdayRequest -Request $request -Uri $Uri -Username $Username -Password $Password | Write-Output
}