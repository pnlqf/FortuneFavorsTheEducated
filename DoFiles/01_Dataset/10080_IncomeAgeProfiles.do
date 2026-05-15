clear all
use "$TempData/HouseholdDatasetIncomeAge", clear


rename fgaktiv_2014_partner realassets_partner
rename fgpassiv_2014_partner totaldebt_partner

gen totalassets_partner = realassets_partner + financialassets_partner // Financial Assets + Real Assets
gen totalnetassets_partner = realassets_partner + financialassets_partner -  totaldebt_partner  // Financial Assets + Real Assets - Debt

gen hh_totalassets = totalassets + cond(missing(totalassets_partner), 0 , totalassets_partner)
gen hh_totalnetassets = totalnetassets +  cond(missing(totalnetassets_partner), 0 , totalnetassets_partner)
gen hh_totaldebt = totaldebt +   cond(missing(totaldebt_partner), 0 , totaldebt_partner)

_pctile hh_finassets
replace hh_finassets = r(r1) if hh_finassets < r(r1)
replace hh_finassets = r(r2) if hh_finassets > r(r2)

_pctile hh_totalassets
replace hh_totalassets = r(r1) if hh_totalassets < r(r1)
replace hh_totalassets = r(r2) if hh_totalassets > r(r2)

_pctile hh_totalnetassets
replace hh_totalnetassets = r(r1) if hh_totalnetassets < r(r1)
replace hh_totalnetassets = r(r2) if hh_totalnetassets > r(r2)

egen pnr_id = group(pnr)
xtset pnr_id year
sort pnr_id year

**
gen byte retired_raw = (beskst13 == "07" & age > 65)
bysort pnr_id (year): egen first_ret_year = min(cond(retired_raw == 1, year,.))
gen byte retired = 0
replace retired = 1 if year == first_ret_year-1
replace retired = 2 if year >= first_ret_year & retired_raw == 1

*preserve
*keep if inlist(retired,1,2)
tab finlit  finlitparent if age == 65

collapse (mean) hh_income income hh_finassets hh_totalassets hh_totalnetassets, by(finlit finlitparent age)

export excel using "$out/WTI_ReplacementRates.xlsx", firstrow(variables) replace

** Average Parent
clear all
use "$TempData/HouseholdDatasetIncomeAge", clear


rename fgaktiv_2014_partner realassets_partner
rename fgpassiv_2014_partner totaldebt_partner

gen totalassets_partner = realassets_partner + financialassets_partner // Financial Assets + Real Assets
gen totalnetassets_partner = realassets_partner + financialassets_partner -  totaldebt_partner  // Financial Assets + Real Assets - Debt

gen hh_totalassets = totalassets + cond(missing(totalassets_partner), 0 , totalassets_partner)
gen hh_totalnetassets = totalnetassets +  cond(missing(totalnetassets_partner), 0 , totalnetassets_partner)
gen hh_totaldebt = totaldebt +   cond(missing(totaldebt_partner), 0 , totaldebt_partner)

_pctile hh_finassets
replace hh_finassets = r(r1) if hh_finassets < r(r1)
replace hh_finassets = r(r2) if hh_finassets > r(r2)

_pctile hh_totalassets
replace hh_totalassets = r(r1) if hh_totalassets < r(r1)
replace hh_totalassets = r(r2) if hh_totalassets > r(r2)

_pctile hh_totalnetassets
replace hh_totalnetassets = r(r1) if hh_totalnetassets < r(r1)
replace hh_totalnetassets = r(r2) if hh_totalnetassets > r(r2)

egen pnr_id = group(pnr)
xtset pnr_id year
sort pnr_id year

**
gen byte retired_raw = (beskst13 == "07" & age > 65)
bysort pnr_id (year): egen first_ret_year = min(cond(retired_raw == 1, year,.))
gen byte retired = 0
replace retired = 1 if year == first_ret_year-1
replace retired = 2 if year >= first_ret_year & retired_raw == 1

*preserve
*keep if inlist(retired,1,2)
tab finlit  finlitparent if age == 65

collapse (mean) hh_income income hh_finassets hh_totalassets hh_totalnetassets, by(finlit age)

export excel using "$out/WTI_ReplacementRatesAverageParent.xlsx", firstrow(variables) replace

******** NON PARAMETRIC *********
use "$TempData/HouseholdDatasetIncomeAge", clear
drop if age > 90

tostring cohort_start, gen(cohort_str)
encode cohort_str, gen(cohort_id)

gen income2 = income/1000

preserve
	tempfile cs
	collapse (mean) cs_income = income2, by(age)
	save `cs'
restore

collapse (mean) income2, by(cohort_id age)
merge m:1 age using `cs', nogen

levelsof cohort_id, local(cohorts)
foreach c of local cohorts {
	local plots "`plots' (line income age if cohort == `c', lpattern(solid) lcolor(black) lwidth(thin))"
}

twoway `plots' (line cs_income age, lcolor("65 83 116") lwidth(medthin) lpattern(solid)),  title("") legend(off) scheme(plotplain) graphregion(color(white)) plotregion(color(white))  ///
ylabel(, labsize(small) nogrid format(%9.0fc)) xlabel(25(5)90 ) ///
xtitle("Age", size(small)) ytitle("Household Income (1,000 DKK)", size(small))  ///
legend( pos(6) rows(2) size(small)) 
graph export "$out/income_cohort_heterogeneity.pdf", replace


******** Income-Age Profiles *********
use "$TempData/HouseholdDatasetIncomeAge", clear
drop if age > 65

tab finlit finlitparent if parents_missing == 0

egen pnr_id = group(pnr)

xtset pnr_id year
tabstat pnr_id, by(year)

save "$TempData/HouseholdRegressionData", replace

use "$TempData/HouseholdRegressionData", clear

levelsof finlit, local(cats)
foreach x of local cats {
	* Run regression with polynomial terms and interaction effects
	reg logincome age age2 age3 age4 age5 ib2019.year if finlit == `x', vce(robust)
	est store m1 
	esttab m1 using "$out/income_age_time_fifth_reg_`x'", replace se star(* 0.10 ** 0.05 *** 0.01) stats(N r2 r2_a)
	test age4 age5

	* Predict values and residuals
	predict yhat_`x' if finlit == `x'
	predict resid_`x' if finlit == `x' , resid
	
}

* Variance Decomposition cf. Samwick and Carroll (1997)
foreach x of local cats{
	gen double dr_`x' = resid_`x' - L1.resid_`x'
	gen double cross_`x' = dr_`x' * L1.dr_`x'

	* This is the variance we want
	qui sum dr_`x' if !missing(cross_`x')
	local var_dr = r(Var)
	local n_var = r(N)
	
	* But we can't seperate trans and perm income shocks. So we use the cov trick
	* We get covariance between residual and a lag of it by multiplying them, then
	* take exp as cov(x,y) = E(XY) - E(X) E(Y) and the latter terms are zero. 

	qui sum cross_`x' 
	local cov_dr = r(mean)
	local n_cov = r(N)
	
	local sigma2_v = -`cov_dr'
	local sigma2_eps = `var_dr' + 2*`cov_dr'
	
	local lbl : label (finlit) `x'
	
	di as result " `lbl' (finlit `x'):"
	di as result "Transitory: `sigma2_v'"
	di as result "Permanent: `sigma2_eps'"
}

save "$TempData/RegressionResults_TimeFifth", replace


********** TIME THIRD *************
use "$TempData/HouseholdRegressionData", clear
levelsof finlit, local(cats)

foreach x of local cats {
	* Run regression with polynomial terms and interaction effects
	reg logincome age age2 age3 ib2019.year if finlit == `x', vce(robust)
	est store m1 
	esttab m1 using "$out/income_age_time_third_reg_`x'", replace se star(* 0.10 ** 0.05 *** 0.01) stats(N r2 r2_a)

	* Predict values and residuals
	predict yhat_`x' if finlit == `x'
	predict resid_`x' if finlit == `x' , resid
	
}

* Variance Decomposition cf. Samwick and Carroll (1997)
foreach x of local cats{
	gen double dr_`x' = resid_`x' - L1.resid_`x'
	gen double cross_`x' = dr_`x' * L1.dr_`x'

	* This is the variance we want
	qui sum dr_`x' if !missing(cross_`x')
	local var_dr = r(Var)
	local n_var = r(N)
	
	* But we can't seperate trans and perm income shocks. So we use the cov trick
	* We get covariance between residual and a lag of it by multiplying them, then
	* take exp as cov(x,y) = E(XY) - E(X) E(Y) and the latter terms are zero. 

	qui sum cross_`x' 
	local cov_dr = r(mean)
	local n_cov = r(N)
	
	local sigma2_v = -`cov_dr'
	local sigma2_eps = `var_dr' + 2*`cov_dr'
	
	local lbl : label (finlit) `x'
	
	di as result " `lbl' (finlit `x'):"
	di as result "Transitory: `sigma2_v'"
	di as result "Permanent: `sigma2_eps'"
}

save "$TempData/RegressionResults_TimeThird", replace

********** COHORT THIRD *************
use "$TempData/HouseholdRegressionData", clear
levelsof finlit, local(cats)

foreach x of local cats {
	* Run regression with polynomial terms and interaction effects
	reg logincome age age2 age3 ib1961.cohort_start if finlit == `x', vce(robust)
	est store m1 
	esttab m1 using "$out/income_age_time_third_reg_`x'", replace se star(* 0.10 ** 0.05 *** 0.01) stats(N r2 r2_a)

	* Predict values and residuals
	predict yhat_`x' if finlit == `x'
	predict resid_`x' if finlit == `x' , resid
	
}

* Variance Decomposition cf. Samwick and Carroll (1997)
foreach x of local cats{
	gen double dr_`x' = resid_`x' - L1.resid_`x'
	gen double cross_`x' = dr_`x' * L1.dr_`x'

	* This is the variance we want
	qui sum dr_`x' if !missing(cross_`x')
	local var_dr = r(Var)
	local n_var = r(N)
	
	* But we can't seperate trans and perm income shocks. So we use the cov trick
	* We get covariance between residual and a lag of it by multiplying them, then
	* take exp as cov(x,y) = E(XY) - E(X) E(Y) and the latter terms are zero. 

	qui sum cross_`x' 
	local cov_dr = r(mean)
	local n_cov = r(N)
	
	local sigma2_v = -`cov_dr'
	local sigma2_eps = `var_dr' + 2*`cov_dr'
	
	local lbl : label (finlit) `x'
	
	di as result " `lbl' (finlit `x'):"
	di as result "Transitory: `sigma2_v'"
	di as result "Permanent: `sigma2_eps'"
}

save "$TempData/RegressionResults_CohortThird", replace

********** COHORT FIFTH *************
use "$TempData/HouseholdRegressionData", clear
levelsof finlit, local(cats)

foreach x of local cats {
	* Run regression with polynomial terms and interaction effects
	reg logincome age age2 age3 age4 age5 ib1961.cohort_start if finlit == `x', vce(robust)
	est store m1 
	esttab m1 using "$out/income_age_time_third_reg_`x'", replace se star(* 0.10 ** 0.05 *** 0.01) stats(N r2 r2_a)
	test age4 age5

	* Predict values and residuals
	predict yhat_`x' if finlit == `x'
	predict resid_`x' if finlit == `x' , resid
	
}

* Variance Decomposition cf. Samwick and Carroll (1997)
foreach x of local cats{
	gen double dr_`x' = resid_`x' - L1.resid_`x'
	gen double cross_`x' = dr_`x' * L1.dr_`x'

	* This is the variance we want
	qui sum dr_`x' if !missing(cross_`x')
	local var_dr = r(Var)
	local n_var = r(N)
	
	* But we can't seperate trans and perm income shocks. So we use the cov trick
	* We get covariance between residual and a lag of it by multiplying them, then
	* take exp as cov(x,y) = E(XY) - E(X) E(Y) and the latter terms are zero. 

	qui sum cross_`x' 
	local cov_dr = r(mean)
	local n_cov = r(N)
	
	local sigma2_v = -`cov_dr'
	local sigma2_eps = `var_dr' + 2*`cov_dr'
	
	local lbl : label (finlit) `x'
	
	di as result " `lbl' (finlit `x'):"
	di as result "Transitory: `sigma2_v'"
	di as result "Permanent: `sigma2_eps'"
}

save "$TempData/RegressionResults_CohortFifth", replace

* Export Income Paths
use "$TempData/RegressionResults_CohortFifth", clear

preserve
	collapse (mean) yhat_*, by(age)
	foreach v of varlist yhat_* {
		replace `v' = exp(`v')
	}
	twoway (line yhat_* age), xtitle("Age") ytitle("Predicted Log Income") title("Income-Age Profiles by Education") legend(off)
	export excel using "$out/IncomeAgeProfiles_CohortFifth.xlsx", firstrow(variables) replace
restore

preserve
	collapse (mean) actual_income = income, by(age finlit)
	reshape wide actual_income, i(age) j(finlit)
	rename actual_income0 actual_0
	rename actual_income1 actual_1
	cap rename actual_income2 actual_2
	if _rc gen actual_2 = .
	tempfile actuals
	save `actuals' 
restore 

collapse (mean) yhat_* , by(age)
cap gen yhat_2 = .
merge 1:1 age using `actuals', nogen

* Adjustment for Jensens, hard coded with MSE's from regression outputs
local sigma2_0 = 0.32543^2
local sigma2_1 = 0.38532^2
local sigma2_2 = 0.34326^2

replace yhat_0 = exp(yhat_0 + `sigma2_0' / 2)/1000
replace yhat_1 = exp(yhat_1 + `sigma2_1' / 2)/1000 
replace yhat_2 = exp(yhat_2 + `sigma2_2' / 2)/1000

replace actual_0 = actual_0 / 1000
replace actual_1 = actual_1 / 1000
replace actual_2 = actual_2 / 1000


* Graph Output	
twoway (line yhat_0 age, lcolor("65 83 116") lwidth(medthin) lpattern(solid)) (line actual_0 age, lcolor("65 83 116") lwidth(medthin) lpattern(dash)) ///
(line yhat_1 age, lcolor("126 69 71") lwidth(medthin) lpattern(solid)) (line actual_1 age, lcolor("126 69 71") lwidth(medthin) lpattern(dash)) ///
(line yhat_2 age, lcolor("87 117 41") lwidth(medthin) lpattern(solid)) (line actual_2 age, lcolor("87 117 41") lwidth(medthin) lpattern(dash)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid format(%9.0fc)) xlabel(25(5)65, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Predicted Income (1,000 DKK)", size(small)) title("") ///
legend(order(1 "Primary (Fitted)" 2 "Primary (Actual)" 3 "Master's (Fitted)" 4 "Master's (Actual)" 5 "Econ (Fitted)" 6 "Econ (Actual)") pos(6) row(2) size(small))
graph export "$out/IncomeAgePrediction_CohortFifth.pdf", replace

* Export Income Paths
use "$TempData/RegressionResults_CohortThird", clear

preserve
	collapse (mean) yhat_*, by(age)
	foreach v of varlist yhat_* {
		replace `v' = exp(`v')
	}
	twoway (line yhat_* age), xtitle("Age") ytitle("Predicted Log Income") title("Income-Age Profiles by Education") legend(off)
	export excel using "$out/IncomeAgeProfiles_CohortThird.xlsx", firstrow(variables) replace
restore

preserve
	collapse (mean) actual_income = income, by(age finlit)
	reshape wide actual_income, i(age) j(finlit)
	rename actual_income0 actual_0
	rename actual_income1 actual_1
	cap rename actual_income2 actual_2
	if _rc gen actual_2 = .
	tempfile actuals
	save `actuals' 
restore 

collapse (mean) yhat_* , by(age)
cap gen yhat_2 = .
merge 1:1 age using `actuals', nogen

* Adjustment for Jensens, hard coded with MSE's from regression outputs
local sigma2_0 = 0.32555^2
local sigma2_1 = 0.38567^2
local sigma2_2 = 0.34374^2

replace yhat_0 = exp(yhat_0 + `sigma2_0' / 2)/1000
replace yhat_1 = exp(yhat_1 + `sigma2_1' / 2)/1000
replace yhat_2 = exp(yhat_2 + `sigma2_2' / 2)/1000

replace actual_0 = actual_0 / 1000
replace actual_1 = actual_1 / 1000
replace actual_2 = actual_2 / 1000


* Graph Output	
twoway (line yhat_0 age, lcolor("65 83 116") lwidth(medthin) lpattern(solid)) (line actual_0 age, lcolor("65 83 116") lwidth(medthin) lpattern(dash)) ///
(line yhat_1 age, lcolor("126 69 71") lwidth(medthin) lpattern(solid)) (line actual_1 age, lcolor("126 69 71") lwidth(medthin) lpattern(dash)) ///
(line yhat_2 age, lcolor("87 117 41") lwidth(medthin) lpattern(solid)) (line actual_2 age, lcolor("87 117 41") lwidth(medthin) lpattern(dash)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid format(%9.0fc)) xlabel(25(5)65, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Predicted Income (1,000 DKK)", size(small)) title("") ///
legend(order(1 "Primary (Fitted)" 2 "Primary (Actual)" 3 "Master's (Fitted)" 4 "Master's (Actual)" 5 "Econ (Fitted)" 6 "Econ (Actual)") pos(6) row(2) size(small))
graph export "$out/IncomeAgePrediction_CohortThird.pdf", replace



* Export Income Paths
use "$TempData/RegressionResults_TimeFifth", clear

preserve
	collapse (mean) yhat_*, by(age)
	foreach v of varlist yhat_* {
		replace `v' = exp(`v')
	}
	twoway (line yhat_* age), xtitle("Age") ytitle("Predicted Log Income") title("Income-Age Profiles by Education") legend(off)
	export excel using "$out/IncomeAgeProfiles_TimeFifth.xlsx", firstrow(variables) replace
restore

preserve
	collapse (mean) actual_income = income, by(age finlit)
	reshape wide actual_income, i(age) j(finlit)
	rename actual_income0 actual_0
	rename actual_income1 actual_1
	cap rename actual_income2 actual_2
	if _rc gen actual_2 = .
	tempfile actuals
	save `actuals' 
restore 

collapse (mean) yhat_* , by(age)
cap gen yhat_2 = .
merge 1:1 age using `actuals', nogen

* Adjustment for Jensens, hard coded with MSE's from regression outputs
local sigma2_0 = 0.32458^2
local sigma2_1 = 0.38472^2
local sigma2_2 = 0.34245^2

replace yhat_0 = exp(yhat_0 + `sigma2_0' / 2)/1000
replace yhat_1 = exp(yhat_1 + `sigma2_1' / 2)/1000
replace yhat_2 = exp(yhat_2 + `sigma2_2' / 2)/1000

replace actual_0 = actual_0 / 1000
replace actual_1 = actual_1 / 1000
replace actual_2 = actual_2 / 1000


* Graph Output	
twoway (line yhat_0 age, lcolor("65 83 116") lwidth(medthin) lpattern(solid)) (line actual_0 age, lcolor("65 83 116") lwidth(medthin) lpattern(dash)) ///
(line yhat_1 age, lcolor("126 69 71") lwidth(medthin) lpattern(solid)) (line actual_1 age, lcolor("126 69 71") lwidth(medthin) lpattern(dash)) ///
(line yhat_2 age, lcolor("87 117 41") lwidth(medthin) lpattern(solid)) (line actual_2 age, lcolor("87 117 41") lwidth(medthin) lpattern(dash)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid format(%9.0fc)) xlabel(25(5)65, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Predicted Income (1,000 DKK)", size(small)) title("") ///
legend(order(1 "Primary (Fitted)" 2 "Primary (Actual)" 3 "Master's (Fitted)" 4 "Master's (Actual)" 5 "Econ (Fitted)" 6 "Econ (Actual)") pos(6) row(2) size(small))
graph export "$out/IncomeAgePrediction_TimeFifth.pdf", replace

* Export Income Paths
use "$TempData/RegressionResults_TimeThird", clear

preserve
	collapse (mean) yhat_*, by(age)
	foreach v of varlist yhat_* {
		replace `v' = exp(`v')
	}
	twoway (line yhat_* age), xtitle("Age") ytitle("Predicted Log Income") title("Income-Age Profiles by Education") legend(off)
	export excel using "$out/IncomeAgeProfiles_TimeThird.xlsx", firstrow(variables) replace
restore

preserve
	collapse (mean) actual_income = income, by(age finlit)
	reshape wide actual_income, i(age) j(finlit)
	rename actual_income0 actual_0
	rename actual_income1 actual_1
	cap rename actual_income2 actual_2
	if _rc gen actual_2 = .
	tempfile actuals
	save `actuals' 
restore 

collapse (mean) yhat_* , by(age)
cap gen yhat_2 = .
merge 1:1 age using `actuals', nogen

* Adjustment for Jensens, hard coded with MSE's from regression outputs
local sigma2_0 = 0.3248^2
local sigma2_1 = 0.38541^2
local sigma2_2 = 0.34331^2

replace yhat_0 = exp(yhat_0 + `sigma2_0' / 2)/1000
replace yhat_1 = exp(yhat_1 + `sigma2_1' / 2)/1000
replace yhat_2 = exp(yhat_2 + `sigma2_2' / 2)/1000

replace actual_0 = actual_0 / 1000
replace actual_1 = actual_1 / 1000
replace actual_2 = actual_2 / 1000


* Graph Output	
twoway (line yhat_0 age, lcolor("65 83 116") lwidth(medthin) lpattern(solid)) (line actual_0 age, lcolor("65 83 116") lwidth(medthin) lpattern(dash)) ///
(line yhat_1 age, lcolor("126 69 71") lwidth(medthin) lpattern(solid)) (line actual_1 age, lcolor("126 69 71") lwidth(medthin) lpattern(dash)) ///
(line yhat_2 age, lcolor("87 117 41") lwidth(medthin) lpattern(solid)) (line actual_2 age, lcolor("87 117 41") lwidth(medthin) lpattern(dash)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid format(%9.0fc)) xlabel(25(5)65, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Predicted Income (1,000 DKK)", size(small)) title("") ///
legend(order(1 "Primary (Fitted)" 2 "Primary (Actual)" 3 "Master's (Fitted)" 4 "Master's (Actual)" 5 "Econ (Fitted)" 6 "Econ (Actual)") pos(6) row(2) size(small))
graph export "$out/IncomeAgePrediction_TimeThird.pdf", replace


******** Mean Collapse - Participation & Intensive Margins (Kappa) *********
use "$TempData/HouseholdDatasetIncomeAge", clear
drop if age < 25
*drop if age > 85

replace hh_kappa = abs(hh_kappa)
_pctile hh_kappa, p(1 99)
replace hh_kappa = r(r1) if hh_kappa < r(r1)
replace hh_kappa = r(r2) if hh_kappa > r(r2)

_pctile hh_finassets, p(1 99)
replace hh_finassets = r(r1) if hh_finassets < r(r1)
replace hh_finassets = r(r2) if hh_finassets > r(r2)


_pctile totalassets, p(1 99)
replace totalassets = r(r1) if totalassets < r(r1)
replace totalassets = r(r2) if totalassets > r(r2)

_pctile totalnetassets, p(1 99)
replace totalnetassets = r(r1) if totalnetassets < r(r1)
replace totalnetassets = r(r2) if totalnetassets > r(r2)

_pctile totaldebt, p(1 99)
replace totaldebt = r(r1) if totaldebt < r(r1)
replace totaldebt = r(r2) if totaldebt > r(r2)

rename fgaktiv_2014_partner realassets_partner
rename fgpassiv_2014_partner totaldebt_partner

gen totalassets_partner = realassets_partner + financialassets_partner // Financial Assets + Real Assets
gen totalnetassets_partner = realassets_partner + financialassets_partner -  totaldebt_partner  // Financial Assets + Real Assets - Debt

gen hh_totalassets = totalassets + cond(missing(totalassets_partner), 0 , totalassets_partner)
gen hh_totalnetassets = totalnetassets +  cond(missing(totalnetassets_partner), 0 , totalnetassets_partner)
gen hh_totaldebt = totaldebt +   cond(missing(totaldebt_partner), 0 , totaldebt_partner)

_pctile hh_totaldebt, p(1 99)
replace hh_totaldebt = r(r1) if hh_totaldebt < r(r1)
replace hh_totaldebt = r(r2) if hh_totaldebt > r(r2)

_pctile hh_totalassets, p(1 99)
replace hh_totalassets = r(r1) if hh_totalassets < r(r1)
replace hh_totalassets = r(r2) if hh_totalassets > r(r2)

_pctile hh_totalnetassets, p(1 99)
replace hh_totalnetassets = r(r1) if hh_totalnetassets < r(r1)
replace hh_totalnetassets = r(r2) if hh_totalnetassets > r(r2)

_pctile hh_income, p(1 99)
replace hh_income = r(r1) if hh_income < r(r1)
replace hh_income = r(r2) if hh_income > r(r2)

_pctile hh_finassets_2, p(1 99)
replace hh_finassets_2 = r(r1) if hh_finassets_2 < r(r1)
replace hh_finassets_2 = r(r2) if hh_finassets_2 > r(r2)

gen hh_participationrate = (hh_finassets_2 > 0)
replace hh_participationrate = abs(hh_participationrate)
_pctile hh_participationrate, p(1 99)
replace hh_participationrate = r(r1) if hh_participationrate < r(r1)
replace hh_participationrate = r(r2) if hh_participationrate > r(r2)

** Descriptive Statistics Table
tabstat age ie_type h_size n_adults n_children male married widow divorced age_min age_max educ_lgth_individual educ_lgth_partner  sf hh_income equiv_income hh_income_disp income grundskolekarakter hh_finassets hh_finassets_2 educ_lgth_parent educ_a finlit finlitparent hh_totalassets hh_totalnetassets hh_totaldebt hh_participationrate, stats(mean p50 skewness kurtosis p10 p90)

* Descriptive Stuff
*** EDUCATION

preserve
	contract finlit
	egen total = total(_freq)
	gen pct = 100 * _freq / total
	gen mylabel = string(_freq, "%9.0fc")
	gen zero = 0
	
	twoway (rbar zero _freq finlit if finlit == 0, color("65 83 116") lcolor(black) lwidth(thin) barw(0.5)) ///
	(rbar zero _freq finlit if finlit == 1, color("126 69 71") lcolor(black) lwidth(thin) barw(0.5)) ///
	(rbar zero _freq finlit if finlit == 2, color("87 117 41") lcolor(black) lwidth(thin) barw(0.5)) ///
	(scatter _freq finlit, mcolor(none) mlabel(mylabel) mlabposition(12) mlabgap(1.5) mlabcolor(black) mlabsize(small)), ///
	xlabel(-0.5 " " 0"Low" 1"Medium" 2 "High" 2.5" ", labsize(small) noticks) ///
	xtitle("Financial Literacy", size(small)) ///
	ytitle("Number of Households", size(small)) ///
	ylabel(0(1000000)6000000, format(%9.0fc) labsize(small) angle(0) glcolor(gs14) glwidth(vthin)) ///
	legend(off) ///
	scheme(plotplain)  yscale(range(0 6000000) noextend)
	graph export "$out/finlitfrequency.pdf", replace
restore

preserve
		tabout finlit finlitparent using "$out/tab_finlit_finlitparent.tex", c(col row) replace
	contract finlitparent
	egen total = total(_freq)
	gen pct = 100 * _freq / total
	gen mylabel = string(_freq, "%9.0fc")
	gen zero = 0
	
	twoway (rbar zero _freq finlit if finlit == 0, color("65 83 116") lcolor(black) lwidth(thin) barw(0.5)) ///
	(rbar zero _freq finlit if finlit == 1, color("126 69 71") lcolor(black) lwidth(thin) barw(0.5)) ///
	(rbar zero _freq finlit if finlit == 2, color("87 117 41") lcolor(black) lwidth(thin) barw(0.5)) ///
	(scatter _freq finlit, mcolor(none) mlabel(mylabel) mlabposition(12) mlabgap(1.5) mlabcolor(black) mlabsize(small)), ///
	xlabel(-0.5 " " 0"Low" 1"Medium" 2 "High" 2.5" ", labsize(small) noticks) ///
	xtitle("Parental Financial Literacy", size(small)) ///
	ytitle("Number of Households", size(small)) ///
	ylabel(0(100000)1000000, format(%9.0fc) labsize(small) angle(0) glcolor(gs14) glwidth(vthin)) ///
	legend(off) ///
	scheme(plotplain)  yscale(range(0 1000000) noextend)
	graph export "$out/parentalfinlitfrequency.pdf", replace
restore
	




gen WIR = hh_finassets / hh_income
gen WIR_allassets = hh_totalassets / hh_income
gen WIR_totalnetassets = hh_totalnetassets / hh_income

gen WIR_equiv = hh_finassets / income
gen WIR_allassets_equiv = hh_totalassets / income
gen WIR_totalnetassets_equiv = hh_totalnetassets / income

collapse (mean) WIR WIR_equiv WIR_allassets_equiv WIR_totalnetassets_equiv hh_totalnetassets hh_totaldebt hh_totalassets hh_kappa hh_participationrate income hh_income_disp hh_income hh_finassets_2 hh_finassets WIR_allassets WIR_totalnetassets, by(age finlit)
*export excel using $out/SummaryStatisticsWealth.xlsx, firstrow(variables) replace

drop if age > 90

* This basically reproduces the Lusardi paper's Table
gen hh_income2 = hh_income / 1000

twoway (line hh_income2 age if finlit == 0 , lcolor("65 83 116") lpattern(solid)) (line hh_income2 age if finlit == 1, lcolor("126 69 71") lpattern(solid)) (line hh_income2 age if finlit == 2, lcolor("87 117 41") lpattern(solid)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid ) xlabel( 25(5)90, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Income  (1,000 DKK)", size(small)) title("") ///
legend(order(1 "Primary" 2 "Master's" 3 "Master's in Business / Economics") pos(6) rows(1) size(small))
graph export "$out/hh_income.pdf", replace

twoway (line hh_participationrate age if finlit == 0 , lcolor("65 83 116") lpattern(solid)) (line hh_participationrate age if finlit == 1, lcolor("126 69 71") lpattern(solid)) (line hh_participationrate age if finlit == 2, lcolor("87 117 41") lpattern(solid)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid ) xlabel( 25(5)90, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Participation Rate", size(small)) title("") ///
legend(order(1 "Primary" 2 "Master's" 3 "Master's in Business / Economics") pos(6) rows(1) size(small))
graph export "$out/hh_participationrate.pdf", replace

twoway (line hh_kappa age if finlit == 0 , lcolor("65 83 116") lpattern(solid)) (line hh_kappa age if finlit == 1, lcolor("126 69 71") lpattern(solid)) (line hh_kappa age if finlit == 2, lcolor("87 117 41") lpattern(solid)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid ) xlabel( 25(5)90, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Equity Share", size(small)) title("") ///
legend(order(1 "Primary" 2 "Master's" 3 "Master's in Business / Economics") pos(6) rows(1) size(small))
graph export "$out/hh_equityshare.pdf", replace

gen hh_finassets2 = hh_finassets/1000
twoway (line hh_finassets2 age if finlit == 0 , lcolor("65 83 116") lpattern(solid)) (line hh_finassets2 age if finlit == 1, lcolor("126 69 71") lpattern(solid)) (line hh_finassets2 age if finlit == 2, lcolor("87 117 41") lpattern(solid)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid ) xlabel( 25(5)90, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Financial Assets (1,000 DKK)", size(small)) title("") ///
legend(order(1 "Primary" 2 "Master's" 3 "Master's in Business / Economics") pos(6) rows(1) size(small))
graph export "$out/hh_finassets.pdf", replace

gen hh_totalassets2 = hh_totalassets/1000
twoway (line hh_totalassets2 age if finlit == 0 , lcolor("65 83 116") lpattern(solid)) (line hh_totalassets2 age if finlit == 1, lcolor("126 69 71") lpattern(solid)) (line hh_totalassets2 age if finlit == 2, lcolor("87 117 41") lpattern(solid)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid ) xlabel( 25(5)90, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Total Assets (1,000 DKK)", size(small)) title("") ///
legend(order(1 "Primary" 2 "Master's" 3 "Master's in Business / Economics") pos(6) rows(1) size(small))
graph export "$out/hh_totalassets.pdf", replace

twoway (line WIR age if finlit == 0 , lcolor("65 83 116") lpattern(solid)) (line WIR age if finlit == 1, lcolor("126 69 71") lpattern(solid)) (line WIR age if finlit == 2, lcolor("87 117 41") lpattern(solid)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid ) xlabel( 25(5)90, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Wealth to Income Ratio (Financial Assets)", size(small)) title("") ///
legend(order(1 "Primary" 2 "Master's" 3 "Master's in Business / Economics") pos(6) rows(1) size(small))
graph export "$out/hh_WIR_financial.pdf", replace

twoway (line WIR_allassets age if finlit == 0 , lcolor("65 83 116") lpattern(solid)) (line WIR_allassets age if finlit == 1, lcolor("126 69 71") lpattern(solid)) (line WIR_allassets age if finlit == 2, lcolor("87 117 41") lpattern(solid)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid ) xlabel( 25(5)90, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Wealth to Income Ratio (Total Assets)", size(small)) title("") ///
legend(order(1 "Primary" 2 "Master's" 3 "Master's in Business / Economics") pos(6) rows(1) size(small))
graph export "$out/hh_WIR_total.pdf", replace

twoway (line WIR_totalnetassets age if finlit == 0 , lcolor("65 83 116") lpattern(solid)) (line WIR_totalnetassets age if finlit == 1, lcolor("126 69 71") lpattern(solid)) (line WIR_totalnetassets age if finlit == 2, lcolor("87 117 41") lpattern(solid)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid ) xlabel( 25(5)90, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Wealth to Income Ratio (Net Assets)", size(small)) title("") ///
legend(order(1 "Primary" 2 "Master's" 3 "Master's in Business / Economics") pos(6) rows(1) size(small))
graph export "$out/hh_WIR_netassets.pdf", replace


twoway (line WIR_equiv age if finlit == 0 , lcolor("65 83 116") lpattern(solid)) (line WIR_equiv age if finlit == 1, lcolor("126 69 71") lpattern(solid)) (line WIR_equiv age if finlit == 2, lcolor("87 117 41") lpattern(solid)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid ) xlabel( 25(5)90, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Wealth to Income Ratio (Financial Assets)", size(small)) title("") ///
legend(order(1 "Primary" 2 "Master's" 3 "Master's in Business / Economics") pos(6) rows(1) size(small))
graph export "$out/hh_WIR_equiv_financial.pdf", replace

twoway (line WIR_allassets_equiv age if finlit == 0 , lcolor("65 83 116") lpattern(solid)) (line WIR_allassets_equiv age if finlit == 1, lcolor("126 69 71") lpattern(solid)) (line WIR_allassets_equiv age if finlit == 2, lcolor("87 117 41") lpattern(solid)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid ) xlabel( 25(5)90, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Wealth to Income Ratio (Total Assets)", size(small)) title("") ///
legend(order(1 "Primary" 2 "Master's" 3 "Master's in Business / Economics") pos(6) rows(1) size(small))
graph export "$out/hh_WIR_equiv_total.pdf", replace

twoway (line WIR_totalnetassets_equiv age if finlit == 0 , lcolor("65 83 116") lpattern(solid)) (line WIR_totalnetassets_equiv age if finlit == 1, lcolor("126 69 71") lpattern(solid)) (line WIR_totalnetassets_equiv age if finlit == 2, lcolor("87 117 41") lpattern(solid)), scheme(plotplain) ///
graphregion(color(white)) plotregion(color(white)) ylabel(, labsize(small) nogrid ) xlabel( 25(5)90, labsize(small)) ///
xtitle("Age", size(small)) ytitle("Wealth to Income Ratio (Net Assets)", size(small)) title("") ///
legend(order(1 "Primary" 2 "Master's" 3 "Master's in Business / Economics") pos(6) rows(1) size(small))
graph export "$out/hh_WIR_equiv_netassets.pdf", replace

* Return Heterogeneities

* Idea 1: Merton 
use "$TempData/HouseholdDatasetIncomeAge", clear
encode(civst), gen(civst_d)
drop if age > 65

replace kappa = abs(kappa)
_pctile kappa, p(1 99)
replace kappa = r(r1) if kappa < r(r1)
replace kappa = r(r2) if kappa > r(r2)

replace hh_kappa = abs(hh_kappa)
_pctile hh_kappa, p(1 99)
replace hh_kappa = r(r1) if hh_kappa < r(r1)
replace hh_kappa = r(r2) if hh_kappa > r(r2)

_pctile hh_finassets, p(1 99)
replace hh_finassets = r(r1) if hh_finassets < r(r1)
replace hh_finassets = r(r2) if hh_finassets > r(r2)

_pctile hh_income, p(1 99)
replace hh_income = r(r1) if hh_income < r(r1)
replace hh_income = r(r2) if hh_income > r(r2)

_pctile personindk_individual, p(1 99)
replace personindk_individual = r(r1) if personindk_individual < r(r1)
replace personindk_individual = r(r2) if personindk_individual > r(r2)


reg hh_kappa male hh_income i.finlit##i.finlitparent age hh_finassets ib2019.year i.married n_children, vce(robust)
eststo reg1
esttab reg1 using "$out/equitysharereg_average.tex", replace booktabs se star(* 0.10 ** 0.05 *** 0.01) stats(N r2 r2_a)

margins finlit, atmeans at(age=45)
eststo margins1
esttab margins1 using "$out/margins_average.tex", replace booktabs cells("b se ci")

margins finlit, atmeans at(age=45) 
marginsplot, recast(line) ciopt(recast(rarea)) ///
plot1opts(lcolor("65 83 116") lwidth(medthin) lpattern(solid)) ///
ci1opts(fcolor("65 83 116%20") lcolor("65 83 116%20") lwidth(none)) ///
scheme(plotplain) graphregion(color(white)) plotregion(color(white)) ///
xtitle("Financial Literacy" ,size(small)) ytitle("Estimated Risky Share",size(small)) title("") legend(off) ///
ylabel(, labsize(small)  ) xlabel( , labsize(small))
graph export "$out/marginsplot_average.pdf", replace

reg hh_kappa male hh_income i.finlit##i.finlitparent age hh_finassets ib2019.year i.married n_children, vce(robust) 

margins finlit#finlitparent, atmeans at(age=45)
eststo margins2
esttab margins2 using "$out/margins_full.tex", replace booktabs cells("b se ci")

margins finlit#finlitparent, atmeans at(age=45)
cap marginsplot, recast(line) ciopt(recast(rarea)) ///
plot1opts(lcolor("65 83 116") lwidth(medthin) lpattern(solid)) ///
plot2opts(lcolor("126 69 71") lwidth(medthin) lpattern(solid)) ///
plot3opts(lcolor("87 117 41") lwidth(medthin) lpattern(solid)) ///
ci1opts(fcolor("65 83 116%20") lcolor("65 83 116%20") lwidth(none)) ///
ci2opts(fcolor("126 69 71%20") lcolor("126 69 71%20") lwidth(none)) ///
ci3opts(fcolor("87 117 41%20") lcolor("87 117 41%20") lwidth(none)) ///
scheme(plotplain) graphregion(color(white)) plotregion(color(white)) ///
xtitle("Financial Literacy" ,size(small)) ytitle("Estimated Risky Share",size(small)) title("") legend(order(4 "Primary Parents" 5 "Master's Parents" 6 "Masters in Business / Econ Parents") pos(6) rows(1) size(small)) ///
ylabel(, labsize(small)  ) xlabel( , labsize(small))
if !_rc graph export "$out/marginsplot_full.pdf", replace

*************

