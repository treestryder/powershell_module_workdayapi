<#
.SYNOPSIS
    Updates Worker photos, from a directory of specially named JPEG files.

.PARAMETER Path
    Folder with JEPG photos to be pushed to Workday. Named by Worker ID, optionally zero padded.
    01234.jpg
    01235.jpeg

.PARAMETER ResultsFile
    A path to a CSV file of the results. The .Net format token {0}
    is expanded with the current date and time.

.PARAMETER Since
    Optional. When specified, only photos newer than this time will be processed. Defaults
    to the last time the script successfully ran.

.PARAMETER All
    Use, in place of the Since parameter, to process all photos.

.EXAMPLE
    $parameters = @{
        Path = 'c:\path\to\photos
        ResultsFile = 'c:\path\for\results\Update-WorkdayWorkerPhotosSince_{0:yyyy-MM-dd}.csv'
    }

    .\samples\Update-WorkdayWorkerPhotosSince.ps1 @parameters

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    $Path,
    $ResultsFile,
    [string]$PersistanceFile = (Join-Path $Path 'Update-WorkdayWorkerPhotosSince.clixml'),
    [datetime]$Since = [datetime]::MinValue,
    [switch]$All,
    [switch]$WhatIf
)
Set-StrictMode -Version Latest

function Main {
    $activity = "Updating Workday Worker photos from $Path"

    # Unless the Since has a value specified, use the last time this process was ran.
    if ( $All -eq $false -and
        $Since -eq [datetime]::MinValue -and
        ( Test-Path -Path $persistanceFile )
    ) {
        $Since = Import-Clixml -Path $persistanceFile
        $activity = '{0}, since {1:g}' -f $activity, $Since
    }

    Write-Progress -Activity $activity -Status 'Initalization'
    Write-Verbose $activity


    $RunTime = Get-Date
    Write-Progress -Activity $activity -Status 'Initalization' -CurrentOperation 'Enumerating files'
    $files = @(
        Get-ChildItem -Path (Join-Path $Path '*') -Include *.jpg,*.jpeg |
            Where-Object {$All -or $_.LastWriteTime -ge $Since}
    )

    if ($files.count -gt 0) {
        Write-Progress -Activity $activity -Status 'Initalization' -CurrentOperation 'Downloading and building Worker lookup table.'
        $Workers = Get-WorkdayWorkerByIdLookupTable

        $countOfPhotos = 0
        foreach ($file in $files) {
            $countOfPhotos++
            Write-Progress -Activity $activity -Status "Processing ($countOfPhotos of $(@($files).count))." -CurrentOperation $file -PercentComplete ($countOfPhotos/@($files).count *100)
            $output = [PSCustomObject][ordered]@{
                PhotoPath = $file.FullName
                WorkerId = ''
                WorkerType = ''
                Success = $false
                Message = ''
            }

            if ($file.Name -match '0*(\d+).jpg$') {
                $output.WorkerId = $Matches[1]
                $worker = $Workers[$output.WorkerId]

                if ($worker -eq $null) {
                    $output.Success = $false
                    $output.Message = 'Worker ID not found at Workday.'
                }
                elseif ($worker.Count -gt 1) {
                    $output.Success = $false
                    $unrolledWorkers = ($worker | Foreach-Object {'{0} {1}' -f $_.WorkerType, $_.WorkerId}) -join ', '
                    $output.Message = "More than one Workday Worker found by WorkerID: $unrolledWorkers"
                }
                else {
                    $output.WorkerType = $worker[0].WorkerType
                    if ($WhatIf) {
                        $output.Success = $true
                        $output.Message = "WhatIf: Set-WorkdayWorkerPhoto -WorkerType '{0}' -WorkerId '{1}' -Path '{2}'" -f $worker[0].WorkerType, $worker[0].WorkerId, $file.FullName
                    }
                    else {
                        try {
                            $result = Set-WorkdayWorkerPhoto  -WorkerType $worker[0].WorkerType -WorkerId $worker[0].WorkerId -Path $file.FullName
                            $output.Success = $result.Success
                            $output.Message = $result.Message
                        }
                        catch {
                            $output.Success = $false
                            $output.message = $_
                        }
                    }
                }
            }
            else {
                $output.Success = $false
                $output.Message = 'Invalid file name.'
            }
            Write-Output $output
        }
        Write-Progress -Activity $activity -Completed -Status 'Completed'
        Write-Verbose "Done processing $($files.count) file(s)."
    } else {
        Write-Verbose 'No new photos to process.'
    }

    if (-not $WhatIf) {
        # Save when these tasks were last ran, to only process new files next time.
        $RunTime | Export-Clixml -Path $persistanceFile
    }
}

function CreateDirectoryIfNeeded {
    param ($Path)
    $Directory = Split-Path -Parent -Path $Path
    if ($Directory -ne $null -and -not (Test-Path $Directory)) {
        New-Item -Path $Directory -Type Directory | Out-Null
    }
}

Main | Write-Output -OutVariable Output

if ($ResultsFile -ne $null -and $Output.Count -gt 0) {
    $ResultsFile = $ResultsFile -f (Get-Date)
    CreateDirectoryIfNeeded $ResultsFile
    $Output | Export-Csv -Path $ResultsFile -NoTypeInformation
    Write-Verbose "Result file: $ResultsFile"
}
