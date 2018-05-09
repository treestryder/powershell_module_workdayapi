Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Set-WorkdayWorkerDocument {
    InModuleScope WorkdayApi {

        Mock Invoke-WorkdayRequest {
            Mock_Invoke-WorkdayRequest_Echo @args
        }

        $testFilePath = Join-Path $TestDrive 'TestFile.txt'
        Set-Content -Value 'Test File' -Path $testFilePath

        It 'Creates the expected request XML.' {
            $expectedResponse = @'
<bsvc:Put_Worker_Document_Request bsvc:version="v30.0" bsvc:Add_Only="false" xmlns:bsvc="urn:com.workday/bsvc"><bsvc:Worker_Document_Data><bsvc:Filename>DifferentFileName.txt</bsvc:Filename><!--Optional:--><bsvc:Comment>Test Comment</bsvc:Comment><bsvc:File>VGVzdCBGaWxlDQo=</bsvc:File><bsvc:Document_Category_Reference><bsvc:ID bsvc:type="WID">TestId</bsvc:ID></bsvc:Document_Category_Reference><bsvc:Worker_Reference><bsvc:ID bsvc:type="WID">1</bsvc:ID></bsvc:Worker_Reference><bsvc:Content_Type>text/plain</bsvc:Content_Type></bsvc:Worker_Document_Data></bsvc:Put_Worker_Document_Request>
'@
            $arguments = @{
                WorkerId = 1
                WorkerType = 'WID'
                Path = $testFilePath
                FileName = 'DifferentFileName.txt'
                CategoryType = 'WID'
                CategoryId = 'TestId'
                Comment = 'Test Comment'
            }
            $response = Set-WorkdayWorkerDocument @arguments

            $response.Xml.OuterXml | Should BeExactly $expectedResponse
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
  
        }
    }
}