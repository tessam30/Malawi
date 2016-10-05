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
use "$pathout/hh_base_assets.dta", clear

* Create a loop to merge over all the required dataframes at household level
local flist dietdiversity food_insecurity geovars hh_demog labor shocks social_safetynets ownplot hh_dem_modC
local num2: list sizeof local(flist)
display "`num2'"

foreach x of local flist {
	
		merge 1:1 id using "$pathout/`x'_all.dta", gen(_all_`x')
	}
*end

* Create a variable for those who own some land
g byte ownLand = inlist(landowned, .) != 1
la var ownLand "binary indicating whether household owns cultivatable land"

drop hh_a23a_1-hh_a46c

order latitude longitude y2_hhid case_id year id ea_id panel_tracker
order HHID-round, after(ea_id)

* Merge in 1st wave of community information
merge m:1 ea_id using "$pathout/communnal_organisation_2011.dta", gen(_comorg2011)
merge m:1 ea_id using "$pathout/communal_organisation_2013.dta", gen(_comorg2013)

replace panel_tracker = 3 if year == 2013
la def ptrack 1 "First wave only" 2 "Second wave" 3 "First & second wave"
la val panel_tracker ptrack

compress
order _*, after(Tobacco_club_femMemb)
drop __000000 __000001

* Save in older version for compatibility
saveold "$pathout/MalawiIHS_analysis.dta", replace
export delimited "$pathexport/MalawiIHS_analysis.csv", replace
