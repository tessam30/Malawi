/* -----------------------------------------------------------------------------
# Name:		pesort2
# Purpose:	return a coefficient plot of sorted point estimates
# Author:	Tim Essam
# Created:	2016/10/05
#-------------------------------------------------------------------------------
*/

* Input is a numlist in the form "num1/num2" or "41/82"
capture program drop pesort
program pesort 
         version 13.1
         
		 syntax varlist(numeric) [if] [in] [, geog]

		 marksample touse
		 
		 tempname smean plot
		 /* Program takes two inputs, the variable to be estimated
			and a dimension variable over which the results are sorted*/
			
		qui svy:mean `varlist' if `touse'
		matrix smean = r(table)
		local varmean = smean[1,1]
		local lb = smean[5, 1]
		local ub = smean[6, 1]

		qui svy:mean `varlist' if `touse', over(`2')
		matrix plot = r(table)'
		matsort plot 1 "down"
		matrix plot = plot'
		coefplot (matrix(plot[1,])), ci((plot[5,] plot[6,])) xline(`varmean' `lb' `ub')
		ereturn display
		end
