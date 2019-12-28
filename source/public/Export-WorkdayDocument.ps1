function Export-WorkdayDocument {
<#
.SYNOPSIS
    Exports Workday Documents.

.DESCRIPTION
    Exports Workday Documents.

.PARAMETER Wid
    The Workday ID of the document to export.

.PARAMETER Path
    The Path to save the exported file to. If an existing directory is given, the document is saved
    with its name in Workday to this directory.

.PARAMETER StaffingUri
    Human_Resources Endpoint Uri for the request. If not provided, the value
    stored with Set-WorkdayEndpoint -Endpoint Human_Resources is used.

.PARAMETER Username
    Username used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.PARAMETER Password
    Password used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.EXAMPLE


#>

	[CmdletBinding()]
    [OutputType([PSCustomObject])]
	param (
        [Parameter(Mandatory = $true,
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9]{32}$')]
		[string]$Wid,
        [string]$Path = (Get-Location),
		[string]$StaffingUri,
		[string]$Username,
		[string]$Password
	)

    if ([string]::IsNullOrWhiteSpace($StaffingUri)) { $StaffingUri = $WorkdayConfiguration.Endpoints['Staffing'] }

	$request = [xml]@'
<bsvc:Get_Worker_Documents_Request bsvc:version="v30.0" xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Request_References>
    <bsvc:Worker_Document_Reference>
      <bsvc:ID bsvc:type="WID">string</bsvc:ID>
    </bsvc:Worker_Document_Reference>
  </bsvc:Request_References>
  <bsvc:Request_Criteria>
    <bsvc:Exclude_Inactive_Workers>false</bsvc:Exclude_Inactive_Workers>
  </bsvc:Request_Criteria>
  <bsvc:Response_Group>
    <bsvc:Include_Worker_Document_Data>true</bsvc:Include_Worker_Document_Data>
  </bsvc:Response_Group>
</bsvc:Get_Worker_Documents_Request>
'@

    $request.Get_Worker_Documents_Request.Request_References.Worker_Document_Reference.ID.'#text' = $Wid

    $response = Invoke-WorkdayRequest -Request $request -Uri $StaffingUri -Username:$Username -Password:$Password

    if ($null -eq $response.Xml) {
        Write-Warning ('Unable to find Document information for WID: {0}' -f $Wid)
        return
    }

    $pathIsContainer = (Get-Item -Path $Path).PsIsContainer

    $data = $response.Xml.GetElementsByTagName('wd:Worker_Document_Data')
    $FilePath = if ($pathIsContainer) {
        Join-Path $Path $data.Filename
    } else {
        $Path
    }

    Write-Verbose ('Exporting document WID: {0} to: {1}' -f $Wid, $FilePath)
    [system.io.file]::WriteAllBytes( $FilePath, [System.Convert]::FromBase64String( $data.File ) )

}