function ConvertFrom-WorkdayWorkerXml {
<#
.Synopsis
   Converts Workday Worker XML into a custom object.
#>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    Param (
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        [xml[]]$Xml
    )

    Begin {
        $WorkerObjectTemplate = [pscustomobject][ordered]@{
            WorkerWid             = $null
            WorkerDescriptor      = $null
            PreferredName         = $null
            FirstName             = $null
            LastName              = $null
            WorkerType            = $null
            WorkerId              = $null
            UserId                = $null
            OtherId               = $null
            Phone                 = $null
            Email                 = $null
            BusinessTitle         = $null
            Location              = $null
            WorkSpace             = $null
            WorkerTypeReference   = $null
            Manager               = $null
            XML                   = $null
        }
        $WorkerObjectTemplate.PsObject.TypeNames.Insert(0, "Workday.Worker")
    }

    Process {
        foreach ($elements in $Xml) {
            foreach ($x in $elements.GetElementsByTagName('wd:Worker')) {
                $o = $WorkerObjectTemplate.PsObject.Copy()

                $referenceId = $x.Worker_Reference.ID | Where-Object {$_.type -ne 'WID'}

                $o.WorkerWid        = $x.Worker_Reference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty '#text'
                $o.WorkerDescriptor = $x.Worker_Reference.Descriptor
                $o.PreferredName    = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Formatted_Name
                $o.FirstName        = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.First_Name
                $o.LastName         = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Last_Name
                $o.WorkerType       = $referenceId.type
                $o.WorkerId         = $referenceId.'#text'
                $o.XML              = [XML]$x.OuterXml

                if ($IncludePersonal) {
                    $o.Phone   = @(Get-WorkdayWorkerPhone -WorkerXml $x.OuterXml)
                    $o.Email   = @(Get-WorkdayWorkerEmail -WorkerXml $x.OuterXml)
                    $o.OtherId = @(Get-WorkdayWorkerOtherId -WorkerXml $x.OuterXml)
                    $o.UserId  = $x.Worker_Data.User_ID
                }

                if ($IncludeWork) {
                    $o.BusinessTitle = $x.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Business_Title
                    $o.Location = $x.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Business_Site_Summary_Data.Location_Reference.Descriptor
                    $o.WorkSpace = $x.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Work_Space__Reference.Descriptor
                    $o.WorkerTypeReference = $x.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Worker_Type_Reference.Descriptor
                    $o.Manager = $x.Worker_Data.Employment_Data.Worker_Job_Data.Position_Data.Manager_as_of_last_detected_manager_change_Reference.ID |
                        Where-Object {$_.type -ne 'WID'} |
                            Select-Object @{Name='WorkerType';Expression={$_.type}}, @{Name='WorkerID';Expression={$_.'#text'}}
                }

                Write-Output $o
            }
        }
    }
}
