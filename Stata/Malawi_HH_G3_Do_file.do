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
use "$wave1/HH_MOD_G3.dta"

g byte shared = hh_g09 == 1 
la var shared "Shared meal with non household member"

/* Category of non household members shared meal with:
  1) Children 0-5 years(A)
  2) Children 6-15 years(B)
  3) Adults 16-65 years(C)
  4) People over 66 years(D) */

g byte children = (hh_g10a == "A") & hh_g09 == 1 
g byte childnAbov5 = hh_g10a == "B" & hh_g09 == 1 
g byte adults = hh_g10a == "C" & hh_g09 == 1 
g byte eldery =  hh_g10a == "D" & hh_g09 == 1 

la var children "Children 0-5 years"
la var childnAbov5 "Children 6-15 years"
la var adults "Adults 16-65 years"
la var eldery "People over 66 years" 

egen totdays = total(hh_g10c), by(case_id)
egen totmeals = total(hh_g11), by(case_id)

la var totdays "Total number of days in which meals were shared with people/non hh members"
la var totmeals "Total number of meals shared in the past 7 days" 

* Keep derived data (FCS & dietary diversity scores) and HHID
ds(hh_s* saq* ea_id), not
keep `r(varlist)'

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
ds(case_id), not
collapse (max) `r(varlist)', by(case_id)
qui include "$pathdo/attachlabels.do"



sa "$pathout/dietdiv3_2011.dta", replace

***** Wave 2 *****
* Process 2nd wave 
* Load the dataset needed to derive food consuption variables
clear
use "$wave2/HH_MOD_G3.dta"

g byte shared = hh_g09 == 1 
la var shared "Shared meal with non household member"

/* Category of non household members shared meal with:
  1) Children 0-5 years(A)
  2) Children 6-15 years(B)
  3) Adults 16-65 years(C)
  4) People over 66 years(D) */

g byte children = hh_g10a == 1
g byte childnAbov5 = hh_g10a == 2 
g byte adults = hh_g10a == 3
g byte eldery =  hh_g10a == 4 

la var children "Children 0-5 years"
la var childnAbov5 "Children 6-15 years"
la var adults "Adults 16-65 years"
la var eldery "People over 66 years" 

egen totdays = total(hh_g10c), by(y2_hhid)
egen totmeals = total(hh_g11), by(y2_hhid)

la var totdays "Total number of days in which meals were shared with people/non hh members"
la var totmeals "Total number of meals shared in the past 7 days" 

* Keep derived data (FCS & dietary diversity scores) and HHID
ds(hh_s* saq* ea_id), not
keep `r(varlist)'

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
ds(case_id), not
collapse (max) `r(varlist)', by(y2_hhid)
qui include "$pathdo/attachlabels.do"



sa "$pathout/dietdiv3_2013.dta", replace
