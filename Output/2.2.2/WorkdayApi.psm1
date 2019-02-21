#Region 'PREFIX' 0
    $WorkdayConfiguration = @{
        Endpoints = @{
            Human_Resources = $null
            Integrations    = $null
            Staffing        = $null
        }
        Credential = $null
    }
    
    $WorkdayConfigurationFile = Join-Path $env:LOCALAPPDATA WorkdayConfiguration.clixml
    if (Test-Path $WorkdayConfigurationFile) {
        $WorkdayConfiguration = Import-Clixml $WorkdayConfigurationFile
    } Else {
        $WorkdayConfigurationFile = 'D:\SCRIPTS\SUE\WORKDAY\WORKDAYCONFIGURATION.clixml'
        If (Test-Path $WorkdayConfigurationFile) {
            $WorkdayConfiguration = Import-Clixml $WorkdayConfigurationFile
        }
    }
    
    # Get-ChildItem "$PSScriptRoot/scripts/*.ps1" | foreach { . $_ }
    
    $NM = New-Object System.Xml.XmlNamespaceManager -ArgumentList (New-Object System.Xml.NameTable)
    $NM.AddNamespace('wd','urn:com.workday/bsvc')
    $NM.AddNamespace('bsvc','urn:com.workday/bsvc')
    
    Enable-TLS -Tls12 -Confirm:$false
#EndRegion 'PREFIX'
#Region '.\Private\Format-xml.ps1' 0
function Format-Xml {
<#
.SYNOPSIS
Format the incoming object as the text of an XML document.
#>
    param(
        ## Text of an XML document.
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$Text
    )

    begin {
        $data = New-Object System.Collections.ArrayList
    }
    process {
        [void] $data.Add($Text -join "`n")
    }
    end {
        $doc=New-Object System.Xml.XmlDataDocument
        $doc.LoadXml($data -join "`n")
        $sw=New-Object System.Io.Stringwriter
        $writer=New-Object System.Xml.XmlTextWriter($sw)
        $writer.Formatting = [System.Xml.Formatting]::Indented
        $doc.WriteContentTo($writer)
        $sw.ToString()
    }
}
#EndRegion '.\Private\Format-xml.ps1' 27
#Region '.\Public\ConvertFrom-WorkdayWorkerXml.ps1' 0
function ConvertFrom-WorkdayWorkerXml {
<#
.Synopsis
   Converts Workday Worker XML into a custom object.
#>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    Param (
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        [xml[]]$Xml
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
            UserId                = $null
            NationalId            = $null
            OtherId               = $null
            Phone                 = $null
            Email                 = $null
            BusinessTitle         = $null
            JobProfileName        = $null
            Location              = $null
            WorkSpace             = $null
            WorkerTypeReference   = $null
            Manager               = $null
            Company               = $null
            BusinessUnit          = $null
            Supervisory           = $null
            XML                   = $null
        }
        $WorkerObjectTemplate.PsObject.TypeNames.Insert(0, "Workday.Worker")
    }

    Process {
        foreach ($elements in $Xml) {
            foreach ($x in $elements.SelectNodes('//wd:Worker', $NM)) {
                $o = $WorkerObjectTemplate.PsObject.Copy()

                $referenceId = $x.Worker_Reference.ID | Where-Object {$_.type -ne 'WID'}

                $o.WorkerWid        = $x.Worker_Reference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty '#text'
                $o.WorkerDescriptor = $x.Worker_Descriptor
                $o.PreferredName    = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Formatted_Name
                $o.FirstName        = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.First_Name
                $o.LastName         = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Last_Name
                $o.WorkerType       = $referenceId.type
                $o.WorkerId         = $referenceId.'#text'
                $o.XML              = [XML]$x.OuterXml

                $o.Phone   = @(Get-WorkdayWorkerPhone -WorkerXml $x.OuterXml)
                $o.Email   = @(Get-WorkdayWorkerEmail -WorkerXml $x.OuterXml)
                $o.NationalId = @(Get-WorkdayWorkerNationalId -WorkerXml $x.OuterXml)
                $o.OtherId = @(Get-WorkdayWorkerOtherId -WorkerXml $x.OuterXml)
                $o.UserId  = $x.Worker_Data.User_ID
                
                # The methods SelectNodes and SelectSingleNode have access to the entire XML document and require anchoring with "./" to work as expected.
                $workerJobData = $x.SelectSingleNode('./wd:Worker_Data/wd:Employment_Data/wd:Worker_Job_Data', $NM)
                if ($null -ne $workerJobData) {
                    $o.BusinessTitle = $workerJobData.Position_Data.Business_Title
                    $o.JobProfileName = $workerJobData.Position_Data.Job_Profile_Summary_Data.Job_Profile_Name
                    $o.Location = $workerJobData.SelectNodes('./wd:Position_Data/wd:Business_Site_Summary_Data/wd:Location_Reference/wd:ID[@wd:type="Location_ID"]', $NM).InnerText
                    $o.WorkSpace = $workerJobData.SelectNodes('./wd:Position_Data/wd:Work_Space__Reference/wd:ID[@wd:type="Location_ID"]', $NM).InnerText
                    $o.WorkerTypeReference = $workerJobData.SelectNodes('./wd:Position_Data/wd:Worker_Type_Reference/wd:ID[@wd:type="Employee_Type_ID"]', $NM).InnerText
                    $o.Manager = $workerJobData.Position_Data.Manager_as_of_last_detected_manager_change_Reference.ID |
                        Where-Object {$_.type -ne 'WID'} |
                            Select-Object @{Name='WorkerType';Expression={$_.type}}, @{Name='WorkerID';Expression={$_.'#text'}}
                    $o.Company = $workerJobData.SelectNodes('./wd:Position_Organizations_Data/wd:Position_Organization_Data/wd:Organization_Data[wd:Organization_Type_Reference/wd:ID[@wd:type="Organization_Type_ID" and . = "COMPANY"]]', $NM) | Select-Object -ExpandProperty Organization_Name -First 1
                    $o.BusinessUnit = $workerJobData.SelectNodes('./wd:Position_Organizations_Data/wd:Position_Organization_Data/wd:Organization_Data[wd:Organization_Type_Reference/wd:ID[@wd:type="Organization_Type_ID" and . = "BUSINESS_UNIT"]]', $NM) | Select-Object -ExpandProperty Organization_Name -First 1
                    $o.Supervisory = $workerJobData.SelectNodes('./wd:Position_Organizations_Data/wd:Position_Organization_Data/wd:Organization_Data[wd:Organization_Type_Reference/wd:ID[@wd:type="Organization_Type_ID" and . = "SUPERVISORY"]]', $NM) | Select-Object -ExpandProperty Organization_Name -First 1                          
                }

                Write-Output $o
            }
        }
    }
}
#EndRegion '.\Public\ConvertFrom-WorkdayWorkerXml.ps1' 86
#Region '.\Public\Export-WorkdayDocument.ps1' 0
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
  <bsvc:Response_Group>
    <bsvc:Include_Worker_Document_Data>true</bsvc:Include_Worker_Document_Data>
  </bsvc:Response_Group>
</bsvc:Get_Worker_Documents_Request>
'@

    $request.Get_Worker_Documents_Request.Request_References.Worker_Document_Reference.ID.'#text' = $Wid

    $response = Invoke-WorkdayRequest -Request $request -Uri $StaffingUri -Username:$Username -Password:$Password

    if ($response.Xml -eq $null) {
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
#EndRegion '.\Public\Export-WorkdayDocument.ps1' 82
#Region '.\Public\Get-WorkdayDate.ps1' 0
<#
.SYNOPSIS
    Gets the current time and date from Workday.

.DESCRIPTION
    Gets the current time and date, as a DateTime object, from Workday.

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
function Get-WorkdayDate {
    [CmdletBinding()]
    param (
        [string]$Human_ResourcesUri,
        [string]$Username,
        [string]$Password
    )

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = Get-WorkdayEndpoint 'Human_Resources' }

    $request = '<bsvc:Server_Timestamp_Get xmlns:bsvc="urn:com.workday/bsvc" />' 
    $response = Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password

    if ($response.Success) {
        Get-Date $response.Xml.Server_TimeStamp.Server_Timestamp_Data
    }
    else {
        Write-Warning $response.Message
    }
}
#EndRegion '.\Public\Get-WorkdayDate.ps1' 44
#Region '.\Public\Get-WorkdayEndpoint.ps1' 0
function Get-WorkdayEndpoint {
<#
.SYNOPSIS
    Gets the default Uri value for all or a particular Endpoint.

.DESCRIPTION
    Gets the default Uri value for all or a particular Endpoint.

.PARAMETER Endpoint
    The curent Endpoints used by this module are:
    'Human_Resources', 'Staffing'

.EXAMPLE
    
Get-WorkdayEndpoint -Endpoint Staffing

    Demonstrates how to get a single Endpoint value.

.EXAMPLE

Get-WorkdayEndpoint

    Demonstrates how to get all of the Endpoint values.

#>

    [CmdletBinding()]
    param (
        [parameter(Mandatory=$false)]
        [ValidateSet('Human_Resources', 'Integrations', 'Staffing')]
        [string]$Endpoint
    )

    if ([string]::IsNullOrWhiteSpace($Endpoint)) {
        Write-Output $WorkdayConfiguration.Endpoints
    } else {
        Write-Output $WorkdayConfiguration.Endpoints[$Endpoint]
    }
}
#EndRegion '.\Public\Get-WorkdayEndpoint.ps1' 39
#Region '.\Public\Get-WorkdayIntegrationEvent.ps1' 0

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
#EndRegion '.\Public\Get-WorkdayIntegrationEvent.ps1' 117
#Region '.\Public\Get-WorkdayReport.ps1' 0
function Get-WorkdayReport {
<#
.SYNOPSIS
    Returns the XML result from any Workday report, based on its URI.

.DESCRIPTION
    Returns the XML result from any Workday report, based on its URI.

.PARAMETER Uri
    Uri for the report.

.PARAMETER Username
    Username used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.PARAMETER Password
    Password used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.NOTES
	TODO: Create a parameter that accepts a report name, rather than parsing a Uri.

#>

	[CmdletBinding()]
    [OutputType([XML])]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Uri,
		[string]$Username,
		[string]$Password
	)

	if ($Uri -match '\/([a-z0-9-_]+)(\?|$)') {
		$reportName = $Matches[1]
	} else {
		throw "A valid report name was not found in the Uri: $Uri"
	}

	$request = @'
         <role:Execute_Report xmlns:role="urn:com.workday.report/{0}"></role:Execute_Report>
'@ -f $reportName

	Invoke-WorkdayRequest -Request $request -Uri $Uri -Username:$Username -Password:$Password | Write-Output
}
#EndRegion '.\Public\Get-WorkdayReport.ps1' 46
#Region '.\Public\Get-WorkdayToAdData.ps1' 0
function Get-WorkdayToAdData {
    <#
    .SYNOPSIS
        Converts Get-WorkdayWorker output into "INT011 WD to AD - DT" format.
    .NOTES
        This is a first attempt at pulling data which is normally gathered by
        an integration called "INT011 WD to AD - DT". Though I suspect this
        format is specific to my company, I add this as some may find it
        valuable. In fact, some of this should probably be moved
        into Get-WorkdayWorker.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
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
        [switch]$Force,
        # Adds a "Worker" Property containing the full Worker object.
        [switch]$PassThru
    )

    begin {
        $objectTemplate = 0 | select 'ADD or CHANGE','Employee or Contingent Worker Number','First Name','Last Name','Preferred First Name','Preferred Last Name','User Name','Work Phone','Job Title','Employee or Contingent Worker Type','Worker Type','Worker SubType','Department (LOB)','Sub Department','Location (Building)','Location(Workspace)','Badge Id','Supervisor Name','Supervisor Employee Id','Matrix Manager Name (for Team Members)','Hire Date','Termination Date','Requires Cisco Phone'

        filter ParseWorker {
            $w = $_
            if ($w.psobject.TypeNames -contains 'WorkdayResponse') {
                Write-Error ('Input object was not of type WorkdayResponse: {0}' -f $w.psobject.TypeNames)
                continue
            }

            $o = $objectTemplate.psobject.Copy()
            if ($PassThru) {
                $o = Add-Member -InputObject $o -MemberType NoteProperty -Name Worker -Value $w -PassThru
            }
            $o.'ADD or CHANGE' = ''
            $o.'Employee or Contingent Worker Number' = $w.WorkerId
            $o.'First Name' = $w.Xml.Worker.Worker_Data.Personal_Data.Name_Data.Legal_Name_Data.Name_Detail_Data.First_Name
            $o.'Last Name' = $w.Xml.Worker.Worker_Data.Personal_Data.Name_Data.Legal_Name_Data.Name_Detail_Data.Last_Name
            $o.'Preferred First Name' = $w.FirstName
            $o.'Preferred Last Name' = $w.LastName
            $o.'User Name' = $w.Xml.Worker.Worker_Data.User_ID
            $o.'Work Phone' = $w.Phone | where { $_.UsageType -like 'Work' -and $_.Primary -and $_.Public } | select -ExpandProperty Number -First 1
            $o.'Badge ID' = $w.OtherID | where { $_.Type -eq 'Badge_ID' } | select -ExpandProperty Id -First 1
            $o.'Job Title' = $w.JobProfileName  -replace '^.+?-',''
            $o.'Employee or Contingent Worker Type' = $w.Xml.Worker.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Worker_Type_Reference.ID | where { $_.type -eq 'Employee_Type_ID' } | select -ExpandProperty '#text' -First 1
            $o.'Worker Type' = if ($w.Xml.Worker.Worker_Reference.ID | where { $_.type -eq 'Employee_ID' } ) {'Employee'} else {'Contingent Worker'}
            $o.'Worker SubType' = $w.Xml.Worker.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Worker_Type_Reference.Descriptor
            # Could not find Department.
            # <xsl:value-of select="ws:Additional_Information/ws:Department" /> 
            $o.'Department (LOB)' = 'Unimplemented'
            # Could not find Subdepartment.
            # <xsl:value-of select="ws:Additional_Information/ws:SubDepartment" /> 
            $o.'Sub Department' = 'Unimplemented'
            $o.'Location (Building)' = $w.Location
            $o.'Location(Workspace)' = $w.Workspace
            $supervisorDescriptor = $w.Xml.Worker.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Manager_as_of_last_detected_manager_change_Reference.Descriptor
            $o.'Supervisor Name' = if ($supervisorDescriptor -match '(^.+)\s\(') {
                $Matches[1]
            }
            else {
                $supervisorDescriptor
            }
            $o.'Supervisor Employee Id' = $w.Xml.Worker.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Manager_as_of_last_detected_manager_change_Reference.ID | where { $_.type -eq 'Employee_ID' } | select -ExpandProperty '#text' -First 1
            # Have not found Matrix Manager.
            $o.'Matrix Manager Name (for Team Members)' = $null
            $hireDate = $w.Xml.Worker.Worker_Data.Employment_Data.Worker_Status_Data.Hire_Date
            $o.'Hire Date' = if ($hireDate.length -ge 10) { $hireDate.Substring(0,10) }
            Write-Output $o
        }
    }

    process {
        Get-WorkdayWorker -WorkerId:$WorkerId -WorkerType:$WorkerType -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password -Force:$Force -IncludePersonal -IncludeWork |
            ParseWorker |
                Write-Output
    }
}
#EndRegion '.\Public\Get-WorkdayToAdData.ps1' 89
#Region '.\Public\Get-WorkdayWorker.ps1' 0
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
#EndRegion '.\Public\Get-WorkdayWorker.ps1' 151
#Region '.\Public\Get-WorkdayWorkerByIdLookupTable.ps1' 0
function Get-WorkdayWorkerByIdLookupTable {
    <#
    .SYNOPSIS
        Returns a hashtable of Worker Type and IDs, indexed by ID.

    .DESCRIPTION
        Returns a hashtable of Worker Type and IDs, indexed by ID. Useful
        when the Contingent Worker and Employee ID numbers are unique.
    #>
    [CmdletBinding()]
    param (
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    $WorkerByIdLookup = @{}

    Write-Verbose 'Downloading lookup table from Workday.'
    Get-WorkdayWorker -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password | ForEach-Object {
        if (-not $WorkerByIdLookup.ContainsKey($_.WorkerId)) {
            $WorkerByIdLookup[$_.WorkerId] = @()
        }
        $WorkerByIdLookup[$_.WorkerId] += @{
            WorkerType = $_.WorkerType
            WorkerId   = $_.WorkerId
        }
    }
    Write-Output $WorkerByIdLookup
}
#EndRegion '.\Public\Get-WorkdayWorkerByIdLookupTable.ps1' 32
#Region '.\Public\Get-WorkdayWorkerDocument.ps1' 0
function Get-WorkdayWorkerDocument {
<#
.SYNOPSIS
    Gets Workday Worker Documents.

.DESCRIPTION
    Gets Workday Worker Documents.

.PARAMETER WorkerId
    The Worker's Id at Workday. A Worker ID must be at least 1, up to 32, numbers or hex characters.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

.PARAMETER Path
    If specified, the files will be saved to this directory path.

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

Get-WorkdayWorkerDocument -WorkerId 123

#>

	[CmdletBinding(DefaultParametersetName='Search')]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true,
            Position=0,
            ParameterSetName='Search')]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
        [Parameter(ParameterSetName="Search")]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
        [Parameter(ParameterSetName="Search")]
		[string]$Human_ResourcesUri,
        [Parameter(ParameterSetName="Search")]
		[string]$Username,
        [Parameter(ParameterSetName="Search")]
		[string]$Password,
        [Parameter(ParameterSetName="NoSearch")]
        [xml]$DocumentXml,
        [string]$Path,
        [Alias("Force")]
        [switch]$IncludeInactive
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'Search') {
        $response = Get-WorkdayWorker -WorkerId $WorkerId -WorkerType $WorkerType -IncludeDocuments -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive -ErrorAction Stop
        $DocumentXml = $response.Xml
    }

    if ($DocumentXml -eq $null) {
        Write-Warning 'Unable to find Document information.'
        return
    }

    $fileTemplate = [pscustomobject][ordered]@{
        FileName      = $null
        Category      = $null
        Base64        = $null
    }

    Add-Member -InputObject $fileTemplate -MemberType ScriptMethod -Name SaveAs -Value {
        param ( [string]$Path )
        [system.io.file]::WriteAllBytes( $Path, [System.Convert]::FromBase64String( $this.Base64 ) )
    }

    if (-not ([string]::IsNullOrEmpty($Path)) -and -not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }

    $DocumentXml.GetElementsByTagName('wd:Worker_Document_Detail_Data') | ForEach-Object {
        $o = $fileTemplate.PsObject.Copy()
        $categoryXml = $_.Document_Category_Reference.ID | Where-Object {$_.type -match 'Document_Category__Workday_Owned__ID|Document_Category_ID'}
        $o.Category = '{0}/{1}' -f $categoryXml.type, $categoryXml.'#text'
        $o.FileName = $_.Filename
        $o.Base64 = $_.File
        Write-Output $o
        if (-not ([string]::IsNullOrEmpty($Path))) {
            $filePath = Join-Path $Path $o.FileName
            $o.SaveAs($filePath)
        }
    }
}
#EndRegion '.\Public\Get-WorkdayWorkerDocument.ps1' 100
#Region '.\Public\Get-WorkdayWorkerEmail.ps1' 0
function Get-WorkdayWorkerEmail {
<#
.SYNOPSIS
    Returns a Worker's email addresses.

.DESCRIPTION
    Returns a Worker's email addresses as custom Powershell objects.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

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

Get-WorkdayWorkerEmail -WorkerId 123

Type Email                        Primary Public
---- -----                        ------- ------
Home home@example.com                True  False
Work work@example.com                True   True

#>

	[CmdletBinding(DefaultParametersetName='Search')]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true,
            Position=0,
            ParameterSetName='Search')]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
        [Parameter(ParameterSetName="Search")]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
        [Parameter(ParameterSetName="Search")]
		[string]$Human_ResourcesUri,
        [Parameter(ParameterSetName="Search")]
		[string]$Username,
        [Parameter(ParameterSetName="Search")]
		[string]$Password,
        [Parameter(ParameterSetName="NoSearch")]
        [xml]$WorkerXml,
        [Alias("Force")]
        [switch]$IncludeInactive

	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'Search') {
        $response = Get-WorkdayWorker -WorkerId $WorkerId -WorkerType $WorkerType -IncludePersonal -Passthru -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive -ErrorAction Stop
        $WorkerXml = $response.Xml
    }

    if ($WorkerXml -eq $null) {
        Write-Warning 'Unable to get Email information, Worker not found.'
        return
    }

    $numberTemplate = [pscustomobject][ordered]@{
        UsageType        = $null
        Email            = $null
        Primary          = $null
        Public           = $null
    }

    $WorkerXml.GetElementsByTagName('wd:Email_Address_Data') | ForEach-Object {
        $o = $numberTemplate.PsObject.Copy()
        $o.UsageType = $_.SelectSingleNode('wd:Usage_Data/wd:Type_Data/wd:Type_Reference/wd:ID[@wd:type="Communication_Usage_Type_ID"]', $NM).InnerText
<#
        $UsageXML = $_.Usage_Data.Type_Data.Type_Reference.ID |Where-Object {$_.type -match 'Communication_Usage_Type_ID'}
        $o.UsageType = $UsageXML.'#text' 
#>
        $o.Email = $_.Email_Address
        $o.Primary = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Type_Data.Primary )
        $o.Public = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Public )
        Write-Output $o
    }
}
#EndRegion '.\Public\Get-WorkdayWorkerEmail.ps1' 94
#Region '.\Public\Get-WorkdayWorkerNationalId.ps1' 0
function Get-WorkdayWorkerNationalId {
<#
.SYNOPSIS
    Returns a Worker's National Id information.

.DESCRIPTION
    Returns a Worker's National Id information as custom Powershell objects.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

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

Get-WorkdayWorkerNationalId -WorkerId 123

Type                Id        Descriptor
----                --        ----------
USA-SSN             000000000 000-00-0000 (USA-SSN)

#>

	[CmdletBinding(DefaultParametersetName='Search')]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true,
            Position=0,
            ParameterSetName='Search')]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
        [Parameter(ParameterSetName="Search")]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
        [Parameter(ParameterSetName="Search")]
		[string]$Human_ResourcesUri,
        [Parameter(ParameterSetName="Search")]
		[string]$Username,
        [Parameter(ParameterSetName="Search")]
		[string]$Password,
        [Parameter(ParameterSetName="NoSearch")]
        [xml]$WorkerXml,
        [Alias("Force")]
        [switch]$IncludeInactive
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'Search') {
        $response = Get-WorkdayWorker -WorkerId $WorkerId -WorkerType $WorkerType -IncludePersonal -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive -ErrorAction Stop
        $WorkerXml = $response.Xml
    }

    if ($WorkerXml -eq $null) {
        Write-Warning 'Unable to get National Id information, Worker not found.'
        return
    }

    $numberTemplate = [pscustomobject][ordered]@{
        Type       = $null
        Id         = $null
        Descriptor = $null
        WID = $null
    }

    $WorkerXml.GetElementsByTagName('wd:National_ID') | ForEach-Object {
        $o = $numberTemplate.PsObject.Copy()
        $typeXml = $_.National_ID_Data.ID_Type_Reference.ID | Where-Object {$_.type -eq 'National_ID_Type_Code'}
        $o.Type = $typeXml.'#text'
        $o.Id = $_.National_ID_Data.ID
        $o.Descriptor = $_.National_ID_Reference.Descriptor
        $o.WID = $_.National_ID_Reference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty '#text'
        Write-Output $o
    }

}
#EndRegion '.\Public\Get-WorkdayWorkerNationalId.ps1' 90
#Region '.\Public\Get-WorkdayWorkerOtherId.ps1' 0
function Get-WorkdayWorkerOtherId {
<#
.SYNOPSIS
    Returns a Worker's Id information.

.DESCRIPTION
    Returns a Worker's Id information as custom Powershell objects.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

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

Get-WorkdayWorkerOtherId -WorkerId 123

Type                Id        Descriptor
----                --        ----------
Badge_ID            1         Badge ID

#>

	[CmdletBinding(DefaultParametersetName='Search')]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true,
            Position=0,
            ParameterSetName='Search')]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
        [Parameter(ParameterSetName="Search")]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
        [Parameter(ParameterSetName="Search")]
		[string]$Human_ResourcesUri,
        [Parameter(ParameterSetName="Search")]
		[string]$Username,
        [Parameter(ParameterSetName="Search")]
		[string]$Password,
        [Parameter(ParameterSetName="NoSearch")]
        [xml]$WorkerXml,
        [Alias("Force")]
        [switch]$IncludeInactive
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'Search') {
        $response = Get-WorkdayWorker -WorkerId $WorkerId -WorkerType $WorkerType -IncludePersonal -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive -ErrorAction Stop
        $WorkerXml = $response.Xml
    }

    if ($WorkerXml -eq $null) {
        Write-Warning 'Unable to get Other Id information, Worker not found.'
        return
    }

    $numberTemplate = [pscustomobject][ordered]@{
        Type       = $null
        Id         = $null
        Descriptor = $null
        Issued_Date = $null
        Expiration_Date = $null
        WID = $null
    }

    $WorkerXml.GetElementsByTagName('wd:Custom_ID') | ForEach-Object {
        $o = $numberTemplate.PsObject.Copy()
        $typeXml = $_.Custom_ID_Data.ID_Type_Reference.ID | Where-Object {$_.type -eq 'Custom_ID_Type_ID'}
        $o.Type = '{0}' -f $typeXml.'#text'
        $o.Id = $_.Custom_ID_Data.ID
        $o.Descriptor = $_.Custom_ID_Data.ID_Type_Reference.Descriptor
        $o.Issued_Date = try { Get-Date $_.Custom_ID_Data.Issued_Date -ErrorAction Stop } catch {}
        $o.Expiration_Date = try { Get-Date $_.Custom_ID_Data.Expiration_Date -ErrorAction Stop } catch {}
        $o.WID = $_.Custom_ID_Shared_Reference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty '#text'
        Write-Output $o
    }

}
#EndRegion '.\Public\Get-WorkdayWorkerOtherId.ps1' 94
#Region '.\Public\Get-WorkdayWorkerPhone.ps1' 0
function Get-WorkdayWorkerPhone {
<#
.SYNOPSIS
    Returns a Worker's phone numbers.

.DESCRIPTION
    Returns a Worker's phone numbers as custom Powershell objects.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

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

Get-WorkdayWorkerPhone -WorkerId 123

Type          Number            Primary Public
----          ------            ------- ------
Home/Cell     +1  5551234567       True   True
Work/Landline +1 (555) 765-4321    True   True

#>

	[CmdletBinding(DefaultParametersetName='Search')]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true,
            Position=0,
            ParameterSetName='Search')]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
        [Parameter(ParameterSetName="Search")]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
        [Parameter(ParameterSetName='Search')]
		[string]$Human_ResourcesUri,
        [Parameter(ParameterSetName='Search')]
		[string]$Username,
        [Parameter(ParameterSetName='Search')]
		[string]$Password,
        [Parameter(ParameterSetName='NoSearch')]
        [xml]$WorkerXml,
        [Alias("Force")]
        [switch]$IncludeInactive
	)

    if ($PsCmdlet.ParameterSetName -eq 'Search') {
        if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }
        $response = Get-WorkdayWorker -WorkerId $WorkerId -WorkerType $WorkerType -IncludePersonal -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive -ErrorAction Stop
        $WorkerXml = $response.Xml
    }

    if ($WorkerXml -eq $null) {
        Write-Warning 'Worker not found.'
        return
    }

    $numberTemplate = [pscustomobject][ordered]@{
        UsageType = $null
        DeviceType = $null
        Number  = $null
        Extension = $null
        Primary = $null
        Public  = $null
    }

    $WorkerXml.GetElementsByTagName('wd:Phone_Data') | ForEach-Object {
        $o = $numberTemplate.PsObject.Copy()
        $o.UsageType = $_.SelectSingleNode('wd:Usage_Data/wd:Type_Data/wd:Type_Reference/wd:ID[@wd:type="Communication_Usage_Type_ID"]', $NM).InnerText
        $o.DeviceType = $_.SelectSingleNode('wd:Phone_Device_Type_Reference/wd:ID[@wd:type="Phone_Device_Type_ID"]', $NM).InnerText
        $international = $_ | Select-Object -ExpandProperty 'International_Phone_Code' -ErrorAction SilentlyContinue
        $areaCode = $_ | Select-Object -ExpandProperty 'Area_Code' -ErrorAction SilentlyContinue
        $phoneNumber = $_ | Select-Object -ExpandProperty 'Phone_Number' -ErrorAction SilentlyContinue

        $o.Number = '{0} ({1}) {2}' -f $international, $areaCode, $phoneNumber
        $o.Extension = $_ | Select-Object -ExpandProperty 'Phone_Extension' -ErrorAction SilentlyContinue
        $o.Primary = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Type_Data.Primary )
        $o.Public = [System.Xml.XmlConvert]::ToBoolean( $_.Usage_Data.Public )
        Write-Output $o
    }
}
#EndRegion '.\Public\Get-WorkdayWorkerPhone.ps1' 96
#Region '.\Public\Invoke-WorkdayRequest.ps1' 0
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

	Write-Debug "Request: `n`r $(Format-XML -Text $($WorkdaySoapEnvelope.OuterXml))"
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
		$response = Invoke-RestMethod -Method Post -Uri $Uri -Headers $headers -Body $WorkdaySoapEnvelope
        $o.Xml = [xml]$response.Envelope.Body.InnerXml
        $o.Message = ''
        $o.Success = $true
	}
	catch [System.Net.WebException] {
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
    catch {
        $o.Success = $false
        $o.Message = $_.ToString()
    }
    finally {
        Write-Output $o
    }
}
#EndRegion '.\Public\Invoke-WorkdayRequest.ps1' 128
#Region '.\Public\Remove-WorkdayConfiguration.ps1' 0
function Remove-WorkdayConfiguration {
<#
.SYNOPSIS
    Removes Workday configuration file from the current user's Profile.

.DESCRIPTION
    Removes Workday configuration file from the current user's Profile.

.EXAMPLE
    Remove-WorkdayConfiguration

#>

    [CmdletBinding()]
    param ()

    if (Test-Path -Path $WorkdayConfigurationFile) {
        Remove-Item -Path $WorkdayConfigurationFile
    }
}
#EndRegion '.\Public\Remove-WorkdayConfiguration.ps1' 20
#Region '.\Public\Remove-WorkdayWorkerOtherId.ps1' 0
function Remove-WorkdayWorkerOtherId {
<#
.SYNOPSIS
    Sets the Custom_ID_Type_ID "Badge_ID".
#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
		[Parameter(Mandatory = $true)]
        [ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WID,
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    $request = [xml]@'
<bsvc:Change_Other_IDs_Request bsvc:version="v28.2" xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Business_Process_Parameters>
    <bsvc:Auto_Complete>true</bsvc:Auto_Complete>
    <bsvc:Run_Now>true</bsvc:Run_Now>
    <bsvc:Comment_Data>
      <bsvc:Comment>Other ID set by Set-WorkdayWorkerOtherId</bsvc:Comment>
    </bsvc:Comment_Data>
  </bsvc:Business_Process_Parameters>

  <bsvc:Change_Other_IDs_Data>
    <bsvc:Worker_Reference>
      <bsvc:ID bsvc:type="Employee_ID">Employee_ID</bsvc:ID>
    </bsvc:Worker_Reference>
    <bsvc:Custom_Identification_Data bsvc:Replace_All="false">
      <bsvc:Custom_ID bsvc:Delete="true">
        <bsvc:Custom_ID_Shared_Reference>
          <bsvc:ID bsvc:type="WID">wid</bsvc:ID>
        </bsvc:Custom_ID_Shared_Reference>
      </bsvc:Custom_ID>
    </bsvc:Custom_Identification_Data>

  </bsvc:Change_Other_IDs_Data>
</bsvc:Change_Other_IDs_Request>
'@

    
    $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Worker_Reference.ID.InnerText = $WorkerId
    if ($WorkerType -eq 'Contingent_Worker_ID') {
        $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Worker_Reference.ID.type = 'Contingent_Worker_ID'
    } elseif ($WorkerType -eq 'WID') {
        $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Worker_Reference.ID.type = 'WID'
    }
    
    $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Custom_Identification_Data.Custom_ID.Custom_ID_Shared_Reference.ID.InnerText = $WID

    Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password | Write-Output
}
#EndRegion '.\Public\Remove-WorkdayWorkerOtherId.ps1' 62
#Region '.\Public\Save-WorkdayConfiguration.ps1' 0
function Save-WorkdayConfiguration {
<#
.SYNOPSIS
    Saves default Workday configuration to a file in the current users Profile.

.DESCRIPTION
    Saves default Workday configuration to a file within the current
    users Profile. If it exists, this file is then read, each time the
    Workday Module is imported. Allowing settings to persist between
    sessions.

.EXAMPLE
    Save-WorkdayConfiguration

#>

    [CmdletBinding()]
    param ()

    Export-Clixml -Path $WorkdayConfigurationFile -InputObject $WorkdayConfiguration
}
#EndRegion '.\Public\Save-WorkdayConfiguration.ps1' 21
#Region '.\Public\Set-WorkdayCredential.ps1' 0
function Set-WorkdayCredential {
<#
.SYNOPSIS
    Sets the default Workday API credentials.

.DESCRIPTION
    Sets the default Workday API credentials. Configuration values can
    be securely saved to a user's profile using Save-WorkdayConfiguration.

.PARAMETER Credential
    A standard Powershell Credential object. Optional.
    
.EXAMPLE
    Set-WorkdayCredential

    This will prompt the user for credentials and save them in memory.

.EXAMPLE
    $cred = Get-Credential -Message 'Custom message...' -UserName 'Custom Username'
    Set-WorkdayCredential -Credential $cred

    This demonstrates prompting the user with a custom message and default username.

#>

    [CmdletBinding()]
    param (
        [PSCredential]$Credential = $(Get-Credential -Message 'Enter Workday API credentials.')
    )

    $WorkdayConfiguration.Credential = $Credential
}

#EndRegion '.\Public\Set-WorkdayCredential.ps1' 33
#Region '.\Public\Set-WorkdayEndpoint.ps1' 0
function Set-WorkdayEndpoint {
<#
.SYNOPSIS
    Sets the default Uri value for a particular Endpoint.

.DESCRIPTION
    Sets the default Uri value for a particular Endpoint. These values
    can be saved to a user's profile using Save-WorkdayConfiguration.

.PARAMETER Endpoint
    The curent Endpoints used by this module are:
    'Human_Resources', 'Staffing'

.PARAMETER Uri
    Uri for this Endpoint.

.EXAMPLE
    
Set-WorkdayEndpoint -Endpoint Staffing -Uri 'https://SERVICE.workday.com/ccx/service/TENANT/Staffing/v26.0'

    Demonstrates how to set a single Endpoint value.

.EXAMPLE

ConvertFrom-Csv @'
Endpoint,Uri
Staffing,https://SERVICE.workday.com/ccx/service/TENANT/Staffing/v26.0
Human_Resources,https://SERVICE.workday.com/ccx/service/TENANT/Human_Resources/v26.0
Integrations,https://SERVICE.workday.com/ccx/service/TENANT/Integrations/v26.0
'@ | Set-WorkdayEndpoint

    Demonstrates how it would be possible to import a CSV file to set these values.
    This will be more important when there are more Endpoints supported.

#>

    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('Human_Resources', 'Integrations', 'Staffing')]
        [string]$Endpoint,
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string]$Uri
    )

    process {
        $WorkdayConfiguration.Endpoints[$Endpoint] = $Uri
    }
}
#EndRegion '.\Public\Set-WorkdayEndpoint.ps1' 51
#Region '.\Public\Set-WorkdayWorkerDocument.ps1' 0
function Set-WorkdayWorkerDocument {
<#
.SYNOPSIS
    Uploads a document to a Worker's records in Workday.

.DESCRIPTION
    Uploads a document to a Worker's records in Workday.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

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
    
Set-WorkdayWorkerDocument -WorkerId 123 -Path Document.pdf

#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
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
<bsvc:Put_Worker_Document_Request bsvc:version="v30.0" bsvc:Add_Only="false" xmlns:bsvc="urn:com.workday/bsvc">
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
    } elseif ($WorkerType -eq 'WID') {
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
#EndRegion '.\Public\Set-WorkdayWorkerDocument.ps1' 101
#Region '.\Public\Set-WorkdayWorkerEmail.ps1' 0
function Set-WorkdayWorkerEmail {
	<#
	.SYNOPSIS
		Sets a Worker's email in Workday.
	
	.DESCRIPTION
		Sets a Worker's email in Workday.
	
	.PARAMETER WorkerId
		The Worker's Id at Workday.
	
	.PARAMETER WorkerType
		The type of ID that the WorkerId represents. Valid values
		are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.
	
	.PARAMETER Email
		Email address.
	
	.PARAMETER UsageType
		Currently supports HOME and WORK.
	
	.PARAMETER Secondary
		By default, this will set one non-Primary email address of the same UsageType. To set more than one, use the -Append switch. At some point this command may need to allow specifying a specific email WID to update.
	
	.PARAMETER Append
		When used with the Secondary switch, this will add the specified Email as a non-Primary email of the same UsageType.
	
	.PARAMETER Private
		Marks the email as not Public in Workday.
	
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
		
	Set-WorkdayWorkerEmail -WorkerId 123 -WorkEmail worker@example.com
	
	.NOTES
		When setting a primary email, by default, Workday deletes ALL non-primary addresses of the same type.
		When using Do_Not_Replace_All="true", Workday will append non-primary addresses, rather than update a current address.
		For this behavior, use the -Append switch, with the -Secondary switch.
		Otherwise use the -Secondary switch.
	
	#>
	
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true,
				Position=0)]
			[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
			[string]$WorkerId,
			[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
			[string]$WorkerType = 'Employee_ID',
			[Parameter(Mandatory = $true)]
			[ValidatePattern('^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$')]
			[Alias('EmailAddress')]
			[string]$Email,
			[ValidateSet('HOME','WORK')]
			[string]$UsageType = 'WORK',
			[switch]$Private,
			[switch]$Secondary,
			[switch]$Append,
			[string]$Human_ResourcesUri,
			[string]$Username,
			[string]$Password
		)
	
		if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }
	
		$request = [xml]@'
	<bsvc:Maintain_Contact_Information_for_Person_Event_Request bsvc:version="v30.0" bsvc:Add_Only="false" xmlns:bsvc="urn:com.workday/bsvc">
		<bsvc:Business_Process_Parameters>
			<bsvc:Auto_Complete>true</bsvc:Auto_Complete>
			<bsvc:Run_Now>true</bsvc:Run_Now>
			<bsvc:Comment_Data>
				<bsvc:Comment>Email set by Set-WorkdayWorkerEmail</bsvc:Comment>
			</bsvc:Comment_Data>
		</bsvc:Business_Process_Parameters>
		<bsvc:Maintain_Contact_Information_Data>
			<bsvc:Worker_Reference>
				<bsvc:ID bsvc:type="Employee_ID">Employee_ID</bsvc:ID>
			</bsvc:Worker_Reference>
			<bsvc:Effective_Date>Effective_Date</bsvc:Effective_Date>
			<bsvc:Worker_Contact_Information_Data>
				<bsvc:Email_Address_Data bsvc:Do_Not_Replace_All="true">
					<bsvc:Email_Address>Email_Address</bsvc:Email_Address>
					<bsvc:Usage_Data bsvc:Public="true">
						<bsvc:Type_Data bsvc:Primary="true">
						<bsvc:Type_Reference>
							<bsvc:ID bsvc:type="Communication_Usage_Type_ID">WORK</bsvc:ID>
						</bsvc:Type_Reference>
						</bsvc:Type_Data>
					</bsvc:Usage_Data>
				</bsvc:Email_Address_Data>
			</bsvc:Worker_Contact_Information_Data>
		</bsvc:Maintain_Contact_Information_Data>
	</bsvc:Maintain_Contact_Information_for_Person_Event_Request>
'@
	
		$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Reference.ID.InnerText = $WorkerId
		if ($WorkerType -eq 'Contingent_Worker_ID') {
			$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Reference.ID.type = 'Contingent_Worker_ID'
		} elseif ($WorkerType -eq 'WID') {
			$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Reference.ID.type = 'WID'
		}
	
		$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Email_Address_Data.Email_Address = $Email
		$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Effective_Date = (Get-Date).ToString( 'yyyy-MM-dd' )
		$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Email_Address_Data.Usage_Data.Type_Data.Type_Reference.ID.'#text' = $UsageType
	
		if ($Secondary) {
			$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Email_Address_Data.Usage_Data.Type_Data.Primary = 'false'
			if (-not $Append) {
				$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Email_Address_Data.Do_Not_Replace_All = 'false'
			}
		}
	
		if ($Private) {
			$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Email_Address_Data.Usage_Data.Public = 'false'
		}
	
		Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password | Write-Output
	
	}
#EndRegion '.\Public\Set-WorkdayWorkerEmail.ps1' 133
#Region '.\Public\Set-WorkdayWorkerOtherId.ps1' 0
function Set-WorkdayWorkerOtherId {
<#
.SYNOPSIS
    Sets the Custom_ID_Type_ID "Badge_ID".
#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
		[Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
		[string]$Type,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Id,
    [ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		$WID,
    $IssuedDate,
    $ExpirationDate,
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    $request = [xml]@'
<bsvc:Change_Other_IDs_Request bsvc:version="v28.2" xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Business_Process_Parameters>
    <bsvc:Auto_Complete>true</bsvc:Auto_Complete>
    <bsvc:Run_Now>true</bsvc:Run_Now>
    <bsvc:Comment_Data>
      <bsvc:Comment>Other ID set by Set-WorkdayWorkerOtherId</bsvc:Comment>
    </bsvc:Comment_Data>
  </bsvc:Business_Process_Parameters>

  <bsvc:Change_Other_IDs_Data>
    <bsvc:Worker_Reference>
      <bsvc:ID bsvc:type="Employee_ID">Employee_ID</bsvc:ID>
    </bsvc:Worker_Reference>
    <bsvc:Custom_Identification_Data bsvc:Replace_All="false">
      <bsvc:Custom_ID bsvc:Delete="false">
        <bsvc:Custom_ID_Data>
          <bsvc:ID>string</bsvc:ID>
          <bsvc:ID_Type_Reference>
            <bsvc:ID bsvc:type="Custom_ID_Type_ID">Type</bsvc:ID>
          </bsvc:ID_Type_Reference>
          <bsvc:Issued_Date></bsvc:Issued_Date>
          <bsvc:Expiration_Date></bsvc:Expiration_Date>
        </bsvc:Custom_ID_Data>
        <bsvc:Custom_ID_Shared_Reference>
          <bsvc:ID bsvc:type="WID">wid</bsvc:ID>
        </bsvc:Custom_ID_Shared_Reference>
      </bsvc:Custom_ID>
    </bsvc:Custom_Identification_Data>

  </bsvc:Change_Other_IDs_Data>
</bsvc:Change_Other_IDs_Request>
'@

    
    $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Worker_Reference.ID.InnerText = $WorkerId
    if ($WorkerType -eq 'Contingent_Worker_ID') {
        $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Worker_Reference.ID.type = 'Contingent_Worker_ID'
    } elseif ($WorkerType -eq 'WID') {
        $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Worker_Reference.ID.type = 'WID'
    }
    
    $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Custom_Identification_Data.Custom_ID.Custom_ID_Data.ID_Type_Reference.ID.InnerText = $Type
    $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Custom_Identification_Data.Custom_ID.Custom_ID_Data.ID = $Id

  # Deal with the potential for blank or invalid incoming or current date values.
  if (-not [string]::IsNullOrWhiteSpace($IssuedDate)) {
    try {
      $d = Get-Date $IssuedDate -ErrorAction Stop
      $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Custom_Identification_Data.Custom_ID.Custom_ID_Data.Issued_Date = $d.ToString('o')
    }
    catch {
      throw "Invalid IssuedDate [$IssuedDate]"
    }
  }
  if (-not [string]::IsNullOrWhiteSpace($ExpirationDate)) {
    try {
      $d = Get-Date $ExpirationDate -ErrorAction Stop
      $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Custom_Identification_Data.Custom_ID.Custom_ID_Data.Expiration_Date = $d.ToString('o')
    }
    catch {
      throw "Invalid ExpirationDate [$ExpirationDate]"
    }
  }

  if ($PSBoundParameters.ContainsKey('WID')) {
    $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Custom_Identification_Data.Custom_ID.Custom_ID_Shared_Reference.ID.InnerText = $WID
  }
  else {
    $null = $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Custom_Identification_Data.Custom_ID.RemoveChild($request.Change_Other_IDs_Request.Change_Other_IDs_Data.Custom_Identification_Data.Custom_ID.Custom_ID_Shared_Reference)
  }

	Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password | Write-Output
}
#EndRegion '.\Public\Set-WorkdayWorkerOtherId.ps1' 105
#Region '.\Public\Set-WorkdayWorkerPhone.ps1' 0
function Set-WorkdayWorkerPhone {
<#
.SYNOPSIS
    Sets a Worker's phone number in Workday.

.DESCRIPTION
    Sets a Worker's phone number in Workday.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

.PARAMETER Number
    Sets the Workday primary Work Landline for a Worker. This cmdlet does not
    currently support other phone types. Also excepts the alias OfficePhone.

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

Set-WorkdayWorkerPhone -WorkerId 123 -Number 1234567890

#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
        [string]$WorkerId,
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Number,
		[string]$Extension,
		[ValidateSet('HOME','WORK')]
        [string]$UsageType = 'WORK',
		[ValidateSet('Landline','Cell')]
        [string]$DeviceType = 'Landline',
        [switch]$Private,
        [switch]$Secondary,
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }


	$request = [xml]@'
<bsvc:Maintain_Contact_Information_for_Person_Event_Request bsvc:version="v30.0" bsvc:Add_Only="false" xmlns:bsvc="urn:com.workday/bsvc">
	<bsvc:Business_Process_Parameters>
		<bsvc:Auto_Complete>true</bsvc:Auto_Complete>
		<bsvc:Run_Now>true</bsvc:Run_Now>
		<bsvc:Comment_Data>
			<bsvc:Comment>Phone number set by Set-WorkdayWorkerPhone</bsvc:Comment>
		</bsvc:Comment_Data>
	</bsvc:Business_Process_Parameters>
    <bsvc:Maintain_Contact_Information_Data>
		<bsvc:Worker_Reference>
			<bsvc:ID bsvc:type="Employee_ID">Employee_ID?</bsvc:ID>
		</bsvc:Worker_Reference>
		<bsvc:Effective_Date>Effective_Date?</bsvc:Effective_Date>
		<bsvc:Worker_Contact_Information_Data>
			<bsvc:Phone_Data>
				<bsvc:International_Phone_Code>1</bsvc:International_Phone_Code>
				<bsvc:Area_Code>?</bsvc:Area_Code>
                <bsvc:Phone_Number>?</bsvc:Phone_Number>
				<bsvc:Phone_Extension>?</bsvc:Phone_Extension>
				<bsvc:Phone_Device_Type_Reference>
					<bsvc:ID bsvc:type="Phone_Device_Type_ID">Landline?</bsvc:ID>
				</bsvc:Phone_Device_Type_Reference>
				<bsvc:Usage_Data bsvc:Public="1">
					<bsvc:Type_Data bsvc:Primary="1">
						<bsvc:Type_Reference>
							<bsvc:ID bsvc:type="Communication_Usage_Type_ID">WORK?</bsvc:ID>
						</bsvc:Type_Reference>
					</bsvc:Type_Data>
				</bsvc:Usage_Data>
			</bsvc:Phone_Data>
		</bsvc:Worker_Contact_Information_Data>
    </bsvc:Maintain_Contact_Information_Data>
</bsvc:Maintain_Contact_Information_for_Person_Event_Request>
'@

    $request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Reference.ID.InnerText = $WorkerId
    if ($WorkerType -eq 'Contingent_Worker_ID') {
        $request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Reference.ID.type = 'Contingent_Worker_ID'
    } elseif ($WorkerType -eq 'WID') {
        $request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Reference.ID.type = 'WID'
    }

	$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Effective_Date = (Get-Date).ToString( 'yyyy-MM-dd' )

    $scrubbedNumber = $Number -replace '[^\d]', ''
    if ($scrubbedNumber -notmatch '(?<country>[\d]*?)(?<areacode>\d{0,3}?)(?<prefix>\d{0,3}?)(?<line>\d{1,4})$') {
        throw "Invalid number: [$Number]"
    }

	$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Phone_Data.Phone_Device_Type_Reference.ID.'#text' =
	 $DeviceType
	$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Phone_Data.Usage_Data.Type_Data.Type_Reference.ID.'#text' =
	 $UsageType

	if ($Private) {
		$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Phone_Data.Usage_Data.Public = '0'
	}

	if ($Secondary) {
		$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Phone_Data.Usage_Data.Type_Data.Primary = '0'
	}

	$country = if ([string]::IsNullOrWhiteSpace($Matches['country'])) {'1'} else { $Matches['country'] }
	$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Phone_Data.International_Phone_Code =
	 $country
	$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Phone_Data.Area_Code =
	 $Matches['areacode']

    $phoneNumber = ''
    if ($Matches['prefix'].length -gt 0) {
        $phoneNumber = $Matches['prefix'] + '-'
    }
    $phoneNumber += $Matches['line']
	$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Phone_Data.Phone_Number = $phoneNumber

	$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Phone_Data.Phone_Extension =
	 $Extension

	Write-Debug "Request: `n`r $(Format-XML -Text $request.OuterXml)"
    Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password | Write-Output
}
#EndRegion '.\Public\Set-WorkdayWorkerPhone.ps1' 145
#Region '.\Public\Set-WorkdayWorkerPhoto.ps1' 0
function Set-WorkdayWorkerPhoto {
<#
.SYNOPSIS
    Uploads an image file to Workday and set it as a Worker's photo.

.DESCRIPTION
    Uploads an image file to Workday and set it as a Worker's photo.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

.PARAMETER Path
    The Path to the image file to upload.

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
    
Set-WorkdayWorkerPhoto -EmpoyeeId 123 -Path Photo.jpg

#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
		[Parameter(Mandatory = $true)]
		[ValidateScript({Test-Path $_ -PathType Leaf})]
		[ValidateNotNullOrEmpty()]
        [string]$Path,
        [string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

	$request = [xml]@'
<bsvc:Put_Worker_Photo_Request bsvc:version="v30.1" xmlns:bsvc="urn:com.workday/bsvc">
    <bsvc:Worker_Reference>
        <bsvc:ID bsvc:type="Employee_ID">employeeId</bsvc:ID>
    </bsvc:Worker_Reference>
    <bsvc:Worker_Photo_Data>
        <bsvc:Filename>filename</bsvc:Filename>
        <bsvc:File>base64</bsvc:File>
    </bsvc:Worker_Photo_Data>
</bsvc:Put_Worker_Photo_Request>
'@

    $request.Put_Worker_Photo_Request.Worker_Reference.ID.InnerText = $WorkerId
    if ($WorkerType -eq 'Contingent_Worker_ID') {
        $request.Put_Worker_Photo_Request.Worker_Reference.ID.type = 'Contingent_Worker_ID'
    } elseif ($WorkerType -eq 'WID') {
        $request.Put_Worker_Photo_Request.Worker_Reference.ID.type = 'WID'
    }

	$request.Put_Worker_Photo_Request.Worker_Photo_Data.File = [System.Convert]::ToBase64String( [system.io.file]::ReadAllBytes( $Path ) )
	$request.Put_Worker_Photo_Request.Worker_Photo_Data.Filename = [string] (Split-Path -Path $Path -Leaf)

	Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password | Write-Output

}
#EndRegion '.\Public\Set-WorkdayWorkerPhoto.ps1' 80
#Region '.\Public\Start-WorkdayIntegration.ps1' 0
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
#EndRegion '.\Public\Start-WorkdayIntegration.ps1' 115
#Region '.\Public\Update-WorkdayWorkerEmail.ps1' 0
function Update-WorkdayWorkerEmail {
<#
.SYNOPSIS
    Updates a Worker's email in Workday, only if it is different.

.DESCRIPTION
    Updates a Worker's email in Workday, only if it is different.
    Change requests are always recorded in Workday's audit log even when
    the email is the same. Unlike Set-WorkdayWorkerEmail, this cmdlet
    first checks the current email before requesting a change.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

.PARAMETER Email
    Sets the Workday primary, public, Work email for a Worker. This cmdlet does not
    currently support other email types. Also excepts the alias EmailAddress.

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

Update-WorkdayWorkerEmail -WorkerId 123 -Email test@example.com

.NOTES
    The Set-WorkdayWorkerEmail switch -Append is not supported, as the -Secondary
    switch assumes there is only one non-primary email address. At some point
    it may be nessesary to implement a means to update a specific email WID.

#>

	[CmdletBinding(DefaultParametersetName='Search')]
	param (
		[Parameter(Mandatory = $true,
            ParameterSetName="Search",
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
        [Parameter(ParameterSetName="Search")]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
        [Parameter(ParameterSetName="Search")]
		[string]$Human_ResourcesUri,
        [Parameter(ParameterSetName="Search")]
		[string]$Username,
        [Parameter(ParameterSetName="Search")]
		[string]$Password,
        [Parameter(Mandatory = $true,
            ParameterSetName="NoSearch")]
        [xml]$WorkerXml,
        [Parameter(Mandatory = $true)]
        [Alias('EmailAddress')]
		[string]$Email,
		[ValidateSet('HOME','WORK')]
        [string]$UsageType = 'WORK',
        [switch]$Private,
        [switch]$Secondary,
        [Alias("Force")]
        [switch]$IncludeInactive
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'NoSearch') {
        $current = Get-WorkdayWorkerEmail -WorkerXml $WorkerXml
        $WorkerType = 'WID'
        $workerReference = $WorkerXml.GetElementsByTagName('wd:Worker_Reference') | Select-Object -First 1
        $WorkerId = $workerReference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty InnerText
    } else {
        $current = Get-WorkdayWorkerEmail -WorkerId $WorkerId -WorkerType $WorkerType -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive
    }

    $currentEmail = $current |
        Where-Object {
            $_.UsageType -eq $UsageType -and
            (-not $_.Primary) -eq $Secondary
        } | Select-Object -First 1

    $msg = "{0} Current [$($currentEmail.Email)] Proposed [$Email]"
    $output = [pscustomobject][ordered]@{
        WorkerId = $WorkerId
        WorkerType = $WorkerType
        Email = $Email
        UsageType = $UsageType
        Primary = -not $Secondary
        Public = -not $Private
        Success = $false
        Message = $msg -f 'Failed'
    }
    if (
        $currentEmail -ne $null -and
        $currentEmail.Email -eq $Email -and
        $currentEmail.UsageType -eq $UsageType -and
        (-not $currentEmail.Primary) -eq $Secondary -and
        (-not $currentEmail.Public) -eq $Private
    ) {
        $output.Message = $msg -f 'Matched'
        $output.Success = $true
    } else {
        $o = Set-WorkdayWorkerEmail -WorkerId $WorkerId -WorkerType $WorkerType -Email $Email -UsageType:$UsageType -Private:$Private -Secondary:$Secondary -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password
        if ($o -ne $null) {
            if ($o.Success) {
                $output.Success = $true
                $output.Message = $msg -f 'Changed'
            }
            else {
                $output.Success = $false
                $output.Message = $o.Message
            }
        }
    }

    Write-Verbose $output.Message
    Write-Output $output
}
#EndRegion '.\Public\Update-WorkdayWorkerEmail.ps1' 129
#Region '.\Public\Update-WorkdayWorkerOtherId.ps1' 0
function Update-WorkdayWorkerOtherId {
<#
.SYNOPSIS
    Updates a Worker's Other ID data in Workday, only if it is different.

.DESCRIPTION
    Updates a Worker's Other ID data in Workday, only if it is different.
    Change requests are always recorded in Workday's audit log even when
    the values are the same. Unlike Set-WorkdayWorkerOtherId, this cmdlet
    first checks the current value before requesting a change.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

.PARAMETER Human_ResourcesUri
    Human_Resources Endpoint Uri for the request. If not provided, the value
    stored with Set-WorkdayEndpoint -Endpoint Human_Resources is used.


.PARAMETER Username
    Username used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.PARAMETER Password
    Password used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
            ParameterSetName="Search",
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
        [Parameter(ParameterSetName="Search")]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
        [Parameter(ParameterSetName="Search")]
		[string]$Human_ResourcesUri,
        [Parameter(ParameterSetName="Search")]
		[string]$Username,
        [Parameter(ParameterSetName="Search")]
		[string]$Password,
        [Parameter(Mandatory = $true,
            ParameterSetName="NoSearch")]
        [xml]$WorkerXml,
		[Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[string]$Type,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Id,
        [ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		$WID,
        $IssuedDate,
        $ExpirationDate,
        [switch]$WhatIf,
        [Alias("Force")]
        [switch]$IncludeInactive
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'NoSearch') {
        $otherIds = Get-WorkdayWorkerOtherId -WorkerXml $WorkerXml
        $WorkerType = 'WID'
        $workerReference = $WorkerXml.GetElementsByTagName('wd:Worker_Reference') | Select-Object -First 1
        $WorkerId = $workerReference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty InnerText
    } else {
        $otherIds = Get-WorkdayWorkerOtherId -WorkerId $WorkerId -WorkerType $WorkerType -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive
    }

    Write-Debug "OtherIds: $otherIds"

    $current = $otherIds | Where-Object {$PSBoundParameters.ContainsKey('WID') -and $_.WID -eq $WID} | Select-Object -First 1
    # Default to the first of the requsted type.
    if ($current -eq $null) {
        $current = $otherIds | Where-Object {$_.Type -eq $Type} | Select-Object -First 1
    }

    $currentIdDisplay = $null
    $issuedCurrentDisplay = $null
    $expirationCurrentDisplay = $null
    $issuedProposedDisplay = $IssuedDate
    $expirationProposedDisplay = $ExpirationDate
    # Defaults to not matching.
    $idMatched = $false
    $issuedDateMatched = $false
    $expirationDateMatched = $false
    # Throw an error for an invalid date, default to the current value when no date is specified.
    if ($IssuedDate -ne $null) {
        try {
            $d = Get-Date $IssuedDate -ErrorAction Stop
            $IssuedDate = $d
            $issuedProposedDisplay = $IssuedDate.ToString('g')
        }
        catch {
            throw "Invalid IssuedDate [$IssuedDate]"
        }
    } else {
        $issuedProposedDisplay = 'current IssuedDate'
    }

    if ($ExpirationDate -ne $null) {
        try {
            $d = Get-Date $ExpirationDate -ErrorAction Stop
            $ExpirationDate = $d
            $expirationProposedDisplay = $ExpirationDate.ToString('g')
        }
        catch {
            throw "Invalid ExpirationDate [$ExpirationDate]"
        }
    } else {
        $expirationProposedDisplay = 'current ExpirationDate'
    }

    if ($current -ne $null) {
        Write-Debug "Current: $current"
        $currentIdDisplay = $current.Id
        $idMatched = $current.Id -eq $Id
        $WID = $current.Wid
        $issuedCurrentDisplay = if ($current.Issued_Date -is [DateTime]) { $current.Issued_Date.ToString('g') }
        $expirationCurrentDisplay = if ($current.Expiration_Date -is [DateTime]) { $current.Expiration_Date.ToString('g') }

        # Is a date change requested?
        if ($IssuedDate -is [datetime]) {
            $issuedProposedDisplay = $IssuedDate.ToString('g')
            # Is there a date to compare?
            if ($current.Issued_Date -is [datetime]) {
                # Do the dates match?
                $IssuedDateMatched = ($current.Issued_Date - $IssuedDate).Days -eq 0
            }
        }
        else {
            $IssuedDateMatched = $true
        }

        # Is a date change requested?
        if ($ExpirationDate -is [datetime]) {
            $expirationProposedDisplay = $ExpirationDate.ToString('g')
            # Is there a date to compare?
            if ($current.Expiration_Date -is [datetime]) {
                # Do the dates match?
                $ExpirationDateMatched = ($current.Expiration_Date - $ExpirationDate).Days -eq 0
            }
        }
        else {
            $ExpirationDateMatched = $true
        }
    }

    $msg = '{{0}} Current [{0} valid from {1} to {2}] Proposed [{3} valid from {4} to {5}]' -f $currentIdDisplay, $issuedCurrentDisplay, $expirationCurrentDisplay, $Id, $issuedProposedDisplay, $expirationProposedDisplay

    Write-Debug "idMatched=$idMatched; issuedDateMatched=$issuedDateMatched; expirationDateMatched=$expirationDateMatched"
    
    $output = [pscustomobject][ordered]@{
        WorkerId = $WorkerId
        WorkerType = $WorkerType
        Type = $Type
		Id = $Id
        WID = $WID
        IssueDate = $IssuedDate
        ExpirationDate = $ExpirationDate
        Success = $false
        Message = $msg -f 'Failed'
    }

    if (
        $idMatched -and
        $issuedDateMatched -and
        $expirationDateMatched
    ) {
        $output.Message = $msg -f 'Matched'
        $output.Success = $true
    } elseif ($WhatIf) {
        $output.Success = $true
        $output.Message = $msg -f 'Would change'
    } else {
        $params = @{
            WorkerId = $WorkerId
            WorkerType = $WorkerType
            Type = $Type
            Id = $Id
        }
        if (-not [string]::IsNullOrWhiteSpace($WID)) {
            $params['WID'] = $WID
        }

        $o = Set-WorkdayWorkerOtherId @params -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password -IssuedDate:$IssuedDate -ExpirationDate:$ExpirationDate
        if ($null -ne $o) {
            if ($o.Success) {
                $output.Success = $true
                $output.Message = $msg -f 'Changed'
            }
            else {
                $output.Success = $false
                $output.Message = $o.Message
            }
        }
    }

    Write-Verbose $output.Message
    Write-Output $output
}
#EndRegion '.\Public\Update-WorkdayWorkerOtherId.ps1' 210
#Region '.\Public\Update-WorkdayWorkerPhone.ps1' 0
function Update-WorkdayWorkerPhone {
<#
.SYNOPSIS
    Updates a Worker's phone number in Workday, only if it is different.

.DESCRIPTION
    Updates a Worker's phone number in Workday, only if it is different.
    Change requests are always recorded in Workday's audit log even when
    the number is the same. Unlike Set-WorkdayWorkerPhone, this cmdlet
    first checks the current phone number before requesting a change.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

.PARAMETER WorkPhone
    Sets the Workday primary Work Landline for a Worker. This cmdlet does not
    currently support other phone types. Also excepts the alias OfficePhone.

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

Update-WorkdayWorkerPhone -WorkerId 123 -Number 1234567890

#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
            ParameterSetName="Search",
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
        [Parameter(ParameterSetName="Search")]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
        [Parameter(ParameterSetName="Search")]
		[string]$Human_ResourcesUri,
        [Parameter(ParameterSetName="Search")]
		[string]$Username,
        [Parameter(ParameterSetName="Search")]
		[string]$Password,
        [Parameter(Mandatory = $true,
            ParameterSetName="NoSearch")]
        [xml]$WorkerXml,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Number,
		[string]$Extension,
		[ValidateSet('HOME','WORK')]
        [string]$UsageType = 'WORK',
		[ValidateSet('Landline','Cell')]
        [string]$DeviceType = 'Landline',
        [switch]$Private,
        [switch]$Secondary,
        [Alias("Force")]
        [switch]$IncludeInactive
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'NoSearch') {
        $current = Get-WorkdayWorkerPhone -WorkerXml $WorkerXml
        $WorkerType = 'WID'
        $workerReference = $WorkerXml.GetElementsByTagName('wd:Worker_Reference') | Select-Object -First 1
        $WorkerId = $workerReference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty InnerText
    } else {
        $current = Get-WorkdayWorkerPhone -WorkerId $WorkerId -WorkerType $WorkerType -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive
    }

    function scrub ([string]$PhoneNumber) { $PhoneNumber -replace '[^\d]','' }

    $scrubbedProposedNumber = scrub $Number
    $scrubbedProposedExtention = scrub $Extension
    $scrubbedCurrentNumber = $null
    $scrubbedCurrentExtension = $null
    $currentMatch = $current |
     Where-Object {
        $_.UsageType -eq $UsageType -and
        $_.DeviceType -eq $DeviceType -and
        (-not $_.Primary) -eq $Secondary
    } | Select-Object -First 1
    if ($currentMatch -ne $null) {
        $scrubbedCurrentNumber = scrub $currentMatch.Number
        $scrubbedCurrentExtension = scrub $currentMatch.Extension
    }

    $msg = "{0} Current [$scrubbedCurrentNumber] ext [$scrubbedCurrentExtension] Proposed [$scrubbedProposedNumber] ext [$scrubbedProposedExtention]"
    $output = [pscustomobject][ordered]@{
        WorkerId = $WorkerId
        WorkerType = $WorkerType
        Number = $Number
		Extension = $Extension
		UsageType = $UsageType
		DeviceType = $DeviceType
        Primary = -not $Secondary
        Public = -not $Private
        Success = $false
        Message = $msg -f 'Failed'
    }
    if (
        $currentMatch -ne $null -and
        $scrubbedCurrentNumber -eq $scrubbedProposedNumber -and
        $scrubbedCurrentExtension -eq $scrubbedProposedExtention -and
        (-not $currentMatch.Primary) -eq $Secondary -and
        (-not $currentMatch.Public) -eq $Private
    ) {
        $output.Message = $msg -f 'Matched'
        $output.Success = $true
    }
    else {
        $params = $PSBoundParameters
        $null = $params.Remove('WorkerXml')
        $null = $params.Remove('WorkerId')
        $null = $params.Remove('WorkerType')
        Write-Debug $params
        $o = Set-WorkdayWorkerPhone -WorkerId $WorkerId -WorkerType $WorkerType @params
        if ($o -ne $null) {
            if ($o.Success) {
                $output.Success = $true
                $output.Message = $msg -f 'Changed'
            }
            else {
                $output.Success = $false
                $output.Message = $o.Message
            }
        }
    }

    Write-Verbose $output.Message
    Write-Output $output
}
#EndRegion '.\Public\Update-WorkdayWorkerPhone.ps1' 147
