function Invoke-WorkdayRequest {
<#
.SYNOPSIS
    Sends XML requests to Workday API, with proper authentication and receives XML response.

.DESCRIPTION
    Sends XML requests to Workday API, with proper authentication and receives XML response.

    Used for all communication to Workday in this module and may be used to send
    custom XML requests.

.PARAMETER Request
    The Workday request XML to be sent to Workday.
    See https://community.workday.com/custom/developer/API/index.html for more information.

.PARAMETER Uri
    Endpoint Uri for the request.

.PARAMETER Username
    Username used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.PARAMETER Password
    Password used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.EXAMPLE
    
$response = Invoke-WorkdayRequest -Request '<bsvc:Server_Timestamp_Get xmlns:bsvc="urn:com.workday/bsvc" />' -Uri https://SERVICE.workday.com/ccx/service/TENANT/Human_Resources/v25.1

$response.Server_Timestamp

wd                   version Server_Timestamp_Data        
--                   ------- ---------------------        
urn:com.workday/bsvc v25.1   2015-12-02T12:18:30.841-08:00

.INPUTS
    Workday XML

.OUTPUTS
    Workday XML
#>

	[CmdletBinding()]
    [OutputType([XML])]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[xml]$Request,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Uri,
		[string]$Username,
		[string]$Password
	)
    
    if ($WorkdayConfiguration.Credential -is [PSCredential]) {
        if ([string]::IsNullOrWhiteSpace($Username)) { $Username = $WorkdayConfiguration.Credential.Username }
        if ([string]::IsNullOrWhiteSpace($Password)) { $Password = $WorkdayConfiguration.Credential.GetNetworkCredential().Password }
    }

	$WorkdaySoapEnvelope = [xml] @'
<soapenv:Envelope xmlns:bsvc="urn:com.workday/bsvc" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Header>
        <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
            <wsse:UsernameToken>
                <wsse:Username>IntegrationUser@Tenant</wsse:Username>
                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">Password</wsse:Password>
            </wsse:UsernameToken>
        </wsse:Security>
    </soapenv:Header>
    <soapenv:Body>
         <bsvc:RequestNode xmlns:bsvc="urn:com.workday/bsvc" />
    </soapenv:Body>
</soapenv:Envelope>
'@

	$WorkdaySoapEnvelope.Envelope.Header.Security.UsernameToken.Username = $Username
	$WorkdaySoapEnvelope.Envelope.Header.Security.UsernameToken.Password.InnerText = $Password
	$WorkdaySoapEnvelope.Envelope.Body.InnerXml = $Request.OuterXml

	Write-Debug "Request: $($WorkdaySoapEnvelope.OuterXml)"
	$headers= @{
		'Content-Type' = 'text/xml;charset=UTF-8'
	}
	
    
     $o = [pscustomobject][ordered]@{
        Success    = $false
        Message  = 'Unknown Error'
        Xml = $null
    }
    $o.psobject.TypeNames.Insert(0, "WorkdayResponse")

	$response = $null
    try {
		$response = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $Uri -Headers $headers -Body $WorkdaySoapEnvelope
        $o.Xml = [xml]$response.Envelope.Body.InnerXml
        $o.Message = ''
        $o.Success = $true
	}
	catch {
        $o.Success = $false
		$reader = New-Object System.IO.StreamReader -ArgumentList $_.Exception.Response.GetResponseStream()
		$response = $reader.ReadToEnd()
		$reader.Close()
        try {
           $xml = [xml]$response
           $o.Xml = [xml]$xml.Envelope.Body.InnerXml 

            # Put the first Workday Exception into the Message property.
            if ($o.Xml.InnerXml.StartsWith('<SOAP-ENV:Fault ')) {
                $o.Success = $false
                $o.Message = "$($o.Xml.Fault.faultcode): $($o.Xml.Fault.faultstring)"
            }
        }
        catch {
            $o.Message = $response
        }
	}
    
    Write-Output $o
}
