
* Household illness past 2weeks
g byte illness_2wk = (hh_d04 == 1)
egen totIllness_2wk = total(illness_2wk), by(case_id)
la var totIllness_2wk "Total hh members suffered illness/injury in last two weeks"

* What type?
clonevar illness_injuryType =  hh_d05a

* Household chronic illness 
g byte chlonicillness = (hh_d33 == 1)
egen totchronicIllness = total(chlonicillness), by(case_id)
la var totchronicIllness "Total hh members suffer from chronicillness"

la var illness_2wk "illness/injury in last 14 days"
la var chlonicillness "hh member(s) suffering from chronicillness"

*collapse
qui include "/Users/student/Desktop/LAM MALAWI_STATA/DataProcessing/copylabels.do"

ds(case_id id_code hh_c01), not
collapse (max) `r(varlist)', by(case_id)

qui include "/Users/student/Desktop/LAM MALAWI_STATA/DataProcessing/attachlables.do"
