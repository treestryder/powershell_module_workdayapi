function Get-WorkdayWorkerDocument {
<#
.SYNOPSIS
    Gets Workday Worker Documents.

.DESCRIPTION
    Gets Workday Worker Documents.

.PARAMETER WorkerId
    The Worker's Id at Workday. A Worker ID must be at least 1, up to 32, numbers or hex characters.

.PARAMETER WorkerType
    The type of ID that the WorkerId represents. Valid values
    are 'WID', 'Contingent_Worker_ID' and 'Employee_ID'.

.PARAMETER Path
    If specified, the files will be saved to this directory path.

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

Get-WorkdayWorkerDocument -WorkerId 123

#>

	[CmdletBinding(DefaultParametersetName='Search')]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true,
            Position=0,
            ParameterSetName='Search')]
		[ValidatePattern ('^[a-fA-F0-9\-]{1,32}$')]
		[string]$WorkerId,
        [Parameter(ParameterSetName="Search")]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
        [Parameter(ParameterSetName="Search")]
		[string]$Human_ResourcesUri,
        [Parameter(ParameterSetName="Search")]
		[string]$Username,
        [Parameter(ParameterSetName="Search")]
		[string]$Password,
        [Parameter(ParameterSetName="NoSearch")]
        [xml]$DocumentXml,
        [string]$Path,
        [Alias("Force")]
        [switch]$IncludeInactive
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'Search') {
        $response = Get-WorkdayWorker -WorkerId $WorkerId -WorkerType $WorkerType -IncludeDocuments -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -IncludeInactive:$IncludeInactive -ErrorAction Stop
        $DocumentXml = $response.Xml
    }

    if ($DocumentXml -eq $null) {
        Write-Warning 'Unable to find Document information.'
        return
    }

    $fileTemplate = [pscustomobject][ordered]@{
        FileName      = $null
        Category      = $null
        Base64        = $null
    }

    Add-Member -InputObject $fileTemplate -MemberType ScriptMethod -Name SaveAs -Value {
        param ( [string]$Path )
        [system.io.file]::WriteAllBytes( $Path, [System.Convert]::FromBase64String( $this.Base64 ) )
    }

    if (-not ([string]::IsNullOrEmpty($Path)) -and -not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }

    $DocumentXml.GetElementsByTagName('wd:Worker_Document_Detail_Data') | ForEach-Object {
        $o = $fileTemplate.PsObject.Copy()
        $categoryXml = $_.Document_Category_Reference.ID | Where-Object {$_.type -match 'Document_Category__Workday_Owned__ID|Document_Category_ID'}
        $o.Category = '{0}/{1}' -f $categoryXml.type, $categoryXml.'#text'
        $o.FileName = $_.Filename
        $o.Base64 = $_.File
        Write-Output $o
        if (-not ([string]::IsNullOrEmpty($Path))) {
            $filePath = Join-Path $Path $o.FileName
            $o.SaveAs($filePath)
        }
    }
}
