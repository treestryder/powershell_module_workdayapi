@{
RootModule = 'WorkdayApi.psm1'
ModuleVersion = '2.2.1'
GUID = 'bd4390dc-a8ad-4bce-8d69-f53ccf8e4163'
Author = 'Nathan Hartley'
Copyright = '(c) 2017 . All rights reserved.'
Description = 'Provides a means to access the Workday SOAP API in a Powershell friendly manner.'
PowerShellVersion = '3.0'
RequiredModules = @('BetterTLS')
FunctionsToExport = @(
        'ConvertFrom-WorkdayWorkerXml',
		'Export-WorkdayDocument',
        'Get-WorkdayToAdData',
        'Get-WorkdayReport',
        'Get-WorkdayWorker',
        'Get-WorkdayWorkerByIdLookupTable',
        'Invoke-WorkdayRequest',
        'Remove-WorkdayConfiguration',
		'Set-WorkdayWorkerPhoto',

        'Get-WorkdayEndpoint',
        'Set-WorkdayCredential',
        'Set-WorkdayEndpoint',
        'Save-WorkdayConfiguration',

        'Get-WorkdayWorkerEmail',
		'Set-WorkdayWorkerEmail',
        'Update-WorkdayWorkerEmail',

        'Get-WorkdayWorkerDocument',
        'Set-WorkdayWorkerDocument',

        'Get-WorkdayWorkerNationalId',

        'Get-WorkdayWorkerOtherId',
        'Remove-WorkdayWorkerOtherId',
        'Set-WorkdayWorkerOtherId',
        'Update-WorkdayWorkerOtherId',

        'Get-WorkdayWorkerPhone',
		'Set-WorkdayWorkerPhone',
        'Update-WorkdayWorkerPhone',

        'Start-WorkdayIntegration',
        'Get-WorkdayIntegrationEvent',

        'Get-WorkdayDate'

	)
# VariablesToExport = '*'
# AliasesToExport = '*'
# PrivateData = ''
}

