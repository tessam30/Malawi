* Describe what is accomplished with file:
* This .do file processed the household education variables
* Date: 2016/09/16
* Author: Park Muhonda & Tim Essam
* Project: WVU Livelihood Analysis for Malawi
********************************************************************


* Load the dataset needed to derive education variables
use "$wave1/HH_MOD_C.dta"

** What is the purpose of the code below? What do you want it to accomplish?
* The first 1/2 seems redundant to the demographic processing.
**********************************************************************

/* Data processing 
g byte hohc = hh_c01 == 1
la var hohc "Head of household"

g byte spousec = hh_c01 == 2
la var spousec "spouse of hoh"

* --- Education levels 
g educHohc = hh_c09 if hoh == 1
g educSpousec = hh_c09 if spouse == 1
egen educAdultc =  max(hh_c09), by(case_id)

la var educHohc "Education of Hoh"
la var educSpousec "Education of spouse"
la var educAdultc "Highest adult education in household"

* convert values that are in hours =<2 into minutes 
replace hh_c19a = (hh_c19a*60) if hh_c19b == 2

egen lenTimeSchool =  max(hh_c19a), by(case_id)

la var lenTimeSchool  "Length of time to get to school"

*collapse
qui include "/Users/student/Desktop/LAM MALAWI_STATA/DataProcessing/copylabels.do"

ds(case_id id_code hh_c01), not
collapse (max) `r(varlist)', by(case_id)

qui include "/Users/student/Desktop/LAM MALAWI_STATA/DataProcessing/attachlables.do"

