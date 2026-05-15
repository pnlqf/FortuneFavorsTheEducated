*********************************************************************************************************************
* EDUCATIONAL DATA FROM THE MINISTRY OF EDUCATION (REGISTRY: UDDA)
*********************************************************************************************************************
* Log
cap log close
log using "$logs\\${date}_10040_Merge.txt", replace
clear all
*Loop over years
forval x = 2014/2024	 {
		*-------------------------------------------------------------------*
		* Start with Demographics Data
		*-------------------------------------------------------------------*
		
		use "$TempData/Demo_`x'", clear
		
		*-------------------------------------------------------------------*
		* Merge individual's education	
		*-------------------------------------------------------------------*
		merge 1:1 pnr using "$TempData/Educ_`x'"
		drop if _merge == 2
		rename _merge Merge_educ_individual
		rename audd audd_individual
		rename educ_lgth educ_lgth_individual
		rename educ_type educ_type_individual
		rename educ_area educ_area_individual
		
		*-------------------------------------------------------------------*
		* Merge mother's education
		*-------------------------------------------------------------------*
		rename pnr pnr_individual
		rename mor_id pnr
		
		merge m:1 pnr using "$TempData/Educ_`x'", keepusing(educ_lgth educ_area educ_type) 
		
		rename educ_lgth educ_lgth_mother
		rename educ_area educ_area_mother
		rename educ_type educ_type_mother
		drop if _merge ==2
		rename _merge merge_educ_mother
		
		rename pnr mor_id
		rename pnr_individual pnr
		
		*-------------------------------------------------------------------*
		* Merge father's education
		*-------------------------------------------------------------------*
		rename pnr pnr_individual
		rename far_id pnr
		
		merge m:1 pnr using "$TempData/Educ_`x'", keepusing(educ_lgth educ_area educ_type) 
		
		rename educ_lgth educ_lgth_father
		rename educ_area educ_area_father
		rename educ_type educ_type_father
		drop if _merge ==2
		rename _merge merge_educ_father
		
		rename pnr far_id
		rename pnr_individual pnr
		
		*-------------------------------------------------------------------*
		* Merge partners's education
		*-------------------------------------------------------------------*
		rename pnr pnr_individual
		rename e_faelle_id pnr
		
		merge m:1 pnr using "$TempData/Educ_`x'", keepusing(educ_lgth educ_area educ_type) 
		
		rename educ_lgth educ_lgth_partner
		rename educ_area educ_area_partner
		rename educ_type educ_type_partner
		drop if _merge ==2
		rename _merge merge_educ_partner
		
		rename pnr e_faelle_id
		rename pnr_individual pnr
		
		
		*-------------------------------------------------------------------*
		* Merge partners's mother education
		*-------------------------------------------------------------------*
		rename pnr pnr_individual
		rename mor_id_partner pnr
		
		merge m:1 pnr using "$TempData/Educ_`x'", keepusing(educ_lgth educ_area educ_type) 
		
		rename educ_lgth educ_lgth_partner_mother
		rename educ_area educ_area_partner_mother
		rename educ_type educ_type_partner_mother
		drop if _merge ==2
		rename _merge merge_educ_partner_mother
		
		rename pnr mor_id_partner
		rename pnr_individual pnr

		*-------------------------------------------------------------------*
		* Merge partners's father education
		*-------------------------------------------------------------------*
		rename pnr pnr_individual
		rename far_id_partner pnr
		
		merge m:1 pnr using "$TempData/Educ_`x'", keepusing(educ_lgth educ_area educ_type) 
		
		rename educ_lgth educ_lgth_partner_father
		rename educ_area educ_area_partner_father
		rename educ_type educ_type_partner_father
		drop if _merge ==2
		rename _merge merge_educ_partner_father
		
		rename pnr far_id_partner
		rename pnr_individual pnr	
		
		*-------------------------------------------------------------------*
		* Merge individual's income
		*-------------------------------------------------------------------*
		merge 1:1 pnr using "$TempData/Inco_`x'"
		drop if _merge == 2
		rename _merge merge_income
		
		rename personindk personindk_individual
		rename netovskud_13 netovskud_13_individual
		rename perindkialt_13 perindkialt_13_individual
		rename qaktivf_ny05 qaktivf_ny05_individual
		rename qpassivn qpassivn_individual
		rename fin_akt fin_akt_individual
		rename net_fin_akt net_fin_akt_individual
		rename dispon_13 dispon_13_individual
				
		*-------------------------------------------------------------------*
		* Merge partners's income
		*-------------------------------------------------------------------*
		rename pnr pnr_
		rename e_faelle_id pnr
		merge m:1 pnr using "$TempData/Inco_`x'"
		drop if _merge == 2
		rename _merge merge_income_partner
		
		rename pnr e_faelle_id
		rename pnr_ pnr
		
		rename personindk personindk_partner
		rename perindkialt_13 perindkialt_13_partner
		rename netovskud_13 netovskud_13_partner
		rename qaktivf_ny05 qaktivf_ny05_partner
		rename qpassivn qpassivn_partner
		rename fin_akt fin_akt_partner
		rename net_fin_akt net_fin_akt_partner
		rename dispon_13 dispon_13_partner
		
		
		*-------------------------------------------------------------------*
		* Merge individual's formue
		*-------------------------------------------------------------------*
		merge m:1 pnr using "$TempData/Formue_`x'"
		drop if _merge == 2
		drop _merge
		
		rename fgaktiv_2014 fgaktiv_2014_individual
		rename fgb1 fgb1_individual
		rename fgb2 fgb2_individual 
		rename fgb3 fgb3_individual 
		rename fgb4 fgb4_individual 
		rename fgb5  fgb5_individual  
		rename fgb7 fgb7_individual 
		rename fgb_2014 fgb_2014_individual 
		rename fgnf_2014 fgnf_2014_individual 
		rename fgpassiv_2014 fgpassiv_2014_individual
		
		*-------------------------------------------------------------------*
		* Merge partner's formue
		*-------------------------------------------------------------------*
		rename pnr pnr_
		rename e_faelle_id pnr
		
		merge m:1 pnr using "$TempData/Formue_`x'"
		drop if _merge == 2
		drop _merge
		
		rename pnr e_faelle_id
		rename pnr_ pnr
		
		
		rename fgaktiv_2014 fgaktiv_2014_partner
		rename fgb1 fgb1_partner
		rename fgb2 fgb2_partner 
		rename fgb3 fgb3_partner 
		rename fgb4 fgb4_partner 
		rename fgb5  fgb5_partner  
		rename fgb7 fgb7_partner 
		rename fgb_2014 fgb_2014_partner 
		rename fgnf_2014 fgnf_2014_partner 
		rename fgpassiv_2014 fgpassiv_2014_partner
		
		compress
		
		save "$TempData/DemoEducInco_`x'", replace
}











