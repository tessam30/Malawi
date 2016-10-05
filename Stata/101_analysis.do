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
	saveold "$pathout/FCS_rplot.dta", replace
	
restore

* Investigate the food insecurity data


g byte vulnHead = (agehead<18 | agehead >59) & !missing(agehead)
la var vulnHead "Hoh is younger than 18 or older than 60"

* Analyze major shocks
global demog "agehead c.agehead#c.agehead i.femhead i.marriedHoh vulnHead ib(3).religHoh
global educ "litHead educAdult gendMix hhsize mlabor flabor
global assets
global geog
global seopts "cluster(ea_id)"
