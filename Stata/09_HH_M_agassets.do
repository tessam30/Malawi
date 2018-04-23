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

*  ---------------------------------------------------------------
******************
* 2016 Ag assets *
******************

use "$wave3/HH_MOD_M.dta", clear

/* Asset list below
601 HAND HOE
602 SLASHER
603 AXE
604 SPRAYER
605 PANGA KNIFE
606 SICKLE
607 TREADLE PUMP
608 WATERING CAN
609 OX CART
610 OX PLOUGH
611 TRACTOR
612 TRACTOR PLOUGH
613 RIDGER
614 CULTIVATOR
615 GENERATOR
616 MOTORISED PUMP
617 GRAIN MILL
618 OTHER
619 CHICKEN HOUSE
620 LIVESTOCK KRAAL
621 POULTRY KRAAL
622 STORAGE HOUSE
623 GRANARY
624 BARN
625 PIG STY
*/

*#delimit ;
	local agassets hoe slasher axe sprayer pangaKnife sickle treadlePump waterCan oxCart oxPlough tractor tractorPlough ridger cultivator generator motorPump grainMill other chxHouse livestockKrall poultryKrall storageHouse granary barn pigSty
*#delimit cr
local num : list sizeof local(agassets)
display "`num'"
label list Id

/* NOTES: It appears the data does not include the correct label/question for hh_m00; It should read, Does your household currently own the item. Instead, it asks question A at the top of the module Pag 44 of the HH questionnaire). Creating a dummy variable that flags whether or not a hh owns a listed ag asset. */

g byte ownAsset = (hh_m01>0 & hh_m01 != .)

* Notice the difference if one uses hh_m00 -- 275K v 287K
tab ownAsset hh_m00, mi

local i = 601
foreach x of local agassets {
	g byte `x' = (inlist(hh_m0b, `i') & ownAsset == 1)
	la var `x' "hh owns `x'"

	g total_`x' = hh_m01 if inlist(hh_m0b, `i') & ownAsset == 1
	replace total_`x' = 0 if total_`x' == .
	la var total_`x' "Total `x' owned by hh"
	display in yellow "hh_m0a `i' ==> `x'"

	local i = `++i'
	}
*
order case_id `agassets'
sum hoe-pigSty

* Retain variables needed
ds(hh_m* HHID), not
keep `r(varlist)'

qui include "$pathdo/copylabels.do"
	ds(case_id), not
	collapse (max) `r(varlist)', by(case_id)
qui include "$pathdo/attachlabels.do"

* Sum derived assets to make sure they make sense
sum
g year = 2016
compress
save "$pathout/hh_agassets2016.dta", replace
