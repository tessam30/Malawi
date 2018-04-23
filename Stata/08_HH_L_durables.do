/*-------------------------------------------------------------------------------
# Name:		Malawi_HH_L_Do_file.do
# Purpose:	Process household durable goods for wealth index
# Author:	Tim Essam, Ph.D.
# Created:	2016/09/25
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
	collapse (max) `r(varlist)', by(case_id) fast
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
	collapse (max) `r(varlist)', by(y2_hhid) fast
qui include "$pathdo/attachlabels.do"

order y2_hhid `dgoods'
compress
save "$pathout/hh_durables2013.dta", replace

* Append two together
append using "$pathout/hh_durables2011.dta"
g year = 2013 if y2_hhid != ""
replace year = 2011 if case_id != "" & year == .

clonevar id = case_id
replace id = y2_hhid if id == "" & year == 2013
save "$pathout/hh_durables_all.dta", replace

*


*--------------------------------------------------------------------------
* ###############
* 2016 Durables #
* ###############
*--------------------------------------------------------------------------

use "$wave3/HH_MOD_L.dta", clear

/*
501 Mortar/pestle (mtondo)
502 Bed
503 Table
504 Chair
505 Fan
506 Air conditioner
507 Radio ('wireless')
508 Tape or CD/DVD player; HiFi
509 Television
510 VCR
511 Sewing machine
512 Kerosene/paraffin stove
513 Electric or gas stove; hot plate
514 Refrigerator
515 Washing machine
516 Bicycle
517 Motorcycle/scooter
518 Car
519 Mini-bus
520 Lorry
521 Beer-brewing drum
522 Upholstered chair, sofa set
523 Coffee table (for sitting room)
524 Cupboard, drawers, bureau
525 Lantern (paraffin)
526 Desk
527 Clock
528 Iron (for pressing clothes)
529 Computer equipment & accessories
530 Sattelite dish
531 Solar panel
532 Generator
5081 Radio with flash drive/micro CD
*/

* Turning delimiter off to run through Atom -- provides soft wrapping
*#delimit ;
local dgoods mortar bed table chair fan AC radio tape tv vcr sewingMaching kerosene_stove hotplat fridge washMachine bike moto car minibus lorry beerDrum upholsteredChair coffeeTable cupboard  lantern desk  clock iron computer satDish soloarPanel generator
*#delimit cr
local num : list sizeof local(dgoods)
display "`num'"

* Ensure that the number displays matches to the number in the label list and codebook;  Radio w/ flash drive/micro CD was added to questions

local i = 501
foreach x of local dgoods {
		g byte `x' = (inlist(hh_l02, `i') & hh_l01 == 1)
		la var `x' "hh owns `x'"

		g total_`x' = hh_l03 if inlist(hh_l02, `i') & hh_l01 == 1
		replace total_`x' = 0 if total_`x' == .
		la var total_`x' "Total `x' owned by hh"
		local i = `++i'
	}
*end

* Add in radio w/ flash drive/micro CD (about ~ 240 owned)
	g byte radioCD = inlist(hh_l02, 5081) & hh_l01 == 1
	la var radioCD "hh owns radio CD"

	g total_radioCD = hh_l03 if inlist(hh_l02, 5081) & hh_l01 == 1
	replace total_radioCD = 0 if total_radioCD == .
	la var total_radioCD "total radio CDs owend by hh"


* Retain variables needed
ds(hh_l* HHID), not
keep `r(varlist)'

qui include "$pathdo/copylabels.do"
	ds(case_id), not
	collapse (max) `r(varlist)', by(case_id) fast
qui include "$pathdo/attachlabels.do"

compress
g year = 2016
save "$pathout/hh_durables_2016.dta", replace
