/*-------------------------------------------------------------------------------
# Name:		02_stunting_2010
# Purpose:	recode and rename household assets for use in stunting analysis
# Author:	Tim Essam, Ph.D.
# Created:	2018/07/09
# Owner:	USAID GeoCenter 
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close

* Load and convert in DHS flagged households in the FFP Selected zones to be merged at end
import delimited "$pathout/MWI_2010_DHS_livelihood_FFP_attributes.txt", clear
save "$DHSout/MWI_2010_DHS_livelihood_FFP_attributes.dta", replace

* Process kids stunting data for regressions
use "$pathkids10/MWKR61FL.dta", clear
log using "02_stunting2010", replace

* Flag children selected for anthropmetry measures
	g cweight = (v005/1000000)
	clonevar anthroTag = v042
	keep if anthroTag == 1
	clonevar DHSCLUST = v001

	clonevar stunting = hw5
	clonevar stunting2 = hw70

	foreach x of varlist stunting stunting2 {
		replace `x' = . if inlist(`x', 9998, 9999, 9996)
		replace `x' = `x' / 100
		}
*end

	g byte stunted = (stunting < -2.0)
	replace stunted = . if stunting == .

	g byte stunted2 = (stunting2 < -2.0)
	replace stunted2 = . if stunting2 == .

	g byte extstunted = (stunting < -3.0)
	replace extstunted =. if stunting == .

	g byte extstunted2 = (stunting2 < -3.0)
	replace extstunted2 = . if stunting2 == .

	clonevar ageChild = hw1
	clonevar age_group = v013

	egen ageMonGroup = cut(ageChild), at(0, 6, 9, 12, 18, 24, 36, 48, 60) label

	recode b4 (1 = 0 "male")(2 = 1 "female"), gen(female)

* Stunting averages grouping
	egen ageg_stunting = mean(stunting2), by(age_group)
	egen age_stunting = mean(stunting2), by(ageChild)
	la var ageg_stunting "age group average for stunting"
	la var age_stunting "age chunk average for stunting"

* religion
	clonevar religion = v130
	la values religion rel

* health outcomes
	g byte diarrhea = (h11 == 2)
	g byte orsKnowledge = inlist(v416, 1, 2)
	la var orsKnowledge "used ORS or heard of it"

* Birth order and breastfeeding
	clonevar precedBI 	= b11
	clonevar succeedBI 	= b12
	clonevar birthOrder = bord
	clonevar dob 		= b3
	clonevar ageFirstBirth = v212
	clonevar bfDuration	= m4
	clonevar bfMonths	= m5
	clonevar breastfeeding = v404
	clonevar anemia = v457

* Antenatal care visits (missing for about 25% of sample)
	recode m14 (3 = 2 "2-3 visits") (4/11 = 3 "4+ ANC visit")(98 99 = .), gen(anc)
	clonevar anc_Visits = m14
	replace anc_Visits = . if anc_Visits == 98

* Contraception use practices
	g byte modernContra = v313 == 3
	la var modernContra "Use modern method of contraception (binary)"

* Birth size
	recode m18 (1 = 5 "very large")(2 = 4 "above ave")(3 = 3 "ave")(4 = 2 "below ave")/*
	*/(5 = 1 "very below")(8 9 = .), gen(birthSize)

*Place of delivery
	g byte birthAtHome = inlist(m15, 11, 12)
	recode h34 (0 = 0 "No")(1 = 1 "Yes")(8 9 = .), gen(vitaminA)

*recode s579 (0 8 = 0 "no")(1 = 1 "yes"), gen(childSick)
	clonevar deliveryPlace = m15

	clonevar birthWgt = m19
	replace birthWgt = . if inlist(birthWgt, 9996, 9998, 9999)
	replace birthWgt = birthWgt / 1000

	clonevar birthWgtSource = m19a

* Keep elibigle children
	g eligChild = 0
	replace eligChild = 1 if (hw70 < 9996 & hw71 < 9996 & hw72 < 9996)
	g eligChild2 = 0
	replace eligChild2 =1 if (hw5 < 9996 & hw6 < 9996 & hw7 < 9996)
	tab eligChild*

* How many children per household?
	bys caseid: g numChild = _N if eligChild == 1

* Mother's bmi
	replace v445 = . if v445 == 9998
	g bmitmp = (v445/100) if (v445 < 9999)
	egen motherBMI = cut(bmitmp), at(0, 18.5, 25.0, 50) label
	la def bmi 0 "undernourished" 1 "normal" 2 "overweight"
	la val motherBMI bmi

	clonevar motherBWeight = v440 
	replace motherBWeight = . if inlist(motherBWeight, 9998, 9999)
	replace motherBWeight = (motherBWeight / 100)

	clonevar wantedChild = v367
	recode h43 (0 8 9 = 0 "No")(1 = 1 "Yes"), gen(intParasites)

* Mother's education
	clonevar motherEd = v106
	clonevar motherEdYears = v107
		
* Keep subset of variables
	#delimit ;
	ds(stunting stunting2 stunted stunted2 ageChild 
		age_group female ageg_stunting age_stunting 
		religion diarrhea precedBI succeedBI 
		birthOrder dob ageFirstBirth bfDuration 
		bfMonths /*childSick*/ deliveryPlace birthWgt 
		birthWgtSource v001 v002 eligChild
		ageMonGroup 
		bmitmp motherBMI motherBWeight 
		motherEd breastfeeding birthAtHome
		motherEdYears DHSCLUST cweight wantedChild anemia
		vitaminA intParasites extstunted* orsKnowledge);
	#delimit cr
	keep `r(varlist)'

	* Clone the cluster variable so you can merge
	clonevar dhsclust = v001
	
	
	compress
	saveold "$DHSout/DHS_child2010.dta", replace

* Merge in household information and livelihood information
	merge m:1 v001 v002 using "$DHSout/DHS_hhvar2010.dta", gen(_hhvar2010)
	merge m:1 dhsclust using "$DHSout/MWI_2010_DHS_livelihood_FFP_attributes.dta", gen(_ffpzoi)
	g byte ffp_focus = (_ffpzoi == 3)
	la var ffp_focus "focus of FFP activity design"

g year = 2010
save "$DHSout/DHS_2010_analysis.dta", replace




