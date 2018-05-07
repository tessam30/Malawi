/*-------------------------------------------------------------------------------
# Name:		02_hhbase
# Purpose:	create a standardized household base that you can use as a merge-into file
# Author:	Tim Essam, Ph.D.
# Updated:  2016/09/26
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

* Use the household base from the LSMS group
* Source the household Geovariables data to set up the base structure
include "$pathdo/Malawi_HH_Geovariables_Do_file.do"

clear
capture log close
log using "$pathout/hh_base.txt", replace

use "$wave1/ConsumptionAggregate_2010.dta", clear
g byte hhPanel = 1
g year = 2011
save "$pathout/panel_2011.dta", replace

use "$wave1/ihs3_summary.dta", clear

clonevar hhwgt_2011 = hhweight

ds (rexp*), not
keep `r(varlist)'

#delimit ;
local klist case_id ea_id region urban area district TA strata cluster
		hhweight hhwgt_2011 hhsize adulteq intmonth intyear month head_age head_gender
		head_edlevel head_marital;
#delimit cr
keep `klist'
g year = 2011

merge 1:1 case_id using "$pathout/panel_2011.dta", gen(_panel)
replace hhPanel = 0 if _panel == 1
drop _panel
save "$pathout/hh_base1.dta", replace

use "$wave2/ConsumptionAggregate2013.dta", replace

ren hhweight hhweight2013
#delimit ;
local klist2 y2_hhid case_id HHID ea_id region urban district strata hhweight2013
		hhweightR1 hhsize adulteq intmonth intyear panel interview_status
		rexpagg pcrexpagg absolute_povline extreme_povline poor epoor price_indexL;
#delimit cr
keep `klist2'
g year = 2013
append using "$pathout/hh_base1.dta", force

g id = case_id if year == 2011
replace id = y2_hhid if id == "" & year == 2013

* ID will be the merge variable going forward. Eventually need to figure out a way of identifying
* panel households.

merge 1:1 id using "$pathout/geovars_all.dta", gen(_geo)

save "$pathout/hh_base_all.dta", replace

* Create a base roster for the panel households around in 2011
* Use this to create flags for sub-analysis of households over time


* Create a district variable that you'll need downstream
use "$wave2/HH_MOD_A_FILT.dta", clear
keep y2_hhid district stratum
save "$pathout/district2014.dta", replace

********** 2016 Household base roster **************
use "$wave3/HH_MOD_B.dta", clear

* Flag to who is a regular member of a household
* Using 6 months as a cutoff for hosuehold membership
g byte hhmemb = inlist(hh_b07, 0, 1, 2, 3, 4, 5, 6) == 1
la var hhmemb "Usual member of a household?"

* How different is this number for the official numbers? Unclear, b/c data are not available w/ IHS
egen hhsize = total(hhmemb), by(case_id)
la var hhsize "househld size"

keep if hhmemb == 1

keep case_id HHID PID hhsize

merge m:1 case_id using "$wave3/HH_MOD_A_FILT.dta", gen(_hh_details)
keep if _hh_details == 3

keep case_id PID hhsize ea_id region district reside hh_wgt interviewDate
save "$pathout/hh_base_indiv_2016.dta", replace

* Collapse down to the hh level
qui include "$pathdo/copylabels.do"
collapse (max) hhsize region district hh_wgt, by(case_id)
qui include "$pathdo/attachlabels.do"

merge 1:1 case_id using "$wave3/HH_MOD_A_FILT.dta"
drop _merge hh_w01 hh_s01 hh_o0a hh_g09 hh_a13 hh_a11 hh_a06

merge 1:1 case_id using "$pathout/geovars_2016.dta"

compress
save "$pathout/hh_base_2016.dta", replace
