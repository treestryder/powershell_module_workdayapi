<#
.SYNOPSIS
    Sets a Worker's email in Workday.

.DESCRIPTION
    Sets a Worker's email in Workday.

.PARAMETER EmployeeId
    The Worker's Employee Id at Workday. This cmdlet does not currently
    support Contengent Workers or referencing workers by WID.

.PARAMETER WorkEmail
    Sets the Workday primary Work email for a Worker. This cmdlet does not
    currently support other email types.

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
    
Set-WorkdayWorkerEmail -EmpoyeeId 123 -WorkEmail worker@example.com

#>


function Set-WorkdayWorkerEmail {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$EmployeeId,
		[Parameter(Mandatory = $true)]
		[ValidatePattern('^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$')]
		[string]$WorkEmail,
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password,
        [switch]$Passthru
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Uri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

	$request = [xml]@'
<bsvc:Maintain_Contact_Information_for_Person_Event_Request bsvc:Add_Only="false" xmlns:bsvc="urn:com.workday/bsvc">
	<bsvc:Business_Process_Parameters>
		<bsvc:Auto_Complete>true</bsvc:Auto_Complete>
		<bsvc:Run_Now>true</bsvc:Run_Now>
		<bsvc:Comment_Data>
			<bsvc:Comment>Work Email set by Set-WorkdayWorkerEmail</bsvc:Comment>
		</bsvc:Comment_Data>
	</bsvc:Business_Process_Parameters>
    <bsvc:Maintain_Contact_Information_Data>
		<bsvc:Worker_Reference>
			<bsvc:ID bsvc:type="Employee_ID">Employee_ID</bsvc:ID>
		</bsvc:Worker_Reference>
		<bsvc:Effective_Date>Effective_Date</bsvc:Effective_Date>
		<bsvc:Worker_Contact_Information_Data>
			<bsvc:Email_Address_Data>
				<bsvc:Email_Address>Email_Address</bsvc:Email_Address>
				<bsvc:Usage_Data bsvc:Public="true">
					<bsvc:Type_Data bsvc:Primary="0">
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

	$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Reference.ID.InnerText = $EmployeeId
	$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Email_Address_Data.Email_Address = $WorkEmail
	$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Effective_Date = (Get-Date).ToString( 'yyyy-MM-dd' )

	Invoke-WorkdayRequest -Request $request -Uri $Uri -Username $Username -Password $Password | where {$Passthru} | Write-Output
	}