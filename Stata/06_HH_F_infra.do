/*-------------------------------------------------------------------------------
# Name:		Malawi_HH_F_Do_file.do
# Purpose:	Process household infrastructure
# Author:	Tim Essam, Ph.D.
# Created:	2016/09/25
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

* Process household infrastructure variables
clear
capture log close
log using "$pathlog/Housing.txt", replace
use "$wave1/HH_MOD_F.dta", clear

clonevar houseMaterial 	= hh_f07
clonevar roofMaterial 	= hh_f08
clonevar floorMaterial	= hh_f09
clonevar roomsHouse		= hh_f10
clonevar fuelSource		= hh_f11
clonevar cookingFuel	= hh_f12
clonevar electricity	= hh_f19
clonevar mobilesOwned	= hh_f34
clonevar drinkingWater	= hh_f36
clonevar toiletType		= hh_f41
clonevar rubbishDisposal= hh_f43
clonevar bedNets		= hh_f44

g byte improvedSanit = inlist(toiletType, 1, 2) & hh_f42 == 1
la var improvedSanit "Improved sanitation based on JMP guidelines"

label list HH_F36
g byte improvedWater = inlist(drinkingWater, 1, 2, 3, 6, 7, 8, 9, 13)
la var improvedWater "Improved water based on JMP guidelines"

ds(visit hh_*), not
keep `r(varlist)'

g byte ironRoof = (roofMaterial == 2)
g year = 2011
save "$pathout/hh_infra2011.dta", replace

* #####################
* 2013 Infrastructure #
* #####################

use "$wave2/HH_MOD_F.dta", clear

clonevar houseMaterial 	= hh_f07
clonevar roofMaterial 	= hh_f08
clonevar floorMaterial	= hh_f09
clonevar roomsHouse		= hh_f10
clonevar fuelSource		= hh_f11
clonevar cookingFuel	= hh_f12
clonevar electricity	= hh_f19
clonevar mobilesOwned	= hh_f34
clonevar drinkingWater	= hh_f36
clonevar toiletType		= hh_f41
clonevar rubbishDisposal= hh_f43
clonevar bedNets		= hh_f44
clonevar bankAccount	= hh_f48


label list HH_F41
g byte improvedSanit = inlist(toiletType, 1, 2) & hh_f42 == 1
la var improvedSanit "Improved sanitation based on JMP guidelines"

label list HH_F36
g byte improvedWater = inlist(drinkingWater, 1, 2, 3, 6, 7, 8, 9, 13)
la var improvedWater "Improved water based on JMP guidelines"

ds(occ qx_type interview*  hh_*), not
keep `r(varlist)'
g year = 2013
save "$pathout/hh_infra2013.dta", replace

append using "$pathout/hh_infra2011.dta"

g byte ironRoof = (roofMaterial == 2)
clonevar id = case_id
replace id = y2_hhid if id == "" & year == 2013
save "$pathout/hh_infra_all.dta", replace

****** 2016 Wave 3 ******
use "$wave3/HH_MOD_F.dta", clear
foreach x of varlist hh_f07 hh_f08 hh_f09 hh_f10 hh_f11 hh_f12 hh_f13 hh_f14 hh_f15 hh_f19 {
  di "`x'"
  tab `x', mi
}


clonevar houseMaterial  = hh_f07
clonevar roofMaterial   = hh_f08
clonevar floorMaterial  = hh_f09
clonevar roomsHouse     = hh_f10
clonevar fuelSource     = hh_f11
clonevar cookingFuel    = hh_f12
clonevar electricity    = hh_f19
clonevar mobilesOwned   = hh_f34
clonevar drinkingWater  = hh_f36
clonevar toiletType     = hh_f41
clonevar rubbishDisposal= hh_f43
clonevar bedNets        = hh_f44
g byte treatedBedNets = (bedNets & inlist(hh_f45, 1, 3) == 1)

* --- Sanitation variables
/*g byte improvedSanit = inlist(toiletType, 1, 2) & hh_f42 == 1
la var improvedSanit "improved sanitation based on JMP guidelines"

label list hh_f36
g byte improvedWater = inlist(drinkingWater, 1, 2, 3, 6, 7, 8, 9, 13) == 1
la var improvedWater "improved water based on JMP guidelines"
*/

* No need to collapse down
ds(hh_f* HHID), not
keep `r(varlist)'

g byte ironRoof = (roofMaterial == 2)

compress
save "$pathout/hh_infra_2016.dta", replace
