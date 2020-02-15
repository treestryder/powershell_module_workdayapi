# Changelog

## 2.2.7 - 2020-02-15

- Set-WorkdayWorkerPhone now excepts any DeviceType and UsageType.

## 2.2.6 - 2020-02-03

- Added WID to the terribly named Get-WorkdayWorkerByIdLookupTable and an Active property to Get-WorkdayWorker.
- Removed the confusing and broken Export-WorkdayWorkerDocument and improved Get-WorkdayWorkerDocument.

## 2.2.5 - 2019-12-28

- Fixed Worker Location that before was returning the ID, rather than the value.

## 2.2.4 - 2019-12-28

- Published to the Microsoft Powershell Gallery.
- Improved server level error handling when calling Invoke-WorkdayRequest.

## 2.2.3 - 2019-12-27

- Parameter "-IncludeInactive" now available on all Worker cmdlets.
- Code cleanup and preparation for publishing to the Powershell Gallery.

## 2.2.2 - 2018-12-13

- Bug fix: Update-WorkdayWorkerOtherId now behaves as expected, when a date is not passed.

## 2.2.1 - 2018-11-30

- Bug fix: When not requesting individual workers, Get-WorkdayWorker was returning the last set of values on each page of Workers, due to not anchoring XML XPath queries with "./" in ConvertFrom-WorkdayWorkerXml.

## 2.2.0 - 2018-11-29

- Get-WorkdayWorker now returns Company, BusinessUnit (Department) and Supervisory (still looking for Sub-Department).

## 2.1.3 - 2018-04-13

- Update_Email_By_WorkerID.ps1 will now also read an input file without a header.

## 2.1.2 - 2018-04-13

- Corrected two Get-WorkdayWorker bugs.

## 2.1.1 - 2018-04-10

- Added Get-WorkdayWorkerByIdLookupTable.
- New sample script Update_Email_By_WorkerID.ps1.

## 2.1.0 - 2018-04-09

- Set-WorkdayWorkerEmail will now update a primary email address, without deleting all non-primary addresses. Use the new switch -Append, with -Secondary, to append multiple non-Primary email addresses.
- Update-* commands (Update-WorkdayWorkerEmail, Update-WorkdayWorkerOtherId, Update-WorkdayWorkerPhone) now output details of the request; such as Worker Type, Id and input values and no longer output XML.
