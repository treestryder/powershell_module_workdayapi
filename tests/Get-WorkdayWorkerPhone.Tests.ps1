Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Get-WorkdayWorkerPhone {
    InModuleScope WorkdayApi {

        Context Search {
            It 'Returns expected phone information when provided an EmployeeId.' {
                Mock Invoke-WorkdayRequest {
                    Mock_Invoke-WorkdayRequest_ExampleWorker
                }

                $response = @(Get-WorkdayWorkerPhone -WorkerId 1)
                $response.Count | Should Be 1
                $response[0].UsageType | Should Be 'Work'
                $response[0].DeviceType | Should Be 'Landline'
                $response[0].Number | Should Be '1 (517) 123-4567'
                $response[0].Extension | Should Be '4321'
                $response[0].Primary | Should Be $true
                $response[0].Public | Should Be $true
                Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
            }
        }

        Context NoSearch {
            It 'Returns expected Phone information when provided a Worker XML object.' {
                Mock Invoke-WorkdayRequest {}
                
                $worker = Mock_Invoke-WorkdayRequest_ExampleWorker
                $response = @(Get-WorkdayWorkerPhone -WorkerXml $worker.Xml )
                $response.Count | Should Be 1
                $response[0].UsageType | Should Be 'Work'
                $response[0].DeviceType | Should Be 'Landline'
                $response[0].Number | Should Be '1 (517) 123-4567'
                $response[0].Extension | Should Be '4321'
                $response[0].Primary | Should Be $true
                $response[0].Public | Should Be $true
                Assert-MockCalled Invoke-WorkdayRequest -Exactly 0
            }
        }

    }
}