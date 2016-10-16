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
include "$pathdo2/pesort.do"

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
	keep FCS cereal_days roots_days meat_days milk_days veg_days fats_days sugar_days fruit_days district latitude longitude case_id hh_wgt	
	rename (cereal_days roots_days fats_days)(staples_days pulse_days oil_days)
	drop if FCS == .
	export delimited "$pathout/FCS_rplot.csv", replace
	saveold "$pathout/FCS_rplot.dta", replace
	
restore

* Investigate the food insecurity data
/*	collapse (mean) finsec_mar09-finsec_mar11 if year == 2011 [pw = hh_wgt], by(district).
	collapse (mean) finsec_apr12- finsec_oct13 if year == 2013 [pw = hhweight2013], by(district)
*/


* TODO: ea_id is missing for 2013 data; Need this to cluster standard errors


g byte vulnHead = (agehead<18 | agehead >59) & !missing(agehead)
la var vulnHead "Hoh is younger than 18 or older than 60"

recode urban (1 = 0 "urban")(2= 1 "rural"), gen(rural)
replace tluTotal = 0 if tluTotal == .

* Calculate land quartiles after winsorizing landowned
winsor landowned if year == 2011, gen(landowned_cnsrd) p(0.001) highonly
winsor landowned if year == 2013, gen(lo_cnsrd) p(0.001) highonly
replace landowned_cnsrd = lo_cnsrd if year == 2013
replace landowned_cnsrd = 0 if landowned == .

xtile landQtile = landowned_cnsrd if year == 2011, nq(4)
xtile lqtmp = landowned_cnsrd if year == 2013, nq(4)
replace landQtile = lqtmp if year == 2013 

* generate a squared term for education
g educAdultsq = educAdult^2
la var educAdultsq "highest adult education squared"

la var landowned_cnsrd "total land owned"
la var dist_popcenter "Distanced to nearest pop center"

* Analyze major shocks
global demog "agehead c.agehead#c.agehead i.femhead i.marriedHoh vulnHead"
global educ "litHeadChich litHeadEng educHoh educAdult educAdultsq gendMix depRatio mlabor flabor hhsize"
global assets "tluTotal  ag_index_2011 durables_index_2011 infra_index_2011 landowned_cnsrd ib(4).landQtile"
global assets2 "tluTotal  wealth_2011 landowned_cnsrd ib(4).landQtile"
global community "community_index_2011 dist_borderpost dist_popcenter dist_road"
global geog " i.region i.rural"
global geog2 "ib(206).district"
global survey "ib(7).intmonth ib(2010).intyear" 
global opts "if year == 2011"
global seopts "cluster(ea_id)"

/* NOTE: Lilongwe is the reference distct */

* --- Ag Shocks -----
*--------------------
est clear
foreach x of varlist ag disaster foodprice health anyShock {

	eststo `x'1: reg `x' $demog $educ $assets $geog $opts, $seopts
	linktest
	eststo `x'2: reg `x' $demog $educ $assets $community $survey $geog $opts, $seopts
	linktest
	eststo `x'3: reg `x' $demog $educ $assets2 $community $survey $geog $opts, $seopts
	linktest
	eststo `x'4: reg `x' $demog $educ $assets $community $geog2 $survey $opts, $seopts
	linktest
	eststo `x'5: reg `x' $demog $educ $assets2 $community $geog2 $survey $opts, $seopts
	linktest
	est dir
	esttab `x'*, star(+ 0.10 ++ 0.05 +++ 0.01) label not
	
	}

esttab ag* disaster* foodprice* health* anyShock* using "$pathreg/Shocks_2011.csv", star(+ 0.10 ++ 0.05 +++ 0.01) label not replace

*******************************************************************
** ---------------- 2011 Subset ------------------------------------------

global opts "if year == 2011 & hhPanel == 1"

est clear
qui foreach x of varlist ag disaster foodprice health anyShock {

	eststo `x'1: reg `x' $demog $educ $assets $geog $opts, $seopts
	linktest
	eststo `x'2: reg `x' $demog $educ $assets $community $survey $geog $opts, $seopts
	linktest
	eststo `x'3: reg `x' $demog $educ $assets2 $community $survey $geog $opts, $seopts
	linktest
	eststo `x'4: reg `x' $demog $educ $assets $community $geog2 $survey $opts, $seopts
	linktest
	eststo `x'5: reg `x' $demog $educ $assets2 $community $geog2 $survey $opts, $seopts
	linktest
	est dir
	esttab `x'*, star(+ 0.10 ++ 0.05 +++ 0.01) label not
	
	}

esttab ag* disaster* foodprice* health* anyShock* using "$pathreg/Shocks_2011_sub.csv", star(+ 0.10 ++ 0.05 +++ 0.01) label not replace

*******************************************************************
** ---------------- 2013 ------------------------------------------
* Analyze major shocks
global demog "agehead c.agehead#c.agehead i.femhead i.marriedHoh vulnHead"
global educ "litHeadChich litHeadEng educHoh educAdult educAdultsq gendMix depRatio mlabor flabor hhsize"
global assets "tluTotal  ag_index_2013 durables_index_2013 infra_index_2013 landowned_cnsrd ib(4).landQtile"
global assets2 "tluTotal  wealth_2013 landowned_cnsrd ib(4).landQtile"
global community "community_index_2013 dist_borderpost dist_popcenter dist_road"
global geog " i.region i.rural"
global geog2 "ib(206).district"
global survey "ib(7).intmonth" 
global opts "if year == 2013"
global seopts "cluster(ea_id)"

est clear
qui foreach x of varlist ag disaster foodprice health anyShock {

	eststo `x'1: reg `x' $demog $educ $assets $geog $opts, $seopts
	linktest
	eststo `x'2: reg `x' $demog $educ $assets $community $survey $geog $opts, $seopts
	linktest
	eststo `x'3: reg `x' $demog $educ $assets2 $community $survey $geog $opts, $seopts
	linktest
	eststo `x'4: reg `x' $demog $educ $assets $community $geog2 $survey $opts, $seopts
	linktest
	eststo `x'5: reg `x' $demog $educ $assets2 $community $geog2 $survey $opts, $seopts
	linktest
	est dir
	esttab `x'*, star(+ 0.10 ++ 0.05 +++ 0.01) label not
	
	}
esttab ag* disaster* foodprice* health*  anyShock* using "$pathreg/Shocks_2013_sub.csv", star(+ 0.10 ++ 0.05 +++ 0.01) label not replace


*******************************************************************
** ---------------- PArticipation in Ganyu ------------------------
*******************************************************************

* What are the stats of people who participate in ganyu
g byte t = (year == 2011)
diff anyShock, t(ganyuParticipation) p(t) cov(agehead femhead marriedHoh /*
*/vulnHead femCount20_34 femCount35_59 under5 youth15to24 poor epoor FCS /*
*/ inferiorFood limitPortion reduceMeals restrictCons borrowFood foodInsecure12Months /*
*/ litHeadChich litHeadEng educHoh educAdult educAdultsq gendMix /*
*/ depRatio mlabor flabor hhsize tluTotal wealth_2013 ownLand mobilesOwned landowned_cnsrd /*
*/ ag foodprice disaster goodcope badcope improvedSanit improvedWater) test












* Statistics for posters -- all using 2014 data
preserve 
drop if year == 2011
* --- Shocks 2013/14
svyset ea_id [pweight=hhweight2013], strata(district) singleunit(centered)
svydescribe

* Summarize the shocks -- Use these for official stats
svy:mean anyShock foodprice ag disaster health 
svy:mean anyShock foodprice ag disaster health, over(region)
svy:mean anyShock foodprice ag disaster health, over(urban)
svy:mean foodprice ag disaster, over( region urban)

svy:mean FCS, over(region urban)
svy:mean ganyuParticipation , over(region urban)
svy:mean ganyuParticipation 

svy:mean ganyuTotHHWagePC
svy:mean ganyuTotHHWage

g lnganyuWR = ln(ganyuWR)
svy: mean lnganyuWR
	matrix smean = r(table)
	local varmean = smean[1,1]
svy: mean lnganyuWR, over(district)
	matrix plot = r(table)'
	matsort plot 1 "down"
	matrix plot = plot'
	coefplot (matrix(plot[1,])), ci((plot[5,] plot[6,])) xline(`varmean')
	
tab tot_shocks
g byte twoOrFewerShocks = (tot_shocks <= 2)
tab twoOrFewerShocks, mi

* Run a regression on hh with two or fewer shocks
est clear
foreach x of varlist twoOrFewerShocks {

	eststo `x'1: reg `x' $demog $educ $assets $geog $opts, $seopts
	linktest
	eststo `x'2: reg `x' $demog $educ $assets $community $survey $geog $opts, $seopts
	linktest
	eststo `x'3: reg `x' $demog $educ $assets2 $community $survey $geog $opts, $seopts
	linktest
	eststo `x'4: reg `x' $demog $educ $assets $community $geog2 $survey $opts, $seopts
	linktest
	eststo `x'5: reg `x' $demog $educ $assets2 $community $geog2 $survey $opts, $seopts
	linktest
	est dir
	esttab `x'*, star(+ 0.10 ++ 0.05 +++ 0.01) label not
	
	}
esttab two* using "$pathreg/Shocks_2013_sub.csv", star(+ 0.10 ++ 0.05 +++ 0.01) label not replace
