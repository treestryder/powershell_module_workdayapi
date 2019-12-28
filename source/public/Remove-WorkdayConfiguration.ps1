function Remove-WorkdayConfiguration {
<#
.SYNOPSIS
    Removes Workday configuration file from the current user's Profile.

.DESCRIPTION
    Removes Workday configuration file from the current user's Profile.

.EXAMPLE
    Remove-WorkdayConfiguration

#>

    [CmdletBinding()]
    param ()

    if (Test-Path -Path $ConfigurationFile) {
        Remove-Item -Path $ConfigurationFile
    }
}
