/*-------------------------------------------------------------------------------
# Name:		Malawi_HH_M_Do_file.do
# Purpose:	Process household agricultural assets for wealth index
# Author:	Tim Essam, Ph.D.
# Created:	2016/09/25
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
	display in yellow "hh_m0a `i' ==> `x'"

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

* Sum derived assets to make sure they make sense
sum 

compress
save "$pathout/hh_agassets2011.dta", replace

* ###############
* 2013 ag assets#
* ###############

use "$wave2/HH_MOD_M.dta", clear
label list HH_M0B


#delimit ;
	local agassets hoe slasher axe sprayer pangaKnife sickle treadlePump waterCan 
	oxCart oxPlough tractor tractorPlough ridger cultivator generator 
	motorPump grainMill other chxHouse livestockKrall poultryKrall 
	storageHouse granary barn pigSty;
#delimit cr
local num : list sizeof local(agassets)
display "`num'"

local i = 601
foreach x of local agassets {
	g byte `x' = (inlist(hh_m0b, `i') & hh_m0c == 1)
	la var `x' "hh owns `x'"
	
	g total_`x' = hh_m01 if inlist(hh_m0b, `i') & hh_m0c == 1
	replace total_`x' = 0 if total_`x' == .
	la var total_`x' "Total `x' owned by hh"
	display in yellow "`i' ==> `x'"
	
	local i = `++i'
	}
*
order y2_hhid `agassets'
sum hoe-pigSty

ds(occ qx_type interview hh_*), not
keep `r(varlist)'

qui include "$pathdo/copylabels.do"
	ds(y2_hhid), not
	collapse (max) `r(varlist)', by(y2_hhid)
qui include "$pathdo/attachlabels.do"

* Sum derived assets to make sure they make sense
sum 


save "$pathout/hh_agassets2013.dta", replace
append using "$pathout/hh_agassets2011.dta"
g year = 2013 if y2_hhid != ""
replace year = 2011 if case_id != "" & year == .

clonevar id = case_id
replace id = y2_hhid if id == "" & year == 2013
save "$pathout/hh_agassets_all.dta", replace
