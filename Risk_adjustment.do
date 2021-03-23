clear

// Import data

/*
set excelxlsxlargefile on
forvalues i=2007/2018 {
	local sheet_name = "State_county " + string(`i')
	import excel State=A County=B Total_pop=D FFS_pop=E MA_penetration=G Average_age=H ///
		Percent_Female=I Percent_Male=J Percent_white=K Percent_Black=L Percent_Hispanic=M ///
		Percent_duals=O Risk_score=P Actual_cost=U ///
		using "Geo_variation_PUF.xlsx", sheet(`sheet_name') allstring cellrange(A3) clear
	gen Year = `i'
	if `i' == 2007 {
		save Geo_var, replace
	}
	else {
		append using Geo_var.dta
		save Geo_var, replace
	} 
}
*/

// Strings to numerics

use Geo_var

destring Total_pop FFS_pop MA_penetration Average_age ///
		Percent_Female Percent_Male Percent_white Percent_Black Percent_Hispanic ///
		Percent_duals Risk_score Actual_cost, replace ignore("%") force
		
foreach var in MA_penetration Average_age Percent_Female ///
	Percent_Male Percent_white Percent_Black Percent_Hispanic Percent_duals{
	replace `var' = `var' / 100
}

// Generate USPCC

save intermediate_1, replace
keep if County== "NATIONAL TOTAL"

keep Year Actual_cost
rename Actual_cost USPCC

merge 1:m Year using intermediate_1

// Generate other variables

gen Expected_cost = Risk_score * USPCC
gen OE_cost = Actual_cost/Expected_cost
gen FIPS = State + "_" + County

// Delete counties without complete data

drop if strpos(County, "TOTAL")>0
egen missing = rowmiss(*)
drop if missing>0
bysort FIPS: egen records = count(Year)
drop if records<12

// Create lagged MA variable

sort FIPS Year
by FIPS: gen MA_penetration_lagged = MA_penetration[_n-1]
drop if Year == 2007

// Regression (will not compile on Stata/IC due to number of counties)

/*
egen FIPS_cat = group(FIPS)
regress OE_cost MA_penetration_lagged i.FIPS_cat i.Year Average_age Percent_Female Percent_white Percent_Black Percent_Hispanic Percent_duals
*/

// Produce Chart 1

xtile decile = MA_penetration_lagged, nq(10)
bysort decile: egen Expected_cost_mean = mean(Expected_cost)
bysort decile: egen Actual_cost_mean = mean(Actual_cost)
label var Actual_cost_mean "Actual cost"
label var Expected_cost_mean "Expected cost"
line Actual_cost_mean Expected_cost_mean decile, ///
ytitle("Average annual FFS cost, $") xtitle("Prior year MA-penetration decile") ///
title("Chart 1: Actual and expected FFS costs by MA-penetration")
