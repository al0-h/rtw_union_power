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

net install scheme-modern, from("https://raw.githubusercontent.com/mdroste/stata-scheme-modern/master/")
net install grc1leg,from( http://www.stata.com/users/vwiggins/) 
set scheme modern


local Union_participation_Figures 1 // Generate union membership & coverage over the years
local BEA_figures 1 // gross operating surplus and incomes over the years


global folder "/Users/alexanderleon-hernandez/Desktop/rtw_union_power"
global data "$folder/data"
global intm "$folder/intm"
global tables "$folder/Presentations/Tables"
global figures "$folder/Presentations/Figures"

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

graph export "$figures/UnionMemRTWNat.pdf", replace

  
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

graph export "$figures/UnionCovRTWNat.pdf", replace
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

* Top 10 unionized firms from 2003 - 2019
use "$intm/RTW_Analysis.dta", clear

*---------------------------------------------------------------------
* A.  Compute 2003 (pre-treatment) union density and sample size
*---------------------------------------------------------------------
//preserve
collapse (first) rtw_year (mean) pre_union = unmem (sum) pre_pop = wt, by(ind_2d year)

*---------------------------------------------------------------------
* B.  Keep private, sizeable cells & rank by union density
*---------------------------------------------------------------------
sort pre_union -pre_pop
list ind_2d pre_union pre_pop in 1/15  // eyeball the top 15

*---- pick the top 10 unionised private industries -------------------
egen rank = rank(-pre_union)
keep if rank <= 10
levelsof ind_2d, local(top10)   // stores codes in `top10'

restore  // back to the full panel


keep if inlist(ind_2d ,4,10,18,23,24,29,31,40,41,51)

/*-------------------------------------------------------------*
  2 ▸ Collapse to state-year level with weights                *
*-------------------------------------------------------------*/
collapse (first) rtw_year (sum) pop = wt                                     ///
         (mean) unmem rtw , ///
         by(state year ind_2d)


/*-------------------------------------------------------------*
  3 ⏵ Loop over industries, run CSDID first stage, collect β   *
*--------------------------------------------------------------*/

levelsof ind_2d, local(top10)

foreach k of local top10 {
    preserve
    keep if ind_2d == `k'

    * CSDID first stage
    csdid unmem [iw = pop], ///
          ivar(state) time(year) gvar(rtw_year) ///
          method(dripw) post

    * --- get the ONE aggregated ATT and its s.e. -------------
    estat simple, post              // <---- this line is essential
	eststo model_`k'
    
	restore
}

use "$intm/RTW_Analysis.dta",clear

collapse  (first) rtw_year  (sum) lfstat nilf pop = wt lf_pop=lf_w  unemp_pop=unemp_w (mean)  unmem rtw lnrw female college manuf      ///
                 black foreign publicjob          ///
				 [aw = wt], by(state year)

replace rtw = 0 if rtw < .5 & rtw != 0
replace rtw = 1 if rtw >= .5 & rtw != 0

xtset state year


foreach v in unemp_rate female college manuf black foreign publicjob   {
    by state: gen L1_`v' = L.`v'
}

by state (year): gen L1_unemp = L.unemp_rate   // 1-year lag

 csdid unmem [iw = pop], ///
          ivar(state) time(year) gvar(rtw_year) ///
          method(dripw) post
	estat simple, post              
	eststo model_all	  

coefplot model_* , mlabels

foreach m in model_4 model_10 model_18 model_23 model_24 ///
             model_29 model_31 model_40 model_41 model_51 {
    qui estimates restore `m'
    di as text "`m':  |t| = " %5.2f abs(_b[ATT]/_se[ATT])
}




use "$intm/RTW_Analysis.dta" if ind_2d == 23,clear
collapse  (first) rtw_year  (sum) lfstat nilf pop = wt lf_pop=lf_w  unemp_pop=unemp_w (mean)  unmem rtw lnrw female college manuf      ///
                 black foreign publicjob          ///
				 [aw = wt], by(state year)

replace rtw = 0 if rtw < .5 & rtw != 0
replace rtw = 1 if rtw >= .5 & rtw != 0

gen unemp_rate = 100 * unemp_pop / lf_pop   if lf_pop>0
xtset state year

* keep only rows that have BOTH outcomes observed
keep if !missing(unmem) & !missing(lnrw)



* ── first stage ───────────────────────────────────────────────
count 
csdid unmem [iw = pop], ivar(state) time(year) gvar(rtw_year) ///
      method(dripw) post
estat simple, post	  
nlcom unmem : _b[ATT],post
est sto unmem
	  


* ── reduced form ──────────────────────────────────────────────
count 
csdid lnrw  [iw = pop], ivar(state) time(year) gvar(rtw_year) ///
      method(dripw) post
estat simple, post	  
nlcom lnrw : _b[ATT],post
est sto lnrw


/*-----------------------------------------------------------------
1 ▸ FIRST STAGE : RTW → union membership share
------------------------------------------------------------------*/


csdid  unmem [iw = pop],                                      ///
      ivar(state) time(year) gvar(rtw_year)                   ///
      controls(L1_unemp_rate L1_female L1_college L1_manuf    ///
               L1_black L1_foreign  ) ///
      method(dripw) post
estat simple
estat event, window(-5 10)
csdid_plot

matrix m1 = r(table)              // 1st row = coef, 2nd = s.e.
scalar b_union  = m1[1,1]         // β̂_1st
scalar se_union = m1[2,1]
est store csdid_union             // keep for a results table

/*-----------------------------------------------------------------
2 ▸ REDUCED FORM : RTW → ln(real wage)
------------------------------------------------------------------*/
csdid  lnrw  [iw = pop],                                     ///
      ivar(state) time(year) gvar(rtw_year)                  ///
      controls(L1_unemp_rate L1_female L1_college L1_manuf   ///
               L1_black L1_foreign  ) ///
      method(dripw) post

matrix m2 = r(table)
scalar b_wage  = m2[1,1]          // β̂_RF
scalar se_wage = m2[2,1]
est store csdid_wage

/*-----------------------------------------------------------------
3 ▸ WALD RATIO  θ  and delta-method standard error
   θ = β̂_RF / β̂_1st
------------------------------------------------------------------*/
scalar theta = b_wage / b_union
scalar se_theta = abs(theta) * sqrt( (se_wage/b_wage)^2 ///
                                   + (se_union/b_union)^2 )

display "-------------------------------------------"
display "Wald ratio (θ)  = " %8.4f theta
display "Delta-method s.e. = " %8.4f se_theta
display "z-stat = " %6.2f (theta/se_theta)
display "-------------------------------------------"



**********************************************************************
* 5 ▸ Two-way fixed effects (reghdfe)
**********************************************************************
reghdfe unmem rtw                                                      ///
        L1_unemp_rate L1_female L1_college L1_manuf L1_black L1_foreign ///
        L1_publicjob                   ///
        [pw = pop], absorb(state year) vce(cluster state)
est store twfe_rich

csdid unmem [iw = pop],                                                ///
      ivar(state) time(year) gvar(rtw_year)                            ///
      controls(L1_unemp_rate L1_female L1_college L1_manuf L1_black    ///
               L1_foreign L1_publicjob )                                             ///
      method(dripw) post
estat simple
estat event, window(-5 10)
csdid_plot
est store csdid_rich

csdid lnrw [iw = pop],                                                ///
      ivar(state) time(year) gvar(rtw_year)                            ///
      controls(L1_unemp_rate L1_female L1_college L1_manuf L1_black    ///
               L1_foreign L1_publicjob )                                             ///
      method(dripw) post
estat simple
estat event, window(-5 10)
csdid_plot
est store csdid_rich2


* 2  Goodman-Bacon decomposition with all three options
bys state: egen pop_state = mean(pop)   // or max(pop) — any constant works


bacondecomp unmem rtw [pw = pop_state],                          ///
           ddetail                                               ///
           stub(bacon_)                                          ///
           gropt(title("Goodman–Bacon weights: RTW and union membership") ///
                 note("Circles = Early v Late, Triangles = Late v Early, X's = Never v Timing") ///
                 legend(rows(1) pos(6)))

* 3  Inspect negative weights 
matrix list e(wt)          // inspect visually

* Automatic count
local neg 0
forval j = 1/`=colsof(e(wt))' {
    if (e(wt)[1,`j'] < 0) local ++neg
}
di "Negative weights: `neg'"


* csdid 
csdid unmem  [iw = pop], ///
      ivar(state) time(year) gvar(rtw_year)  ///
      controls(L1_unemp /* add your lagged demos if used */)  ///
      method(dripw)  post
estat simple
// plot the first stage
estat event, window(-10 10)
csdid_plot







* Callaway–Sant'Anna   

//keep if ind_2d == 40 & empl == 1
xtset state year

foreach v in female college manuf age unemp_rate {
    by state (year): gen L1_`v' = L.`v'
}

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


reghdfe unmem rtw [aw = pop], absorb(state year) vce(cluster state)


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




