* Describe what is accomplished with file:
* This .do file processed household food consumption information
* Date: 2016/09/16
* Author: Tim Essam, Brent McCusker & Park Muhonda
* Project: WVU Livelihood Analysis for Malawi
********************************************************************

clear
capture log close

* Load the dataset for dietary diversity and food consumption scores
use "$wave1/HH_MOD_G2.dta", clear

/* Create dietary diversity variable consisting of following food groups:
  1) Cereals, Grain and Cereal Products(A)
  2) Roots, tubers and Plantains(B)
  3) Nuts and Pulses(C)
  4) Vegetables (D)
  5) Meat, Fish and Animal Products(E)
  6) Fruits(F)
  7) Milk/Milk Products(G)
  8) Fats/Oil(H)
  9) Sugar/Sugar Products/Honey(I)
  10) Spices/condiments(J)	*/

* Cannot consume something 8 days in 7 day week.
recode hh_g08c (8 = 0)

local food "cereal roots legumes veg meat fruit milk fats sugar cond"
local alpha "A B C D E F G H I J"
local n : word count `food'

forvalues i = 1/`n' {
	local a : word `i' of `food'
	local b : word `i' of `alpha'
	g byte `a' = (hh_g08a == "`b'") & inrange(hh_g08c, 1, 7)
	la var `a' "Consumed `a' in last seven days"
	}
 *end
g byte staple = inlist(1, cereal, roots)
 /*
g byte cereal = (hh_g08a == "A") & inrange(hh_g08c, 1,7)
g byte roots = (hh_g08a == "B")
g byte legumes = (hh_g08a == "C")
g byte veg =  (hh_g08a == "D")
g byte meat = (hh_g08a == "E")
g byte fruit =  (hh_g08a == "F")
g byte milk =  (hh_g08a == "G")
g byte fats =  (hh_g08a == "H")
g byte sugar =  (hh_g08a == "I")
g byte cond =  (hh_g08a == "J")
*/

* Create number of days per week in which item was consumed
local dietLab cereal roots legumes veg meat fruit milk fats sugar cond staple
foreach x of local dietLab {
	la var `x' "Consumed `x' in last 7 days"
	g `x'_days = hh_g08c if `x' == 1
	replace `x'_days = 0 if `x'_days == .
}
*end

* Try to get something resembling an FCS
g cerealFCS = cereal_days * 2
g starchFCS = roots_days * 2
g staplesFCS = staple_days * 2
g legumesFCS = legumes_days * 3

* Both weighted by 1
g vegFCS = veg_days
g fruitFCS = fruit_days

* meat, poultry, fish, eggs
g meatFCS = meat_days * 4
g milkFCS = milk_days * 4

g sweetFCS = sugar_days * 0.5
g oilFCS = fats_days * 0.5

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
	ds(case_id visit ea_id hh_g*), not
	collapse (max) `r(varlist)', by(case_id)
qui include "$pathdo/attachlabels.do"

egen dietDiv = rsum2(cereal roots legumes veg meat fruit milk fats sugar cond)
recode dietDiv (0 1 = 2)

egen FCS = rsum2(staplesFCS legumesFCS vegFCS fruitFCS meatFCS milkFCS sweetFCS oilFCS)
recode FCS (0 = .)
histogram FCS

clonevar FCS_categ = FCS
recode FCS_categ (0/21 = 0) (21.5/35 = 1) (35.1/53 = 2) (53/112 = 3)
lab def fcscat 0 "Poor" 1 " Borderline" 2 " Acceptable low" 3 "Acceptable high"
lab val FCS_categ fcscat
la var FCS_categ "Food consumption score category"
tab FCS_cat, mi

g year = 2011
sa "$pathout/dietdiv2_2011.dta", replace


******************************************************************************
***** Wave 2 *****
******************************************************************************



* Process 2nd wave
* Load the dataset needed to derive food consuption variables
clear
use "$wave2/HH_MOD_G2.dta", clear

* Check label list
label list HH_G08A

/* Create dietary diversity variable consisting of following food groups:
  1) Cereals, Grain and Cereal Products(A)
  2) Roots, tubers and Plantains(B)
  3) Nuts and Pulses(C)
  4) Vegetables (D)
  5) Meat, Fish and Animal Products(E)
  6) Fruits(F)
  7) Milk/Milk Products(G)
  8) Fats/Oil(H)
  9) Sugar/Sugar Products/Honey(I)
  10) Spices/condiments(J)	*/

local flist cereal roots legumes veg meat fruit milk fats sugar cond
local i = 1
foreach x of local flist {
	* Create binary to track food group consumption
	g byte `x' = (hh_g08a == `i') & inrange(hh_g08c, 1, 7)
    la var `x' "consumed `x' in last seven days"

	* Create continuous to prep for FCS calculation
	g `x'_days = hh_g08c if `x' == 1
	replace `x'_days = 0 if `x'_days == .

	* Track the iterator
	display in yellow "`i'"
	local i = `++i'
}
*end
g byte staple = inlist(1, cereal, roots)
g staple_days = hh_g08c if staple == 1

* Try to get something resembling an FCS
g cerealFCS = cereal_days * 2
g starchFCS = roots_days * 2
g staplesFCS = staple_days * 2

g legumesFCS = legumes_days * 3

* Both weighted by 1
g vegFCS = veg_days
g fruitFCS = fruit_days

* meat, poultry, fish, eggs
g meatFCS = meat_days * 4
g milkFCS = milk_days * 4

g sweetFCS = sugar_days * 0.5
g oilFCS = fats_days * 0.5

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
	ds(occ y2_hhid interview_status hh_* qx_type), not
	collapse (max) `r(varlist)', by(y2_hhid)
qui include "$pathdo/attachlabels.do"

egen dietDiv = rsum2(cereal roots legumes veg meat fruit milk fats sugar cond)
recode dietDiv (0 1 = 2)

egen FCS = rsum2(staplesFCS legumesFCS vegFCS fruitFCS meatFCS milkFCS sweetFCS oilFCS)
recode FCS (0 = .)
histogram FCS

clonevar FCS_categ = FCS
recode FCS_categ (0/21 = 0) (21.5/35 = 1) (35.1/53 = 2) (53/112 = 3)
lab def fcscat 0 "Poor" 1 " Borderline" 2 " Acceptable low" 3 "Acceptable high"
lab val FCS_categ fcscat
la var FCS_categ "Food consumption score category"
tab FCS_cat, mi

g year = 2013
sa "$pathout/dietdiv2_2013.dta", replace

*Append in 2011 data
append using "$pathout/dietdiv2_2011.dta"

tab FCS_categ year
tab dietDiv year
compress


g id = case_id if year == 2011
replace id = y2_hhid if id == "" & year == 2013

save "$pathout/dietdiversity_all.dta", replace

****************************************************************************
* ---- Wave 3 - FCS data processing
******************************************************************************

use "$wave3/HH_MOD_G2.dta", clear

/* NOTES: The structure of the data changed with this round. No longer
	need to loop over alpha codes to create new variables. Can just
	clone variables and use the days straight up. */

* Checking that max values fall within acceptable range
local food "cereal roots legumes veg meat fruit milk fats sugar cond"
local alpha "a b c d e f g h i j"
local n: word count `food'

forvalues i = 1 / `n' {
	local a: word `i' of `food'
	local b: word `i' of `alpha'

	clonevar `a'_days = hh_g08`b'
	la var `a'_days "Days hh consumed `a' in last 7 days"
	}
*end
egen staple_days = rowmax(cereal_days roots_days)

*g cerealFCS = cereal_days * 2
*g starchFCS = roots_days * 2
g staplesFCS = staple_days * 2
g legumesFCS = legumes_days * 3
g vegFCS = veg_days
g fruitFCS = fruit_days
g meatFCS = meat_days * 4
g milkFCS = milk_days * 4
g sweetFCS = sugar_days * 0.5
g oilFCS = fats_days * 0.5

* No need to collapse data as it is reported at the household level
egen FCS = rowtotal(staplesFCS legumesFCS vegFCS fruitFCS meatFCS milkFCS sweetFCS oilFCS), m
tab FCS, mi
* The assert statement will break the code b/c of the one hh w/ missing data
*assert FCS <= 112
histogram FCS

clonevar FCS_categ = FCS
recode FCS_categ (0/21 = 0) (21.5/35 = 1) (35.5/53 = 2) (53.5/112 = 3)
lab def fcscat 0 "Poor" 1 " Borderline" 2 " Acceptable low" 3 "Acceptable high"
lab val FCS_categ fcscat
la var FCS_categ "Food consumption score category"
tab FCS_cat, mi

tab FCS FCS_categ, mi

* Keep selected variables for analysis and visualizations
ds(HHID hh_g*), not
keep `r(varlist)'

compress
save "$pathout/dietdiversity_2016.dta", replace
