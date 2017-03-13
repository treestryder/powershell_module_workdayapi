function Set-WorkdayWorkerBadgeId {
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
		[ValidatePattern('^[0-9]+$')]
		[string]$BadgeId,
    [Parameter(Mandatory = $true)]
    [datetime]$IssuedDate,
    [Parameter(Mandatory = $true)]
    [datetime]$ExpirationDate,
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    $request = [xml]@'
<bsvc:Change_Other_IDs_Request bsvc:version="v27.2" xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Business_Process_Parameters>
    <bsvc:Auto_Complete>true</bsvc:Auto_Complete>
    <bsvc:Run_Now>true</bsvc:Run_Now>
    <bsvc:Comment_Data>
      <bsvc:Comment>Badge ID set by Set-WorkdayWorkerBadgeId</bsvc:Comment>
    </bsvc:Comment_Data>
  </bsvc:Business_Process_Parameters>

  <bsvc:Change_Other_IDs_Data>
    <bsvc:Worker_Reference>
      <bsvc:ID bsvc:type="Employee_ID">Employee_ID</bsvc:ID>
    </bsvc:Worker_Reference>
    <bsvc:Custom_Identification_Data bsvc:Replace_All="true">
      <bsvc:Custom_ID bsvc:Delete="false">
        <bsvc:Custom_ID_Data>
          <bsvc:ID>string</bsvc:ID>
          <bsvc:ID_Type_Reference bsvc:Descriptor="Badge ID">
            <bsvc:ID bsvc:type="Custom_ID_Type_ID">Badge_ID</bsvc:ID>
          </bsvc:ID_Type_Reference>
          <bsvc:Issued_Date>2014-06-09+00:00</bsvc:Issued_Date>
          <bsvc:Expiration_Date>2008-11-15</bsvc:Expiration_Date>
        </bsvc:Custom_ID_Data>
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

$request.Change_Other_IDs_Request.Change_Other_IDs_Data.Custom_Identification_Data.Custom_ID.Custom_ID_Data.ID = $BadgeId
$request.Change_Other_IDs_Request.Change_Other_IDs_Data.Custom_Identification_Data.Custom_ID.Custom_ID_Data.Issued_Date = $IssuedDate.ToString('o')
$request.Change_Other_IDs_Request.Change_Other_IDs_Data.Custom_Identification_Data.Custom_ID.Custom_ID_Data.Expiration_Date = $ExpirationDate.ToString('yyyy-MM-dd')

	Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password | Write-Output
}