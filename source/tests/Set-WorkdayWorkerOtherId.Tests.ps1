Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Set-WorkdayWorkerOtherId {
    InModuleScope WorkdayApi {

        # Echo Request
        Mock Invoke-WorkdayRequest {
            Mock_Invoke-WorkdayRequest_Echo @args
        }

        It 'Creates the correct XML for the Workday request.' {
        $expectedResponse = @'
<bsvc:Change_Other_IDs_Request bsvc:version="v28.2" xmlns:bsvc="urn:com.workday/bsvc"><bsvc:Business_Process_Parameters><bsvc:Auto_Complete>true</bsvc:Auto_Complete><bsvc:Run_Now>true</bsvc:Run_Now><bsvc:Comment_Data><bsvc:Comment>Other ID set by Set-WorkdayWorkerOtherId</bsvc:Comment></bsvc:Comment_Data></bsvc:Business_Process_Parameters><bsvc:Change_Other_IDs_Data><bsvc:Worker_Reference><bsvc:ID bsvc:type="WID">1</bsvc:ID></bsvc:Worker_Reference><bsvc:Custom_Identification_Data bsvc:Replace_All="false"><bsvc:Custom_ID bsvc:Delete="false"><bsvc:Custom_ID_Data><bsvc:ID>2</bsvc:ID><bsvc:ID_Type_Reference><bsvc:ID bsvc:type="Custom_ID_Type_ID">Badge_ID</bsvc:ID></bsvc:ID_Type_Reference><bsvc:Issued_Date>2001-01-01T00:00:00.0000000</bsvc:Issued_Date><bsvc:Expiration_Date>2002-02-02T00:00:00.0000000</bsvc:Expiration_Date></bsvc:Custom_ID_Data><bsvc:Custom_ID_Shared_Reference><bsvc:ID bsvc:type="WID">00000000000000000000000000000000</bsvc:ID></bsvc:Custom_ID_Shared_Reference></bsvc:Custom_ID></bsvc:Custom_Identification_Data></bsvc:Change_Other_IDs_Data></bsvc:Change_Other_IDs_Request>
'@
            $response = Set-WorkdayWorkerOtherId -WorkerId 1 -WorkerType WID -Type 'Badge_ID' -Id 2 -IssuedDate (Get-Date '1/1/2001') -ExpirationDate (Get-Date '2/2/2002') -WID '00000000000000000000000000000000'
            $response.Xml.OuterXml | Should BeExactly $expectedResponse
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
        }

    }
}