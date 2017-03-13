function Update-WorkdayWorkerPhone {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$EmployeeId,
		[Parameter(Mandatory = $true)]
        [Alias('OfficePhone')]
		[string]$WorkPhone,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Uri,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Username,
		[Parameter(Mandatory = $true)]
		[string]$Password,
        [switch]$Passthru
	)
    
    function scrub ([string]$PhoneNumber) { $PhoneNumber -replace '[^\d]','' -replace '^1','' }

    $current = Get-WorkdayWorkerPhone -EmployeeId $EmployeeId -Uri $Uri -Username $Username -Password $Password

    $scrubbedCurrent = scrub $current['Work/Landline']
    $scrubbedProposed = scrub $WorkPhone

    if ($scrubbedCurrent -ne $scrubbedProposed) {
        Set-WorkdayWorkerPhone @PSBoundParameters | where {$Passthru} | Write-Output
    }
}
