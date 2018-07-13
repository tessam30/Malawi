/*-------------------------------------------------------------------------------
# Name:		07_StuntingAnalysisTemporal
# Purpose:	Compare stunting results over time
# Author:	Tim Essam, Ph.D.
# Created:	2018/07/13
# Owner:	USAID GeoCenter 
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/


clear
capture log close
log using "$pathlog/07_StuntingAnalysisTemporal.txt", replace

use "$DHSout/DHS_2015_Stunting.dta", clear
ren district district_2015
append using "$DHSout/DHS_2010_Stunting.dta"
