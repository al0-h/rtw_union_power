/*******************************************************************************
* FILE     : 1_Clean.do
* PROJECT  : RTW Project
* PURPOSE  : Creates main data set
*
* CREATED  : 23 May 2025
* STATA    : StataNow/SE 18.5 for Mac (Apple Silicon) Revision 04 Sep 2024
*
* INPUTS   : - RTW_Years.xlsx
*			 - 
*
* OUTPUTS  : - Appended_CPS_ORG.dta
*			 - 
*			 -
*
* REQUIRES : -
*
* NOTES    : - 
*
********************************************************************************/

* Settings and paths *
**********************

clear all 

local RTW_key 1 // generates the RTW key for panel data 
local Gen_Appended 1 // takes a long time don't run once then set to 0
local BEA_Extract 1

global folder "/Users/alexanderleon-hernandez/Desktop/rtw_union_power"
global data "$folder/data"
global intm "$folder/intm"

cd "$folder"       

log using "$folder/code/Logs/1_Clean", replace

*********************************************
* Generate the RTW key dataset - Prepares for merging RTW indicators with panel data		
*********************************************
if `RTW_key' == 1{
	
	import excel "$data/RTW_Years.xlsx", sheet("Sheet1") firstrow clear

	* Generate years variables
	expand year
	bys state: replace year = 1979
	bys	state: replace year = year[_n-1]+1 if _n > 1

	* Generate months variables
	expand month
	bys state year: replace month = 1
	bys	state year: replace month = month[_n-1]+1 if _n > 1

	sort state year month


	* Generate RTW status based on month and year implementation

	gen double adopt_date = ym(rtw_year , rtw_month)
	format adopt_date %tm

	gen double obs_date   = ym(year , month)
	format obs_date %tm

	gen rtw = obs_date >= adopt_date  if !missing(adopt_date)
	replace rtw = 0 if missing(adopt_date)

	gen alwaystreat = adopt_date < ym(1979,1) if !missing(adopt_date)
	
	drop obs_date adopt_date
	
	rename (state icpsr_code) (state_name state)


	save "$intm/RTW_States", replace
}


*********************************************
* Append all the MORG CPS data together	2003-2019 for same reasons as in Fortin et al. 2022	
*********************************************
if `Gen_Appended' == 1{
	
	local start_year 1979
	local end_year	 2019
	
	* Download all the CPS ORG data
	
	forvalues y = `start_year'/`end_year' {
		
		*
		copy "https://ceprdata.s3.amazonaws.com/data/cps/data/cepr_org_`y'.zip" ///
			 "$data/CPS_ORG_Data/cepr_org_`y'.zip", replace
		
		cd "$data/CPS_ORG_dta" 
		
		unzipfile "$data/CPS_ORG_Data/cepr_org_`y'.zip", replace
		  
	}
	
	cd "$folder"
	
	
	* Append raw CPS MORG data into Appended_CPS_ORG.dta
	cd "$data/CPS_ORG_dta"
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

}

if `BEA_Extract' == 1{
	
* ── Import Deflator  ───────────────────────────────────────────────────────── *

	* Download quarterly GDPDEF (2017=100) from FRED
	set fredkey 1984e496c0397c8628bd0a928de0f2b7 
	// request here API key "https://fred.stlouisfed.org/docs/api/api_key.html."
	import fred GDPDEF, clear

	* Add calendar year
	gen year = year(daten)

	* Average the four quarters within each year
	collapse (mean) gdpdef = GDPDEF, by(year)

	* Keep only the years you need
	keep if inrange(year, 1997, 2024)
	tempfile deflate
	save `deflate', replace
	
	
* ── Setup Gross operating surplus  ─────────────────────────────────────────── *
	
	import excel "$data/Table.xlsx", sheet("Table") cellrange(A6:AC66) firstrow clear // Gross operating surplus is in thousands of current dollars (not adjusted for inflation). Statistics presented in thousands of dollars do not indicate more precision than statistics presented in millions of dollars. Industry detail is based on the 2017 North American Industry Classification System (NAICS).* For the all industry total, government and government enterprises, federal civilian, and military, the difference between the United States and sum-of-states reflects overseas activity, economic activity taking place outside the borders of the United States by the military and associated federal civilian support staff.(D) Not shown to avoid disclosure of confidential information; estimates are included in higher-level totals.Last updated: September 27, 2024-- new statistics for 2023; revised statistics for 2019-2022.
	
	rename *, lower        
	rename (c-ac) (v#), addnumber(1997)

	reshape long v, i(geofips geoname) j(year)
	rename v Value
	destring year, replace	
	drop if substr(geofips, 1, 1) == "9" // remove regional
	recast str10 geofips    // change type from strL to str10 in place
	tempfile BEA
	save `BEA', replace 
	
	
* ── Setup   ─────────────────────────────────────────── *
	
	import delimited  "$data/SASUMMARY/SASUMMARY__ALL_AREAS_1998_2024.csv", clear
	replace geofips  = subinstr(geofips , `"""', "", .)
	rename (v9-v35) (v#), addnumber(1998)
	drop if regexm(geofips, "[A-Za-z]")

	
	reshape long v, ///
    i(geofips geoname region tablename linecode ///
      industryclassification description unit) ///
    j(year)
	
	recast str10 geofips    // change type from strL to str10 in place

	merge m:1  year geofips  using `BEA'
	rename _m _m_BEA
	 
	merge m:1 year using `deflate'
	rename _merge _m_deflate
	
	
	gen GrossOpSur_def_17 = Value/gdpdef if !mi(Value) // Deflated 2017 Gross operating surplus
	
	* Merge on RTW indicators 
	
	gen state = geoname
	
	
	
	merge m:1 state using "$intm/simple_RTWkey.dta"
	
	save "$intm/BEA_data.dta", replace
	
}

log close
