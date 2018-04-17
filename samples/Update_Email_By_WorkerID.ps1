<#
.SYNOPSIS
    Updates Worker Email Addresses, given a file with WorkerID and Email.
.DESCRIPTION
    Updates Worker Email Addresses, given a file with WorkerID and Email.

.PARAMETER InputFile
    Path to input CSV file. The CSV should look like this (with or without the header):
        WorkerID,Email
        1,email1@example.com
        2,email2@example.com    

.PARAMETER ArchiveFile
    A path can be specified to move / archive the input file. The .Net format
    token {0} is expanded with the current date and time. When not specified,
    the input file is left untouched. When a value of 'delete' is given the
    input file is deleted.
.PARAMETER ResultsFile
    A path to an optional CSV file of the results. The .Net format token {0}
    is expanded with the current date and time.
.PARAMETER UsageType
    Passed to Update-WorkdayWorkerEmail. Currently supports Work or Home.
.PARAMETER Private
    Passed to Update-WorkdayWorkerEmail.
.PARAMETER Secondary
    Passed to Update-WorkdayWorkerEmail.

.EXAMPLE
    $parameters = @{
        InputFile = 'Secondary_Work_Emails.csv' # WorkerID,Email
        ArchiveFile = 'Secondary_Work_Emails_{0:yyyyMMdd}.csv'
        ResultsFile = 'Secondary_Work_Emails_{0:yyyyMMdd}_Results.csv'
        UsageType = 'WORK'
        Secondary = $true
    }

   .\samples\Update_Email_By_WorkerID.ps1 @parameters

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    $InputFile,
    $ArchiveFile,
    $ResultsFile,
    [ValidateSet('HOME','WORK')]
    [string]$UsageType = 'WORK',
    [switch]$Private,
    [switch]$Secondary
)

Write-Verbose "Downloading and building Worker lookup table."
$Workers = Get-WorkdayWorkerByIdLookupTable

function Main {

    Write-Verbose "Processing input file: $InputFile"
    $arguments = @{
        Path = $InputFile
    }
    
    # Add a header argument, if the first line starts with a number.
    $firstLine = Get-Content -Path $InputFile -TotalCount 1
    if ($firstLine -match '^"?\d') {
        $arguments['Header'] = 'WorkerID','Email'
    }
    
    if ($ResultsFile -eq $null) {
        Import-Csv @arguments | UpdateEmail    
    }
    else {
        $ResultsFile = $ResultsFile -f (Get-Date)
        CreateDirectoryIfNeeded $ResultsFile
        Import-Csv @arguments | UpdateEmail | Export-Csv -Path $ResultsFile -NoTypeInformation
        Write-Verbose "Result file: $ResultsFile"
    }
    
    if ($ArchiveFile -ne $null) {
        if ($ArchiveFile -eq 'delete') {
            Write-Verbose "Deleting input file."
            Remove-Item -Path $InputFile
        }
        else {
            $ArchiveFile = $ArchiveFile -f (Get-Date)
            Write-Verbose "Archiving input file to: $ArchiveFile"
            CreateDirectoryIfNeeded $ArchiveFile
            Move-Item -Path $InputFile -Destination $ArchiveFile -Force
        }
    }
}

filter UpdateEmail {
    $entry = $_
    $worker = $Workers[$entry.WorkerID]
    if ($worker -eq $null) {
        $output = GetErrorResponse -WorkerId $entry.WorkerID -Email $entry.Email -Message 'Workday Worker not found by WorkerID.'
        Write-Output $output
    }
    elseif ($worker.Count -gt 1) {
        $unrolledWorkers = ($worker | foreach {'{0} {1}' -f $_.WorkerType, $_.WorkerId}) -join ', '
        $msg = "More than one Workday Worker found by WorkerID: $unrolledWorkers"
        $output = GetErrorResponse -WorkerId $entry.WorkerID -Email $entry.Email -Message $msg
        Write-Output $output
    }
    else {
        try {
            $output = Update-WorkdayWorkerEmail -WorkerType  $worker[0].WorkerType -WorkerId $worker[0].WorkerId -Email $entry.Email -UsageType:$UsageType -Private:$Private -Secondary:$Secondary -ErrorAction Stop
            Write-Output $output
        }
        catch {
            $msg = 'Update-WorkdayWorkerEmail error: {0}' -f $_
            $output = GetErrorResponse -WorkerId $entry.WorkerID -Email $entry.Email -Message $msg
            Write-Output $output
        }
    }
}

function GetErrorResponse {
    param (
        $WorkerId,
        $Email,
        $Message
    )
    [PSCustomObject][Ordered]@{
        WorkerId = $WorkerId
        WorkerType = $null
        Email = $Email
        UsageType = $UsageType
        Primary = -not $Secondary
        Public = -not $Private
        Success = $false
        Message = $Message
    } | Write-Output
}

function CreateDirectoryIfNeeded {
    param ($Path)
    $Directory = Split-Path -Parent -Path $Path
    if (-not (Test-Path $Directory)) {
        New-Item -Path $Directory -Type Directory | Out-Null
    }
}

. Main
