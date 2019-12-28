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