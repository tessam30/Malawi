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
merge 1:1 id using "$pathout/hh_base_all.dta", gen(_demog)

* Check the infrastructure and wash variables for variation
foreach x of varlist houseMaterial - bankAccount {
		tab `x', mi
}

tab houseMaterial, gen(walls)
drop walls1 walls2 walls7 walls8 walls9
g byte walls1 = inlist(houseMaterial, 1, 2)
g byte walls7 = inlist(houseMaterial, 7, 8, 20)

g byte roofGrass = inlist(roofMaterial, 1)
g byte roofIron  = inlist(roofMaterial, 2)
g byte roofOther = inlist(roofMaterial, 3, 4, 5, 6)

g byte floorEarth  = inlist(floorMaterial, 1, 2)
g byte floorCement= inlist(floorMaterial, 3)
g byte floorOther = inlist(floorMaterial, 4, 5, 6)

g roomsPC = roomsHouse / hhsize

g byte naturalFuel = inlist(fuelSource, 1, 2, 3)
g byte elecFuel	= inlist(fuelSource, 5)
g byte gasFuel	= inlist(fuelSource, 4, 6)
g byte batteryFuel = inlist(fuelSource, 7, 10)
g byte othFuel	= inlist(fuelSource, 8, 9)

g byte collectCook 	= inlist(cookingFuel, 1, 7, 8, 9, 10, 14)
g byte buyCookfw   	= inlist(cookingFuel, 2)
g byte charCook		= inlist(cookingFuel, 3, 6, 5)
g byte electCook	= inlist(cookingFuel, 4)

tab drinkingWater, gen(waterSource)
drop waterSource9 - waterSource14
g waterSource9 = inrange(drinkingWater, 9, 14)
la var waterSource9 "drinkingWater == Surface, tanker or other"

tab toiletType, gen(toilet)
replace toilet5 = 1 if toilet6 == 1

tab rubbishDisposal, gen(garbage)
recode bedNets (4 = 2)

* Create an infrastructure, asset, ag asset and wealth index

* ################
* Infrastructure #
* ################


