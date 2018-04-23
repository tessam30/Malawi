
* Describe what is accomplished with file:
* This .do file processed household social safetnets  
* Date: 2016/09/16
* Author: Tim Essam, Brent McCusker & Park Muhonda
* Project: WVU Livelihood Analysis for Malawi
********************************************************************

clear
capture log close

* Load the dataset needed to derive time use and ganyu variables
use "$wave1/HH_MOD_R.dta", clear

/* Program 
Free Maize
Free Food (other than Maize)
Food/Cash-for-Work Programme
Inputs-For-Work Programme
School Feeding Programme
Free Distribution of Likuni Phala to Children and Mothers
Supplementary Feeding for Malnourished Children at a Nutritional Rehabilitation Unit
Scholarships/Bursaries for Secondary Education
Scholarships for Tertiary Education
Tertiary Loan Scheme
Direct Cash Transfers from Government
Other Direct Cash Transfers (Specify)
Other (Specify)	*/

#delimit ;
	local plist FreeMaize FreeFood Food4Work Inputs4Work Sch_Feeding LikuniPhala
			Supp_Feeding_Malnourished Scholarships_Sec Scholarships_Tert 
			TertiaryLoan DirectCashTransGovt OtherDirectCashTrans Other;
#delimit cr

local i = 101
foreach x of local plist {
	g rcvd`x' = hh_r0a == `i' & hh_r01 == 1
	la var rcvd`x' "Received `x'"
	display in yellow "`x'	==> program number `i'"
	
	* Iterate over the hh_r0a number
	local i = `++i'
	}
*end

/*
g rcvdFreeMaize = hh_r0a == 101 & hh_r01 == 1
g rcvdFreeFood = hh_r0a == 102 & hh_r01 == 1
g rcvdFood4Work = hh_r0a == 103 & hh_r01 == 1
g rcvdInputs4Work = hh_r0a == 104 & hh_r01 == 1
g rcvdSch_Feeding = hh_r0a == 105 & hh_r01 == 1
g rcvdLikuniPhala = hh_r0a == 106 & hh_r01 == 1
g rcvdSupp_Feeding_Malnourished = hh_r0a == 107 & hh_r01 == 1
g rcvdScholarships_Sec = hh_r0a == 108 & hh_r01 == 1
g rcvdScholarships_Tert = hh_r0a == 109 & hh_r01 == 1
g rcvdTertiaryLoan = hh_r0a == 110 & hh_r01 == 1
g rcvdDirectCashTransGovt = hh_r0a == 111 & hh_r01 == 1
g rcvdOtherDirectCashTrans = hh_r0a == 112 & hh_r01 == 1
g rcvdOther	= hh_r0a == 113 & hh_r01 == 1

la var rcvdFreeMaize "Received Free Maize"
la var rcvdFreeFood "Received Free Food (other than Maize)"
la var rcvdFood4Work "Received Food/Cash-for-Work Programme"
la var rcvdInputs4Work "Received Inputs-For-Work Programme"
la var rcvdSch_Feeding "Received School Feeding Programme"
la var rcvdLikuniPhala "Received Free Distribution of Likuni Phala to Children and Mothers"
la var rcvdSupp_Feeding_Malnourished "Received Supplementary Feeding for Malnourished Children at a Nutritional Rehabilitation Unit"
la var rcvdScholarships_Sec "Received Scholarships/Bursaries for Secondary Education"
la var rcvdScholarships_Tert "Received Scholarships for Tertiary Education"
la var rcvdTertiaryLoan "Received Tertiary Loan Scheme"
la var rcvdDirectCashTransGovt "Received Direct Cash Transfers from Government"
la var rcvdOtherDirectCashTrans  "Received Other Direct Cash Transfers (Specify)"
la var rcvdOther	 "Received Other (Specify)"
*/ 

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
	ds(case_id hh_r* visit ea_id), not
	collapse (max) `r(varlist)', by(case_id)
qui include "$pathdo/attachlabels.do"

* Need to run this after the collapse b/c it will result in 1 as a max b/c data are still long
egen social_safetynet = rowtotal(rcvd*)
la var social_safetynet "total assistance programs recieved by hh"
compress
g year = 2011

sa "$pathout/social_safetynets_2011.dta", replace

***** Wave 2 *****
* Process 2nd wave 
* Load the dataset needed to derive food consuption variables
use "$wave2/HH_MOD_R.dta", clear 

* NOTE: BE CAREFUL; PROGRAM CODES CHANGE
/* 	FreeMaize	101
	FreeFood	102
	Inputs4Work	104
	Sch_Feeding	105
	LikuniPhala	106
	Supp_Feeding_Malnourished	107
	Scholarships_Sec	108
	DirectCashTransGovt	111
	OtherDirectCashTrans	112
	Other	113
	MASF	1031
	Food4Work	1032
	Scholarships_Tert	1091
*/

* Notice that some of the values/programs are missing from the 1st wave.
label list HH_R0A
#delimit ;
local plist "FreeMaize FreeFood Inputs4Work Sch_Feeding LikuniPhala Supp_Feeding_Malnourished
		Scholarships_Sec DirectCashTransGovt OtherDirectCashTrans Other MASF Food4Work
		Scholarships_Tert";
#delimit cr

* Use levels of to create a list of unique values in hh_r0a; Test that the length of the unique values
* is equivalent to that of the plist local macro that is created above. This ensures the variables are 
* mapping correctly
levelsof(hh_r0a), local(levels)
local num : list sizeof local(levels)
local num2: list sizeof local(plist)

*Verify that the numbers balance
assert `num' == `num2'
display in yellow "Unique elements in hh_r0a = `num' ==> Unique categories to be created == `num2'"

forvalues i = 1/`num' {
	local a : word `i' of `plist'
	local b : word `i' of `levels'
	
	g rcvd`a' = hh_r0a == `b' & hh_r01 == 1
	la var rcvd`a' "Received `a'"
	display in yellow "`a'	==> program number `b'"
	}   
*

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
	ds(occ y2_hhid qx_type interview_status hh_* ), not
	collapse (max) `r(varlist)', by(y2_hhid)
qui include "$pathdo/attachlabels.do"

egen social_safetynet = rowtotal(rcvd*)
la var social_safetynet "total assistance programs recieved by hh"
compress
g year = 2013

sa "$pathout/social_safetynets_2013.dta", replace

* Append together
append using "$pathout/social_safetynets_2011.dta"
order case_id y2_hhid year


clonevar id = case_id
replace id = y2_hhid if id == "" & year == 2013
save "$pathout/social_safetynets_all.dta", replace
