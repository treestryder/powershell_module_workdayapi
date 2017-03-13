<#
.SYNOPSIS
    Sets a Worker's phone number in Workday.

.DESCRIPTION
    Sets a Worker's phone number in Workday.

.PARAMETER EmployeeId
    The Worker's Employee Id at Workday. This cmdlet does not currently
    support Contengent Workers or referencing workers by WID.

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
    
Set-WorkdayWorkerPhone -EmpoyeeId 123 -WorkPhone 1234567890

#>

function Set-WorkdayWorkerPhone {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$EmployeeId,
		[Parameter(Mandatory = $true)]
        [Alias('OfficePhone')]
		[string]$WorkPhone,
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password,
        [switch]$Passthru
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }


	$request = [xml]@'
<bsvc:Maintain_Contact_Information_for_Person_Event_Request bsvc:Add_Only="false" xmlns:bsvc="urn:com.workday/bsvc">
	<bsvc:Business_Process_Parameters>
		<bsvc:Auto_Complete>true</bsvc:Auto_Complete>
		<bsvc:Run_Now>true</bsvc:Run_Now>
		<bsvc:Comment_Data>
			<bsvc:Comment>Work Phone set by Set-WorkdayWorkerPhone</bsvc:Comment>
		</bsvc:Comment_Data>
	</bsvc:Business_Process_Parameters>
    <bsvc:Maintain_Contact_Information_Data>
		<bsvc:Worker_Reference>
			<bsvc:ID bsvc:type="Employee_ID">Employee_ID</bsvc:ID>
		</bsvc:Worker_Reference>
		<bsvc:Effective_Date>Effective_Date</bsvc:Effective_Date>
		<bsvc:Worker_Contact_Information_Data>
			<bsvc:Phone_Data>
				<bsvc:International_Phone_Code>1</bsvc:International_Phone_Code>
				<bsvc:Area_Code/>
                <bsvc:Phone_Number/>
				<bsvc:Phone_Extension/>
				<bsvc:Phone_Device_Type_Reference>
					<bsvc:ID bsvc:type="Phone_Device_Type_ID">Landline</bsvc:ID>
				</bsvc:Phone_Device_Type_Reference>
				<bsvc:Usage_Data bsvc:Public="true">
					<bsvc:Type_Data bsvc:Primary="0">
						<bsvc:Type_Reference>
							<bsvc:ID bsvc:type="Communication_Usage_Type_ID">WORK</bsvc:ID>
						</bsvc:Type_Reference>
					</bsvc:Type_Data>
				</bsvc:Usage_Data>
			</bsvc:Phone_Data>
		</bsvc:Worker_Contact_Information_Data>
    </bsvc:Maintain_Contact_Information_Data>
</bsvc:Maintain_Contact_Information_for_Person_Event_Request>
'@

	$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Reference.ID.InnerText = $EmployeeId
	$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Effective_Date = (Get-Date).ToString( 'yyyy-MM-dd' )

    $scrubbedNumber = $WorkPhone -replace '[^\d]', ''
	if ($scrubbedNumber -match '(?<country>[\d]*?)(?<areacode>\d{0,3}?)(?<prefix>\d{0,3}?)(?<line>\d{1,4})$') {
		if ($Matches['country'].length -gt 0) {
			$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Phone_Data.International_Phone_Code = $Matches['country']
		}
		if ($Matches['areacode'].length -gt 0) {
			$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Phone_Data.Area_Code = $Matches['areacode']
		}

        $phoneNumber = ''
        if ($Matches['prefix'].length -gt 0) {
            $phoneNumber = $Matches['prefix'] + '-'
        }
        if ($Matches['line'].length -gt 0) {
            $phoneNumber += $Matches['line']
        }
		if ($phoneNumber.length -gt 0) {
			$request.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data.Worker_Contact_Information_Data.Phone_Data.Phone_Number = $phoneNumber
		}

    	Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password | where {$Passthru} | Write-Output
	} else {
        Write-Warning "Unable to update Work phone number for EmployeeId: $EmployeeId, invalid Phone Number: $WorkPhone"
    }
}