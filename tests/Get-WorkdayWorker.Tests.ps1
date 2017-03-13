Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Get-WorkdayWorker {
    InModuleScope WorkdayApi {

        Mock Invoke-WorkdayRequest {
            Mock_Invoke-WorkdayRequest_Echo @args
        }

        It 'Creates the correct XML for the Workday request.' {

        $expectedResponse = @'
<bsvc:Get_Workers_Request xmlns:bsvc="urn:com.workday/bsvc"><bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false"><bsvc:Worker_Reference><bsvc:ID bsvc:type="Employee_ID">1</bsvc:ID></bsvc:Worker_Reference></bsvc:Request_References><bsvc:Response_Group><bsvc:Include_Reference>false</bsvc:Include_Reference><bsvc:Include_Personal_Information>false</bsvc:Include_Personal_Information><bsvc:Include_Employment_Information>false</bsvc:Include_Employment_Information><bsvc:Include_Compensation>false</bsvc:Include_Compensation><bsvc:Include_Organizations>false</bsvc:Include_Organizations><bsvc:Include_Roles>false</bsvc:Include_Roles><bsvc:Include_Worker_Documents>false</bsvc:Include_Worker_Documents></bsvc:Response_Group></bsvc:Get_Workers_Request>
'@ -f (Get-Date)
            $response = Get-WorkdayWorker -WorkerId 1 -WorkerType Employee_ID
            $response.Xml.OuterXml | Should BeExactly $expectedResponse
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
        }

        It 'Returns expected worker information.' {

            Mock Invoke-WorkdayRequest {
                Mock_Invoke-WorkdayRequest_ExampleWorker
            }

            $response = @(Get-WorkdayWorker -WorkerId 1 -WorkerType Employee_ID -IncludePersonal)
            $response.Count | Should Be 1
            $response[0].WorkerWid | Should Be '00000000000000000000000000000000'
            $response[0].WorkerDescriptor | Should Be 'Example Worker (1)'
            $response[0].Phone.Count | Should Be 1
            $response[0].Email.Count | Should Be 1
            @($response[0].OtherId).Count | Should Be 2
            $response[0].XML -is [XML] | Should Be $true
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 2

        }

    }
}