
function Get-WorkdayIntegrationEvent {

<#
.SYNOPSIS
    Retrieves the status of a Workday Integration.

.DESCRIPTION
    Retrieves the status of a Workday Integration.

.PARAMETER Wid
    The WID of the Integration Event to retrieve.

.PARAMETER Type
    The type of ID that -Id represents. Valid values
    are 'WID' or 'Integration_System_ID'.

.PARAMETER Integrations_ResourcesUri
    Integration Endpoint Uri for the request. If not provided, the value
    stored with Set-WorkdayEndpoint -Endpoint Integration is tried.

.PARAMETER Username
    Username used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.PARAMETER Password
    Password used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.EXAMPLE
    Get-WorkdayIntegrationEvent -Wid 0123456789ABCDEF0123456789ABCDEF -Integrations_ResourcesUri 'https://SERVICE.workday.com/ccx/service/TENANT/Integrations/v26.0'

    Name            : Integration ESB Invocation (INT123 Integration - 04/13/2016 10:18:57.848 (Completed))
    Start           : 4/13/2016 1:18:57 PM
    End             : 4/13/2016 1:21:21 PM
    Message         : Integration Completed.
    PercentComplete : 100
    Xml             : #document

.NOTES
    Currently only designed for use when waiting for an Integration to complete and retrieving its status.
    Start-WorkdayIntegration -Wait

    TODO: Update request to current specifications. https://community.workday.com/sites/default/files/file-hosting/productionapi/Integrations/v30.0/Launch_Integration.html

#>

	[CmdletBinding(DefaultParametersetName='Search')]
    [OutputType([PSCustomObject])]
	param (
        [Parameter(Mandatory = $true,
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$Wid,
		[string]$Username,
		[string]$Password,
        [string]$Integrations_ResourcesUri
    )

    if ([string]::IsNullOrWhiteSpace($Integrations_ResourcesUri)) { $Integrations_ResourcesUri = $WorkdayConfiguration.Endpoints['Integrations'] }

    $request = [XML]@'
<bsvc:Get_Integration_Events_Request bsvc:version="v27.0" xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Request_References>
    <bsvc:Integration_Event_Reference>
      <bsvc:ID bsvc:type="WID">wid</bsvc:ID>
    </bsvc:Integration_Event_Reference>
  </bsvc:Request_References>
</bsvc:Get_Integration_Events_Request>
'@
    $request.Get_Integration_Events_Request.Request_References.Integration_Event_Reference.ID.InnerText = $wid

    $response = Invoke-WorkdayRequest -Request $request -Uri $Integrations_ResourcesUri -Username:$Username -Password:$Password

    $output = [pscustomobject][ordered]@{
        Name            = $null
        Start           = $null
        End             = $null
        Message         = $null
        PercentComplete = $null
        Xml             = $null
    }

    if ($response -eq $null) {
        $output.Message = 'ERROR: null response.'
        return $output
    }

    if ($response.Success -eq $false) {
        $output.Status = $response.Message
        $output.Xml = $response.Xml
        return $output
    }

    $output.Name = $response.Xml.Get_Integration_Events_Response.Request_References.Integration_Event_Reference.Descriptor

    $startTime = $response.Xml.Get_Integration_Events_Response.Response_Data.Integration_Event.Integration_Event_Data.Initiated_DateTime
    if ([string]::IsNullOrWhiteSpace($startTime) -eq $false) {
        $output.Start = Get-Date $startTime
    }

    $endTime = $response.Xml.Get_Integration_Events_Response.Response_Data.Integration_Event.Integration_Event_Data.Completed_DateTime
    if ([string]::IsNullOrWhiteSpace($endTime) -eq $false) {
        $output.End = Get-Date $endTime
    }

    $output.Message = $response.Xml.Get_Integration_Events_Response.Response_Data.Integration_Event.Integration_Event_Data.Integration_Response_Message

    $percentComplete = $response.Xml.Get_Integration_Events_Response.Response_Data.Integration_Event.Integration_Event_Data.Percent_Complete
    if ([string]::IsNullOrWhiteSpace($percentComplete) -eq $false) {
        $output.PercentComplete = ([int]$percentComplete) * 100
    }

    $output.Xml = $response.Xml
    return $output

}
