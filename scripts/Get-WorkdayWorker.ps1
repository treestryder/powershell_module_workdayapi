function Get-WorkdayWorker {
<#
.SYNOPSIS
    Gets Worker information as Workday XML.

.DESCRIPTION
    Gets Worker information as Workday XML.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

.PARAMETER IncludePersonal
    Adds Reference and Personal_Information values to response.

.PARAMETER IncludeWork
    Adds Employment_Information, Compensation, Organizations and Roles
    values to the response.

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

	[CmdletBinding()]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true,
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
        [string]$WorkerId,
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password,
        [switch]$IncludePersonal,
        [switch]$IncludeWork,
        [switch]$IncludeDocuments,
        # Outputs raw XML, rather than a custom object.
        [switch]$Passthru
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

	$request = [xml]@'
<bsvc:Get_Workers_Request xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false">
	<bsvc:Worker_Reference>
		<bsvc:ID bsvc:type="Employee_ID">employeeId</bsvc:ID>
	</bsvc:Worker_Reference>
  </bsvc:Request_References>
  <bsvc:Response_Group>
    <bsvc:Include_Reference>false</bsvc:Include_Reference>
    <bsvc:Include_Personal_Information>false</bsvc:Include_Personal_Information>
    <bsvc:Include_Employment_Information>false</bsvc:Include_Employment_Information>
    <bsvc:Include_Compensation>false</bsvc:Include_Compensation>
    <bsvc:Include_Organizations>false</bsvc:Include_Organizations>
    <bsvc:Include_Roles>false</bsvc:Include_Roles>
    <bsvc:Include_Worker_Documents>false</bsvc:Include_Worker_Documents>
  </bsvc:Response_Group>
</bsvc:Get_Workers_Request>
'@

    $request.Get_Workers_Request.Request_References.Worker_Reference.ID.InnerText = $WorkerId
    if ($WorkerType -eq 'Contingent_Worker_ID') {
        $request.Get_Workers_Request.Request_References.Worker_Reference.ID.type = 'Contingent_Worker_ID'
    } elseif ($WorkerType -eq 'WID') {
        $request.Get_Workers_Request.Request_References.Worker_Reference.ID.type = 'WID'
    }

    # Default = Reference, Personal Data, Employment Data, Compensation Data, Organization Data, and Role Data.

    if ($IncludePersonal) {
        $request.Get_Workers_Request.Response_Group.Include_Reference = 'true'
        $request.Get_Workers_Request.Response_Group.Include_Personal_Information = 'true'
    }

    if ($IncludeWork) {
        $request.Get_Workers_Request.Response_Group.Include_Employment_Information = 'true'
        $request.Get_Workers_Request.Response_Group.Include_Compensation = 'true'
        $request.Get_Workers_Request.Response_Group.Include_Organizations = 'true'
        $request.Get_Workers_Request.Response_Group.Include_Roles = 'true'
    }

    if ($IncludeDocuments) {
        $request.Get_Workers_Request.Response_Group.Include_Worker_Documents = 'true'
    }

    $response = Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password

    if ($Passthru) { return $response }

    if (-not $response.Success) {
        Write-Warning ('Failed to get Worker information: {0}' -f $response.Message)
        return
    }

    $referenceId = $response.Xml.Get_Workers_Response.Response_Data.Worker.Worker_Reference.ID | where {$_.type -ne 'WID'}

    $worker = [pscustomobject][ordered]@{
        WorkerWid        = $response.Xml.Get_Workers_Response.Response_Data.Worker.Worker_Reference.ID | where {$_.type -eq 'WID'} | select -ExpandProperty '#text'
        WorkerDescriptor = $response.Xml.Get_Workers_Response.Request_References.Worker_Reference.Descriptor
        PreferredName    = $response.Xml.Get_Workers_Response.Response_Data.Worker.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Formatted_Name
        FirstName        = $response.Xml.Get_Workers_Response.Response_Data.Worker.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.First_Name
        LastName         = $response.Xml.Get_Workers_Response.Response_Data.Worker.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Last_Name
        WorkerType       = $referenceId.type
        WorkerId         = $referenceId.'#text'
        OtherId          = $null
        Phone            = $null
        Email            = $null
        XML              = $response.Xml
    }

    if ($IncludePersonal) {
        $worker.Phone   = @(Get-WorkdayWorkerPhone -WorkerXml $response.Xml)
        $worker.Email   = @(Get-WorkdayWorkerEmail -WorkerXml $response.Xml)
        $worker.OtherId = @(Get-WorkdayWorkerOtherId -WorkerXml $response.Xml)
    }

    Write-Output $worker
}