* Describe what is accomplished with file:
* This .do file processed the household demographic variables
* Date: 2016/09/16
* Author: Park Muhonda & Tim Essam
* Project: WVU Livelihood Analysis for Malawi
********************************************************************

clear
capture log close

* Read in the data you are using; Use relative paths whenver possible
/* Note: I store the raw data in two folders called wave1 and wave 2.
I then point to them using global macros. This keeps the code general
and allows me to port it across machines by only changing the macro and
not any hard-coded depedencies. */

global wave1 "C:/Users/Tim/Documents/Malawi/Datain/wave1"
global wave2 "C:/Users/Tim/Documents/Malawi/Datain/wave2"
global pathout "C:/Users/Tim/Documents/Malawi/Dataout"
global pathdo "C:/Users/Tim/Documents/GitHub/Malawi/Stata"

* Load the dataset needed to derive household demographic variables
use "$wave1/HH_MOD_B.dta"


* Data processing 
g byte hoh =  hh_b04 == 1
la var hoh "Head of household"

g byte spouse =  hh_b04 == 2
la var spouse "spouse of hoh"

g byte femhead =  hh_b04 == 1 & hh_b03 == 2
la var femhead "Female head of household"

g agehead = hh_b05a if hoh == 1
la var agehead "Age of hoh"

g genderhead = hh_b03 if hoh == 1
la var genderhead "Gender of hoh"

* --- Relationship status 
g byte marriedHoh = inlist(hh_b24, 1, 2) & hoh == 1
g byte marriedHohm = (hh_b24 == 1 & hoh == 1)
g byte marriedHohp = (hh_b24 == 2 & hoh == 1)
g byte nonmarriedHoh = (inlist(hh_b24, 3, 4, 5, 6)==1) & hoh == 1
g byte widowFemhead = femhead == 1 & hh_b24 == 5
g byte nonmarriedFemhead = femhead == 1 & inlist(hh_b24, 3, 4, 5, 6)

la var marriedHoh "Married hoh (any type)"
la var marriedHohm "Monogamous married hoh"
la var marriedHohp "Polygamous married hoh"
la var nonmarriedHoh "Non-married (never marry, divorce, separated, widowed)"
la var widowFemhead "Widowed female hoh"
la var nonmarriedFemhead "Non-married (never marry, divorce, separated, widowed) female hoh"

* --- Religion 
g religHoh = hh_b23 if hoh == 1
g religSpouse = hh_b23 if hh_b01 == 2

tempvar hohrelig sprelig
egen `hohrelig' = max(religHoh), by(case_id)
egen `sprelig' = max(religSpouse), by(case_id)
g byte mxdreligHH = `hohrelig' != `sprelig' & `hohrelig' != . & `sprelig' != .

la var religHoh "Religion of hoh"
la var religSpouse "Religion of spouse"
la var mxdreligHH "Mixed-religion household"

* --- Household demographics 
* Create gender ratio for households
g byte male = hh_b03 == 1 
g byte female = hh_b03 == 2 
la var male "male hh members"
la var female "female hh members"

egen msize = total(male), by(case_id)
la var msize "number of males in hh"

egen fsize = total(female), by(case_id)
la var fsize "number of females in hh"

* Create a gender ratio variable
g gendMix = msize/fsize
*recode gendMix (. = 0) if fsize==0
la var gendMix "Ratio of males to females (1 = 1:1 mix)"

* --- Education levels 
* drop values that take on 8
g educHoh = hh_b21 if hoh == 1 & hh_b21 != 8 
g educSpouse = hh_b21 if spouse == 1 & hh_b21 != 8 
egen educAdult =  max(hh_b21), by(case_id)

la var educHoh "Education of Hoh"
la var educSpouse "Education of spouse"
la var educAdult "Highest adult education in household"

* If spouse live in the hh 
g byte presentSpouse = hh_b25 == 1 & spouse == 1
la var presentSpouse "Spouse lives in the hh"

* --- Length of stay  
g lenStayHoh = hh_b12 if hoh == 1 & hh_b12 != 99
g lenStaySpouse = hh_b12 if spouse == 1 & hh_b12 != 99
egen lenStayAdult =  max(hh_b12), by(case_id)

la var lenStayHoh "Length of stay in the area by Hoh"
la var lenStaySpouse "Length of stay in the area by spouse"
la var lenStayAdult "Maximum length of stay in the area by hh member"

*collapse
qui include "$pathdo/copylabels.do"

ds(case_id id_code hh_b* visit ea_id qx_type), not
collapse (max) `r(varlist)', by(case_id)

qui include "$pathdo/attachlabels.do"

g year = 2011
compress
save "$pathout/hh_dem_wave1.dta", replace


***** Wave 2 *****
* Process 2nd wave 
use "$wave1/HH_MOD_B.dta", clear

* Data processing 
g byte hoh = hh_b04 == 1
la var hoh "Head of household"

g byte spouse = hh_b04 == 2
la var spouse "spouse of hoh"

g byte femhead = hh_b04 == 1 & hh_b03 == 2
la var femhead "Female head of household"

g agehead = hh_b05a if hoh == 1
la var agehead "Age of hoh"

g genderhead = hh_b03 if hoh == 1
la var genderhead "Gender of hoh"

* --- Relationship status 
g byte marriedHoh = inlist(hh_b24, 1, 2) & hoh == 1
g byte marriedHohm = (hh_b24 == 1 & hoh == 1)
g byte marriedHohp = (hh_b24 == 2 & hoh == 1)
g byte nonmarriedHoh = (inlist(hh_b24, 3, 4, 5, 6)==1) & hoh == 1
g byte widowFemhead = femhead == 1 & hh_b24 == 5
g byte nonmarriedFemhead = femhead == 1 & inlist(hh_b24, 3, 4, 5, 6)

la var marriedHoh "Married hoh (any type)"
la var marriedHohm "Monogamous married hoh"
la var marriedHohp "Polygamous married hoh"
la var nonmarriedHoh "Non-married (never marry, divorce, separated, widowed)"
la var widowFemhead "Widowed female hoh"
la var nonmarriedFemhead "Non-married (never marry, divorce, separated, widowed) female hoh"

* --- Religion 
g religHoh = hh_b23 if hoh == 1
g religSpouse = hh_b23 if hh_b04 == 2

tempvar hohrelig sprelig
egen `hohrelig' = max(religHoh), by(case_id)
egen `sprelig' = max(religSpouse), by(case_id)
g byte mxdreligHH = `hohrelig' != `sprelig' & `hohrelig' != . & `sprelig' != .

la var religHoh "Religion of hoh"
la var religSpouse "Religion of spouse"
la var mxdreligHH "Mixed-religion household"

* --- Household demographics 
* Create gender ratio for households
g byte male = hh_b03 == 1 
g byte female = hh_b03 == 2 
la var male "male hh members"
la var female "female hh members"

egen msize = total(male), by(case_id)
la var msize "number of males in hh"

egen fsize = total(female), by(case_id)
la var fsize "number of females in hh"

* Create a gender ratio variable
g gendMix = msize/fsize
*recode gendMix (. = 0) if fsize==0
la var gendMix "Ratio of males to females (1 = 1:1 mix)"

* --- Education levels 
g educHoh = hh_b21 if hoh == 1 & hh_b21 != 8 
g educSpouse = hh_b21 if spouse == 1 & hh_b21 != 8 
egen educAdult =  max(hh_b21), by(case_id)

la var educHoh "Education of Hoh"
la var educSpouse "Education of spouse"
la var educAdult "Highest adult education in household"

* If spouse live in the hh 
g byte presentSpouse = hh_b25 == 1 & spouse == 1

la var presentSpouse "Spouse lives in the hh"

* --- Length of stay  
g lenStayHoh = hh_b12 if hoh == 1 & hh_b12 != 99
g lenStaySpouse = hh_b12 if spouse == 1 & hh_b12 != 99
egen lenStayAdult =  max(hh_b12), by(case_id)

la var lenStayHoh "Length of stay in the area by Hoh"
la var lenStaySpouse "Length of stay in the area by spouse"
la var lenStayAdult "Maximum length of stay in the area by hh member"

*collapse
qui include "$pathdo/copylabels.do"

ds(case_id id_code hh_b* visit ea_id qx_type), not
collapse (max) `r(varlist)', by(case_id)

qui include "$pathdo/attachlabels.do"

g year = 2013
compress
save "$pathout/hh_dem_wave2.dta", replace

* append the two datasets together
append using "$pathout/hh_dem_wave1.dta"
sort case_id year
save "$pathout/hh_demog.dta", replace

