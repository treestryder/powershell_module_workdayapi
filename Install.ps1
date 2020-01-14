[CmdletBinding()]
param (
    [string]$InstallPath = $(
        If (($env:OS -eq 'Windows_NT') -Or ($PSVersionTable.platform -eq 'Win32NT')){
            Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules\WorkdayApi'
        }ElseIf(($PSVersionTable.platform -eq 'Unix')){
            Join-Path ~/.local/share/ 'powershell/Modules/WorkdayApi'
        }),
    [switch]$Force
)

$sourceFiles = @(
    '.\source\public\*'
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
