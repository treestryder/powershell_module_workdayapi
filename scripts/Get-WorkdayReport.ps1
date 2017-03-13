#
# Invoke_WorkdayReport.ps1
#$ Invoke-WorkdayRequest -Request '<role:Execute_Report xmlns:role="urn:com.workday.report/Role_Based_Security_Groups"></role:Execute_Report>' -Uri 'https://wd5-services1.myworkday.com/ccx/service/Report2/peckham/prehmann@peckham.org/Role_Based_Security_Groups' -Username $u -Password $p
function Get-WorkdayReport {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Uri,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Username,
		[Parameter(Mandatory = $true)]
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