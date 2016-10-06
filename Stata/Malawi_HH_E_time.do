* Describe what is accomplished with file:
* This .do file calculates the ganyu labor time for households
* Date: 2016/09/16
* Author: Tim Essam, Brent McCusker & Park Muhonda
* Project: WVU Livelihood Analysis for Malawi
********************************************************************

clear
capture log close

* Load the dataset needed to derive time use and ganyu variables
use "$wave1/HH_MOD_E.dta", clear

* Merge in household roster so you can determine who is head and spouse
merge 1:1 case_id id_code using "$wave1/HH_MOD_B.dta", gen(_roster)
merge 1:1 case_id id_code using "$pathout/hh_roster_2011.dta", gen(_rosterKeep)
drop if _rosterKeep == 1 | _roster == 2

* water time -- use hh_b04 (correct variable when making spouse/head vars)
egen totWaterTime = total(hh_e05), by(case_id)
g spouseWaterTime = (hh_e05) if hh_b04 == 2 
g headWaterTime = (hh_e05) if hh_b04 == 1 

* Firewood time 
egen totFirewdTime = total(hh_e06), by(case_id)
g spouseFireTime = (hh_e06) if hh_b04 == 2 
g headFireTime	= (hh_e06) if hh_b04 == 1 

* Ganyu time 
g byte ganyuParticipation = inlist(hh_e55 , 1)
egen ganyuDenom = total(ganyuParticipation), by(case_id)

g ganyuTotdays = hh_e56 * hh_e57 * hh_e58 if ganyuParticipation == 1
* Check that no household has more than 365 days of Ganyu Labor participation
assert ganyuTotdays < 365 if !missing(ganyuTotdays)

* What is total estimated wage of ganyu labor efforts
clonevar ganyuWageRate = hh_e59
sum ganyuWageRate, d
count if ganyuWageRate > 2 * `r(p99)' & !missing(ganyuWageRate)
winsor ganyuWageRate, gen(ganyuWR) highonly h(`r(N)')

g ganyuTotWage = ganyuTotdays * hh_e59 if ganyuParticipation == 1

* Check for outliers (greater than 99th percentile), replace them with
sum ganyuTotWage, d
scalar tmpmed = `r(p99)'
* replace the outliers using the median value of the wage (hh_e59)
egen medWage = median(hh_e59)
replace ganyuTotWage = ganyuTotdays * medWage if ganyuTotWage > tmpmed & !missing(ganyuTotWage)

* Create a logged value to normalize the distribution of ganyu earnings
g ganyuTotWageLog = ln(ganyuTotWage)
egen ganyuTotHHWage = total(ganyuTotWage), by(case_id)
g ganyuTotHHWagePC = ganyuTotHHWage/ganyuDenom
g ganyuTotHHWageLog = log(ganyuTotHHWage)
g ganyuTotHHWageLogPC =  ganyuTotHHWageLog/ganyuDenom

egen maxGanyuTime = max(ganyuTotdays), by(case_id)
g spouseGanyuTime = (ganyuTotdays) if hh_b04 == 2 
g sopuseGanyuWage = ganyuTotWage if hh_b04 == 2
g headGanyuTime	= (ganyuTotdays) if hh_b04 == 1
g headGanyuWage =  ganyuTotWage if hh_b04 == 1

la var totWaterTime "Total household time spent on water collection"
la var spouseWaterTime "Total spouse time spent on water collection"
la var headWaterTime "Total time hh head spent on water collection"
la var totFirewdTime "Total household time spent on firewood collection"
la var spouseFireTime "Total spouse time spent on firewood collection"
la var headFireTime "Total hoh time spent on firewood collection"
la var spouseGanyuTime "Total spouse time spent on Ganyu activities in past 12months"
la var headGanyuTime "Total hh of houdehold time spent on Ganyu activities in past 12months"
la var maxGanyuTime "Maximum time a household member spent on Ganyu activities in the past 12months"
la var ganyuParticipation "household member participated in ganyu labor"
la var ganyuDenom "Total number of household members participating in ganyu"
la var ganyuTotdays "Total number of days participating in labor (months * weeks * days/week)"
la var ganyuTotWage "Total estimated wage earned through ganyu (days * average wage)"
la var ganyuTotWageLog "Logged value of ganyuTotWage (to normalize)"
la var spouseGanyuTime "Spouse time spent in ganyu"
la var sopuseGanyuWage "Spouse wage earned in ganyu"
la var headGanyuTime "Head time spent in ganyu"
la var headGanyuWage "Head wage earned in ganyu"
la var ganyuTotHHWage "total household ganyu wage"
la var ganyuTotHHWagePC "total household ganyu wage per ganyu participant"
la var ganyuTotHHWageLog "total household ganyu wage logged"
la var ganyuTotHHWageLogPC "total household ganyu wage logged per ganyu participant"

* Calculate a regional wage rate based on district averages
egen ganyuDistWR = mean(ganyuWR), by(district)

* Create a quick plot of the results
mean ganyuWageRate
	matrix smean = r(table)
	local varmean = smean[1,1]
mean ganyuWageRate, over(district)
	matrix plot = r(table)'
	matsort plot 1 "down"
	matrix plot = plot'
	coefplot (matrix(plot[1,])), ci((plot[5,] plot[6,])) xline(`varmean')


*collapse
qui include "$pathdo/copylabels.do"
	ds(hh_* case_id id_code qx_type visit status ea_id _roster), not
	collapse (max) `r(varlist)', by(case_id)
qui include "$pathdo/attachlabels.do"

g year = 2011
compress
* This will write over your other hh_dem_wave1 data.
*save "$pathout/hh_dem_wave1.dta", replace
save "$pathout/hh_dem_modE_wave1.dta", replace

***** Wave 2 *****
* Process 2nd wave 
* Load the dataset needed to derive time use and ganyu variables
use "$wave2/HH_MOD_E.dta", clear
merge 1:1 y2_hhid PID using "$wave2/HH_MOD_B.dta", gen(_roster)

* Drop anyone who is not a regular household member
keep if hhmember !=0

* water time 
egen totWaterTime = total(hh_e05), by(y2_hhid)
g spouseWaterTime = (hh_e05) if hh_b04 == 2 
g headWaterTime = (hh_e05) if hh_b04 == 1 

* Firewood time 
egen totFirewdTime = total(hh_e06), by(y2_hhid)
g spouseFireTime = (hh_e06) if hh_b04 == 2 
g headFireTime	= (hh_e06) if hh_b04 == 1 

* Ganyu time 
g byte ganyuParticipation = inlist(hh_e06_6 , 1)
egen ganyuDenom = total(ganyuParticipation), by(y2_hhid)

g ganyuTotdays = hh_e56 * hh_e57 * hh_e58 if ganyuParticipation == 1
* Check that no household has more than 365 days of Ganyu Labor participation
assert ganyuTotdays < 365 if !missing(ganyuTotdays)

* What is total estimated wage of ganyu labor efforts
g ganyuTotWage = ganyuTotdays * hh_e59 if ganyuParticipation == 1

* Check for outliers, replace them with 
sum ganyuTotWage, d
g tmpmed = `r(p99)'
* replace the outliers using the median value of the wage (hh_e59)
egen medWage = median(hh_e59)
replace ganyuTotWage = ganyuTotdays * medWage if ganyuTotWage > tmpmed & !missing(ganyuTotWage)

* Create a logged value to normalize the distribution of ganyu earnings
g ganyuTotWageLog = ln(ganyuTotWage)
egen ganyuTotHHWage = total(ganyuTotWage), by(y2_hhid)
g ganyuTotHHWagePC = ganyuTotHHWage/ganyuDenom
g ganyuTotHHWageLog = log(ganyuTotHHWage)
g ganyuTotHHWageLogPC =  ganyuTotHHWageLog/ganyuDenom

egen maxGanyuTime = max(ganyuTotdays), by(y2_hhid)
g spouseGanyuTime = (ganyuTotdays) if hh_b04 == 2 
g sopuseGanyuWage = ganyuTotWage if hh_b04 == 2
g headGanyuTime	= (ganyuTotdays) if hh_b04 == 1
g headGanyuWage =  ganyuTotWage if hh_b04 == 1

la var totWaterTime "Total household time spent on water collection"
la var spouseWaterTime "Total spouse time spent on water collection"
la var headWaterTime "Total time hh head spent on water collection"
la var totFirewdTime "Total household time spent on firewood collection"
la var spouseFireTime "Total spouse time spent on firewood collection"
la var headFireTime "Total hoh time spent on firewood collection"
la var spouseGanyuTime "Total spouse time spent on Ganyu activities in past 12months"
la var headGanyuTime "Total hh of houdehold time spent on Ganyu activities in past 12months"
la var maxGanyuTime "Maximum time a household member spent on Ganyu activities in the past 12months"
la var ganyuParticipation "household member participated in ganyu labor"
la var ganyuDenom "Total number of household members participating in ganyu"
la var ganyuTotdays "Total number of days participating in labor (months * weeks * days/week)"
la var ganyuTotWage "Total estimated wage earned through ganyu (days * average wage)"
la var ganyuTotWageLog "Logged value of ganyuTotWage (to normalize)"
la var spouseGanyuTime "Spouse time spent in ganyu"
la var sopuseGanyuWage "Spouse wage earned in ganyu"
la var headGanyuTime "Head time spent in ganyu"
la var headGanyuWage "Head wage earned in ganyu"
la var ganyuTotHHWage "total household ganyu wage"
la var ganyuTotHHWagePC "total household ganyu wage per ganyu participant"
la var ganyuTotHHWageLog "total household ganyu wage logged"
la var ganyuTotHHWageLogPC "total household ganyu wage logged ganyu participant"

*collapse
qui include "$pathdo/copylabels.do"
	ds(occ y2_hhid PID qx_type baselineme~r moverbasehh interview_status hh_* /*
	*/ hhmember baselineme~t _roster tmp*), not
	collapse (max) `r(varlist)', by(y2_hhid)
qui include "$pathdo/attachlabels.do"

g year = 2013
compress
save "$pathout/hh_dem_modE_wave2.dta", replace

* Append two datasets together
append using "$pathout/hh_dem_modE_wave1.dta"
order case_id y2_hhid

g id = case_id if year == 2011
replace id = y2_hhid if id == "" & year == 2013

save "$pathout/labor_all.dta", replace
