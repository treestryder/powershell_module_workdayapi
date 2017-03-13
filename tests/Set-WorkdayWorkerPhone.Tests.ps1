Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1', '')

Describe $sut {
    InModuleScope WorkdayApi {

        # Echo Request
        Mock Invoke-WorkdayRequest {
            Mock_Invoke-WorkdayRequest_Echo @args
        }

        It 'Creates the correct XML for the Workday request.' {
        $expectedResponse = @'
<bsvc:Maintain_Contact_Information_for_Person_Event_Request bsvc:Add_Only="false" xmlns:bsvc="urn:com.workday/bsvc"><bsvc:Business_Process_Parameters><bsvc:Auto_Complete>true</bsvc:Auto_Complete><bsvc:Run_Now>true</bsvc:Run_Now><bsvc:Comment_Data><bsvc:Comment>Work Phone set by Set-WorkdayWorkerPhone</bsvc:Comment></bsvc:Comment_Data></bsvc:Business_Process_Parameters><bsvc:Maintain_Contact_Information_Data><bsvc:Worker_Reference><bsvc:ID bsvc:type="Employee_ID">1</bsvc:ID></bsvc:Worker_Reference><bsvc:Effective_Date>2015-12-22</bsvc:Effective_Date><bsvc:Worker_Contact_Information_Data><bsvc:Phone_Data><bsvc:International_Phone_Code>1</bsvc:International_Phone_Code><bsvc:Area_Code>123</bsvc:Area_Code><bsvc:Phone_Number>456-7890</bsvc:Phone_Number><bsvc:Phone_Extension /><bsvc:Phone_Device_Type_Reference><bsvc:ID bsvc:type="Phone_Device_Type_ID">Landline</bsvc:ID></bsvc:Phone_Device_Type_Reference><bsvc:Usage_Data bsvc:Public="true"><bsvc:Type_Data bsvc:Primary="true"><bsvc:Type_Reference><bsvc:ID bsvc:type="Communication_Usage_Type_ID">WORK</bsvc:ID></bsvc:Type_Reference></bsvc:Type_Data></bsvc:Usage_Data></bsvc:Phone_Data></bsvc:Worker_Contact_Information_Data></bsvc:Maintain_Contact_Information_Data></bsvc:Maintain_Contact_Information_for_Person_Event_Request>
'@
            $response = & $sut -EmployeeId 1 -WorkPhone 1234567890 -Passthru
            $response.OuterXml | Should BeExactly $expectedResponse
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
        }

        It 'Throws an exception when an invalid phone number is supplied.' {
            & $sut -EmployeeId 1 -WorkPhone BadNumber Should Throw 'Unable to update Work phone number for EmployeeId: 1, invalid Phone Number: BadNumber'
        }
    }
}