* Describe what is accomplished with file:
* This .do file processed the household education variables
* Date: 2016/09/16
* Author: Tim Essam, Brent McCusker & Park Muhonda
* Project: WVU Livelihood Analysis for Malawi
********************************************************************


capture log close
clear

* Load the dataset needed to derive education variables
use "$wave1/HH_MOD_C.dta", clear
merge 1:1 case_id id_code using "$wave1/HH_MOD_B.dta", gen(_roster)
merge 1:1 case_id id_code using "$pathout/hh_roster_2011.dta", gen(_rosterKeep)
drop if _rosterKeep == 1 | _roster == 2

** What is the purpose of the code below? What do you want it to accomplish?
* The first 1/2 seems redundant to the demographic processing.
**********************************************************************
* Data processing
///This may not be true. Need to link back to hh roster. -- Resolved
g byte hoh =  hh_b04 == 1
la var hoh "Head of household"

///Same as above
g byte spouse =  hh_b04 == 2
la var spouse "spouse of hoh"

* --- Education levels
* no need to drop values that take on 8 because there is none
g educHoh = hh_c09 if hoh == 1
g educSpouse = hh_c09 if spouse == 1
egen educAdult =  max(hh_c09), by(case_id)
g litHeadEng = inlist(1, hh_c05b) if hoh == 1
g litHeadChich = inlist(1, hh_c05a) if hoh == 1

la var educHoh "Education of Hoh"
la var educSpouse "Education of spouse"
la var educAdult "Highest adult education in household"
la var litHeadChich "Head is literate in Chichewa"
la var litHeadEng "Head is literate in English"

* --- Distance to school in time
* convert values that are in hours into minutes ]
* Don't overwrite raw values in data; create clones and modify instead
clonevar schoolTime = hh_c19a
replace schoolTime = (schoolTime*60) if hh_c19b == 2

* I think you want these variables to be continuous not binaries
* Also, these are listed for each hh roster member, you'll have to
* figure out what level you want this data collapsed. Do you want it collapsed
* for each member of the hh roster?
g timeFoot =  schoolTime if hh_c18 == 1
g timeBicycle =  schoolTime if hh_c18 == 2
g timeMinibus =  schoolTime if hh_c18 == 3
g timePvtVehicle =  schoolTime if hh_c18 == 4
g timeOther =  schoolTime if hh_c18 == 5

la var timeFoot "Distance to school in minutes by foot"
la var timeBicycle "Distance to school in minutes by bicycle"
la var timeMinibus "Distance to school in minutes by bus/minibus"
la var timePvtVehicle "Distance to school in minutes by Pvt Vehicle"
la var timeOther "Distance to school in minutes by other"

* Need to determine the household members for which you want to collapse the time variables
* As they stand, they are created for each member of the household. What is important to you?

*collapse
qui include "$pathdo/copylabels.do"
	ds(case_id id_code hh_c* visit ea_id hh_* _roster qx_type), not
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
merge 1:1 y2_hhid PID using "$wave2/HH_MOD_B.dta", gen(_roster)
merge 1:1 y2_hhid PID using "$pathout/hh_roster_2013.dta", gen(_rosterKeep)
drop if _rosterKeep == 1 | _roster == 2

* Remove non-household members
drop if hhmember == 0

** What is the purpose of the code below? What do you want it to accomplish?
* The first 1/2 seems redundant to the demographic processing.
**********************************************************************
* Data processing
g byte hoh =  hh_b04 == 1
la var hoh "Head of household"

g byte spouse =  hh_b04 == 2
la var spouse "spouse of hoh"

* --- Education levels
* no need to drop values that take on 8 because there is none
g educHoh = hh_c09 if hoh == 1
g educSpouse = hh_c09 if spouse == 1
egen educAdult =  max(hh_c09), by(y2_hhid)
g litHeadEng = inlist(1, hh_c05b) if hoh == 1
g litHeadChich = inlist(1, hh_c05a) if hoh == 1

la var educHoh "Education of Hoh"
la var educSpouse "Education of spouse"
la var educAdult "Highest adult education in household"
la var litHeadChich "Head is literate in Chichewa"
la var litHeadEng "Head is literate in English"

* --- Distance to school in time
* convert values that are in hours into minutes
clonevar schoolTime = hh_c19a
replace schoolTime = (schoolTime*60) if hh_c19b == 2

g byte timeFoot =  schoolTime if hh_c18 == 1
g byte timeBicycle =  schoolTime if hh_c18 == 2
g byte timeMinibus =  schoolTime if hh_c18 == 3
g byte timePvtVehicle =  schoolTime if hh_c18 == 4
g byte timeOther =  schoolTime if hh_c18 == 5

la var timeFoot "Distance to school in minutes by foot"
la var timeBicycle "Distance to school in minutes by bicycle"
la var timeMinibus "Distance to school in minutes by bus/minibus"
la var timePvtVehicle "Distance to school in minutes by Pvt Vehicle"
la var timeOther "Distance to school in minutes by other"

*collapse
qui include "$pathdo/copylabels.do"
	ds(y2_hhid hh_c*  qx_type occ interview_status PID _roster /*
		*/ hh_* hhmember baseline* mover* individualmover), not
	collapse (max) `r(varlist)', by(y2_hhid)

qui include "$pathdo/attachlabels.do"

g year = 2013
compress
save "$pathout/hh_dem_modC_wave2.dta", replace

* append together
append using "$pathout/hh_dem_modC_wave1.dta"

clonevar id = case_id
replace id = y2_hhid if id == "" & year == 2013
save "$pathout/hh_dem_modC_all.dta", replace

* ---- Wave 3: 2016 data
clear
use "$wave3/HH_MOD_C.dta"
merge 1:1 case_id PID using "$wave3/HH_MOD_B.dta", gen(_rosterKeep)
* Everyone merged

* Idenfity hoh and spouse to create their education profiles
g byte hoh = hh_b04 == 1
la var hoh "head of household"

g byte spouse = hh_b04 == 2
la var spouse "spouse"

* ---- Education levels
g educHoh = hh_c09 if hoh == 1
g educSpouse = hh_c09 if spouse == 1
egen educAdult = max(hh_c09), by(case_id)

g litHeadEng = inlist(1, hh_c05b) if hoh == 1
g litHeadChich = inlist(1, hh_c05a) if hoh == 1

la var educHoh "Education of hoh"
la var educSpouse "Education spouse"
la var educAdult "max education in household"
la var litHeadEng "Head is literate in English"
la var litHeadChich "Head is literate in Chichewa"

* ---- Distance to school
/*clonevar schoolTime = hh_c19a
replace schoolTime = (schoolTime * 60) if hh_c19b == 2
la var schoolTime "time to get to school in minutes"
*/

* --- Collapse and save for merging/appending
qui include "$pathdo/copylabels.do"
	ds(case_id hh_c* hh_b* PID HHID _rosterKeep), not
	collapse (max) 	`r(varlist)', by(case_id)
qui include "$pathdo/attachlabels.do"

g year = 2016
compress

save "$pathout/hh_educ_2016.dta", replace
