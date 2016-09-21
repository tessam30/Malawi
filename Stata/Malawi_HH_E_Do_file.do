* Describe what is accomplished with file:
* This .do file calculates the ganyu labor time for households
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
use "$wave1/HH_MOD_E.dta"

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
qui include "$pathdo/copylabels.do"

ds(case_id id_code hh_e* visit ea_id qx_type), not
collapse (max) `r(varlist)', by(case_id)

qui include "$pathdo/attachlabels.do"

g year = 2011
compress
save "$pathout/hh_dem_wave1.dta", replace


***** Wave 2 *****
* Process 2nd wave 
* Load the dataset needed to derive time use and ganyu variables
use "$wave2/HH_MOD_E.dta"

* water time 
egen totWaterTime = total(hh_e05), by(y2_hhid)
g spouseWaterTime = (hh_e05) if hh_e01 == 2 
g headWaterTime = (hh_e05) if hh_e01 == 1 

* Firewood time 
egen totFirewdTime = total(hh_e06), by(y2_hhid)
g spouseFireTime = (hh_e06) if hh_e01 == 2 
g headFireTime	= (hh_e06) if hh_e01 == 1 

* Ganyu time 
egen totGanyutime = total(hh_e56), by(y2_hhid)
egen maxGanyuTime = max(hh_e56), by(y2_hhid)
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
qui include "$pathdo/copylabels.do"

ds(case_id id_code hh_e* visit ea_id qx_type), not
collapse (max) `r(varlist)', by(y2_hhid)

qui include "$pathdo/attachlabels.do"

g year = 2013
compress
save "$pathout/hh_dem_wave1.dta", replace
