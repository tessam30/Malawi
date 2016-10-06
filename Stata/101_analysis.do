/*-------------------------------------------------------------------------------
# Name:		101_Analysis
# Purpose:	Analyze shocks and participation in ganyu labor
# Author:	Tim Essam, Ph.D.
# Created:	2016/09/22
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close
log using "$pathlog/analysis.do", replace

* load custom program that calculates point estimates, sorts results and plots them.
* TODO: Fix program syntax to be generalizable to all datasets
include "$pathdo/pesort.do"

use "$pathout/MalawiIHS_analysis.dta", clear

* First, we will look at the major shocks as was done in other LAMS
* Use sampling weights for the fulls sample in 2011
preserve
	keep if year == 2011 
	svyset ea_id [pweight=hh_wgt], strata(district) singleunit(centered)
	svy:mean ag conflict disaster financial health foodprice, over(region)
	
	* Create a graphic of the 
	pesort disaster district
	pesort ag district
	pesort foodprice district

		
	* Create an export for R function
	keep FCS cereal_days roots_days meat_days milk_days veg_days fats_days sugar_days fruit_days district latitude longitude case_id	
	rename (cereal_days roots_days fats_days)(staples_days pulse_days oil_days)
	tostring district, gen(District)
	saveold "$pathout/FCS_rplot.dta", replace
	
restore

* Investigate the food insecurity data

* TODO: ea_id is missing for 2013 data; Need this to cluster standard errors


g byte vulnHead = (agehead<18 | agehead >59) & !missing(agehead)
la var vulnHead "Hoh is younger than 18 or older than 60"

* Calculate land quartiles after winsorizing landowned
winsor landowned if year == 2011, gen(landowned_cnsrd) p(0.001) highonly
winsor landowned if year == 2013, gen(lo_cnsrd) p(0.001) highonly
replace landowned_cnsrd = lo_cnsrd if year == 2013
replace landowned_cnsrd = 0 if landowned == .

xtile landQtile = landowned_cnsrd if year == 2011, nq(4)
xtile lqtmp = landowned_cnsrd if year == 2013, nq(4)
replace landQtile = lqtmp if year == 2013 

* Analyze major shocks
global demog "agehead c.agehead#c.agehead i.femhead i.marriedHoh vulnHead"
global educ "litHeadChich litHeadEng educAdult gendMix hhsize"
global assets "tluTotal wealth_2013 landowned_cnsrd ib(4).landQtile"
global geog "dist_borderpost dist_popcenter dist_road i.region" 
global seopts "cluster(ea_id)"


logit foodprice $demog $educ $assets $geog if year == 2011, cluster(ea_id) or
linktest
