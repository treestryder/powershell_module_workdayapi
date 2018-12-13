Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Set-WorkdayWorkerPhoto {
    InModuleScope WorkdayApi {

        Mock Invoke-WorkdayRequest {
            Mock_Invoke-WorkdayRequest_Echo @args
        }

        $testFilePath = Join-Path $TestDrive 'TestFile.txt'
        Set-Content -Value 'Test File' -Path $testFilePath

        It 'Creates the expected request XML.' {
            $expectedResponse = @'
<bsvc:Put_Worker_Photo_Request bsvc:version="v30.1" xmlns:bsvc="urn:com.workday/bsvc"><bsvc:Worker_Reference><bsvc:ID bsvc:type="WID">1</bsvc:ID></bsvc:Worker_Reference><bsvc:Worker_Photo_Data><bsvc:Filename>TestFile.txt</bsvc:Filename><bsvc:File>VGVzdCBGaWxlDQo=</bsvc:File></bsvc:Worker_Photo_Data></bsvc:Put_Worker_Photo_Request>
'@
            $arguments = @{
                WorkerId = 1
                WorkerType = 'WID'
                Path = $testFilePath
            }
            $response = Set-WorkdayWorkerPhoto @arguments

            $response.Xml.OuterXml | Should BeExactly $expectedResponse
            Assert-MockCalled Invoke-WorkdayRequest -Exactly 1
  
        }
    }
}