* Describe what is accomplished with file:
* This .do file processed the household GeographicInfo
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

* Load the dataset needed to derive household GeographicInfo
use "$wave1/HouseholdGeovariables.dta"

* Extract relevant data
clonevar latitude = lat_modified 
clonevar longitude = lon_modified
keep case_id ea_id longitude latitude

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

keep y2_hhid latitude longitude

g year = 2013
compress
save "$pathout/geovars_2013.dta", replace
