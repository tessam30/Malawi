/*-------------------------------------------------------------------------------
# Name:		07_StuntingAnalysisTemporal
# Purpose:	Compare stunting results over time
# Author:	Tim Essam, Ph.D.
# Created:	2018/07/13
# Owner:	USAID GeoCenter 
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/


clear
capture log close
log using "$pathlog/07_StuntingAnalysisTemporal.txt", replace

use "$DHSout/DHS_2015_Stunting.dta", clear
clonevar district_2015 = district
append using "$DHSout/DHS_2010_Stunting.dta"
 
/* shdist list for lables from 2010
         101 Chitipa
         102 Karonga
         103 Nkhatabay
         104 Rumphi
         105 Mzimba
         106 Likoma (not nkhatabay)
		 107 Mzuzu City
         201 Kasungu
         202 Nkhota Kota
         203 Ntchisi
         204 Dowa
         205 Salima
         206 Lilongwe Rural
         207 Mchinji
         208 Dedza
         209 Ntcheu
         210 Lilongwe city
         301 Mangochi
         302 Machinga
         303 Zomba Rural
         304 Chiradzulu
         305 Blantyre Rural
         306 Mwanza
         307 Thyolo
         308 Mulanje
         309 Phalombe
         310 Chikwawa
         311 Nsanje / Ndanje
         312 Balaka
         313 Neno
         314 Zomba City
         315 Blantyre City
*/

* Need to fix Blantyre City, Zomba City, Mzuzu City and Lilongwe city so that districts
* are standardized across years for the regression models
* Assuming that the combination of district + rural == 0 + year == 2010 --> City

	tab district rural if year == 2010, mi
	replace district = 315 if (district == 305 & rural == 0)
	replace district = 314 if (district == 303 & rural == 0)
	replace district = 210 if (district == 206 & rural == 0)

* Do point estimates match up to DHS estimaties?
	mean stunted2 if year == 2010 [aw=cweight] 
	mean stunted2 if year == 2015 [aw=cweight] 

* Check district averages and how they moved over time
	* Check data overtime by district/livelihood zone
	foreach x of varlist stunting2 stunted2 extstunted2 {
		egen `x'_dist2010 = mean(`x') if year == 2010, by(district)
		egen `x'_dist2015 = mean(`x') if year == 2015, by(district)

	}
*end

* Plot differences over time to see 
graph dot (mean) stunted2_dist2010 stunted2_dist2015, over(district, sort(1))


* Create district averages for each year w/ CIs
		* Set the geography for summary stats
		global geog "district"
		
		*mean stunted2 if year == 2010 & ageChild < 24 [aw = cweight], over($geog)
		mean stunted2 if year == 2010 [aw = cweight], over($geog)
		matrix A = r(table)'
		matrix N = e(_N)'
		local dimCol = rowsof(A)
		display `dimCol'
		matrix y1 = J(`dimCol', 1, 2010)
		matrix C = A , y1, N
		
		*mean stunted2 if year == 2014 & ageChild < 24 [aw=cweight] , over($geog)
		mean stunted2 if year == 2015 [aw = cweight], over($geog)
		matrix B = r(table)'
		matrix N = e(_N)'
		local dimCol2 = rowsof(B)
		display "Number of rows in summary matrix is: `dimCol2'"
		matrix y2 = J(`dimCol2', 1, 2014)
		
		matrix D = B, y2, N
		matrix Z = C \ D
		
		*district_under2_or_equal
		
	mat2txt, matrix(Z) saving("$pathreg/stunting_by_district.txt") replace

* Regression specifications -- use similar ones as used for the year by year analysis

	replace ffp_focus = 1 if ffp_focus15 == 1

* Create groups for covariates as they map into conceptual framework for stunting
	* -- Birthw weight is missing for quite a few of the kiddos. Drops sample for regression down to around ~3000
	
	global matchar "motherBWeight motherBMI motherEd femhead orsKnowledge"
	global matchar2 "motherBWeight rohrer_idx motherEd femhead orsKnowledge"
	global hhchar "mobile bankAcount improvedSanit improvedWater bnetITNuse landless"
	global hhchar2 "wealth bnetITNuse"
	global contra "modernContra ib(1).wantedChild idealChildNo"
	global hhag "tlutotal"
	global hhag2 "cowtrad goat sheep chicken pig rabbit"
	global demog "hhsize agehead hhchildUnd5"
	global chldchar "ib(3).age_group birthOrder cough fever" 
	global chldchar2 "ageChild agechildsq birthOrder birthWgt cough fever"
	global chealth "intParasites vitaminA diarrhea anemia"
	global geog "altitude2 rural i.ffp_focus"
	global geog1 "altitude2 ib(1).ffp_aois"
	global geog2 "altitude2  ib(206).district"
	global year "ib(2015).year"
	global cluster "cluster(dhsclust)"
	global cluster2 "cluster(hhgroup)"

	* STOP: Check all globals for missing values! 
	* Vitamin A has a decent amount of missing values
	sum $matchar $hhchar $hhag $demog female $chldchar $chealth $geog if eligChild == 1


	est clear
	eststo zcont_0: reg stunting2 $matchar $hhchar $contra $hhag $demog female $chldchar $chealth $geog $year ib(1327).intdate, $cluster 
	eststo zcont_1: reg stunting2 $matchar $hhchar $contra $hhag $demog female $chldchar $chealth $geog2 $year ib(1327).intdate, $cluster 
	eststo zcont_2: reg stunting2 $matchar $hhchar2 $contra $hhag $demog female $chldchar2 $chealth $geog $year ib(1327).intdate, $cluster 
	eststo zcont_3: reg stunting2 $matchar $hhchar2 $contra $hhag $demog female $chldchar2 $chealth $geog2 $year ib(1327).intdate, $cluster 	

	eststo zcont_4: reg stunting2 $matchar $hhchar $contra $hhag $demog female $chldchar $chealth $geog1 $year ib(1327).intdate if ffp_focus, $cluster 
	eststo zcont_5: reg stunting2 $matchar $hhchar $contra $hhag $demog female $chldchar $chealth $geog1 $year ib(1327).intdate if ffp_focus, $cluster 
	eststo zcont_6: reg stunting2 $matchar $hhchar2 $contra $hhag $demog female $chldchar2 $chealth $geog1 $year ib(1327).intdate if ffp_focus, $cluster 
	eststo zcont_7: reg stunting2 $matchar $hhchar2 $contra $hhag $demog female $chldchar2 $chealth $geog1 $year ib(1327).intdate if ffp_focus, $cluster 
	esttab zcont*, se star(* 0.10 ** 0.05 *** 0.01) ar2 pr2 beta not /*eform(0 0 1 1 1)*/ compress
	
	
	
	
	
	
	

