*********************************************************************************************************************
* FINANCIAL WEALTH FROM DANISH TAX AUTHORITIES (SKAT)
* Create Data Set for Financial Wealth
* Variables created: 
	* Netwealth
	* Assets
	* Debt 
	* Income 
	* Housing Assets 
	* Mortgage 
	* Bank Loan 
	* Private Loan (Mortgage deeds)
	* Stocks 
	* Bonds 
	* Bank Deposits
	* Financial Assets = bankdeposits + bonds + stocks + otherbonds
	* Net Financial Assets = Financial Assets - bankloan, i.e. non-house debt
*********************************************************************************************************************

* Log
cap log close
log using "$logs\\${date}_10020_FinancialWealth.txt", replace
clear all

* Load rawdata
forval x = 2014/2024 {
use "$rawdata/ind`x'", clear

gen fin_akt = bankakt + oblakt + kursakt + pantakt
gen net_fin_akt = (bankakt + oblakt + kursakt + pantakt) - (bankgaeld)
keep pnr personindk perindkialt_13 qaktivf_ny05 qpassivn fin_akt net_fin_akt aktieindk qaktska netovskud_13 dispon_13

egen seq_n = seq(), by(pnr)
egen max_n = max(seq_n), by(pnr)
drop if max_n > 1
drop seq_n max_n

save "$TempData/Inco_`x'", replace

}

cap log close

