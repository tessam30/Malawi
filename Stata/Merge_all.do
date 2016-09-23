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
* According to the ConsumptionAggregate_panel there should be 3,246 in the panel. 
bys HHID: gen hhidtmp = _N
bys case_id: gen idtmp = _N
order hhidtmp idtmp ptrack case_id y2_hhid round HHID panel year 
sort case_id year y2_hhid 

clist case_id y2_hhid hhidtmp ptrack year if inrange(hhidtmp, 3, 4), noo

* Assume that the ending value of the variable y2_hhid is mapped to the original household in the panel and that any higher values
* map into the break-off units of the household. Use the `reverse' and `strpos' commands to create a flag for observations where
* the reversed value of the string y2_hhid take the value of one. This will be our panel tracker for original households. We may 
* also assumed that the valueof the y2_hhid variable maps into the roster position of the person in the household (if it's two
* it may indicate that the spouse split off.)

tab hhidtmp
g byte origHH = strpos(reverse(y2_hhid), "1") == 1  & inrange(hhidtmp, 2, 7)
replace ptrack = 1 if origHH == 1
replace ptrack = 2 if origHH == 0 & year == 2013 & inrange(hhidtmp, 3, 7)
replace ptrack = 1 if hhidtmp == 2 & ptrack == .
* Fill in flag for households that are in panel

merge m:1 y2_hhid using "$wave2\HH_MOD_A_FILT.dta", keepusing(hh_a05 y2_hhid)
* Recode observations where the split off appears to be wrong based on hh_a05 variable
replace ptrack = 1 if hh_a05 == 1 & ptrack == 2


use "$wave2/HH_MOD_A_FILT.dta", clear
* So documentation of the panel is a bit convoluted based on the original survey documents.
* http://siteresources.worldbank.org/INTLSMS/Resources/3358986-1233781970982/5800988-1271185595871/6964312-1404828635943/IHPS_BID_FINAL.pdf

* Create a variable that tracks the contribution to the 2013 sample


keep occ y2_hhid HHID case_id ea_id stratum baseline_rural panelweight hh_wgt region district reside hhsize hh_a05
g year = 2013
bys HHID: gen hhidtmp = _N
tab hhidtmp

bys case_id: gen idtmp = _N
save "$pathout/hh_base_wave2.dta", replace


use "$wave1/ihs3_summary.dta", clear
g year = 2011
g wave = 1
la def WAVE 1 "first wave" 2 "second wave"
lab val wave WAVE

* Append the two waves hh bases together. Use this a merging base.


* Create a variable to track how many case_ids show up in 2011 and 2013. Those
* in both years indicate that the household is in the panel.
bys case_id: gen ptrack = _N
order ptrack hhidtmp idtmp  y2_hhid case_id HHID year
