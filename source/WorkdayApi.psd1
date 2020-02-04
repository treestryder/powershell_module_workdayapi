@{
    Description = 'Provides a means to access the Workday SOAP API in a Powershell friendly manner.'
    ModuleVersion = '2.2.6'
    HelpInfoURI = 'https://github.com/treestryder/powershell_module_workdayapi/wiki'
    Author = 'Nathan Hartley'
    Copyright = '(c) 2019 Nathan Hartley. All rights reserved.'
    RootModule = 'WorkdayApi.psm1'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    PrivateData = @{
        PSData = @{
            Tags = @('Workday')
            LicenseUri = 'https://github.com/treestryder/powershell_module_workdayapi/blob/master/source/License.txt'
            ProjectUri = 'https://github.com/treestryder/powershell_module_workdayapi/'
            ReleaseNotes = 'Inital release to the Powershell Gallery.'
        }
    }
    FunctionsToExport = @(
        'ConvertFrom-WorkdayWorkerXml',
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
    GUID = 'bd4390dc-a8ad-4bce-8d69-f53ccf8e4163'
}
