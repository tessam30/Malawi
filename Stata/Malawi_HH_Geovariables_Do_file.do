* Describe what is accomplished with file:
* This .do file processed the household GeographicInfo
* Date: 2016/09/16
* Author: Tim Essam, Brent McCusker & Park Muhonda
* Project: WVU Livelihood Analysis for Malawi
********************************************************************

clear
capture log close

* Load the dataset needed to derive household GeographicInfo
use "$wave1/HouseholdGeovariables.dta"

* Extract relevant data
clonevar latitude = lat_modified 
clonevar longitude = lon_modified
keep case_id ea_id longitude latitude dist_*

g year = 2011
compress
save "$pathout/geovars_2011.dta", replace


***** Wave 2 *****
* Process 2nd wave 
* Load the dataset needed to derive household GeographicInfo
use "$wave2/HouseholdGeovariables_IHPS.dta", clear

* Extract relevant data
clonevar latitude = LAT_DD_MOD
clonevar longitude = LON_DD_MOD

keep y2_hhid latitude longitude dist_*

g year = 2013
compress
save "$pathout/geovars_2013.dta", replace

* Append datasets togther; ea_id should be the unique ID
append using "$pathout/geovars_2011.dta"

g id = case_id if year == 2011
replace id = y2_hhid if id == "" & year == 2013

save "$pathout/geovars_all.dta", replace
