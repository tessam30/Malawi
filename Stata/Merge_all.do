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

* Append the two waves hh bases together. Use this a merging base.
append using "$pathout/hh_base_wave2.dta"

* Create a variable to track how many case_ids show up in 2011 and 2013. Those
* in both years indicate that the household is in the panel.
bys case_id: gen ptrack = _N
