clear all
cap log close
set more off
global date=date(c(current_date), "DMY")

* Location of raw data
global rawdata		="C:\Users\pnata\OneDrive - CBS - Copenhagen Business School\Thesis\04_Technicalities\01_ Empirics\DST w. Dummy Data\RAWDATA\2025-06-18"

* Location of subdirectories
global Do			="C:\Users\pnata\OneDrive - CBS - Copenhagen Business School\Thesis\04_Technicalities\01_ Empirics\DST w. Dummy Data\DoFiles"
global TempData 	="C:\Users\pnata\OneDrive - CBS - Copenhagen Business School\Thesis\04_Technicalities\01_ Empirics\DST w. Dummy Data\TempData"
global logs  		="C:\Users\pnata\OneDrive - CBS - Copenhagen Business School\Thesis\04_Technicalities\01_ Empirics\DST w. Dummy Data\Logs"
global data			="C:\Users\pnata\OneDrive - CBS - Copenhagen Business School\Thesis\04_Technicalities\01_ Empirics\DST w. Dummy Data\Data"
global out			="C:\Users\pnata\OneDrive - CBS - Copenhagen Business School\Thesis\04_Technicalities\01_ Empirics\DST w. Dummy Data\Output"
global AuxFiles 	="C:\Users\pnata\OneDrive - CBS - Copenhagen Business School\Thesis\04_Technicalities\01_ Empirics\DST w. Dummy Data\Data\AuxFiles"

********************************************************************************
* Data Generation
********************************************************************************

do "$Do\01_Dataset\10010_Demographics.do"
do "$Do\01_Dataset\10020_FinancialWealth.do"
do "$Do\01_Dataset\10030_Education.do"
do "$Do\01_Dataset\10035_Formue.do"
do "$Do\01_Dataset\10040_Merge.do"
do "$Do\01_Dataset\10050_Households.do"
do "$Do\01_Dataset\10060_HouseholdPanel.do"
do "$Do\01_Dataset\10070_Grades.do"
do "$Do\01_Dataset\10075_Restrictions.do"
do "$Do\01_Dataset\10080_IncomeAgeProfiles.do"



