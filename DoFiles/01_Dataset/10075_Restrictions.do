use "$TempData/HouseholdPanelGrades", clear

egen pnr_id = group(pnr)

*Tab the Education Information we need on an individual level
tabout educ_area educ_cat if year == 2019 using "$out/tab_educ_finlit.tex", replace

estpost tabstat educ_lgth_individual, by(educ_cat) stats(mean) columns(statistics)
esttab . using "$out/educ_lgth_educ_cat.tex", cells("mean") replace

* Now restrict the dataset  
keep pnr mor_id far_id familie_id e_faelle_id aegte_id age civst ie_type age_min age_max h_size n_adults n_children male married widow divorced audd_individual educ_lgth_individual educ_type_individual educ_area_individual educ_lgth_mother educ_type_mother educ_area_mother educ_lgth_father educ_type_father educ_area_father educ_lgth_partner educ_type_partner educ_area_partner dispon_13_individual netovskud_13_individual perindkialt_13_individual personindk_individual qaktivf_ny05_individual qaktska qpassivn_individual fin_akt_individual net_fin_akt_individual dispon_13_partner netovskud_13_partner perindkialt_13_partner personindk_partner qaktivf_ny05_partner qpassivn_partner fin_akt_partner net_fin_akt_partner realassets fgb1_individual fgb2_individual fgb3_individual fgb4_individual fgb5_individual fgb7_individual financialassets fgnf_2014_individual totaldebt fgaktiv_2014_partner fgb1_partner fgb2_partner fgb3_partner fgb4_partner fgb5_partner fgb7_partner fgb_2014_partner fgnf_2014_partner fgpassiv_2014_partner year sf hh_income equiv_income hh_income_disp equiv_disp_income beskst13 birthyear cohort5 cohort_start age2 age3 age4 age5 logincome educ_cat educ_area financialassets2 totalassets totalnetassets participationrate kappa kappa_real grundskolekarakter educ_lgth_partner_mother educ_lgth_partner_father educ_area_partner_mother educ_area_partner_father educ_type_partner_father educ_type_partner_mother

* And collapse on the household head (the one with the longest education)
drop if age < 25
drop if age == .
replace educ_lgth_individual = 0 if missing(educ_lgth_individual)
bysort familie_id year (educ_lgth_individual age): keep if _n == _N

* Generate variables for Household Level Assets and Participation Rates
rename fgb_2014_partner  financialassets_partner 
gen financialassets_partner_2 = financialassets_partner	 - fgb1_partner // This is not including cash

gen hh_finassets = financialassets + cond(missing(financialassets_partner), 0 , financialassets_partner)
gen hh_finassets_2 = financialassets2 + cond(missing(financialassets_partner_2), 0 , financialassets_partner_2)
gen hh_kappa = hh_finassets_2 / hh_finassets

gen parents_missing = missing(mor_id) & missing(far_id)
gen inlaws_missing = missing(educ_lgth_partner_father) & missing(educ_lgth_partner_mother)
gen noparents = (parents_missing == 1 & inlaws_missing == 1)
tab ie_type parents_missing
gen businessincome = (netovskud_13_individual != 0)
replace netovskud_13_partner = 0 if missing(netovskud_13_partner)
gen businessincome_partner = (netovskud_13_partner != 0)

* Parents Education
gen educ_lgth_parent = max(educ_lgth_father, educ_lgth_mother)
gen mother_longer = (educ_lgth_mother >= educ_lgth_father)

gen educ_area_parent = educ_area_mother if mother_longer == 1
replace educ_area_parent = educ_area_father if mother_longer == 0

gen educ_type_parent = educ_type_mother if mother_longer == 1
replace educ_type_parent = educ_type_father if mother_longer == 0

drop mother_longer

* In laws education
gen educ_lgth_partner_parent = max(educ_lgth_partner_father, educ_lgth_partner_mother)
gen mother_longer = (educ_lgth_partner_mother >= educ_lgth_partner_father)

gen educ_area_partner_parent = educ_area_partner_mother if mother_longer == 1
replace educ_area_partner_parent = educ_area_partner_father if mother_longer == 0

gen educ_type_partner_parent = educ_type_partner_mother if mother_longer == 1
replace educ_type_partner_parent = educ_type_partner_father if mother_longer == 0

drop mother_longer

replace educ_area_parent = educ_area_father if missing(educ_lgth_mother)
replace educ_area_parent = educ_area_mother if missing(educ_lgth_father)

replace educ_type_parent = educ_type_father if missing(educ_lgth_mother)
replace educ_type_parent = educ_type_mother if missing(educ_lgth_father)

replace educ_area_partner_parent = educ_area_partner_father if missing(educ_lgth_partner_mother)
replace educ_area_partner_parent = educ_area_partner_mother if missing(educ_lgth_partner_father)

replace educ_type_partner_parent = educ_type_partner_father if missing(educ_lgth_partner_mother)
replace educ_type_partner_parent = educ_type_partner_mother if missing(educ_lgth_partner_father)

encode educ_type_mother, gen(educ_cat_mother)
encode educ_type_father, gen(educ_cat_father)

encode educ_area_father, gen(educ_a_father)
encode educ_area_mother, gen(educ_a_mother)
encode educ_area_individual, gen(educ_a)

encode educ_type_parent, gen(educ_cat_parent)
encode educ_area_parent, gen(educ_a_parent)

encode educ_type_partner, gen(educ_cat_partner)
encode educ_area_partner, gen(educ_a_partner)

encode educ_type_partner_parent, gen(educ_cat_partner_parent)
encode educ_area_partner_parent, gen(educ_a_partner_parent)

* Capture if you or your partner are financially literate
gen finlit = 0
replace finlit = 1 if ((educ_cat == 2 | educ_cat == 3) & educ_area != 5) | ((educ_cat_partner == 2 | educ_cat_partner == 3) & educ_a_partner != 5)
replace finlit = 2 if ((educ_cat == 2 | educ_cat == 3) & educ_area == 5) | ((educ_cat_partner == 2 | educ_cat_partner == 3) & educ_a_partner == 5)

* Capture if you or your partner's parents are financially literate
gen finlitparent = 0
replace finlitparent = 1 if ((educ_cat_parent == 2	 | educ_cat_parent == 3) & educ_a_parent != 5)  | ((educ_cat_partner_parent == 2 | educ_cat_partner_parent == 3) & educ_a_partner_parent != 5)
replace finlitparent = 2 if ((educ_cat_parent == 2 | educ_cat_parent == 3) & educ_a_parent == 5) | ((educ_cat_partner_parent == 2 | educ_cat_partner_parent == 3) & educ_a_partner_parent == 5)

* Restrictions
keep if educ_cat == 2 | educ_cat == 3 | educ_cat == 5 	

tabstat equiv_disp_income, by(businessincome) stats(mean p1 p5 p25 p75 p99)

estpost tabstat equiv_disp_income, by(businessincome) stats(mean sd N p1 p10 p50 p90  p99)
eststo t1
esttab t1 using "$out/tab_business_income.tex", cells("mean(fmt(3)) sd(fmt(3)) count(fmt(0)) p1(fmt(3))  p10(fmt(3)) p50(fmt(3)) p90(fmt(3)) p99(fmt(3))") nonumber nomtitle noobs booktabs label unstack replace
eststo clear

drop if businessincome == 1
drop if businessincome_partner == 1

rename equiv_disp_income income

estpost tabstat income, stats(mean SD N p1 p10 p50 p90  p99)
eststo t1
esttab t1 using "$out/tab_income_dist_pre.tex", cells("mean(fmt(3)) sd(fmt(3)) count(fmt(0)) p1(fmt(3))  p10(fmt(3)) p50(fmt(3)) p90(fmt(3)) p99(fmt(3))") nonumber nomtitle noobs booktabs label unstack replace
eststo clear


su income, detail
_pctile income, p(5 99)
drop if income < r(r1) | income > r(r2)

estpost tabstat income, stats(mean SD N p1 p10 p50 p90  p99)
eststo t1
esttab t1 using "$out/tab_income_dist_post.tex", cells("mean(fmt(3)) sd(fmt(3)) count(fmt(0)) p1(fmt(3))  p10(fmt(3)) p50(fmt(3)) p90(fmt(3)) p99(fmt(3))") nonumber nomtitle noobs booktabs label unstack replace
eststo clear

save "$TempData/HouseholdDatasetIncomeAge", replace