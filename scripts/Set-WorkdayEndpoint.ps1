function Set-WorkdayEndpoint {
<#
.SYNOPSIS
    Sets the default Uri value for a particular Endpoint.

.DESCRIPTION
    Sets the default Uri value for a particular Endpoint. These values
    can be saved to a user's profile using Save-WorkdayConfiguration.

.PARAMETER Endpoint
    The curent Endpoints used by this module are:
    'Human_Resources', 'Staffing'

.PARAMETER Uri
    Uri for this Endpoint.

.EXAMPLE

Set-WorkdayEndpoint -Endpoint Staffing -Uri 'https://SERVICE.workday.com/ccx/service/TENANT/Staffing/v26.0'

    Demonstrates how to set a single Endpoint value.

.EXAMPLE

ConvertFrom-Csv @'
Endpoint,Uri
Staffing,https://SERVICE.workday.com/ccx/service/TENANT/Staffing/v26.0
Human_Resources,https://SERVICE.workday.com/ccx/service/TENANT/Human_Resources/v26.0
Integrations,https://SERVICE.workday.com/ccx/service/TENANT/Integrations/v26.0
'@ | Set-WorkdayEndpoint

    Demonstrates how it would be possible to import a CSV file to set these values.
    This will be more important when there are more Endpoints supported.

#>

    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('Human_Resources', 'Integrations', 'Staffing')]
        [string]$Endpoint,
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string]$Uri
    )

    process {
        $WorkdayConfiguration.Endpoints[$Endpoint] = $Uri
    }
}
