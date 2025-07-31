/*******************************************************************************
* FILE     : 2_Analysis.do
* PROJECT  : RTW Project
* PURPOSE  : Generates Main Analysis Figures
*
* CREATED  : 23 May 2025
* STATA    : StataNow/SE 18.5 for Mac (Apple Silicon) Revision 04 Sep 2024
*
* INPUTS   : - Appended_CPS_ORG.dta
*			 - 
*
* OUTPUTS  : - 
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

set scheme s2color
graph set window fontface "Times New Roman"


local Union_participation_Figures 1 // Generate union membership & coverage over the years
local BEA_figures 1 // gross operating surplus and incomes over the years


global folder "/Users/alexanderleon-hernandez/Desktop/rtw_union_power"
global data "$folder/data"
global intm "$folder/intm"
global output "$folder/output"

cd "$folder"       

//log using "$folder/Scripts/Logs/2_Analysis", replace

if `Union_participation_Figures' == 1 {

use "$intm/Appended_CPS_ORG.dta" if  empl == 1 & rtw_year >= 1984 & year >= 1984 , clear //removed unemployed, the union question was first asked in 1983


gen wt=round(orgwgt/12,1)

replace rtw_year = 0 if missing(rtw_year)

g rtw_stateind = rtw_year!=0

**********************************************************
* 1.  Collapse by RTW status  (two rows per year)        *
**********************************************************
preserve
collapse (sum)   pop   = wt         ///
         (mean)  unmem uncov rw           ///
         (semean) se_unmem = unmem se_uncov = uncov ///
         [aw = wt], by(rtw_stateind year)

* save to temp file
tempfile by_status
save `by_status'
restore

**********************************************************
* 2.  Collapse for the NATIONAL average  (one row/year)  *
**********************************************************
collapse (sum)   pop   = wt         ///
         (mean)  unmem uncov           ///
         (semean) se_unmem = unmem se_uncov = uncov ///
         [aw = wt], by(year)

* mark the national rows with missing rtw_stateind
gen byte rtw_stateind = .            // . = national

* save to temp file
tempfile national
save `national'

**********************************************************
* 3.  Append the two pieces and build 95 % CIs           *
**********************************************************
use `by_status', clear
append using `national'

gen lb95 = unmem - 1.96*se_unmem
gen ub95 = unmem + 1.96*se_unmem

gen lb95c = uncov - 1.96*se_uncov
gen ub95c = uncov + 1.96*se_uncov

**********************************************************
* 4.  Plot: black = national, red = RTW, blue = non-RTW  *
*	  Union Membership									 *
**********************************************************

twoway  /* NATIONAL average
*/	(rarea ub95 lb95 year if missing(rtw_stateind), color(black%20)) /*
*/  (line  unmem     year if missing(rtw_stateind), lcolor(black) lwidth(medthick)) /* RTW states
*/  (rarea ub95 lb95 year if rtw_stateind==1,       color(red%20)) /*
*/  (line  unmem     year if rtw_stateind==1,       lcolor(red)  lwidth(medthick)) /* Non-RTW states
*/  (rarea ub95 lb95 year if rtw_stateind==0,       color(blue%20)) /*
*/  (line  unmem     year if rtw_stateind==0,       lcolor(blue) lwidth(medthick)) /*
*/,	legend(order(4 "RTW states" 6 "Non-RTW states" 2 "All states") position(7) ring(0)) /*
*/	xscale(range(1984 2019) noextend)  /*
*/  xlabel(1984(2)2019, nogrid)  ylabel(, nogrid) /*
*/  ytitle("Union-membership share")   xtitle("Year") /*
*/  title("Union membership with 95% CIs, 1984-2019")

graph export "$output/UnionMemRTWNat.pdf", replace

  
**********************************************************
* 5.  Plot: black = national, red = RTW, blue = non-RTW  *
*	  Union Coverage									 *
**********************************************************

twoway /* NATIONAL average 
*/	(rarea ub95c lb95c year if missing(rtw_stateind), color(black%20)) /*
*/	(line  uncov     year if missing(rtw_stateind), lcolor(black) lwidth(medthick)) /* RTW states
*/	(rarea ub95c lb95c year if rtw_stateind==1,       color(red%20))  /*
*/	(line  uncov     year if rtw_stateind==1,       lcolor(red)  lwidth(medthick)) /* Non-RTW states 
*/	(rarea ub95c lb95c year if rtw_stateind==0,       color(blue%20)) /*
*/	(line  uncov     year if rtw_stateind==0,       lcolor(blue) lwidth(medthick)) /*
*/	, legend(order(4 "RTW states" 6 "Non-RTW states" 2 "All states") position(7) ring(0)) /*
*/	xscale(range(1984 2019) noextend)  /*
*/	xlabel(1984(2)2019, nogrid)  ylabel(, nogrid) /*
*/	ytitle("Union-coverage share")   xtitle("Year") /*
*/	title("Union coverage with 95% CIs, 1984-2019")

graph export "$output/UnionCovRTWNat.pdf", replace
}


if `BEA_figures' == 1{
	
	use "$intm/BEA_data", clear
	
	**********************************************************
	* 1.  Plot: red = RTW, blue = non-RTW  					 *
	*	  Union Coverage									 *
	**********************************************************
	
	preserve 
	
	collapse (mean)   Value           ///
         (semean) Value_se = Value  ///
         , by(year rtw_ind)
	
	drop if year == 2024 // just 2024 no values
		 
	gen lb95 = Value - 1.96*Value_se
	gen ub95 = Value + 1.96*Value_se
		 
	twoway /* RTW states 
*/	(rarea ub95 lb95 year if rtw_ind==1,       color(cranberry%20))  /*
*/	(line  Value     year if rtw_ind==1,       lcolor(cranberry)  lwidth(medthick)) /* Non-RTW states 
*/	(rarea ub95 lb95 year if rtw_ind==0,       color(edkblue%20)) /*
*/	(line  Value     year if rtw_ind==0,       lcolor(edkblue) lwidth(medthick)) /*
*/	, legend(order(2 "RTW states" 4 "Non-RTW states") position(6) ring(1)) /*
*/	xlabel(, nogrid)  ylabel(, nogrid) /*
*/	xscale(range(1997 2023) noextend)  xlabel(1997(6)2023, nogrid) /*
*/	ytitle("Gross Operating Surplus")   xtitle("Year") /*
*/	title("Gross Operating Surplus with 95% CIs, 1997-2023")
  
  graph export "$output/temp.pdf", replace
  
  restore 
  
  
	**********************************************************
	* 2.  Plot: red = RTW, blue = non-RTW  					 *
	*	  Real personal income								 *
	**********************************************************
  
	//preserve 
	keep if description == " Real personal income (millions of constant (2017) dollars) 2/"
	destring v, replace force 
	
	collapse (mean)   v           ///
         (semean) v_se = v  ///
         , by(year rtw_ind)
	
	drop if mi(v)
	gen lb95 = v - 1.96*v_se
	gen ub95 = v + 1.96*v_se
	
	twoway (rarea ub95 lb95 year if rtw_ind==1,       color(cranberry%20))  ///
    (line  v     year if rtw_ind==1,       lcolor(cranberry)  lwidth(medthick)) /// Non-RTW states
    (rarea ub95 lb95 year if rtw_ind==0,       color(edkblue%20)) ///
    (line  v     year if rtw_ind==0,       lcolor(edkblue) lwidth(medthick)) 
	
}

*********************************************************************************

use "$intm/Appended_CPS_ORG.dta" if   rtw_year >= 2003 & year >= 2003 , clear // 2000s onwards RTW states differ too much from pre 2000s RTW states. For consitency I'll stick to 2000s
gen wt=round(orgwgt/12,1)

replace rtw_year = 0 if missing(rtw_year)

g rtw_stateind = rtw_year!=0

g lnrw = ln(rw) if !mi(rw)

collapse  (first) rtw_year  (sum)   pop = wt (mean) uncov unmem rtw rw lnrw multjob schcol [aw = wt], by(state year empl)

replace rtw = 0 if rtw < .5 & rtw != 0
replace rtw = 1 if rtw >= .5 & rtw != 0

keep if empl == 1

* Callaway–Sant'Anna   

//keep if ind_2d == 40 & empl == 1
xtset state year

/*
**PLACEBO YEAR VAR****
*   For each state, grab the first year with rtw==1
by state (year): gen _first = year if rtw == 1
by state: egen gvar = min(_first)   // will be missing if a state is always 0
replace gvar = 0 if missing(gvar)
label var gvar "First RTW year (0 = never)"
drop _first


gen gvar_m5 = cond(gvar==0, 0, gvar + 5)
summ year, meanonly
replace gvar_m5 = 0 if gvar_m5 > `r(max)'    // keeps it inside your sample
label var gvar_m5 "Placebo: first RTW year −5"
**********
*/
* ----  ATT of RTW on union coverage --------------------------------------
* https://www.statalist.org/forums/forum/general-stata-discussion/general/1690247-csdid-with-weights
* recommends using iweights
csdid unmem  [iw=pop], ivar(state) time(year) gvar(rtw_year) method(reg) post 
estat simple
// plot the first stage
estat event, window(-10 10)
csdid_plot

 //graph export  "$output/First_Stage.pdf",replace

matrix b1 = r(table)
scalar att_union = b1[1,1]
scalar se_union  = b1[2,1]

* ---- ATT of RTW on wages -----------------------------------------------
csdid lnrw     [iw=pop], ivar(state) time(year) gvar(rtw_year) method(reg) post
estat simple                
matrix b2 = r(table)
scalar att_outcome = b2[1,1]
scalar se_outcome  = b2[2,1]   // <-- use b2, not b1

* ---- Wald ratio and delta-method s.e. -----------------------------------
* Not sure if this works but for now seems like a practical solution
scalar wald = att_outcome/att_union
scalar se_wald = abs(wald)*sqrt( (se_outcome/att_outcome)^2 ///
                                 + (se_union /att_union )^2 )

di wald
di se_wald



use "/Users/alexanderleon-hernandez/Downloads/cps_00005.dta"
 
rename statefip state
 
merge m:1 state year month using "$intm/RTW_States", keep(3)

g unmem = union == 2 if !mi(union)

g uncov = union == 2 | union == 3 if !mi(union)


replace rtw_year = 0 if missing(rtw_year)

g rtw_stateind = rtw_year!=0

keep if empstat == 10 // at work
collapse  (first) rtw_year  (sum)   pop = hwtfinl (mean) uncov unmem rtw [pw = hwtfinl], by(state year)

replace rtw = 0 if rtw < .5 & rtw != 0
replace rtw = 1 if rtw >= .5 & rtw != 0

 
 csdid unmem  [iw=pop], ivar(state) time(year) gvar(rtw_year) method(reg) post 
estat simple
// plot the first stage
estat event, window(-10 10)
csdid_plot

 csdid uncov  [iw=pop], ivar(state) time(year) gvar(rtw_year) method(reg) post 
estat simple
// plot the first stage
estat event, window(-10 10)
csdid_plot




