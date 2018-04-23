/*-------------------------------------------------------------------------------
# Name:		18_COM_
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
log using "$pathlog/Community_vars.txt", replace

use "$wave1/COM_CD.dta", clear

* WVU team expressed an interest in these variables
d com_cd06 com_cd16a com_cd18a com_cd27a com_cd32 com_cd36a com_cd38 com_cd49a com_cd51a com_cd60a

* These seem to better capture the availability of community services and will combined into an index
d com_cd03 com_cd06 com_cd12 com_cd15 com_cd21 com_cd32 com_cd35 com_cd48 com_cd50 com_cd62
tab com_cd01, gen(roadType)
g byte asphaltRoad = inlist(com_cd01, 1)
g byte dirtTrack = inlist(com_cd01, 4)

#delimit ;
	local comserv com_cd03 com_cd06  com_cd12 com_cd17 com_cd66
		com_cd15 com_cd21 com_cd32 com_cd35 com_cd48 com_cd19 
		com_cd50 com_cd62 com_cd68 dirtTrack asphaltRoad;
#delimit cr

factor `comserv', pcf factors(1)
predict community_index_2011 if e(sample)
histogram community_index_2011
g year = 2011

save "$pathout/comm_index2011.dta", replace

** ----------------------- 2013 Data --------------------------------------

use "$wave2/COM_MOD_D.dta", clear

tab com_cd01, gen(roadType)
g byte asphaltRoad = inlist(com_cd01, 1)
g byte dirtTrack = inlist(com_cd01, 4)

#delimit ;
	local comserv com_cd03 com_cd06  com_cd66
		com_cd15 com_cd23 com_cd32 com_cd35 com_cd48 
		com_cd50  asphaltRoad;
#delimit cr

d `comserv'
factor `comserv', pcf factors(1)
predict community_index_2013 if e(sample)
histogram community_index_2013
g year = 2013

* Keep these separate incase the ea_ids are duplicates in the appended data
save "$pathout/comm_index2013.dta", replace

