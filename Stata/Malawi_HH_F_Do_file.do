/*-------------------------------------------------------------------------------
# Name:		Malawi_HH_F_Do_file.do
# Purpose:	Process food insecurity module
# Author:	Tim Essam, Ph.D.
# Created:	2016/04/27
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

* Process food insecurity module
clear
capture log close
log using "$pathlog/Housing.txt", replace
use "$wave1/HH_MOD_F.dta", clear

