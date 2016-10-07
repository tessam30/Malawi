* Describe what is accomplished with file:
* This .do file processed the household demographic variables
* Extensive efforts were made to align the household size variable
* with the same figures offered by the World Bank
* Date: 2016/09/16
* Author: Tim Essam, Brent McCusker & Park Muhonda
* Project: WVU Livelihood Analysis for Malawi
********************************************************************

clear
capture log close
log using "$pathlog/hh_demog.txt", replace

* Load the dataset needed to derive household demographic variables
use "$wave1/HH_MOD_B.dta", clear
merge m:1 case_id using "$wave1/ihs3_summary.dta", keepus(region district hhsize adulteq intmonth intyear)
drop _merge

* A regular household member includes those present when the enumerator visited and a head was present
* generate a flag for when the head is present on the 1st visit

** ----------------------- Aligning Household Size ---------------------------------------------
* One corner case that is missed by code below (added this to top of stream b/c it's missed)
drop if case_id	== "103040120125" & id_code == 12

* Need a flag to determine how many visits a household had
g byte hhmemb = inlist(hh_b07, 0, 1, 2, 3, 4, 5, 6, .) == 1 
la var hhmemb "Usual member of household"

* How different are the given and the calculated household sizes?
egen hhs1 = total(hhmemb), by(case_id)
g hhdiff = hhsize - hhs1

* Flag those households for which we can use the entire roster based on code above
g byte keepFlag1 = (hhsize == hhs1)
drop if keepFlag1 == 1 & hhmemb != 1

* Was the hh head present during the visit? Use this information to determine
* cases where the household was visited but the head was not present
egen rosterPresent = min(hh_b04) if keepFlag1 != 1, by(case_id visit)
g byte headPresent = rosterPresent == 1 
replace headPresent = . if keepFlag1 == 1

* Create a new hhousehold variable based on head's presence
egen hhs2 = total(headPresent) if keepFlag1 != 1, by(case_id)
tab hhs2 hhsize if keepFlag1 != 1
g byte hhsizeSame2 = (hhsize == hhs2)
replace hhsizeSame2 = . if  keepFlag1 == 1
g byte keepFlag2 = headPresent == 1 & hhsizeSame2 == 1

* Drop non eligible observations within households matching sizes of official figures
drop if headPresent ==0 & hhsizeSame2 == 1
replace hhs1 = hhs2 if hhsizeSame2 == 1

* If a member has gone or is dead, flag them as 0
g byte stay1 = inlist(status, 1, 2) if hhsizeSame2 == 0
egen hhs3 = total(stay1) if hhsizeSame2 == 0 , by(case_id)
g byte hhsizeSame3 = (hhs3 == hhsize)
g byte keepFlag3 = stay1 == 1

* Drop non eligible households within households with matching sizes of official figures
drop if keepFlag3 == 0 & hhsizeSame3 == 1
replace hhs1 = hhs3 if hhsizeSame3 == 1

* This should be all 1s if above is executed correctly
g byte masterKeep = (keepFlag3 | keepFlag2 | keepFlag1)
tab hhsize hhs1

preserve
	keep case_id id_code region district
	save "$pathout/hh_roster_2011.dta", replace
restore

** ----------------------- Aligning Household Size End--------------------------------------


* Data processing 
g byte hoh =  hh_b04 == 1
la var hoh "Head of household"

g byte spouse =  hh_b04 == 2
la var spouse "spouse of hoh"

g byte femhead =  hh_b04 == 1 & hh_b03 == 2
la var femhead "Female head of household"

g agehead = hh_b05a if hoh == 1
la var agehead "Age of hoh"

g genderhead = hh_b03 if hoh == 1
la var genderhead "Gender of hoh"

* --- Relationship status 
g byte marriedHoh = inlist(hh_b24, 1, 2) & hoh == 1
g byte marriedHohm = (hh_b24 == 1 & hoh == 1)
g byte marriedHohp = (hh_b24 == 2 & hoh == 1)
g byte nonmarriedHoh = (inlist(hh_b24, 3, 4, 5, 6)==1) & hoh == 1
g byte widowFemhead = femhead == 1 & hh_b24 == 5
g byte nonmarriedFemhead = femhead == 1 & inlist(hh_b24, 3, 4, 5, 6)

la var marriedHoh "Married hoh (any type)"
la var marriedHohm "Monogamous married hoh"
la var marriedHohp "Polygamous married hoh"
la var nonmarriedHoh "Non-married (never marry, divorce, separated, widowed)"
la var widowFemhead "Widowed female hoh"
la var nonmarriedFemhead "Non-married (never marry, divorce, separated, widowed) female hoh"

* --- Religion 
g religHoh = hh_b23 if hoh == 1
g religSpouse = hh_b23 if hh_b01 == 2

tempvar hohrelig sprelig
egen `hohrelig' = max(religHoh), by(case_id)
egen `sprelig' = max(religSpouse), by(case_id)
g byte mxdreligHH = `hohrelig' != `sprelig' & `hohrelig' != . & `sprelig' != .

la var religHoh "Religion of hoh"
la var religSpouse "Religion of spouse"
la var mxdreligHH "Mixed-religion household"

* --- Household demographics 
* Create gender ratio for households
g byte male = hh_b03 == 1 
g byte female = hh_b03 == 2 
la var male "male hh members"
la var female "female hh members"

egen msize = total(male), by(case_id)
la var msize "number of males in hh"

egen fsize = total(female), by(case_id)
la var fsize "number of females in hh"

* Create a gender ratio variable
g gendMix = msize/fsize
recode gendMix (. = 0) if fsize==0
la var gendMix "Ratio of males to females (1 = 1:1 mix)"

* Flag observations under 60 months (5 years)
g byte und5tmp = (hh_b05a <= 5)

* Create categorical for age group chunks
/* NOTE: These codes will be used throughout for demographic factors so determine
   the cuts needed before initiating the cut; Will save time downstream.
*/
egen youthtmp = cut(hh_b05a), at(0, 5, 10, 12, 15, 18, 25, 31, 36, 60, 65, 100) icodes
* replace youthtmp = 0 if und5tmp // Not needed b/c age vars were entered differently
table youthtmp, c(min hh_b05a max hh_b05a)

egen youthtmp2 = cut(hh_b05a), at(0, 10, 20, 100) icodes
replace youthtmp2 = 0 if und5tmp

* Create binary variables for demographic categories
g byte under5tmp = inlist(youthtmp, 0) 
g byte under15tmp = inlist(youthtmp, 0, 1, 2, 3) 
g byte under24tmp = inlist(youthtmp, 0, 1, 2, 3, 4, 5)
g byte youth15to24tmp = inlist(youthtmp, 4, 5) 
g byte youth18to30tmp = inlist(youthtmp, 5, 6)
g byte youth25to35tmp = inlist(youthtmp, 6, 7) 
g byte over35under65tmp = inlist(youthtmp, 8, 9)
g byte over64tmp = inlist(youthtmp, 10) 

* Create total, male and female totals at the household level of each demographic
local demo under5 under15 under24 youth15to24 youth18to30 youth25to35 over35under65 over64
foreach x of local demo {
	egen `x'  = total(`x'tmp), by(case_id)
	egen `x'm = total(`x'tmp) if male == 1, by(case_id)
	egen `x'f = total(`x'tmp) if female == 1, by(case_id)
	
	* Replace missing values with zeros
	replace `x' = 0 if `x' == .
	replace `x'm = 0 if `x'm == .
	replace `x'm = 0 if `x'm == .
	
	la var `x' "total hh members `x'"
	la var `x'm "total male hh members `x'"
	la var `x'f "total female hh members `x'"
}
*end

/* Create intl. HH dependency ratio 
# HH Dependecy Ratio = [(# people 0-14 + those 65+) / # people aged 15-64 ] * 100 # 
The dependency ratio is defined as the ratio of the number of members in the age groups 
of 14 years and above 65 years to the number of members of working age (15-64 years). 
The ratio is normally expressed as a percentage (data below are multiplied by 100 for pcts.*/
g byte numDepRatio = inlist(youthtmp, 4, 5, 6, 7, 8, 9) != 1
g byte demonDepRatio = inlist(youthtmp, 4, 5, 6, 7, 8, 9) == 1
egen totNumDepRatio = total(numDepRatio), by(case_id)
egen totDenomDepRatio = total(demonDepRatio), by(case_id)

* Check that numbers add to hhsize
assert hhsize == totNumDepRatio+totDenomDepRatio 
g depRatio = (totNumDepRatio/totDenomDepRatio)*100 if totDenomDepRatio!=.
*recode depRatio (. = 0) if totDenomDepRatio==0
la var depRatio "Dependency Ratio"

* Calculate household labor shares (ages 12 - 60)
/* Household Labor Shares */
g byte hhLabort = inlist(youthtmp, 3, 4, 5, 6, 7, 8)==1
egen hhlabor = total(hhLabort), by(case_id)
la var hhlabor "hh labor age>11 & < 60"

g byte mlabort = inlist(youthtmp, 3, 4, 5, 6, 7, 8)==1 & male == 1
egen mlabor = total(mlabort), by(case_id)
la var mlabor "hh male labor age>11 & <60"

g byte flabort = inlist(youthtmp, 3, 4, 5, 6, 7, 8)==1 & female == 1
egen flabor = total(flabort), by(case_id)
la var flabor "hh female labor age>11 & <60"
drop hhLabort mlabort flabort

* Male/Female labor share in hh
g mlaborShare = mlabor/hhlabor
recode mlaborShare (. = 0) if hhlabor == 0
la var mlaborShare "share of working age males in hh"

g flaborShare = flabor/hhlabor
recode flaborShare (. = 0) if hhlabor == 0
la var flaborShare "share of working age females in hh"



*--------------------------------------
* % of hh females aged 20-34 & 35 - 59
g byte fem20_34tmp = (hh_b05a >= 20 & hh_b05a < 35) & (female == 1)
g byte fem35_59tmp = (hh_b05a >=35 & hh_b05a <60) & (female == 1)
egen femCount20_34 = total(fem20_34tmp), by(case_id)
egen femCount35_59 = total(fem35_59tmp), by(case_id)
g femRatio20_34 = femCount20_34/hhsize
g femRatio35_59 = femCount35_59/hhsize

la var femRatio20_34 "Share of females in hh 20-34"
la var femRatio35_59 "Share of females in hh 35-59"
la var femCount20_34 "Number of females in hh 20-34"
la var femCount35_59 "Number of females in hh 35-59"

* --- Generate adult equivalents in household
scalar male10 	= 1
scalar fem10_19 = 0.84
scalar fem20	= 0.72
scalar child10	= 0.60

g ae = .
replace ae = male10 if inlist(youthtmp2, 1, 2) == 1 & male == 1
replace ae = fem10_19 if inlist(youthtmp2, 1)==1 & female == 1
replace ae = fem20 if inlist(youthtmp2, 2) & female == 1 
replace ae = child10 if inlist(youthtmp2, 0)

la var ae "Adult equivalents in household"
egen adultEquiv = total(ae), by(case_id)
la var adultEquiv "Total adult equivalent units"

/* Calculate Migrant Network Variable: Has lived
	in current village/town for 1/5 years  	*/
	
g byte migrant = ( hh_b12 > 1 &  hh_b12 <= 5)
egen hhmignet = max(migrant), by(case_id)


* --- Education levels 
* drop values that take on 8
g educHoh = hh_b21 if hoh == 1 & hh_b21 != 8 
g educSpouse = hh_b21 if spouse == 1 & hh_b21 != 8 
egen educAdult =  max(hh_b21), by(case_id)

la var educHoh "Education of Hoh"
la var educSpouse "Education of spouse"
la var educAdult "Highest adult education in household"

* If spouse live in the hh 
g byte presentSpouse = hh_b25 == 1 & spouse == 1
la var presentSpouse "Spouse lives in the hh"

* --- Length of stay  
g lenStayHoh = hh_b12 if hoh == 1 & hh_b12 != 99
g lenStaySpouse = hh_b12 if spouse == 1 & hh_b12 != 99
egen lenStayAdult =  max(hh_b12), by(case_id)

la var lenStayHoh "Length of stay in the area by Hoh"
la var lenStaySpouse "Length of stay in the area by spouse"
la var lenStayAdult "Maximum length of stay in the area by hh member"

*collapse
qui include "$pathdo/copylabels.do"

ds(case_id id_code hh_b* visit ea_id qx_type), not
collapse (max) `r(varlist)', by(case_id)

qui include "$pathdo/attachlabels.do"

drop hhdiff keepFlag1 rosterPresent headPresent hhs2 /*
*/ hhsizeSame2 keepFlag2 stay1 hhs3 hhsizeSame3 keepFlag3 masterKeep


* Fix variables for which values are missing due to no female members of hh
local dgph gendMix under5f under15f under24f youth15to24f youth18to30f youth25to35f over35under65f over64f
foreach x of local dgph {
	replace `x' = 0 if `x' == .
	}
*end


g year = 2011
compress
save "$pathout/hh_dem_wave1.dta", replace


** ----------------------- Wave 2 Processing----------------------------------------------------
* Process 2nd wave 
use "$wave2/HH_MOD_B.dta", clear
merge m:1 y2_hhid using "$wave2/ConsumptionAggregate2013.dta", keepus(region district hhsize adulteq intmonth intyear)
drop _merge

** ----------------------- Aligning Household Size ---------------------------------------------
* Much easier this time around as the survey includes a variable for whether a hh member is eligible
egen hhsize2 = total(hhmember), by(y2_hhid)
keep if hhmember == 1

preserve
	keep y2_hhid PID region district
	save "$pathout/hh_roster_2013.dta", replace
restore

tab hhsize hhsize2

** ----------------------- End Aligning Household Size ---------------------------------------------

* Data processing 
g byte hoh = hh_b04 == 1
la var hoh "Head of household"

g byte spouse = hh_b04 == 2
la var spouse "spouse of hoh"

g byte femhead = hh_b04 == 1 & hh_b03 == 2
la var femhead "Female head of household"

g agehead = hh_b05a if hoh == 1
la var agehead "Age of hoh"

g genderhead = hh_b03 if hoh == 1
la var genderhead "Gender of hoh"

* --- Relationship status 
g byte marriedHoh = inlist(hh_b24, 1, 2) & hoh == 1
g byte marriedHohm = (hh_b24 == 1 & hoh == 1)
g byte marriedHohp = (hh_b24 == 2 & hoh == 1)
g byte nonmarriedHoh = (inlist(hh_b24, 3, 4, 5, 6)==1) & hoh == 1
g byte widowFemhead = femhead == 1 & hh_b24 == 5
g byte nonmarriedFemhead = femhead == 1 & inlist(hh_b24, 3, 4, 5, 6)

la var marriedHoh "Married hoh (any type)"
la var marriedHohm "Monogamous married hoh"
la var marriedHohp "Polygamous married hoh"
la var nonmarriedHoh "Non-married (never marry, divorce, separated, widowed)"
la var widowFemhead "Widowed female hoh"
la var nonmarriedFemhead "Non-married (never marry, divorce, separated, widowed) female hoh"

* --- Religion 
g religHoh = hh_b23 if hoh == 1
g religSpouse = hh_b23 if hh_b04 == 2

tempvar hohrelig sprelig
egen `hohrelig' = max(religHoh), by(y2_hhid)
egen `sprelig' = max(religSpouse), by(y2_hhid)
g byte mxdreligHH = `hohrelig' != `sprelig' & `hohrelig' != . & `sprelig' != .

la var religHoh "Religion of hoh"
la var religSpouse "Religion of spouse"
la var mxdreligHH "Mixed-religion household"

g byte male = hh_b03 == 1 
g byte female = hh_b03 == 2 
la var male "male hh members"
la var female "female hh members"

egen msize = total(male), by(y2_hhid)
la var msize "number of males in hh"

egen fsize = total(female), by(y2_hhid)
la var fsize "number of females in hh"

** ----------------------- Household size variables ---------------------------------------------
* Create a gender ratio variable
g gendMix = msize/fsize
recode gendMix (. = 0) if fsize==0
la var gendMix "Ratio of males to females (1 = 1:1 mix)"

* Flag observations under 60 months (5 years)
g byte und5tmp = (hh_b05a <= 5)

* Create categorical for age group chunks
/* NOTE: These codes will be used throughout for demographic factors so determine
   the cuts needed before initiating the cut; Will save time downstream.
*/
egen youthtmp = cut(hh_b05a), at(0, 5, 10, 12, 15, 18, 25, 31, 36, 60, 65, 100) icodes
* replace youthtmp = 0 if und5tmp // Not needed b/c age vars were entered differently
table youthtmp, c(min hh_b05a max hh_b05a)

egen youthtmp2 = cut(hh_b05a), at(0, 10, 20, 100) icodes
replace youthtmp2 = 0 if und5tmp

* Create binary variables for demographic categories
g byte under5tmp = inlist(youthtmp, 0) 
g byte under15tmp = inlist(youthtmp, 0, 1, 2, 3) 
g byte under24tmp = inlist(youthtmp, 0, 1, 2, 3, 4, 5)
g byte youth15to24tmp = inlist(youthtmp, 4, 5) 
g byte youth18to30tmp = inlist(youthtmp, 5, 6)
g byte youth25to35tmp = inlist(youthtmp, 6, 7) 
g byte over35under65tmp = inlist(youthtmp, 8, 9)
g byte over64tmp = inlist(youthtmp, 10) 

* Create total, male and female totals at the household level of each demographic
local demo under5 under15 under24 youth15to24 youth18to30 youth25to35 over35under65 over64
foreach x of local demo {
	egen `x'  = total(`x'tmp), by(y2_hhid)
	egen `x'm = total(`x'tmp) if male == 1, by(y2_hhid)
	egen `x'f = total(`x'tmp) if female == 1, by(y2_hhid)
	
	* Replace missing values with zeros
	replace `x' = 0 if `x' == .
	replace `x'm = 0 if `x'm == .
	replace `x'm = 0 if `x'm == .
	
	la var `x' "total hh members `x'"
	la var `x'm "total male hh members `x'"
	la var `x'f "total female hh members `x'"
}
*end

/* Create intl. HH dependency ratio 
# HH Dependecy Ratio = [(# people 0-14 + those 65+) / # people aged 15-64 ] * 100 # 
The dependency ratio is defined as the ratio of the number of members in the age groups 
of 14 years and above 65 years to the number of members of working age (15-64 years). 
The ratio is normally expressed as a percentage (data below are multiplied by 100 for pcts.*/
g byte numDepRatio = inlist(youthtmp, 4, 5, 6, 7, 8, 9) != 1
g byte demonDepRatio = inlist(youthtmp, 4, 5, 6, 7, 8, 9) == 1
egen totNumDepRatio = total(numDepRatio), by(y2_hhid)
egen totDenomDepRatio = total(demonDepRatio), by(y2_hhid)

* Check that numbers add to hhsize
assert hhsize == totNumDepRatio+totDenomDepRatio 
g depRatio = (totNumDepRatio/totDenomDepRatio)*100 if totDenomDepRatio!=.
recode depRatio (. = 0) if totDenomDepRatio==0
la var depRatio "Dependency Ratio"

* Calculate household labor shares (ages 12 - 60)
/* Household Labor Shares */
g byte hhLabort = inlist(youthtmp, 3, 4, 5, 6, 7, 8)==1
egen hhlabor = total(hhLabort), by(y2_hhid)
la var hhlabor "hh labor age>11 & < 60"

g byte mlabort = inlist(youthtmp, 3, 4, 5, 6, 7, 8)==1 & male == 1
egen mlabor = total(mlabort), by(y2_hhid)
la var mlabor "hh male labor age>11 & <60"

g byte flabort = inlist(youthtmp, 3, 4, 5, 6, 7, 8)==1 & female == 1
egen flabor = total(flabort), by(y2_hhid)
la var flabor "hh female labor age>11 & <60"
drop hhLabort mlabort flabort

* Male/Female labor share in hh
g mlaborShare = mlabor/hhlabor
recode mlaborShare (. = 0) if hhlabor == 0
la var mlaborShare "share of working age males in hh"

g flaborShare = flabor/hhlabor
recode flaborShare (. = 0) if hhlabor == 0
la var flaborShare "share of working age females in hh"



*--------------------------------------
* % of hh females aged 20-34 & 35 - 59
g byte fem20_34tmp = (hh_b05a >= 20 & hh_b05a < 35) & (female == 1)
g byte fem35_59tmp = (hh_b05a >=35 & hh_b05a <60) & (female == 1)
egen femCount20_34 = total(fem20_34tmp), by(y2_hhid)
egen femCount35_59 = total(fem35_59tmp), by(y2_hhid)
g femRatio20_34 = femCount20_34/hhsize
g femRatio35_59 = femCount35_59/hhsize

la var femRatio20_34 "Share of females in hh 20-34"
la var femRatio35_59 "Share of females in hh 35-59"
la var femCount20_34 "Number of females in hh 20-34"
la var femCount35_59 "Number of females in hh 35-59"

* --- Generate adult equivalents in household
scalar male10 	= 1
scalar fem10_19 = 0.84
scalar fem20	= 0.72
scalar child10	= 0.60

g ae = .
replace ae = male10 if inlist(youthtmp2, 1, 2) == 1 & male == 1
replace ae = fem10_19 if inlist(youthtmp2, 1)==1 & female == 1
replace ae = fem20 if inlist(youthtmp2, 2) & female == 1 
replace ae = child10 if inlist(youthtmp2, 0)

la var ae "Adult equivalents in household"
egen adultEquiv = total(ae), by(y2_hhid)
la var adultEquiv "Total adult equivalent units"

/* Calculate Migrant Network Variable: Has lived
	in current village/town for 1/5 years  	*/
	
g byte migrant = ( hh_b12 > 1 &  hh_b12 <= 5)
egen hhmignet = max(migrant), by(y2_hhid)


* --- Education levels 
g educHoh = hh_b22_3 if hoh == 1 & hh_b22_3 != 8 
g educSpouse = hh_b22_3 if spouse == 1 & hh_b22_3 != 8 
egen educAdult =  max(hh_b22_3), by(y2_hhid)

la var educHoh "Education of Hoh"
la var educSpouse "Education of spouse"
la var educAdult "Highest adult education in household"

* If spouse live in the hh 
g byte presentSpouse = hh_b25 == 1 & spouse == 1

la var presentSpouse "Spouse lives in the hh"

* --- Length of stay  
g lenStayHoh = hh_b12 if hoh == 1 
g lenStaySpouse = hh_b12 if spouse == 1 
egen lenStayAdult =  max(hh_b12), by(y2_hhid)

la var lenStayHoh "Length of stay in the area by Hoh"
la var lenStaySpouse "Length of stay in the area by spouse"
la var lenStayAdult "Maximum length of stay in the area by hh member"

*collapse
qui include "$pathdo/copylabels.do"

ds(hh_b* moverbasehh individualmover baselinemembercount interview_status qx_type PID y2_hhid occ), not
collapse (max) `r(varlist)', by(y2_hhid)

qui include "$pathdo/attachlabels.do"

g year = 2013
compress
save "$pathout/hh_dem_wave2.dta", replace

* append the two datasets together
append using "$pathout/hh_dem_wave1.dta"
drop __000002 __000003
sort y2_hhid year

clonevar id = y2_hhid
replace id = y2_hhid if id == "" & year == 2013
save "$pathout/hh_demog_all.dta", replace

