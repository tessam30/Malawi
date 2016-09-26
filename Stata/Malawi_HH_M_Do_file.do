/*-------------------------------------------------------------------------------
# Name:		Malawi_HH_M_Do_file.do
# Purpose:	Process household agricultural assets for wealth index
# Author:	Tim Essam, Ph.D.
# Created:	2016/04/27
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close
log using "$pathlog/agassets.txt", replace

use "$wave1/HH_MOD_M.dta", clear

#delimit ;
	local agassets hoe slasher axe sprayer pangaKnife sickle treadlePump waterCan 
	oxCart oxPlough tractor tractorPlough ridger cultivator generator 
	motorPump grainMill other chxHouse livestockKrall poultryKrall 
	storageHouse granary barn pigSty;
#delimit cr
local num : list sizeof local(agassets)
display "`num'"
label list HH_M0A


local i = 601
foreach x of local agassets {
	g byte `x' = (inlist(hh_m0a, `i') & hh_m0c == 1)
	la var `x' "hh owns `x'"
	
	g total_`x' = hh_m01 if inlist(hh_m0a, `i') & hh_m0c == 1
	replace total_`x' = 0 if total_`x' == .
	la var total_`x' "Total `x' owned by hh"
	local i = `++i'
	}
*
order case_id `agassets'
sum hoe-pigSty

* Retain variables needed
ds(visit ea_id hh_*), not
keep `r(varlist)'

qui include "$pathdo/copylabels.do"
	ds(case_id), not
	collapse (max) `r(varlist)', by(case_id)
qui include "$pathdo/attachlabels.do"

compress
save "$pathout/hh_durables2011.dta", replace
