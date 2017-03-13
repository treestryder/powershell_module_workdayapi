# Workday Powershell Script Module #

## Description ##
Provides simple methods for accessing the Workday API.

This simple Powershell Module has been written to fulfill my employer's Workday automation needs. I see this as a prototype, while I experiment with the best way to expose the complexities of the Workday API in a Powershell-y way. Thinking that the community might find it helpful and may even wish to comment or contribute, I have hosted the source here.

## Features ##

* Cmdlets for setting default configuration.
* Cmdlet to securely save default configuration to current user's profile.
* ...
 
## Examples ##
    Set-WorkdayCredential
    Set-WorkdayEndpoint -Endpoint Staffing        -Uri 'https://SERVICE.workday.com/ccx/service/TENANT/Staffing/v25.1'
    Set-WorkdayEndpoint -Endpoint Human_Resources -Uri 'https://SERVICE.workday.com/ccx/service/TENANT/Human_Resources/v25.1'
    Save-WorkdayConfiguration

    Set-WorkdayWorkerPhone -EmployeeId -WorkPhone 9876543210

    Get-WorkdayWorkerPhone -EmpoyeeId 123

    Type          Number            Primary Public
    ----          ------            ------- ------
    Home/Landline +1 (123) 456-7890 0        False
    Work/Landline +1 (987) 654-3210 0         True


## Installation ##

The only dependency is Powershell version 4.

To install...

* Download the files.
* Execute the script Install-WorkdayModule.ps1
