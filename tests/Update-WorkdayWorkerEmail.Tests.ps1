Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force

Describe Update-WorkdayWorkerEmail {
    InModuleScope WorkdayApi {

        Mock Get-WorkdayWorkerEmail {
            [pscustomobject][ordered]@{
                WorkerWid        = $null
                WorkerDescriptor = $null
                Type             = 'Work'
                Email            = 'test@example.com'
                Primary          = $true
                Public           = $true
            }
        }

        Mock Set-WorkdayWorkerEmail {
            [pscustomobject][ordered]@{
                Success = $true
                Message = 'Success'
                Xml = '<x>Success</x>'
            }
        }

        Context DifferentEmail {
            It 'Calls Set-WorkdayWorkerEmail when a new number is presented.' {
                $response = Update-WorkdayWorkerEmail -WorkerId 1 -WorkEmail 'new@example.com'
                Assert-MockCalled Set-WorkdayWorkerEmail -Exactly 1
            }

            It 'Works when passed a Worker XML object.' {
                $worker = Mock_Invoke-WorkdayRequest_ExampleWorker
                $response = Update-WorkdayWorkerEmail -WorkerXml $worker.Xml -WorkEmail 'new@example.com'
                Assert-MockCalled Set-WorkdayWorkerEmail -Exactly 2
            }
        }

        Context SameEmail {
            It 'Skips calling Set-WorkdayWorkerEmail when a duplicate number is presented.' {
                $response = Update-WorkdayWorkerEmail -WorkerId 1 -WorkEmail 'test@example.com'
                Assert-MockCalled Set-WorkdayWorkerEmail -Exactly 0
            }
        }

    }
}