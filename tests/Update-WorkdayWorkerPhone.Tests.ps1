Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force

Describe Update-WorkdayWorkerPhone {
    InModuleScope WorkdayApi {

        Mock Get-WorkdayWorkerPhone {
            [pscustomobject][ordered]@{
                WorkerWid        = $null
                WorkerDescriptor = $null
                Type    = 'Work/Landline'
                Number  = '+1 (517) 123-4567'
                Primary = $true
                Public  = $true
            }
        }

        Mock Set-WorkdayWorkerPhone {}

        Context DifferentNumber {
            It 'Calls Set-WorkdayWorkerPhone when a new number is presented.' {
                $response = Update-WorkdayWorkerPhone -EmployeeId 1 -WorkPhone 2
                Assert-MockCalled Set-WorkdayWorkerPhone -Exactly 1
            }

            It 'Works when passed a Worker XML object.' {
                $workerXml = Mock_Invoke-WorkdayRequest_ExampleWorker
                $response = Update-WorkdayWorkerPhone -WorkerXml $workerXml -WorkPhone 2
                Assert-MockCalled Set-WorkdayWorkerPhone -Exactly 2
            }
        }

        Context SameNumber {
            It 'Skips calling Set-WorkdayWorkerPhone when a duplicate number is presented.' {
                $response = Update-WorkdayWorkerPhone -EmployeeId 1 -WorkPhone '1-517-123-4567'
                Assert-MockCalled Set-WorkdayWorkerPhone -Exactly 0
            }
        }

    }
}