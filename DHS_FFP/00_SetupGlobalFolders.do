/*-------------------------------------------------------------------------------
# Name:		00_SetupFolderGlobals
# Purpose:	Create series of folders Food for Uganda Vulnerability Analysis
# Author:	Tim Essam, Ph.D.
# Created:	10/31/2014; 2018/04/19
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

/* RUN/READ ME FIRST -- Make directories for the study.
 1. Requires root name for file folder structure
 2. Requires branch names for sub-folders
 3. Sets global macros for the study; These are used through the do files.
 4. TODO -- Script DOES NOT copy in raw data at this point.
 5. TODO -- Create program folder for calling custom programs.
 6. TODO -- Convert setup .do file into a program (inputs are project path & folder name)
*/
	
* install the confirm directory ado if not already installed
* list all known user-written .ados needed for project
local required_ados confirmdir mvfiles fs spatgsa  adolist labellist winsor2   
foreach x of local required_ados { 
	capture findfile `x'.ado
		if _rc==601 {
			cap ssc install `x'
		}
		else disp in yellow "`x' currently installed."
	}
*end

* Determine path for the study 
* global projectpath "U:/"
*global projectpath "/Users/tessam/Documents/"
global projectpath "/Users/timessam/Documents/USAID/"
*global projectpath "C:/Users/t/Documents/"
cd "$projectpath"

* Run a macro to set up study folder (needs to be modified)
* Name the file path below -- replace "nigerlsms" with your folder name
local pFolder 2018_Malawi
foreach dir in `pFolder' {
	confirmdir "`dir'"
	if `r(confirmdir)'==170 {
		mkdir "`dir'"
		display in yellow "Project directory named: `dir' created"
		}
	else disp as error "`dir' already exists, not created."
	cd "$projectpath/`dir'"
	}
* end

* Run initially to set up folder structure
* Choose your folders to set up as the local macro `folders'
local folders Rawdata Stata Datain Log Output Dataout DHSout Excel PDF Word Graph GIS Export R Python Programs Sensitive_Data FinalProducts
foreach dir in `folders' {
	confirmdir "`dir'"
	if `r(confirmdir)'==170 {
			mkdir "`dir'"
			disp in yellow "`dir' successfully created."
		}
	else disp as error "`dir' already exists. Skipped to next folder."
}
*end

/*---------------------------------
# Set Globals based on path above #
-----------------------------------*/
global date $S_DATE
local dir `c(pwd)'
global path "`dir'"
global pathdo "`dir'/Stata"
*global pathdo2 "C:/Users/Tim/Documents/GitHub/Uganda/Stata"
global pathlog  "`dir'/Log"
global pathin "`dir'/Datain"
global pathout "`dir'/Dataout"
global DHSout "`dir'/DHSout"
global pathgraph "`dir'/Graph"
global wave3 "`dir'/Datain/wave3"
global wave1 "`dir'/Datain/wave1"
global wave2 "`dir'/Datain/wave2"
global pathxls "`dir'/Excel"
global pathreg "`dir'/Output"
global pathgis "`dir'/GIS"
global pathraw "`dir'/Rawdata"
global pathexport "`dir'/Export"
global pathR "`dir'/R"
*global pathR2 "C:/Users/t/Documents/GitHub/Uganda/R"
global pathPython "`dir'/Python"
global pathProgram "`dir'/Program"
*global pathPdrive "P:/GeoCenter/GIS/Projects/LVA/Uganda"
*global pathSensitive "`dir'/Sensitive_Data"
global pathProducts "`dir'/FinalProducts"
* Project macros are defined as:
macro list 

* DHS specific paths
global pathDHS "`dir'/DHS_FFP"

global pathkids "`dir'/DHS/MW_2015-16_DHS/MWKR7HDT"
global pathwomen "`dir'/DHS/MW_2015-16_DHS/MWIR7HDT"
global pathmen "`dir'/DHS/MW_2015-16_DHS/MWMR7HDT"
global pathroster "`dir'/DHS/MW_2015-16_DHS/MWPR7HDT"
global pathhh "`dir'/DHS/MW_2015-16_DHS/MWHR7HDT"
global path2010 "`dir'/DHS/MW_2010_DHS"


global pathkids10 "`dir'/DHS/MW_2010_DHS/MWKR61DT"
global pathwomen10 "`dir'/DHS/MW_2010_DHS/MWIR61DT"
global pathmen10 "`dir'/DHS/MW_2010_DHS/MWMR61DT"
global pathroster10 "`dir'/DHS/MW_2010_DHS/MWPR61DT"
global pathhh10 "`dir'/DHS/MW_2010_DHS/MWHR61DT"

include "$pathdo/pesort.do"



