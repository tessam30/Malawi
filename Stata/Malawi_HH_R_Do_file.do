* Describe what is accomplished with file:
* This .do file processed household social safetnets  
* Date: 2016/09/16
* Author: Brent McCusker, Park Muhonda & Tim Essam
* Project: WVU Livelihood Analysis for Malawi
********************************************************************

clear
capture log close

* Read in the data you are using; Use relative paths whenver possible
/* Note: I store the raw data in two folders called wave1 and wave 2.
I then point to them using global macros. This keeps the code general
and allows me to port it across machines by only changing the macro and
not any hard-coded depedencies. */

global wave1 "C:/Users/student/Documents/Malawi/Datain/wave1"
global wave2 "C:/Users/student/Documents/Malawi/Datain/wave2"
global pathout "C:/Users/student/Documents/Malawi/Dataout"
*global pathdo "C:/Users/student/Documents/GitHub/Malawi/Stata"

* Load the dataset needed to derive time use and ganyu variables
use "$wave1/HH_MOD_R.dta"

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

egen social_safetynet = rowtotal(rcvdFreeMaize rcvdFreeFood rcvdFood4Work rcvdInputs4Work rcvdSch_Feeding rcvdLikuniPhala rcvdSupp_Feeding_Malnourished rcvdScholarships_Sec rcvdScholarships_Tert rcvdTertiaryLoan rcvdDirectCashTransGovt rcvdOtherDirectCashTrans rcvdOther)

* Keep derived data (FCS & dietary diversity scores) and HHID
ds(hh_s* saq* ea_id), not
keep `r(varlist)'

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
ds(case_id), not
collapse (max) `r(varlist)', by(case_id)
qui include "$pathdo/attachlabels.do"


sa "$pathout/social_safetynets_2011.dta", replace

***** Wave 2 *****
* Process 2nd wave 
* Load the dataset needed to derive food consuption variables
clear
use "$wave2/HH_MOD_R.dta"

/* Program 
Free Maize
Free Food (other than Maize)
MASAF - Public Works Programme
Food/Cash-for-Work Programme
Inputs-For-Work Programme
School Feeding Programme
Free Distribution of Likuni Phala to Children and Mothers
Supplementary Feeding for Malnourished Children at a Nutritional Rehabilitation Unit
Scholarships/Bursaries for Secondary Education
Scholarships for Tertiary Education
Direct Cash Transfers from Government
Other Direct Cash Transfers (Specify)
Other (Specify)	*/

g rcvdFreeMaize = hh_r0a == 101 & hh_r01 == 1
g rcvdFreeFood = hh_r0a == 102 & hh_r01 == 1
g rcvdMASAF = hh_r0a == 1031 & hh_r01 == 1
g rcvdFood4Work = hh_r0a == 1032 & hh_r01 == 1
g rcvdInputs4Work = hh_r0a == 104 & hh_r01 == 1
g rcvdSch_Feeding = hh_r0a == 105 & hh_r01 == 1
g rcvdLikuniPhala = hh_r0a == 106 & hh_r01 == 1
g rcvdSupp_Feeding_Malnourished = hh_r0a == 107 & hh_r01 == 1
g rcvdScholarships_Sec = hh_r0a == 108 & hh_r01 == 1
g rcvdScholarships_Tert = hh_r0a == 1091 & hh_r01 == 1
g rcvdDirectCashTransGovt = hh_r0a == 111 & hh_r01 == 1
g rcvdOtherDirectCashTrans = hh_r0a == 112 & hh_r01 == 1
g rcvdOther	= hh_r0a == 113 & hh_r01 == 1

la var rcvdFreeMaize "Received Free Maize"
la var rcvdFreeFood "Received Free Food (other than Maize)"
la var rcvdMASAF "MASAF - Public Works Programme)"
la var rcvdFood4Work "Received Food/Cash-for-Work Programme"
la var rcvdInputs4Work "Received Inputs-For-Work Programme"
la var rcvdSch_Feeding "Received School Feeding Programme"
la var rcvdLikuniPhala "Received Free Distribution of Likuni Phala to Children and Mothers"
la var rcvdSupp_Feeding_Malnourished "Received Supplementary Feeding for Malnourished Children at a Nutritional Rehabilitation Unit"
la var rcvdScholarships_Sec "Received Scholarships/Bursaries for Secondary Education"
la var rcvdScholarships_Tert "Received Scholarships for Tertiary Education"
la var rcvdDirectCashTransGovt "Received Direct Cash Transfers from Government"
la var rcvdOtherDirectCashTrans  "Received Other Direct Cash Transfers (Specify)"
la var rcvdOther	 "Received Other (Specify)"

egen social_safetynet = rowtotal(rcvdFreeMaize rcvdFreeFood rcvdMASAF rcvdFood4Work rcvdInputs4Work rcvdSch_Feeding rcvdLikuniPhala rcvdSupp_Feeding_Malnourished rcvdScholarships_Sec rcvdScholarships_Tert rcvdDirectCashTransGovt rcvdOtherDirectCashTrans rcvdOther)

* Keep derived data (FCS & dietary diversity scores) and HHID
ds(hh_s* saq* ea_id), not
keep `r(varlist)'

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
ds(case_id), not
collapse (max) `r(varlist)', by(case_id)
qui include "$pathdo/attachlabels.do"


sa "$pathout/social_safetynets_2013.dta", replace
