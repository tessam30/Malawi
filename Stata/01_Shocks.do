/*-------------------------------------------------------------------------------
# Name:		01_Shocks
# Purpose:	Process shock modules for upcoming trip to Mission
# Author:	Tim Essam, Ph.D.
# Created:	2016/04/27
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close 
log using "$pathlog/01_shocks.txt", replace

use "$wave1/HH_MOD_A_FILT.dta", clear
merge 1:1 case_id using"$wave1/HouseholdGeovariables.dta", gen(hh_rost_geo)
save "$pathout/geo_hh_roster1.dta", replace
clear

* Load shock module to process
use "$wave1/HH_MOD_U.dta", clear

* Excecute program to create macros with lists of numbers
include "$pathdo/cnumlist.do"

* Tabulate top two shocks for creating shock variables
tab hh_u0a if inlist(hh_u02, 1, 2)

* Flag observations with a shock
g byte rptShock = hh_u01 == 1

tab hh_u0a hh_u02 if rptShock == 1, mi
la var rptShock "Household reported a shock"

* Create lowercase labels for the graphs
clonevar shock_code = hh_u0a

clonevar shock_sev = hh_u02
la def severity 1 "Most severe" 2 "2nd most severe" 3 "3rd most severe"
la val shock_sev severity 

label list HH_U0A

* Create new label set
lab def shockN 101 "drought" 102 "floods" 103 "earthquakes" 104 "crop pest/disease" /*
*/ 105 "livstock disease" 106 "low ag output price" 107 "high ag input prices" 108 "high food price" /*
*/ 109 "remittances/aid ends" 110 "non-ag earnings fall" 111 "non-ag biz failure" 112 "salary reduced" /*
*/ 113 "unemployed" 114 "illness/injury" 115 "birth in hh" 116 "death of income earner" /*
*/ 117 "other death" 118 "hh break-up" 119 "theft all forms" 120 "conflict/violence" 121 "other" 
la val shock_code shockN

/*ag    = other crop damage; input price increase; death of livestock
* conflit   = theft/robbery/violence
* disaster  = drought, flood, heavy rains, landslides, fire
* financial = loss of non-farm job
* foodprice = price rise of food item
* pricedown = price fall of food items
* health  = death of hh member; illness of hh member
* other   = loss of house; displacement; other */ 

cnumlist "101 102 103"
local disaster `r(numlist)'
cnumlist "104 105 106 107"
local ag `r(numlist)'
cnumlist "109 110 111 112 113"
local fin `r(numlist)'
cnumlist "114 115 116 117"
local health `r(numlist)'

* Create scalars to set the range of severity that will be considered for flagging shocks
scalar s_min = 1
scalar s_max = 2

* Create standard categories for shocks using WB methods
g byte ag     = inlist(hh_u0a, `ag') & rptShock /*& inrange(shock_sev, s_min, s_max)*/
g byte conflict = inlist(hh_u0a, 119, 120) & rptShock /*& inrange(shock_sev, s_min, s_max)*/
g byte disaster = inlist(hh_u0a, `disaster') & rptShock /*& inrange(shock_sev, s_min, s_max)*/
g byte financial= inlist(hh_u0a, `fin') & rptShock /*& inrange(shock_sev, s_min, s_max)*/
g byte health   = inlist(hh_u0a, `health') & rptShock /*& inrange(shock_sev, s_min, s_max)*/
g byte other  = inlist(hh_u0a, 118, 121) & rptShock /*& inrange(shock_sev, s_min, s_max)*/
g byte foodprice= inlist(hh_u0a, 108) & rptShock /*& inrange(shock_sev, s_min, s_max)*/

* Create a long variable that would identify groups of shocks, strictly for plotting
g shock_type = .
local slist "ag conflict disaster financial health other foodprice"
local i = 0
foreach x of local slist {
    replace shock_type = `i' if `x' == 1
    local i = `++i'
}
la def shocka 0 "Agricultural" 1 "Conflict" 2 "Disaster" 3 "Financial" /*
*/ 4 "Health" 5 "Other" 6 "Food Prices"
la val shock_type shocka
tabsort shock_type shock_sev, mi

* Create bar graph of shocks ranked by severity
graph hbar (count) if rptShock == 1, /*
*/ over(shock_code, sort(1) descending label(labsize(vsmall))) /*
*/ blabel(bar) scheme(s2mono) scale(.80) /*
*/ by(shock_sev, missing cols(2) iscale(*.80) /*
*/ title(High food and agricultural input prices are the most common and the most severe shocks/*
*/, size(small) color("100 100 100"))) 
graph export "$pathgraph\Shocks2011.pdf", as(pdf) replace

* Create bar graph of shocks ranked by severity
graph hbar (count) if rptShock == 1, /*
*/ over(shock_type, sort(1) descending label(labsize(vsmall))) /*
*/ blabel(bar) scheme(s2mono) scale(.8) /*
*/ by(shock_sev, missing cols(2) iscale(*.8) title(Food price /*
*/ and agricultural shocks are the most common and most severe shock categories/*
*/, size(small) color("100 100 100")))
graph export "$pathgraph\Shock_categories2011.pdf", as(pdf) replace

merge m:m case_id using "$pathout/geo_hh_roster1.dta"

graph hbar (count) if rptShock == 1, /*
*/ over(shock_type, sort(1) descending label(labsize(vsmall))) /*
*/ blabel(bar) scheme(s2mono) scale(.8) /*
*/ by(shock_sev reside, missing cols(3) iscale(*.8) title(Food price /*
*/ and agricultural-based shocks are the most common and severe shock categories/*
*/, size(small) color("100 100 100")))
graph export "$pathgraph\Shock_categories_rural2011.pdf", as(pdf) replace

* Total shocks reported by hh
egen tot_shocks = total(rptShock), by(case_id)

* Label shocks
la var ag "Agricultural shock (any severity)"
la var conflict "Conflict shock (any severity)"
la var disaster "Disaster shock (any severity)"
la var financial "Financial shock (any severity)"
la var health "Health shock (any severity)"
la var other "Other shock (any severity)"
la var foodprice "Price rise shock (any severity)"
la var shock_type "type of shock shock (any severity)"

* Incorporate coping strategy informationuse per Brent's request
/* Coping Mechanisms - What are good v. bad coping strategies? From (Heltberg et al., 2013)
  http://siteresources.worldbank.org/EXTNWDR2013/Resources/8258024-1352909193861/
  8936935-1356011448215/8986901-1380568255405/WDR15_bp_What_are_the_Sources_of_Risk_Oviedo.pdf
  Good Coping: use of savings, credit, asset sales, additional employment, 
          migration, and assistance
  Bad Coping: increases vulnerabiliy* compromising health and edudcation 
        expenses, productive asset sales, conumsumption reductions */

label list HH_U04A

clonevar cope_type1 = hh_u04a
clonevar cope_type2 = hh_u04b
clonevar cope_type3 = hh_u04c
clonevar first_cope = hh_u04a

label def copeN 1 "savings" 2 "help relatives/friends" 3 "help govt" 4 "help ngo/relig" /*
*/ 5 "change eating patterns" 6 "seek more employment" 7 "idle family find work" 8 "migrate" /*
*/ 9 "reduce exp. on health/ed" 10 "get credit" 11 "sell ag assets" 12 "sell durables" /*
*/ 13 "sell land/building" 14 "sell crop stock" 15 "sell livestock" 16 "fish more" /*
*/ 17 "send children away" 18 "spritual efforts" 19 "did nothing" 20 "other"
lab val cope_type1 copeN
lab val cope_type2 copeN
lab val cope_type3 copeN

* Create macros of coping types
cnumlist "1 2 3 4 6 7 10 12 16"
global gdcope `r(numlist)'
cnumlist "5 9 11 13 14 15 17"
global bdcope `r(numlist)'
    
g byte goodcope = inlist(hh_u04a, $gdcope) & rptShock == 1 
g byte badcope = inlist(hh_u04a, $bdcope) & rptShock == 1
g byte nocope = inlist(hh_u04a, 19) & rptShock == 1
g byte praycope = inlist(hh_u04a, 18) & rptShock == 1

g byte goodcope2 = inlist(hh_u04b, $gdcope) & rptShock == 1 
g byte badcope2 = inlist(hh_u04b,  $bdcope) & rptShock == 1
g byte nocope2 = inlist(hh_u04b, 19) & rptShock == 1
g byte praycope2 = inlist(hh_u04b, 18) & rptShock == 1

g byte goodcope3 = inlist(hh_u04c, $gdcope) & rptShock == 1 
g byte badcope3 = inlist(hh_u04c,  $bdcope) & rptShock == 1
g byte nocope3 = inlist(hh_u04c, 19) & rptShock == 1
g byte praycope3 = inlist(hh_u04c, 18) & rptShock == 1

* Plot coping strategies by shock type

* Create a sorted shock_type variable that is based on the frequency from 
tabsort hh_u04a shock_type
recode shock_type (2 = 0 "Disaster")(0 = 1 "Agricultural")(6 = 2 "Food Prices")/*
  */ (4 = 3 "Health")(1 = 4 "Conflict")(3 = 5 "Financial")(5 = 6 "Other"), gen(shock_sort)

tabsort hh_u04a shock_type if shock_sev == 1

* First look at the primary coping mechanism for ANY type of shock
graph hbar (count) if rptShock == 1  & shock_type != 5 , /*
*/ over(hh_u04a, sort(1) descending label(labsize(vsmall))) /*
*/ blabel(bar, size(tiny)) scheme(s2mono) scale(.8)  nofill/*
*/ by(shock_sort, cols(3) iscale(*.8) title(Do nothing is /*
*/ the primary coping strategy for all types of shocks/*
*/, size(small) color("100 100 100"))) ylabel(, labsize(vsmall))/*
*/ yscale(noline) subtitle(, color("100 100 100"))
graph export "$pathgraph\Shock_coping_2011.pdf", as(pdf) replace


drop  hh_wgt-h2010_sen hh_*

* Collapse data to househld level and merge back with GIS info
ds (shock_code shock_type visit), not
keep `r(varlist)'

include "$pathdo/copylabels.do"
  ds(case_id ea_id shock_sev), not
  collapse (max) `r(varlist)', by(case_id)
include "$pathdo/attachlabels.do"

g anyShock = tot_shocks > 0 & tot_shocks != .

la var tot_shocks "total shocks (of any severity)"
la var goodcope "Good coping mechanisms employed as primary response"
la var badcope "Bad coping mechanisms employed as primary response"
la var nocope "Did nothing as primary response"
la var praycope "Prayed as primary response"

merge 1:1 case_id using "$pathout/geo_hh_roster1.dta", gen(geo_merge)
gen year = 2011
save "$pathout/shocks_wide2011.dta", replace
export delimited "$pathxls/shocks_wide2011.csv", replace


/*
* ############################
* Run below if plotting in R 
* #############################
foreach x of varlist ag conflict disaster financial health other foodprice tot_shocks {
  ren `x' shk_`x'
  }
*end

* If you want a long panel for plotting in R use code below
reshape long shk_@, i(case_id) j(shock, string)
clear
*/

* #####################
* 2013 Shocks ****
* #####################

* First merge geo + hh roster informationuse 
use "$wave2/HH_MOD_A_FILT.dta", clear
merge 1:1 y2_hhid using"$wave2/HouseholdGeovariables_IHPS.dta", gen(hh_rost_geo)
save "$pathout/geo_hh_roster2.dta", replace
clear

use "$wave2/HH_MOD_U.dta" 

* Tabulate top two shocks for creating shock variables
tab hh_u0a if inlist(hh_u02, 1, 2)

* Flag observations with a shock
g byte rptShock = hh_u01 == 1

tab hh_u0a hh_u02 if rptShock == 1, mi
la var rptShock "Household reported a shock"

* Create lowercase labels for the graphs
g shock_des = strlower(hh_u0b)
clonevar shock_code = hh_u0a

clonevar shock_sev = hh_u02
la def severity 1 "Most severe" 2 "2nd most severe" 3 "3rd most severe"
la val shock_sev severity 

* Gather shock codes and create shock category variables
* Create preliminary shock variables (first or 2nd most severe shock)
label list HH_U0A

* Create new label set
lab def shockN 101 "drought" 102 "floods" 103 "earthquakes" 104 "crop pest/disease" /*
*/ 105 "livstock disease" 106 "low ag output price" 107 "high ag input prices" 108 "high food price" /*
*/ 109 "remittances/aid ends" 110 "non-ag earnings fall" 111 "non-ag biz failure" 112 "salary reduced" /*
*/ 113 "unemployed" 114 "illness/injury" 115 "birth in hh" 116 "death of income earner" /*
*/ 117 "other death" 118 "hh break-up" 119 "theft all forms" 120 "conflict/violence" 121 "other" /*
*/ 1101 "irregular rains" 1102 "landslides"
la val shock_code shockN

/*ag 		= other crop damage; input price increase; death of livestock
* conflit 	= theft/robbery/violence
* disaster 	= drought, flood, heavy rains, landslides, fire
* financial	= loss of non-farm job
* foodprice	= price rise of food item
* pricedown = price fall of food items
* health	= death of hh member; illness of hh member
* other 	= loss of house; displacement; other */ 

cnumlist "101 1101 102 1102 103"
local disaster `r(numlist)'
cnumlist "104 105 106 107"
local ag `r(numlist)'
cnumlist "109 110 111 112 113"
local fin `r(numlist)'
cnumlist "114 115 116 117"
local health `r(numlist)'

* Create scalars to set the range of severity that will be considered for flagging shocks
scalar s_min = 1
scalar s_max = .

* Create standard categories for shocks using WB methods
g byte ag 		    = inlist(hh_u0a, `ag') & rptShock /*& inrange(shock_sev, s_min, s_max)*/
g byte conflict   = inlist(hh_u0a, 119, 120) & rptShock /*& inrange(shock_sev, s_min, s_max)*/
g byte disaster   = inlist(hh_u0a, `disaster') & rptShock /*& inrange(shock_sev, s_min, s_max)*/
g byte financial  = inlist(hh_u0a, `fin') & rptShock /*& inrange(shock_sev, s_min, s_max)*/
g byte health 	  = inlist(hh_u0a, `health') & rptShock /*& inrange(shock_sev, s_min, s_max)*/
g byte other 	    = inlist(hh_u0a, 118, 121) & rptShock /*& inrange(shock_sev, s_min, s_max)*/
g byte foodprice  = inlist(hh_u0a, 108) & rptShock /*& inrange(shock_sev, s_min, s_max)*/

* Create a long variable that would identify groups of shocks, strictly for plotting
g shock_type = .
local slist "ag conflict disaster financial health other foodprice"
local i = 0
foreach x of local slist {
    replace shock_type = `i' if `x' == 1
    local i = `++i'
}

la def shocka 0 "Agricultural" 1 "Conflict" 2 "Disaster" 3 "Financial" /*
*/ 4 "Health" 5 "Other" 6 "Food Prices"
la val shock_type shocka
tabsort shock_type shock_sev, mi

* Create bar graph of shocks ranked by severity
graph hbar (count) if rptShock == 1, /*
*/ over(shock_code, sort(1) descending label(labsize(vsmall))) /*
*/ blabel(bar) scheme(s2mono) scale(.80) /*
*/ by(shock_sev, missing cols(2) iscale(*.80) /*
*/ title(High food and agricultural input prices are the most common and the most severe shocks/*
*/, size(small) color("100 100 100"))) 
graph export "$pathgraph\Shocks2013.pdf", as(pdf) replace

* Create bar graph of shocks ranked by severity
graph hbar (count) if rptShock == 1, /*
*/ over(shock_type, sort(1) descending label(labsize(vsmall))) /*
*/ blabel(bar) scheme(s2mono) scale(.8) /*
*/ by(shock_sev, missing cols(2) iscale(*.8) title(Food price /*
*/ and agricultural shocks are the most common and most severe shock categories/*
*/, size(small) color("100 100 100")))
graph export "$pathgraph\Shock_categories2013.pdf", as(pdf) replace

merge m:m y2_hhid using "$pathout/geo_hh_roster2.dta"

graph hbar (count) if rptShock == 1, /*
*/ over(shock_type, sort(1) descending label(labsize(vsmall))) /*
*/ blabel(bar) scheme(s2mono) scale(.8) /*
*/ by(shock_sev region, missing cols(3) iscale(*.8) title(Food price /*
*/ and agricultural-based shocks are the most common and severe shock categories/*
*/, size(small) color("100 100 100")))
graph export "$pathgraph\Shock_categories_region2013.pdf", as(pdf) replace

* Total shocks reported by hh
egen tot_shocks = total(rptShock), by(y2_hhid)

* Label shocks
la var ag "Agricultural shock (any severity)"
la var conflict "Conflict shock (any severity)"
la var disaster "Disaster shock (any severity)"
la var financial "Financial shock (any severity)"
la var health "Health shock (any severity)"
la var other "Other shock (any severity)"
la var foodprice "Price rise shock (any severity)"
la var shock_type "type of shock shock (any severity)"

label list HH_U04A

clonevar cope_type1 = hh_u04a
clonevar cope_type2 = hh_u04b
clonevar cope_type3 = hh_u04c
clonevar first_cope = hh_u04a

label def copeN 1 "savings" 2 "help relatives/friends" 3 "help govt" 4 "help ngo/relig" /*
*/ 5 "change eating patterns" 6 "seek more employment" 7 "idle family find work" 8 "migrate" /*
*/ 9 "reduce exp. on health/ed" 10 "get credit" 11 "sell ag assets" 12 "sell durables" /*
*/ 13 "sell land/building" 14 "sell crop stock" 15 "sell livestock" 16 "fish more" /*
*/ 17 "send children away" 18 "spritual efforts" 19 "did nothing" 20 "other"
lab val cope_type1 copeN

* Create macros of coping types
cnumlist "1 2 3 4 6 7 10 12 16"
global gdcope `r(numlist)'
cnumlist "5 9 11 13 14 15 17"
global bdcope `r(numlist)'
    
g byte goodcope = inlist(hh_u04a, $gdcope) & rptShock == 1 
g byte badcope = inlist(hh_u04a, $bdcope) & rptShock == 1
g byte nocope = inlist(hh_u04a, 19) & rptShock == 1
g byte praycope = inlist(hh_u04a, 18) & rptShock == 1

la var goodcope "Good coping mechanisms employed as primary response"
la var badcope "Bad coping mechanisms employed as primary response"
la var nocope "Did nothing as primary response"
la var praycope "Prayed as primary response"

* Create a sorted shock_type variable that is based on the frequency from 
tabsort hh_u04a shock_type
recode shock_type (0 = 0 "Agricultural")(6 = 1 "Food Prices")(2 = 2 "Disaster")/*
  */ (4 = 3 "Health")(3 = 4 "Financial")(1 = 5 "Conflict")(5 = 6 "Other"), gen(shock_sort)

* Convert the value lables to lowercase for consistency w/ other graphs
foreach v of varlist hh_u04a {
  local u : value label `v'
    * change belwo to upper/proper when needed
    local l = lower("`u'") 
    capture labvalclone `u' `l'
   
     if _rc == 0 {
        * change the value label's name
        label val `v' `l' 
        label drop `u'
        levelsof `v', local(xvalues)

           foreach x of local xvalues {
              local z: label (`v') `x', strict
              local znew =lower("`z'") 
              noi display in yellow "`x': `z' ==> `znew'"
              label define `l' `x' "`znew'", modify 
              }
     }
}

* First look at the primary coping mechanism for ANY type of shock
graph hbar (count) if rptShock == 1  & shock_type != 5 , /*
*/ over(hh_u04a, sort(1) descending label(labsize(vsmall))) /*
*/ blabel(bar, size(tiny)) scheme(s2mono) scale(.8)  nofill/*
*/ by(shock_sort, cols(3) iscale(*.8) title(Using savings is /*
*/ the primary coping strategy for all types of shocks/*
*/, size(small) color("100 100 100"))) ylabel(, labsize(vsmall))/*
*/ yscale(noline) subtitle(, color("100 100 100"))
graph export "$pathgraph\Shock_coping_2013.pdf", as(pdf) replace

drop dist_to_IHS3location- _merge
* Collapse data to househld level and merge back with GIS info
ds (hh_u* shock_des shock_code shock_type occ), not
keep `r(varlist)'

ds (qx_type y2_hhid interview_status shock_sev case_id ea_id stratum HHID baseline* panel* region district), not
include "$pathdo/copylabels.do"
	collapse (max) `r(varlist)', by(y2_hhid)
include "$pathdo/attachlabels.do"

g anyShock = tot_shocks > 0 & !missing(tot_shocks)
la var anyShock "hh reported any type of shock"

merge 1:1 y2_hhid using "$pathout/geo_hh_roster2.dta", gen(geo_merge)
g year = 2013
save "$pathout/shocks_wide2013.dta", replace
export delimited "$pathxls/shocks_wide2013.csv", replace

preserve
append using  "$pathout/shocks_wide2011.dta", force
compress
save "$pathout/shocks_all.dta", replace
restore

/*
foreach x of varlist ag conflict disaster financial health other foodprice tot_shocks {
	ren `x' shk_`x'
	}
*end
reshape long shk_@, i(y2_hhid) j(shock, string)
*/
