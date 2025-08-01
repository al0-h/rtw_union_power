/*******************************************************************************
* FILE     : 00_Master.do
* PROJECT  : RTW Project
* PURPOSE  : Complies all the scripts
*
* CREATED  : 23 May 2025
* STATA    : StataNow/SE 18.5 for Mac (Apple Silicon) Revision 04 Sep 2024
*
* INPUTS   : - See README.md or README.md
*
* OUTPUTS  : - Complies all data and analysis in the paper
*
* REQUIRES : -
*
* NOTES    : - 
*
********************************************************************************/



net install scheme-modern, from("https://raw.githubusercontent.com/mdroste/stata-scheme-modern/master/")
net install grc1leg,from( http://www.stata.com/users/vwiggins/) 
set scheme modern
