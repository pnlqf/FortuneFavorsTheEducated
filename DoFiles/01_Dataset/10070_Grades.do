*********************************************************************************************************************
* Collapse to household level
*********************************************************************************************************************
* Log
clear all
cap log close
log using "$logs\\${date}_10055_Grades.txt", replace

*Loop over years

* Start with 2010
use "$rawdata/UDFK2025", clear

* Append Remaining years
forval x = 2023/2025{
	append using "$rawdata/UDFK`x'"
}
duplicates drop
drop if pnr ==""
save "$TempData/Grades", replace

* Manip
use "$TempData/Grades", clear

keep if grundskolefag == "Matematik"

collapse (mean)  grundskolekarakter opr_karakter, by(pnr)

save "$TempData/GradesCollapsed", replace

use "$TempData/HouseholdPanel", clear
drop _merge
merge m:1 pnr using "$TempData/GradesCollapsed"

save "$TempData/HouseholdPanelGrades", replace  
















		
		

		
		
	
	
	
	
	
	