function Set-WorkdayWorkerPhone {
<#
.SYNOPSIS
    Will eventually set Custom_ID_Type_ID "Badge_ID".


.NOTES

    HumanResources.Human_ResourcesPortClient client = WorkdayService.HumanResourcesHelper.GetNewHRClient();
    Change_Other_IDs_Business_Process_DataType dataType = new Change_Other_IDs_Business_Process_DataType();
    dataType.Worker_Reference = badge.WorkerType.Worker_Reference;
    dataType.Custom_Identification_Data = new Custom_Identification_DataType();
    dataType.Custom_Identification_Data.Replace_All = false;
    dataType.Custom_Identification_Data.Replace_AllSpecified = true;

    Custom_IDType customIDType = new Custom_IDType();
    customIDType.Delete = false;
    customIDType.DeleteSpecified = true;
    customIDType.Custom_ID_Data = new Custom_ID_DataType();

    customIDType.Custom_ID_Data.ID = badge.AccessControlBadgeID;
    customIDType.Custom_ID_Data.Issued_Date = badge.IssueDate; // = "Badge_ID";
    customIDType.Custom_ID_Data.Issued_DateSpecified = true;
    customIDType.Custom_ID_Data.Expiration_Date = badge.ExpirationDate;
    customIDType.Custom_ID_Data.Expiration_DateSpecified = true;

    customIDType.Custom_ID_Data.ID_Type_Reference = new Custom_ID_TypeObjectType();
    customIDType.Custom_ID_Data.ID_Type_Reference.ID = new Custom_ID_TypeObjectIDType[1];
    customIDType.Custom_ID_Data.ID_Type_Reference.ID[0] = new Custom_ID_TypeObjectIDType() { type = "Custom_ID_Type_ID", Value = "Badge_ID" };

    dataType.Custom_Identification_Data.Custom_ID = new Custom_IDType[1];
    dataType.Custom_Identification_Data.Custom_ID[0] = new Custom_IDType();
    dataType.Custom_Identification_Data.Custom_ID[0].Custom_ID_Data = new Custom_ID_DataType();
    dataType.Custom_Identification_Data.Custom_ID[0].Custom_ID_Data = customIDType.Custom_ID_Data;

    dataType.Custom_Identification_Data.Replace_All = true;
    dataType.Custom_Identification_Data.Replace_AllSpecified = true;

    request.Change_Other_IDs_Data = dataType;

    Change_Other_IDs_ResponseType response = new Change_Other_IDs_ResponseType();
    response = client.Change_Other_IDs(request);

#>

    $request = @'
<bsvc:Change_Other_IDs_Request bsvc:version="string" xmlns:bsvc="urn:com.workday/bsvc">
  <!--Optional:-->
  <bsvc:Business_Process_Parameters>
    <!--Optional:-->
    <bsvc:Auto_Complete>false</bsvc:Auto_Complete>
    <!--Optional:-->
    <bsvc:Run_Now>true</bsvc:Run_Now>
    <!--Optional:-->
    <bsvc:Comment_Data>
      <!--Optional:-->
      <bsvc:Comment>string</bsvc:Comment>
      <!--Optional:-->
      <bsvc:Worker_Reference bsvc:Descriptor="string">
        <!--Zero or more repetitions:-->
        <bsvc:ID bsvc:type="string">string</bsvc:ID>
      </bsvc:Worker_Reference>
    </bsvc:Comment_Data>
    <!--Zero or more repetitions:-->
    <bsvc:Business_Process_Attachment_Data>
      <bsvc:File_Name>string</bsvc:File_Name>
      <!--Optional:-->
      <bsvc:Event_Attachment_Description>string</bsvc:Event_Attachment_Description>
      <!--Optional:-->
      <bsvc:Event_Attachment_Category_Reference bsvc:Descriptor="string">
        <!--Zero or more repetitions:-->
        <bsvc:ID bsvc:type="string">string</bsvc:ID>
      </bsvc:Event_Attachment_Category_Reference>
      <!--Optional:-->
      <bsvc:File>Y3Vt</bsvc:File>
      <!--Optional:-->
      <bsvc:Content_Type>string</bsvc:Content_Type>
    </bsvc:Business_Process_Attachment_Data>
  </bsvc:Business_Process_Parameters>
  <bsvc:Change_Other_IDs_Data>
    <bsvc:Worker_Reference bsvc:Descriptor="string">
      <!--Zero or more repetitions:-->
      <bsvc:ID bsvc:type="string">string</bsvc:ID>
    </bsvc:Worker_Reference>
    <bsvc:Custom_Identification_Data bsvc:Replace_All="true">
      <!--Zero or more repetitions:-->
      <bsvc:Custom_ID bsvc:Delete="true">
        <!--Optional:-->
        <bsvc:Custom_ID_Reference bsvc:Descriptor="string">
          <!--Zero or more repetitions:-->
          <bsvc:ID bsvc:type="string">string</bsvc:ID>
        </bsvc:Custom_ID_Reference>
        <!--Optional:-->
        <bsvc:Custom_ID_Data>
          <!--Optional:-->
          <bsvc:ID>string</bsvc:ID>
          <!--Optional:-->
          <bsvc:ID_Type_Reference bsvc:Descriptor="string">
            <!--Zero or more repetitions:-->
            <bsvc:ID bsvc:type="string">string</bsvc:ID>
          </bsvc:ID_Type_Reference>
          <!--Optional:-->
          <bsvc:Issued_Date>2014-06-09+00:00</bsvc:Issued_Date>
          <!--Optional:-->
          <bsvc:Expiration_Date>2008-11-15</bsvc:Expiration_Date>
          <!--Optional:-->
          <bsvc:Organization_ID_Reference bsvc:Descriptor="string">
            <!--Zero or more repetitions:-->
            <bsvc:ID bsvc:type="string">string</bsvc:ID>
          </bsvc:Organization_ID_Reference>
          <!--Optional:-->
          <bsvc:Custom_Description>string</bsvc:Custom_Description>
        </bsvc:Custom_ID_Data>
        <!--Optional:-->
        <bsvc:Custom_ID_Shared_Reference bsvc:Descriptor="string">
          <!--Zero or more repetitions:-->
          <bsvc:ID bsvc:type="string">string</bsvc:ID>
        </bsvc:Custom_ID_Shared_Reference>
      </bsvc:Custom_ID>
    </bsvc:Custom_Identification_Data>
  </bsvc:Change_Other_IDs_Data>
</bsvc:Change_Other_IDs_Request>
'@

    throw "Set-WorkdayWorkerPhone has not been implemented yet."
}