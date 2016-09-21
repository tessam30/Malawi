* Describe what is accomplished with file:
* This .do file processed the household education variables
* Date: 2016/09/16
* Author: Brent McCusker, Park Muhonda & Tim Essam
* Project: WVU Livelihood Analysis for Malawi
********************************************************************


capture log close
clear

* Load the dataset needed to derive education variables
use "$wave1/HH_MOD_C.dta", clear

** What is the purpose of the code below? What do you want it to accomplish?
* The first 1/2 seems redundant to the demographic processing.
**********************************************************************
* Data processing 
///This may not be true. Need to link back to hh roster.
g byte hoh =  hh_c01 == 1  
la var hoh "Head of household"

///Same as above
g byte spouse =  hh_c01 == 2
la var spouse "spouse of hoh"

* --- Education levels 
* no need to drop values that take on 8 because there is none
g educHoh = hh_c09 if hoh == 1
g educSpouse = hh_c09 if spouse == 1
egen educAdult =  max(hh_c09), by(case_id)

la var educHoh "Education of Hoh"
la var educSpouse "Education of spouse"
la var educAdult "Highest adult education in household"

* --- Distance to school in time  
* convert values that are in hours into minutes 
replace hh_c19a = (hh_c19a*60) if hh_c19b == 2

* I think you want these variables to be continuous not binaries
* Also, these are listed for each hh roster member, you'll have to 
* figure out what level you want this data collapsed. Do you want it collapsed
* for each member of the hh roster?
g timeFoot =  hh_c19a if hh_c18 == 1
g timeBicycle =  hh_c19a if hh_c18 == 2
g timeMinibus =  hh_c19a if hh_c18 == 3
g timePvtVehicle =  hh_c19a if hh_c18 == 4
g timeOther =  hh_c19a if hh_c18 == 5

la var timeFoot "Distance to school in minutes by foot"
la var timeBicycle "Distance to school in minutes by bicycle"
la var timeMinibus "Distance to school in minutes by bus/minibus"
la var timePvtVehicle "Distance to school in minutes by Pvt Vehicle"
la var timeOther "Distance to school in minutes by other"

*collapse
qui include "$pathdo/copylabels.do"

ds(case_id id_code hh_c* visit ea_id ), not
collapse (max) `r(varlist)', by(case_id)

qui include "$pathdo/attachlabels.do"

g year = 2011
compress
* I don't think you want to do this, it will overwrite your other file
*save "$pathout/hh_dem_wave1.dta", replace
save "$pathout/hh_dem_modC_wave1.dta", replace


***** Wave 2 *****
* Process 2nd wave 
* Load the dataset needed to derive education variables
use "$wave2/HH_MOD_C.dta", clear

** What is the purpose of the code below? What do you want it to accomplish?
* The first 1/2 seems redundant to the demographic processing.
**********************************************************************
* Data processing 
g byte hoh =  hh_c01 == 1
la var hoh "Head of household"

g byte spouse =  hh_c01 == 2
la var spouse "spouse of hoh"

* --- Education levels 
* no need to drop values that take on 8 because there is none
g educHoh = hh_c09 if hoh == 1
g educSpouse = hh_c09 if spouse == 1
egen educAdult =  max(hh_c09), by(y2_hhid)

la var educHoh "Education of Hoh"
la var educSpouse "Education of spouse"
la var educAdult "Highest adult education in household"

* --- Distance to school in time  
* convert values that are in hours into minutes 
replace hh_c19a = (hh_c19a*60) if hh_c19b == 2

g byte timeFoot =  hh_c19a if hh_c18 == 1
g byte timeBicycle =  hh_c19a if hh_c18 == 2
g byte timeMinibus =  hh_c19a if hh_c18 == 3
g byte timePvtVehicle =  hh_c19a if hh_c18 == 4
g byte timeOther =  hh_c19a if hh_c18 == 5

la var timeFoot "Distance to school in minutes by foot"
la var timeBicycle "Distance to school in minutes by bicycle"
la var timeMinibus "Distance to school in minutes by bus/minibus"
la var timePvtVehicle "Distance to school in minutes by Pvt Vehicle"
la var timeOther "Distance to school in minutes by other"

*collapse
qui include "$pathdo/copylabels.do"

ds(y2_hhid hh_c*  qx_type occ interview_status PID), not
collapse (max) `r(varlist)', by(y2_hhid)

qui include "$pathdo/attachlabels.do"

g year = 2013
compress
save "$pathout/hh_dem_modC_wave2.dta", replace
