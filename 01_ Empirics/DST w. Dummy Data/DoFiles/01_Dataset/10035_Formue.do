* Log
cap log close
log using "$logs\\${date}_10035_Formue.txt", replace
clear all

* Load rawdata
forval x = 2014/2024 {
use "$rawdata/FORMPERS`x'", clear

keep pnr fgaktiv_2014 fgb1 fgb2 fgb3 fgb4 fgb5  fgb7 fgb_2014 fgnf_2014 fgpassiv_2014

egen seq_n = seq(), by(pnr)
egen max_n = max(seq_n), by(pnr)
drop if max_n > 1
drop seq_n max_n

save "$TempData/Formue_`x'", replace

}

cap log close