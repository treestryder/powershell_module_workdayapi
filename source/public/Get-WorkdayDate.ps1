<#
.SYNOPSIS
    Gets the current time and date from Workday.

.DESCRIPTION
    Gets the current time and date, as a DateTime object, from Workday.

.PARAMETER Human_ResourcesUri
    Human_Resources Endpoint Uri for the request. If not provided, the value
    stored with Set-WorkdayEndpoint -Endpoint Human_Resources is used.

.PARAMETER Username
    Username used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.PARAMETER Password
    Password used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.EXAMPLE

Get-WorkdayWorker -WorkerId 123 -IncludePersonal

#>
function Get-WorkdayDate {
    [CmdletBinding()]
    param (
        [string]$Human_ResourcesUri,
        [string]$Username,
        [string]$Password
    )

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = Get-WorkdayEndpoint 'Human_Resources' }

    $request = '<bsvc:Server_Timestamp_Get xmlns:bsvc="urn:com.workday/bsvc" />'
    $response = Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password

    if ($response.Success) {
        Get-Date $response.Xml.Server_TimeStamp.Server_Timestamp_Data
    }
    else {
        Write-Warning $response.Message
    }
}
