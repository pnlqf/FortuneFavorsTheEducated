forval x = 2014/2024{
	use "$rawdata/bef`x'12", clear
	drop if pnr == ""
	duplicates drop
	
	tempfile main
	save `main'
		
	keep pnr mor_id far_id
	rename pnr e_faelle_id
	rename mor_id mor_id_partner
	rename far_id far_id_partner

	tempfile partner_parents
	save `partner_parents'
	
	use `main', clear
	merge m:1 e_faelle_id using `partner_parents', keep(master match) nogen

	*-------------------------------------------------------------------*
	* Rename variables
	*-------------------------------------------------------------------*

	* Identify children in household by:
	** Checking first 10 positions in the household sorted by age
	** Count how many household members have this person as parent
	sort familie_id alder
	forval i = 1(1) 10 {
		by familie_id: gen child_of_mother_`i' = (pnr[`i'] == mor_id) & mor_id != ""
		by familie_id: gen child_of_father_`i' = (pnr[`i'] == far_id) & far_id != ""
	}

	egen child_m = rowtotal(child_of_mother_*)
	egen child_f = rowtotal(child_of_father_*)

	drop child_of_mother_*
	drop child_of_father_*

	* Household Size
	egen h_size = count(familie_id), by(familie_id)
	gen adult = alder >= 15
	gen child = alder < 15
	
	bys familie_id: egen n_adults = total(adult)
	bys familie_id: egen n_children = total(child)
	
	* Individual Level Demo
	gen male = (koen==1)
	drop koen

	gen married =(civst=="G")
	gen widow = (civst=="E")
	gen divorced= (civst=="F")

	* Household Level Demo
	egen age_min = min(alder), by(familie_id)
	egen age_max = max(alder), by(familie_id)

	save "$TempData/Demo_`x'", replace
}


