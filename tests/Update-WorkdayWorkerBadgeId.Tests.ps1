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
                 Issued_Date = Get-Date -Year 2000 -Month 1 -Day 1
                 Expiration_Date = Get-Date -Year 2001 -Month 1 -Day 1
             }
        }

        Mock Set-WorkdayWorkerBadgeId {}

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
                $response = Update-WorkdayWorkerBadgeId -WorkerId 0 -BadgeId 1 -IssuedDate '1/1/2000' -ExpirationDate '1/1/2001' -debug
                Assert-MockCalled Set-WorkdayWorkerBadgeId -Exactly 5
            }

        }

        Context Same {

            It 'Skips calling Set-WorkdayWorkerBadgeId when no changes found.' {
                $response = Update-WorkdayWorkerBadgeId -WorkerId 1 -BadgeId 1 -IssuedDate '1/1/2000' -ExpirationDate '1/1/2001'
                Assert-MockCalled Get-WorkdayWorkerOtherId -Exactly 1
                Assert-MockCalled Set-WorkdayWorkerBadgeId -Exactly 0
            }

        }
    }
}