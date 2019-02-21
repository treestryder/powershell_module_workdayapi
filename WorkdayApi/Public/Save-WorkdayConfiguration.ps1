function Save-WorkdayConfiguration {
<#
.SYNOPSIS
    Saves default Workday configuration to a file in the current users Profile.

.DESCRIPTION
    Saves default Workday configuration to a file within the current
    users Profile. If it exists, this file is then read, each time the
    Workday Module is imported. Allowing settings to persist between
    sessions.

.EXAMPLE
    Save-WorkdayConfiguration

#>

    [CmdletBinding()]
    param ()

    Export-Clixml -Path $WorkdayConfigurationFile -InputObject $WorkdayConfiguration
}
