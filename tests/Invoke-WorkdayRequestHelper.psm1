

Set-WorkdayEndpoint -Endpoint Staffing        -Uri 'https://SERVICE.workday.com/ccx/service/TENANT/Staffing'
Set-WorkdayEndpoint -Endpoint Human_Resources -Uri 'https://SERVICE.workday.com/ccx/service/TENANT/Human_Resources'
Set-WorkdayEndpoint -Endpoint Integrations    -Uri 'https://SERVICE.workday.com/ccx/service/TENANT/Integrations'


# Echo Request
function Mock_Invoke-WorkdayRequest_Echo {
    param (
        $Request
    )
    [pscustomobject][ordered]@{
        Success    = $true
        Message  = ''
        Xml = [xml]$Request
    }
}


# Return an error
function Mock_Invoke-WorkdayRequest_ExampleError {
    [pscustomobject][ordered]@{
        Success = $false
        Message = 'SOAP-ENV:Client.validationError: Workday Request Error Example'
        Xml     = [xml]@'
<SOAP-ENV:Fault xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wd="urn:com.workday/bsvc">
    <faultcode>SOAP-ENV:Client.validationError</faultcode>
    <faultstring>Workday Request Error Example/bsvc</faultstring>
    <detail>
        <wd:Validation_Fault>
            <wd:Validation_Error>
                <wd:Message>Workday Request Error Example</wd:Message>
                <wd:Detail_Message></wd:Detail_Message>
                <wd:Xpath></wd:Xpath>
            </wd:Validation_Error>
        </wd:Validation_Fault>
    </detail>
</SOAP-ENV:Fault>
'@
    }
}


# Return a Good example
function Mock_Invoke-WorkdayRequest_ExampleWorker {
    [pscustomobject][ordered]@{
        Success    = $true
        Message  = ''
        Xml = [xml]@'
		<wd:Get_Workers_Response xmlns:wd="urn:com.workday/bsvc" wd:version="v25.1">
		<wd:Request_References>
			<wd:Worker_Reference wd:Descriptor="Example Worker (1)">
				<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
				<wd:ID wd:type="Employee_ID">1</wd:ID>
			</wd:Worker_Reference>
		</wd:Request_References>
		<wd:Response_Group>
			<wd:Include_Reference>1</wd:Include_Reference>
			<wd:Include_Personal_Information>1</wd:Include_Personal_Information>
			<wd:Include_Employment_Information>0</wd:Include_Employment_Information>
			<wd:Include_Compensation>0</wd:Include_Compensation>
			<wd:Include_Organizations>0</wd:Include_Organizations>
			<wd:Include_Roles>0</wd:Include_Roles>
		</wd:Response_Group>
		<wd:Response_Results>
			<wd:Total_Results>1</wd:Total_Results>
			<wd:Total_Pages>1</wd:Total_Pages>
			<wd:Page_Results>1</wd:Page_Results>
			<wd:Page>1</wd:Page>
		</wd:Response_Results>
		<wd:Response_Data>
			<wd:Worker>
				<wd:Worker_Reference wd:Descriptor="Example Worker (1)">
					<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
					<wd:ID wd:type="Employee_ID">1</wd:ID>
				</wd:Worker_Reference>
				<wd:Worker_Data>
					<wd:Worker_ID>1</wd:Worker_ID>
					<wd:User_ID>ExampleWorker@example.com</wd:User_ID>
					<wd:Personal_Data>
						<wd:Name_Data>
							<wd:Legal_Name_Data>
								<wd:Name_Detail_Data wd:Formatted_Name="Example Worker" wd:Reporting_Name="Worker, Example Middle">
									<wd:Country_Reference wd:Descriptor="United States of America">
										<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
										<wd:ID wd:type="ISO_3166-1_Alpha-2_Code">US</wd:ID>
										<wd:ID wd:type="ISO_3166-1_Alpha-3_Code">USA</wd:ID>
										<wd:ID wd:type="ISO_3166-1_Numeric-3_Code">840</wd:ID>
									</wd:Country_Reference>
									<wd:First_Name>Example</wd:First_Name>
									<wd:Middle_Name>Middle</wd:Middle_Name>
									<wd:Last_Name>Worker</wd:Last_Name>
								</wd:Name_Detail_Data>
							</wd:Legal_Name_Data>
							<wd:Preferred_Name_Data>
								<wd:Name_Detail_Data wd:Formatted_Name="Example Worker" wd:Reporting_Name="Worker, Example Middle">
									<wd:Country_Reference wd:Descriptor="United States of America">
										<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
										<wd:ID wd:type="ISO_3166-1_Alpha-2_Code">US</wd:ID>
										<wd:ID wd:type="ISO_3166-1_Alpha-3_Code">USA</wd:ID>
										<wd:ID wd:type="ISO_3166-1_Numeric-3_Code">840</wd:ID>
									</wd:Country_Reference>
									<wd:First_Name>Example</wd:First_Name>
									<wd:Middle_Name>Middle</wd:Middle_Name>
									<wd:Last_Name>Worker</wd:Last_Name>
								</wd:Name_Detail_Data>
							</wd:Preferred_Name_Data>
						</wd:Name_Data>
						<wd:Gender_Reference wd:Descriptor="Male">
							<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
							<wd:ID wd:type="Gender_Code">Male</wd:ID>
						</wd:Gender_Reference>
						<wd:Birth_Date>1960-01-01-07:00</wd:Birth_Date>
						<wd:Marital_Status_Reference wd:Descriptor="Married (United States of America)">
							<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
							<wd:ID wd:type="Marital_Status_ID">Married_United_States_of_America</wd:ID>
						</wd:Marital_Status_Reference>
						<wd:Marital_Status_Date>2000-01-01-07:00</wd:Marital_Status_Date>
						<wd:Disability_Status_Data>
							<wd:Disability_Reference wd:Descriptor="N/A (United States of America)">
								<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
								<wd:ID wd:type="Disability_ID">DISABILITY-6-71</wd:ID>
							</wd:Disability_Reference>
							<wd:Disability_Degree>0</wd:Disability_Degree>
							<wd:Disability_Remaining_Capacity>0</wd:Disability_Remaining_Capacity>
							<wd:Disability_FTE_Toward_Quota>0</wd:Disability_FTE_Toward_Quota>
							<wd:Disability_Status_Reference wd:Descriptor="DISABILITY_STATUS_REFERENCE-3-354">
								<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
								<wd:ID wd:type="Disability_Status_ID">DISABILITY_STATUS_REFERENCE-3-354</wd:ID>
							</wd:Disability_Status_Reference>
						</wd:Disability_Status_Data>
						<wd:Ethnicity_Reference wd:Descriptor="Purple (United States of America)">
							<wd:ID wd:type="WID">e20c9b6394e9107595745c28ac01495c</wd:ID>
							<wd:ID wd:type="Ethnicity_ID">00000000000000000000000000000000</wd:ID>
						</wd:Ethnicity_Reference>
						<wd:Hispanic_or_Latino>0</wd:Hispanic_or_Latino>
						<wd:Citizenship_Status_Reference wd:Descriptor="Citizen (United States of America)">
							<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
							<wd:ID wd:type="Citizenship_Status_Code">Citizen_United_States_of_America</wd:ID>
						</wd:Citizenship_Status_Reference>
						<wd:Military_Service_Data>
							<wd:Status_Reference wd:Descriptor="08 - Not a US Veteran (United States of America)">
								<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
								<wd:ID wd:type="Military_Status_ID">MILITARY_STATUS-6-14</wd:ID>
								<wd:ID wd:type="Armed_Forces_Status_ID">MILITARY_STATUS-6-14</wd:ID>
							</wd:Status_Reference>
							<wd:Military_Service_Reference wd:Descriptor="MILITARY_SERVICE_REFERENCE-3-3343">
								<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
								<wd:ID wd:type="Military_Service_ID">MILITARY_SERVICE_REFERENCE-3-3343</wd:ID>
							</wd:Military_Service_Reference>
						</wd:Military_Service_Data>
						<wd:Identification_Data>
							<wd:National_ID>
								<wd:National_ID_Reference wd:Descriptor="000-00-0000 (USA-SSN)">
									<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
								</wd:National_ID_Reference>
								<wd:National_ID_Data>
									<wd:ID>000000000</wd:ID>
									<wd:ID_Type_Reference wd:Descriptor="Social Security Number (SSN)">
										<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
										<wd:ID wd:type="National_ID_Type_Code">USA-SSN</wd:ID>
									</wd:ID_Type_Reference>
									<wd:Country_Reference wd:Descriptor="United States of America">
										<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
										<wd:ID wd:type="ISO_3166-1_Alpha-2_Code">US</wd:ID>
										<wd:ID wd:type="ISO_3166-1_Alpha-3_Code">USA</wd:ID>
										<wd:ID wd:type="ISO_3166-1_Numeric-3_Code">840</wd:ID>
									</wd:Country_Reference>
									<wd:Verification_Date>2015-07-28-07:00</wd:Verification_Date>
									<wd:Verified_By_Reference wd:Descriptor="First Last (2)">
										<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
										<wd:ID wd:type="Employee_ID">2</wd:ID>
									</wd:Verified_By_Reference>
								</wd:National_ID_Data>
								<wd:National_ID_Shared_Reference wd:Descriptor="NATIONAL_IDENTIFIER_REFERENCE-3-13830">
									<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
									<wd:ID wd:type="National_Identifier_Reference_ID">NATIONAL_IDENTIFIER_REFERENCE-3-13830</wd:ID>
								</wd:National_ID_Shared_Reference>
							</wd:National_ID>
							<wd:Custom_ID>
								<wd:Custom_ID_Reference wd:Descriptor="123">
									<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
								</wd:Custom_ID_Reference>
								<wd:Custom_ID_Data>
									<wd:ID>1</wd:ID>
									<wd:ID_Type_Reference wd:Descriptor="Badge ID">
										<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
										<wd:ID wd:type="Custom_ID_Type_ID">Badge_ID</wd:ID>
									</wd:ID_Type_Reference>
									<wd:Issued_Date>2015-07-31-07:00</wd:Issued_Date>
									<wd:Expiration_Date>2020-07-30-07:00</wd:Expiration_Date>
								</wd:Custom_ID_Data>
								<wd:Custom_ID_Shared_Reference wd:Descriptor="CUSTOM_IDENTIFIER_REFERENCE-3-20109">
									<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
									<wd:ID wd:type="Custom_Identifier_Reference_ID">CUSTOM_IDENTIFIER_REFERENCE-3-20109</wd:ID>
								</wd:Custom_ID_Shared_Reference>
							</wd:Custom_ID>
						</wd:Identification_Data>
						<wd:Contact_Data>
							<wd:Address_Data wd:Effective_Date="1900-01-01-08:00" wd:Address_Format_Type="Basic" wd:Formatted_Address="3510 Capital City Blvd.&amp;#xa;Lansing, MI 48906&amp;#xa;United States of America" wd:Defaulted_Business_Site_Address="1">
								<wd:Country_Reference wd:Descriptor="United States of America">
									<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
									<wd:ID wd:type="ISO_3166-1_Alpha-2_Code">US</wd:ID>
									<wd:ID wd:type="ISO_3166-1_Alpha-3_Code">USA</wd:ID>
									<wd:ID wd:type="ISO_3166-1_Numeric-3_Code">840</wd:ID>
								</wd:Country_Reference>
								<wd:Last_Modified>2014-10-08T12:24:19.493-07:00</wd:Last_Modified>
								<wd:Address_Line_Data wd:Type="ADDRESS_LINE_1" wd:Descriptor="Address Line 1">3510 Capital City Blvd.</wd:Address_Line_Data>
								<wd:Municipality>Lansing</wd:Municipality>
								<wd:Country_Region_Reference wd:Descriptor="Michigan">
									<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
									<wd:ID wd:type="Country_Region_ID">USA-MI</wd:ID>
								</wd:Country_Region_Reference>
								<wd:Postal_Code>48906</wd:Postal_Code>
								<wd:Usage_Data wd:Public="1">
									<wd:Type_Data wd:Primary="1">
										<wd:Type_Reference wd:Descriptor="Work">
											<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
											<wd:ID wd:type="Communication_Usage_Type_ID">WORK</wd:ID>
										</wd:Type_Reference>
									</wd:Type_Data>
								</wd:Usage_Data>
								<wd:Address_Reference wd:Descriptor="ADDRESS_REFERENCE-6-153">
									<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
									<wd:ID wd:type="Address_ID">ADDRESS_REFERENCE-6-153</wd:ID>
								</wd:Address_Reference>
							</wd:Address_Data>
							<wd:Phone_Data wd:Formatted_Phone="+1 (517) 123-4567 x4321">
								<wd:Country_ISO_Code>MSR</wd:Country_ISO_Code>
								<wd:International_Phone_Code>1</wd:International_Phone_Code>
								<wd:Area_Code>517</wd:Area_Code>
								<wd:Phone_Number>123-4567</wd:Phone_Number>
								<wd:Phone_Extension>4321</wd:Phone_Extension>
								<wd:Phone_Device_Type_Reference wd:Descriptor="Landline">
									<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
									<wd:ID wd:type="Phone_Device_Type_ID">Landline</wd:ID>
								</wd:Phone_Device_Type_Reference>
								<wd:Usage_Data wd:Public="1">
									<wd:Type_Data wd:Primary="true">
										<wd:Type_Reference wd:Descriptor="Work">
											<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
											<wd:ID wd:type="Communication_Usage_Type_ID">WORK</wd:ID>
										</wd:Type_Reference>
									</wd:Type_Data>
								</wd:Usage_Data>
							</wd:Phone_Data>
							<wd:Email_Address_Data>
								<wd:Email_Address>test@example.com</wd:Email_Address>
								<wd:Usage_Data wd:Public="1">
									<wd:Type_Data wd:Primary="true">
										<wd:Type_Reference wd:Descriptor="Work">
											<wd:ID wd:type="WID">1f27f250dfaa4724ab1e1617174281e4</wd:ID>
											<wd:ID wd:type="Communication_Usage_Type_ID">WORK</wd:ID>
										</wd:Type_Reference>
									</wd:Type_Data>
								</wd:Usage_Data>
							</wd:Email_Address_Data>
						</wd:Contact_Data>
						<wd:Tobacco_Use>0</wd:Tobacco_Use>
					</wd:Personal_Data>
					<wd:Employment_Data>
						<wd:Worker_Job_Data wd:Primary_Job="1">
							<wd:Position_Organizations_Data>
								<wd:Position_Organization_Data>
									<wd:Organization_Reference>
										<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
										<wd:ID wd:type="Business_Unit_ID">BUSINESS_UNIT-3-2</wd:ID>
									</wd:Organization_Reference>
									<wd:Organization_Data>
										<wd:Organization_Reference_ID>BUSINESS_UNIT-3-2</wd:Organization_Reference_ID>
										<wd:Organization_Name>Business Unit Organization Name</wd:Organization_Name>
										<wd:Organization_Type_Reference>
											<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
											<wd:ID wd:type="Organization_Type_ID">BUSINESS_UNIT</wd:ID>
										</wd:Organization_Type_Reference>
										<wd:Organization_Support_Role_Data>
											<wd:Organization_Support_Role>
												<wd:Organization_Role_Reference>
													<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
													<wd:ID wd:type="Organization_Role_ID">Integration_Partner</wd:ID>
												</wd:Organization_Role_Reference>
												<wd:Organization_Role_Data>
													<wd:Worker_Reference>
														<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
														<wd:ID wd:type="Employee_ID">14970</wd:ID>
													</wd:Worker_Reference>
													<wd:Assignment_From>Assigned</wd:Assignment_From>
												</wd:Organization_Role_Data>
											</wd:Organization_Support_Role>
										</wd:Organization_Support_Role_Data>
										<wd:Used_in_Change_Organization_Assignments>1</wd:Used_in_Change_Organization_Assignments>
									</wd:Organization_Data>
								</wd:Position_Organization_Data>
							</wd:Position_Organizations_Data>
						</wd:Worker_Job_Data>
					</wd:Employment_Data>
				</wd:Worker_Data>
			</wd:Worker>
		</wd:Response_Data>
	</wd:Get_Workers_Response>
'@
    }
}

function Mock_Invoke-WorkdayRequest_ExampleIntegration {
    [pscustomobject][ordered]@{
        Success    = $true
        Message  = ''
        Xml = [xml]@'
<wd:Launch_Integration_Event_Response xmlns:wd="urn:com.workday/bsvc" wd:version="v26.0" wd:Debug_Mode="0">
	<wd:Integration_Event>
		<wd:Integration_Event_Reference wd:Descriptor="Test Descriptor">
			<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
			<wd:ID wd:type="Background_Process_Instance_ID">INTEGRATION_ESB_INVOCATION-0-00000</wd:ID>
		</wd:Integration_Event_Reference>
		<wd:Integration_Event_Data>
			<wd:Integration_System_Reference wd:Descriptor="Integration">
				<wd:ID wd:type="WID">00000000000000000000000000000000</wd:ID>
			</wd:Integration_System_Reference>
			<wd:Initiated_DateTime>2016-04-12T15:22:27.342-07:00</wd:Initiated_DateTime>
		</wd:Integration_Event_Data>
	</wd:Integration_Event>
</wd:Launch_Integration_Event_Response>

'@
    }
}

# Return a Good example
function Mock_Invoke-WorkdayRequest_ExampleIntegrationEvent {
    [pscustomobject][ordered]@{
        Success    = $true
        Message  = ''
        Xml = [xml]@'
<wd:Get_Integration_Events_Response xmlns:wd="urn:com.workday/bsvc" wd:version="v26.0">
	<wd:Request_References>
		<wd:Integration_Event_Reference wd:Descriptor="Test Descriptor">
		</wd:Integration_Event_Reference>
	</wd:Request_References>
	<wd:Response_Data>
		<wd:Integration_Event>
			<wd:Integration_Event_Data>
				<wd:Initiated_DateTime>2016-04-12T15:22:27.342-07:00</wd:Initiated_DateTime>
				<wd:Integration_Response_Message>Integration Completed.</wd:Integration_Response_Message>
				<wd:Completed_DateTime>2016-04-12T15:24:38.308-07:00</wd:Completed_DateTime>
                <wd:Percent_Complete>1</wd:Percent_Complete>
            </wd:Integration_Event_Data>
		</wd:Integration_Event>
	</wd:Response_Data>
</wd:Get_Integration_Events_Response>
'@
    }
}