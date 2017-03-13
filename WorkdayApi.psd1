@{
RootModule = 'WorkdayApi.psm1'
ModuleVersion = '1.2.0'
GUID = 'bd4390dc-a8ad-4bce-8d69-f53ccf8e4163'
Author = 'Nathan Hartley'
Copyright = '(c) 2015 . All rights reserved.'
Description = 'Provides a means to access the Workday SOAP API in a Powershell friendly manner.'
PowerShellVersion = '3.0'
FunctionsToExport = @(
		'Export-WorkdayDocument',
        'Invoke-WorkdayRequest',
		'Get-WorkdayReport',
		'Get-WorkdayWorker',
        'Remove-WorkdayConfiguration',
		'Set-WorkdayWorkerPhoto',

        'Get-WorkdayEndpoint',
        'Set-WorkdayCredential',
        'Set-WorkdayEndpoint',
        'Save-WorkdayConfiguration'

        'Get-WorkdayWorkerEmail',
		'Set-WorkdayWorkerEmail',
        'Update-WorkdayWorkerEmail'

        'Get-WorkdayWorkerDocument',
        'Set-WorkdayWorkerDocument',

        'Get-WorkdayWorkerOtherId',
        'Set-WorkdayWorkerBadgeId',
        'Update-WorkdayWorkerBadgeId',

        'Get-WorkdayWorkerPhone',
		'Set-WorkdayWorkerPhone',
        'Update-WorkdayWorkerPhone',

        'Start-WorkdayIntegration',
        'Get-WorkdayIntegrationEvent'

	)
# VariablesToExport = '*'
# AliasesToExport = '*'
# PrivateData = ''
}

