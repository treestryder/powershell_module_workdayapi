Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Update-WorkdayWorkerPhone {
    InModuleScope WorkdayApi {

        Mock Get-WorkdayWorkerPhone {
            [pscustomobject][ordered]@{
                WorkerWid        = $null
                WorkerDescriptor = $null
                UsageType        = 'Work'
                DeviceType       = 'Landline'
                Number           = '+1 (517) 123-4567'
                Extension        = '4321'
                Primary          = $true
                Public           = $true
            }
        }

        Mock Set-WorkdayWorkerPhone {
             [pscustomobject][ordered]@{
                Success = $true
                Message = 'Success'
                Xml = '<x>Success</x>'
            }
        }

        Context DifferentNumber {
            It 'Calls Set-WorkdayWorkerPhone when a new number is presented.' {
                $response = Update-WorkdayWorkerPhone -WorkerId 1 -Number 2
                Assert-MockCalled Set-WorkdayWorkerPhone -Exactly 1
            }

            It 'Works when passed a Worker XML object.' {
                $worker = Mock_Invoke-WorkdayRequest_ExampleWorker
                $response = Update-WorkdayWorkerPhone -WorkerXml $worker.Xml -Number 2
                Assert-MockCalled Set-WorkdayWorkerPhone -Exactly 2
            }
        }

        Context SameNumber {
            It 'Skips calling Set-WorkdayWorkerPhone when a duplicate number is presented.' {
                $response = Update-WorkdayWorkerPhone -WorkerId 1 -Number '15171234567' -Extension '4321'
                Assert-MockCalled Get-WorkdayWorkerPhone -Exactly 1
                Assert-MockCalled Set-WorkdayWorkerPhone -Exactly 0
            }
        }

    }
}