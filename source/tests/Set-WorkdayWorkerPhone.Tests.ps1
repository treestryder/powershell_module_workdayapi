Get-Module WorkdayApi | Remove-Module -Force
Import-Module "$PsScriptRoot\..\WorkdayApi.psd1" -Force
Import-Module "$PsScriptRoot\Invoke-WorkdayRequestHelper.psm1" -Force -DisableNameChecking

Describe Set-WorkdayWorkerPhone {
    InModuleScope WorkdayApi {

        # Echo Request
        Mock Invoke-WorkdayRequest {
            Mock_Invoke-WorkdayRequest_Echo @args
        }

        Context 'Valid Input' {
            $response = Set-WorkdayWorkerPhone -WorkerId 1 -Number 12345678901 -Extension 1234 -Private -Secondary
            $x = [xml]$response.Xml
            $mcid = $x.Maintain_Contact_Information_for_Person_Event_Request.Maintain_Contact_Information_Data

            It 'References the correct worker.' {
                $mcid.Worker_Reference.ID.'#text' | Should BeExactly '1'
            }

            It 'Effective_Date' {
                $mcid.Effective_Date | Should BeExactly  (Get-Date).ToString( 'yyyy-MM-dd' )
            }

            It 'International_Phone_Code' {
                $mcid.Worker_Contact_Information_Data.Phone_Data.International_Phone_Code |
                    Should BeExactly '1'
            }

            It 'Correct Area_Code' {
                $mcid.Worker_Contact_Information_Data.Phone_Data.Area_Code |
                    Should BeExactly '234'
            }

            It 'Phone_Number' {
                $mcid.Worker_Contact_Information_Data.Phone_Data.Phone_Number |
                    Should BeExactly '567-8901'
            }

            It 'Phone_Extension' {
                $mcid.Worker_Contact_Information_Data.Phone_Data.Phone_Extension |
                    Should BeExactly '1234'
            }

            It 'Communication_Usage_Type_ID' {
                $mcid.Worker_Contact_Information_Data.Phone_Data.Usage_Data.Type_Data.Type_Reference.ID.'#text' |
                    Should BeExactly 'WORK'
            }

            It 'Phone_Device_Type_ID' {
                $mcid.Worker_Contact_Information_Data.Phone_Data.Phone_Device_Type_Reference.ID.'#text' |
                    Should BeExactly 'Landline'
            }

            It 'Public' {
                $mcid.Worker_Contact_Information_Data.Phone_Data.Usage_Data.Public |
                    Should BeExactly '0'
            }

            It 'Primary' {
                $mcid.Worker_Contact_Information_Data.Phone_Data.Usage_Data.Type_Data.Primary |
                    Should BeExactly '0'
            }

        }

<#
$ $mcid.Worker_Contact_Information_Data.Phone_Data.Usage_Data.Type_Data.Type_Reference.ID

type                        #text
----                        -----
Communication_Usage_Type_ID WORK



$ $mcid.Worker_Contact_Information_Data.Phone_Data.Usage_Data.Type_Data.Type_Reference.ID.'#text'
WORK
#>
        Context 'Invalid Input' {
            It 'Throws an exception when an invalid phone number is supplied.' {
                { Set-WorkdayWorkerPhone -WorkerId 1 -Number BadNumber } | Should Throw 'Invalid number: [BadNumber]'
            }
        }
    }
}