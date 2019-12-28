Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Get-WorkdayWorkerOtherId {
    InModuleScope WorkdayApi {

        It 'Returns expected ID information.' {
            Mock Invoke-WorkdayRequest {
                Mock_Invoke-WorkdayRequest_ExampleWorker
            }

            $response = @(Get-WorkdayWorkerOtherId -WorkerId 1)
            $response.Count | Should Be 1
            $response[0].Type | Should Be 'Badge_ID'
            $response[0].Id | Should Be '1'
            $response[0].Descriptor | Should Be 'Badge ID'
            $response[0].WID | Should Be '00000000000000000000000000000000'
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
        }
    }
}