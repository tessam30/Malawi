* Describe what is accomplished with file:
* This .do file processed communual organisation   
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
use "$wave1/COM_CJ.dta"

/* Organisation 
Village Development Committee 
Agricultural Coop 
Farmers' Group 
Savings & Credit Coop 
Business Assoc. 
Women's Group 
Youth Group 
Political Group 
Religious Group 
Cultural Group 
Health Committee 
School Committee 
Parent-Teacher Assoc. 
Sports Group 
NGO 
Community Police/Watch Group 
Disabled Assoc. 
Other (Specify) */

g VDC = com_cj0b == 301 & com_cj01 == 1
g Agr_Coop = com_cj0b == 302 & com_cj01 == 1
g Farmers_Grp = com_cj0b == 303 & com_cj01 == 1
g Sav_Cred_Coop = com_cj0b== 304 & com_cj01 == 1
g Business_Assoc = com_cj0b == 305 & com_cj01 == 1
g Women_Grp = com_cj0b == 306 & com_cj01 == 1
g Youth_Grp = com_cj0b == 307 & com_cj01 == 1
g Political_Grp = com_cj0b == 308 & com_cj01 == 1
g Religious_Grp = com_cj0b == 309 & com_cj01 == 1
g Cultural_Grp = com_cj0b == 310 & com_cj01 == 1
g Health_Comm = com_cj0b == 311 & com_cj01 == 1
g School_Comm = com_cj0b == 312 & com_cj01 == 1
g PTA = com_cj0b == 313 & com_cj01 == 1
g Sports_Grp = com_cj0b == 314 & com_cj01 == 1
g NGO = com_cj0b == 315 & com_cj01 == 1
g Commnty_Police = com_cj0b == 316 & com_cj01 == 1
g Disabled_Assoc = com_cj0b == 317 & com_cj01 == 1
g Other	= com_cj0b == 318 & com_cj01 == 1

la var VDC "Village Development Committee" 
la var Agr_Coop "Agricultural Coop"
la var Farmers_Grp "Farmers' Group"
la var Sav_Cred_Coop "Savings & Credit Coop" 
la var Business_Assoc "Business Assoc."
la var Women_Grp "Women's Group"
la var Youth_Grp "Youth Group"
la var Political_Grp "Political Group"
la var Religious_Grp "Religious Group"
la var Cultural_Grp "Cultural Group"
la var Health_Comm "Health Committee"
la var School_Comm "School Committee"
la var PTA "Parent-Teacher Assoc."
la var Sports_Grp "Sports Group"
la var NGO "NGO"
la var Commnty_Police "Community Police/Watch Group"
la var Disabled_Assoc "Disabled Assoc."
la var Other "Other (Specify)"


g femVDC = com_cj05 if VDC == 1
g femAgr_Coop = com_cj05 if Agr_Coop == 1
g femFarmers_Grp = com_cj05 if Farmers_Grp == 1  
g femSav_Cred_Coop = com_cj05 if Sav_Cred_Coop == 1
g femBusiness_Assoc = com_cj05 if Business_Assoc == 1
g femWomen_Grp = com_cj05 if Women_Grp == 1
g femYouth_Grp = com_cj05 if Youth_Grp == 1
g femPolitical_Grp = com_cj05 if Political_Grp == 1
g femReligious_Grp = com_cj05 if Religious_Grp == 1
g femCultural_Grp = com_cj05 if Cultural_Grp == 1
g femHealth_Comm = com_cj05 if Health_Comm == 1
g femSchool_Comm = com_cj05 if School_Comm == 1
g femPTA = com_cj05 if PTA == 1
g femSports_Grp = com_cj05 if Sports_Grp == 1
g femNGO = com_cj05 if NGO == 1
g femCommnty_Police = com_cj05 if Commnty_Police == 1
g femDisabled_Assoc = com_cj05 if Disabled_Assoc == 1
g femOther	= com_cj05 if Other == 1

la var femVDC "Female Members in Village Development Committee" 
la var femAgr_Coop "Female Members in Agricultural Coop"
la var femFarmers_Grp "Female Members in Farmers' Group"
la var femSav_Cred_Coop "Female Members in Savings & Credit Coop" 
la var femBusiness_Assoc "Female Members in Business Assoc."
la var femWomen_Grp "Female Members in Women's Group"
la var femYouth_Grp "Female Members in Youth Group"
la var femPolitical_Grp "Female Members in Political Group"
la var femReligious_Grp "Female Members in Religious Group"
la var femCultural_Grp "Female Members in Cultural Group"
la var femHealth_Comm "Female Members in Health Committee"
la var femSchool_Comm "Female Members in School Committee"
la var femPTA "Female Members in Parent-Teacher Assoc."
la var femSports_Grp "Female Members in Sports Group"
la var femNGO "Female Members in NGO"
la var femCommnty_Police "Female Members in Community Police/Watch Group"
la var femDisabled_Assoc "Female Members in Disabled Assoc."
la var femOther "Female Members in Other (Specify)"

* Keep derived data (FCS & dietary diversity scores) and HHID
ds(hh_s* saq* ea_id), not
keep `r(varlist)'

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
ds(case_id), not
collapse (max) `r(varlist)', by(ea_id)
qui include "$pathdo/attachlabels.do"


sa "$pathout/communnal_organisation_2011.dta", replace

***** Wave 2 *****
* Process 2nd wave 
* Load the dataset needed to ptocess communal organisation variables
use "$wave2/COM_MOD_J.dta"

/* Organisation 
Village Development Committee 
Agricultural Coop 
Farmers' Group 
Savings & Credit Coop 
Business Assoc. 
Women's Group 
Youth Group 
Political Group 
Religious Group 
Cultural Group 
Health Committee 
School Committee 
Parent-Teacher Assoc. 
Sports Group 
NGO 
Community Police/Watch Group 
Disabled Assoc. 
Other (Specify) 
Tobacco Club */

g VDC = com_cj0b == 301 & com_cj01 == 1
g Agr_Coop = com_cj0b == 302 & com_cj01 == 1
g Farmers_Grp = com_cj0b == 303 & com_cj01 == 1
g Sav_Cred_Coop = com_cj0b== 304 & com_cj01 == 1
g Business_Assoc = com_cj0b == 305 & com_cj01 == 1
g Women_Grp = com_cj0b == 306 & com_cj01 == 1
g Youth_Grp = com_cj0b == 307 & com_cj01 == 1
g Political_Grp = com_cj0b == 308 & com_cj01 == 1
g Religious_Grp = com_cj0b == 309 & com_cj01 == 1
g Cultural_Grp = com_cj0b == 310 & com_cj01 == 1
g Health_Comm = com_cj0b == 311 & com_cj01 == 1
g School_Comm = com_cj0b == 312 & com_cj01 == 1
g PTA = com_cj0b == 313 & com_cj01 == 1
g Sports_Grp = com_cj0b == 314 & com_cj01 == 1
g NGO = com_cj0b == 315 & com_cj01 == 1
g Commnty_Police = com_cj0b == 316 & com_cj01 == 1
g Disabled_Assoc = com_cj0b == 317 & com_cj01 == 1
g Other	= com_cj0b == 318 & com_cj01 == 1
g Tobacco_Club = com_cj0b == 3302 & com_cj01 == 1

la var VDC "Village Development Committee" 
la var Agr_Coop "Agricultural Coop"
la var Farmers_Grp "Farmers' Group"
la var Sav_Cred_Coop "Savings & Credit Coop" 
la var Business_Assoc "Business Assoc."
la var Women_Grp "Women's Group"
la var Youth_Grp "Youth Group"
la var Political_Grp "Political Group"
la var Religious_Grp "Religious Group"
la var Cultural_Grp "Cultural Group"
la var Health_Comm "Health Committee"
la var School_Comm "School Committee"
la var PTA "Parent-Teacher Assoc."
la var Sports_Grp "Sports Group"
la var NGO "NGO"
la var Commnty_Police "Community Police/Watch Group"
la var Disabled_Assoc "Disabled Assoc."
la var Other "Other (Specify)"
la var Tobacco_Club "Tobacco Club"

g femVDC = com_cj05 if VDC == 1
g femAgr_Coop = com_cj05 if Agr_Coop == 1
g femFarmers_Grp = com_cj05 if Farmers_Grp == 1  
g femSav_Cred_Coop = com_cj05 if Sav_Cred_Coop == 1
g femBusiness_Assoc = com_cj05 if Business_Assoc == 1
g femWomen_Grp = com_cj05 if Women_Grp == 1
g femYouth_Grp = com_cj05 if Youth_Grp == 1
g femPolitical_Grp = com_cj05 if Political_Grp == 1
g femReligious_Grp = com_cj05 if Religious_Grp == 1
g femCultural_Grp = com_cj05 if Cultural_Grp == 1
g femHealth_Comm = com_cj05 if Health_Comm == 1
g femSchool_Comm = com_cj05 if School_Comm == 1
g femPTA = com_cj05 if PTA == 1
g femSports_Grp = com_cj05 if Sports_Grp == 1
g femNGO = com_cj05 if NGO == 1
g femCommnty_Police = com_cj05 if Commnty_Police == 1
g femDisabled_Assoc = com_cj05 if Disabled_Assoc == 1
g femOther	= com_cj05 if Other == 1
g femTobacco_Club = com_cj05 if Tobacco_Club == 1

la var femVDC "Female Members in Village Development Committee" 
la var femAgr_Coop "Female Members in Agricultural Coop"
la var femFarmers_Grp "Female Members in Farmers' Group"
la var femSav_Cred_Coop "Female Members in Savings & Credit Coop" 
la var femBusiness_Assoc "Female Members in Business Assoc."
la var femWomen_Grp "Female Members in Women's Group"
la var femYouth_Grp "Female Members in Youth Group"
la var femPolitical_Grp "Female Members in Political Group"
la var femReligious_Grp "Female Members in Religious Group"
la var femCultural_Grp "Female Members in Cultural Group"
la var femHealth_Comm "Female Members in Health Committee"
la var femSchool_Comm "Female Members in School Committee"
la var femPTA "Female Members in Parent-Teacher Assoc."
la var femSports_Grp "Female Members in Sports Group"
la var femNGO "Female Members in NGO"
la var femCommnty_Police "Female Members in Community Police/Watch Group"
la var femDisabled_Assoc "Female Members in Disabled Assoc."
la var femOther "Female Members in Other (Specify)"
la var femTobacco_Club "Female Members in Tobacco Club)"

* Keep derived data (FCS & dietary diversity scores) and HHID
ds(hh_s* saq* ea_id), not
keep `r(varlist)'

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
ds(case_id), not
collapse (max) `r(varlist)', by(ea_id)
qui include "$pathdo/attachlabels.do"


sa "$pathout/communal_organisation_2013.dta", replace
