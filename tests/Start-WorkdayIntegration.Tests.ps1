Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Start-WorkdayIntegration {
    InModuleScope WorkdayApi {

        # Echo Request
        Mock Invoke-WorkdayRequest {
            Mock_Invoke-WorkdayRequest_ExampleIntegration @args
        }

        It 'Calls Invoke-WorkdayRequest and returns the proper responses.' {
            $response = Start-WorkdayIntegration -Id TestId
            $response.Name    | Should BeExactly 'Test Descriptor'
            $response.Wid     | Should BeExactly '00000000000000000000000000000000'
            $response.Message | Should BeExactly 'Started at 4/12/2016 6:22 PM.'
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
        }
    }
}