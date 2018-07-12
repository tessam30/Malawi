/*-------------------------------------------------------------------------------
# Name:		03_StuntingAnalysis_2010
# Purpose:	Plot data and run stunting anlaysis models
# Author:	Tim Essam, Ph.D.
# Created:	2018/07/09
# Owner:	USAID GeoCenter 
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/
clear

* Source the previous files that build the analysis dataset
include "$pathDHS/01_hhassets_2010.do"
include "$pathDHS/03_stunting_2010.do"

capture log close

log using "$pathlog/03a_StuntingAnalysis2010", replace
use "$DHSout/DHS_2010_analysis.dta", clear

* Label the cmc codes di 12*(2015 - 1900)+1) --> Jan 2015 (last digit is month)

	la def cmc 1326 "Jun. 2010" 1327 "Jul. 2010" 1328 "Aug. 2010" 1329 "Sep. 2010"
	la val intdate cmc

* Fix altitude
	replace altitude = . if altitude == 9999
	
* What does the within cluster distribution of stunting scores look like?
	egen clust_stunt = mean(stunting2), by(strata)
	egen alt_stunt = mean(stunting2), by(altitude)

* Basic plots
	twoway(scatter clust_stunt strata)
	twoway(scatter stunting2 strata)

* Summary of z-scores by altitudes
	twoway (scatter alt_stunt altitude, sort mcolor("192 192 192") msize(medsmall) /*
	*/ msymbol(circle) mlcolor("128 128 128") mlwidth(thin)) (lpolyci alt_stunt /*
	*/ altitude [aweight = cweight] if inrange(altitude, 0, 2000), clcolor("99 99 99") clwidth(medthin)), /*
	*/ ytitle(Stunting Z-score) ytitle(, size(small) color("128 128 128")) /*
	*/ xtitle(, size(small) color("128 128 128")) title(Stunting outcomes appear /*
	*/ to worsen with increases in elevation., size(small) color("99 99 99") /*
	*/ span justification(left))

* Summary of stunting by wealth
	twoway (scatter stunting2 wealth, sort mcolor("192 192 192") msize(medsmall)/* 
	*/msymbol(circle) mlcolor("128 128 128") mlwidth(thin)) (lpolyci stunting2 /*
	*/wealth [aweight = cweight], clcolor("99 99 99") clwidth(medthin)), /*
	*/ytitle(Stunting Z-score) ytitle(, size(small) color("128 128 128")) /* 
	*/yline(-2, lwidth(medium) lcolor("99 99 99")) xtitle(, size(small) /*
	*/color("128 128 128")) xline(0, lwidth(medium) lcolor("99 99 99")) /*
	*/title(Stunting outcomes appear to positively correlate with /*
	*/elevation., size(small) color("99 99 99") span justification(left)) /*
	*/ysca(alt) xsca(alt) xlabel(, grid gmax) legend(off) saving(main, replace)

	twoway histogram stunting2, fraction xsca(alt reverse) ylabel(, grid gmax) horiz fxsize(25)  saving(hy, replace)
	twoway histogram wealth, fraction ysca(alt reverse) ylabel(, nogrid)/*
	*/ fysize(25) xlabel(, grid gmax) saving(hx, replace)
	* Combine graphs together to put histograms on x/y axis
	graph combine hy.gph main.gph hx.gph, hole(3) imargin(0 0 0 0) 

	* Survey set the data to account for complex sampling design
	* Ntchisi (strata == 43) only has 1 sampling unit in the urban strata
	* Need to recode this with strata == 44 to get point estimates w/ std. errors or drop
	clonevar strata_mod = strata
	replace strata_mod = 44 if strata_mod == 43
	
	svyset psu [pw = cweight], strata(strata_mod)
	svydescribe
	
	* Look at the stunting prevalence across FFP focus zones
	svy:mean stunted2, over(ffp_focus)
	

* Show the distribituion of education on z-scores
	twoway (kdensity stunting2 if motherEd ==0)(kdensity stunting2 if motherEd ==1) /*
	*/ (kdensity stunting2 if motherEd ==2)(kdensity stunting2 if motherEd ==3) /*
	*/ , xline(-2, lwidth(thin) lpattern(dash) lcolor("199 199 199"))

* Check stunting over standard covariates
	svy:mean stunting2, over(district)
	svy:mean stunted2, over(district)
	matrix smean = r(table)
	matrix district = smean'
	mat2txt, matrix(district) saving("$pathxls/stunting_dist2010") replace

* Create locals for reference lines in coefplot
	local stuntmean = smean[1,1]
	local lb = smean[5, 1]
	local ub = smean[6, 1]

	matrix plot = r(table)'
	matsort plot 1 "down"
	matrix plot = plot'
	coefplot (matrix(plot[1,])), ci((plot[5,] plot[6,])) xline(`stuntmean' `lb' `ub')

* Create a table for export
	matrix district = e(_N)'
	matrix stunt = smean'
	matrix gis = district, stunt
	mat2txt, matrix(gis) saving("$pathxls/district_stunting2010.csv") replace
	matrix drop _all


	* Check stunting over livelihood zones
	svy:mean stunting2, over(ffp_focus)
	matrix smean = r(table)
	matrix lvdzone = smean'
	*mat2txt, matrix(lvdzone) saving("$pathxls/stunting_lvd2010") replace

* running a few other statistics
svy:mean stunted2, over(female)
svy:mean stunted2, over(wealthGroup)
svy:mean stunted2, over(motherBMI female)
svy:mean stunted2, over(religion)
svy:mean stunted2, over(diarrhea)

* Save a cut for any GIS products
preserve
	keep if eligChild == 1
	keep v001 v002 stunted2 stunting2 latnum longnum urban_rura alt_gps dhsclust ageChild religion ffp_focus
	export delimited "$pathxls\MWI_2010_DHS_stunting.csv", replace
restore

bob
/* Consider stunting over the livelihood zones.
	mean stunted2, over(lvdzone)
	cap matrix drop plot smean
	matrix smean = r(table)
	local stuntmean = smean[1,1]
	local lb = smean[5, 1]
	local ub = smean[6, 1]
	matrix plot = r(table)'
	matsort plot 1 "down"
	matrix plot = plot'
	coefplot (matrix(plot[1,])), ci((plot[5,] plot[6,])) xline(`stuntmean' `lb' `ub')
*/

	set matsize 1000
	pwmean stunting2, over(ffp_focus) pveffects mcompare(tukey)
	pwmean stunted2, over(district) pveffects mcompare(tukey)

* calculate moving average
preserve
	collapse (sum) stunted2 (count) stuntN = stunted2, by(ageChild female)
	drop if ageChild == . | ageChild<6
	sort female ageChild
	xtset  female ageChild

	bys female: g smoothStunt = (l2.stunted2 + l1.stunted2 + stunted2 + f1.stunted2 + f2.stunted2)/ /*
	*/		(l2.stuntN + l1.stuntN + stuntN + f1.stuntN + f2.stuntN) 

	tssmooth ma stuntedMA = (stunted2/stuntN), window(2 1 2)
	xtline(stuntedMA smoothStunt)
restore

export delimited "$pathout/stuntingAnalysis2010.csv", replace
saveold "$pathout/stuntingAnalysis2010.dta", replace

* Stunting regression analysis using various models; 
	g agechildsq = ageChild^2
	la var rural "rural household"
	
	g altitude2 = altitude/1000
	la var altitude2 "altitude divided by 1000"
	egen hhgroup = group(v001 v002) if eligChild == 1

	replace wantedChild = . if wantedChild ==9
	replace idealChildNo = . if idealChildNo == 7

	replace anemia = . if anemia == 9
	save "$pathout/DHS_2010_Stunting.dta", replace
	
* Create a geography variable to cpature the three main zones of the FFP focus
	g ffp_zone = 1 if (inlist(district, 309, 303, 304, 308) & ffp_focus == 1)
	replace ffp_zone = 2 if (inlist(district, 301, 302, 209, 312) & ffp_focus == 1)
	replace ffp_zone = 3 if (inlist(district, 313, 305) & ffp_focus == 1)

	la var dist 1 "Phalombe" 2 "Mangochi" 3 "

* Create groups for covariates as they map into conceptual framework for stunting
	* -- Birthw weight is missing for quite a few of the kiddos. Drops sample for regression down to around ~3000
	
	global matchar "motherBWeight motherBMI motherEd femhead orsKnowledge"
	global matchar2 "motherBWeight rohrer_idx motherEd femhead orsKnowledge"
	global hhchar "mobile bankAcount improvedSanit improvedWater bnetITNuse landless"
	global hhchar2 "wealth bnetITNuse"
	global contra "modernContra ib(1).wantedChild idealChildNo"
	global hhag "tlutotal"
	global hhag2 "cowtrad goat sheep chicken pig rabbit"
	global demog "hhsize agehead hhchildUnd5"
	global chldchar "ageChild agechildsq birthOrder" 
	global chldchar2 "ageChild agechildsq birthOrder birthWgt"
	global chealth "intParasites vitaminA diarrhea anemia"
	global geog "altitude2 rural i.ffp_focus"
	global geog2 "altitude2  ib(206).district"
	global cluster "cluster(dhsclust)"
	global cluster2 "cluster(hhgroup)"

* STOP: Check all globals for missing values!
sum $matchar $hhchar $hhag $demog female $chldchar $chealth $geog 

* First looka at continuous measure of malnutrition -- z-score
est clear
	eststo zcont_0: reg stunting2 $matchar $hhchar $contra $hhag $demog female $chldchar2 $chealth $geog ib(1327).intdate, $cluster 
	eststo zcont_1: reg stunting2 $matchar $hhchar $contra $hhag $demog female $chldchar2 $chealth $geog2 ib(1327).intdate, $cluster 
	eststo zcont_2: reg stunting2 $matchar $hhchar2 $contra $hhag $demog female $chldchar $chealth $geog ib(1327).intdate, $cluster 
	eststo zcont_3: reg stunting2 $matchar $hhchar2 $contra $hhag $demog female $chldchar $chealth $geog2 ib(1327).intdate, $cluster 	

	eststo zcont_4: reg stunting2 $matchar $hhchar $contra $hhag $demog female $chldchar2 $chealth altitude2 ib(1327).intdate if ffp_focus, $cluster 
	eststo zcont_5: reg stunting2 $matchar $hhchar $contra $hhag $demog female $chldchar2 $chealth altitude2 ib(1327).intdate if ffp_focus, $cluster 
	eststo zcont_6: reg stunting2 $matchar $hhchar2 $contra $hhag $demog female $chldchar $chealth altitude2 ib(1327).intdate if ffp_focus, $cluster 
	eststo zcont_7: reg stunting2 $matchar $hhchar2 $contra $hhag $demog female $chldchar $chealth altitude2 ib(1327).intdate if ffp_focus, $cluster 
	esttab zcont*, se star(* 0.10 ** 0.05 *** 0.01) ar2 pr2 beta not /*eform(0 0 1 1 1)*/ compress
* export results to .csv
	esttab zcont* using "$pathout/MWI_stunt_results_2010.csv", wide mlabels
	
* Now consider models that looking only at the stunting threshold	
	
	
	eststo sted2_3: logit stunted2 $matchar $hhchar $hhag $demog female $chldchar $chealth $geog ib(1333).intdate, $cluster or 
	eststo sted2_4: logit stunted2 $matchar $hhchar $hhag $demog female $chldchar $chealth $geog2 ib(1333).intdate, $cluster or
	eststo sted2_5: logit extstunted2 $matchar $hhchar $hhag $demog female $chldchar $chealth $geog ib(1333).intdate, $cluster or 
	eststo sted2_6: logit extstunted2 $matchar $hhchar $hhag $demog female $chldchar $chealth $geog2 ib(1333).intdate, $cluster or 
	esttab sted*, se star(* 0.10 ** 0.05 *** 0.01) label ar2 pr2 beta not /*eform(0 0 1 1 1)*/ compress
* export results to .csv
esttab sted* using "$pathout/`x'Wide2010.csv", wide mlabels(none) ar2 pr2 beta label replace not

	




* by gender
est clear
eststo sted2_1, title("Stunted 1"): reg stunting2 $matchar $hhchar $hhag $demog $chldchar $chealth $geog2 ib(1333).intdate if female == 1, $cluster 
eststo sted2_2, title("Stunted 2"): reg stunting2 $matchar $hhchar $hhag $demog $chldchar $chealth $geog2 ib(1333).intdate if female == 0, $cluster 
esttab sted*

* Regional variations
est clear
	local i = 0
	levelsof adm1name, local(levels)
	foreach x of local levels {
		local name =  strtoname("`x'")
		eststo stunt_`name', title("Stunted `x'"): reg stunting2 $matchar $hhchar /*
		*/ $hhag $demog female $chldchar $chealth $geog if adm1name == "`x'", $cluster 
		local i = `++i'
		}
	*
	esttab stunt_*, se star(* 0.10 ** 0.05 *** 0.01) label ar2 beta
	coefplot stunt_East || stunt_North || stunt_South || stunt_West, drop(_cons ) /*
	*/ xline(0) /*mlabel format(%9.2f) mlabposition(11) mlabgap(*2)*/ byopts(row(1)) 


/*
* Quantile regression 
sqreg stunting2 $matchar $hhchar $hhag $demog female $chldchar $chealth $geog, quantile(0.2 0.4 0.6 0.8) reps(100)
*qplot stunting2, recast(line)
grqreg, ci ols olsci

* compare manually
local x = 1
forvalues i = 0.2(0.2)0.8 {
	eststo bsqreq`x': bsqreg stunting2 $matchar $hhchar $hhag $demog female $chldchar $chealth $geog2, quantile(`i')
	local x = `++x'
	}
*end
esttab bsqreq*, se star(* 0.10 ** 0.05 *** 0.01) label

* Test for heteroskedasticity
qui reg stunting2 $matchar $hhchar $hhag $demog female $chldchar $chealth
estat hettest $matchar $hhchar $hhag $demog female $chldchar $chealth, iid
*/


	eststo sted2_1, title("Stunted 1"): reg stunting2 $matchar $hhchar $hhag $demog $chldchar $chealth $geog ib(1381).intdate, $cluster 
	eststo sted2_2, title("Stunted 2"): reg stunting2 $matchar $hhchar $hhag $demog $chldchar $chealth $geog2 ib(1381).intdate, $cluster 
	eststo sted2_3, title("Stunted 3"): reg stunting2 $matchar $hhchar $hhag2 $demog $chldchar $chealth $geog ib(1381).intdate, $cluster 
	eststo sted2_4, title("Stunted 4"): reg stunting2 $matchar $hhchar2 $hhag $demog $chldchar $chealth $geog ib(1381).intdate, $cluster 
	eststo sted2_5, title("Stunted 5"): reg stunting2 $matchar $hhchar2 $hhag2 $demog $chldchar $chealth $geog ib(1381).intdate, $cluster 
	eststo sted2_6, title("Stunted 6"): reg stunting2 $matchar $hhchar2 $hhag2 $demog $chldchar $chealth $geog2 ib(1381).intdate, $cluster 
	esttab sted2_*, se star(* 0.10 ** 0.05 *** 0.01) label wide ar2

* Sort the coefficients before plotting
matrix smean = r(table)
matrix district = smean'
matrix plot = r(table)'
matsort plot 1 "down"
matrix plot = plot'
coefplot (matrix(plot[1,])) , ci((plot[5,] plot[6,]))  xline(0, lwidth(thin) lcolor(gray)) mlabs(small) ylabel(, labsize(tiny)) xlabel(, labsize(small))
 log close

*** --- 2010 subset analysis of children under 24mo w/ diet div recall
clear
use "$pathout/RWA_DHS_2010_under24mo_analysis.dta", replace

	/* Livelihood zones are small -- don't place too much 
	emphasis on spatial results b/c of sample size */
	tab lvdzone, mi

* Stunting regression analysis using various models; 
	g agechildsq = ageChild^2
	la var rural "rural household" 
	g altitude2 = altitude/1000
	la var altitude2 "altitude divided by 1000"

*Fix anemia
	replace anemia = . if anemia == 9

* Create groups for covariates as they map into conceptual framework for stunting
	global matchar "motherBWeight motherBMI motherEd femhead orsKnowledge"
	global hhchar "wealth improvedSanit improvedWater bnetITNuse landless"
	global hhchar2 "mobile bankAcount improvedSanit improvedWater bnetITNuse"
	global hhag "tlutotal"
	global hhag2 "cowtrad goat sheep chicken pig rabbit cowmilk cowbull"
	global demog "hhsize agehead hhchildUnd5"
	global chldchar "ageChild agechildsq birthOrder birthWgt"
	global chealth "intParasites vitaminA diarrhea anemia"
	global geog "altitude2 rural"
	global geog2 "altitude2 ib(1).lvdzone "
	global cluster "cluster(dhsclust)"
	global cluster2 "cluster(hhgroup)"

* Run summary stats to verify that ranges are reasonable.
	sum stunting2 stunted2 extstunted2 dietdiv $matchar $hhchar $hhag $demog female $chldchar $chealth

* Be continuous versus binary
est clear
	eststo sted1_0: reg stunting2 dietdiv $matchar $hhchar $hhag $demog female $chldchar $chealth $geog ib(1333).intdate, $cluster 
	eststo sted1_1: reg stunting2 dietdiv $matchar $hhchar $hhag $demog female $chldchar $chealth $geog2 ib(1333).intdate, $cluster 
	eststo sted2_3: logit stunted2 dietdiv $matchar $hhchar $hhag $demog female $chldchar $chealth $geog ib(1333).intdate, $cluster or 
	eststo sted2_4: logit stunted2 dietdiv $matchar $hhchar $hhag $demog female $chldchar $chealth $geog2 ib(1333).intdate, $cluster or
	eststo sted2_5: logit extstunted2 dietdiv $matchar $hhchar $hhag $demog female $chldchar $chealth $geog ib(1333).intdate, $cluster or 
	eststo sted2_6: logit extstunted2 dietdiv $matchar $hhchar $hhag $demog female $chldchar $chealth $geog2 ib(1333).intdate, $cluster or 
	esttab sted*, se star(* 0.10 ** 0.05 *** 0.01) label ar2 pr2 beta not /*eform(0 0 1 1 1)*/ compress
	* export results to .csv
esttab sted* using "$pathout/`x'Wide2010_under24.csv", wide mlabels(none) ar2 pr2 beta label replace not