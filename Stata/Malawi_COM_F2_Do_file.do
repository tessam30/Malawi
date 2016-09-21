* Describe what is accomplished with file:
* This .do file processed agriculture    
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
use "$wave2/COM_MOD_F2.dta", clear

/* Project  
Do you want to know more about the ag projects? The types of assistance they are providing?*/

g byte Agr_prjct = inlist(com_cf28, 1)
la var Agr_prjct "Presence of any agricultural project in the community" 

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
ds(ea_id occ com_c*), not
collapse (max) `r(varlist)', by(ea_id)
qui include "$pathdo/attachlabels.do"

sa "$pathout/comm_agprojects_wave2.dta", replace
