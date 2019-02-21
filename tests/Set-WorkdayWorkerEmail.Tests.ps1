Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Set-WorkdayWorkerEmail {
    InModuleScope WorkdayApi {

        # Echo Request
        Mock Invoke-WorkdayRequest {
            Mock_Invoke-WorkdayRequest_Echo @args
        }

        It 'Creates the correct XML for the Workday request.' {
        $expectedResponse = @'
<bsvc:Maintain_Contact_Information_for_Person_Event_Request bsvc:version="v30.0" bsvc:Add_Only="false" xmlns:bsvc="urn:com.workday/bsvc"><bsvc:Business_Process_Parameters><bsvc:Auto_Complete>true</bsvc:Auto_Complete><bsvc:Run_Now>true</bsvc:Run_Now><bsvc:Comment_Data><bsvc:Comment>Email set by Set-WorkdayWorkerEmail</bsvc:Comment></bsvc:Comment_Data></bsvc:Business_Process_Parameters><bsvc:Maintain_Contact_Information_Data><bsvc:Worker_Reference><bsvc:ID bsvc:type="WID">1</bsvc:ID></bsvc:Worker_Reference><bsvc:Effective_Date>{0:yyyy-MM-dd}</bsvc:Effective_Date><bsvc:Worker_Contact_Information_Data><bsvc:Email_Address_Data bsvc:Do_Not_Replace_All="false"><bsvc:Email_Address>new@example.com</bsvc:Email_Address><bsvc:Usage_Data bsvc:Public="false"><bsvc:Type_Data bsvc:Primary="false"><bsvc:Type_Reference><bsvc:ID bsvc:type="Communication_Usage_Type_ID">WORK</bsvc:ID></bsvc:Type_Reference></bsvc:Type_Data></bsvc:Usage_Data></bsvc:Email_Address_Data></bsvc:Worker_Contact_Information_Data></bsvc:Maintain_Contact_Information_Data></bsvc:Maintain_Contact_Information_for_Person_Event_Request>
'@ -f (Get-Date)
            $response = Set-WorkdayWorkerEmail -WorkerId 1 -WorkerType WID -Email 'new@example.com' -UsageType WORK -Private -Secondary
            $response.Xml.OuterXml | Should BeExactly $expectedResponse
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
        }

        It 'Throws an exception when an invalid email is supplied.' {
            { Set-WorkdayWorkerEmail -WorkerId 1 -WorkEmail BadEmail } | Should Throw
        }
    }
}