Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Get-WorkdayWorkerEmail {
    InModuleScope WorkdayApi {

        Context Search {
            It 'Returns expected email information when provided an EmployeeId.' {
                Mock Invoke-WorkdayRequest {
                    Mock_Invoke-WorkdayRequest_ExampleWorker
                }

                $response = @(Get-WorkdayWorkerEmail -EmployeeId 1)
                $response.Count | Should Be 1
                $response[0].WorkerWid | Should Be '00000000000000000000000000000000'
                $response[0].WorkerDescriptor | Should Be 'Example Worker (1)'
                $response[0].Type | Should Be 'Work'
                $response[0].Email | Should Be 'test@example.com'
                $response[0].Primary | Should Be $true
                $response[0].Public | Should Be $true
                Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
            }
        }

        Context NoSearch {
            It 'Returns expected email information when provided a Worker XML object.' {
                Mock Invoke-WorkdayRequest {}
                
                $workerXml = Mock_Invoke-WorkdayRequest_ExampleWorker
                $response = @(Get-WorkdayWorkerEmail -WorkerXml $workerXml )
                $response.Count | Should Be 1
                $response[0].WorkerWid | Should Be '00000000000000000000000000000000'
                $response[0].WorkerDescriptor | Should Be 'Example Worker (1)'
                $response[0].Type | Should Be 'Work'
                $response[0].Email | Should Be 'test@example.com'
                $response[0].Primary | Should Be $true
                $response[0].Public | Should Be $true
                Assert-MockCalled Invoke-WorkdayRequest -Exactly 0
            }
        }
    }
}