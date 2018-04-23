/*-------------------------------------------------------------------------------
# Name:		01_ChildAnthro2016
# Purpose:	Process child anthro data to show discrepancies with DHS
# Author:	Tim Essam, Ph.D.
# Created:	2018/04/18
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/


clear
capture log close
set more off
cd $path

use "$wave3/HH_MOD_V.dta", clear 

isid case_id PID
merge 1:1 case_id PID using "$wave3/HH_MOD_B.dta"

tab hh_v05, mi
drop if hh_v05 != 1
count

* Create age variable
g years = hh_b05a
g month = hh_b05b
g byte birthcert = hh_b05_2_1 == 1 

g ageMonths = (years * 12) + month
keep if inrange(ageMonths, 6, 59)
sum ageMonths, d

histogram(ageMonths)

clonevar sex = hh_b03
clonevar oedema = hh_v14
clonevar height = hh_v09
clonevar weight = hh_v08
recode hh_v10 (1 = 2 "Standing")(2 = 1 "Lying down"), gen(measure)
drop if measure == 3


scatter height ageMonths
histogram height
*scatter weight ageMonths

* Calculate z-scores using zscore06 package
zscore06, a(ageMonths) s(sex) h(height) w(weight) o(oedema) measure(measure)


* Remove scores that are implausible
replace haz06=. if haz06<-6 | haz06>6
replace waz06=. if waz06<-6 | waz06>5
replace whz06=. if whz06<-5 | whz06>5
replace bmiz06=. if bmiz06<-5 | bmiz06>5

ren haz06 stunting
ren waz06 underweight
ren whz06 wasting
ren bmiz06 BMI

la var stunting "Stunting: Length/height-for-age Z-score"
la var underweight "Underweight: Weight-for-age Z-score"
la var wasting "Wasting: Weight-for-length/height Z-score"

g byte stunted = stunting < -2 if stunting != .
g byte underwgt = underweight < -2 if underweight != . 
g byte wasted = wasting < -2 if wasting != . 
g byte BMIed = BMI <-2 if BMI ~= . 
la var stunted "Child is stunting"
la var underwgt "Child is underweight for age"
la var wasted "Child is wasting"

sum stunted underwgt wasted

compress

keep case_id HHID PID years month ageMonths sex oedema height weight /*
*/ measure stunting underweight wasting BMI stunted underwgt wasted BMIed 

* Merge in geographic information

merge m:1 case_id using "$wave3/HouseholdGeovariablesIHS4.dta", gen(_geo)
keep if _geo == 3
merge m:1 case_id using "$wave3/HH_MOD_A_FILT.dta", gen(_hhbase)
keep if _geo == 3

* Set sampling weights
svyset ea_id [pweight=hh_wgt], strata(district) singleunit(centered) 
svydescribe

svy:mean stunted, over(district)
mean stunted [iweight = hh_wgt], over(district) 

pesort stunted district

twoway (lpolyci stunted ageMonths), by(sex, rows(2))

scatter 


compress

*
preserve
keep lat_modified lat_modified lon_modified stunting stunted case_id district
export delimited "$dataout\mwi_childanthro_gis.csv", replace
restore

