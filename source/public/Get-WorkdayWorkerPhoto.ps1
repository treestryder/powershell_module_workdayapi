function Get-WorkdayWorkerPhoto {
<#
.SYNOPSIS
    Gets Worker photo encoded as Base64 as Workday XML.

.DESCRIPTION
    Gets Worker photo information as Workday XML with photo bytes encoded as Base64.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

.PARAMETER Path
    Path to save the photo. If Path is to a directory, the file name from Workday will be appened.
    If no Path is specified, a PsCustomObject is returned containing the file name and byte array.

.PARAMETER Passthru
    Outputs Invoke-WorkdayRequest object, rather than a custom Worker object.
    If desired, the Base 64 encoded image and file name can be aquired from the XML.

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

# Get the Binary Array of a
$BinaryArray = Get-WorkdayWorkerPhoto -WorkerId 123

.EXAMPLE
#


#>


	[CmdletBinding()]
    [OutputType([PSCustomObject])]
	param (
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='IndividualWorker')]
		[ValidatePattern ('^$|^[a-zA-Z0-9\-]{1,32}$')]
        [string]$WorkerId,
        [Parameter(Position=1,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='IndividualWorker')]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
        [string]$WorkerType = 'Employee_ID',
        [string]$Path,
        [switch]$Passthru,
		[string]$Human_ResourcesUri,
		[string]$Username,
        [string]$Password,
        [DateTime]$AsOfEntryDateTime = (Get-Date)
	)

    begin {
        if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = Get-WorkdayEndpoint 'Human_Resources' }
    }

    process {
    	$request = [xml]@'
<bsvc:Get_Worker_Photos_Request bsvc:version="v30.0" xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false">
	<bsvc:Worker_Reference>
		<bsvc:ID bsvc:type="Employee_ID">?EmployeeId?</bsvc:ID>
	</bsvc:Worker_Reference>
  </bsvc:Request_References>
  <bsvc:Response_Filter>
    <bsvc:As_Of_Entry_DateTime>?DateTime?</bsvc:As_Of_Entry_DateTime>
  </bsvc:Response_Filter>
</bsvc:Get_Worker_Photos_Request>
'@

        $request.Get_Worker_Photos_Request.Response_Filter.As_Of_Entry_DateTime = $AsOfEntryDateTime.ToString('o')

        $request.Get_Worker_Photos_Request.Request_References.Worker_Reference.ID.InnerText = $WorkerId
        if ($WorkerType -eq 'Contingent_Worker_ID') {
            $request.Get_Worker_Photos_Request.Request_References.Worker_Reference.ID.type = 'Contingent_Worker_ID'
        } elseif ($WorkerType -eq 'WID') {
            $request.Get_Worker_Photos_Request.Request_References.Worker_Reference.ID.type = 'WID'
        }
        $response = Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password

        if ($Passthru) {
            Write-Output $response
        }
        elseif ($response.Success) {
            $filename = $response.Xml.Get_Worker_Photos_Response.Response_Data.Worker_Photo.Worker_Photo_Data.Filename
            $base64 = $response.Xml.Get_Worker_Photos_Response.Response_Data.Worker_Photo.Worker_Photo_Data.File
            $bytes = [System.Convert]::FromBase64String($base64)

            if ([string]::IsNullOrEmpty($Path)) {
                $output = [PsCustomObject][Ordered]@{
                    Filename = $filename
                    Bytes    = $bytes
                }
                Write-Output $output
            }
            else {
                if (Test-Path -Path $Path -PathType Container) {
                    $Path = Join-Path $Path $filename
                }
                $bytes | Set-Content -Path $Path -Encoding Byte
            }
        }
        else {
            throw "Error calling Get_Worker_Photos_Request: $($response.Message)"
        }
    }
}
