<#
    .Synopsys Script that pulls latest copy of WorkdayAPI, tests it, then publishes it to the Powershell Gallery.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ApiKey,
    [string]$ProjectUri = 'https://github.com/treestryder/powershell_module_workdayapi.git',
    [string]$Repository = 'PSGallery',
    [switch]$WhatIf
)
#TODO: Make this script multiplatform, possibly borrowing more from here https://github.com/PowerShell/PowerShellGet/blob/development/tools/build.psm1

$tempPath   = [System.IO.Path]::GetTempPath()
$rootPath   = './WorkdayAPI'
$sourcePath = './WorkdayAPI/source'
$modulePath = './WorkdayAPI/WorkdayAPI'
try {
    Push-Location $tempPath -ErrorAction Stop
    'Git Cloning project to "{0}".' -f $rootPath | Write-Host -ForegroundColor Yellow
    git clone $ProjectUri $rootPath | Out-String
    if (-not $?) {throw 'Git clone failed.'}

    'Renaming source folder to make Publish-Module work.' | Write-Host -ForegroundColor Yellow
    Move-Item $sourcePath $modulePath -ErrorAction Stop

    'Testing Module.' | Write-Host -ForegroundColor Yellow
    $pesterResult = Invoke-Pester -Script $modulePath -PassThru
    if ($pesterResult.FailedCount -gt 0) { throw "Will not publish, as there were $($pesterResult.FailedCount) failed Pester Tests."}

    'Publishing Module.' | Write-Host -ForegroundColor Yellow
    Publish-Module -Path $modulePath -NuGetApiKey $ApiKey -Repository $Repository -WhatIf:$WhatIf  -ErrorAction Stop -Verbose
}
catch {
    throw
}
finally {
    'Cleaning up.' | Write-Host -ForegroundColor Yellow
    Remove-Item $rootPath -Recurse -Force -ErrorAction Stop
    Pop-Location -ErrorAction Stop
}
