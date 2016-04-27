/* -----------------------------------------------------------------------------
# Name:		cnumlist
# Purpose:	creates comma separated number lists, return `r(numlist)'
# Author:	n.j.cox@durham.ac.uk from Statalist
# copied from http://hsphsun3.harvard.edu/cgi-bin/lwgate/STATALIST/archives/statalist.0406/Subject/article-540.html
# Created:	2015/02/11
# Modified: 2015/02/11
#-------------------------------------------------------------------------------
*/

* Input is a numlist in the form "num1/num2" or "41/82"
capture program drop cnumlist
program cnumlist, rclass 
         version 13.1
         numlist `0'
         local result "`r(numlist)'"
         local result : subinstr local result " " ",", all
         return local numlist "`result'"
end
