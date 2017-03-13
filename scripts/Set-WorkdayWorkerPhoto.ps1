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
		[ValidateNotNullOrEmpty()]
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
<bsvc:Put_Worker_Photo_Request xmlns:bsvc="urn:com.workday/bsvc">
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