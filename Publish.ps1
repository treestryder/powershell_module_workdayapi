<#
    .Synopsys Script that pulls latest copy of WorkdayAPI, tests it, then publishes it to the Powershell Gallery.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ApiKey,
    [string]$ProjectUri = 'https://github.com/treestryder/powershell_module_workdayapi.git',
    [switch]$WhatIf
)
#TODO: Make this script multiplatform, possibly borrowing more from here https://github.com/PowerShell/PowerShellGet/blob/development/tools/build.psm1

$TempPath = [System.IO.Path]::GetTempPath()

Push-Location $TempPath
git clone $ProjectUri WorkdayAPI | Out-String
$pesterResult = Invoke-Pester -Script "$TempPath\WorkdayAPI\" -PassThru
if ($pesterResult.FailedCount -gt 0) { throw "Will not publish, as there were $($pesterResult.FailedCount) failed Pester Tests."}
Publish-Module -Path "$TempPath\WorkdayAPI\" -NuGetApiKey $ApiKey -Repository PSGallery -WhatIf:$WhatIf -Verbose
Remove-Item .\WorkdayAPI -Recurse -Force
Pop-Location
