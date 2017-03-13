$WorkdayConfiguration = @{
    Endpoints = @{
        Human_Resources = $null
        Integration     = $null
        Staffing        = $null
    }
    Credential = $null
}

$WorkdayConfigurationFile = Join-Path $env:LOCALAPPDATA WorkdayConfiguration.clixml
if (Test-Path $WorkdayConfigurationFile) {
    $WorkdayConfiguration = Import-Clixml $WorkdayConfigurationFile
}

Get-ChildItem "$PSScriptRoot/scripts/*.psm1" | foreach { Import-Module $_ }
Get-ChildItem "$PSScriptRoot/scripts/*.ps1" | foreach { . $_ }
