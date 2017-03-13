function Remove-WorkdayConfiguration {
<#
.SYNOPSIS
    Removes Workday configuration file from the current users Profile.

.DESCRIPTION
    Removes Workday configuration file from the current users Profile.

.EXAMPLE
    Remove-WorkdayConfiguration

#>

    [CmdletBinding()]
    param ()

    if (Test-Path -Path $WorkdayConfigurationFile) {
        Remove-Item -Path $WorkdayConfigurationFile
    }
}
