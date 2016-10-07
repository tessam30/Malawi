* Describe what is accomplished with file:
* This .do file processes household illnesses
* Date: 2016/09/16
* Author: Tim Essam, Brent McCusker & Park Muhonda
* Project: WVU Livelihood Analysis for Malawi
********************************************************************


clear
capture log close
use "$wave1/HH_MOD_D.dta"
merge 1:1 case_id id_code using "$wave1/HH_MOD_B.dta", gen(_roster)
merge 1:1 case_id id_code using "$pathout/hh_roster_2011.dta", gen(_rosterKeep)
drop if _rosterKeep == 1 | _roster == 2



* What is itention of creating the following variables? Are you iterested
* whether or not the household has any illness or that it is mainly in the 
* population of economically active individuals? Remember, most of your analysis
* is going to be at the household level. So carefully think about how you intend
* to use/analyze the variables before they are created. If you really care about 
* total instances of illness in a hh in the last week you will also want to restrict
* this to normal household membmers. To derive this informaiton you'll likely have to
* modify the HH_B data processing .do file

* Household illness past 2weeks
g byte illness_2wk = (hh_d04 == 1)
egen totIllness_2wk = total(illness_2wk), by(case_id)
la var totIllness_2wk "Total hh members suffered illness/injury in last two weeks"

* What type?
clonevar illness_injuryType =  hh_d05a

* Household chronic illness 
g byte chlonicillness = (hh_d33 == 1)
egen totchronicIllness = total(chlonicillness), by(case_id)
la var totchronicIllness "Total hh members suffer from chronicillness"

la var illness_2wk "illness/injury in last 14 days"
la var chlonicillness "hh member(s) suffering from chronicillness"

*collapse
qui include "/Users/student/Desktop/LAM MALAWI_STATA/DataProcessing/copylabels.do"

ds(case_id id_code hh_c01), not
collapse (max) `r(varlist)', by(case_id)

qui include "/Users/student/Desktop/LAM MALAWI_STATA/DataProcessing/attachlables.do"

