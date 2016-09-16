* Describe what is accomplished with file:
* This .do file calculates the ganyu labor time for households
* Date: 2016/09/16
* Author: Park Muhonda & Tim Essam
* Project: WVU Livelihood Analysis for Malawi
********************************************************************



clear
capture log close
use "$wave1/HH_MOD_D.dta"

* water time 
egen totWaterTime = total(hh_e05), by(case_id)
g spouseWaterTime = (hh_e05) if hh_e01 == 2 
g headWaterTime = (hh_e05) if hh_e01 == 1 

* Firewood time 
egen totFirewdTime = total(hh_e06), by(case_id)
g spouseFireTime = (hh_e06) if hh_e01 == 2 
g headFireTime	= (hh_e06) if hh_e01 == 1 

* Ganyu time 
egen totGanyutime = total(hh_e56), by(case_id)
egen maxGanyuTime = max(hh_e56), by(case_id)
g spouseGanyuTime = (hh_e56) if hh_e01 == 2 
g headGanyuTime	= (hh_e56) if hh_e01 == 1 

la var totWaterTime "Total household time spent on water collection"
la var spouseWaterTime "Total spouse time spent on water collection"
la var headWaterTime "Total time hh head spent on water collection"
la var totFirewdTime "Total household time spent on firewood collection"
la var spouseFireTime "Total spouse time spent on firewood collection"
la var headFireTime "Total hoh time spent on firewood collection"
la var totGanyutime "Total time spent on Ganyu activities in past 12months"
la var spouseGanyuTime "Total spouse time spent on Ganyu activities in past 12months"
la var headGanyuTime "Total hh of houdehold time spent on Ganyu activities in past 12months"
la var maxGanyuTime "Maximum time a household member spent on Ganyu activities in the past 12months"

*collapse
qui include "/Users/student/Desktop/LAM MALAWI_STATA/DataProcessing/copylabels.do"

ds(case_id id_code hh_e01), not
collapse (max) `r(varlist)', by(case_id)

qui include "/Users/student/Desktop/LAM MALAWI_STATA/DataProcessing/attachlables.do"


