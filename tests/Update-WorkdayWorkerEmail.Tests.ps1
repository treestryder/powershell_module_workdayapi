Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force

Describe Update-WorkdayWorkerEmail {
    InModuleScope WorkdayApi {

        Mock Get-WorkdayWorkerEmail {
            [pscustomobject][ordered]@{
                WorkerWid        = $null
                WorkerDescriptor = $null
                UsageType        = 'WORK'
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
            It 'Calls Set-WorkdayWorkerEmail when a new email is presented.' {
                $response = Update-WorkdayWorkerEmail -WorkerId 1 -Email 'new@example.com' -UsageType WORK
                Assert-MockCalled Set-WorkdayWorkerEmail -Exactly 1
            }

            It 'Works when passed a Worker XML object.' {
                $worker = Mock_Invoke-WorkdayRequest_ExampleWorker
                $response = Update-WorkdayWorkerEmail -WorkerXml $worker.Xml -Email 'new@example.com'
                Assert-MockCalled Set-WorkdayWorkerEmail -Exactly 2
            }
        }

        Context SameEmail {
            It 'Skips calling Set-WorkdayWorkerEmail when a duplicate email is presented.' {
                $response = Update-WorkdayWorkerEmail -WorkerId 1 -Email 'test@example.com'
                Assert-MockCalled Set-WorkdayWorkerEmail -Exactly 0
            }
        }

    }
}