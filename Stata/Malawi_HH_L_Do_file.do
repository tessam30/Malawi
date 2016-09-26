/*-------------------------------------------------------------------------------
# Name:		Malawi_HH_L_Do_file.do
# Purpose:	Process household durable goods for wealth index
# Author:	Tim Essam, Ph.D.
# Created:	2016/04/27
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close
* Load durable good module to create dummies for ownership
use "$wave1/HH_MOD_L.dta", clear

#delimit ;
local dgoods mortar bed table chair fan AC radio tape tv vcr sewingMaching 
		kerosene_stove hotplat fridge washMachine bike moto car minibus
		lorry beerDrum upholsteredChair coffeeTable cupboard  lantern desk 
		clock iron computer satDish soloarPanel generator;
#delimit cr
local num : list sizeof local(dgoods)
display "`num'"

local i = 501
foreach x of local dgoods {
	g byte `x' = (inlist(hh_l02, `i') & hh_l01 == 1)
	la var `x' "hh owns `x'"
	
	g total_`x' = hh_l03 if inlist(hh_l02, `i') & hh_l01 == 1
	replace total_`x' = 0 if total_`x' == .
	la var total_`x' "Total `x' owned by hh"
	local i = `++i'
	}
*

* Retain variables needed
ds(visit ea_id hh_*), not
keep `r(varlist)'

qui include "$pathdo/copylabels.do"
	ds(case_id), not
	collapse (max) `r(varlist)', by(case_id)
qui include "$pathdo/attachlabels.do"

order case_id `dgoods'
compress
save "$pathout/hh_durables2011.dta", replace

* ###############
* 2013 Durables #
* ###############

use "$wave2/HH_MOD_L.dta", clear

#delimit ;
local dgoods mortar bed table chair fan AC radio tape tv vcr sewingMaching 
		kerosene_stove hotplat fridge washMachine bike moto car minibus
		lorry beerDrum upholsteredChair coffeeTable cupboard  lantern desk 
		clock iron computer satDish soloarPanel generator;
#delimit cr
local num : list sizeof local(dgoods)
display "`num'"

local i = 501
foreach x of local dgoods {
	g byte `x' = (inlist(hh_l02, `i') & hh_l01 == 1)
	la var `x' "hh owns `x'"
	
	g total_`x' = hh_l03 if inlist(hh_l02, `i') & hh_l01 == 1
	replace total_`x' = 0 if total_`x' == .
	la var total_`x' "Total `x' owned by hh"
	local i = `++i'
	}
*
* Retain variables needed
ds(occ qx_type interview hh_*), not
keep `r(varlist)'

qui include "$pathdo/copylabels.do"
	ds(y2_hhid), not
	collapse (max) `r(varlist)', by(y2_hhid)
qui include "$pathdo/attachlabels.do"

order y2_hhid `dgoods'
compress
save "$pathout/hh_durables2013.dta", replace

* Append two together
append using "$pathout/hh_durables2011.dta"
g year = 2013 if y2_hhid != ""
replace year = 2011 if case_id != "" & year == .
save "$pathout/hh_durables_all.dta", replace

* 
