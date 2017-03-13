function Get-WorkdayWorker {
	[CmdletBinding()]
	param (
		[string]$EmployeeId,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Uri,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Username,
		[Parameter(Mandatory = $true)]
		[string]$Password
	)

<#
	ORIGINAL EXAMPLE
<bsvc:Get_Workers_Request bsvc:version="string" xmlns:bsvc="urn:com.workday/bsvc">
  <!--Optional:-->
  <bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false">
    <!--1 or more repetitions:-->
    <bsvc:Worker_Reference bsvc:Descriptor="string">
      <!--Zero or more repetitions:-->
      <bsvc:ID bsvc:type="string">string</bsvc:ID>
    </bsvc:Worker_Reference>
  </bsvc:Request_References>
  <!--Optional:-->
  <bsvc:Request_Criteria>
    <!--Zero or more repetitions:-->
    <bsvc:Transaction_Log_Criteria_Data>
      <!--Optional:-->
      <bsvc:Transaction_Date_Range_Data>
        <!--Optional:-->
        <bsvc:Updated_From>2007-10-26T06:36:28</bsvc:Updated_From>
        <!--Optional:-->
        <bsvc:Updated_Through>2004-02-14T18:44:14</bsvc:Updated_Through>
        <!--Optional:-->
        <bsvc:Effective_From>2018-11-01T05:36:46+00:00</bsvc:Effective_From>
        <!--Optional:-->
        <bsvc:Effective_Through>2013-05-22T01:02:49+00:00</bsvc:Effective_Through>
      </bsvc:Transaction_Date_Range_Data>
      <!--You have a CHOICE of the next 2 items at this level-->
      <!--Optional:-->
      <bsvc:Transaction_Type_References>
        <!--Zero or more repetitions:-->
        <bsvc:Transaction_Type_Reference bsvc:Descriptor="string">
          <!--Zero or more repetitions:-->
          <bsvc:ID bsvc:type="string">string</bsvc:ID>
        </bsvc:Transaction_Type_Reference>
      </bsvc:Transaction_Type_References>
      <!--Optional:-->
      <bsvc:Subscriber_Reference bsvc:Descriptor="string">
        <!--Zero or more repetitions:-->
        <bsvc:ID bsvc:type="string">string</bsvc:ID>
      </bsvc:Subscriber_Reference>
    </bsvc:Transaction_Log_Criteria_Data>
    <!--Zero or more repetitions:-->
    <bsvc:Organization_Reference bsvc:Descriptor="string">
      <!--Zero or more repetitions:-->
      <bsvc:ID bsvc:type="string">string</bsvc:ID>
    </bsvc:Organization_Reference>
    <!--Zero or more repetitions:-->
    <bsvc:Country_Reference bsvc:Descriptor="string">
      <!--Zero or more repetitions:-->
      <bsvc:ID bsvc:type="string">string</bsvc:ID>
    </bsvc:Country_Reference>
    <!--Optional:-->
    <bsvc:Include_Subordinate_Organizations>true</bsvc:Include_Subordinate_Organizations>
    <!--Zero or more repetitions:-->
    <bsvc:Position_Reference bsvc:Descriptor="string">
      <!--Zero or more repetitions:-->
      <bsvc:ID bsvc:type="string">string</bsvc:ID>
    </bsvc:Position_Reference>
    <!--Optional:-->
    <bsvc:Event_Reference bsvc:Descriptor="string">
      <!--Zero or more repetitions:-->
      <bsvc:ID bsvc:type="string">string</bsvc:ID>
    </bsvc:Event_Reference>
    <!--Zero or more repetitions:-->
    <bsvc:Benefit_Plan_Reference bsvc:Descriptor="string">
      <!--Zero or more repetitions:-->
      <bsvc:ID bsvc:type="string">string</bsvc:ID>
    </bsvc:Benefit_Plan_Reference>
    <!--Optional:-->
    <bsvc:Field_And_Parameter_Criteria_Data>
      <!--1 or more repetitions:-->
      <bsvc:Provider_Reference bsvc:Descriptor="string">
        <!--Zero or more repetitions:-->
        <bsvc:ID bsvc:type="string">string</bsvc:ID>
      </bsvc:Provider_Reference>
    </bsvc:Field_And_Parameter_Criteria_Data>
    <!--Zero or more repetitions:-->
    <bsvc:National_ID_Criteria_Data>
      <bsvc:Identifier_ID>string</bsvc:Identifier_ID>
      <!--You have a CHOICE of the next 2 items at this level-->
      <bsvc:National_ID_Type_Reference bsvc:Descriptor="string">
        <!--Zero or more repetitions:-->
        <bsvc:ID bsvc:type="string">string</bsvc:ID>
      </bsvc:National_ID_Type_Reference>
      <bsvc:Country_Reference bsvc:Descriptor="string">
        <!--Zero or more repetitions:-->
        <bsvc:ID bsvc:type="string">string</bsvc:ID>
      </bsvc:Country_Reference>
    </bsvc:National_ID_Criteria_Data>
    <!--Optional:-->
    <bsvc:Exclude_Inactive_Workers>false</bsvc:Exclude_Inactive_Workers>
    <!--Optional:-->
    <bsvc:Exclude_Employees>false</bsvc:Exclude_Employees>
    <!--Optional:-->
    <bsvc:Exclude_Contingent_Workers>false</bsvc:Exclude_Contingent_Workers>
  </bsvc:Request_Criteria>
  <!--Optional:-->
  <bsvc:Response_Filter>
    <!--Optional:-->
    <bsvc:As_Of_Effective_Date>2016-01-01</bsvc:As_Of_Effective_Date>
    <!--Optional:-->
    <bsvc:As_Of_Entry_DateTime>2012-01-07T19:42:56</bsvc:As_Of_Entry_DateTime>
    <!--Optional:-->
    <bsvc:Page>1000.00</bsvc:Page>
    <!--Optional:-->
    <bsvc:Count>1000.00</bsvc:Count>
  </bsvc:Response_Filter>
  <!--Optional:-->
  <bsvc:Response_Group>
    <!--Optional:-->
    <bsvc:Include_Reference>true</bsvc:Include_Reference>
    <!--Optional:-->
    <bsvc:Include_Personal_Information>true</bsvc:Include_Personal_Information>
    <!--Optional:-->
    <bsvc:Include_Additional_Jobs>true</bsvc:Include_Additional_Jobs>
    <!--Optional:-->
    <bsvc:Include_Employment_Information>false</bsvc:Include_Employment_Information>
    <!--Optional:-->
    <bsvc:Include_Compensation>false</bsvc:Include_Compensation>
    <!--Optional:-->
    <bsvc:Include_Organizations>true</bsvc:Include_Organizations>
    <!--Optional:-->
    <bsvc:Exclude_Organization_Support_Role_Data>false</bsvc:Exclude_Organization_Support_Role_Data>
    <!--Optional:-->
    <bsvc:Exclude_Location_Hierarchies>false</bsvc:Exclude_Location_Hierarchies>
    <!--Optional:-->
    <bsvc:Exclude_Cost_Centers>false</bsvc:Exclude_Cost_Centers>
    <!--Optional:-->
    <bsvc:Exclude_Cost_Center_Hierarchies>false</bsvc:Exclude_Cost_Center_Hierarchies>
    <!--Optional:-->
    <bsvc:Exclude_Companies>true</bsvc:Exclude_Companies>
    <!--Optional:-->
    <bsvc:Exclude_Company_Hierarchies>true</bsvc:Exclude_Company_Hierarchies>
    <!--Optional:-->
    <bsvc:Exclude_Matrix_Organizations>false</bsvc:Exclude_Matrix_Organizations>
    <!--Optional:-->
    <bsvc:Exclude_Pay_Groups>true</bsvc:Exclude_Pay_Groups>
    <!--Optional:-->
    <bsvc:Exclude_Regions>false</bsvc:Exclude_Regions>
    <!--Optional:-->
    <bsvc:Exclude_Region_Hierarchies>true</bsvc:Exclude_Region_Hierarchies>
    <!--Optional:-->
    <bsvc:Exclude_Supervisory_Organizations>false</bsvc:Exclude_Supervisory_Organizations>
    <!--Optional:-->
    <bsvc:Exclude_Teams>false</bsvc:Exclude_Teams>
    <!--Optional:-->
    <bsvc:Exclude_Custom_Organizations>true</bsvc:Exclude_Custom_Organizations>
    <!--Optional:-->
    <bsvc:Include_Roles>false</bsvc:Include_Roles>
    <!--Optional:-->
    <bsvc:Include_Management_Chain_Data>true</bsvc:Include_Management_Chain_Data>
    <!--Optional:-->
    <bsvc:Include_Multiple_Managers_in_Management_Chain_Data>true</bsvc:Include_Multiple_Managers_in_Management_Chain_Data>
    <!--Optional:-->
    <bsvc:Include_Benefit_Enrollments>false</bsvc:Include_Benefit_Enrollments>
    <!--Optional:-->
    <bsvc:Include_Benefit_Eligibility>false</bsvc:Include_Benefit_Eligibility>
    <!--Optional:-->
    <bsvc:Include_Related_Persons>true</bsvc:Include_Related_Persons>
    <!--Optional:-->
    <bsvc:Include_Qualifications>false</bsvc:Include_Qualifications>
    <!--Optional:-->
    <bsvc:Include_Employee_Review>false</bsvc:Include_Employee_Review>
    <!--Optional:-->
    <bsvc:Include_Goals>true</bsvc:Include_Goals>
    <!--Optional:-->
    <bsvc:Include_Development_Items>true</bsvc:Include_Development_Items>
    <!--Optional:-->
    <bsvc:Include_Skills>true</bsvc:Include_Skills>
    <!--Optional:-->
    <bsvc:Include_Photo>true</bsvc:Include_Photo>
    <!--Optional:-->
    <bsvc:Include_Worker_Documents>false</bsvc:Include_Worker_Documents>
    <!--Optional:-->
    <bsvc:Include_Transaction_Log_Data>false</bsvc:Include_Transaction_Log_Data>
    <!--Optional:-->
    <bsvc:Include_Succession_Profile>false</bsvc:Include_Succession_Profile>
    <!--Optional:-->
    <bsvc:Include_Talent_Assessment>false</bsvc:Include_Talent_Assessment>
    <!--Optional:-->
    <bsvc:Include_Employee_Contract_Data>true</bsvc:Include_Employee_Contract_Data>
    <!--Optional:-->
    <bsvc:Include_Collective_Agreement_Data>true</bsvc:Include_Collective_Agreement_Data>
    <!--Optional:-->
    <bsvc:Include_Probation_Period_Data>false</bsvc:Include_Probation_Period_Data>
    <!--Optional:-->
    <bsvc:Include_Feedback_Received>true</bsvc:Include_Feedback_Received>
    <!--Optional:-->
    <bsvc:Include_User_Account>true</bsvc:Include_User_Account>
    <!--Optional:-->
    <bsvc:Include_Career>true</bsvc:Include_Career>
    <!--Optional:-->
    <bsvc:Include_Account_Provisioning>true</bsvc:Include_Account_Provisioning>
    <!--Optional:-->
    <bsvc:Include_Background_Check_Data>false</bsvc:Include_Background_Check_Data>
    <!--Optional:-->
    <bsvc:Include_Contingent_Worker_Tax_Authority_Form_Information>true</bsvc:Include_Contingent_Worker_Tax_Authority_Form_Information>
    <!--Optional:-->
    <bsvc:Exclude_Funds>true</bsvc:Exclude_Funds>
    <!--Optional:-->
    <bsvc:Exclude_Fund_Hierarchies>true</bsvc:Exclude_Fund_Hierarchies>
    <!--Optional:-->
    <bsvc:Exclude_Grants>true</bsvc:Exclude_Grants>
    <!--Optional:-->
    <bsvc:Exclude_Grant_Hierarchies>false</bsvc:Exclude_Grant_Hierarchies>
    <!--Optional:-->
    <bsvc:Exclude_Business_Units>true</bsvc:Exclude_Business_Units>
    <!--Optional:-->
    <bsvc:Exclude_Business_Unit_Hierarchies>false</bsvc:Exclude_Business_Unit_Hierarchies>
    <!--Optional:-->
    <bsvc:Exclude_Programs>true</bsvc:Exclude_Programs>
    <!--Optional:-->
    <bsvc:Exclude_Program_Hierarchies>true</bsvc:Exclude_Program_Hierarchies>
    <!--Optional:-->
    <bsvc:Exclude_Gifts>true</bsvc:Exclude_Gifts>
    <!--Optional:-->
    <bsvc:Exclude_Gift_Hierarchies>true</bsvc:Exclude_Gift_Hierarchies>
  </bsvc:Response_Group>
</bsvc:Get_Workers_Request>
#>

	$request = [xml]@'
<bsvc:Get_Workers_Request xmlns:bsvc="urn:com.workday/bsvc">
  <bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false">
	<bsvc:Worker_Reference>
		<bsvc:ID bsvc:type="Employee_ID">employeeId</bsvc:ID>
	</bsvc:Worker_Reference>
  </bsvc:Request_References>
</bsvc:Get_Workers_Request>
'@

	$request.Get_Workers_Request.Request_References.Worker_Reference.ID.InnerText = $EmployeeId

	Invoke-WorkdayApiRequest -Request $request -Uri $Uri -Username $Username -Password $Password | Write-Output
}