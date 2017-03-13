function Set-WorkdayWorkerDocument {
<#
.SYNOPSIS
    Uploads a document to a Worker's records in Workday.

.DESCRIPTION
    Uploads a document to a Worker's records in Workday.

.PARAMETER EmployeeId
    The Worker's Employee Id at Workday. This cmdlet does not currently
    support Contengent Workers or referencing workers by WID.

.PARAMETER Path
    The Path to the document file to upload.

.PARAMETER StaffingUri
    Staffing Endpoint Uri for the request. If not provided, the value
    stored with Set-WorkdayEndpoint -Endpoint Staffing is used.

.PARAMETER Username
    Username used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.PARAMETER Password
    Password used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.EXAMPLE
    
Set-WorkdayWorkerDocument -EmpoyeeId 123 -Path Document.pdf

#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$WorkerId,
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
		[Parameter(Mandatory = $true)]
		[ValidateScript({Test-Path $_ -PathType Leaf})]
		[string]$Path,
        [string]$FileName,
        [Parameter(Mandatory = $true)]
        [ValidateSet('WID', 'Document_Category__Workday_Owned__ID', 'Document_Category_ID')]
        [string]$CategoryType,
        [Parameter(Mandatory = $true)]
        [string]$CategoryId,
        [string]$Comment,
		[string]$StaffingUri,
		[string]$Username,
		[string]$Password
	)

    Add-Type -AssemblyName "System.Web"

    if ([string]::IsNullOrWhiteSpace($StaffingUri)) { $StaffingUri = $WorkdayConfiguration.Endpoints['Staffing'] }

	$request = [xml]@'
<bsvc:Put_Worker_Document_Request bsvc:Add_Only="false" xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Worker_Document_Data>
    <bsvc:Filename>Filename</bsvc:Filename>
    <!--Optional:-->
    <bsvc:Comment></bsvc:Comment>
    <bsvc:File>Z2Vybw==</bsvc:File>
    <bsvc:Document_Category_Reference>
      <bsvc:ID bsvc:type="CategoryType">CategoryId</bsvc:ID>
    </bsvc:Document_Category_Reference>
	<bsvc:Worker_Reference>
		<bsvc:ID bsvc:type="Employee_ID">Employee_ID</bsvc:ID>
	</bsvc:Worker_Reference>
    <bsvc:Content_Type>ContentType</bsvc:Content_Type>
  </bsvc:Worker_Document_Data>
</bsvc:Put_Worker_Document_Request>
'@

    $request.Put_Worker_Document_Request.Worker_Document_Data.Worker_Reference.ID.InnerText = $WorkerId
    if ($WorkerType -eq 'Contingent_Worker_ID') {
        $request.Put_Worker_Document_Request.Worker_Document_Data.Worker_Reference.ID.type = 'Contingent_Worker_ID'
    }
    if ($WorkerType -eq 'WID') {
        $request.Put_Worker_Document_Request.Worker_Document_Data.Worker_Reference.ID.type = 'WID'
    }

    if ([string]::IsNullOrWhiteSpace($FileName)) {
        $FileName = [string] (Split-Path -Path $Path -Leaf)
    }
	$request.Put_Worker_Document_Request.Worker_Document_Data.Filename = $FileName
    $request.Put_Worker_Document_Request.Worker_Document_Data.File = [System.Convert]::ToBase64String( [system.io.file]::ReadAllBytes( $Path ) )
    $request.Put_Worker_Document_Request.Worker_Document_Data.Document_Category_Reference.ID.type = $CategoryType
    $request.Put_Worker_Document_Request.Worker_Document_Data.Document_Category_Reference.ID.InnerText = $CategoryId
    $request.Put_Worker_Document_Request.Worker_Document_Data.Comment = $Comment
	$request.Put_Worker_Document_Request.Worker_Document_Data.Content_Type = [System.Web.MimeMapping]::GetMimeMapping( $fileName )

	Invoke-WorkdayRequest -Request $request -Uri $StaffingUri -Username:$Username -Password:$Password | Write-Output
	}