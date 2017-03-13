function Get-WorkdayEndpoint {
<#
.SYNOPSIS
    Gets the default Uri value for all or a particular Endpoint.

.DESCRIPTION
    Gets the default Uri value for all or a particular Endpoint.

.PARAMETER Endpoint
    The curent Endpoints used by this module are:
    'Human_Resources', 'Staffing'

.EXAMPLE
    
Get-WorkdayEndpoint -Endpoint Staffing

    Demonstrates how to get a single Endpoint value.

.EXAMPLE

Get-WorkdayEndpoint

    Demonstrates how to get all of the Endpoint values.

#>

    [CmdletBinding()]
    param (
        [parameter(Mandatory=$false)]
        [ValidateSet('Human_Resources', 'Staffing')]
        [string]$Endpoint
    )

    if ([string]::IsNullOrWhiteSpace($Endpoint)) {
        Write-Output $WorkdayConfiguration.Endpoints
    } else {
        Write-Output $WorkdayConfiguration.Endpoints[$Endpoint]
    }
}
