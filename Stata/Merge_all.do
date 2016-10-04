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
local flist dietdiversity food_insecurity geovars hh_demog labor shocks social_safetynets ownplot 
local num2: list sizeof local(flist)
display "`num2'"

foreach x of local flist {
	
		merge 1:1 id using "$pathout/`x'_all.dta", gen(_all_`x')
	}
*end

* Create a variable for those who own some land
g byte ownLand = inlist(landowned, .) != 1
la var ownLand "binary indicating whether household owns cultivatable land"

order y2_hhid case_id year id ea_id
order HHID-round, after(ea_id)
































* Download the derived panel data set from the LSMS website. They have created a subset of data that tracks the panel
* household across the two years. Using this base data we will create a panel tracking variable so we can use the full
* sample from 2011 where desirable, but also have the option of only looking at the panel over time.

* First, load the full sample from 2011 to create a base.
use "$wave1/ihs3_summary.dta", clear

* Now merge in the subsample panel and create a flag for tracking the observations.
merge 1:1  case_id using "$wave1/ConsumptionAggregate_panel.dta", gen(panel_household)
recode panel_household (1 = 0 "2011 Sample only")(3 = 1 "Panel household")(2 = 2 "Break-off household"), gen(ptrack)
g flag = 1 if ptrack == 1
g year = 2011

* Now we can append in the 2013 data set and get the panel as well as split off households
* Using the force option b/c the panel variable is string in master but byte in using
append using "$wave2/ConsumptionAggregate2013.dta", force
replace year = 2013 if year == .

* Now, create a few variables to track the sample of panel households.
* So documentation of the panel is a bit convoluted based on the original survey documents.
* http://siteresources.worldbank.org/INTLSMS/Resources/3358986-1233781970982/5800988-1271185595871/6964312-1404828635943/IHPS_BID_FINAL.pdf
* According to the ConsumptionAggregate_panel there should be 3,246 in the panel. But it is unclear how to track these households because
* there are 2,729 "original" households captured by the hh_a05 variable. Not worth tracking the panel at this point and am not really sure 
* the time is worth the cost given the binding time constraints.

bys HHID: gen hhidtmp = _N
la var hhidtmp "household ID count based on IHS3 baseline serial"
bys case_id: gen idtmp = _N


order hhidtmp idtmp ptrack case_id y2_hhid round HHID panel year 
sort case_id year y2_hhid 

clist case_id y2_hhid hhidtmp ptrack year if inrange(hhidtmp, 3, 4), noo

merge m:1 y2_hhid using "$wave2\HH_MOD_A_FILT.dta", keepusing(hh_a05 y2_hhid)

order panel_household flag hhweightR1 interview_status hh_a05, after( qx_type)
order rexp_cat011- rexp_cat12, after( pcrexp_cat123)
order case_id y2_hhid year hh_a05 hhidtmp idtmp year

* Create the id variable used to link the panel datasets
clonevar id = case_id
replace id = y2_hhid if id == "" & year == 2013
isid id































































