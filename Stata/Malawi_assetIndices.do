/*-------------------------------------------------------------------------------
# Name:		Malawi_assetIndices.do
# Purpose:	Create asset indices using DHS method; Merge in asset data
# 			 (http://dhsprogram.com/topics/wealth-index/Wealth-Index-Construction.cfm)
# Author:	Tim Essam, Ph.D.
# Created:  2016/09/26
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close 
log using "$pathlog/AssetIndices.txt", replace

use "$pathout/hh_infra_all.dta", clear

merge 1:1 id using "$pathout/hh_durables_all.dta", gen(_assets1)
merge 1:1 id using "$pathout/tlus_all.dta", gen(_tlus)

