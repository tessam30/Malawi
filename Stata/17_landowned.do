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

* First process plot details from the rainy season
use "$wave1/AG_MOD_C.dta", clear
drop if ag_c00 == ""
isid case_id ag_c00

clonevar plotsize = ag_c04c

keep case_id ea_id ag_c00 plotsize

tempfile plotRainy
save "`plotRainy'"

* Clean up the merging variables to get a clean merge
use "$wave1/AG_MOD_D.dta", clear

clonevar ag_c00 = ag_d00
drop if ag_c00 == ""
bys case_id ag_c00: gen id = _n
drop if id != 1

g byte ownplotRainy = inrange(ag_d03, 1, 5) 
keep case_id visit ea_id ag_c00 ownplotRainy

merge 1:1 case_id ag_c00 using "`plotRainy'", gen(_plots)

* keep the plots that are owned by the household; collapse to hh
keep if ownplotRainy == 1
keep case_id ag_c00 plotsize ownplotRainy

*collapse
qui include "$pathdo/copylabels.do"
	collapse ownplotRainy (sum) landownedRainy = plotsize (count) plotsOwnedRainy = ownplotRainy, by(case_id)
qui include "$pathdo/attachlabels.do"

tempfile plotRainyOwn
save "`plotRainyOwn'"

* ##################
* Dry Season Owned #
* ##################
* Process dry season land ownership as well

use "$wave1/AG_MOD_J.dta", clear
drop if ag_j00 == ""

* Check for uniquness
isid case_id ag_j00
clonevar plotsize = ag_j05c
keep case_id ea_id ag_j00 plotsize

tempfile plotDry
save "`plotDry'"

* Clean up the merging variables to get a clean merge
* 3 cases where id is not uninque (dropping)
use "$wave1/AG_MOD_K.dta", clear
clonevar  ag_j00 = ag_k0a

* Filter out variables missing id information or that have been previously reported
drop if ag_j00 == "" | ag_k01 != 2
bys case_id ag_j00: gen id = _n
isid case_id ag_j00

* Not worrying about who owns the land for now
g byte ownplotDry = inrange(ag_k04, 1, 5) 
keep if ownplotDry == 1
keep case_id visit ea_id ag_j00 ownplotDry

merge 1:1 case_id ag_j00 using "`plotDry'", gen(_plots)
keep if _plots == 3
/* Merge NOTES: */

*collapse
qui include "$pathdo/copylabels.do"
	collapse ownplotDry (sum) landownedDry = plotsize (count) plotsOwnedDry = ownplotDry, by(case_id)
qui include "$pathdo/attachlabels.do"

* Combine the rainy and dry land holdings together
merge 1:1 case_id using  "`plotRainyOwn'", gen(_land2011)
/* NOTE: 907 households have different plots in rainy and wet season */


* Create total land owned variables
egen double landowned = rsum(landownedDry landownedRainy)
replace landowned = . if landowned == 0
* Add condition so we do not overcount the total plots owned
egen plotsOwned = rsum(plotsOwnedRainy plotsOwnedDry)
sum landowned, d
scalar  cutoff = `r(p99)'
g avePlotSize if landowned <= cutoff = landowned / plotsOwned
sum landowned if landowned <= cutoff

la var landowned "total cultivatable land owned (rainy + dry season)"
la var landownedDry "total cultivatable land owned (rainy season)"
la var landownedRainy "total cultivatable land owned (dry season)"
la var plotsOwnedDry "total plots owned (dry season)"
la var plotsOwnedRainy "total plots owned (rainy season)"
la var plotsOwned "total plots owned (rainy + dry season)"
la var a

gen year = 2011
compress

save "$pathout/ownplot_2011.dta", replace

* ------------------------------- Start Second Wave -------------------------------------------------

* ############
* 2013 Data #
* ###########
use "$wave2/AG_MOD_C.dta", clear

drop if ag_c00 == ""
isid y2_hhid ag_c00

clonevar plotsize = ag_c04c

keep y2_hhid ag_c00 plotsize

tempfile plotRainy13
save "`plotRainy13'"

* Clean up the merging variables to get a clean merge
use "$wave2/AG_MOD_D.dta", clear

clonevar ag_c00 = ag_d00
drop if ag_c00 == ""
bys y2_hhid ag_c00: gen id = _n
drop if id != 1

g byte ownplotRainy = inrange(ag_d03, 1, 5) 
keep y2_hhid ag_c00 ownplotRainy

merge 1:1 y2_hhid ag_c00 using "`plotRainy13'", gen(_plots)
keep if _plots == 3

* keep the plots that are owned by the household; collapse to hh
keep if ownplotRainy == 1
keep y2_hhid ag_c00 plotsize ownplotRainy

*collapse
qui include "$pathdo/copylabels.do"
	collapse ownplotRainy (sum) landownedRainy = plotsize (count) plotsOwnedRainy = ownplotRainy, by(y2_hhid)
qui include "$pathdo/attachlabels.do"

tempfile plotRainyOwn13
save "`plotRainyOwn13'"

* ##################
* Dry Season Owned #
* ##################
* Process dry season land ownership as well

use "$wave2/AG_MOD_J.dta", clear
drop if ag_j00 == ""

* Check for uniquness
isid y2_hhid ag_j00
clonevar plotsize = ag_j05c
keep y2_hhid  ag_j00 plotsize

tempfile plotDry13
save "`plotDry13'"

* Clean up the merging variables to get a clean merge
* 3 cases where id is not uninque (dropping)
use "$wave2/AG_MOD_K.dta", clear
clonevar  ag_j00 = ag_k00

* Filter out variables missing id information or that have been previously reported
drop if ag_j00 == "" | ag_k01 != 2
bys y2_hhid ag_j00: gen id = _n
isid y2_hhid ag_j00

* Not worrying about who owns the land for now
g byte ownplotDry = inrange(ag_k04, 1, 5) 
keep if ownplotDry == 1
keep y2_hhid ag_j00 ownplotDry

merge 1:1 y2_hhid ag_j00 using "`plotDry13'", gen(_plots)
keep if _plots == 3
/* Merge NOTES: */

*collapse
qui include "$pathdo/copylabels.do"
	collapse ownplotDry (sum) landownedDry = plotsize (count) plotsOwnedDry = ownplotDry, by(y2_hhid)
qui include "$pathdo/attachlabels.do"

* Combine the rainy and dry land holdings together
merge 1:1 y2_hhid using  "`plotRainyOwn13'", gen(_land2013)
/* NOTE: 502 households have different plots in rainy and wet season */


* Create total land owned variables
egen double landowned = rsum(landownedDry landownedRainy)
replace landowned = . if landowned == 0
egen plotsOwned = rsum(plotsOwnedRainy plotsOwnedDry)  if plotsOwnedDry > 0 | plotsOwnedDry > 0 


sum landowned, d
scalar  cutoff = `r(p99)'
g avePlotSize if landowned <= cutoff = landowned / plotsOwned
sum landowned if landowned <= cutoff

la var landowned "total cultivatable land owned (rainy + dry season)"
la var landownedDry "total cultivatable land owned (rainy season)"
la var landownedRainy "total cultivatable land owned (dry season)"
la var plotsOwnedDry "total plots owned (dry season)"
la var plotsOwnedRainy "total plots owned (rainy season)"
la var plotsOwned "total plots owned (rainy + dry season)"
la var avePlotSize "average plot size"

gen year = 2013
compress

save "$pathout/ownplot_2013.dta", replace

append using "$pathout/ownplot_2011.dta"
order case_id y2_hhid year

clonevar id = case_id
replace id = y2_hhid if id == "" & year == 2013
order id

order _land2013, after(_land2011)

save "$pathout/ownplot_all.dta", replace
* Merge in with the household roster for merging with other data

