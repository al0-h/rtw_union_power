/****************************************************************************
* Script   : 02_Processing.do
*
* PROJECT  : RTW Project
* PURPOSE  : Create weights, person level controls, RTW indicators, and other helpful variables
*
* CREATED  : 23 May 2025
*
* STATA    : StataNow/SE 18.5 for Mac (Apple Silicon) Revision 04 Sep 2024
*
* INPUTS   : - ../Intm/Appended_CPS_ORG.dta
*
* OUTPUTS  : - ../Intm/RTW_Analysis.dta
*
* NOTES	   : - For more on weights https://ceprdata.org/cps-uniform-data-extracts/cps-outgoing-rotation-group/cps-org-faq/#weight
*
****************************************************************************/

log using "$folder/code/Logs/02_Processing", replace

use "$intm/Appended_CPS_ORG.dta" if   rtw_year >= 2003 & year >= 2003 , clear // 2000s onwards RTW states differ too much from pre 2000s RTW states. For consitency I'll stick to 2000s

* The link for the source of this formula for weights is in the notes 
gen wt=round(orgwgt/12,1) 

gen lf_w    = (empl==1 | unem==1) * wt            // labour-force = employed+unem
gen unemp_w = (unem==1)           * wt            // unemployed only

replace rtw_year = 0 if missing(rtw_year)


* Person-level Controls
gen black     = wbho==2   if !mi(wbho)
gen foreign   = forborn==1
gen publicjob = pubsect==1
gen college  = educ>=4                   if !mi(educ)       // Bachelor's or more

g rtw_stateind = rtw_year!=0

g lnrw = ln(rw) if !mi(rw)	

save "$intm/RTW_Analysis.dta", replace

log close
