function Get-WorkdayWorkerPhone {
	[CmdletBinding()]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$EmployeeId,
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password
	)

    if ([string]::IsNullOrWhiteSpace($Uri)) { $Uri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

        $w = Get-WorkdayWorker @PSBoundParameters -IncludePersonal
        if ($w -eq $null) { return }

        $numberTemplate = [pscustomobject][ordered]@{
            Type    = $null
            Number  = $null
            Primary = $null
            Public  = $null
        }

        $w.Get_Workers_Response.Response_Data.FirstChild.Worker_Data.Personal_Data.Contact_Data.Phone_Data | foreach {
            $o = $numberTemplate.PsObject.Copy()
            $o.Type = $_.Usage_Data.Type_Data.Type_Reference.Descriptor + '/' + $_.Phone_Device_Type_Reference.Descriptor
            $o.Number = $_.Formatted_Phone
            $o.Primary = $_.Usage_Data.Type_Data.Primary
            $o.Public = $_.Usage_Data.Public -eq 1
            Write-Output $o
        }
	}
