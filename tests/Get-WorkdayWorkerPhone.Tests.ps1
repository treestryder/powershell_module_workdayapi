Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Get-WorkdayWorkerPhone {
    InModuleScope WorkdayApi {

        It 'Returns expected phone number information.' {
        Mock Invoke-WorkdayRequest {
            Mock_Invoke-WorkdayRequest_ExampleWorker
        }

            $response = @(Get-WorkdayWorkerPhone -EmployeeId 1)
            $response.Count | Should Be 1
            $response[0].WorkerWid | Should Be '00000000000000000000000000000000'
            $response[0].WorkerDescriptor | Should Be 'Example Worker (1)'
            $response[0].Type | Should Be 'Work/Landline'
            $response[0].Number | Should Be '+1 (517) 123-4567'
            $response[0].Primary | Should Be $true
            $response[0].Public | Should Be $true
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
        }

    }
}