function Set-WorkdayWorkerUserName {
<#
.SYNOPSIS
    Sets a Worker's account user name in Workday.

.DESCRIPTION
    Sets a Worker's user name in Workday.

.PARAMETER WorkerId
    The Worker's Id at Workday.

.PARAMETER WorkerUserName
	The Worker UserName to login into Workday.

.PARAMETER WorkerType
	Currently supports Employee and Contingent.

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

Set-WorkdayWorkerUserName -WorkerId 123 -WorkerUserName worker@example.com

.NOTES
	This changes the users login name for Workday

#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
            Position=0)]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
		[Parameter(Mandatory = $true)]
		[ValidatePattern('^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$')] # Since the user name is email-id in this implementation
		[string]$WorkerUserName,
		[ValidateSet('Employee','Contingent')]
        [string]$WorkerType = 'Employee',
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

	if ($WorkerType -eq 'Employee') {
		$employeeref.Employee_Reference.Integration_ID_Reference.ID.InnerText = $WorkerId
		$request.Workday_Account_for_Worker_Update.Worker_Reference.InnerXml = $employeeref.OuterXml
	} elseif ($WorkerType -eq 'Contingent') {
		$contingentref.Contingent_Worker_Reference.Integration_ID_Reference.ID.InnerText = $WorkerId
		$request.Workday_Account_for_Worker_Update.Worker_Reference.InnerXml = $contingentref.OuterXml
	}
	
	# Set Workday employee/congingent worker UserName
	$request.Workday_Account_for_Worker_Update.Workday_Account_for_Worker_Data.User_Name = $WorkerUserName
	
	Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password | Write-Output

}
