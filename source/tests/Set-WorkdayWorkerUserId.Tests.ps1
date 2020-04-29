Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Set-WorkdayWorkerUserId {
    InModuleScope WorkdayApi {

        # Echo Request
        Mock Invoke-WorkdayRequest {
            Mock_Invoke-WorkdayRequest_Echo @args
        }

        It 'Creates the correct XML for the Workday request for a Contingent Worker.' {
        $expectedResponse = @'
<bsvc:Workday_Account_for_Worker_Update bsvc:version="v33.0" xmlns:bsvc="urn:com.workday/bsvc"><bsvc:Worker_Reference><bsvc:Contingent_Worker_Reference><bsvc:Integration_ID_Reference><bsvc:ID bsvc:System_ID="WD-EMPLID">1</bsvc:ID></bsvc:Integration_ID_Reference></bsvc:Contingent_Worker_Reference></bsvc:Worker_Reference><bsvc:Workday_Account_for_Worker_Data><bsvc:User_Name>new@example.com</bsvc:User_Name></bsvc:Workday_Account_for_Worker_Data></bsvc:Workday_Account_for_Worker_Update>
'@ -f (Get-Date)
            $response = Set-WorkdayWorkerUserId -WorkerId 1 -WorkerType Contingent_Worker_ID -UserId 'new@example.com'
            $response.Xml.OuterXml | Should BeExactly $expectedResponse
        }

        It 'Creates the correct XML for the Workday request for an Employee.' {
            $expectedResponse = @'
<bsvc:Workday_Account_for_Worker_Update bsvc:version="v33.0" xmlns:bsvc="urn:com.workday/bsvc"><bsvc:Worker_Reference><bsvc:Employee_Reference><bsvc:Integration_ID_Reference><bsvc:ID bsvc:System_ID="WD-EMPLID">1</bsvc:ID></bsvc:Integration_ID_Reference></bsvc:Employee_Reference></bsvc:Worker_Reference><bsvc:Workday_Account_for_Worker_Data><bsvc:User_Name>new@example.com</bsvc:User_Name></bsvc:Workday_Account_for_Worker_Data></bsvc:Workday_Account_for_Worker_Update>
'@ -f (Get-Date)
                $response = Set-WorkdayWorkerUserId -WorkerId 1 -WorkerType Employee_ID -UserId 'new@example.com'
                $response.Xml.OuterXml | Should BeExactly $expectedResponse
            }

        It 'Throws an exception when a blank UserId is supplied.' {
            { Set-WorkdayWorkerUserId -WorkerId 1 -UserId '' } | Should Throw
        }
    }
}