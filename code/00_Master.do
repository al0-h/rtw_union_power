/*******************************************************************************
* FILE     : 00_Master.do
* PROJECT  : RTW Project
* PURPOSE  : Complies all the scripts for the analysis of the paper
*
* CREATED  : 23 May 2025
* STATA    : StataNow/SE 18.5 for Mac (Apple Silicon) Revision 04 Sep 2024
*
********************************************************************************/


* 	  Settings	     *
**********************

clear all
set more off
version 18.5

net install scheme-modern, from("https://raw.githubusercontent.com/mdroste/stata-scheme-modern/master/")
net install grc1leg,from( http://www.stata.com/users/vwiggins/) 
set scheme modern

* 	    Paths		 *
**********************

global folder "/Users/alexanderleon-hernandez/Desktop/rtw_union_power"
global data "$folder/Data"
global intm "$folder/Intm"
global figures "$folder/Presentations/Figures"
global tables "$folder/Presentations/Tables"


cd "$folder"       


/* ────────────────────────────────────────────────────────────────────────── *
 *                              Main Scripts   					              *
 * ────────────────────────────────────────────────────────────────────────── */

do "Code/01a_Create_CPS_RTW_ind.do"  // Prepares RTW_Years data set for panel data

do "Code/01b_Gen_Appended.do"	// Merges CPS ORG data from 1979-2003

do "Code/02_Processing.do"	// Creates analysis dataset with controls

do "Code/03a_Top_UnionShareInd.do"	// Creates figure with union share pre-rtw

do "Code/03b_TWFE_HetT10.do"	// plots estimates of TWFE of RTW on Union mem of T10 Union Ind

do "Code/03c_CSDID_HetT10.do"	// plots estimates of CSDID of RTW on Union mem of T10 Union Ind



