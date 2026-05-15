*********************************************************************************************************************
* Collapse to household level
*********************************************************************************************************************
* Log
clear all
cap log close
log using "$logs\\${date}_10050_Households.txt", replace

*Loop over years

forval x = 2014/2024{
		use "$TempData/DemoEducInco_`x'", clear
		gen year = `x'
		gen sf = 1+0.5*(n_adults-1) + 0.3*n_children
		gen hh_income = personindk_individual + cond(missing(personindk_partner), 0 , personindk_partner)
		gen equiv_income = hh_income / sf
		
		gen hh_income_disp = dispon_13_individual + cond(missing(dispon_13_partner), 0 , dispon_13_partner)
		gen equiv_disp_income = hh_income_disp / sf
			
		compress
		save "$TempData/Household_`x'", replace
}
		


		
		

		
		
	
	
	
	
	
	