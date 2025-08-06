/****************************************************************************
* Script   : 01c_BEA_Extract.do
*
* PROJECT  : RTW Project
* PURPOSE  : Generate BEA dataset
*
* CREATED  : 23 May 2025
*
* STATA    : StataNow/SE 18.5 for Mac (Apple Silicon) Revision 04 Sep 2024
*
* INPUTS   : - ../Intm/RTW_States.dta
*
* OUTPUTS  : - ../Intm/BEA_data.dta
*
* NOTES	   : - You need an API key from FRED
*			   Send the request here https://fred.stlouisfed.org/docs/api/api_key.html.
*
****************************************************************************/

log using "$folder/code/Logs/01c_BEA_Extract", replace

* Import Deflator 

* Download quarterly GDPDEF (2017=100) from FRED
	//set fredkey 1984e496c0397c8628bd0a928de0f2b7 
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
	
	
* Setup Gross operating surplus 
	
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
	
	
* Setup data 
	
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
	
log close
