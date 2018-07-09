/*-------------------------------------------------------------------------------
# Name:		01_hhassets_2015
# Purpose:	recode and rename household assets for use in stunting analysis
# Author:	Tim Essam, Ph.D.
# Created:	2018/07/09
# Owner:	USAID GeoCenter 
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close
log using "$pathlog/01_hhassets", replace

*******************************************
* Add in data about male occupation in hh *
*******************************************
use "$pathmen/MWMR7HFL.DTA", clear

* Remove visitors from household to not convolute occupations
	drop if mv135 == 2

* Check how many unique household there are: 4,660
	egen tag = tag( mv001 mv002)
	tab tag, mi

* Create a variable for head of household's occupation
* Note: not all household will have male head
	bys mv001 mv002: g occupationM = mv717 if mv150 == 1

	bys mv001 mv002: g headLit = mv155 if mv150 == 1
	recode headLit (3 4 = 1)
	lab val headLit MV155

	la var occupation "Occupation of male head"
	la var headLit "Literacy status of male head"

	include "$pathdo/copylabels.do"
	collapse (max) occupationM headLit, by(mv001 mv002)
	include "$pathdo/attachlabels.do"

	lab val headLit MV155
	lab val occupationM MV717

	ren (mv001 mv002)(v001 v002)
	isid v001 v002
save "$DHSout/hh_occupM.dta", replace
clear


*********************************************
* Add in data about female occupation in hh *
*********************************************
use "$pathwomen/MWIR7HFL.DTA", clear
	
	* Check how many unique households there are for women
	egen tag = tag(v001 v002) 
	tab tag, mi 

	bys v001 v002: g occupationF = v717 if v150 == 1
	recode v467d (1 = 1 "big problem")(2 = 0 "not a big problem"), gen(distHC)
	
	include "$pathdo/copylabels.do"
	collapse (max) occupationF distHC, by(v001 v002)
	include "$pathdo/attachlabels.do"

	lab val occupationF V717

save "$DHSout/hh_occupF.dta", replace

***********************************************
* Adding in personal records for demographics *
***********************************************
use "$pathroster/MWPR7HFL.DTA", clear

* Household composition of women; Is it an older or younger household?
* Note: These need to be summed when collapsing to the household level
	g byte numWomen15_25 = inrange(hv105, 16, 25) if hv104 == 2 & hv102 == 1
	g byte numWomen26_65 = inrange(hv105, 26, 65) if hv104 == 2 & hv102 == 1

	clonevar hhsize = hv012
	clonevar numChildUnd5 = hv014

	clonevar maleEduc 	= hb68
	clonevar femaleEduc = ha68 
	clonevar motherEduc = hc68


include "$pathdo/copylabels.do"
	collapse (max) hhsize numChildUnd5 maleEduc femaleEduc /*
	*/ motherEduc (sum) numWomen15_25 numWomen26_65, by(hv001 hv002)
include "$pathdo/attachlabels.do"

	ren (hv001 hv002)(v001 v002)
	isid v001 v002

merge 1:1 v001 v002 using "$DHSout/hh_occupF.dta", gen(_occupF)
merge 1:1 v001 v002 using "$DHSout/hh_occupM.dta", gen(_occupM)

	clonevar occupation = occupationM
	replace occupation = occupationF if occupation == . & occupationM == .
	la var occupation "occupation of head of household (male/female)"

save "$DHSout/hhdemog.dta", replace

********************
* Household info *
use "$pathhh/MWHR7HFL.DTA", clear

	clonevar v001 = hv001
	clonevar v002 = hv002
	isid v001 v002	


****** NOTE : a better solution is to simply rename the merging variables ******

* clean up sampling information
	clonevar cluster 	= hv001
	clonevar hhnum 		= hv002
	clonevar monthint 	= hv006
	clonevar yearint	= hv007
	clonevar intdate	= hv008
	clonevar psu		= hv021
	clonevar strata		= hv022
	clonevar province	= hv024
	clonevar altitude	= hv040
	clonevar district 	= shdist

	g hhweight = hv005 / 1000000
	g maleweight = hv028/1000000

* Syntax for setting weights *
* svyset psu [pw = hhweight], strata(strata)
	la var hhweight "household weight"
	la var maleweight "male weight"

* Fix value labels on rural
	recode hv025 (1 = 0 "urban")(2 = 1 "rural"), gen(rural)

* HH size and demographics
	clonevar hhsize = hv009
	clonevar hhchildUnd5 = hv014

* HH assets
	clonevar toilet = hv205
	clonevar toiletShare = hv225
	g byte handwashObs = inlist(hv230a, 1)
	la var handwashObs "Observed handwashing station"
	rename (hv206 hv207 hv208 hv209 hv210 hv211 hv212 hv243a)(electricity radio tv refrig bike moto car mobile)

	recode hv213 (11 12 = 1 "earth, sand, dung")(33 34 35 96 = 0 "ceramic or better"), gen(dirtfloor)
	clonevar hhrooms = hv216
	g roomPC = hhrooms / hhsize
	la var roomPC "rooms per hh size"

	recode hv219 (1 = 0 "male")(2 = 1 "female"), gen(femhead)
	clonevar agehead = hv220
	replace agehead = . if agehead == 98

	recode hv230a (2 3 4 = 0 "unobserved") (1 = 1 "observed"), gen(handwash)
	recode hv237 (8 = .)(0 = 0 "no")(1 = 1 "yes"), gen(treatwater)

	recode hv242 (0 = 0 "no")(1 = 1 "yes")(. = .), gen(kitchen)
	clonevar bednet = hv227 

	g byte bnetITNuse = inlist(hml12_01, 1) & bednet == 1
	la var bnetITNuse "own ITN mosquito bednet"

* Wash variables (http://www.wssinfo.org/definitions-methods/watsan-categories/)
/* IMPROVED WATER
	Piped water into dwelling - 10, 11
	Piped water to yard/plot - 12
	Public tap or standpipe - 13
	Tubewell or borehole - 20, 21
	Protected dug well - 30, 31
	Protected spring - 41
	Rainwater - 51
*/
g byte improvedWater = inlist(hv201, 10, 11, 12, 13, 20, 21, 30, 31, 41, 51)

/* UNIMPROVED WATER
	Unprotected spring - 42
	Unprotected dug well - 32
	Cart with small tank/drum - 62
	Tanker-truck - 61
	Surface water - 43
	Bottled water - 71
*/
g byte unimprovedWater = inlist(hv201, 32, 42, 43, 61, 62, 71) 
g byte waterLake = inlist(hv201, 43)

/* IMPROVED SANITATION & not shared [ & (hv225 == 0)]
	Flush toilet - 10
	Piped sewer system - 11
	Septic tank - 12
	Flush/pour flush to pit latrine - 13
	Ventilated improved pit latrine (VIP) - 21
	Pit latrine with slab - 20
	Composting toilet - 41
	Special case 
	*/
g byte improvedSanit = inlist(hv205, 10, 11, 12, 13, 20, 21, 41, 22) & hv225 == 0

/* UNIMPROVED SANITATION  
	Flush/pour flush to elsewhere - 14, 15
	Pit latrine without slab - 23
	Bucket - 42
	Hanging toilet or hanging latrine - 43
	Shared sanitation - 
	No facilities or bush or field - 30, 31, 96
	*/

g byte unimprovedSanit = inlist(hv205, 14, 15, 23, 30, 31, 42, 43, 96)  | hv225 == 1
	
**********************************************
* HH Landholding for agricultural production *
**********************************************
	recode hv244 (1 = 0 "owns ag land")(0 = 1 "landless"), gen(landless)

	clonevar landowned = hv245
	replace landowned = . if landowned == 998
	replace landowned = (landowned / 10)

	histogram landowned

	clonevar livestock = hv246

/*Create TLU (based on values from http://www.lrrd.org/lrrd18/8/chil18117.htm)
Notes: Sheep includes sheep and goats
Horse includes all draught animals (donkey, horse, bullock)
chxTLU includes all small animals (chicken, fowl, etc).*/
	g camelVal 	= 0.70
	g cattleVal = 0.50
	g pigVal 	= 0.20
	g sheepVal 	= 0.10
	g horsesVal = 0.50
	g mulesVal 	= 0.60
	g assesVal 	= 0.30
	g chxVal 	= 0.01

* Decode unknown values to be missing not zero (affects few obs) and strip labels
	
	sum hv246*
	mvdecode hv246a hv246c hv246d hv246e hv246f hv246g hv246h hv246b, mv(98)
	_strip_labels hv246a-hv246j


* Check the TLU variables as they seem to change from country to country and year to year
   d hv246*
 */
   
	rename (hv246a hv246b hv246c hv246d hv246e hv246f hv246g hv246h)/*
		  */ (cowtrad cowbull horse goat sheep chicken pig poultry) 
	*summarize results to check min / max
	sum cowtrad-poultry
			
	g tlucattle = (cowtrad + cowbull) * cattleVal	  
	g tlusheep 	= (sheep + goat) * sheepVal
	g tluhorses = (horse) * horsesVal
	g tlupig 	= (pig) * pigVal
	g tluchx 	= (poultry + chicken) * chxVal

	* Generate overall tlus
	egen tlutotal = rsum(tlucattle tlusheep tluhorses tlupig tluchx)
	la var tlutotal "Total tropical livestock units"

	sum tlutotal
	histogram tlutotal if livestock ==1 & tlutotal < 10

	* Wealth
	clonevar wealthGroup = hv270
	clonevar wealth = hv271
	replace wealth = (wealth / 100000)

	* Bank account?
	clonevar bankAcount = hv247

	* Smoker in house?
	recode hv252 (0 = 0 "no smoker") (1 2 3 4 = 1 "smoker in house"), gen(smoker)

	* Drop extra variables no longer needed
	drop *Val

	#delimit ;
	ds(ha0* ha1* ha2* ha3* ha4* ha5* ha6* ha7* hb* hc* 
		hmhid* hml* hv* hvidx* sh1* sh2* sh3* sh4* idxh*)
		, not;
	keep `r(varlist)';
	#delimit cr

	* drop extra data
	aorder


	* Check for value labels and clean up ones that do not make sense
	local labCheck agehead bankAcount bednet bike car dirtfloor /*
			*/ district electricity femhead handwash landless /*
			*/  landowned livestock mobile moto province radio /*
			*/ refrig rural smoker strata toilet toiletShare /*
			*/ treatwater tv

	* Most everything looks ok, not sure we need value labels but will leave for now
	set more off
	foreach x of local labCheck {
		tab `x', mi nol
		
		* Adding a toggle if you need to slow down loop
		*more
		}
	*

	_strip_labels agehead

* Summary stats to check if you can match DHS report
* Matching stats on pp. 24 of report httpssmok://www.dhsprogram.com/pubs/pdf/FR316/FR316.pdf
	svyset psu [pw = hhweight], strata(strata)

	svy: mean radio, over(rural)
	svy: mean livestock, over(rural)

* Sort and create coef plot of district values
	svy: mean landless, over(district)
	matrix plot = r(table)'
	matsort plot 1 "down"
	matrix plot = plot'
	coefplot (matrix(plot[1,])), ci((plot[5,] plot[6,]))

* Captilize value label list so that it seemlessly merges into ArcGIS shapefile
	local varname district
	local sLabelName: value label `varname'
	di "`sLabelName'"

	levelsof `varname', local(xValues)
	foreach x of local xValues {
		local sLabel: label (`varname') `x', strict
		local sLabelNew =proper("`sLabel'")
		noi di "`x': `sLabel' ==> `sLabelNew'"
		label define `sLabelName' `x' "`sLabelNew'", modify
	}
	*end

merge 1:1 v001 v002 using "$DHSout/hhdemog.dta", gen(_demog)
clonevar dhsclust = v001 
compress
saveold "$pathout/DHS_hhvar.dta", replace
log close

