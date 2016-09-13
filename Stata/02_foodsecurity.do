/*-------------------------------------------------------------------------------
# Name:		02_foodsecurity
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
log using "$pathlog/02_foodsecurity.txt", replace

use "$wave2/HH_MOD_G2.dta", clear

* Calculate how many times hh consumed various foods; See link below
* https://github.com/tessam30/Bangladesh/wiki/Food-Security-Notes
