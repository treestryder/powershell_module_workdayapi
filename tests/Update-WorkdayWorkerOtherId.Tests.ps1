Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Update-WorkdayWorkerOtherId {

    InModuleScope WorkdayApi {
    
        Mock Get-WorkdayWorkerOtherId  {
            param ($WorkerId)
            if ($WorkerId -eq 0) { return }
            [pscustomobject][ordered]@{
                 Type       = 'Badge_ID'
                 Id         = 1
                 Descriptor = $null
                 Issued_Date = Get-Date '2000-01-01'
                 Expiration_Date = Get-Date '2001-01-01'
                 WID = '00000000000000000000000000000000'
             }
        }

        Mock Set-WorkdayWorkerOtherId {
             [pscustomobject][ordered]@{
                Success = $true
                Message = 'Success'
                Xml = '<x>Success</x>'
            }
        }

        Context Different {

            It 'Works when passed a Worker XML object.' {
                $worker = Mock_Invoke-WorkdayRequest_ExampleWorker
                $response = Update-WorkdayWorkerOtherId -WorkerXml $worker.Xml -Type 'Badge_ID' -Id 2 -IssuedDate '1/1/2000' -ExpirationDate '1/1/2001'
                Assert-MockCalled Set-WorkdayWorkerOtherId -Exactly 1
            }

            It 'Calls Set-WorkdayWorkerOtherId when BadgeId changes.' {
                $response = Update-WorkdayWorkerOtherId -WorkerId 1 -Type 'Badge_ID' -Id 2 -IssuedDate '1/1/2000' -ExpirationDate '1/1/2001'
                Assert-MockCalled Set-WorkdayWorkerOtherId -Exactly 2
            }

            It 'Calls Set-WorkdayWorkerOtherId when Issued_Date changes.' {
                $response = Update-WorkdayWorkerOtherId -WorkerId 1 -Type 'Badge_ID' -Id 1 -IssuedDate (Get-Date) -ExpirationDate '1/1/2001'
                Assert-MockCalled Set-WorkdayWorkerOtherId -Exactly 3
            }

            It 'Calls Set-WorkdayWorkerOtherId when Expiration_Date changes.' {
                $response = Update-WorkdayWorkerOtherId -WorkerId 1 -Type 'Badge_ID' -Id 1 -IssuedDate '1/1/2000' -ExpirationDate (Get-Date)
                Assert-MockCalled Set-WorkdayWorkerOtherId -Exactly 4
            }

            It 'Calls Set-WorkdayWorkerOtherId when there is a new Badge ID.' {
                $response = Update-WorkdayWorkerOtherId -WorkerId 0 -Type 'Badge_ID' -Id 1 -IssuedDate '1/1/2000' -ExpirationDate '1/1/2001'
                Assert-MockCalled Set-WorkdayWorkerOtherId -Exactly 5
            }

            It 'Should default to the current IssueDate value when a date is not passed.' {
                $expected = 'Changed Current [1 valid from 1/1/2000 12:00 AM to 1/1/2001 12:00 AM] Proposed [1 valid from current IssuedDate to 1/1/2003 12:00 AM]'
                $response = Update-WorkdayWorkerOtherId -WorkerId 1 -Type 'Badge_ID' -Id 1 -ExpirationDate '1/1/2003'
                $response.Message | Should Be $expected
                Assert-MockCalled Set-WorkdayWorkerOtherId -Exactly 6
            }

            It 'Should default to the current Expiration value when a date is not passed.' {
                $expected = 'Changed Current [1 valid from 1/1/2000 12:00 AM to 1/1/2001 12:00 AM] Proposed [1 valid from 1/1/2003 12:00 AM to current ExpirationDate]'
                $response = Update-WorkdayWorkerOtherId -WorkerId 1 -Type 'Badge_ID' -Id 1 -IssuedDate '1/1/2003'
                $response.Message | Should Be $expected
                Assert-MockCalled Set-WorkdayWorkerOtherId -Exactly 7
            }

            It 'Throws an exception when an invalid IssueDate is passed.' {
                {Update-WorkdayWorkerOtherId -WorkerId 1 -Type 'Badge_ID' -Id 1 -IssuedDate 'bad' -ExpirationDate '1/1/2001'} | Should Throw
            }

            It 'Throws an exception when an invalid ExpirationDate is passed.' {
                {Update-WorkdayWorkerOtherId -WorkerId 1 -Type 'Badge_ID' -Id 1 -IssuedDate '1/1/2000' -ExpirationDate 'bad'} | Should Throw
            }

        }

        Context Same {

            It 'Skips calling Set-WorkdayWorkerOtherId when no changes found.' {
                $null = Update-WorkdayWorkerOtherId -WorkerId 1 -Type 'Badge_ID' -Id 1 -IssuedDate '1/1/2000' -ExpirationDate '1/1/2001'
                Assert-MockCalled Get-WorkdayWorkerOtherId -Exactly 1
                Assert-MockCalled Set-WorkdayWorkerOtherId -Exactly 0
            }

            It 'Skips calling Set-WorkdayWorkerOtherId when no changes and no dates passed.' {
                $null = Update-WorkdayWorkerOtherId -WorkerId 1 -Type 'Badge_ID' -Id 1
                Assert-MockCalled Get-WorkdayWorkerOtherId -Exactly 2
                Assert-MockCalled Set-WorkdayWorkerOtherId -Exactly 0
            }
        }
    }
}