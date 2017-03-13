Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force

Describe Invoke-WorkdayRequest {
    InModuleScope WorkdayApi {

        It 'Returns the time from Workday using the API.' {
            $request = @'
    <bsvc:Server_Timestamp_Get xmlns:bsvc="urn:com.workday/bsvc" />
'@
            $response = Invoke-WorkdayRequest -Request $request -Uri (Get-WorkdayEndpoint -Endpoint Human_Resources)
            $response.Xml -is [XML] | Should Be $true
            $response.Xml.Server_Timestamp.Server_Timestamp_Data -match '^\d\d\d\d-\d\d-\d\d' | Should Be $true
        }
    }
}