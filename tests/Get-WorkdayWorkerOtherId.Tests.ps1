Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Get-WorkdayWorkerOtherId {
    InModuleScope WorkdayApi {

        It 'Returns expected ID information.' {
            Mock Invoke-WorkdayRequest {
                Mock_Invoke-WorkdayRequest_ExampleWorker
            }

            $response = @(Get-WorkdayWorkerOtherId -EmployeeId 1)
            $response.Count | Should Be 2
            $response[0].Type | Should Be 'National_ID/USA-SSN'
            $response[0].Id | Should Be '000000000'
            $response[0].Descriptor | Should Be '000-00-0000 (USA-SSN)'
            $response[1].Type | Should Be 'Custom_ID/Badge_ID'
            $response[1].Id | Should Be '1'
            $response[1].Descriptor | Should Be 'Badge ID'
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
        }
    }
}