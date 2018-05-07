/*-------------------------------------------------------------------------------
# Name:		102_Analysis
# Purpose:	Analyze shocks and participation in ganyu labor for 2016 data
# Author:	Tim Essam, Ph.D.
# Created:	2018/04/26
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close
log using "$pathlog/102_Analysis", replace


use "$pathout/MWI_IHS_2011_13.dta", replace

keep if year == 2011

* Survey set the data so all statistics are representative at the appropriate levels
svyset ea_id [pweight=hh_wgt], strata(district) singleunit(centered)
svydescribe

	factor shock1* if year == 2011 [aweight = hh_wgt], pcf
	scree
	predict shock_index if e(sample)

* Create national averages to calculate deviations downstream

local natave "ag conflict disaster health foodprice financial other shock_index FCS foodInsecure12Months ganyuParticipation tluTotal"
local shocklist "shock101 shock102 shock103 shock104 shock105 shock106 shock107 shock108 shock109 shock110 shock111 shock112 shock113 shock114 shock115 shock116 shock117 shock118 shock119 shock120 shock121"
local statlist `shocklist' `natave'

foreach x of local statlist {
	di `x'
	svy:mean `x' if year == 2011
	matrix smean = r(table)
	g `x'_natAve = smean[1,1]
 }
*end

preserve
	collapse (mean) *_natAve ag conflict disaster health foodprice financial other shock_index shock101-shock121 FCS foodInsecure12Months ganyuParticipation tluTotal year if year == 2011 [iw = hh_wgt], by(district)
	export delimited "$pathout/shocks_2011_district_ave.csv", replace
	save "$pathout/shocks_2011_district_ave.dta", replace
restore




* ---- 2016 Statistics --------------

use "$pathout/MWI_IHS_2016.dta", clear
	export delimited "$pathout/MWI_IHD_2016.csv", replace
	drop __*

* Survey set the data so all statistics are representative at the appropriate levels
svyset ea_id [pweight=hh_wgt], strata(district) singleunit(centered)
svydescribe

	pesort FCS district
	pesort new_disaster district

* Trying something new with the 2016 data -- TODO: run on the 2011 for comparison
* Use dimensionality reduction to extract the common variance from teh different shocks
* assuming that there is a fair amount of correlation within a household across shocks

	pwcorr ag conflict new_disaster financial health other foodprice, star(0.05)
	pwcorr ag conflict disaster financial health other  foodprice, star(0.05)


	pwcorr shock*

	factor shock101-shock121  [aweight = hh_wgt], pcf
	scree
	predict shock_index if e(sample)
	histogram shock_index, by(reside)

	factor shock1* [aweight = hh_wgt], pcf
	scree
	predict shock_index_new if e(sample)


* Create national averages to calculate deviations downstream

local natave "ag conflict disaster health foodprice financial other shock_index FCS foodInsecure12Months ganyuParticipation tluTotal"
local shocklist "shock101 shock102 shock103 shock104 shock105 shock106 shock107 shock108 shock109 shock110 shock111 shock112 shock113 shock114 shock115 shock116 shock117 shock118 shock119 shock120 shock121 shock1101 shock1102"
local statlist `shocklist' `natave'

	foreach x of local statlist {
		di `x'
		svy:mean `x' 
		matrix smean = r(table)
		g `x'_natAve = smean[1,1]
	 }
*end



* Create a heat map of shocks by district, include the shock index in the metrix as a summary column
*preserve
	include "$pathdo/copylabels.do"
	collapse (mean) *_natAve ag conflict disaster health foodprice financial other shock_index shock_index_new shock101-shock1102 FCS foodInsecure12Months ganyuParticipation tluTotal year [iw = hh_wgt], by(district)
	include "$pathdo/attachlabels.do"
	
	
	export delimited "$pathout/shocks_2016_district_ave.csv", replace
	save "$pathout/shocks_2016_district_ave.dta", replace

	append using "$pathout/shocks_2011_district_ave.dta"
	
	* Fixing regions so they will merge w/ shapefile in tableau
	decode district, gen(district_str)
	tab district_str, mi
	replace district_str = "Zomba" if district_str == "Zomba Non-City"
	replace district_str = "Nkhata Bay" if district_str == "Nkhatabay"
	
	* Create a consistent numbering for the districts that will run sequentially for creating small multiples in Tableau
	levelsof district, local(levels)
	gen district_id = .
	local i = 1

	foreach x of local levels {
		replace district_id = `i' if district == `x'
		local i = `++i'
		}
		
	clonevar district_id2 = district_id
	replace district_id2 = district_id-1 if inrange(district_id, 7, 32)
	
	la var district_id "district codes 1 - 32 for sm in tableau"
	la var district_id2 "district codes for year 2011 -- Likoma dropped"
	
	
	sort district year
	by district: gen ganyuP_lag = ganyuParticipation[_n-1]
	g ganyuParticChange = ganyuParticipation - ganyuP_lag
	la var ganyuParticChange "change in ganyu participation"
	
	save "$pathout/shocks_2011_2016_district_ave.dta", replace
	export delimited "$pathout/shocks_2011_2016_district_ave.csv", replace
	
	* Reshape the data so that it is in long format
	drop shock10* shock11* shock12*
	
	* Create shock deviations in a new variable
	foreach x of varlist ag conflict disaster health foodprice financial other {
		g dev_`x' = `x' - `x'_natAve
		ren `x' shock_`x'
		ren `x'_natAve natAve_`x'
	}
	
	egen uniqueID = group(district year)
	
	local natAvg "natAve_ag natAve_conflict natAve_disaster natAve_health natAve_foodprice natAve_financial natAve_other"
	local shocks "shock_ag shock_conflict shock_disaster shock_health shock_foodprice shock_financial shock_other"
	local devs "dev_ag dev_conflict dev_disaster dev_health dev_foodprice dev_financial dev_other"
	
	keep district* uniqueID year `natAvg' `shocks' `devs'
	
	* Need shocks stacked (long) so we can filter and manipulate in software optizimed for row wise orientation
	* Code below reshapes, stacks, and renames so visualizing in Talbeau is easy
	reshape long natAve@ dev@ shock@, i(uniqueID) j(tmp) string
	ren tmp shock_type
	replace shock_type = subinstr(shock_type, "_", "",.)
	
	
	

* ---- Shocks and TLU processing -----	
use "$pathout/MWI_IHS_2016.dta", replace

* Append in 2016 data
	drop HHID
	append using "$pathout/MalawiIHS_analysis.dta"

	* Fixing regions so they will merge w/ shapefile in tableau
	decode district, gen(district_str)
	tab district_str, mi
	replace district_str = "Zomba" if district_str == "Zomba Non-City"
	replace district_str = "Nkhata Bay" if district_str == "Nkhatabay"
	
* Create a total shock variable the captures how many of the major shocks a household reported
	egen total_shock_categ = rsum(ag conflict disaster financial health other foodprice)
	egen total_shock_categ_2016 = rsum(ag conflict new_disaster financial health other foodprice) if year == 2016
	la var total_shock_categ "Total shocks summarized across categories (max 7 possible)"
	la var total_shock_categ_2016 "Total shocks summarized across categories (max 7 possible)"
		
* Check the TLU settingd to ensure that we have consistency in variable acros time
	gen byte livestock =  inlist(ownLivestock, 1)
	clonevar tlus = tluTotal
	replace tlus = 0 if tluTotal == .

	clonevar tlus_censored = tluTotal
	replace tlus_censored = . if tluTotal ==0
	
	la var livestock "does household own any livestock?"
	la var tlus "total TLUs including households w/ 0 or missing livestock"
	la var tlus_censored "total TLUs excluding households w/ 0 or missing livestock"
	
* Fix mobile binary so it applies to all years
	replace mobile = ownsMobile if year == 2016
	
	
* Export a cut of shock data to WVU for kriging
	preserve 
	keep if inlist(year, 2016, 2011)
	local shocklist "ag conflict disaster new_disaster financial health other foodprice total_shock_categ tot_shocks anyShock livestock FCS"
	local geo "latitude longitude ea_id district case_id reside year"
	keep `geo' `shocklist'
	sum
	
	forvalues i = 2011(5)2016 {
		export delimited "$pathexport/mwi_shocks_`i'_geo.csv" if year == `i', replace
		}
	restore
	

	
********************************************************************************
* Livestock *
********************************************************************************	
* Export a cut of livestock data for exploration in Tableau -- want cut at district level
	
	
forvalues i = 2011(5)2016 {
		preserve
		capture drop __*
		keep if year == `i' 
		svyset ea_id [pweight=hh_wgt], strata(district) singleunit(centered) 
		
		local statlist "tlucattle tlusheep tluhorses tluchx tlupig tluTotal"
		
			foreach x of local statlist {
			di `x'
			svy:mean `x' if year == `i' & livestock == 1
			matrix smean = r(table)
			g natAve_`x' = smean[1,1]
			la var natAve_`x' "national average of `x' for livestock owners"
		 }

		include "$pathdo/copylabels.do"
		collapse (mean) `statlist' (max) natAve_tlu* if year == `i' & livestock == 1 [iw = hh_wgt], by(district)
		include "$pathdo/attachlabels.do"
		
		* Create deviation variables
		foreach x of local statlist {
			g dev_`x' = `x' - natAve_`x'
			la var dev_`x' "`x' deviation from national average for"
		}
		
		g year = `i'
		
			if 	`i' == 2016 {
			
				* On the 2nd pass w/ 2016 data do the reshaping, renaming and restructuring in one pass
				append using "$pathout/mwi_tlu_district_2011.dta"
				
				egen id = group(district year)
				
				foreach x of local statlist {
					rename `x' _`x'
					}
				
				reshape long _@ natAve_@ dev_@, i(id) j(categ) string
				rename (_ natAve_ dev_)(livestock natAve deviation)
				
				replace categ = subinstr(categ, "tlu", "",.)
				
					decode district, gen(district_str)
					tab district_str, mi
					replace district_str = "Zomba" if district_str == "Zomba Non-City"
					replace district_str = "Nkhata Bay" if district_str == "Nkhatabay"
	
					la var livestock "tlu average for livestock category"
					la var natAve "national average"
					la var deviation "deviation from national average for district"
					la var year "year of survey"
				
				* Incorporate FFP filter variables
					gen ffp_focue = inlist(district, 312, 305, 310, 302, 301, 313, 311, 309)
				
				
				save "$pathout/mwi_tlu_district_2011_2016.dta", replace
				export delimited "$pathout/mwi_tlu_district_2011_2016.csv", replace
				}
				
			else save "$pathout/mwi_tlu_district_`i'.dta", replace
		
		restore
	}
			

* Food insecurity history by district and correlation w/ interview date?
	
forvalues i = 2011(5)2016 {
		preserve
			capture drop __*
			
			svyset ea_id [pweight=hh_wgt], strata(district) singleunit(centered)
			* Drop implausible values
			drop if totMoFoodInsec == 25

			local statlist "foodInsecure7Days inferiorFood limitPortion reduceMeals restrictCons borrowFood foodInsecure12Months totMoFoodInsec"

				foreach x of local statlist {
					di `x'
					svy:mean `x' if year == `i' 
					matrix smean = r(table)
					g natAve_`x' = smean[1,1]
					la var natAve_`x' "national average of `x'"
				 }

			include "$pathdo/copylabels.do"
			collapse (mean) `statlist' (max) natAve_* if year == `i' [iw = hh_wgt], by(district)
			include "$pathdo/attachlabels.do" 
				 
			gen year = `i'
			
			if year == 2016 {
						append using "$pathout/mwi_foodinsec_2011.dta"
						
						egen id = group(district year)
						
						decode district, gen(district_str)
						tab district_str, mi
						replace district_str = "Zomba" if district_str == "Zomba Non-City"
						replace district_str = "Nkhata Bay" if district_str == "Nkhatabay"
						
						* Incorporate FFP filter variables
						gen ffp_focus = inlist(district, 312, 305, 310, 302, 301, 313, 311, 309)
					
						* Calculate the change in key variables from year to year
						sort district year
						foreach x of varlist `statlist' {
							by district: g `x'lag = `x'[_n-1] 
							g `x'_diff = `x' - `x'lag
							drop `x'lag
							}
					
						save "$pathout/mwi_foodinsec_district_2011_2016.dta", replace
						export delimited "$pathout/mwi_foodinsec_district_2011_2016.csv", replace
					}
			
			else save "$pathout/mwi_foodinsec_2011.dta", replace
		
		restore
		
	}
	
	
	
	
	
	
	
	
	
* Ganyu labor summary cut	
	
	
	
	

	
* ---- Food Consumption Score Processing -----
* This is fed into R script to generate the FCS heatmap, density plots and tic tac chart
* Likoma does not appear in the 2010 wave (it's grouped) so starte w/ 2016 to keep the level around
use "$pathout/MWI_IHS_2016.dta", replace

* Append in 2016 data
drop HHID
append using "$pathout/MWI_IHS_2011_13.dta"

*svyset ea_id [pweight=hh_wgt], strata(district) singleunit(centered)


rename (staple_days legumes_days fats_days) (staples_days pulse_days oil_days)
clonevar region_var = district

	* Fixing regions so they will merge w/ shapefile in tableau
	decode district, gen(district_str)
	tab district_str, mi
	replace district_str = "Zomba" if district_str == "Zomba Non-City"
	replace district_str = "Nkhata Bay" if district_str == "Nkhatabay"
	



local foodDays "staples_days pulse_days meat_days milk_days veg_days oil_days fruit_days sugar_days"
keep region_var year hh_wgt strata ea_id `foodDays' FCS

drop if inlist(., oil_days, sugar_days, pulse_days, veg_days, staples_days, FCS)
decode region_var, gen(region_var_string)

save "$pathout/FCS_plots.dta", replace
	
	
* Calculate office FCS scores and variables for 2011 and 2016 data

foreach x of local foodDays {
		g `x'_dist = .
	
	
	
	
	
restore


