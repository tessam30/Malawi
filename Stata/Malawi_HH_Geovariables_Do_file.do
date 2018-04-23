* Describe what is accomplished with file:
* This .do file processed the household GeographicInfo
* Date: 2016/09/16; Updated 2018/04/19
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

***** Wave 3 ******
* Process 3rd wave
* Load the dataset need for GIS info
use "$wave3/HouseholdGeovariablesIHS4.dta", clear

* extract relevant geographic information
clonevar latitude = lat_modified
clonevar longitude = lon_modified

keep case_id HHID latitude longitude dist_*
 
g year = 2016
compress
save "$pathout/geovars_2016.dta", replace

* Append datasets togther; ea_id should be the unique ID
use "$pathout/geovars_2013.dta", clear
append using "$pathout/geovars_2011.dta"

g id = case_id if year == 2011
replace id = y2_hhid if id == "" & year == 2013
save "$pathout/geovars_all.dta", replace

* Create a fully appended dataset that includes all waves of data (2011, 2013, 2016)

append using "$pathout/geovars_2016.dta"
replace id = case_id if year == 2016 & id == ""
save "$pathout/geovars_full.dta", replace




