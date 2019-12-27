$WorkdayConfiguration = @{
    Endpoints = @{
        Human_Resources = $null
        Integrations    = $null
        Staffing        = $null
    }
    Credential = $null
}

$WorkdayConfigurationFile = $(
    If (($env:OS -eq 'Windows_NT') -Or ($PSVersionTable.platform -eq 'Win32NT')){
        Join-Path $env:LOCALAPPDATA WorkdayConfiguration.clixml
    }ElseIf(($PSVersionTable.platform -eq 'Unix')){
        Join-Path ~/.workdayapi/ 'WorkdayConfiguration.clixml'
    })

if (Test-Path $WorkdayConfigurationFile) {
    $WorkdayConfiguration = Import-Clixml $WorkdayConfigurationFile
}

$NM = New-Object System.Xml.XmlNamespaceManager -ArgumentList (New-Object System.Xml.NameTable)
$NM.AddNamespace('wd','urn:com.workday/bsvc')
$NM.AddNamespace('bsvc','urn:com.workday/bsvc')

Get-ChildItem "$PSScriptRoot/scripts/*.ps1" | foreach { . $_ }
