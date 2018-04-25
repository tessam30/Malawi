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
merge 1:1 id using "$pathout/hh_agassets_all.dta", gen(_agassets)
merge 1:1 id using "$pathout/tlus_all.dta", gen(_tlus)
merge 1:1 id using "$pathout/hh_base_all.dta", gen(_demog)

* Check the infrastructure and wash variables for variation
foreach x of varlist houseMaterial - bankAccount {
		tab `x', mi
}
*end
g roomsPC = roomsHouse / hhsize
g byte walls1 = inlist(houseMaterial, 1, 2, 7, 9)
g byte walls2 = inlist(houseMaterial, 3)
g byte walls3 = inlist(houseMaterial, 4)
g byte walls4 = inlist(houseMaterial, 5)
g byte walls5 = inlist(houseMaterial, 6, 8)

g byte roofGrass = inlist(roofMaterial, 1)
g byte roofIron  = inlist(roofMaterial, 1) != 1

g byte floorEarth  = inlist(floorMaterial, 1, 2, 4, 6)
g byte floorCement= inlist(floorMaterial, 3, 5)

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
g waterBore		= inlist(drinkingWater, 8)
g waterOther	= inlist(drinkingWater, 9, 10, 11, 12, 14, 16)

g byte mobile = mobilesOwned != 0 & !missing(mobilesOwned)


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

*#delimit ;
	global  infra roomsPC walls1-walls5 roofGrass roofIron floorEarth floorCement waterPiped waterStandPipe waterWellOpen waterWellProt waterBore waterOther toilet1 toilet3 toilet4 toilet5 electricity
*#delimit cr

* Verify that the data are not missing or if missing they are missing
* that few of them are missing
sum $infra

/* A note on creating indices to be comparable across years:
	Create indices for both panel and full sample in 2011 */

* Review the different years and calculations, looking at loading plots and scree plot
factor $infra if year == 2011 [aweight = hhwgt_2011], pcf
screeplot
scoreplot
loadingplot
* Now rotate factors to make them more orthogonal
rotate
scoreplot
screeplot


*2011 - assuming that the hhweight_2011 is the correct metric to use here
* refresher: https://www.princeton.edu/~otorres/Factor.pdf
* Also, reviewing code from FAO RIGA dataset and using same snippet
factor $infra if year == 2011 [aweight = hhwgt_2011], pcf factors(1)
predict infra_index_2011 if e(sample)
histogram infra_index_2011, by(urban)
la var infra_index_2011 "infrastructure index for 2011"

factor $infra if year == 2013 [aweight = hhweight2013], pcf factors(1)
predict infra_index_2013 if e(sample)
histogram infra_index_2013, by(urban)
la var infra_index_2013 "infrastructure index for 2013"

* ############
* Ag assets  #
* ############
*# delimit ;
	global agassets hoe slasher axe sprayer pangaKnife sickle treadlePump waterCan oxCart oxPlough cultivator motorPump grainMill chxHouse livestockKrall poultryKrall storageHouse granary pigSty barn
*#delimit cr
factor $agassets if year == 2011 [aweight = hhwgt_2011], pcf factors(1)
predict ag_index_2011 if e(sample)
histogram ag_index_2011, by(urban)
la var ag_index_2011 "agricultural asset index for 2011"

factor $agassets if year == 2013 [aweight = hhweight2013], pcf factors(1)
predict ag_index_2013 if e(sample)
histogram ag_index_2013, by(urban)
la var ag_index_2013 "agricultural asset index for 2013"

* ############
* durables  #
* ############

*# delimit ;
	global durgoods mortar bed table chair fan radio tape tv sewingMaching  hotplat fridge bike minibus lorry beerDrum upholsteredChair coffeeTable cupboard lantern clock iron satDish
*#delimit cr

factor $durgoods  if year == 2011 [aweight = hhwgt_2011], pcf factors(1)
predict durables_index_2011 if e(sample)
histogram durables_index_2011, by(urban)
la var durables_index_2011 "durable goods index for 2011"

factor $durgoods  if year == 2013  & urban == 2 [aweight = hhweight2013], pcf factors(1)
predict durables_index_2013 if e(sample)
histogram durables_index_2013, by(urban)
la var durables_index_2013 "durable goods index for 2013"

* ##############
* Wealth Index #
* ##############
factor $infra $agassets $durgoods mobile if year == 2011 [aweight = hhwgt_2011], pcf
predict wealth_2011 if e(sample)
histogram wealth_2011, by(urban)
la var wealth_2011 "Wealth index for 2011"

factor $infra $agassets $durgoods mobile if year == 2013 [aweight = hhweight2013], pcf
predict wealth_2013 if e(sample)
histogram wealth_2013, by(urban)
la var wealth_2013 "Wealth index for 2013"


* This is interesting to play around with as it relates to our own Center's mandate
* Who owns a mobile phone and who is benefitting from their expansion the most?
* How correlated are the indices and consumption?
g lnexp = ln(rexpagg)
pwcorr wealth_2011 wealth_2013 lnexp, star(0.05)
scatter wealth_2011 lnexp
twoway(scatter wealth_2013 lnexp)(lowess wealth_2013 lnexp) if urban == 2

twoway(lowess mobile wealth_2011 if urban == 2)(lowess radio wealth_2011 if urban == 2)
twoway(lowess mobile lnexp if urban == 2)(lowess radio lnexp if urban == 2)

drop walls1- waterOther
compress
save "$pathout/hh_base_assets.dta", replace


***********************************
* Calculating separately for 2016 *
***********************************
use "$pathout/hh_infra_2016.dta", clear

merge 1:1 case_id using "$pathout/hh_durables_2016.dta", gen(_assets1)
merge 1:1 case_id using "$pathout/hh_agassets2016.dta", gen(_agassets)
merge 1:1 case_id using "$pathout/tlus_2016.dta", gen(_tlus)
merge 1:1 case_id using "$pathout/hh_base_hhlevel_2016.dta", gen(_demog)

* Household asset list
* Check the infrastructure and wash variables for variation
foreach x of varlist houseMaterial - bedNets {
		tab `x', mi
}
*end

/*         1 GRASS
           2 MUD
           3 COMPACTED EARTH
           4 MUD BRICK
           5 BURNT BRICKS
           6 CONCRETE
           7 WOOD
           8 IRON SHEETS
           9 OTHER (SPECIFY)
*/

g roomsPC = roomsHouse / hhsize
g byte walls1 = inlist(houseMaterial, 1, 2, 7, 9)
g byte walls2 = inlist(houseMaterial, 3)
g byte walls3 = inlist(houseMaterial, 4)
g byte walls4 = inlist(houseMaterial, 5)
g byte walls5 = inlist(houseMaterial, 6, 8)

g byte roofGrass = inlist(roofMaterial, 1)
* Few households are not iron or grass roof
g byte roofIron  = inlist(roofMaterial, 2)

g byte floorEarth  = inlist(floorMaterial, 1, 2, 4, 6)
g byte floorCement= inlist(floorMaterial, 3, 5)

g byte naturalFuel = inlist(fuelSource, 1, 2, 3)
g byte elecFuel	= inlist(fuelSource, 5)
g byte gasFuel	= inlist(fuelSource, 4, 6)
g byte batteryFuel = inlist(fuelSource, 7)
g byte othFuel	= inlist(fuelSource, 8, 9)

g byte collectCook 	= inlist(cookingFuel, 1, 7, 8, 10)
g byte buyCookfw   	= inlist(cookingFuel, 2)
g byte charCook		= inlist(cookingFuel, 3, 6, 5)
g byte electCook	= inlist(cookingFuel, 4)

g waterPiped 	= inlist(drinkingWater, 1, 2)
g waterStandPipe = inlist(drinkingWater, 3)
g waterWellOpen = inlist(drinkingWater, 4, 5)
g waterWellProt = inlist(drinkingWater, 6, 7)
g waterBore		= inlist(drinkingWater, 8)
g waterOther	= inlist(drinkingWater, 9, 10, 11, 12, 14, 15, 16)

g byte mobile = mobilesOwned != 0 & !missing(mobilesOwned)

* Toilets and rubbish
tab toiletType, gen(toilet)
replace toilet5 = 1 if toilet6 == 1
replace toilet1 = 1 if toilet2 == 1
drop toilet2 toilet6


tab rubbishDisposal, gen(garbage)
recode bedNets (2 = 0)
recode electricity (2 = 0)

* ################
* Infrastructure #
* ################

*#delimit ;
	global  infra roomsPC walls1-walls5 roofGrass roofIron floorEarth floorCement waterPiped waterStandPipe waterWellOpen waterWellProt waterBore waterOther  toilet1 toilet3 toilet4 toilet5 electricity
*#delimit cr

* Verify that the data are not missing or if missing they are missing
* that few of them are missing
sum $infra

* Review the different years and calculations, looking at loading plots and scree plot
factor $infra [aweight = hh_wgt], pcf
screeplot
scoreplot
loadingplot
* Now rotate factors to make them more orthogonal


predict infra_index_2016 if e(sample)
histogram infra_index_2016, by(reside)
la var infra_index_2016 "infrastructure index for 2016"

********* Ag Assets ***********
macro drop agassets
*# delimit ;
	global agassets hoe slasher axe sprayer pangaKnife sickle treadlePump waterCan oxCart oxPlough cultivator motorPump grainMill chxHouse livestockKrall poultryKrall storageHouse granary pigSty barn
*#delimit cr
factor $agassets [aweight = hh_wgt], pcf factors(1)
predict ag_index_2016 if e(sample)
histogram ag_index_2016, by(reside)
la var ag_index_2016 "agricultural asset index for 2016"


********* durables *********
*
macro drop durgoods
*# delimit ;
	global durgoods mortar bed table chair fan radio tape tv sewingMaching hotplat fridge bike minibus lorry beerDrum upholsteredChair coffeeTable cupboard lantern clock iron satDish
*#delimit cr

factor $durgoods [aweight = hh_wgt], pcf factors(1)
predict durables_index_2016 if e(sample)
histogram durables_index_2016, by(reside)
la var durables_index_2016 "durable goods index for 2016"

* ##############
* Wealth Index #
* ##############
factor $infra $agassets $durgoods mobile [aweight = hh_wgt], pcf
predict wealth_2016 if e(sample)
histogram wealth_2016, by(reside)
la var wealth_2016 "Wealth index for 2011"

twoway(lowess mobile wealth_2016 if reside == 2)(lowess radio wealth_2016 if reside == 2)
drop walls1- garbage6

compress
save "$pathout/hh_base_assets_2016.dta", replace
