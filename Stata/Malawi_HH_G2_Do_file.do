* Describe what is accomplished with file:
* This .do file processed household food consumption information 
* Date: 2016/09/16
* Author: Brent McCusker, Park Muhonda & Tim Essam
* Project: WVU Livelihood Analysis for Malawi
********************************************************************

clear
capture log close

* Read in the data you are using; Use relative paths whenver possible
/* Note: I store the raw data in two folders called wave1 and wave 2.
I then point to them using global macros. This keeps the code general
and allows me to port it across machines by only changing the macro and
not any hard-coded depedencies. */

global wave1 "C:/Users/student/Documents/Malawi/Datain/wave1"
global wave2 "C:/Users/student/Documents/Malawi/Datain/wave2"
global pathout "C:/Users/student/Documents/Malawi/Dataout"
*global pathdo "C:/Users/student/Documents/GitHub/Malawi/Stata"

* Load the dataset needed to derive time use and ganyu variables
use "$wave1/HH_MOD_G2.dta"

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

g byte cereal = hh_g08a == "A" 
g byte roots = hh_g08a == "B" 
g byte nuts = hh_g08a == "C"
g byte veg =  hh_g08a == "D" 
g byte meat = hh_g08a == "E"
g byte fruit =  hh_g08a == "F" 
g byte milk =  hh_g08a == "G" 
g byte fats =  hh_g08a == "H" 
g byte sugar =  hh_g08a == "I" 
g byte cond =  hh_g08a == "J" 
  
local dietLab cereal root nuts veg meat fruit milk fats sugar cond
foreach x of local dietLab {
	la var `x' "Consumed `x' in last 7 days"
	g `x'_days = hh_g08c if `x' == 1
	replace `x'_days = 0 if `x'_days == .
} 
* Keep derived data (FCS & dietary diversity scores) and HHID
ds(hh_s* saq* ea_id), not
keep `r(varlist)'

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
ds(case_id), not
collapse (max) `r(varlist)', by(case_id)
qui include "$pathdo/attachlabels.do"



sa "$pathout/dietdiv2_2011.dta", replace

***** Wave 2 *****
* Process 2nd wave 
* Load the dataset needed to derive food consuption variables
clear
use "$wave2/HH_MOD_G2.dta"

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

g byte cereal = hh_g08a == 1 
g byte roots = hh_g08a == 2 
g byte nuts = hh_g08a == 3
g byte veg =  hh_g08a == 4 
g byte meat = hh_g08a == 5
g byte fruit =  hh_g08a == 6 
g byte milk =  hh_g08a == 7 
g byte fats =  hh_g08a == 8
g byte sugar =  hh_g08a == 9
g byte cond =  hh_g08a == 10 


local dietLab cereal root nuts veg meat fruit milk fats sugar cond
foreach x of local dietLab {
	la var `x' "Consumed `x' in last 7 days"
	g `x'_days = hh_g08c if `x' == 1
	replace `x'_days = 0 if `x'_days == .
} 
* Keep derived data (FCS & dietary diversity scores) and HHID
ds(hh_s* saq* ea_id), not
keep `r(varlist)'

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
ds(y2_hhid), not
collapse (max) `r(varlist)', by(y2_hhid)
qui include "$pathdo/attachlabels.do"



sa "$pathout/dietdiv2_2013.dta", replace
