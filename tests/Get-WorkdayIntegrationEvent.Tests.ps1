Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Get-WorkdayIntegrationEvent {
    InModuleScope WorkdayApi {

        # Echo Request
        Mock Invoke-WorkdayRequest {
            Mock_Invoke-WorkdayRequest_ExampleIntegrationEvent @args
        }

        It 'Calls Invoke-WorkdayRequest and returns the proper responses.' {
            $response = Get-WorkdayIntegrationEvent -Wid 0123456789ABCDEF0123456789ABCDEF
            $response.Name                 | Should BeExactly 'Test Descriptor'
            $response.Start.GetType().Name | Should BeExactly 'DateTime'
            $response.End.GetType().Name   | Should BeExactly 'DateTime'
            $response.Message              | Should BeExactly 'Integration Completed.'
            $response.PercentComplete      | Should BeExactly 100
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
        }
    }
}