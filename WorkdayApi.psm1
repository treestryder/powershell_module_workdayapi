$WorkdayConfiguration = @{
    Endpoints = @{
        Human_Resources = $null
        Integrations    = $null
        Staffing        = $null
    }
    Credential = $null
}

$WorkdayConfigurationFile = Join-Path $env:LOCALAPPDATA WorkdayConfiguration.clixml
if (Test-Path $WorkdayConfigurationFile) {
    $WorkdayConfiguration = Import-Clixml $WorkdayConfigurationFile
}

Get-ChildItem "$PSScriptRoot/scripts/*.ps1" | foreach { . $_ }
