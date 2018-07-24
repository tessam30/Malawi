/*-------------------------------------------------------------------------------
# Name:		103_Food_For_Peace_proriority_zone_focus_analysis
# Purpose:	Analyze shocks and participation in ganyu labor for 2016 data
# Author:	Tim Essam, Ph.D.
# Created:	2018/06/21
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close

*  First, need to import the text files created in ArcMap to attach the spatial info of select households with rest
*  case_id is a string in the original data, so due to ArcMap coercion to a numeric, we create a new variable on which
*  we will later using as a merging variable

	import delimited "$pathout/MWI_2011_IHS_livelihood_FFP_attributes.txt", clear
	save "$pathout/MWI_2011_IHS_livelihood_FFP_attributes.dta", replace

	import delimited "$pathout/MWI_2016_IHS_livelihood_FFP_attributes.txt", clear
	append using "$pathout/MWI_2011_IHS_livelihood_FFP_attributes.dta", force
	
	tostring case_id, gen(case_id_str) format("%15.0f") 
	
	#delimit ;
		keep fid target_fid case_id case_id_str fid_mwi_ff fid_mwi_ff no_ area_km2 
		fid_mw_lhz fnid eff_year country lznum lzcode lznameen lznamefr 
		lznamesp lznamept class shape_leng shape_area year;
	#delimit cr
		
	
	save "$pathout/MWI_IHS_livelihood_FFP_attributes", replace

* Load analysis data and merge in livelihood information
	use "$pathout/mwi_analysis_2011_2016.dta", clear
    clonevar case_id_str = case_id
	
	merge 1:1 case_id_str year using "$pathout/MWI_IHS_livelihood_FFP_attributes.dta", gen(ffp_flag) force
	g byte ffp_priority = inlist(ffp_flag, 3) == 1
	
	* Change the the households that mapped into the national park as mapping in 
	replace lznameen = "Lake Chilwa - Phalombe Plain" if lznameen == "National Park"

	* Merge wealth indices from the years into a single column
	g wealth_index = .
	replace wealth_index = wealth_2016 if year == 2016
	replace wealth_index = wealth_2011 if year == 2011
	
	
* Data are merged; Now run the summary statistics over the areas across time. Assuming a simple random sample.
	encode lznameen, gen(livelihood_zone)
	mean FCS ag foodprice disaster foodInsecure7Days new_disaster foodInsecure12Months, over(ffp_priority year)
	mean FCS ag foodprice disaster foodInsecure7Days foodInsecure12Months, over(livelihood_zone year)
	
	mean livestock educHoh wealth_index ganyuParticipation, over(ffp_priority year)
	
* TODO: extract the estimates and plot them in a ggplot showing how much overlap there is in confidence intervals


	

/* Food Insecurity Analysis 
	Goal: Look at different dimensions of food security on a national scale, but also at the FFP scale
	Trying to triangulate the correlations across dimensions including: FCS, 7 day food insec, 12 month food insec, and food price shocks
	
	Key factors identified by the activity design tea:
		shocks
		infrastructure
		environment
		education
		land holdings
		ag assets
		income generation opportunities
		demographics
		access to markets/inputs etc
		
	Analytical approach: Pooled approach, year-by-year, sub-region analysis -- compare coefficients	
		
		*/
		
	* First, create summary statistics for the key control covariates
	
	* Fix the interview dates, need to account for when in the year the household was surveyed
	g intDate2011 = mdy(intmonth, 1, intyear)
	format intDate2011 %td
	replace intDateMY = intDate2011 if year == 2011
	
	* lump thin categories
	replace intDateMY = 20910 if intDateMY == 20940
	
	* Vulnerable household heads
	g byte vulnHead = (agehead<18 | agehead >59) & !missing(agehead)
	la var vulnHead "Hoh is younger than 18 or older than 60"
	
	* Appears the 2016 cultivated land was not included in roll-up, add it in
	merge 1:1 case_id year using "$pathout/land_cultivated_rainy_2016.dta", gen(land_2016)
		
		gen landHoldings = landownedRainy if year == 2011
		replace landHoldings = landCultivatedRainy if year == 2016
		
		* Calculate land quartiles after winsorizing landowned
		winsor landHoldings, gen(landHoldings_cnsrd) p(0.001) highonly
		replace landHoldings_cnsrd = 0 if landHoldings == .

		xtile landQtile = landHoldings_cnsrd, nq(4)
		g byte landOwned = landHoldings_cnsrd > 0
		la var landOwned "household owns any land for cultivation"
	
	* Fix all the indices so they can be applied in a pooled regression
	local indices "ag_index durables_index infra_index"
	foreach x of local indices {
	
		g `x' 		= `x'_2011 if year == 2011
		replace `x' = `x'_2016 if year == 2016
	
	}

	* Own livestock variable and TLUS are wrong b/c they are censored for 2016
	* ISSUE: how to classify those urban household that do not own livestock and are given a "." value
	replace tluTotal = 0 if tluTotal == . & year == 2016
	replace tluTotal = 0 if tluTotal == . & year == 2011
	drop ownLivestock
	g byte ownLivestock = (tluTotal > 0) & !missing(tluTotal)

	
	* generate a squared term for education
	g educAdultsq = educAdult^2
	la var educAdultsq "highest adult education squared"
	
	g byte ironRoof = inlist(roof, 2, 3, 4) == 1
	g byte rural = inlist(reside, 2)
	
	la var rural "rural household"
	la var ironRoof "household owns iron roof"
	la var ownLivestock "household owns some type of livestock"
	la var ag_index "agricultural index from ag assets"
	la var durables_index "durables index from durable goods"
	la var infra_index "infrastructure index"
	la var wealth_index "wealth index from all assets"
	
	
	

	compress
	
	save "$pathout/mwi_analysis_2011_2016_food_for_peace.dta", replace

	* Run summary statistics on ffp focus versus non-focus zones: how is the targeting?
	mean FCS foodInsecure12Months foodInsecure7Days ag foodprice disaster health wealth_index tluTotal, over(ffp_priority year)
	/* FFP priority areas have:
			lower FCS -- both years
			more 12 month food insecurity
			similar 7 day food insecurity
			fewer ag shocks
			fewer food price shocks
	        more disaster shocks -- espcially irregular rains
			MUCH less wealth overall and similar TLU holdings */
			
	* Same stats over livelihood zones within selected districts
	mean FCS foodInsecure12Months foodInsecure7Days ag foodprice disaster health wealth_index tluTotal, over(year livelihood_zone)
	
	
	* Create a set of globals to use in regressions
	global demog "agehead c.agehead#c.agehead i.femhead i.ganyuFemhead i.marriedHoh vulnHead"
	global educ "litHeadChich litHeadEng educAdult educAdultsq gendMix depRatio under15 mlabor flabor hhmignet "
	global shocks "ag foodprice disaster"
	global ironroof "ironRoof mobile ownLivestock ib(4).landQtile"
	global assets "tluTotal ownLivestock ag_index durables_index infra_index ib(4).landQtile"
	global assets2 "tluTotal ownLivestock wealth_index ib(4).landQtile"
	global community "dist_admarc  dist_popcenter dist_road fsrad3_agpct"
	global geog " ib(3).region i.rural"
	global geog2 "ib(206).district"
	global geog3 "ib(2).livelihood_zone"
	global year "ib(2016).year"
	* Check the date 
	di %td 18567
	*global survey "ib(18567).intDateMY" 
	global survey "ib(2011).year"
	global seopts "cluster(ea_id)"
	global ffp "if ffp_priority == 1 & year == 2016"
	global ffp2 "if ffp_priority == 1"


	sum $demog $hhlabor $educ $assets $assets2 $community
	
	* Test a linear model with an incremental build across a pooled sample
	est clear
	
		global depvar "FCS"
		local estname "FCS_OLS"
		local year = 201116
	
	* ensure that estout is installed: ssc install estout
		eststo `estname'_`year'_1: reg $depvar $demog $educ $ironroof $survey, $seopts
		eststo `estname'_`year'_2: reg $depvar $demog $educ $shocks $ironroof $survey, $seopts
		eststo `estname'_`year'_3: reg $depvar $demog $educ $shocks $ironroof $assets $survey, $seopts
		eststo `estname'_`year'_4: reg $depvar $demog $educ $shocks $assets2 $community $geog $survey, $seopts
		eststo `estname'_`year'_5: reg $depvar $demog $educ $shocks $assets2 $community $geog2 $survey, $seopts
		
	* Use the esttab to combine all the results and all you to scan them across for what is really important
	* the beta options stanardizes the coeficents so you can compare across all covariates equally.
		est dir
		esttab FCS_OLS*, star( ** 0.05 *** 0.01) beta ar2 /*drop(*intDateMY*)*/ mtitles("base" "base 2" "base 3" "region fe" "district fe")
	
	* To write the results to a .csv use the snippet below, modifying only the estimates you want written (beta option not used!)
	*esttab FCS* using "$pathreg/mwi_fcs_pooled.csv", star(+ 0.10 ++ 0.05 +++ 0.01) label not replace
	
		
	* Now a model for each livelihood zone -- getting smaller and smaller sample sizes

		eststo lvd_all: reg $depvar $demog $educ $shocks $ironroof  $community $survey ib(2).livelihood_zone, robust 
	
		levelsof livelihood_zone, local(levels)
		local i = 1
		
		* Loop over each livelihood zone, run a regression and store the results in a distinct name
		foreach x of local levels {	
		
			eststo lvd_`x'`i': reg $depvar $demog $educ $shocks $ironroof $community $survey if livelihood_zone == `x', robust
			local i = `i++'
			}
		
		* Preview the results
		esttab lvd*, beta  mtitles("FFP Focus" "Phalombe" "Shire Valley" "Phirilongwe" "Shire Hland")


	* Call the 
	
* Call the markstat file that will produce the the HTML document with results
	markstat using "$pathdo/103_FFP_FCS_results_brent.stmd", strict
		
