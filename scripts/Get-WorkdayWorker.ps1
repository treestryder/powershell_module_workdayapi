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
        [switch]$Passthru,
        [switch]$Force
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = Get-WorkdayEndpoint 'Human_Resources' }

	$request = [xml]@'
<bsvc:Get_Workers_Request xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false">
	<bsvc:Worker_Reference>
		<bsvc:ID bsvc:type="Employee_ID">employeeId</bsvc:ID>
	</bsvc:Worker_Reference>
  </bsvc:Request_References>
  <bsvc:Request_Criteria>
    <bsvc:Exclude_Inactive_Workers>true</bsvc:Exclude_Inactive_Workers>
  </bsvc:Request_Criteria>
  <bsvc:Response_Filter>
    <bsvc:Page>Page</bsvc:Page>
  </bsvc:Response_Filter>
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

    if ($Force) {
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
            $response.Xml.GetElementsByTagName('wd:Worker') | ConvertFrom-WorkdayWorkerXml | Write-Output 
        }
        $more = $response.Success -and $nextPage -lt $response.xml.Get_Workers_Response.Response_Results.Total_Pages
    }

}

function ConvertFrom-WorkdayWorkerXml {
<#
.Synopsis
   Converts Workday Worker XML into a custom object.
#>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    Param (
        # Param1 help description
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        $Xml
    )

    Begin {
        $WorkerObjectTemplate = [pscustomobject][ordered]@{
            WorkerWid             = $null
            WorkerDescriptor      = $null
            PreferredName         = $null
            FirstName             = $null
            LastName              = $null
            WorkerType            = $null
            WorkerId              = $null
            OtherId               = $null
            Phone                 = $null
            Email                 = $null
            XML                   = $null
        }
        $WorkerObjectTemplate.PsObject.TypeNames.Insert(0, "Workday.Worker")
    }

    Process {
        foreach ($x in $Xml) {
            $o = $WorkerObjectTemplate.PsObject.Copy()

            $referenceId = $x.Worker_Reference.ID | where {$_.type -ne 'WID'}

            $o.WorkerWid        = $x.Worker_Reference.ID | where {$_.type -eq 'WID'} | select -ExpandProperty '#text'
            $o.WorkerDescriptor = $x.Worker_Reference.Descriptor
            $o.PreferredName    = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Formatted_Name
            $o.FirstName        = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.First_Name
            $o.LastName         = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Last_Name
            $o.WorkerType       = $referenceId.type
            $o.WorkerId         = $referenceId.'#text'
            $o.OtherId          = $null
            $o.Phone            = $null
            $o.Email            = $null
            $o.XML              = [XML]$x.OuterXml

            if ($IncludePersonal) {
                $o.Phone   = @(Get-WorkdayWorkerPhone -WorkerXml $x.OuterXml)
                $o.Email   = @(Get-WorkdayWorkerEmail -WorkerXml $x.OuterXml)
                $o.OtherId = @(Get-WorkdayWorkerOtherId -WorkerXml $x.OuterXml)
            }
            Write-Output $o
        }
    }
}
