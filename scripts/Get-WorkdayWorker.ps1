function Get-WorkdayWorker {
<#
.SYNOPSIS
    Gets Worker information as Workday XML.

.DESCRIPTION
    Gets Worker information as Workday XML.

.PARAMETER EmployeeId
    The Worker's Employee Id at Workday. This cmdlet does not currently
    support Contengent Workers or referencing workers by WID.

.PARAMETER IncludePersonal
    Adds Reference and Personal_Information values to response.

.PARAMETER IncludeDefault
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
    
Get-WorkdayWorker -EmpoyeeId 123 -IncludePersonal -IncludeDefault

#>

	[CmdletBinding()]
    [OutputType([XML],[PSCustomObject])]
	param (
		[string]$EmployeeId,
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password,
        [switch]$IncludePersonal,
        [switch]$IncludeDefault,
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
  </bsvc:Response_Group>
</bsvc:Get_Workers_Request>
'@

	$request.Get_Workers_Request.Request_References.Worker_Reference.ID.InnerText = $EmployeeId

    # Default = Reference, Personal Data, Employment Data, Compensation Data, Organization Data, and Role Data.

    if ($IncludePersonal -or $IncludeDefault) {
        $request.Get_Workers_Request.Response_Group.Include_Reference = 'true'
        $request.Get_Workers_Request.Response_Group.Include_Personal_Information = 'true'
    }

    if ($IncludeDefault) {
        $request.Get_Workers_Request.Response_Group.Include_Employment_Information = 'true'
        $request.Get_Workers_Request.Response_Group.Include_Compensation = 'true'
        $request.Get_Workers_Request.Response_Group.Include_Organizations = 'true'
        $request.Get_Workers_Request.Response_Group.Include_Roles = 'true'
    }
	
    try {
        $response = Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password
    }
    catch { throw }

    if ($Passthru) { return $response }

    $referenceId = $response.Get_Workers_Response.Response_Data.Worker.Worker_Reference.ID | where {$_.type -ne 'WID'}

    $worker = [pscustomobject][ordered]@{
        WorkerWid        = $response.Get_Workers_Response.Response_Data.Worker.Worker_Reference.ID | where {$_.type -eq 'WID'} | select -ExpandProperty '#text'
        WorkerDescriptor = $response.Get_Workers_Response.Request_References.Worker_Reference.Descriptor
        PreferredName    = $response.Get_Workers_Response.Response_Data.Worker.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Formatted_Name
        FirstName        = $response.Get_Workers_Response.Response_Data.Worker.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.First_Name
        LastName         = $response.Get_Workers_Response.Response_Data.Worker.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Last_Name
        WorkerType       = $referenceId.type
        WorkerId         = $referenceId.'#text'
        OtherId          = $null
        Phone            = $null
        Email            = $null
        XML              = $response
    }

    if ($IncludePersonal) {
        $worker.Phone   = @(Get-WorkdayWorkerPhone -WorkerXml $response)
        $worker.Email   = @(Get-WorkdayWorkerEmail -WorkerXml $response)
        $worker.OtherId = @(Get-WorkdayWorkerOtherId -WorkerXml $response)
    }

    Write-Output $worker
}