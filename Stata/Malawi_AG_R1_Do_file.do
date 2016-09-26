/*-------------------------------------------------------------------------------
# Name:		Malawi_AG_R1_Do_file.do
# Purpose:	Process household infrastructure
# Author:	Tim Essam, Ph.D.
# Created:	2016/09/25
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close
log using "$pathlog/tlus.txt", replace
use "$wave1/AG_MOD_R1.dta", replace

recode ag_r00 (1 = 1 "Yes")(2 = 0 "No"), gen(ownLivestock)

#delimit ;
	local tlus calf steer cow bull donkey mule goat sheep pig chicken_layer hen
			chicken_broiler cock_local turkey duck guineaFowl beehive;
#delimit cr
local num : list sizeof local(tlus)
display "`num'"

local i = 301
foreach x of local tlus {
	g byte `x' = (inlist(ag_r0a, `i') & ag_r01 == 1)
	la var `x' "hh owns `x'"
		
	g total_`x' = ag_r02 if inlist(ag_r0a, `i') & ag_r01 == 1
	replace total_`x' = 0 if total_`x' == .
	la var total_`x' "Total `x' owned by hh"
	display in yellow "`i' ==> `x'"
	
	local i = `++i'
	}
*

* Retain variables needed
ds(visit ea_id ag_*), not
keep `r(varlist)'

qui include "$pathdo/copylabels.do"
	ds(case_id), not
	collapse (max) `r(varlist)', by(case_id)
qui include "$pathdo/attachlabels.do"

order case_id `tlus'

/*Create TLU (based on values from http://www.lrrd.org/lrrd18/8/chil18117.htm)
Notes: Sheep includes sheep and goats
Horse includes all draught animals (donkey, horse, bullock)
chxTLU includes all small animals (chicken, fowl, etc).*/
scalar define  camelVal 	= 0.70
scalar define  cattleVal 	= 0.50
scalar define  pigVal 		= 0.20
scalar define  sheepVal 	= 0.10
scalar define  horsesVal 	= 0.50
scalar define  mulesVal 	= 0.60
scalar define  assesVal 	= 0.30
scalar define  chxVal 		= 0.01


g tlucattle = (total_calf + total_steer + total_cow + total_bull) * cattleVal	  
g tlusheep 	= (total_sheep + total_goat) * sheepVal
g tluhorses = (total_donkey + total_mule) * horsesVal
g tlupig 	= (total_pig) * pigVal
g tluchx 	= (total_chicken_layer + total_hen + total_chicken_broiler + /*
*/ 			total_cock_local + total_turkey + total_duck + total_guineaFowl) * chxVal

* Generate overall tlus
egen tluTotal = rsum(tlucattle tlusheep tluhorses tlupig tluchx)
la var tluTotal "Total tropical livestock units"

sum tluTotal, d

* Affects 8 households if we change their TLUs to be equal to 20
replace tluTotal = 20 if tluTotal>20 & !missing(tluTotal)
histogram tluTotal if tluTotal <5

compress
save "$pathout/tlus_2011.dta", replace

* ###############
* 2013 TLUS		#
* ###############

use "$wave2/AG_MOD_R1.dta", replace
recode ag_r00 (1 = 1 "Yes")(2 = 0 "No"), gen(ownLivestock)

#delimit ;
	local tlus calf steer cow bull goat sheep pig hen cock_local duck other 
	dove ox donkey chicken_layer guineaFowl;
#delimit cr
local num : list sizeof local(tlus)
display "`num'"

levelsof(ag_r0a), local(levels)
local num2: list sizeof local(levels)
display "`num2'"

assert `num' == `num2'
display in yellow "Unique elements in hh_r0a = `num' ==> Unique categories to be created == `num2'"

forvalues i = 1/`num' {
	local x : word `i' of `tlus'
	local b : word `i' of `levels'
	
	g byte `x' = (inlist(ag_r0a, `b') & ag_r01 == 1)
	la var `x' "hh owns `x'"
		
	g total_`x' = ag_r02 if inlist(ag_r0a, `b') & ag_r01 == 1
	replace total_`x' = 0 if total_`x' == .
	la var total_`x' "Total `x' owned by hh"
	display in yellow "`b' ==> `x'"
	}
*end

* Retain variables needed
ds(occ qx_type interview ag_*), not
keep `r(varlist)'

qui include "$pathdo/copylabels.do"
	ds(y2_hhid), not
	collapse (max) `r(varlist)', by(y2_hhid)
qui include "$pathdo/attachlabels.do"

order y2_hhid `tlus'

g tlucattle = (total_calf + total_steer + total_cow + total_bull + total_ox) * cattleVal	  
g tlusheep 	= (total_sheep + total_goat) * sheepVal
g tluhorses = (total_donkey) * horsesVal
g tlupig 	= (total_pig) * pigVal
g tluchx 	= (total_hen + total_cock_local + total_duck + total_dove + /*
			*/ total_chicken_layer + total_guineaFowl) * chxVal

* Generate overall tlus
egen tluTotal = rsum(tlucattle tlusheep tluhorses tlupig tluchx)
la var tluTotal "Total tropical livestock units"

sum tluTotal, d
replace tluTotal = 20 if tluTotal>20 & !missing(tluTotal)
histogram tluTotal if tluTotal <5

compress
save "$pathout/tlus_2013.dta", replace

* Append two together
append using "$pathout/tlus_2011.dta"
g year = 2013 if y2_hhid != ""
replace year = 2011 if case_id != "" & year == .
save "$pathout/tlus_all.dta", replace

