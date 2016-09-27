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
clear
capture log close
log using "$pathout/hh_base.txt", replace

use "$wave1/ihs3_summary.dta", clear

ds (rexp*), not
keep `r(varlist)'

#delimit ;
local klist case_id ea_id region urban area district TA strata cluster 
		hhweight hhsize adulteq intmonth intyear month head_age head_gender 
		head_edlevel head_marital;
#delimit cr
keep `klist'
g year = 2011
save "$pathout/hh_base1.dta", replace

use "$wave2/ConsumptionAggregate2013.dta", replace

#delimit ;
local klist2 y2_hhid case_id HHID ea_id region urban district strata hhweight 
		hhweightR1 hhsize adulteq intmonth intyear panel interview_status 
		rexpagg pcrexpagg absolute_povline extreme_povline poor epoor price_indexL;
#delimit cr
keep `klist2'
g year = 2013
append using "$pathout/hh_base1.dta"

g id = case_id if year == 2011
replace id = y2_hhid if id == "" & year == 2013

* ID will be the merge variable going forward. Eventually need to figure out a way of identifying
* panel households.

save "$pathout/hh_base_all.dta", replace
