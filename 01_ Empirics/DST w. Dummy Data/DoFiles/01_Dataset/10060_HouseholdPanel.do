* Log
clear all
cap log close
log using "$logs\\${date}_10060_HouseholdPanel.txt", replace

forval x = 2014/2023 {
	use "$rawdata/AKM`x'"
	keep pnr alder_ult_ink beskst13
	gen year = `x'
	drop if pnr == ""
	duplicates drop pnr year, force
	
	save "$TempData/LabourMarketAttachment_`x'", replace
}

forval x = 2014/2023 {
	use "$TempData/Household_`x'"
	merge m:1 pnr year using "$TempData/LabourMarketAttachment_`x'"
	save "$TempData/Household__`x'", replace
}

use "$TempData/Household_2024", clear
save "$TempData/Household__2024", replace

* Start with 2014
use "$TempData/Household__2014", clear

* Append Remaining years
forval x = 2015/2024{
	append using "$TempData/Household__`x'"

}
* Gen all variables necessary for our analysis
gen birthyear = year(foed_dag)
gen cohort5 = floor((birthyear - 1901)/5)
gen cohort_start = 1901 + 5*cohort5

gen age2 = alder^2
gen age3 = alder^3
gen age4 = alder^4
gen age5 = alder^5
rename alder age

*gen logincome = log(equiv_income)
gen logincome = log(equiv_disp_income)

encode educ_type_individual, gen(educ_cat)
encode educ_area_individual, gen(educ_area)

rename fgb_2014_individual financialassets // Stocks + Bonds + Investment Funds + Cash
gen financialassets2 = financialassets	 - fgb1_individual // This is not including cash

rename fgaktiv_2014_individual realassets
rename fgpassiv_2014_individual totaldebt 

gen totalassets = realassets + financialassets // Financial Assets + Real Assets
gen totalnetassets = realassets + financialassets -  totaldebt  // Financial Assets + Real Assets - Debt

gen participationrate = (financialassets2 > 0) // = 1 if holding Stocks, Bonds or Investment Funds.

gen kappa = financialassets2 / financialassets // Share of wealth in risky vs cash i.e. no real assets

gen kappa_real = financialassets / totalnetassets // Stocks + Bonds + Investment Funds + Cash vs Total net assets 

save "$TempData/HouseholdPanel", replace


