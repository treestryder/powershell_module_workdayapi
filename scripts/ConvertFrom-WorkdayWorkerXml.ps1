function ConvertFrom-WorkdayWorkerXml {
<#
.Synopsis
   Converts Workday Worker XML into a custom object.
#>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    Param (
        # Param1 help description
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        $Xml
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
            XML                   = $null
        }
        $WorkerObjectTemplate.PsObject.TypeNames.Insert(0, "Workday.Worker")
    }

    Process {
        foreach ($x in $Xml) {
            $o = $WorkerObjectTemplate.PsObject.Copy()

            $referenceId = $x.Worker_Reference.ID | Where-Object {$_.type -ne 'WID'}

            $o.WorkerWid        = $x.Worker_Reference.ID | Where-Object {$_.type -eq 'WID'} | Select-Object -ExpandProperty '#text'
            $o.WorkerDescriptor = $x.Worker_Reference.Descriptor
            $o.PreferredName    = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Formatted_Name
            $o.FirstName        = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.First_Name
            $o.LastName         = $x.Worker_Data.Personal_Data.Name_Data.Preferred_Name_Data.Name_Detail_Data.Last_Name
            $o.WorkerType       = $referenceId.type
            $o.WorkerId         = $referenceId.'#text'
            $o.UserId           = $null
            $o.OtherId          = $null
            $o.Phone            = $null
            $o.Email            = $null
            $o.XML              = [XML]$x.OuterXml

            if ($IncludePersonal) {
                $o.Phone   = @(Get-WorkdayWorkerPhone -WorkerXml $x.OuterXml)
                $o.Email   = @(Get-WorkdayWorkerEmail -WorkerXml $x.OuterXml)
                $o.OtherId = @(Get-WorkdayWorkerOtherId -WorkerXml $x.OuterXml)
                $o.UserId  = $x.Worker_Data.User_ID
            }
            Write-Output $o
        }
    }
}
