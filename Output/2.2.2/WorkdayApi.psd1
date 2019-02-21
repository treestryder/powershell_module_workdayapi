@{
RootModule = 'WorkdayApi.psm1'
ModuleVersion = '2.2.2'
GUID = 'bd4390dc-a8ad-4bce-8d69-f53ccf8e4163'
Author = 'Nathan Hartley'
Copyright = '(c) 2017 . All rights reserved.'
Description = 'Provides a means to access the Workday SOAP API in a Powershell friendly manner.'
PowerShellVersion = '3.0'
RequiredModules = @('BetterTLS')
FunctionsToExport = @('ConvertFrom-WorkdayWorkerXml','Export-WorkdayDocument','Get-WorkdayDate','Get-WorkdayEndpoint','Get-WorkdayIntegrationEvent','Get-WorkdayReport','Get-WorkdayToAdData','Get-WorkdayWorker','Get-WorkdayWorkerByIdLookupTable','Get-WorkdayWorkerDocument','Get-WorkdayWorkerEmail','Get-WorkdayWorkerNationalId','Get-WorkdayWorkerOtherId','Get-WorkdayWorkerPhone','Invoke-WorkdayRequest','Remove-WorkdayConfiguration','Remove-WorkdayWorkerOtherId','Save-WorkdayConfiguration','Set-WorkdayCredential','Set-WorkdayEndpoint','Set-WorkdayWorkerDocument','Set-WorkdayWorkerEmail','Set-WorkdayWorkerOtherId','Set-WorkdayWorkerPhone','Set-WorkdayWorkerPhoto','Start-WorkdayIntegration','Update-WorkdayWorkerEmail','Update-WorkdayWorkerOtherId','Update-WorkdayWorkerPhone')
# VariablesToExport = '*'
# AliasesToExport = '*'
# PrivateData = ''
}



