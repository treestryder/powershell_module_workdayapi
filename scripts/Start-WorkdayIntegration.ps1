function Start-WorkdayIntegration {
<#
.SYNOPSIS
    Starts a Workday Integration.

.DESCRIPTION
    Starts a Workday Integration and returns the resulting Integration 
    information as a custom Powershell object. If the -Wait switch is used,
    the script will wait for the Integration to complete and return the
    Event information.

.PARAMETER Id
    The WID or Integration_System_ID of the Integration to be triggered.

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

.PARAMETER Wait
    Causes the script to wait for the Integration to complete, then returns
    the resulting Event information.

.PARAMETER UseDefaultCredentials
    Sets Invoke_Integration_As_Current_User to 'true'.
    
.EXAMPLE
    Start-WorkdayIntegration -Id Integration/Id/StartHere -Type Integration_System_ID -Integrations_ResourcesUri 'https://SERVICE.workday.com/ccx/service/TENANT/Integrations/v26.0'

    Name    : Integration ESB Invocation (INT123 Integration - 04/13/2016 08:39:02.099 (Processing))
    Start   : 4/13/2016 11:39:02 AM
    End     : 
    Message : 
    Xml     : #document

#>

	[CmdletBinding(DefaultParametersetName='Search')]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true,
            Position=0)]
		[string]$Id,
		[ValidateSet('WID', 'Integration_System_ID')]
		[string]$Type = 'Integration_System_ID',
		[string]$Username,
		[string]$Password,
        [string]$Integrations_ResourcesUri,
        [switch]$Wait,
        [switch]$UseDefaultCredentials
	)

    if ([string]::IsNullOrWhiteSpace($Integrations_ResourcesUri)) { $Integrations_ResourcesUri = $WorkdayConfiguration.Endpoints['Integrations'] }

    $request = [XML]@'
<bsvc:Launch_Integration_Event_Request bsvc:version="v27.0" xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Integration_System_Reference>
    <bsvc:ID bsvc:type="type">id</bsvc:ID>
  </bsvc:Integration_System_Reference>
  <bsvc:Invoke_Integration_As_Current_User>false</bsvc:Invoke_Integration_As_Current_User>
</bsvc:Launch_Integration_Event_Request>
'@

    $request.Launch_Integration_Event_Request.Integration_System_Reference.ID.type = $Type
    $request.Launch_Integration_Event_Request.Integration_System_Reference.ID.InnerText = $Id
    if ($UseDefaultCredentials) {
        $request.Launch_Integration_Event_Request.Invoke_Integration_As_Current_User = 'true'
    }


    $response = Invoke-WorkdayRequest -Request $request -Uri $Integrations_ResourcesUri -Username:$Username -Password:$Password

    $output = [pscustomobject][ordered]@{
        Name      = $null
        Wid       = $null
        Message   = 'Error'
        Xml       = $null
    }

    if ($response -eq $null) {
        return $output
    }
    
    if ($response.Success -eq $false) {
        $output.Message = $response.Message
        $output.Xml = $response.Xml
        return $output
    }

    $output.Name = $response.Xml.Launch_Integration_Event_Response.Integration_Event.Integration_Event_Reference.Descriptor
    $output.Wid = $response.Xml.Launch_Integration_Event_Response.Integration_Event.Integration_Event_Reference.ID | where {$_.type -eq 'WID'} | select -ExpandProperty InnerText
    $initTime = Get-Date $response.Xml.Launch_Integration_Event_Response.Integration_Event.Integration_Event_Data.Initiated_DateTime
    $output.Message = 'Started at {0:g}.' -f $initTime
    $output.Xml = $response.Xml
    if ($Wait) {
        $event = Get-WorkdayIntegrationEvent -Wid $output.Wid -Integrations_ResourcesUri:$Integrations_ResourcesUri -Username:$Username -Password:$Password
        while ($event.End -eq $null) {
            Start-Sleep -Seconds 5
            $event = Get-WorkdayIntegrationEvent -Wid $output.Wid -Integrations_ResourcesUri:$Integrations_ResourcesUri -Username:$Username -Password:$Password   
        }
        return $event
    }
    return $output
}
