param (
    [string]$ConfigurationFile = '~\.WorkdayApi.clixml'
)

$WorkdayConfiguration = @{
    Endpoints = @{
        Human_Resources = $null
        Integrations    = $null
        Staffing        = $null
    }
    Credential = $null
}

### Change from old configuration name to new name.
$OldWorkdayConfigurationFile = $(
    If (($env:OS -eq 'Windows_NT') -Or ($PSVersionTable.platform -eq 'Win32NT')){
        Join-Path $env:LOCALAPPDATA WorkdayConfiguration.clixml
    }ElseIf(($PSVersionTable.platform -eq 'Unix')){
        Join-Path ~/.workdayapi/ 'WorkdayConfiguration.clixml'
    })
if (Test-Path $OldWorkdayConfigurationFile) {
    Move-Item -Path $OldWorkdayConfigurationFile -Destination $ConfigurationFile    
}

if (Test-Path $ConfigurationFile) {
    $WorkdayConfiguration = Import-Clixml $ConfigurationFile
}

$NM = New-Object System.Xml.XmlNamespaceManager -ArgumentList (New-Object System.Xml.NameTable)
$NM.AddNamespace('wd','urn:com.workday/bsvc')
$NM.AddNamespace('bsvc','urn:com.workday/bsvc')

Get-ChildItem "$PSScriptRoot/public/*.ps1" | ForEach-Object { . $_ }
