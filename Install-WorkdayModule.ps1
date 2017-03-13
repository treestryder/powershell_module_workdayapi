[CmdletBinding()]
param (
    [string]$InstallPath = (Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules\WorkdayApi'),
    [switch]$Force
)

$sourceFiles = @(
    '.\en-US\',
    '.\samples\',
    '.\scripts\',
    '.\tests\',
    '.\WorkdayApi.ps*'
)


if (Test-Path $InstallPath) {
    if ($Force) {
        Remove-Item -Path $InstallPath\* -Recurse
    } else {
        Write-Warning "Module already installed at `"$InstallPath`" use -Force to overwrite installation."
        return
    }
} else {
    New-Item -Path $InstallPath -ItemType Directory | Out-Null
}

Push-Location $PSScriptRoot

Copy-Item -Path $sourceFiles -Destination $InstallPath -Recurse

Pop-Location

Import-Module -Name WorkdayApi -Verbose
