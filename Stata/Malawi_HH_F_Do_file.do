/*-------------------------------------------------------------------------------
# Name:		Malawi_HH_F_Do_file.do
# Purpose:	Process household infrastructure
# Author:	Tim Essam, Ph.D.
# Created:	2016/04/27
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

ds(visit hh_*), not
keep `r(varlist)'

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

ds(occ qx_type interview*  hh_*), not
keep `r(varlist)'
g year = 2013
save "$pathout/hh_infra2013.dta", replace

append using "$pathout/hh_infra2011.dta"
save "$pathout/hh_infra_all.dta", replace
