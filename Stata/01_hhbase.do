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
