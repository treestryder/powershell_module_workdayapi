Get-ChildItem "$PSScriptRoot/scripts/*.psm1" | foreach { Import-Module $_ }
Get-ChildItem "$PSScriptRoot/scripts/*.ps1" | foreach { . $_ }
