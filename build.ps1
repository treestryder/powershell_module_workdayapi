#requires -Module ModuleBuilder 
[cmdletBinding()]
Param(
    [Alias("ModuleVersion")]
    [string]$Version
)
Push-Location $PSScriptRoot -StackName BuildSUEModule
$Test = Invoke-Pester -PassThru -OutputFile ./artifacts/TestResults.xml -OutputFormat NUnitXml
#If ($Test.FailedCount -gt 0) {
#    Write-Error "Tests Failed, please review the errors (artifacts/TestResults.xml).  Build will not continue"
#} else {
    Try {
        Build-Module -SourcePath .\WorkdayApi  @PSBoundParameters
    } Catch {
        Write-Host "We encountered a build error"
        Write-Host "Error Message: $($_.Exception.Message)"
    }
#}
Pop-Location -StackName BuildSUEModule
