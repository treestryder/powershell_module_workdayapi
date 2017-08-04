Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Update-WorkdayWorkerBadgeId {

    InModuleScope WorkdayApi {
    
        Mock Get-WorkdayWorkerOtherId  {
            param ($WorkerId)
            if ($WorkerId -eq 0) { return }
            [pscustomobject][ordered]@{
                 Type       = 'Custom_ID/Badge_ID'
                 Id         = 1
                 Descriptor = $null
                 Issued_Date = Get-Date '2000-01-01'
                 Expiration_Date = Get-Date '2001-01-01'
             }
        }

        Mock Set-WorkdayWorkerBadgeId {
             [pscustomobject][ordered]@{
                Success = $true
                Message = 'Success'
                Xml = '<x>Success</x>'
            }
        }

        Context Different {

            It 'Works when passed a Worker XML object.' {
                $worker = Mock_Invoke-WorkdayRequest_ExampleWorker
                $response = Update-WorkdayWorkerBadgeId -WorkerXml $worker.Xml -BadgeId 2 -IssuedDate '1/1/2000' -ExpirationDate '1/1/2001'
                Assert-MockCalled Set-WorkdayWorkerBadgeId -Exactly 1
            }

            It 'Calls Set-WorkdayWorkerBadgeId when BadgeId changes.' {
                $response = Update-WorkdayWorkerBadgeId -WorkerId 1 -BadgeId 2 -IssuedDate '1/1/2000' -ExpirationDate '1/1/2001'
                Assert-MockCalled Set-WorkdayWorkerBadgeId -Exactly 2
            }

            It 'Calls Set-WorkdayWorkerBadgeId when Issued_Date changes.' {
                $response = Update-WorkdayWorkerBadgeId -WorkerId 1 -BadgeId 1 -IssuedDate (Get-Date) -ExpirationDate '1/1/2001'
                Assert-MockCalled Set-WorkdayWorkerBadgeId -Exactly 3
            }

            It 'Calls Set-WorkdayWorkerBadgeId when Expiration_Date changes.' {
                $response = Update-WorkdayWorkerBadgeId -WorkerId 1 -BadgeId 1 -IssuedDate '1/1/2000' -ExpirationDate (Get-Date)
                Assert-MockCalled Set-WorkdayWorkerBadgeId -Exactly 4
            }

            It 'Calls Set-WorkdayWorkerBadgeId when there is a new Badge ID.' {
                $response = Update-WorkdayWorkerBadgeId -WorkerId 0 -BadgeId 1 -IssuedDate '1/1/2000' -ExpirationDate '1/1/2001'
                Assert-MockCalled Set-WorkdayWorkerBadgeId -Exactly 5
            }

            It 'Should default to the current IssuedDate value when a date is not passed.' {
                $expected = 'Changed Current [1 valid from 1/1/2000 12:00 AM to 1/1/2001 12:00 AM] Proposed [1 valid from 1/1/2003 12:00 AM to 1/1/2001 12:00 AM]'
                $response = Update-WorkdayWorkerBadgeId -WorkerId 1 -BadgeId 1 -IssuedDate '1/1/2003'
                $response.Message | Should Be $expected
                Assert-MockCalled Set-WorkdayWorkerBadgeId -Exactly 6
            }

            It 'Should default to the current Expiration value when a date is not passed.' {
                $expected = 'Changed Current [1 valid from 1/1/2000 12:00 AM to 1/1/2001 12:00 AM] Proposed [1 valid from 1/1/2000 12:00 AM to 1/1/2003 12:00 AM]'
                $response = Update-WorkdayWorkerBadgeId -WorkerId 1 -BadgeId 1 -ExpirationDate '1/1/2003'
                $response.Message | Should Be $expected
                Assert-MockCalled Set-WorkdayWorkerBadgeId -Exactly 7
            }

            It 'Throws an exception when an invalid IssueDate is passed.' {
                {Update-WorkdayWorkerBadgeId -WorkerId 1 -BadgeId 1 -IssuedDate 'bad' -ExpirationDate '1/1/2001'} | Should Throw
            }

            It 'Throws an exception when an invalid ExpirationDate is passed.' {
                {Update-WorkdayWorkerBadgeId -WorkerId 1 -BadgeId 1 -IssuedDate '1/1/2000' -ExpirationDate 'bad'} | Should Throw
            }

        }

        Context Same {

            It 'Skips calling Set-WorkdayWorkerBadgeId when no changes found.' {
                $response = Update-WorkdayWorkerBadgeId -WorkerId 1 -BadgeId 1 -IssuedDate '1/1/2000' -ExpirationDate '1/1/2001'
                Assert-MockCalled Get-WorkdayWorkerOtherId -Exactly 1
                Assert-MockCalled Set-WorkdayWorkerBadgeId -Exactly 0
            }

            It 'Skips calling Set-WorkdayWorkerBadgeId when no changes and no dates passed.' {
                $response = Update-WorkdayWorkerBadgeId -WorkerId 1 -BadgeId 1
                Assert-MockCalled Get-WorkdayWorkerOtherId -Exactly 2
                Assert-MockCalled Set-WorkdayWorkerBadgeId -Exactly 0
            }
        }
    }
}