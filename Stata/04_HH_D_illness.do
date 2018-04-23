* Describe what is accomplished with file:
* This .do file processes household illnesses
* Date: 2016/09/16; 2018/04/20
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

* Who was ill?
g byte illnessHoh = (hh_d04 == 1) & hh_b04 == 1
g byte illnessSpouse = (hh_d04 ==1) & hh_b04 == 2
g byte illnessChild = (hh_d04 ==1) & hh_b04 == 3


* What type?
*clonevar illness_injuryType =  hh_d05a
g byte malariaHoh = ((hh_d05a == 1) & illnessHoh == 1)
g byte malariaSpouse = ((hh_d05a == 1) & illnessSpouse == 1)
g byte malariaChild = ((hh_d05a == 1) & illnessChild == 1)
g byte malariaAny = (hh_d05a == 1)

la var illnessHoh "head of household sick in last 2 weeks"
la var illnessSpouse "spouse sick in last 2 weeks"
la var illnessChild "at least one child sick last 2 weeks"
la var malariaAny "anyone reported malaria like symptoms"
la var malariaHoh "hoh malaria like symptoms"
la var malariaSpouse "spouse malaria like symptoms"
la var malariaChild "any child reported malaria like symptoms"


* Household chronic illness
g byte chlonicillness = (hh_d33 == 1)
egen totchronicIllness = total(chlonicillness), by(case_id)
la var totchronicIllness "Total hh members suffer from chronicillness"

la var illness_2wk "illness/injury in last 14 days"
la var chlonicillness "hh member(s) suffering from chronicillness"

*collapse
qui include "$pathdo/copylabels.do"

ds(case_id id_code hh_* visit status district _rost* ea_id qx_type region), not
collapse (max) `r(varlist)', by(case_id)

qui include "$pathdo/attachlabels.do"

compress
save "$pathout/illness_2011.dta", replace






* ---- Wave 3 2016
use "$wave3/HH_MOD_D.dta", clear
merge 1:1 case_id PID using "$wave3/HH_MOD_B.dta", gen(_roster)
merge 1:1 case_id PID using "$pathout/hh_base_2016.dta", gen(_rosterKeep)
keep if _rosterKeep == 3

* --- Who had illnesses in the last week?
g byte illness_2wk = (hh_d04 == 1)
egen totIllness_2wk = total(illness_2wk), by(case_id)

g byte illnessHoh = (hh_d04 == 1) & hh_b04 == 1
g byte illnessSpouse = (hh_d04 ==1) & hh_b04 == 2
g byte illnessChild = (hh_d04 ==1) & hh_b04 == 3

* What type?
g byte malariaHoh = ((hh_d05a == 1) & illnessHoh == 1)
g byte malariaSpouse = ((hh_d05a == 1) & illnessSpouse == 1)
g byte malariaChild = ((hh_d05a == 1) & illnessChild == 1)
g byte malariaAny = (hh_d05a == 1)

la var illnessHoh "head of household sick in last 2 weeks"
la var illnessSpouse "spouse sick in last 2 weeks"
la var illnessChild "at least one child sick last 2 weeks"
la var malariaAny "anyone reported malaria like symptoms"
la var malariaHoh "hoh malaria like symptoms"
la var malariaSpouse "spouse malaria like symptoms"
la var malariaChild "any child reported malaria like symptoms"

* ---- Collapse down to hh level
qui include "$pathdo/copylabels.do"

  ds(case_id HHID PID hh_d* hh_b* _roster hhsize ea_id region district reside interviewDate hh_wgt _rosterKeep), not
  collapse (max) `r(varlist)', by(case_id)

qui include "$pathdo/attachlabels.do"


g year = 2016
compress
save "$pathout/illness_2016.dta", replace
