function Set-WorkdayWorkerPhoto {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$EmployeeId,
		[Parameter(Mandatory = $true)]
		[ValidateScript({Test-Path $_ -PathType Leaf})]
		[string]$PhotoPath,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Uri,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Username,
		[Parameter(Mandatory = $true)]
		[string]$Password
	)
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

	$request.Put_Worker_Photo_Request.Worker_Reference.ID.InnerText = $EmployeeId
	$request.Put_Worker_Photo_Request.Worker_Photo_Data.File = [System.Convert]::ToBase64String( [system.io.file]::ReadAllBytes( $PhotoPath ) )
	$request.Put_Worker_Photo_Request.Worker_Photo_Data.Filename = [string] (Split-Path -Path $PhotoPath -Leaf)

	Invoke-WorkdayApiRequest -Request $request -Uri $Uri -Username $Username -Password $Password | Write-Output
	}