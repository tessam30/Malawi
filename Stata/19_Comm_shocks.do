/*-------------------------------------------------------------------------------
# Name:		19_Comm_shocks
# Purpose:	Process community level shocks
# Author:	Tim Essam, Ph.D.
# Created:	2018/04/25
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close
log using "$pathlog/comm_shocks.txt", replace

* 2011 Community shock information
use "$wave1/COM_CG2.dta", clear

* list out community level shocks
label list

* Shocks that are categorized as bad, and affect more than 1/2 of community are flagged

* Set a global condition to define shock parameters
global shockParam2011 "inrange(com_cg37, 3, 5) & com_cg35 == 1"

* Drought shocks affecting 1/2 or more of community occuring in last 3 years
g byte comDrought = (com_cg35a == 1 & $shockParam2011)
g byte comDisease = (inlist(com_cg35a, 3, 4, 5) & $shockParam2011)
g byte comFlood   = (inlist(com_cg35a, 2) & $shockParam2011)
g byte comPrice   = (inlist(com_cg35a, 5) & $shockParam2011)
g byte comSocProt = (inlist(com_cg35a, 7, 8, 9) & $shockParam2011)
g byte comBadShock = (inrange(com_cg35a, 1, 10) & $shockParam2011)

g byte comGoodShock = (inrange(com_cg35a, 11, 20) & inrange(com_cg37, 3, 5) & com_cg35 == 2)

la var comDrought "drought community shock"
la var comDisease "crop, livestock or human disease com shock"
la var comFlood "flood com shock"
la var comPrice "sharp change in prices com shock"
la var comSocProt "lay-offs, loss of social services or poweroutages com shock"
la var comBadShock "any bad shock at com level"
la var comGoodShock "any good shock at com level"

include "$pathdo/copylabels.do"
  ds(ea_id com_c*), not
  collapse (max) `r(varlist)', by(ea_id)
include "$pathdo/attachlabels.do"

g year = 2011
save "$pathout/commShocks_2011.dta", replace

use "$wave3/COM_CG.dta", clear

* List out the shocks facing the village
label list
/* NOTES: looking at code cg35b_code, it appears that bad shocks fall under numbers 1/10 and good shocks fall under number 11/20.

* Community shocks will be defined as bad/good shocks that affected at least 1/2 of the community in the past 3 years.
*/

* Set a global condition to define shock parameters
global shockParam "inrange(com_cg37, 3, 5) & inrange(com_cg36, 2014, 2016)"

* Drought shocks affecting 1/2 or more of community occuring in last 3 years
g byte comDrought = (com_cg35c == 1 & $shockParam)
g byte comDisease = (inlist(com_cg35c, 3, 4, 5) & $shockParam)
g byte comFlood   = (inlist(com_cg35c, 2) & $shockParam)
g byte comPrice   = (inlist(com_cg35c, 5) & $shockParam)
g byte comSocProt = (inlist(com_cg35c, 7, 8, 9) & $shockParam)
g byte comBadShock = (inrange(com_cg35c, 1, 10) & $shockParam)

* Good Community comm_shocks
g byte comGoodShock = (inrange(com_cg35c, 11, 20) & $shockParam)

la var comDrought "drought community shock"
la var comDisease "crop, livestock or human disease com shock"
la var comFlood "flood com shock"
la var comPrice "sharp change in prices com shock"
la var comSocProt "lay-offs, loss of social services or poweroutages com shock"
la var comBadShock "any bad shock at com level"
la var comGoodShock "any good shock at com level"

include "$pathdo/copylabels.do"
  ds(ea_id com_c*), not
  collapse (max) `r(varlist)', by(ea_id)
include "$pathdo/attachlabels.do"

compress
save "$pathout/commShocks_2016.dta", replace
