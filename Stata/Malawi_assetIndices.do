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
*end

g byte walls1 = inlist(houseMaterial, 1, 2, 7, 9)
g byte walls2 = inlist(houseMaterial, 3)
g byte walls3 = inlist(houseMaterial, 4)
g byte walls4 = inlist(houseMaterial, 5)
g byte walls5 = inlist(houseMaterial, 6, 8)

g byte roofGrass = inlist(roofMaterial, 1)
g byte roofIron  = inlist(roofMaterial, 1) != 1

g byte floorEarth  = inlist(floorMaterial, 1, 2, 4, 6)
g byte floorCement= inlist(floorMaterial, 3, 5)

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

g waterPiped 	= inlist(drinkingWater, 1, 2)
g waterStandPipe = inlist(drinkingWater, 3)
g waterWellOpen = inlist(drinkingWater, 4, 5)
g waterWellProt = inlist(drinkingWater, 6, 7)
g waterBore		= inlist(drinkingWater, 7)
g waterOther	= inlist(drinkingWater, 8, 9, 10, 11, 12, 14, 16)


tab toiletType, gen(toilet)
replace toilet5 = 1 if toilet6 == 1
replace toilet1 = 1 if toilet2 == 1
drop toilet2 toilet6


tab rubbishDisposal, gen(garbage)
recode bedNets (4 = 2)

* Create an infrastructure, asset, ag asset and wealth index

* ################
* Infrastructure #
* ################

#delimit ;
local infra roomsPC walls1 walls2 walls3 walls4 walls5 roofGrass roofIron 
		floorEarth floorCement roomsPC naturalFuel 
		elecFuel gasFuel batteryFuel othFuel collectCook buyCookfw charCook 
		electCook waterPiped waterStandPipe waterWellOpen waterWellProt 
		waterBore waterOther
		toilet1 toilet3 toilet4 toilet5 garbage1 
		garbage2 garbage3 garbage4 garbage5 garbage6 ;
#delimit cr

* Verify that the data are not missing or if missing they are missing 
* that few of them are missing
sum `infra'

factor `infra' if year == 2011 & urban == 2,  pcf factors(1)
predict infraindex_rural_11 if e(sample) == 1

pca `infra' if year == 2013 & urban == 2,  pcf factors(1)
predict infraindex_rural_13 if e(sample) == 1

