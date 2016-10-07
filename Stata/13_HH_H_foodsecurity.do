/*-------------------------------------------------------------------------------
# Name:		00_SetupFolderGlobals
# Purpose:	Process food insecurity module
# Author:	Tim Essam, Ph.D.
# Created:	2016/04/27
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

* Process food insecurity module
clear
capture log close
log using "$pathlog/FoodInsecurity.txt", replace
use "$wave1/HH_MOD_H.dta", clear

recode hh_h01 (2 = 0 "No")(1 = 1 "Yes"), gen(foodInsecure7Days)
clonevar inferiorFood = hh_h02a
clonevar limitPortion = hh_h02b
clonevar reduceMeals  = hh_h02c
clonevar restrictCons = hh_h02d
clonevar borrowFood	  = hh_h02e

recode hh_h04 (2 = 0 "No")(1 = 1 "Yes"), gen(foodInsecure12Months)

* Create CMC codes for the food security variables
* Questioning starts in March 2009 and ends in March 2011
*display 12*(2009 - 1900)+3 
*display 12*(2011 - 1900)+4

#delimit ;
	local fsmonth  mar09 apr09 may09 jun09 jul09 aug09 sep09 oct09 nov09
			dec09 jan10 feb10 mar10 apr10 may10 jun10 jul10 aug10
			sep10 oct10 nov10 dec10 jan11 feb11 mar11;
#delimit cr
local num2: list sizeof local(fsmonth)
scalar months = `num2'


local i = 1
foreach x of varlist hh_h05a_01- hh_h05b_15 {
	
	local b : word `i' of `fsmonth'
	display "`i' `b''"

	replace `x' = "1" if `x' == "X"
	replace `x' = "0" if `x' == ""
	destring `x', gen(finsec_`b')

	local i = `++i'
	}
*

egen totMoFoodInsec = rsum2(finsec*)
sum totMoFoodInsec, d
scalar maxMo = `r(max)'

la var totMoFoodInsec "Total months w/ food insecurity (out of 25 months)"
g totMoFoodInsecShare = totMoFoodInsec/months
la var totMoFoodInsecShare "Share of total months with food insecurity (out of 25 months)"

* Ag inputs are the primary cause of food shortages according to households
clonevar primaryCauseFI = hh_h06a
clonevar secondaryCauseFI = hh_h06b
g year = 2011

ds(hh_* visit), not
keep `r(varlist)'
save "$pathout/food_insecurity2011.dta", replace

*########################
*# 2013 Food insecurity #
*########################

use "$wave2/HH_MOD_H.dta", clear

recode hh_h01 (2 = 0 "No")(1 = 1 "Yes"), gen(foodInsecure7Days)
clonevar inferiorFood = hh_h02a
clonevar limitPortion = hh_h02b
clonevar reduceMeals  = hh_h02c
clonevar restrictCons = hh_h02d
clonevar borrowFood	  = hh_h02e
recode hh_h04 (2 = 0 "No")(1 = 1 "Yes"), gen(foodInsecure12Months)



#delimit ;
	local fsmonth apr12 may12 jun12 jul12 aug12 sep12 oct12
			nov12 dec12 jan13 feb13 mar13 apr13 may13 jun13 
			jul13 aug13 sep13 oct13;
#delimit cr
local num2: list sizeof local(fsmonth)
scalar months = `num2'


* Create CMC codes for the food security variables
* Questioning starts in March 2009 and ends in March 2011
*display 12*(2012 - 1900)+5 

local i = 1
foreach x of varlist hh_h05a- hh_h05s {
	
	local b : word `i' of `fsmonth'
	display "`i' `b''"

	replace `x' = "1" if `x' == "X"
	replace `x' = "0" if `x' == ""
	destring `x', gen(finsec_`b')

	local i = `++i'
	}
*

egen totMoFoodInsec = rsum2(finsec*)
sum totMoFoodInsec, d
scalar maxMo = `r(max)'

la var totMoFoodInsec "Total months w/ food insecurity (out of 19 months)"
g totMoFoodInsecShare = totMoFoodInsec/months
la var totMoFoodInsecShare "Share of total months with food insecurity (out of 19 months)"

* Ag inputs are the primary cause of food shortages according to households
clonevar primaryCauseFI = hh_h06a
clonevar secondaryCauseFI = hh_h06b

g year = 2013
ds(hh_* qx_type occ interview_status), not
keep `r(varlist)'
save "$pathout/food_insecurity2013.dta", replace

append using "$pathout/food_insecurity2011.dta"

clonevar id = case_id
replace id = y2_hhid if id == "" & year == 2013

order finsec_mar09- finsec_mar11, before( finsec_apr12)

save "$pathout/food_insecurity_all.dta", replace
