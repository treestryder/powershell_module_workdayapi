function Set-WorkdayWorkerUserId {
<#
.SYNOPSIS
    Sets a Worker's account user name in Workday.

.DESCRIPTION
    Sets a Worker's user name in Workday.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER UserId
	The Worker UserId to login into Workday.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'Contingent_Worker_ID' and 'Employee_ID'.

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

Set-WorkdayWorkerUserId -WorkerId 123 -UserId worker@example.com

.NOTES
	This changes the users login name for Workday

#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
            Position=0)]
		[ValidatePattern ('^[a-zA-Z0-9\-]{1,32}$')]
		[string]$WorkerId,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('')]
		[string]$UserId,
		[ValidateSet('Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

	$request = [xml]@'
<bsvc:Workday_Account_for_Worker_Update bsvc:version="v33.0" xmlns:bsvc="urn:com.workday/bsvc">	
	<bsvc:Worker_Reference>
		<bsvc:RefNode xmlns:bsvc="urn:com.workday/bsvc" />
	</bsvc:Worker_Reference>
    <bsvc:Workday_Account_for_Worker_Data>
		<bsvc:User_Name></bsvc:User_Name>
    </bsvc:Workday_Account_for_Worker_Data>
</bsvc:Workday_Account_for_Worker_Update>
'@
	$employeeref = [xml]@'
<bsvc:Employee_Reference xmlns:bsvc="urn:com.workday/bsvc">
	<bsvc:Integration_ID_Reference>
		<bsvc:ID bsvc:System_ID="WD-EMPLID"></bsvc:ID>
	</bsvc:Integration_ID_Reference>
</bsvc:Employee_Reference>
'@
	$contingentref = [xml]@'
<bsvc:Contingent_Worker_Reference xmlns:bsvc="urn:com.workday/bsvc">
	<bsvc:Integration_ID_Reference>
		<bsvc:ID bsvc:System_ID="WD-EMPLID"></bsvc:ID>
	</bsvc:Integration_ID_Reference>
</bsvc:Contingent_Worker_Reference>
'@		

	if ($WorkerType -eq 'Contingent_Worker_ID') {
		$contingentref.Contingent_Worker_Reference.Integration_ID_Reference.ID.InnerText = $WorkerId
		$request.Workday_Account_for_Worker_Update.Worker_Reference.InnerXml = $contingentref.OuterXml
	}
	else {
		$employeeref.Employee_Reference.Integration_ID_Reference.ID.InnerText = $WorkerId
		$request.Workday_Account_for_Worker_Update.Worker_Reference.InnerXml = $employeeref.OuterXml		
	}
	
	# Set Workday employee/congingent worker User ID
	$request.Workday_Account_for_Worker_Update.Workday_Account_for_Worker_Data.User_Name = $UserId
	
	Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password | Write-Output

}
