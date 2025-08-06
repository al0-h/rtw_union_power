/****************************************************************************
* SCRIPT   : 01b_Gen_Appended.do 
*
* PURPOSE  : Append all the ORG CPS data together	
*
* CREATED  : 23 May 2025
*
* STATA    : StataNow/SE 18.5 for Mac (Apple Silicon) Revision 04 Sep 2024
*
* INPUTS   : - 
*
* OUTPUTS  : - ../Intm/Appended_CPS_ORG.dta
*
* NOTES	   : - 2003-2019 for same reasons as in Fortin et al. 2022	
*
****************************************************************************/

log using "$folder/code/Logs/01b_Gen_Appended", replace	
	
* 1979 as far back as we can go with CPS ORG
local start_year 1979
local end_year	 2019
	
* Download all the CPS ORG data from CEPR 
forvalues y = `start_year'/`end_year' {
			
	copy "https://ceprdata.s3.amazonaws.com/data/cps/data/cepr_org_`y'.zip" ///
			 "$data/CPS_ORG_Data/cepr_org_`y'.zip", replace
		
	cd "$data/CPS_ORG_dta" 
		
	unzipfile "$data/CPS_ORG_Data/cepr_org_`y'.zip", replace
		  
}
	
	
* Append raw CPS ORG data into Appended_CPS_ORG.dta
cd "$data/CPS_ORG_dta" // have to set directory for filelist to work
filelist , pattern("*.dta") list
	
gen fullpath = dirname + "/" + filename
levelsof fullpath, local(files)

clear
save "$intm/Appended_CPS_ORG.dta", replace emptyok
foreach file of local files {
	use `file', clear
	append using "$intm/Appended_CPS_ORG.dta", force
	save "$intm/Appended_CPS_ORG.dta", replace
}
	
merge m:1 state year month using "$intm/RTW_States", keep(3)

save "$intm/Appended_CPS_ORG.dta", replace

log close
