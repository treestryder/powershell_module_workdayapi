function Get-WorkdayToAdData {
    <#
    .SYNOPSIS
        Converts Get-WorkdayWorker output into "INT011 WD to AD - DT" format.
    .NOTES
        This is a first attempt at pulling data which is normally gathered by
        an integration called "INT011 WD to AD - DT". Though I suspect this
        format is specific to my company, I add this as some may find it
        valuable. In fact, some of this should probably be moved
        into Get-WorkdayWorker.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Position=0,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='IndividualWorker')]
		[ValidatePattern ('^$|^[a-zA-Z0-9\-]{1,32}$')]
        [string]$WorkerId,
        [Parameter(Position=1,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='IndividualWorker')]
		[ValidateSet('WID', 'Contingent_Worker_ID', 'Employee_ID')]
		[string]$WorkerType = 'Employee_ID',
		[string]$Human_ResourcesUri,
		[string]$Username,
		[string]$Password,
        [switch]$Force,
        # Adds a "Worker" Property containing the full Worker object.
        [switch]$PassThru
    )

    begin {
        $objectTemplate = 0 | select 'ADD or CHANGE','Employee or Contingent Worker Number','First Name','Last Name','Preferred First Name','Preferred Last Name','User Name','Work Phone','Job Title','Employee or Contingent Worker Type','Worker Type','Worker SubType','Department (LOB)','Sub Department','Location (Building)','Location(Workspace)','Badge Id','Supervisor Name','Supervisor Employee Id','Matrix Manager Name (for Team Members)','Hire Date','Termination Date','Requires Cisco Phone'

        filter ParseWorker {
            $w = $_
            if ($w.psobject.TypeNames -contains 'WorkdayResponse') {
                Write-Error ('Input object was not of type WorkdayResponse: {0}' -f $w.psobject.TypeNames)
                continue
            }

            $o = $objectTemplate.psobject.Copy()
            if ($PassThru) {
                $o = Add-Member -InputObject $o -MemberType NoteProperty -Name Worker -Value $w -PassThru
            }
            $o.'ADD or CHANGE' = ''
            $o.'Employee or Contingent Worker Number' = $w.WorkerId
            $o.'First Name' = $w.Xml.Worker.Worker_Data.Personal_Data.Name_Data.Legal_Name_Data.Name_Detail_Data.First_Name
            $o.'Last Name' = $w.Xml.Worker.Worker_Data.Personal_Data.Name_Data.Legal_Name_Data.Name_Detail_Data.Last_Name
            $o.'Preferred First Name' = $w.FirstName
            $o.'Preferred Last Name' = $w.LastName
            $o.'User Name' = $w.Xml.Worker.Worker_Data.User_ID
            $o.'Work Phone' = $w.Phone | where { $_.UsageType -like 'Work' -and $_.Primary -and $_.Public } | select -ExpandProperty Number -First 1
            $o.'Badge ID' = $w.OtherID | where { $_.Type -eq 'Badge_ID' } | select -ExpandProperty Id -First 1
            $o.'Job Title' = $w.JobProfileName  -replace '^.+?-',''
            $o.'Employee or Contingent Worker Type' = $w.Xml.Worker.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Worker_Type_Reference.ID | where { $_.type -eq 'Employee_Type_ID' } | select -ExpandProperty '#text' -First 1
            $o.'Worker Type' = if ($w.Xml.Worker.Worker_Reference.ID | where { $_.type -eq 'Employee_ID' } ) {'Employee'} else {'Contingent Worker'}
            $o.'Worker SubType' = $w.Xml.Worker.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Worker_Type_Reference.Descriptor
            # Could not find Department.
            # <xsl:value-of select="ws:Additional_Information/ws:Department" />
            $o.'Department (LOB)' = 'Unimplemented'
            # Could not find Subdepartment.
            # <xsl:value-of select="ws:Additional_Information/ws:SubDepartment" />
            $o.'Sub Department' = 'Unimplemented'
            $o.'Location (Building)' = $w.Location
            $o.'Location(Workspace)' = $w.Workspace
            $supervisorDescriptor = $w.Xml.Worker.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Manager_as_of_last_detected_manager_change_Reference.Descriptor
            $o.'Supervisor Name' = if ($supervisorDescriptor -match '(^.+)\s\(') {
                $Matches[1]
            }
            else {
                $supervisorDescriptor
            }
            $o.'Supervisor Employee Id' = $w.Xml.Worker.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Manager_as_of_last_detected_manager_change_Reference.ID | where { $_.type -eq 'Employee_ID' } | select -ExpandProperty '#text' -First 1
            # Have not found Matrix Manager.
            $o.'Matrix Manager Name (for Team Members)' = $null
            $hireDate = $w.Xml.Worker.Worker_Data.Employment_Data.Worker_Status_Data.Hire_Date
            $o.'Hire Date' = if ($hireDate.length -ge 10) { $hireDate.Substring(0,10) }
            Write-Output $o
        }
    }

    process {
        Get-WorkdayWorker -WorkerId:$WorkerId -WorkerType:$WorkerType -Human_ResourcesUri:$Human_ResourcesUri -Username:$Username -Password:$Password -Force:$Force -IncludePersonal -IncludeWork |
            ParseWorker |
                Write-Output
    }
}
