<####  Before testing, have to create the mock XML for the test worker.


Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Get-WorkdayToAdData {

    InModuleScope WorkdayApi {

        It 'Returns expected worker information.' {
            Mock Invoke-WorkdayRequest {
                Mock_Invoke-WorkdayRequest_ExampleWorker
            }

            $response = @(Get-WorkdayToAdData -WorkerId 1 -WorkerType Employee_ID)
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
            $response.Count | Should Be 1
            $response[0].'ADD or CHANGE' | Should Be 'ADD'
            $response[0].'Employee or Contingent Worker Number' | Should Be ''
            $response[0].'First Name' | Should Be ''
            $response[0].'Last Name' | Should Be ''
            $response[0].'Preferred First Name' | Should Be ''
            $response[0].'Preferred Last Name' | Should Be ''
            $response[0].'User Name' | Should Be ''
            $response[0].'Work Phone' | Should Be ''
            $response[0].'Badge ID' | Should Be ''
            $response[0].'Job Title' | Should Be ''
            $response[0].'Employee or Contingent Worker Type' | Should Be ''
            $response[0].'Worker Type' | Should Be ''
            $response[0].'Worker SubType' | Should Be ''
            $response[0].'Department (LOB)' | Should Be 'Unimplemented'
            $response[0].'Sub Department' | Should Be 'Unimplemented'
            $response[0].'Location (Building)' | Should Be ''
            $response[0].'Location(Workspace)' | Should Be ''
            $response[0].'Supervisor Name' | Should Be ''
            $response[0].'Supervisor Employee Id' | Should Be ''
            $response[0].'Matrix Manager Name (for Team Members)' | Should Be ''
            $response[0].'Hire Date' | Should Be ''
        }
    }
}
#>