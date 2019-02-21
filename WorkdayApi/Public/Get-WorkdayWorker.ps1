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

.PARAMETER Passthru
    Outputs Invoke-WorkdayRequest object, rather than a custom Worker object.

.PARAMETER IncludeInactive
    Also returns inactive worker(s). Alias is Force

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
        [Parameter(Position=0,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='IndividualWorker')]
		[ValidatePattern ('^$|^[a-fA-F0-9\-]{1,32}$')]
        [string]$WorkerId,
        [Parameter(Position=1,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='IndividualWorker')]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password,
        [switch]$IncludePersonal,
        [switch]$IncludeWork,
        [switch]$IncludeDocuments,
        [DateTime]$AsOfEntryDateTime = (Get-Date),
        # Outputs raw XML, rather than a custom object.
        [switch]$Passthru,
        [Alias("Force")]
        [switch]$IncludeInactive
	)

    begin {
        if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = Get-WorkdayEndpoint 'Human_Resources' }
    }

    process {
    	$request = [xml]@'
<bsvc:Get_Workers_Request bsvc:version="v30.0" xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false">
	<bsvc:Worker_Reference>
		<bsvc:ID bsvc:type="Employee_ID">?EmployeeId?</bsvc:ID>
	</bsvc:Worker_Reference>
  </bsvc:Request_References>
  <bsvc:Response_Filter>
    <bsvc:Page>Page</bsvc:Page>
    <bsvc:As_Of_Entry_DateTime>?DateTime?</bsvc:As_Of_Entry_DateTime>
  </bsvc:Response_Filter>
  <bsvc:Request_Criteria>
    <bsvc:Exclude_Inactive_Workers>true</bsvc:Exclude_Inactive_Workers>
  </bsvc:Request_Criteria>
  <bsvc:Response_Group>
    <bsvc:Include_Reference>true</bsvc:Include_Reference>
    <bsvc:Include_Personal_Information>false</bsvc:Include_Personal_Information>
    <bsvc:Include_Employment_Information>false</bsvc:Include_Employment_Information>
    <bsvc:Include_Compensation>false</bsvc:Include_Compensation>
    <bsvc:Include_Organizations>false</bsvc:Include_Organizations>
    <bsvc:Include_Roles>false</bsvc:Include_Roles>
    <bsvc:Include_Worker_Documents>false</bsvc:Include_Worker_Documents>
  </bsvc:Response_Group>
</bsvc:Get_Workers_Request>
'@

        $request.Get_Workers_Request.Response_Filter.As_Of_Entry_DateTime = $AsOfEntryDateTime.ToString('o')

        if ([string]::IsNullOrWhiteSpace($WorkerId)) {
            $null = $request.Get_Workers_Request.RemoveChild($request.Get_Workers_Request.Request_References)
        } else {
            $request.Get_Workers_Request.Request_References.Worker_Reference.ID.InnerText = $WorkerId
            if ($WorkerType -eq 'Contingent_Worker_ID') {
                $request.Get_Workers_Request.Request_References.Worker_Reference.ID.type = 'Contingent_Worker_ID'
            } elseif ($WorkerType -eq 'WID') {
                $request.Get_Workers_Request.Request_References.Worker_Reference.ID.type = 'WID'
            }
        }

        # Default = Reference, Personal Data, Employment Data, Compensation Data, Organization Data, and Role Data.
        if ($IncludePersonal) {
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

        if ($IncludeInactive) {
            $request.Get_Workers_Request.Request_Criteria.Exclude_Inactive_Workers = 'false'
        }
       
        $more = $true
        $nextPage = 0
        while ($more) {
            $nextPage += 1
            $request.Get_Workers_Request.Response_Filter.Page = $nextPage.ToString()
            $response = Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password
            if ($Passthru -or $response.Success -eq $false) {
                Write-Output $response
            } else {
                $response.Xml | ConvertFrom-WorkdayWorkerXml
            }
            $more = $response.Success -and $nextPage -lt $response.xml.Get_Workers_Response.Response_Results.Total_Pages
        }
    }
}
