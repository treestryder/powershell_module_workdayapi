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

.PARAMETER Extension
	Sets the worker's extension, if included.

.PARAMETER UsageType
	Known usage types: 'HOME' or 'WORK'.

.PARAMETER DeviceType
	Known device types: 'Landline', 'Cell', Mobile, 'WORK'

.PARAMETER Private
	Mark number as private.

.PARAMETER Secondary
	Any non-primary number. There can be multiple non-primary numbers, but only one primary. 
		
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
		[ValidatePattern ('^[a-zA-Z0-9\-]{1,32}$')]
        [string]$WorkerId,
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Number,
		[string]$Extension,
        [string]$UsageType = 'WORK',
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

	Write-Debug $request.OuterXml
    Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password | Write-Output
}