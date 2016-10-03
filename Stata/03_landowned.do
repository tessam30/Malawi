/*-------------------------------------------------------------------------------
# Name:		00_SetupFolderGlobals
# Purpose:	Create series of folders Food for Malawi Vulnerability Analysis
# Author:	Tim Essam, Ph.D.
# Created:	2016/04/27
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/






clear
capture log close
log using "$pathlog/land_own2011.dta", replace
use "wave1/AG_MOD_D.dta", clear

