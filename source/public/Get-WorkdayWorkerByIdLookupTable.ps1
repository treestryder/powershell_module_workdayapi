function Get-WorkdayWorkerByIdLookupTable {
    <#
    .SYNOPSIS
        Returns a hashtable of Worker Type and IDs, indexed by ID.

    .DESCRIPTION
        Returns a hashtable of Worker Type and IDs, indexed by ID. Useful
        when the Contingent Worker and Employee ID numbers are unique.
    #>
    [CmdletBinding()]
    param (
        [switch]$IncludeInactive,
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    $WorkerByIdLookup = @{}

    Write-Verbose 'Downloading lookup table from Workday.'
    Get-WorkdayWorker -IncludeInactive:$IncludeInactive -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password | ForEach-Object {
        if (-not $WorkerByIdLookup.ContainsKey($_.WorkerId)) {
            $WorkerByIdLookup[$_.WorkerId] = @()
        }
        $WorkerByIdLookup[$_.WorkerId] += @{
            WorkerType = $_.WorkerType
            WorkerId   = $_.WorkerId
            WorkerWid  = $_.WorkerWid
        }
    }
    Write-Output $WorkerByIdLookup
}
