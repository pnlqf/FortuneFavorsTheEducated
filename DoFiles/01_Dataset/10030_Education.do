*********************************************************************************************************************
* EDUCATIONAL DATA FROM THE MINISTRY OF EDUCATION (REGISTRY: UDDA)
*********************************************************************************************************************
* Log
cap log close
log using "$logs\\${date}_10030_Education.txt", replace

* Import education TYPE
import delimited "$AuxFiles/AUDD_HOOFDOMRAADE.txt", clear delim(";")
duplicates drop
tostring audd, replace format(%04.0f)
save "$TempData/EDUC_TYPE", replace
clear

import delimited "$AuxFiles/HOOFDOMRAADE_DESCRIPTION.txt", clear delim(";")
duplicates drop
save "$TempData/EDUC_TYPE_DESC", replace
clear

* Import education AREA
import delimited "$AuxFiles/AUDD_FAGGRUPPE.txt", clear delim(";") varnames(1)
duplicates drop
tostring audd, replace format(%04.0f)
save "$TempData/EDUC_AREA", replace
clear

import delimited "$AuxFiles/FAGGRUPPE_DESCRIPTION.txt", clear delim(";")
duplicates drop
save "$TempData/EDUC_AREA_DESC", replace
clear

* Import educational mapping to lengths
import delimited "$AuxFiles/PRIA.txt", clear delim(";")
tostring audd, replace format(%04.0f)
save "$TempData/EDUC_LGTH", replace
clear

* Loop over UDDA frames
forval x = 2014/2020 {
	use "$rawdata/udda`x'", replace
	keep pnr hfaudd
	rename hfaudd audd
	tostring audd, replace format(%04.0f)
	duplicates drop

	* Add years of Education
	merge m:1 audd using "$TempData/EDUC_LGTH"
	drop if _merge == 2 // Drop if no one has the education
	gen educ_lgth = pria / 12 
	drop _merge pria

	* Add educational type
	merge m:1 audd using "$TempData/EDUC_TYPE"
	drop if _merge == 2 // Drop if no one has the education
	drop _merge

	* Add descriptions
	merge m:1 hoofdomraade using "$TempData/EDUC_TYPE_DESC"
	drop if _merge == 2
	drop _merge
	
	* Add educational area
	merge m:1 audd using "$TempData/EDUC_AREA"
	drop if _merge == 2 // Drop if no one has the education
	drop _merge

	* Add descriptions
	merge m:1 faggruppe using "$TempData/EDUC_AREA_DESC"
	drop if _merge == 2
	drop _merge

	* If an individual shows up twice, use the highest educational attainment
	bysort pnr (educ_lgth): keep if _n == _N // We sort by pnr and highest educ_lgth, then only keep the last one
	
	rename description educ_type
	rename desc educ_area
	
	keep pnr audd educ_lgth educ_type educ_area
	save "$TempData/Educ_`x'", replace
}

* Loop over UDDA frames
forval x = 2021/2024 {
	use "$rawdata/udda`x'09", replace
	keep pnr hfaudd
	rename hfaudd audd
	tostring audd, replace format(%04.0f)
	duplicates drop

	* Add years of Education
	merge m:1 audd using "$TempData/EDUC_LGTH"
	drop if _merge == 2 // Drop if no one has the education
	gen educ_lgth = pria / 12 
	drop _merge pria

	* Add educational type
	merge m:1 audd using "$TempData/EDUC_TYPE"
	drop if _merge == 2 // Drop if no one has the education
	drop _merge

	* Add descriptions
	merge m:1 hoofdomraade using "$TempData/EDUC_TYPE_DESC"
	drop if _merge == 2
	drop _merge
	
	* Add educational area
	merge m:1 audd using "$TempData/EDUC_AREA"
	drop if _merge == 2 // Drop if no one has the education
	drop _merge

	* Add descriptions
	merge m:1 faggruppe using "$TempData/EDUC_AREA_DESC"
	drop if _merge == 2
	drop _merge

	* If an individual shows up twice, use the highest educational attainment
	bysort pnr (educ_lgth): keep if _n == _N // We sort by pnr and highest educ_lgth, then only keep the last one
	
	rename description educ_type
	rename desc educ_area
	
	keep pnr audd educ_lgth educ_type educ_area
	save "$TempData/Educ_`x'", replace
}


