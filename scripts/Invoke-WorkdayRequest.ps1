function Invoke-WorkdayRequest {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[xml]$Request,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Uri,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Username,
		[Parameter(Mandatory = $true)]
		[string]$Password
	)

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
	
	$response = ''
	$responseXML = $null
	try {
		$response = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $Uri -Headers $headers -Body $WorkdaySoapEnvelope
	}
	catch {
		$reader = New-Object System.IO.StreamReader -ArgumentList $_.Exception.Response.GetResponseStream()
		$response = $reader.ReadToEnd()
		$reader.Close()
	}
	if ($response -is [xml]) {
		$responseXML = $response
		$response = $responseXML.OuterXml
	} else {
		$responseXML = [xml]$response
	}
	Write-Debug "Response: $($response)"
	if ($response -eq '') {
		Write-Warning 'Empty Response'
	} else {
        if ($responseXML.Envelope.Body.FirstChild.Name -eq 'SOAP-ENV:Fault') {
            throw "$($responseXML.Envelope.Body.Fault.faultcode): $($responseXML.Envelope.Body.Fault.faultstring)"
        }
		[xml]$responseXML.Envelope.Body.InnerXml | Write-Output
	}
}
