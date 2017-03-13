function Get-WorkdayWorkerPhone {
	[CmdletBinding()]
    [OutputType([hashtable])]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$EmployeeId,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Uri,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Username,
		[Parameter(Mandatory = $true)]
		[string]$Password
	)

        $w = get-workdayworker @PSBoundParameters -IncludePersonal

        $numbers = @{}
        $w.Get_Workers_Response.Response_Data.FirstChild.Worker_Data.Personal_Data.Contact_Data.Phone_Data | foreach {
             $numberType = $_.Usage_Data.Type_Data.Type_Reference.Descriptor + '/' + $_.Phone_Device_Type_Reference.Descriptor
             $numbers.Add($numberType, $_.Formatted_Phone)
        }
        Write-Output $numbers
	}