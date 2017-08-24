Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Get-WorkdayWorkerNationalId {
    InModuleScope WorkdayApi {

        It 'Returns expected ID information.' {
            Mock Invoke-WorkdayRequest {
                Mock_Invoke-WorkdayRequest_ExampleWorker
            }

            $response = @(Get-WorkdayWorkerNationalId -WorkerId 1)
            $response.Count | Should Be 1
            $response[0].Type | Should Be 'USA-SSN'
            $response[0].Id | Should Be '000000000'
            $response[0].Descriptor | Should Be '000-00-0000 (USA-SSN)'
            $response[0].WID | Should Be '00000000000000000000000000000000'
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
        }
    }
}