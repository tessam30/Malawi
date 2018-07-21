
/*-------------------------------------------------------------------------------
# Name:		08_Analysis_markdwon
# Purpose:	Source the analysis files and run markdown file with parameters defined
# Author:	Tim Essam, Ph.D.
# Created:	2018/07/13
# Owner:	USAID GeoCenter 
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/


 include "$pathDHS/05_stuntingAnalysis_2010.do"
 include "$pathDHS/06_stuntingAnalysis_2015.do"
 include "$pathDHS/07_stunting_temporal.do"
 
 * Create calls for the statistical tables that will be embedded in markdown doc
 
 * -- First, report the regressions for the pooled data, looking at different models
 esttab zcont_201015_0 zcont_201015_1 zcont_201015_2 zcont_201015_3, se star(* 0.10 ** 0.05 *** 0.01)  beta compress 
 
 * -- Second, report the results for the pooled data, looking at the quantiles of zscores
 esttab qreg qreg_201015*, se star(* 0.10 ** 0.05 *** 0.01) beta compress
 
 * -- Next, show the FFP regions where we used a logistic regression on whether or not the child was stunted
 esttab stunt_201015_global stunt_201015_1 stunt_201015_2 stunt_201015_3 stunt_201015_4, se star(* 0.10 ** 0.05 *** 0.01) beta
 

* Call the markstat file that will produce the the HTML document with results
	markstat using "$pathDHS/08_results.stmd", strict


* For plotting.
    twoway (kdensity stunting2 if year == 2010 & eligChild == 1, lcolor(gs10)) /*
    */(kdensity stunting2 if year == 2015 & eligChild ==1, lcolor(gs5) lpattern(dash)), /*
    */yscale(off) yline(-2, lpattern(solid) lcolor(gs14)) xline(-2, lpattern(solid) lcolor(gs13)) /*
    */ xlabel(-4(2)4) title(The stunting z-score distribution has shifted to the right in the 2015 data, /*
    */size(medsmall)) subtitle(Density to the left of the -2 reference line indicate stunted households, /*
    */size(vsmall)) legend(order(1 "2010 Z-scores" 2 "2015 Z-scores") span)
    graph export StuntingDensity.png, width(500) replace

    ![Stunting Density Plot](StuntingDensity.png)
