/*-------------------------------------------------------------------------------
# Name:		03_landowned
# Purpose:	Create land holding
# Author:	Tim Essam, Ph.D.
# Created:	2016/04/27
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close
log using "$pathlog/land_own2011.dta", replace

use "$wave1/AG_MOD_C.dta", clear
drop if ag_c00 == ""
isid case_id ag_c00

clonevar plotsize = ag_c04c

keep case_id ea_id ag_c00 plotsize

tempfile plots
save "`plots'"


* Clean up the merging variables to get a clean merge
use "$wave1/AG_MOD_D.dta", clear

clonevar ag_c00 = ag_d00
drop if ag_c00 == ""
bys case_id ag_c00: gen id = _n
drop if id != 1

g byte ownplot = inlist(ag_d03, 2, 3, 4, 5) & inrange(ag_d04a, 1, 10)
keep case_id visit ea_id ag_c00 ownplot

merge 1:1 case_id ag_c00 using "`plots'", gen(_plots)

* keep the plots that are owned by the household; collapse to hh
keep if ownplot == 1
keep case_id ag_c00 plotsize ownplot


*collapse
qui include "$pathdo/copylabels.do"
	collapse ownplot (sum) landowned = plotsize, by(case_id)
qui include "$pathdo/attachlabels.do"

save "$pathout/ownplot_2011.dta", replace

