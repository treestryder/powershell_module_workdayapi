@{
    Description = 'Provides a means to access the Workday SOAP API in a Powershell friendly manner.'
    ModuleVersion = '2.3.2'
    HelpInfoURI = 'https://github.com/treestryder/powershell_module_workdayapi/wiki'
    Author = 'Nathan Hartley'
    RootModule = 'WorkdayApi.psm1'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    PrivateData = @{
        PSData = @{
            Tags = @('Workday')
            LicenseUri = 'https://github.com/treestryder/powershell_module_workdayapi/blob/master/source/License.txt'
            ProjectUri = 'https://github.com/treestryder/powershell_module_workdayapi/'
            ReleaseNotes = @'
* Added progress meter to Get-WorkdayWorker.
* Minor improvements. In particular, removed some uses of silent exceptions.

Change log available at: https://github.com/treestryder/powershell_module_workdayapi/blob/master/CHANGELOG.md 
'@
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
        'Get-WorkdayWorkerPhoto',
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
        
        'Get-WorkdayDate',
	
	    'Set-WorkdayWorkerUserId'
    )
    GUID = 'bd4390dc-a8ad-4bce-8d69-f53ccf8e4163'
}
