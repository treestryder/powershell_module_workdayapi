Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Get-WorkdayWorkerPhoto {
    InModuleScope WorkdayApi {

        # Echo Request
        Mock Invoke-WorkdayRequest {
            Mock_Invoke-WorkdayRequest_Echo @args
        }

        It 'Creates the correct XML for the request.' {
            $expectedResponse = @'
<bsvc:Get_Worker_Photos_Request bsvc:version="v30.0" xmlns:bsvc="urn:com.workday/bsvc"><bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false"><bsvc:Worker_Reference><bsvc:ID bsvc:type="Employee_ID">1</bsvc:ID></bsvc:Worker_Reference></bsvc:Request_References><bsvc:Response_Filter><bsvc:As_Of_Entry_DateTime>2020-05-05T00:00:00.0000000</bsvc:As_Of_Entry_DateTime></bsvc:Response_Filter></bsvc:Get_Worker_Photos_Request>
'@ -f (Get-Date)
            $response = Get-WorkdayWorkerPhoto -WorkerId 1 -AsOfEntryDateTime '2020-05-05' -Passthru
            $response.Xml.OuterXml | Should BeExactly $expectedResponse
        }

    }
}