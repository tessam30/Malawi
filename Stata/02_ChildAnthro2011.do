clear
capture log close
set more off

use "$wave1/HH_MOD_V.dta", clear 

isid case_id id_code

merge 1:1 case_id id_code using "$wave1/HH_MOD_B.dta"

tab hh_v05, mi
drop if hh_v05 == .
drop if hh_b07 != 0

count

* Create age variable
g years = hh_b05a
g month = hh_b05b

g ageMonths = (years * 12) + month 
keep if inrange(ageMonths, 6, 59)
keep if hh_v05 == 1
tab years month
sum ageMonths, d

histogram(ageMonths)

clonevar sex = hh_b03
clonevar oedema = hh_v14
clonevar height = hh_v09
clonevar weight = hh_v08
recode hh_v10 (1 = 2 "Standing")(2 = 1 "Lying down"), gen(measure)
drop if measure == 3

drop if oedema == .

sum ageMonths sex height weight measure, d

scatter height ageMonths
histogram height
*scatter weight ageMonths

* Flag children who were not measured recumbantly or standing
g byte wrongMeasure = (ageMonths < 24 & measure == 2)
replace wrongMeasure = 1 if (ageMonths >= 24 & measure == 1)

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

mean stunted underwgt wasted, over(wrongMeasure)

* Clean up dataset and keep essential variables
keep case_id id_code visit ea_id hh_v01 years month ageMonths sex oedema height weight /*
*/ measure stunting underweight wasting BMI stunted underwgt wasted BMIed 

* Merge in geographic information

merge m:1 case_id using "$wave1/HouseholdGeovariables.dta", gen(_geo)
keep if _geo == 3
merge m:1 case_id using "$wave1/HH_MOD_A_FILT.dta", gen(_hhbase)
keep if _hhbase == 3

clonevar district = hh_a01

* Set sampling weights
drop hh_a*


svyset ea_id [pweight=hh_wgt], strata(district) singleunit(centered) 
svydescribe

svy:mean stunted
svy:mean stunted, over(district)
mean stunted [iweight = hh_wgt], over(district) 

pesort stunted district

compress

export delimited "$pathout/LSMS_2011_anthro.csv", replace
