/*-------------------------------------------------------------------------------
# Name:		Merge_Panel
# Purpose:	Merge various sectoral waves into the panel
# Author:	Tim Essam, Ph.D.
# Created:	2016/09/22
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close
log using "$pathlog/Merge_Panel.log", replace

/* data sets to be merged-in
	1) dietdiversity_all
	2) food_insecurity_all
	3) geovars_all
	4) hh_demog_all
	5) labor_all
	6) ownplot_all
	7) showks_all
	8) social_safetynets_all
	9) com_orgs_all
*/

* Start with the hh_assets_base as it has base variables

use "$pathout/hh_base_all.dta", clear

* Create a loop to merge over all the required dataframes at household level
local flist dietdiversity food_insecurity geovars hh_demog labor shocks social_safetynets ownplot hh_dem_modC
local num2: list sizeof local(flist)
display "`num2'"

foreach x of local flist {
	
		merge 1:1 id using "$pathout/`x'_all.dta", gen(_all_`x')
	}
*end
*drop __000000 __000001

* Create a variable for those who own some land
g byte ownLand = inlist(landowned, .) != 1
la var ownLand "binary indicating whether household owns cultivatable land"

drop hh_a23a_1-hh_a46c

order latitude longitude y2_hhid case_id year id ea_id panel_tracker
order HHID-round, after(ea_id)

merge 1:1 id using "$pathout/hh_base_assets.dta", gen(_hhassets)

* Merge in 1st wave of community information
merge m:1 ea_id year using "$pathout/communnal_organisation_2011.dta", gen(_comorg2011)
merge m:1 ea_id year using "$pathout/communal_organisation_2013.dta", gen(_comorg2013)
merge m:1 ea_id year using "$pathout/comm_index2011.dta", gen(_comindex2011)
merge m:1 ea_id year using "$pathout/comm_index2013.dta", gen(_comindex2013)
merge m:1 ea_id year using "$pathout/commShocks_2011.dta", gen(_com_Shocks2011)

replace panel_tracker = 3 if year == 2013
la def ptrack 1 "First wave only" 2 "Second wave" 3 "First & second wave"
la val panel_tracker ptrack

compress
order _*, after(Tobacco_club_femMemb)

drop __0*


/* ----------  NOTE: Identify the true panel households below  * ---------------- */
* Flag those observations that are a true panel -- in the sense that the household
* does not split. Based on the frequency of case_id by case_id (year) being equal to 1
bys case_id year: gen tmp2 = _N if hhPanel != 0
tab tmp year, mi
g byte tmp = (tmp2 == 1 & year == 2013)
egen ptrack = max(tmp), by(case_id)
drop tmp tmp2
tab ptrack year

la var ptrack "Panel tracking variable (true panel hhs)"
/* ----------  NOTE: ptrack identifies the pure panel households * ---------------- */

la var year "year of survey"
la var id "unique id for all data appended together"
la var dietDiv "Dietary diversity"
la var FCS "Food consumption score (WFP methodology)"
la var roomsPC "rooms per capita"
la var mobile "household owns a mobile phone"
la var lnexp "logged expenditures"
la var asphaltRoad "EA has an asphalt road"
la var dirtTrack "EA has a dirt track for road"
la var community_index_2011 "community services index"
la var community_index_2013 "community services index"

foreach x of varlist _geo - _comindex2013 {
	la var `x' "Merge tracker for `x'"
}

compress

merge 1:1 id using "$pathout/hh_base_all.dta", keepusing(ea_id) gen(_eaid_merge)

* Save in older version for compatibility
saveold "$pathout/MalawiIHS_analysis.dta", replace
saveold "$pathout/MWI_IHS_2011_13.dta", replace
export delimited "$pathexport/MalawiIHS_analysis.csv", replace

clear

/* Repeat the process with the 2016 data, ensuring that all files exist */
* First, list out all the files containing 2016 in their names (type below into prompt)
fs $pathout/*2016* $pathout/*wave3*


/* data sets to be merged-in
	1) dietdiversity_2016
	2) food_insecurity2016
	3) geovars_2016
	4) hh_demog_all
	5) labor_all
	6) land_cultivated_rainy_2016
	7) shocks_2016
	8) illness_2016
	9) hh_base_assets_2016
	10) geo_hh_roster2016
	11) commShocks_2016
	12) hh_dem_wave3
	13) hh_dem_modC_wave3
	14) hh_dem_modE_wave3
*/

* Start with the hh_assets_base as it has base variables

use "$pathout/hh_base_2016.dta", clear


* Create a loop to merge over all the required dataframes at household level
local flist dietdiversity_2016 food_insecurity2016 hh_demog_2016 illness_2016 hh_labor_2016 shocks_2016 hh_educ_2016 hh_base_Assets_2016
local num2: list sizeof local(flist)
display "`num2'"

foreach x of local flist {
	
		merge 1:1 case_id using "$pathout/`x'.dta", gen(_all_`x')
		di in yellow "`x'"
	}
 
* Add in data that are collected at the enumeration area level (Community characteristics)

merge m:1 ea_id using "$pathout/commShocks_2016.dta" , gen(_commShocks)

* Clean up some of the variables
g intDate = date(interviewDate, "YMD")

g intMonth = month(intDate)
g intYear = year(intDate)
g intDateMY = mdy(intMonth, 1, intYear )
format intDateMY intDate %td

lab val district district

compress

save "$pathout/MWI_IHS_2016.dta", replace








