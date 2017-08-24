function Remove-WorkdayWorkerOtherId {
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
        [ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WID,
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    $request = [xml]@'
<bsvc:Change_Other_IDs_Request bsvc:version="v28.2" xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Business_Process_Parameters>
    <bsvc:Auto_Complete>true</bsvc:Auto_Complete>
    <bsvc:Run_Now>true</bsvc:Run_Now>
    <bsvc:Comment_Data>
      <bsvc:Comment>Other ID set by Set-WorkdayWorkerOtherId</bsvc:Comment>
    </bsvc:Comment_Data>
  </bsvc:Business_Process_Parameters>

  <bsvc:Change_Other_IDs_Data>
    <bsvc:Worker_Reference>
      <bsvc:ID bsvc:type="Employee_ID">Employee_ID</bsvc:ID>
    </bsvc:Worker_Reference>
    <bsvc:Custom_Identification_Data bsvc:Replace_All="false">
      <bsvc:Custom_ID bsvc:Delete="true">
        <bsvc:Custom_ID_Shared_Reference>
          <bsvc:ID bsvc:type="WID">wid</bsvc:ID>
        </bsvc:Custom_ID_Shared_Reference>
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
    
    $request.Change_Other_IDs_Request.Change_Other_IDs_Data.Custom_Identification_Data.Custom_ID.Custom_ID_Shared_Reference.ID.InnerText = $WID

    Invoke-WorkdayRequest -Request $request -Uri $Human_ResourcesUri -Username:$Username -Password:$Password | Write-Output
}