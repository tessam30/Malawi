* Describe what is accomplished with file:
* This .do file processed household food consumption information 
* Date: 2016/09/16
* Author: Brent McCusker, Park Muhonda & Tim Essam
* Project: WVU Livelihood Analysis for Malawi
********************************************************************

clear
capture log close

* Read in the data you are using; Use relative paths whenver possible
/* Note: I store the raw data in two folders called wave1 and wave 2.
I then point to them using global macros. This keeps the code general
and allows me to port it across machines by only changing the macro and
not any hard-coded depedencies. */

global wave1 "C:/Users/student/Documents/Malawi/Datain/wave1"
global wave2 "C:/Users/student/Documents/Malawi/Datain/wave2"
global pathout "C:/Users/student/Documents/Malawi/Dataout"
*global pathdo "C:/Users/student/Documents/GitHub/Malawi/Stata"

* Load the dataset needed to derive time use and ganyu variables
use "$wave1/HH_MOD_G1.dta"

/* Create dietary diversity variable consisting of following food groups:
  1) Cereals - cereal_days & pulses (x)
  2) White roots and tubers - Starches (x)
  3) Vegetables (x)
  4) Fruits (x)
  5) Meat (x)
  6) Eggs (x) 0
  7) Fish and other seafood (x)
  8) Legumes, nuts and seeds (x)
  9) Milk and milk products (x)
  10) Oils an fats 
  11) Sweets*
  12) Spices condiments and beverages	*/

g byte cereal = inlist(hh_g02, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 114, 115, 116, 117, 820, 827, 828, 829 ) == 1 & hh_g01 == 1
g byte starch = inlist(hh_g02, 201, 202, 203, 204, 205,206,207, 208, 209, 821, 822) == 1 & hh_g01 == 1
g byte veg =  inlist(hh_g02, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414) == 1 & hh_g01 == 1
g byte fruit =  inlist(hh_g02, 601, 602, 603, 604, 605,606,607, 608, 609, 610) == 1 & hh_g01 == 1
g byte meat =  inlist(hh_g02, 504, 505,506,507, 508, 509, 512, 824, 825) == 1 & hh_g01 == 1
g byte eggs =  inlist(hh_g02, 501, 823) == 1 & hh_g01 == 1
g byte fish =  inlist(hh_g02, 502, 503, 512, 513, 514, 515, 826) == 1 & hh_g01 == 1
g byte legumes =  inlist(hh_g02, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310) == 1 & hh_g01 == 1
g byte milk =  inlist(hh_g02, 701, 702, 705,706, 707, 708, 709) == 1 & hh_g01 == 1
g byte fats =  inlist(hh_g02, 703, 704) == 1 & hh_g01 == 1
g byte sweet =  inlist(hh_g02, 113, 801, 802, 815, 816, 817) == 1 & hh_g01 == 1
g byte cond =  inlist(hh_g02, 810, 811, 812, 813, 814, 901, 902, 903, 904, 905,906,907, 908, 909, 910, 911, 912, 913, 914, 915, 916) == 1 & hh_g01 == 1  
g byte meat2 =  inlist(hh_g02, 510, 511) == 1 & hh_g01 == 1
g byte oil =  inlist(hh_g02, 803) == 1 & hh_g01 == 1
g byte staples =  inlist(hh_g02, 101, 103, 106, 202,  207 ) == 1 & hh_g01 == 1

local dietLab cereal starch veg fruit meat eggs fish legumes milk fats sweet cond meat2 oil staples
foreach x of local dietLab {
	la var `x' "Consumed `x' in last 7 days"
	g `x'_days = hh_g02 if `x' == 1
	replace `x'_days = 0 if `x'_days == .
} 

* Check  households not reporting any consumption
egen tmp = rsum(cereal starch veg fruit meat eggs fish legumes milk fats sweet cond)
egen tmpsum = total(tmp), by(case_id)
* for checking which HH are missing all consumption information
*br if tmpsum == 0


* Calculate food consumption score* Create variables to calculate Food Consumption Score 
g cerealFCS = cereal_days * 2
g starchFCS = starch_days * 2
g staplesFCS = staples_days * 2

g legumesFCS = legumes_days * 3

* Both weighted by 1
g vegFCS = veg_days
g fruitFCS = fruit_days

* meat, poultry, fish, eggs
g meatFCS = meat2_days * 4
g milkFCS = milk_days * 4

g sweetFCS = sweet_days * 0.5
g oilFCS = oil_days * 0.5

* Keep derived data (FCS & dietary diversity scores) and HHID
ds(hh_s* saq* ea_id), not
keep `r(varlist)'

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
ds(household_id), not
collapse (max) `r(varlist)', by(household_id)
qui include "$pathdo/attachlabels.do"

* Calculate two metrics
egen dietDiv = rsum(cereal starch veg fruit meat eggs fish legumes milk fats sweet cond)
la var dietDiv "Dietary diversity (12 food groups)"
recode dietDiv (0 = .) 
g year = 2011

egen FCS = rsum2(staplesFCS legumesFCS vegFCS fruitFCS meatFCS milkFCS sweetFCS oilFCS)
recode FCS (0 = .)

clonevar FCS_categ = FCS 
recode FCS_categ (0/21 = 0) (21.5/35 = 1) (35.1/53 = 2) (53/112 = 3)
lab def fcscat 0 "Poor" 1 " Borderline" 2 " Acceptable low" 3 "Acceptable high"
lab val FCS_categ fcscat
la var FCS_categ "Food consumption score category"
tab FCS_cat, mi


sa "$pathout/dietdiv_2011.dta", replace

***** Wave 2 *****
* Process 2nd wave 
* Load the dataset needed to derive food consuption variables
clear
use "$wave2/HH_MOD_G1.dta"

/* Create dietary diversity variable consisting of following food groups:
  1) Cereals - cereal_days & pulses (x)
  2) White roots and tubers - Starches (x)
  3) Vegetables (x)
  4) Fruits (x)
  5) Meat (x)
  6) Eggs (x) 0
  7) Fish and other seafood (x)
  8) Legumes, nuts and seeds (x)
  9) Milk and milk products (x)
  10) Oils an fats 
  11) Sweets*
  12) Spices condiments and beverages	*/

g byte cereal = inlist(hh_g02, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 114, 115, 116, 117, 820, 827, 828, 829 ) == 1 & hh_g01 == 1
g byte starch = inlist(hh_g02, 201, 202, 203, 204, 205,206,207, 208, 209, 821, 822) == 1 & hh_g01 == 1
g byte veg =  inlist(hh_g02, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414) == 1 & hh_g01 == 1
g byte fruit =  inlist(hh_g02, 601, 602, 603, 604, 605,606,607, 608, 609, 610) == 1 & hh_g01 == 1
g byte meat =  inlist(hh_g02, 504, 505,506,507, 508, 509, 512, 824, 825) == 1 & hh_g01 == 1
g byte eggs =  inlist(hh_g02, 501, 823) == 1 & hh_g01 == 1
g byte fish =  inlist(hh_g02, 502, 503, 512, 513, 514, 515, 826) == 1 & hh_g01 == 1
g byte legumes =  inlist(hh_g02, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310) == 1 & hh_g01 == 1
g byte milk =  inlist(hh_g02, 701, 702, 705,706, 707, 708, 709) == 1 & hh_g01 == 1
g byte fats =  inlist(hh_g02, 703, 704) == 1 & hh_g01 == 1
g byte sweet =  inlist(hh_g02, 113, 801, 802, 815, 816, 817) == 1 & hh_g01 == 1
g byte cond =  inlist(hh_g02, 810, 811, 812, 813, 814, 901, 902, 903, 904, 905,906,907, 908, 909, 910, 911, 912, 913, 914, 915, 916) == 1 & hh_g01 == 1  
g byte meat2 =  inlist(hh_g02, 510, 511) == 1 & hh_g01 == 1
g byte oil =  inlist(hh_g02, 803) == 1 & hh_g01 == 1
g byte staples =  inlist(hh_g02, 101, 103, 106, 202,  207 ) == 1 & hh_g01 == 1

local dietLab cereal starch veg fruit meat eggs fish legumes milk fats sweet cond meat2 oil staples
foreach x of local dietLab {
	la var `x' "Consumed `x' in last 7 days"
	g `x'_days = hh_g02 if `x' == 1
	replace `x'_days = 0 if `x'_days == .
} 

* Check  households not reporting any consumption
egen tmp = rsum(cereal starch veg fruit meat eggs fish legumes milk fats sweet cond)
egen tmpsum = total(tmp), by(y2_hhid)
* for checking which HH are missing all consumption information
*br if tmpsum == 0


* Calculate food consumption score* Create variables to calculate Food Consumption Score 
g cerealFCS = cereal_days * 2
g starchFCS = starch_days * 2
g staplesFCS = staples_days * 2

g legumesFCS = legumes_days * 3

* Both weighted by 1
g vegFCS = veg_days
g fruitFCS = fruit_days

* meat, poultry, fish, eggs
g meatFCS = meat2_days * 4
g milkFCS = milk_days * 4

g sweetFCS = sweet_days * 0.5
g oilFCS = oil_days * 0.5

* Keep derived data (FCS & dietary diversity scores) and HHID
ds(hh_s* saq* ea_id), not
keep `r(varlist)'

* Collapse down to household level using max option, retain labels
qui include "$pathdo/copylabels.do"
ds(household_id), not
collapse (max) `r(varlist)', by(household_id)
qui include "$pathdo/attachlabels.do"

* Calculate two metrics
egen dietDiv = rsum(cereal starch veg fruit meat eggs fish legumes milk fats sweet cond)
la var dietDiv "Dietary diversity (12 food groups)"
recode dietDiv (0 = .) 
g year = 2013

egen FCS = rsum2(staplesFCS legumesFCS vegFCS fruitFCS meatFCS milkFCS sweetFCS oilFCS)
recode FCS (0 = .)

clonevar FCS_categ = FCS 
recode FCS_categ (0/21 = 0) (21.5/35 = 1) (35.1/53 = 2) (53/112 = 3)
lab def fcscat 0 "Poor" 1 " Borderline" 2 " Acceptable low" 3 "Acceptable high"
lab val FCS_categ fcscat
la var FCS_categ "Food consumption score category"
tab FCS_cat, mi

sa "$pathout/dietdiv_2013.dta", replace
pappend dietdiv_2011 dietdiv_2013 dietdiv_all

/* Merge into base, use the update option to not overwrite the data
clear
use "$pathout/hh_base.dta", clear
merge 1:1 household_id year using "$pathout/dietdiv_2012.dta", gen(_2011) update replace
merge 1:1 household_id2 year using "$pathout/dietdiv_2014.dta", gen(_2013) update 

drop _2012 _2014

sa "$pathout/dietdiv_all.dta", replace
*/


*Process data for each variable
* Cereal, Grains and Cereal Products
g mgaiwa = hh_g02 == 101
g fineflour = hh_g02 == 102
g branflour = hh_g02 == 103
g maizegrain = hh_g02 == 104
g greenmaize = hh_g02 == 105
g rice = hh_g02 == 106
g fingermillet = hh_g02 == 107
g sorghum = hh_g02 == 108
g pearlmillet = hh_g02 == 109
g wheatflour = hh_g02 == 110
g bread = hh_g02 == 111
g buns = hh_g02 == 112
g biscuits = hh_g02 == 113
g spaghetti = hh_g02 == 114
g breakfastereal = hh_g02 == 115
g infantcereals = hh_g02 == 116
g othercereal = hh_g02 == 117
* Roots, tubers, and Plantains
g cassava = hh_g02 == 201
g cassavaflour = hh_g02 == 202
g whitesweetpotato = hh_g02 == 203
g orangesweetpotato = hh_g02 == 204
g irishpotato = hh_g02 == 205
g potatocrisps = hh_g02 == 206
g plantain = hh_g02 == 207
g cocoyam = hh_g02 == 208
g otherroots = hh_g02 == 209
* Nuts and pulses
g beanwhite = hh_g02 == 301
g beanbrown = hh_g02 == 302
g pigeonpea = hh_g02 == 303
g groundnut = hh_g02 == 304
g groundnutflour = hh_g02 == 305
g soyabeanflour = hh_g02 == 306
g groundbean = hh_g02 == 307
g cowpea = hh_g02 == 308
g macademia = hh_g02 == 309
g othernuts = hh_g02 == 310
* Vegetables
g onion = hh_g02 == 401
g cabbage = hh_g02 == 402
g tanaposi = hh_g02 == 403
g nkhwani = hh_g02 == 404
g chinesecabbage = hh_g02 == 405
g greenleafyveg = hh_g02 == 406
g wildgreenleaves = hh_g02 == 407
g tomato = hh_g02 == 408
g cucumber = hh_g02 == 409
g pumpkin = hh_g02 == 410
g okra = hh_g02 == 411
g tinnedvegetables = hh_g02 == 412
g mushroom = hh_g02 == 413
g otherveg = hh_g02 == 414
* Meat, Fish and Animal products
g egg = hh_g02 == 501
g driedfish = hh_g02 == 502
g freshfish = hh_g02 == 503
g beef = hh_g02 == 504
g goat = hh_g02 == 505
g pork = hh_g02 == 506
g mutton = hh_g02 == 507
g chicken = hh_g02 == 508
g otherpoutry = hh_g02 == 509
g smallanimal = hh_g02 == 510
g otherinsects = hh_g02 == 511
g tinnedmeatfish = hh_g02 == 512
g smokedfish = hh_g02 == 513
g fishsoup = hh_g02 == 514
g othermeat = hh_g02 == 515
* Fruits
g mango = hh_g02 == 601
g banana = hh_g02 == 602
g citrus = hh_g02 == 603
g pineapple = hh_g02 == 604
g papaya = hh_g02 == 605
g guava = hh_g02 == 606
g avocado = hh_g02 == 607
g wildfruit = hh_g02 == 608
g apple = hh_g02 == 609
g otherfruits  = hh_g02 == 610
* Milk and Milk Products
g freshmilk = hh_g02 == 701
g powderedmilk = hh_g02 == 702
g margarine = hh_g02 == 703
g butter = hh_g02 == 704
g chambiko = hh_g02 == 705
g yoghurt = hh_g02 == 706
g cheese = hh_g02 == 707
g infantformula = hh_g02 == 708
g othermilk = hh_g02 == 709
* Sugar, Fats, and Oil
g sugar = hh_g02 == 801
g sugarcane = hh_g02 == 802
g cookingoil = hh_g02 == 803
g othersugar = hh_g02 == 804
* Spices & Miscelaneous 
g salt = hh_g02 == 810
g spices = hh_g02 == 811
g yeast = hh_g02 == 812
g tomatosauce = hh_g02 == 813
g hotsauce = hh_g02 == 814
g jam = hh_g02 == 815
g sweets = hh_g02 == 816
g honey = hh_g02 == 817
g otherspice = hh_g02 == 818
* Cooked Foods from Vendors
g maizeboiledorroastedvendor = hh_g02 == 820
g chipsvendor = hh_g02 == 821
g cassavaboiledvendor = hh_g02 == 822
g eggsboiledvendor = hh_g02 == 823
g chickenvendor = hh_g02 == 824
g meatvendor = hh_g02 == 825
g fishvendor = hh_g02 == 826
g mandazivendor = hh_g02 == 827
g samosavendor = hh_g02 == 828
g mealatrestaurant = hh_g02 == 829
g othercooked = hh_g02 == 830
* Beverages
g tea = hh_g02 == 901
g coffee = hh_g02 == 902
g cocoa = hh_g02 == 903
g squash = hh_g02 == 904
g fruitjuice = hh_g02 == 905
g freezes = hh_g02 == 906
g softdrinks = hh_g02 == 907
g chibuku = hh_g02 == 908
g bottledwater = hh_g02 == 909
g maheu = hh_g02 == 910
g bottledbeer = hh_g02 == 911
g thobwa = hh_g02 == 912
g traditionalbeer = hh_g02 == 913
g wine = hh_g02 == 914
g kachasu = hh_g02 == 915
g otherbeverage = hh_g02 == 916

* Question hh_g03a
* Cereal, Grains and Cereal Products
egen totmgaiwa = total(hh_g03a) if mgaiwa == 1, by(case_id) 
egen totfineflour = total(hh_g03a) if fineflour == 1, by(case_id) 
egen totbranflour = total(hh_g03a) if branflour == 1, by(case_id) 
egen totmaizegrain = total(hh_g03a) if maizegrain == 1, by(case_id) 
egen totgreenmaize = total(hh_g03a) if greenmaize == 1, by(case_id) 
egen totrice = total(hh_g03a) if rice == 1, by(case_id) 
egen totfingermillet = total(hh_g03a) if fingermillet== 1, by(case_id) 
egen totsorghum = total(hh_g03a) if sorghum== 1, by(case_id) 
egen totpearlmillet = total(hh_g03a) if pearlmillet == 1, by(case_id) 
egen totwheatflour = total(hh_g03a) if wheatflour == 1, by(case_id) 
egen totbread = total(hh_g03a) if bread == 1, by(case_id) 
egen totbuns = total(hh_g03a) if buns == 1, by(case_id) 
egen totbiscuits = total(hh_g03a) if biscuits == 1, by(case_id) 
egen totspaghetti = total(hh_g03a) if spaghetti== 1, by(case_id) 
egen totbreakfastereal = total(hh_g03a) if breakfastereal == 1, by(case_id) 
egen totinfantcereals = total(hh_g03a) if infantcereals  == 1, by(case_id) 
egen totothercereal = total(hh_g03a) if othercereal == 1, by(case_id) 
* Roots, tubers, and Plantains
egen totcassava = total(hh_g03a) if cassava  == 1, by(case_id) 
egen totcassavaflour = total(hh_g03a) if cassavaflour == 1, by(case_id) 
egen totwhitesweetpotato = total(hh_g03a) if whitesweetpotato == 1, by(case_id) 
egen totorangesweetpotato = total(hh_g03a) if orangesweetpotato == 1, by(case_id) 
egen totirishpotato = total(hh_g03a) if irishpotato == 1, by(case_id) 
egen totpotatocrisps = total(hh_g03a) if potatocrisps == 1, by(case_id) 
egen totplantain = total(hh_g03a) if plantain == 1, by(case_id) 
egen totcocoyam = total(hh_g03a) if cocoyam == 1, by(case_id) 
egen tototherroots = total(hh_g03a) if otherroots == 1, by(case_id) 
* Nuts and pulses
egen totbeanwhite = total(hh_g03a) if beanwhite == 1, by(case_id) 
egen totbeanbrown = total(hh_g03a) if beanbrown == 1, by(case_id) 
egen totpigeonpea = total(hh_g03a) if pigeonpea == 1, by(case_id) 
egen totgroundnut = total(hh_g03a) if groundnut == 1, by(case_id) 
egen totgroundnutflour = total(hh_g03a) if groundnutflour== 1, by(case_id) 
egen totsoyabeanflour = total(hh_g03a) if soyabeanflour == 1, by(case_id) 
egen totgroundbean = total(hh_g03a) if groundbean == 1, by(case_id) 
egen totcowpea = total(hh_g03a) if cowpea == 1, by(case_id) 
egen totmacademia = total(hh_g03a) if macademia == 1, by(case_id) 
egen totothernuts = total(hh_g03a) if othernuts== 1, by(case_id) 
* Vegetables
egen totonion = total(hh_g03a) if onion == 1, by(case_id) 
egen totcabbage = total(hh_g03a) if cabbage == 1, by(case_id) 
egen tottanaposi = total(hh_g03a) if tanaposi== 1, by(case_id) 
egen totnkhwani = total(hh_g03a) if nkhwani  == 1, by(case_id) 
egen totchinesecabbage = total(hh_g03a) if chinesecabbage == 1, by(case_id) 
egen totgreenleafyveg = total(hh_g03a) if greenleafyveg == 1, by(case_id) 
egen totwildgreenleaves = total(hh_g03a) if wildgreenleaves == 1, by(case_id) 
egen tottomato = total(hh_g03a) if tomato == 1, by(case_id) 
egen totcucumber = total(hh_g03a) if cucumber == 1, by(case_id) 
egen totpumpkin = total(hh_g03a) if pumpkin == 1, by(case_id) 
egen totokra = total(hh_g03a) if okra == 1, by(case_id) 
egen tottinnedvegetables = total(hh_g03a) if tinnedvegetables == 1, by(case_id) 
egen totmushroom = total(hh_g03a) if mushroom == 1, by(case_id) 
egen tototherveg = total(hh_g03a) if otherveg == 1, by(case_id) 
* Meat, Fish and Animal products
egen totegg = total(hh_g03a) if egg == 1, by(case_id) 
egen totdriedfish = total(hh_g03a) if driedfish  == 1, by(case_id) 
egen totfreshfish = total(hh_g03a) if freshfish == 1, by(case_id) 
egen totbeef = total(hh_g03a) if beef == 1, by(case_id) 
egen totgoat = total(hh_g03a) if goat == 1, by(case_id) 
egen totpork = total(hh_g03a) if pork == 1, by(case_id) 
egen totmutton = total(hh_g03a) if mutton == 1, by(case_id) 
egen totchicken = total(hh_g03a) if mgaiwa == 1, by(case_id) 
egen tototherpoutry = total(hh_g03a) if chicken == 1, by(case_id) 
egen totsmallanimal = total(hh_g03a) if smallanimal == 1, by(case_id) 
egen tototherinsects = total(hh_g03a) if otherinsects == 1, by(case_id) 
egen tottinnedmeatfish = total(hh_g03a) if tinnedmeatfish == 1, by(case_id) 
egen totsmokedfish = total(hh_g03a) if smokedfish == 1, by(case_id) 
egen totfishsoup = total(hh_g03a) if fishsoup == 1, by(case_id) 
egen totothermeat = total(hh_g03a) if othermeat == 1, by(case_id) 
* Fruits
egen totmango = total(hh_g03a) if mango== 1, by(case_id) 
egen totbanana = total(hh_g03a) if banana == 1, by(case_id) 
egen totcitrus = total(hh_g03a) if citrus == 1, by(case_id) 
egen totpineapple = total(hh_g03a) if pineapple == 1, by(case_id) 
egen totpapaya = total(hh_g03a) if papaya  == 1, by(case_id) 
egen totguava = total(hh_g03a) if guava == 1, by(case_id) 
egen totavocado = total(hh_g03a) if avocado == 1, by(case_id) 
egen totwildfruit = total(hh_g03a) if mgaiwa == 1, by(case_id) 
egen totapple = total(hh_g03a) if apple  == 1, by(case_id) 
egen tottherfruits  = total(hh_g03a) if otherfruits == 1, by(case_id) 
* Milk and Milk Products
egen totfreshmilk =total(hh_g03a) if freshmilk == 1, by(case_id) 
egen totpowderedmilk = total(hh_g03a) if powderedmilk  == 1, by(case_id) 
egen totmargarine = total(hh_g03a) if margarine == 1, by(case_id) 
egen totbutter = total(hh_g03a) if butter == 1, by(case_id) 
egen totchambiko = total(hh_g03a) if chambiko == 1, by(case_id) 
egen totyoghurt = total(hh_g03a) if yoghurt == 1, by(case_id) 
egen totcheese = total(hh_g03a) if cheese == 1, by(case_id) 
egen totinfantformula = total(hh_g03a) if mgaiwa == 1, by(case_id) 
egen totothermilk = total(hh_g03a) if infantformula == 1, by(case_id) 
* Sugar, Fats, and Oil
egen totsugar = total(hh_g03a) if sugar == 1, by(case_id) 
egen totsugarcane = total(hh_g03a) if sugarcane == 1, by(case_id) 
egen totcookingoil = total(hh_g03a) if cookingoil == 1, by(case_id) 
egen totothersugar = total(hh_g03a) if othersugar == 1, by(case_id) 
* Spices & Miscelaneous 
egen totsalt = total(hh_g03a) if salt == 1, by(case_id) 
egen totspices = total(hh_g03a) if spices == 1, by(case_id) 
egen totyeast = total(hh_g03a) if yeast == 1, by(case_id) 
egen tottomatosauce = total(hh_g03a) if tomatosauce == 1, by(case_id) 
egen tothotsauce = total(hh_g03a) if hotsauce == 1, by(case_id) 
egen totjam = total(hh_g03a) if jam == 1, by(case_id) 
egen totsweets = total(hh_g03a) if sweets == 1, by(case_id) 
egen tothoney = total(hh_g03a) if honey == 1, by(case_id) 
egen tototherspice = total(hh_g03a) if otherspice  == 1, by(case_id) 
* Cooked Foods from Vendors
egen totmaizeboiledorroastedvendor = total(hh_g03a) if maizeboiledorroastedvendor == 1, by(case_id) 
egen totchipsvendor = total(hh_g03a) if chipsvendor == 1, by(case_id) 
egen totcassavaboiledvendor = total(hh_g03a) if cassavaboiledvendor == 1, by(case_id) 
egen toteggsboiledvendor = total(hh_g03a) if eggsboiledvendor == 1, by(case_id) 
egen totchickenvendor = total(hh_g03a) if chickenvendor== 1, by(case_id) 
egen totmeatvendor = total(hh_g03a) if meatvendor == 1, by(case_id) 
egen totfishvendor = total(hh_g03a) if fishvendor == 1, by(case_id) 
egen totmandazivendor = total(hh_g03a) if mandazivendor == 1, by(case_id) 
egen totsamosavendor = total(hh_g03a) if samosavendor == 1, by(case_id) 
egen totmealatrestaurant = total(hh_g03a) if mealatrestaurant == 1, by(case_id) 
egen totothercooked = total(hh_g03a) if othercooked == 1, by(case_id) 
* Beverages
egen tottea = total(hh_g03a) if tea == 1, by(case_id) 
egen totcoffee = total(hh_g03a) if coffee == 1, by(case_id) 
egen totcocoa = total(hh_g03a) if cocoa == 1, by(case_id) 
egen totsquash = total(hh_g03a) if squash == 1, by(case_id) 
egen totfruitjuice = total(hh_g03a) if fruitjuice == 1, by(case_id) 
egen totfreezes = total(hh_g03a) if freezes== 1, by(case_id) 
egen totsoftdrinks = total(hh_g03a) if softdrinks == 1, by(case_id) 
egen totchibuku = total(hh_g03a) if chibuku == 1, by(case_id) 
egen totbottledwater = total(hh_g03a) if bottledwater == 1, by(case_id) 
egen totmaheu = total(hh_g03a) if maheu == 1, by(case_id) 
egen totbottledbeer = total(hh_g03a) if bottledbeer== 1, by(case_id) 
egen totthobwa = total(hh_g03a) if bottledbeer == 1, by(case_id) 
egen tottraditionalbeer = total(hh_g03a) if traditionalbeer == 1, by(case_id) 
egen totwine = total(hh_g03a) if wine == 1, by(case_id) 
egen totkachasu = total(hh_g03a) if kachasu == 1, by(case_id) 
egen tototherbeverage = total(hh_g03a) if otherbeverage == 1, by(case_id) 


*Question hh_g04a
* Cereal, Grains and Cereal Products
egen totmgaiwa = total(hh_g04a) if mgaiwa == 1, by(case_id) 
egen totfineflour = total(hh_g04a) if fineflour == 1, by(case_id) 
egen totbranflour = total(hh_g04a) if branflour == 1, by(case_id) 
egen totmaizegrain = total(hh_g04a) if maizegrain == 1, by(case_id) 
egen totgreenmaize = total(hh_g04a) if greenmaize == 1, by(case_id) 
egen totrice = total(hh_g04a) if rice == 1, by(case_id) 
egen totfingermillet = total(hh_g04a) if fingermillet== 1, by(case_id) 
egen totsorghum = total(hh_g04a) if sorghum== 1, by(case_id) 
egen totpearlmillet = total(hh_g04a) if pearlmillet == 1, by(case_id) 
egen totwheatflour = total(hh_g04a) if wheatflour == 1, by(case_id) 
egen totbread = total(hh_g04a) if bread == 1, by(case_id) 
egen totbuns = total(hh_g04a) if buns == 1, by(case_id) 
egen totbiscuits = total(hh_g04a) if biscuits == 1, by(case_id) 
egen totspaghetti = total(hh_g04a) if spaghetti== 1, by(case_id) 
egen totbreakfastereal = total(hh_g04a) if breakfastereal == 1, by(case_id) 
egen totinfantcereals = total(hh_g04a) if infantcereals  == 1, by(case_id) 
egen totothercereal = total(hh_g04a) if othercereal == 1, by(case_id) 
* Roots, tubers, and Plantains
egen totcassava = total(hh_g04a) if cassava  == 1, by(case_id) 
egen totcassavaflour = total(hh_g04a) if cassavaflour == 1, by(case_id) 
egen totwhitesweetpotato = total(hh_g04a) if whitesweetpotato == 1, by(case_id) 
egen totorangesweetpotato = total(hh_g04a) if orangesweetpotato == 1, by(case_id) 
egen totirishpotato = total(hh_g04a) if irishpotato == 1, by(case_id) 
egen totpotatocrisps = total(hh_g04a) if potatocrisps == 1, by(case_id) 
egen totplantain = total(hh_g04a) if plantain == 1, by(case_id) 
egen totcocoyam = total(hh_g04a) if cocoyam == 1, by(case_id) 
egen tototherroots = total(hh_g04a) if otherroots == 1, by(case_id) 
* Nuts and pulses
egen totbeanwhite = total(hh_g04a) if beanwhite == 1, by(case_id) 
egen totbeanbrown = total(hh_g04a) if beanbrown == 1, by(case_id) 
egen totpigeonpea = total(hh_g04a) if pigeonpea == 1, by(case_id) 
egen totgroundnut = total(hh_g04a) if groundnut == 1, by(case_id) 
egen totgroundnutflour = total(hh_g04a) if groundnutflour== 1, by(case_id) 
egen totsoyabeanflour = total(hh_g04a) if soyabeanflour == 1, by(case_id) 
egen totgroundbean = total(hh_g04a) if groundbean == 1, by(case_id) 
egen totcowpea = total(hh_g04a) if cowpea == 1, by(case_id) 
egen totmacademia = total(hh_g04a) if macademia == 1, by(case_id) 
egen totothernuts = total(hh_g04a) if othernuts== 1, by(case_id) 
* Vegetables
egen totonion = total(hh_g04a) if onion == 1, by(case_id) 
egen totcabbage = total(hh_g04a) if cabbage == 1, by(case_id) 
egen tottanaposi = total(hh_g04a) if tanaposi== 1, by(case_id) 
egen totnkhwani = total(hh_g04a) if nkhwani  == 1, by(case_id) 
egen totchinesecabbage = total(hh_g04a) if chinesecabbage == 1, by(case_id) 
egen totgreenleafyveg = total(hh_g04a) if greenleafyveg == 1, by(case_id) 
egen totwildgreenleaves = total(hh_g04a) if wildgreenleaves == 1, by(case_id) 
egen tottomato = total(hh_g04a) if tomato == 1, by(case_id) 
egen totcucumber = total(hh_g04a) if cucumber == 1, by(case_id) 
egen totpumpkin = total(hh_g04a) if pumpkin == 1, by(case_id) 
egen totokra = total(hh_g04a) if okra == 1, by(case_id) 
egen tottinnedvegetables = total(hh_g04a) if tinnedvegetables == 1, by(case_id) 
egen totmushroom = total(hh_g04a) if mushroom == 1, by(case_id) 
egen tototherveg = total(hh_g04a) if otherveg == 1, by(case_id) 
* Meat, Fish and Animal products
egen totegg = total(hh_g04a) if egg == 1, by(case_id) 
egen totdriedfish = total(hh_g04a) if driedfish  == 1, by(case_id) 
egen totfreshfish = total(hh_g04aa) if freshfish == 1, by(case_id) 
egen totbeef = total(hh_g04a) if beef == 1, by(case_id) 
egen totgoat = total(hh_g04a) if goat == 1, by(case_id) 
egen totpork = total(hh_g04a) if pork == 1, by(case_id) 
egen totmutton = total(hh_g04a) if mutton == 1, by(case_id) 
egen totchicken = total(hh_g04a) if mgaiwa == 1, by(case_id) 
egen tototherpoutry = total(hh_g04a) if chicken == 1, by(case_id) 
egen totsmallanimal = total(hh_g04a) if smallanimal == 1, by(case_id) 
egen tototherinsects = total(hh_g04a) if otherinsects == 1, by(case_id) 
egen tottinnedmeatfish = total(hh_g04a) if tinnedmeatfish == 1, by(case_id) 
egen totsmokedfish = total(hh_g04a) if smokedfish == 1, by(case_id) 
egen totfishsoup = total(hh_g04a) if fishsoup == 1, by(case_id) 
egen totothermeat = total(hh_g04a) if othermeat == 1, by(case_id) 
* Fruits
egen totmango = total(hh_g04a) if mango== 1, by(case_id) 
egen totbanana = total(hh_g04a) if banana == 1, by(case_id) 
egen totcitrus = total(hh_g04a) if citrus == 1, by(case_id) 
egen totpineapple = total(hh_g04a) if pineapple == 1, by(case_id) 
egen totpapaya = total(hh_g04a) if papaya  == 1, by(case_id) 
egen totguava = total(hh_g04a) if guava == 1, by(case_id) 
egen totavocado = total(hh_g04a) if avocado == 1, by(case_id) 
egen totwildfruit = total(hh_g04a) if mgaiwa == 1, by(case_id) 
egen totapple = total(hh_g04a) if apple  == 1, by(case_id) 
egen tottherfruits  = total(hh_g04a) if otherfruits == 1, by(case_id) 
* Milk and Milk Products
egen totfreshmilk =total(hh_g04a) if freshmilk == 1, by(case_id) 
egen totpowderedmilk = total(hh_g04a) if powderedmilk  == 1, by(case_id) 
egen totmargarine = total(hh_g04a) if margarine == 1, by(case_id) 
egen totbutter = total(hh_g04a) if butter == 1, by(case_id) 
egen totchambiko = total(hh_g04a) if chambiko == 1, by(case_id) 
egen totyoghurt = total(hh_g04a) if yoghurt == 1, by(case_id) 
egen totcheese = total(hh_g04a) if cheese == 1, by(case_id) 
egen totinfantformula = total(hh_g04a) if mgaiwa == 1, by(case_id) 
egen totothermilk = total(hh_g04a) if infantformula == 1, by(case_id) 
* Sugar, Fats, and Oil
egen totsugar = total(hh_g04a) if sugar == 1, by(case_id) 
egen totsugarcane = total(hh_g04a) if sugarcane == 1, by(case_id) 
egen totcookingoil = total(hh_g04a) if cookingoil == 1, by(case_id) 
egen totothersugar = total(hh_g04a) if othersugar == 1, by(case_id) 
* Spices & Miscelaneous 
egen totsalt = total(hh_g04a) if salt == 1, by(case_id) 
egen totspices = total(hh_g04a) if spices == 1, by(case_id) 
egen totyeast = total(hh_g04a) if yeast == 1, by(case_id) 
egen tottomatosauce = total(hh_g04a) if tomatosauce == 1, by(case_id) 
egen tothotsauce = total(hh_g04a) if hotsauce == 1, by(case_id) 
egen totjam = total(hh_g04a) if jam == 1, by(case_id) 
egen totsweets = total(hh_g04a) if sweets == 1, by(case_id) 
egen tothoney = total(hh_g04a) if honey == 1, by(case_id) 
egen tototherspice = total(hh_g04a) if otherspice  == 1, by(case_id) 
* Cooked Foods from Vendors
egen totmaizeboiledorroastedvendor = total(hh_g04a) if maizeboiledorroastedvendor == 1, by(case_id) 
egen totchipsvendor = total(hh_g04a) if chipsvendor == 1, by(case_id) 
egen totcassavaboiledvendor = total(hh_g04a) if cassavaboiledvendor == 1, by(case_id) 
egen toteggsboiledvendor = total(hh_g04a) if eggsboiledvendor == 1, by(case_id) 
egen totchickenvendor = total(hh_g04a) if chickenvendor== 1, by(case_id) 
egen totmeatvendor = total(hh_g04a) if meatvendor == 1, by(case_id) 
egen totfishvendor = total(hh_g04a) if fishvendor == 1, by(case_id) 
egen totmandazivendor = total(hh_g04a) if mandazivendor == 1, by(case_id) 
egen totsamosavendor = total(hh_g04a) if samosavendor == 1, by(case_id) 
egen totmealatrestaurant = total(hh_g04a) if mealatrestaurant == 1, by(case_id) 
egen totothercooked = total(hh_g04a) if othercooked == 1, by(case_id) 
* Beverages
egen tottea = total(hh_g04a) if tea == 1, by(case_id) 
egen totcoffee = total(hh_g04a) if coffee == 1, by(case_id) 
egen totcocoa = total(hh_g03a) if cocoa == 1, by(case_id) 
egen totsquash = total(hh_g04a) if squash == 1, by(case_id) 
egen totfruitjuice = total(hh_g04a) if fruitjuice == 1, by(case_id) 
egen totfreezes = total(hh_g04a) if freezes== 1, by(case_id) 
egen totsoftdrinks = total(hh_g04a) if softdrinks == 1, by(case_id) 
egen totchibuku = total(hh_g04a) if chibuku == 1, by(case_id) 
egen totbottledwater = total(hh_g04a) if bottledwater == 1, by(case_id) 
egen totmaheu = total(hh_g04a) if maheu == 1, by(case_id) 
egen totbottledbeer = total(hh_g04a) if bottledbeer== 1, by(case_id) 
egen totthobwa = total(hh_g04a) if bottledbeer == 1, by(case_id) 
egen tottraditionalbeer = total(hh_g04a) if traditionalbeer == 1, by(case_id) 
egen totwine = total(hh_g04a) if wine == 1, by(case_id) 
egen totkachasu = total(hh_g04a) if kachasu == 1, by(case_id) 
egen tototherbeverage = total(hh_g04a) if otherbeverage == 1, by(case_id) 

*Question hh_g05
* Cereal, Grains and Cereal Products
egen totmgaiwa = total(hh_g05) if mgaiwa == 1, by(case_id) 
egen totfineflour = total(hh_g05) if fineflour == 1, by(case_id) 
egen totbranflour = total(hh_g05) if branflour == 1, by(case_id) 
egen totmaizegrain = total(hh_g05 if maizegrain == 1, by(case_id) 
egen totgreenmaize = total(hh_g05) if greenmaize == 1, by(case_id) 
egen totrice = total(hh_g05) if rice == 1, by(case_id) 
egen totfingermillet = total(hh_g05) if fingermillet== 1, by(case_id) 
egen totsorghum = total(hh_g05) if sorghum== 1, by(case_id) 
egen totpearlmillet = total(hh_g05) if pearlmillet == 1, by(case_id) 
egen totwheatflour = total(hh_g05) if wheatflour == 1, by(case_id) 
egen totbread = total(hh_g05) if bread == 1, by(case_id) 
egen totbuns = total(hh_g05) if buns == 1, by(case_id) 
egen totbiscuits = total(hh_g05) if biscuits == 1, by(case_id) 
egen totspaghetti = total(hh_g05) if spaghetti== 1, by(case_id) 
egen totbreakfastereal = total(hh_g05) if breakfastereal == 1, by(case_id) 
egen totinfantcereals = total(hh_g05) if infantcereals  == 1, by(case_id) 
egen totothercereal = total(hh_g05) if othercereal == 1, by(case_id) 
* Roots, tubers, and Plantains
egen totcassava = total(hh_g05) if cassava  == 1, by(case_id) 
egen totcassavaflour = total(hh_g05) if cassavaflour == 1, by(case_id) 
egen totwhitesweetpotato = total(hh_g05) if whitesweetpotato == 1, by(case_id) 
egen totorangesweetpotato = total(hh_g05) if orangesweetpotato == 1, by(case_id) 
egen totirishpotato = total(hh_g05) if irishpotato == 1, by(case_id) 
egen totpotatocrisps = total(hh_g05) if potatocrisps == 1, by(case_id) 
egen totplantain = total(hh_g05) if plantain == 1, by(case_id) 
egen totcocoyam = total(hh_g05) if cocoyam == 1, by(case_id) 
egen tototherroots = total(hh_g05) if otherroots == 1, by(case_id) 
* Nuts and pulses
egen totbeanwhite = total(hh_g05) if beanwhite == 1, by(case_id) 
egen totbeanbrown = total(hh_g05) if beanbrown == 1, by(case_id) 
egen totpigeonpea = total(hh_g05) if pigeonpea == 1, by(case_id) 
egen totgroundnut = total(hh_g05) if groundnut == 1, by(case_id) 
egen totgroundnutflour = total(hh_g05) if groundnutflour== 1, by(case_id) 
egen totsoyabeanflour = total(hh_g05) if soyabeanflour == 1, by(case_id) 
egen totgroundbean = total(hh_g05 if groundbean == 1, by(case_id) 
egen totcowpea = total(hh_g05) if cowpea == 1, by(case_id) 
egen totmacademia = total(hh_g05) if macademia == 1, by(case_id) 
egen totothernuts = total(hh_g05) if othernuts== 1, by(case_id) 
* Vegetables
egen totonion = total(hh_g05) if onion == 1, by(case_id) 
egen totcabbage = total(hh_g05) if cabbage == 1, by(case_id) 
egen tottanaposi = total(hh_g05) if tanaposi== 1, by(case_id) 
egen totnkhwani = total(hh_g05) if nkhwani  == 1, by(case_id) 
egen totchinesecabbage = total(hh_g05) if chinesecabbage == 1, by(case_id) 
egen totgreenleafyveg = total(hh_g05) if greenleafyveg == 1, by(case_id) 
egen totwildgreenleaves = total(hh_g05) if wildgreenleaves == 1, by(case_id) 
egen tottomato = total(hh_g05) if tomato == 1, by(case_id) 
egen totcucumber = total(hh_g05) if cucumber == 1, by(case_id) 
egen totpumpkin = total(hh_g05) if pumpkin == 1, by(case_id) 
egen totokra = total(hh_g05) if okra == 1, by(case_id) 
egen tottinnedvegetables = total(hh_g05) if tinnedvegetables == 1, by(case_id) 
egen totmushroom = total(hh_g05) if mushroom == 1, by(case_id) 
egen tototherveg = total(hh_g05) if otherveg == 1, by(case_id) 
* Meat, Fish and Animal products
egen totegg = total(hh_g05) if egg == 1, by(case_id) 
egen totdriedfish = total(hh_g05) if driedfish  == 1, by(case_id) 
egen totfreshfish = total(hh_g05) if freshfish == 1, by(case_id) 
egen totbeef = total(hh_g05) if beef == 1, by(case_id) 
egen totgoat = total(hh_g05) if goat == 1, by(case_id) 
egen totpork = total(hh_g05) if pork == 1, by(case_id) 
egen totmutton = total(hh_g05) if mutton == 1, by(case_id) 
egen totchicken = total(hh_g05) if mgaiwa == 1, by(case_id) 
egen tototherpoutry = total(hh_g05) if chicken == 1, by(case_id) 
egen totsmallanimal = total(hh_g05) if smallanimal == 1, by(case_id) 
egen tototherinsects = total(hh_g05) if otherinsects == 1, by(case_id) 
egen tottinnedmeatfish = total(hh_g05) if tinnedmeatfish == 1, by(case_id) 
egen totsmokedfish = total(hh_g05) if smokedfish == 1, by(case_id) 
egen totfishsoup = total(hh_g05) if fishsoup == 1, by(case_id) 
egen totothermeat = total(hh_g05) if othermeat == 1, by(case_id) 
* Fruits
egen totmango = total(hh_g05) if mango== 1, by(case_id) 
egen totbanana = total(hh_g05) if banana == 1, by(case_id) 
egen totcitrus = total(hh_g05 if citrus == 1, by(case_id) 
egen totpineapple = total(hh_g05) if pineapple == 1, by(case_id) 
egen totpapaya = total(hh_g05) if papaya  == 1, by(case_id) 
egen totguava = total(hh_g05) if guava == 1, by(case_id) 
egen totavocado = total(hh_g05) if avocado == 1, by(case_id) 
egen totwildfruit = total(hh_g05) if mgaiwa == 1, by(case_id) 
egen totapple = total(hh_g05) if apple  == 1, by(case_id) 
egen tottherfruits  = total(hh_g05) if otherfruits == 1, by(case_id) 
* Milk and Milk Products
egen totfreshmilk =total(hh_g05) if freshmilk == 1, by(case_id) 
egen totpowderedmilk = total(hh_g05) if powderedmilk  == 1, by(case_id) 
egen totmargarine = total(hh_g05) if margarine == 1, by(case_id) 
egen totbutter = total(hh_g05) if butter == 1, by(case_id) 
egen totchambiko = total(hh_g05) if chambiko == 1, by(case_id) 
egen totyoghurt = total(hh_g05) if yoghurt == 1, by(case_id) 
egen totcheese = total(hh_g05) if cheese == 1, by(case_id) 
egen totinfantformula = total(hh_g05) if mgaiwa == 1, by(case_id) 
egen totothermilk = total(hh_g05) if infantformula == 1, by(case_id) 
* Sugar, Fats, and Oil
egen totsugar = total(hh_g05) if sugar == 1, by(case_id) 
egen totsugarcane = total(hh_g05) if sugarcane == 1, by(case_id) 
egen totcookingoil = total(hh_g05) if cookingoil == 1, by(case_id) 
egen totothersugar = total(hh_g05) if othersugar == 1, by(case_id) 
* Spices & Miscelaneous 
egen totsalt = total(hh_g05) if salt == 1, by(case_id) 
egen totspices = total(hh_g05) if spices == 1, by(case_id) 
egen totyeast = total(hh_g05) if yeast == 1, by(case_id) 
egen tottomatosauce = total(hh_g05) if tomatosauce == 1, by(case_id) 
egen tothotsauce = total(hh_g05) if hotsauce == 1, by(case_id) 
egen totjam = total(hh_g05) if jam == 1, by(case_id) 
egen totsweets = total(hh_g05) if sweets == 1, by(case_id) 
egen tothoney = total(hh_g05) if honey == 1, by(case_id) 
egen tototherspice = total(hh_g05) if otherspice  == 1, by(case_id) 
* Cooked Foods from Vendors
egen totmaizeboiledorroastedvendor = total(hh_g05) if maizeboiledorroastedvendor == 1, by(case_id) 
egen totchipsvendor = total(hh_g05) if chipsvendor == 1, by(case_id) 
egen totcassavaboiledvendor = total(hh_g05) if cassavaboiledvendor == 1, by(case_id) 
egen toteggsboiledvendor = total(hh_g05) if eggsboiledvendor == 1, by(case_id) 
egen totchickenvendor = total(hh_g05) if chickenvendor== 1, by(case_id) 
egen totmeatvendor = total(hh_g05) if meatvendor == 1, by(case_id) 
egen totfishvendor = total(hh_g05) if fishvendor == 1, by(case_id) 
egen totmandazivendor = total(hh_g05) if mandazivendor == 1, by(case_id) 
egen totsamosavendor = total(hh_g05) if samosavendor == 1, by(case_id) 
egen totmealatrestaurant = total(hh_g05) if mealatrestaurant == 1, by(case_id) 
egen totothercooked = total(hh_g05) if othercooked == 1, by(case_id) 
* Beverages
egen tottea = total(hh_g05) if tea == 1, by(case_id) 
egen totcoffee = total(hh_g05) if coffee == 1, by(case_id) 
egen totcocoa = total(hh_g05) if cocoa == 1, by(case_id) 
egen totsquash = total(hh_g05) if squash == 1, by(case_id) 
egen totfruitjuice = total(hh_g05) if fruitjuice == 1, by(case_id) 
egen totfreezes = total(hh_g05) if freezes== 1, by(case_id) 
egen totsoftdrinks = total(hh_g05) if softdrinks == 1, by(case_id) 
egen totchibuku = total(hh_g05) if chibuku == 1, by(case_id) 
egen totbottledwater = total(hh_g05) if bottledwater == 1, by(case_id) 
egen totmaheu = total(hh_g05) if maheu == 1, by(case_id) 
egen totbottledbeer = total(hh_g05) if bottledbeer== 1, by(case_id) 
egen totthobwa = total(hh_g05) if bottledbeer == 1, by(case_id) 
egen tottraditionalbeer = total(hh_g05) if traditionalbeer == 1, by(case_id) 
egen totwine = total(hh_g05) if wine == 1, by(case_id) 
egen totkachasu = total(hh_g05) if kachasu == 1, by(case_id) 
egen tototherbeverage = total(hh_g05) if otherbeverage == 1, by(case_id) 

*Question hh_g06a
* Cereal, Grains and Cereal Products
egen totmgaiwa = total(hh_g06a) if mgaiwa == 1, by(case_id) 
egen totfineflour = total(hh_g06a) if fineflour == 1, by(case_id) 
egen totbranflour = total(hh_g06a) if branflour == 1, by(case_id) 
egen totmaizegrain = total(hh_g06a) if maizegrain == 1, by(case_id) 
egen totgreenmaize = total(hh_g06a) if greenmaize == 1, by(case_id) 
egen totrice = total(hh_g06a) if rice == 1, by(case_id) 
egen totfingermillet = total(hh_g06a) if fingermillet== 1, by(case_id) 
egen totsorghum = total(hh_g06a) if sorghum== 1, by(case_id) 
egen totpearlmillet = total(hh_g06a) if pearlmillet == 1, by(case_id) 
egen totwheatflour = total(hh_g06a) if wheatflour == 1, by(case_id) 
egen totbread = total(hh_g06a) if bread == 1, by(case_id) 
egen totbuns = total(hh_g06a) if buns == 1, by(case_id) 
egen totbiscuits = total(hh_g06a) if biscuits == 1, by(case_id) 
egen totspaghetti = total(hh_g06a) if spaghetti== 1, by(case_id) 
egen totbreakfastereal = total(hh_g06a) if breakfastereal == 1, by(case_id) 
egen totinfantcereals = total(hh_g06a) if infantcereals  == 1, by(case_id) 
egen totothercereal = total(hh_g06a) if othercereal == 1, by(case_id) 
* Roots, tubers, and Plantains
egen totcassava = total(hh_g06a) if cassava  == 1, by(case_id) 
egen totcassavaflour = total(hh_g06a) if cassavaflour == 1, by(case_id) 
egen totwhitesweetpotato = total(hh_g06a) if whitesweetpotato == 1, by(case_id) 
egen totorangesweetpotato = total(hh_g06a) if orangesweetpotato == 1, by(case_id) 
egen totirishpotato = total(hh_g06a) if irishpotato == 1, by(case_id) 
egen totpotatocrisps = total(hh_g06a) if potatocrisps == 1, by(case_id) 
egen totplantain = total(hh_g06a) if plantain == 1, by(case_id) 
egen totcocoyam = total(hh_g06a) if cocoyam == 1, by(case_id) 
egen tototherroots = total(hh_g06a) if otherroots == 1, by(case_id) 
* Nuts and pulses
egen totbeanwhite = total(hh_g06a) if beanwhite == 1, by(case_id) 
egen totbeanbrown = total(hh_g06a) if beanbrown == 1, by(case_id) 
egen totpigeonpea = total(hh_g06a) if pigeonpea == 1, by(case_id) 
egen totgroundnut = total(hh_g06a) if groundnut == 1, by(case_id) 
egen totgroundnutflour = total(hh_g06a) if groundnutflour== 1, by(case_id) 
egen totsoyabeanflour = total(hh_g06a) if soyabeanflour == 1, by(case_id) 
egen totgroundbean = total(hh_g06a) if groundbean == 1, by(case_id) 
egen totcowpea = total(hh_g06a) if cowpea == 1, by(case_id) 
egen totmacademia = total(hh_g06a) if macademia == 1, by(case_id) 
egen totothernuts = total(hh_g06a) if othernuts== 1, by(case_id) 
* Vegetables
egen totonion = total(hh_g06a) if onion == 1, by(case_id) 
egen totcabbage = total(hh_g06a) if cabbage == 1, by(case_id) 
egen tottanaposi = total(hh_g06a) if tanaposi== 1, by(case_id) 
egen totnkhwani = total(hh_g06a) if nkhwani  == 1, by(case_id) 
egen totchinesecabbage = total(hh_g06a) if chinesecabbage == 1, by(case_id) 
egen totgreenleafyveg = total(hh_g06a) if greenleafyveg == 1, by(case_id) 
egen totwildgreenleaves = total(hh_g06a) if wildgreenleaves == 1, by(case_id) 
egen tottomato = total(hh_g06a) if tomato == 1, by(case_id) 
egen totcucumber = total(hh_g06a) if cucumber == 1, by(case_id) 
egen totpumpkin = total(hh_g06a) if pumpkin == 1, by(case_id) 
egen totokra = total(hh_g06a) if okra == 1, by(case_id) 
egen tottinnedvegetables = total(hh_g06a) if tinnedvegetables == 1, by(case_id) 
egen totmushroom = total(hh_g06a) if mushroom == 1, by(case_id) 
egen tototherveg = total(hh_g06a) if otherveg == 1, by(case_id) 
* Meat, Fish and Animal products
egen totegg = total(hh_g03a) if egg == 1, by(case_id) 
egen totdriedfish = total(hh_g06a) if driedfish  == 1, by(case_id) 
egen totfreshfish = total(hh_g06a) if freshfish == 1, by(case_id) 
egen totbeef = total(hh_g06a) if beef == 1, by(case_id) 
egen totgoat = total(hh_g06a) if goat == 1, by(case_id) 
egen totpork = total(hh_g06a) if pork == 1, by(case_id) 
egen totmutton = total(hh_g06a) if mutton == 1, by(case_id) 
egen totchicken = total(hh_g06a) if mgaiwa == 1, by(case_id) 
egen tototherpoutry = total(hh_g06a) if chicken == 1, by(case_id) 
egen totsmallanimal = total(hh_g06a) if smallanimal == 1, by(case_id) 
egen tototherinsects = total(hh_g06a) if otherinsects == 1, by(case_id) 
egen tottinnedmeatfish = total(hh_g06a) if tinnedmeatfish == 1, by(case_id) 
egen totsmokedfish = total(hh_g06a) if smokedfish == 1, by(case_id) 
egen totfishsoup = total(hh_g06a) if fishsoup == 1, by(case_id) 
egen totothermeat = total(hh_g06a) if othermeat == 1, by(case_id) 
* Fruits
egen totmango = total(hh_g06a) if mango== 1, by(case_id) 
egen totbanana = total(hh_g06a) if banana == 1, by(case_id) 
egen totcitrus = total(hh_g06a) if citrus == 1, by(case_id) 
egen totpineapple = total(hh_g06a) if pineapple == 1, by(case_id) 
egen totpapaya = total(hh_g06a) if papaya  == 1, by(case_id) 
egen totguava = total(hh_g06a) if guava == 1, by(case_id) 
egen totavocado = total(hh_g06a) if avocado == 1, by(case_id) 
egen totwildfruit = total(hh_g06a) if mgaiwa == 1, by(case_id) 
egen totapple = total(hh_g06a) if apple  == 1, by(case_id) 
egen tottherfruits  = total(hh_g06a) if otherfruits == 1, by(case_id) 
* Milk and Milk Products
egen totfreshmilk =total(hh_g06a) if freshmilk == 1, by(case_id) 
egen totpowderedmilk = total(hh_g06a) if powderedmilk  == 1, by(case_id) 
egen totmargarine = total(hh_g06a) if margarine == 1, by(case_id) 
egen totbutter = total(hh_g06a) if butter == 1, by(case_id) 
egen totchambiko = total(hh_g06a) if chambiko == 1, by(case_id) 
egen totyoghurt = total(hh_g06a) if yoghurt == 1, by(case_id) 
egen totcheese = total(hh_g06a) if cheese == 1, by(case_id) 
egen totinfantformula = total(hh_g06a) if mgaiwa == 1, by(case_id) 
egen totothermilk = total(hh_g06a) if infantformula == 1, by(case_id) 
* Sugar, Fats, and Oil
egen totsugar = total(hh_g06a) if sugar == 1, by(case_id) 
egen totsugarcane = total(hh_g06a) if sugarcane == 1, by(case_id) 
egen totcookingoil = total(hh_g06a) if cookingoil == 1, by(case_id) 
egen totothersugar = total(hh_g06a) if othersugar == 1, by(case_id) 
* Spices & Miscelaneous 
egen totsalt = total(hh_g06a) if salt == 1, by(case_id) 
egen totspices = total(hh_g06a) if spices == 1, by(case_id) 
egen totyeast = total(hh_g06a) if yeast == 1, by(case_id) 
egen tottomatosauce = total(hh_g06a) if tomatosauce == 1, by(case_id) 
egen tothotsauce = total(hh_g06a) if hotsauce == 1, by(case_id) 
egen totjam = total(hh_g06a) if jam == 1, by(case_id) 
egen totsweets = total(hh_g06a) if sweets == 1, by(case_id) 
egen tothoney = total(hh_g06a) if honey == 1, by(case_id) 
egen tototherspice = total(hh_g06a) if otherspice  == 1, by(case_id) 
* Cooked Foods from Vendors
egen totmaizeboiledorroastedvendor = total(hh_g06a) if maizeboiledorroastedvendor == 1, by(case_id) 
egen totchipsvendor = total(hh_g06a) if chipsvendor == 1, by(case_id) 
egen totcassavaboiledvendor = total(hh_g06a) if cassavaboiledvendor == 1, by(case_id) 
egen toteggsboiledvendor = total(hh_g06a) if eggsboiledvendor == 1, by(case_id) 
egen totchickenvendor = total(hh_g06a) if chickenvendor== 1, by(case_id) 
egen totmeatvendor = total(hh_g06a) if meatvendor == 1, by(case_id) 
egen totfishvendor = total(hh_g06a) if fishvendor == 1, by(case_id) 
egen totmandazivendor = total(hh_g06a) if mandazivendor == 1, by(case_id) 
egen totsamosavendor = total(hh_g06a) if samosavendor == 1, by(case_id) 
egen totmealatrestaurant = total(hh_g06a) if mealatrestaurant == 1, by(case_id) 
egen totothercooked = total(hh_g06a) if othercooked == 1, by(case_id) 
* Beverages
egen tottea = total(hh_g06a) if tea == 1, by(case_id) 
egen totcoffee = total(hh_g03a) if coffee == 1, by(case_id) 
egen totcocoa = total(hh_g06a) if cocoa == 1, by(case_id) 
egen totsquash = total(hh_g06a) if squash == 1, by(case_id) 
egen totfruitjuice = total(hh_g06a) if fruitjuice == 1, by(case_id) 
egen totfreezes = total(hh_g06a) if freezes== 1, by(case_id) 
egen totsoftdrinks = total(hh_g06a) if softdrinks == 1, by(case_id) 
egen totchibuku = total(hh_g03a) if chibuku == 1, by(case_id) 
egen totbottledwater = total(hh_g06a) if bottledwater == 1, by(case_id) 
egen totmaheu = total(hh_g06a) if maheu == 1, by(case_id) 
egen totbottledbeer = total(hh_g06a) if bottledbeer== 1, by(case_id) 
egen totthobwa = total(hh_g06a) if bottledbeer == 1, by(case_id) 
egen tottraditionalbeer = total(hh_g06a) if traditionalbeer == 1, by(case_id) 
egen totwine = total(hh_g06a) if wine == 1, by(case_id) 
egen totkachasu = total(hh_g06a) if kachasu == 1, by(case_id) 
egen tototherbeverage = total(hh_g06a) if otherbeverage == 1, by(case_id) 

*Question hh_g07a
* Cereal, Grains and Cereal Products
egen totmgaiwa = total(hh_g07a) if mgaiwa == 1, by(case_id) 
egen totfineflour = total(hh_g07a) if fineflour == 1, by(case_id) 
egen totbranflour = total(hh_g07a) if branflour == 1, by(case_id) 
egen totmaizegrain = total(hh_g07a) if maizegrain == 1, by(case_id) 
egen totgreenmaize = total(hh_g07a) if greenmaize == 1, by(case_id) 
egen totrice = total(hh_g07a) if rice == 1, by(case_id) 
egen totfingermillet = total(hh_g07a) if fingermillet== 1, by(case_id) 
egen totsorghum = total(hh_g07a) if sorghum== 1, by(case_id) 
egen totpearlmillet = total(hh_g07a) if pearlmillet == 1, by(case_id) 
egen totwheatflour = total(hh_g07a) if wheatflour == 1, by(case_id) 
egen totbread = total(hh_g07a) if bread == 1, by(case_id) 
egen totbuns = total(hh_g07a) if buns == 1, by(case_id) 
egen totbiscuits = total(hh_g07a) if biscuits == 1, by(case_id) 
egen totspaghetti = total(hh_g07a) if spaghetti== 1, by(case_id) 
egen totbreakfastereal = total(hh_g07a) if breakfastereal == 1, by(case_id) 
egen totinfantcereals = total(hh_g07a) if infantcereals  == 1, by(case_id) 
egen totothercereal = total(hh_g07a) if othercereal == 1, by(case_id) 
* Roots, tubers, and Plantains
egen totcassava = total(hh_g07a) if cassava  == 1, by(case_id) 
egen totcassavaflour = total(hh_g07a) if cassavaflour == 1, by(case_id) 
egen totwhitesweetpotato = total(hh_g07a) if whitesweetpotato == 1, by(case_id) 
egen totorangesweetpotato = total(hh_g07a) if orangesweetpotato == 1, by(case_id) 
egen totirishpotato = total(hh_g07a) if irishpotato == 1, by(case_id) 
egen totpotatocrisps = total(hh_g07a) if potatocrisps == 1, by(case_id) 
egen totplantain = total(hh_g07a) if plantain == 1, by(case_id) 
egen totcocoyam = total(hh_g07a) if cocoyam == 1, by(case_id) 
egen tototherroots = total(hh_g07a) if otherroots == 1, by(case_id) 
* Nuts and pulses
egen totbeanwhite = total(hh_g07a) if beanwhite == 1, by(case_id) 
egen totbeanbrown = total(hh_g07a) if beanbrown == 1, by(case_id) 
egen totpigeonpea = total(hh_g07a) if pigeonpea == 1, by(case_id) 
egen totgroundnut = total(hh_g07a) if groundnut == 1, by(case_id) 
egen totgroundnutflour = total(hh_g07a) if groundnutflour== 1, by(case_id) 
egen totsoyabeanflour = total(hh_g07a) if soyabeanflour == 1, by(case_id) 
egen totgroundbean = total(hh_g07a) if groundbean == 1, by(case_id) 
egen totcowpea = total(hh_g07a) if cowpea == 1, by(case_id) 
egen totmacademia = total(hh_g03a) if macademia == 1, by(case_id) 
egen totothernuts = total(hh_g07a) if othernuts== 1, by(case_id) 
* Vegetables
egen totonion = total(hh_g07a) if onion == 1, by(case_id) 
egen totcabbage = total(hh_g07a) if cabbage == 1, by(case_id) 
egen tottanaposi = total(hh_g07a) if tanaposi== 1, by(case_id) 
egen totnkhwani = total(hh_g07a) if nkhwani  == 1, by(case_id) 
egen totchinesecabbage = total(hh_g07a) if chinesecabbage == 1, by(case_id) 
egen totgreenleafyveg = total(hh_g07a) if greenleafyveg == 1, by(case_id) 
egen totwildgreenleaves = total(hh_g07a) if wildgreenleaves == 1, by(case_id) 
egen tottomato = total(hh_g07a) if tomato == 1, by(case_id) 
egen totcucumber = total(hh_g07a) if cucumber == 1, by(case_id) 
egen totpumpkin = total(hh_g07a) if pumpkin == 1, by(case_id) 
egen totokra = total(hh_g07a) if okra == 1, by(case_id) 
egen tottinnedvegetables = total(hh_g07a) if tinnedvegetables == 1, by(case_id) 
egen totmushroom = total(hh_g07a) if mushroom == 1, by(case_id) 
egen tototherveg = total(hh_g07a) if otherveg == 1, by(case_id) 
* Meat, Fish and Animal products
egen totegg = total(hh_g07a) if egg == 1, by(case_id) 
egen totdriedfish = total(hh_g07a) if driedfish  == 1, by(case_id) 
egen totfreshfish = total(hh_g07a) if freshfish == 1, by(case_id) 
egen totbeef = total(hh_g07a) if beef == 1, by(case_id) 
egen totgoat = total(hh_g07a) if goat == 1, by(case_id) 
egen totpork = total(hh_g07a) if pork == 1, by(case_id) 
egen totmutton = total(hh_g07a) if mutton == 1, by(case_id) 
egen totchicken = total(hh_g07a) if mgaiwa == 1, by(case_id) 
egen tototherpoutry = total(hh_g07a) if chicken == 1, by(case_id) 
egen totsmallanimal = total(hh_g07a) if smallanimal == 1, by(case_id) 
egen tototherinsects = total(hh_g07a) if otherinsects == 1, by(case_id) 
egen tottinnedmeatfish = total(hh_g07a) if tinnedmeatfish == 1, by(case_id) 
egen totsmokedfish = total(hh_g07a) if smokedfish == 1, by(case_id) 
egen totfishsoup = total(hh_g07a) if fishsoup == 1, by(case_id) 
egen totothermeat = total(hh_g07a) if othermeat == 1, by(case_id) 
* Fruits
egen totmango = total(hh_g07a) if mango== 1, by(case_id) 
egen totbanana = total(hh_g07a) if banana == 1, by(case_id) 
egen totcitrus = total(hh_g07a) if citrus == 1, by(case_id) 
egen totpineapple = total(hh_g07a) if pineapple == 1, by(case_id) 
egen totpapaya = total(hh_g07a) if papaya  == 1, by(case_id) 
egen totguava = total(hh_g07a) if guava == 1, by(case_id) 
egen totavocado = total(hh_g07a) if avocado == 1, by(case_id) 
egen totwildfruit = total(hh_g07a) if mgaiwa == 1, by(case_id) 
egen totapple = total(hh_g07a) if apple  == 1, by(case_id) 
egen tottherfruits  = total(hh_g07a) if otherfruits == 1, by(case_id) 
* Milk and Milk Products
egen totfreshmilk =total(hh_g07a) if freshmilk == 1, by(case_id) 
egen totpowderedmilk = total(hh_g07a) if powderedmilk  == 1, by(case_id) 
egen totmargarine = total(hh_g07a) if margarine == 1, by(case_id) 
egen totbutter = total(hh_g07a) if butter == 1, by(case_id) 
egen totchambiko = total(hh_g07a) if chambiko == 1, by(case_id) 
egen totyoghurt = total(hh_g07a) if yoghurt == 1, by(case_id) 
egen totcheese = total(hh_g07a) if cheese == 1, by(case_id) 
egen totinfantformula = total(hh_g07a) if mgaiwa == 1, by(case_id) 
egen totothermilk = total(hh_g07a) if infantformula == 1, by(case_id) 
* Sugar, Fats, and Oil
egen totsugar = total(hh_g07a) if sugar == 1, by(case_id) 
egen totsugarcane = total(hh_g07a) if sugarcane == 1, by(case_id) 
egen totcookingoil = total(hh_g07a) if cookingoil == 1, by(case_id) 
egen totothersugar = total(hh_g07a) if othersugar == 1, by(case_id) 
* Spices & Miscelaneous 
egen totsalt = total(hh_g07a) if salt == 1, by(case_id) 
egen totspices = total(hh_g07a) if spices == 1, by(case_id) 
egen totyeast = total(hh_g07a) if yeast == 1, by(case_id) 
egen tottomatosauce = total(hh_g07a) if tomatosauce == 1, by(case_id) 
egen tothotsauce = total(hh_g07a) if hotsauce == 1, by(case_id) 
egen totjam = total(hh_g07a) if jam == 1, by(case_id) 
egen totsweets = total(hh_g07a) if sweets == 1, by(case_id) 
egen tothoney = total(hh_g07a) if honey == 1, by(case_id) 
egen tototherspice = total(hh_g07a) if otherspice  == 1, by(case_id) 
* Cooked Foods from Vendors
egen totmaizeboiledorroastedvendor = total(hh_g03a) if maizeboiledorroastedvendor == 1, by(case_id) 
egen totchipsvendor = total(hh_g07a) if chipsvendor == 1, by(case_id) 
egen totcassavaboiledvendor = total(hh_g07a) if cassavaboiledvendor == 1, by(case_id) 
egen toteggsboiledvendor = total(hh_g07a) if eggsboiledvendor == 1, by(case_id) 
egen totchickenvendor = total(hh_g07a) if chickenvendor== 1, by(case_id) 
egen totmeatvendor = total(hh_g07a) if meatvendor == 1, by(case_id) 
egen totfishvendor = total(hh_g07a) if fishvendor == 1, by(case_id) 
egen totmandazivendor = total(hh_g07a) if mandazivendor == 1, by(case_id) 
egen totsamosavendor = total(hh_g07a) if samosavendor == 1, by(case_id) 
egen totmealatrestaurant = total(hh_g07a) if mealatrestaurant == 1, by(case_id) 
egen totothercooked = total(hh_g07a) if othercooked == 1, by(case_id) 
* Beverages
egen tottea = total(hh_g07a) if tea == 1, by(case_id) 
egen totcoffee = total(hh_g07a) if coffee == 1, by(case_id) 
egen totcocoa = total(hh_g07a) if cocoa == 1, by(case_id) 
egen totsquash = total(hh_g07a) if squash == 1, by(case_id) 
egen totfruitjuice = total(hh_g07a) if fruitjuice == 1, by(case_id) 
egen totfreezes = total(hh_g07a) if freezes== 1, by(case_id) 
egen totsoftdrinks = total(hh_g07a) if softdrinks == 1, by(case_id) 
egen totchibuku = total(hh_g07a) if chibuku == 1, by(case_id) 
egen totbottledwater = total(hh_g07a) if bottledwater == 1, by(case_id) 
egen totmaheu = total(hh_g07a) if maheu == 1, by(case_id) 
egen totbottledbeer = total(hh_g07a) if bottledbeer== 1, by(case_id) 
egen totthobwa = total(hh_g07a) if bottledbeer == 1, by(case_id) 
egen tottraditionalbeer = total(hh_g07a) if traditionalbeer == 1, by(case_id) 
egen totwine = total(hh_g07a) if wine == 1, by(case_id) 
egen totkachasu = total(hh_g07a) if kachasu == 1, by(case_id) 
egen tototherbeverage = total(hh_g07a) if otherbeverage == 1, by(case_id) 

