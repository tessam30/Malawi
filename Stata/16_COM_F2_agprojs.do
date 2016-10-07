* Describe what is accomplished with file:
* This .do file processed agriculture    
* Date: 2016/09/16
* Author: Tim Essam, Brent McCusker & Park Muhonda
* Project: WVU Livelihood Analysis for Malawi
********************************************************************

clear
capture log clos

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
