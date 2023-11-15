clear all
*Setting up the working directory
cd "D:\AD TUS work\Processed Data in Stata Format(.dta)"

/*******************************
Creation of participation dummies 
*******************************/

//Loading the time spent data 
use TUS106_L05-001, clear

// creating individual level unique identification by combining household id and memeber serial number
gen iid = Common_ID + Serial_no_of_member

** breaking down 3 digit activity codes into 2 digit and single digit numbers for conviniently grouping activities
//Major Division - 1 digit codes
gen mdivision = substr(_3_didit_activity_code,1,1)

//Divison - 2 digit codes
gen division = substr(_3_didit_activity_code,1,2) 

//Activity - 3 digit codes
rename _3_didit_activity_code activity_group

//Converting the codes to int 
destring(division), replace
destring(activity_group), replace 
destring(mdivision), replace 

//saving temporary file to utilitse lateer 
tempfile edited_panel 
save `edited_panel', replace

** Creating dummies for participation based on TUS activity classification if indvidual performs the activity during anytime of the day and using egen function to report participation in the actvity for all entries of an id

//dummy for employment related activities 
gen emp = 1 if inlist(mdivision,1)

by iid (time_from), sort : egen Emp = max(emp)
replace emp = Emp 
drop Emp

//dummy for sna production 
gen sna =1 if inlist(division,11,12,13,14,15,16,53)
replace sna =1 if inlist(activity_group,181,511,512)
replace sna =1 if inlist(mdivision,1)

by iid (time_from), sort : egen SNA = max(sna)
replace sna = SNA
drop SNA 

//dummy for non-sna production 
gen n_sna =1 if inlist(mdivision,3,4)
replace n_sna=1 if inlist(activity_group,512,513,514,515,519,522,523,524,529)

by iid (time_from), sort : egen n_SNA = max(n_sna)
replace n_sna = n_SNA
drop n_SNA

//dummy for production of good for own use 
gen prod_own_use = 1 if inlist(mdivision,2)

by iid (time_from), sort : egen Prod_own_use = max(prod_own_use)
replace prod_own_use = Prod_own_use
drop Prod_own_use


//dummy for unpaid domestic services
gen hh =1 if inlist(mdivision,3)

by iid (time_from) , sort : egen Hh = max(hh)
replace hh = Hh
drop Hh

//dummy for unpaid caregiving services
gen care =1 if inlist(mdivision,4)

by iid (time_from) , sort : egen Unpaid_care = max(care)
replace care = Unpaid_care
drop Unpaid_care

// dummy for child_care 
gen child_care=1 if inlist(division,41)
replace child_care =1 if inlist(activity_group,442)

by iid (time_from) , sort : egen Child_care = max(child_care)
replace child_care = Child_care
drop Child_care

//dummy for elder_care
gen adult_care = 1 if inlist(division,42,43,49)
replace adult_care =1 if inlist(activity_group,441,443,444)

by iid (time_from) , sort : egen Adult_care = max(adult_care)
replace adult_care = Adult_care
drop Adult_care

//dummy for Leisure, culture, mass media dummy 
gen leisure =1 if inlist(mdivision,8)

by iid (time_from) , sort : egen Leisure = max(leisure)
replace leisure = Leisure
drop Leisure

//dummy for Self Care and maintenance 
gen self_care =1 if inlist(mdivision,9)

by iid (time_from), sort : egen Self_care = max(self_care)
replace self_care = Self_care
drop Self_care

//dummy for cooking 
gen cooking =1 if inlist(division, 31)

by iid (time_from), sort : egen Cooking = max(cooking)
replace cooking = Cooking 
drop Cooking 

//dummy for cleaning 
gen cleaning =1 if inlist(division, 32)

by iid (time_from), sort : egen Cleaning = max(cleaning)
replace cleaning = Cleaning 
drop Cleaning 

//dummy for livestock rearing 
gen livestock =1 if inlist(activity_group,212)

by iid (time_from), sort : egen Livestock = max(livestock)
replace livestock = Livestock
drop Livestock

//dummy for  firewood 
gen firewood = 1 if inlist(activity_group,241)

by iid (time_from), sort : egen Firewood = max(firewood)
replace firewood = Firewood
drop Firewood


//dummy for water 
gen water = 1 if inlist(activity_group,242)

by iid (time_from), sort : egen Water = max(water)
replace water = Water
drop Water

//dummy for washing clothes 
gen washing_clothes =1 if inlist(activity_group,341,342,343)

by iid (time_from), sort : egen Washing_clothes = max(washing_clothes)
replace washing = Washing_clothes
drop Washing_clothes

// dummy for paid_activites based on the classification in the questionnaire 
destring(unpaid_paid_status_of_activity), replace
gen paid_activity = 1 if unpaid_paid_status_of_activity >=13 

by iid (time_from), sort : egen Paid_activity = max(paid_activity)
replace paid_activity = Paid_activity 
drop Paid_activity

// dummy for unpaid activities based on the classification in the questionnaire
gen unpaid_activity=1 if inrange(unpaid_paid_status_of_activity,2,12)

by iid (time_from), sort : egen Unpaid_activity = max(unpaid_activity)
replace unpaid_activity = Unpaid_activity 
drop Unpaid_activity

// dummy for residual activities 
gen residual = 1 if unpaid_paid_status_of_activity ==1 

by iid (time_from), sort : egen Residual = max(residual)
replace residual = Residual 
drop Residual


** Keeping only unique entries for each individual for efficient merging and analysis - As we have marked the participation dummies for entries of the participant, that informatin will not be lost. 
duplicates drop iid , force

// saving the file in the directory to be utilised later for providing information on participation
tempfile activity_data 
save participation_dummies.dta,replace 
save `activity_data'

clear all

/*********************************
    estiamtes of composition
**********************************/

// loading individual level data 
use TUS106_L02, clear 

**creating individual level unique identification 
gen iid = Common_ID + Person_serial_no_

//Classifying people with age < 6 as child
destring(Age), replace
gen child =1 if Age < 6
replace child = 0 if child !=1

// Tagging each person in a household where a child was present 
by Common_ID, sort : egen Child = max(child)

// Creating a variable for total number of children in each household
by Common_ID, sort : egen t_child = total(child)
replace child = Child
drop Child 

// labeling the dummy values
label define childl 1 "HH with children beloww age 6 " 0 "HH with no children below age 6"
label values child childl 

***Repeating the same process for the presence of old or disabled

// marking a dummy based on age 
gen old = 1 if Age > 60 
replace old = 0 if old !=1 

// editing the dummy based on disability metric 
destring(usual_principal_activity__status), replace 
replace old =1 if usual_principal_activity__status == 95

by Common_ID, sort : egen Old = max(old)
replace old = Old 
drop Old 

// labeling the dummy values 
label define oldl 1 "HH with elderly person or PWD" 0 "HH with no elderly person or PWD"
label values old oldl

** Tagging each household where a working age women exists and calculating the total number of working age women in the household.
destring(Gender), replace 

//classifying any women between age 15-60 inclusive as working age women
gen women_working = 1 if Gender==2 & inlist(Age,15,60)
replace women_working = 0 if women_working!=1

// tagging all members of household if working age women exists 
by Common_ID, sort : egen Women_working = max(women_working)

// creating a new variable that marks the total number of working age women in the household for each member of the household
by Common_ID, sort : egen n_working_women = total(women_working)

replace women_working = Women_working
drop Women_working

// labeling the dummy values  
label define women_workingl 1 "HH with women of working age " 0 "HH with no women of working age"
label values women_working women_workingl


** Tagging houeholds with both a child and a disbaled or old person
gen old_child = 1 if old ==1 & child ==1 
replace old_child=0 if old_child==.

// tagging all memebers of the household 
by Common_ID, sort : egen Old_child = max(old_child)
replace old_child  = Old_child

// labeling the dummy values 
label define old_childl 1 "HH with child & elderly person/PWD" 0 " HH with no child & elderly person/PWD"
label values old_child old_childl 


// tabbing the newly created variables across the whole sample
preserve
duplicates drop Common_ID, force 

local hh_ch "child old old_child women_working"

foreach var in `hh_ch'{
	latab `var'
}
restore


** Merged with household level data to import all relevant household level identifier
merge m:1 Common_ID using TUS106_L03
drop _merge 

// saving the temp file to later utilise as indicator for household composition 
tempfile composition_dummies
save `composition_dummies'


/************************
Estimates of Time Spent 
***********************/


**Loading the time use data set 
use TUS106_L05-001, clear

*creating individual level unique identification
gen iid = Common_ID + Serial_no_of_member

*breaking down activity codes to conviniently grouping activities same as before 
gen mdivision = substr(_3_didit_activity_code,1,1)
gen division = substr(_3_didit_activity_code,1,2) 
rename _3_didit_activity_code activity_group
destring(division), replace
destring(activity_group), replace 
destring(mdivision), replace 


** Generating the time spent variable 

// creating variable to signify the start time and end time 
generate start_time = (clock(time_from,"hm"))/(60*1000)
generate end_time = clock(time_to, "hm")/(60*1000)
drop if end_time ==.

// if start time > end time then day is changing so accounting for the difference by adding 24 hours in the end _time 
replace end_time = end_time+ 1440 if start_time > end_time

// mins in each activity slot 
gen non_adjusted_mins = end_time-start_time

// adjusting for multiple activities in a time period by dividing the time equally between all activities executed at the same time
bysort iid time_from : egen n_act = count(time_from)
gen act_time = non_adjusted_mins/n_act
 
 
** Time spent calculations for various activities are carried out by finding the number of minutes in the time slot in which the activity was performed and then for each individual creating a new variable that sums up the minutes spend on that particular activity in the day.  

//time for unpaid domestic services
gen hh_time = (act_time) if inlist(mdivision,3)
replace hh_time = 0 if hh_time==.

by iid (time_from) , sort : egen Unpaid_hh_time = total(hh_time)
replace hh_time = Unpaid_hh_time
drop Unpaid_hh_time

// time for caregiving services 
gen care_time = (act_time) if inlist(mdivision,4)
replace care_time = 0 if care_time==.

by iid (time_from), sort : egen Care_time = total(care_time)
replace care_time=Care_time 
drop Care_time

//time for unpaid childcare services 
gen child_care_time = act_time if inlist(division,41)
replace child_care_time = act_time if inlist(activity_group,442)
replace child_care_time = 0 if child_care_time==.

by iid (time_from) , sort : egen Unpaid_childcare_time = total(child_care_time)
replace child_care_time = Unpaid_childcare_time
drop Unpaid_childcare_time

// time for unpaid adult care 
gen adult_care_time = act_time if inlist(division,42,43,49)
replace adult_care_time = act_time if inlist(activity_group,441,443,444)

by iid (time_from), sort : egen Unpaid_adultcare_time = total(adult_care_time)
replace adult_care_time = Unpaid_adultcare_time
drop Unpaid_adultcare_time

// time spent on employment related acitivies 
gen emp_time = act_time if inlist(mdivision,1)

by iid (time_from), sort : egen Emp_time = total(emp_time)
replace emp_time = Emp_time 
drop Emp_time

// time spent on Non-SNA work 
gen n_sna_time = act_time if inlist(mdivision,3,4)
replace n_sna_time = act_time if inlist(activity_group,512,513,514,515,519,522,523,524,529)

by iid (time_from), sort : egen N_sna_time = total(n_sna_time)
replace n_sna_time = N_sna_time
drop N_sna_time

// time spent on cooking 
gen cooking_time = act_time if inlist(division,31)

by iid (time_from), sort : egen Cooking_time = total(cooking_time)
replace cooking_time = Cooking_time
drop Cooking_time

// time spent on cleaning
gen cleaning_time = act_time if inlist(division,32)

by iid (time_from), sort : egen Cleaning_time = total(cleaning_time)
replace cleaning_time = Cleaning_time 
drop Cleaning_time 

// time spent on livestock_rearing 
gen livestock_time = act_time if inlist(activity_group,212)

by iid (time_from), sort : egen Livestock_time = total(livestock_time)
replace livestock_time = Livestock_time 
drop Livestock_time

// time spent on firewood collection 
gen firewood_time = act_time if inlist(activity_group,241)

by iid (time_from), sort : egen Firewood_time = total(firewood_time)
replace firewood_time = Firewood_time 
drop Firewood_time 

// time spent on water collection 
gen water_time = act_time if inlist(activity_group,242)

by iid (time_from), sort : egen Water_time = total(water_time)
replace water_time = Water_time 
drop Water_time

// time spent on washing clothes 
gen washing_time = act_time if inlist(activity_group, 341,342,343)

by iid (time_from), sort : egen Washing_time = total(washing_time)
replace washing_time = Washing_time
drop Washing_time

// time spent on enagagement in paid activity
destring( unpaid_paid_status_of_activity), replace  
rename unpaid_paid_status_of_activity paid_status

gen paid_activity_time = act_time if paid_status >= 13
by iid (time_from) , sort : egen Paid_activity_time = total(paid_activity_time)
replace paid_activity_time = Paid_activity_time
drop Paid_activity_time

// time spent on enagegement in unpaid activity 
gen unpaid_activity_time = act_time if inrange(paid_status,2,12)
by iid (time_from), sort : egen Unpaid_activity_time = total(unpaid_activity_time)
replace unpaid_activity_time = Unpaid_activity_time
drop Unpaid_activity_time

// time spent on engagement in residual activity 
gen residual_time = act_time if paid_status==1
by iid (time_from), sort : egen Residual_time = total(residual_time)
replace residual_time= Residual_time
drop Residual_time

** Calculating time spent on different categories of unpaid work 

label define unpaid_l 1 "self_care" 2 "other_care" 3"prod_serv" 4"prod_good" 5 "vo_prod_good" 6"vol_prod_serv" 7 "vol_prod_good_mkt" 8 "vol_prod_serv_mkt" 9 "trainee_good" 10 "trainee_serv" 11 "other_goods" 12"other_serv" 13 "emp_prod_goods" 14 "emp_prod_serv" 15 "salary_prod_good" 16 "salary_prod_serv" 17 "casual_prod_good" 18 "casual_prod_serv" 
label values paid_status unpaid_l 

// gen a new variable with labels of paid stauts 
decode (paid_status), gen(unpaid_tag)

// generating a dummy variable representing value 1 for each category of paid status - the command creates 18 new variables with mkt_time_ as a suffix before each numerical value 
tab paid_status, gen(mkt_time_)

// calculating time spent on each unpaid activity by limited to loop to unpaid activities 

forval i=1/12{
	replace mkt_time_`i' = 0 if mkt_time_`i'!= 1
	replace mkt_time_`i' = act_time if mkt_time_`i' == 1
	by iid (time_from), sort : egen Time_`i' = total(mkt_time_`i')
	replace mkt_time_`i' = Time_`i'
	drop Time_`i'
}

** only keeping unique entries for each id 
duplicates drop iid, force

*merging with individual level data to import all id level variables and then meging with the edited household level data
merge 1:1 iid using `composition_dummies'
drop if _merge ==2 | _merge ==1
drop _merge 
merge 1:1 iid using participation_dummies.dta 
drop if _merge ==2

/*************
Cleaning variables that will be utilised as controls and cuts for time spent stats 
*************/

** States

// generating state_codes using the codebook
gen state_codes = substr(NSS_Region,1,2)
destring(state_codes), replace 

// generating another state variable for merging SDP data 
gen State_name = state_codes
label define state_codesl 35 "Andaman and Nicobar Islands" 28 "Andhra Pradesh" 12 "Arunachal Pradesh" 18 "Assam" 10 "Bihar" 4 "Chandigarh" 22 "Chhattisgarh" 26 "Dadra & Nagar Haveli" 25 "Daman & Diu" 7 "Delhi" 30 "Goa" 24 "Gujarat" 6 "Haryana" 2 "Himachal Pradesh" 1 "Jammu and Kashmir" 20 "Jharkhand" 29 "Karnataka" 32 "Kerala" 31 "Lakshadweep" 23 "Madhya Pradesh" 27 "Maharashtra" 14 "Manipur" 17 "Meghalaya" 15 "Mizoram" 13 "Nagaland" 21 "Odisha" 34 "Puducherry" 3 "Punjab" 8 "Rajasthan" 11 "Sikkim" 33 "Tamil Nadu" 36 "Telangana" 16 "Tripura" 5 "Uttarakhand" 9 "Uttar Pradesh" 19 "West Bengal" 
label values State_name state_codesl

// match the name and type with the state variable in the SDP data
decode State_name, gen(state)
drop State_name
rename state State_name

//labeling states with short forms for each clear representation in graphs
label define state_abb 35 "A&N" 28 "AP" 12 "ANP" 18 "AS" 10 "BH" 4 "CH" 22 "CG" 26 "D&N" 25 "D&D" 7"DEL" 30"GOA" 24 "GUJ" 6"HAR" 2 "HP" 1 "J&K" 20 "JHA" 29"KAR" 32"KER" 31"LD" 23 "MP" 27 "MR" 14"MAN" 17"MEG" 15"MIZ" 13 "NL" 21"ODI" 24"PC" 3"PUN" 8"RJ" 11"SIK" 33"TN" 36"TEL" 16"TRI" 5"UK" 9"UP" 19"WB"
label values state_codes state_abb


** Sector 
destring(Sector), replace

//labeling sector values 
label define sectorl 1 "Rural" 2 "Urban"
label values Sector sectorl

** Social Group
destring(Social_group), replace 

//labeling caste group
label define castel 1 "ST" 2  "SC"  3 "OBC" 9 "Others"
label values Social_group castel 

** Religion
destring(religion), replace 

//labeling religion
label define Religionl 1"Hinduism" 2 "Islam" 3"Christianity" 4"Sikkhism" 5"Jainism" 6"Buddhism" 7 "Zoroastrianism" 9"others"
label values religion Religionl 

** Gender 
// already numeric so only needs to give labels 
label define Genderl 1"Male" 2"Female" 3"Third Gender" 
label values Gender Genderl

** MPCE 
destring(usual_monthly_consumer_expenditu), replace 
rename usual_monthly_consumer_expenditu MPCE

// creating 4 quantiles for the month consumption expenditure variable 
xtile MPCE_qrt = MPCE, nquantiles(4)

// labeling the different quantiles 
label define MPCE_l 1 "0-25" 2 "25-50" 3 "50-75" 4 "75-100"
label values MPCE_qrt MPCE_l

** Generation 
gen generation = 1 if Age <= 35
replace generation = 2 if Age > 35 

//labeling generationg
label define gen_l 1 "Young" 2 "Old"
label values generation gen_l


** Education 
// Generating different categories of education attained by individuals 
destring(highest_level_of_education), replace 
rename highest_level_of_education education 

replace education = 2 if education ==3| education ==4
replace education = 3 if education ==5 | education ==7
replace education = 4 if education ==8| education ==6
replace education = 5 if education >= 10 

// labeling the values 
label define edu_l 1 "Illiterate" 2 "Upto Middle School" 3"Secondary" 4"Higher Secondary" 5"Graduate and above" 
label values education edu_l

** Marital Status 
destring(marital_status),replace

save temporary.dta,replace

/***********
 Weighting the data set 
***********/

//defining p_weight
destring(MULT), replace
gen pweight = MULT/100

// generating primary survey unit
ren FSU_Serial_No psu
lab var psu "primary survey unit (village/block)"

// defining strata 
gen state= state_codes
gen sector = Sector
destring(Stratum Sub_Stratum),replace 
gen fs_strata = state + Sector + Stratum + Sub_Stratum
lab var fs_strata "first stage strata"

// defining the weight 
svyset psu [pw = pweight], strata(fs_strata) singleunit(centered)


/************
checking the cleaning of variables that have been utilised as cuts or controls 
*************/ 

// checking for the type 
des Social_group state_codes religion Sector MPCE_qrt generation Age education 

// checking for the values 
local cuts "Social_group religion Sector MPCE_qrt generation Age education"
foreach cut in `cuts'{
    tab `cut'
}
// checking for duplicate variables by browsing through list of all variables 
des

// Age and old_child have duplicate variables, so dropping the duplicates 
drop age Old_child

// dropping the third gender variable 
drop if Gender==3 

/*******************
Time spent means and participation rates 
*******************/
** By gender across the whole sample 

// creating a variable signifying all indviduals to match the numbers with total statistics in report 
gen Whole_sample =1 

// list of cuts 
local cats "Whole_sample Social_group religion Sector MPCE_qrt generation education "

// list of outcome variables 
local variable " hh_time care_time"

foreach var in `variable'{
	foreach cat in `cats'{
		collect :svy :  mean `var' , over(`cat' Gender) 
		collect layout (colname) (result[_r_b _r_se _r_ci]) (cmdset) 
// 		collect export "D:\AD TUS work\data folders\total time.xlsx", as (xlsx) sheet(`var'-`cat') cell(A1) modify
		collect clear
	}
}


// drop if Gender ==3 
// foreach var in `variable'{
// 	foreach cat in `cats'{
// 		svy : table (`cat' Gender) () (),  stat(count `var') stat(mean `var') stat(sd `var') stat(min `var') stat(max `var') stat(median `var') nformat(%9.1f mean) nformat(%9.1f sd)
// 		collect label levels result sd "Sd", modify
// 		collect label levels result min "Min", modify
// 		collect label levels result max "Max", modify
// 		collect label levels result count "N", modify
// 		collect  export "D:\AD TUS work\data folders\total time.xlsx", as (xlsx) sheet(`var'-`cat') cell(A1) modify
// 	}
// }


** By gender conditional on pariticipation

// list of cuts
local cats "Whole_sample Social_group religion Sector MPCE_qrt generation education"
// list of participation variable which is also the prefix of the outcome variable 
local varlist "hh care"

drop if Gender==3
foreach var in `varlist'{
	preserve 
	keep if `var'==1 
	foreach cat in `cats'{
		collect : svy : mean `var'_time, over(`cat' Gender)
		collect layout (colname) (result[_r_b _r_se _r_ci]) (cmdset)
// 		collect export "D:\AD TUS work\data folders\total time if participating.xlsx", as (xlsx) sheet(`var'-`cat') cell(A1) modify
		collect clear 
	}
	restore
}


// foreach var in `varlist'{
// 	preserve 
// 	keep if `var'==1
// 	foreach cat in `cats'{
// 		table (`cat' Gender) () (), stat(count `var'_time) stat(mean `var'_time) stat(sd `var'_time) stat(min `var'_time) stat(max `var'_time) stat(median `var'_time) nformat(%9.1f mean) nformat(%9.1f sd) 
// 		collect label levels result sd "Sd", modify
// 		collect label levels result min "Min", modify
// 		collect label levels result max "Max", modify
// 		collect label levels result count "N", modify
// 		collect export "D:\AD TUS work\data folders\total time if participating.xlsx", as (xlsx) sheet(`var'-`cat') cell(A1) modify
//		
// 	}
// 	restore
// }


** Participation rates in each of these activites 

// list of cuts
local cuts " Whole_sample Social_group religion Sector MPCE_qrt generation education"
// list of participation variable 
local varlist "hh care"

foreach cut in `cuts'{
	foreach var in `varlist'{
		bysort `cut' Gender : egen num_`var'_g_`cut' = total(`var'==1)
		bysort `cut' Gender : egen tot_`var'_g_`cut' = total(inlist(`var',.,1,0))
		gen `var'_g_`cut' = (num_`var'_g_`cut'/tot_`var'_g_`cut')*100
	}
}

foreach cut in `cuts'{
	preserve
	duplicates drop `cut' Gender, force 
	rename tot_hh_g_`cut' total_pop
	keep `cut' Gender total_pop hh_g_`cut' care_g_`cut'
// 	export excel using "D:\AD TUS work\data folders\particiation rates.xlsx", firstrow(variables) sheet(`cut') cell(A1) sheetmodify 
	restore
}

** By gender Time spent on market activies 

// variable indicating each entry in the sample 

preserve 
keep if Age>=6
local cuts "Whole_sample state_codes MPCE_qrt Sector generation education"
local vars "paid_activity_time unpaid_activity_time residual_time"

foreach var in `vars'{
	foreach cut in `cuts'{
		collect : svy : mean `var', over (`cut' Gender) 
		 collect layout (colname) (result[_r_b _r_se _r_ci]) (cmdset)
// 		 collect export "D:\AD TUS work\21 June\\ `var'.xlsx", as (xlsx) sheet (`cut') cell (A1) modify
		 collect clear 
	}
}
restore

// foreach var in `vars'{
// 	foreach cut in `cuts'{
// 		table (`cut' Gender) () (), stat(count `var') stat(mean `var') stat(sd `var') stat(min `var') stat(max `var') stat(median `var') nformat(%9.1f mean) nformat(%9.1f sd)
// 		collect label levels result sd "Sd", modify
// 		collect label levels result min "Min", modify
// 		collect label levels result max "Max", modify
// 		collect label levels result count "N", modify
//         collect export "D:\AD TUS work\21 June\\ `var'.xlsx", as (xlsx) sheet (`cut') cell (A1) modify
// 	}
// }
// restore


** By gender time spent on market activities conditional on participation 

local cuts "Whole_sample MPCE_qrt Sector generation education"
local vars "paid_activity unpaid_activity residual"
foreach var in `vars'{
	preserve 
	keep if Age > = 6 
	keep if `var'==1 
	foreach cut in `cuts'{
		collect : svy : mean `var'_time , over (`cut' Gender)
		collect layout (colname) (result[_r_b _r_se _r_ci]) (cmdset)
// 		collect export "D:\AD TUS work\21 June\\ `var'_participation.xlsx", as (xlsx) sheet (`cut') cell (A1) modify
		collect clear 
	}
	restore
}

// foreach var in `vars'{
// 	preserve 
// 	keep if Age>=6
// 	keep if `var'==1
// 	foreach cut in `cuts'{
// 		table (`cut' Gender) () (), stat(count `var'_time) stat(mean `var'_time) stat(sd `var'_time) stat(min `var'_time) stat(max `var'_time) stat(median `var'_time) nformat(%9.1f mean) nformat(%9.1f sd)
// 		collect label levels result sd "Sd", modify
// 		collect label levels result min "Min", modify
// 		collect label levels result max "Max", modify
// 		collect label levels result count "N", modify
// 		collect export "D:\AD TUS work\21 June\\ `var'_participation.xlsx", as (xlsx) sheet (`cut') cell (A1) modify
// 	}
// 	restore
// }

/***********
graphs 
***********/

// Creating state wise particiation rates in employement and non-sna activities
forval i=1/2{
	// calculating state wise total number of people engaging in employment activities for each gender
	bysort state_codes : egen num_employed_`i' = total(emp==1) if Gender == `i'
	bysort state_codes : egen Num_employed_`i' = max(num_employed_`i')
	replace num_employed_`i' = Num_employed_`i'
	// calculating state wise total number of people of each gender 
	bysort state_codes : egen total_employed_`i' = total(inlist(Gender,`i'))
	// using the above two variables to calculated state wise employment rate
	gen employment_rate_`i' = (num_employed_`i'/total_employed_`i')*100
    
	// calculating state wise non-sna participation rates by following the same method as above 
	bysort state_codes : egen num_n_sna_`i' = total(n_sna==1) if Gender==`i'
	bysort state_codes : egen Num_n_sna_`i' = max(num_n_sna_`i')
	replace num_n_sna_`i' = Num_n_sna_`i'
	bysort state_codes : egen total_n_sna_`i' = total(inlist(Gender,`i'))
	gen n_sna_rate_`i' =  (num_n_sna_`i'/total_n_sna_`i')*100
	
	// calculating state wise average time spent in employment and non-sna activities for each gender 
	bysort state_codes : egen avg_emp_time_`i' = mean(emp_time) if Gender ==`i' & emp==1
	bysort state_codes : egen Avg_emp_time_`i' = max(avg_emp_time_`i') 
	replace avg_emp_time_`i' = Avg_emp_time_`i'
	bysort state_codes :egen avg_n_sna_time_`i' = mean(n_sna_time) if Gender ==`i' & n_sna==1
	bysort state_codes : egen Avg_n_sna_time_`i' = max(avg_n_sna_time_`i')
	replace avg_n_sna_time_`i' = Avg_n_sna_time_`i'
}

// plotting relationship between non-sna participation and employemnt and the respective rates for men and women
preserve 
keep state_codes Gender employment_rate_* n_sna_rate_* avg_emp_time_* avg_n_sna_time_* 
duplicates drop state_codes, force
graph twoway (lfit employment_rate_1 n_sna_rate_1) scatter employment_rate_1 n_sna_rate_1,  symbol(o)  mcolor(gs1) mlabel(state_codes) legend(off) ytitle("Employment rate among men (%)") xtitle("Participation rate in Non-SNA acitivities among men (%)")
// graph save "D:\AD TUS work\data folders\Participation rate men.gph", replace
graph twoway (lfit employment_rate_2 n_sna_rate_2) scatter employment_rate_2 n_sna_rate_2,  symbol(o)  mcolor(gs1) mlabel(state_codes) legend(off) ytitle("Employment rate among women (%)") xtitle("Participation rate in Non-SNA acitivities among women (%)")
// graph save "D:\AD TUS work\data folders\Participation rate women.gph", replace
graph twoway (lfit avg_emp_time_1 avg_n_sna_time_1) scatter avg_emp_time_1 avg_n_sna_time_1,  symbol(o)  mcolor(gs1) mlabel(state_codes) legend(off) ytitle("Average time spent on employment activities among men") xtitle("Average time spent on Non-SNA activities among men")
// graph save "D:\AD TUS work\data folders\Time spent men.gph", replace
graph twoway (lfit avg_emp_time_2 avg_n_sna_time_2) scatter avg_emp_time_2 avg_n_sna_time_2,  symbol(o)  mcolor(gs1) mlabel(state_codes) legend(off) ytitle("Average time spent on employment activities among women") xtitle("Average time spent on Non-SNA activities among women")
// graph save "D:\AD TUS work\data folders\Time spent wommen.gph", replace
restore

** Time spent on Market activites across states
// Merging with SDP data 
merge m:1 State_name using SDP.dta, gen(merge3)
drop if merge3== 2
destring(SDP), replace

// labeling SDP 
label var SDP "Per Capita NSDP 18-19"

preserve 
keep if Age >=15

// calculating state wise average time spent on paid and unpaid activities for each Gender 
forval i=1/2{
	bysort state_codes : egen total_time_paid_`i' = mean(paid_activity_time) if Gender==`i'
	bysort state_codes : egen total_time_unpaid_`i' = mean(unpaid_activity_time) if Gender==`i'
}

// plotting the relationship between average time spent on market activities and SDP 

graph twoway (lfit total_time_paid_1 SDP ) scatter total_time_paid_1 SDP, symbol(o)  mcolor(gs1) mlabel(state_codes) legend(off) ytitle("Average time spent on paid activities among men") xtitle("NSDP Per Capita (Rs.)")
// graph save "D:\AD TUS work\21 June\Paid Market Activity Men.gph", replace
graph twoway (lfit total_time_paid_2 SDP ) scatter total_time_paid_2 SDP, symbol(o)  mcolor(gs1) mlabel(state_codes) legend(off) ytitle("Average time spent on paid activities among women") xtitle("NSDP Per Capita (Rs.)")
// graph save "D:\AD TUS work\21 June\Paid Market Activity Women.gph", replace
graph twoway (lfit total_time_unpaid_1 SDP ) scatter total_time_unpaid_1 SDP, symbol(o)  mcolor(gs1) mlabel(state_codes) legend(off) ytitle("Average time spent on unpaid activities among men") xtitle("NSDP Per Capita (Rs.)")
// graph save "D:\AD TUS work\21 June\Unpaid Market Activity Men.gph", replace
graph twoway (lfit total_time_unpaid_2 SDP ) scatter total_time_unpaid_2 SDP, symbol(o)  mcolor(gs1) mlabel(state_codes) legend(off) ytitle("Average Time spent on unpaid activities among women") xtitle("NSDP Per Capita (Rs.)")
// graph save "D:\AD TUS work\21 June\Unpaid Market Activity Women.gph", replace

restore


/************
Regression Results
************/ 

** Coefficient plot of time spent on unpaid activies between men and women 

// variable for different Employment Categories 

gen Employment = 1 if usual_principal_activity__status < 31 
replace Employment = 2 if usual_principal_activity__status == 31
replace Employment = 3 if inlist(usual_principal_activity__status,41,51)
replace Employment = 0 if usual_principal_activity__status > 81

// defining labels for employment and marital status 
label define Employment_l 1 "Self-Employed" 2 "Salaried Employee" 3 "Casual Labour" 0 "Not Employed"
label values Employment Employment_l

label define ms_l 1 "Never Married" 2 "Currently Married" 3 "Widowed" 4 "Divorced"
label values marital_status ms_l

// generating a new variable representing females
gen Female = 1 if Gender == 2 
replace Female = 0 if Gender ==1 

eststo clear 
forval i =1/12{
	preserve
	replace mkt_time_`i' = mkt_time_`i'/60
	keep if mkt_time_`i' !=0
	eststo a_`i' : svy : reg mkt_time_`i' Female Age i.education i.Employment i.marital_status, absorb(state_codes) 
	restore 
}

coefplot (a_1 , aseq(Self Care) \ a_2, aseq(Others' care) \ a_3, aseq(Prod'n services own cons'm) \ a_4, aseq(Prod'n good own cons'm) \ a_5,  aseq(Vol. prod'n goods ) \ a_6, aseq(Vol. prod'n services) \ a_7, aseq(Vol. prod'n mkt goods) \ a_8, aseq(Vol. prod'n mkt services) \ a_9, aseq(Trainee prod'n goods) \ a_10, aseq(Trainee prod'n services) \ a_11, aseq(Unpaid prod'n goods) \ a_12, aseq(Unpaid prod'n services)), keep(Female) vertical aseq swapnames xlabel(, angle(45)) title("Female Time allocation on unpaid market activies compared to men (hours)",size(textsizestyle))
// graph save "D:\AD TUS work\21 June\Gender comparison across unpaid mkt activies 2.gph", replace

eststo clear


** Impact of individual characterstics on Time Allocation 
preserve 
// creating a dummy that takes value one if individual is feamle and older than 5 years 
gen a_women = 1 if Gender==2 & Age >=6 
replace a_women=0 if a_women!=1

// creating a vriable that notes down the total number non-child females in the household for all memebrs of the household 
bysort Common_ID : egen t_a_women = total(a_women)

// creating a variable that notes down the numbre of additional women in the houeshold for each women in the household
gen t_add_women = t_a_women-1


// Limiting the data to working age population
keep if Age >=15 

// Creating appropriate labels for control variables

label variable t_child "Total Children in HH"
label variable t_a_women "Total Women in HH"
label variable t_add_women "Total Additional Women in HH"

// for convinient looping
rename (unpaid_activity_time paid_activity_time) (up p)

// coverting time spent to hours 
replace up = up/60 
replace p = p/60

label variable up "Unpaid Work"
label variable p "Paid Work"

local varlist "up p"

foreach var in `varlist'{
	eststo `var'_1 :svy : reg `var' t_child t_a_women  i.education i.marital_status i.Employment Age if Gender ==1, absorb(state_codes) 
	eststo `var'_2 : svy : reg `var' t_child t_add_women  i.education  i.marital_status i. Employment Age if Gender ==2 , absorb(state_codes) 	
}

// esttab up_1 p_1 up_2 p_2 using "Replication_table.tex", replace ///
// b(3) se(3) label star (* 0.10 ** 0.05  *** 0.01) nobaselevels r2 ///
// refcat(2.education "Education (w.r.t Illiterate)" 1.Employment "Employment (w.r.t Not_Employed)" 2.marital_status "Marital Status (w.r.t Never Married)", nolab) ///
// mgroups ("Male" "Female", pattern(1 0 1 0) ///
// prefix(\multicolumn{@span}{c}{) suffix(}) ///
// span erepeat(\cmidrule(lr){@span})) booktabs title({Impact of individual characterstics on Time Allocation (in hours)}) ///
// addnotes(State fixed effects are included.)

eststo clear
restore  


*Estimates for time spent on unpaid domestic and care work
**************
//definig labels for outcome variable 
label variable hh_time "Time spent on unapid domestic activities"
label variable care_time "Time spent on unapid caregiving activities"

label variable child "Child present in hh"
label variable old "Dependent adult present in hh"
label variable old_child "Child and dependent adult present in hh"
label variable n_working_women "No. of working women"

// list of independent variables 
local composition "child old old_child"
// list of outcome variable  
local outcome "hh_time care_time "

//list of controls 
local controls "i.Sector Age i.Social_group i.religion i.MPCE_qrt i.education"

** Impact of presence of dependent family members on time spent in domestic and care work
foreach var in `composition'{
	preserve
	keep if Gender ==2 
	foreach output in `outcome'{
		eststo : svy :reg `output' `var' `controls', absorb(state_codes) 
	}
// 	esttab using "`var'_present.tex", replace ///
// 		b(3) se(3)  label star(* 0.10 ** 0.05  *** 0.01) nobaselevels r2 ///
// 		refcat(2.education "Education (w.r.t Illiterate)" 2.Sector "Sector (w.r.t Rural)" 2.Social_group "Social group (w.r.t ST)" 2.religion "Religion (w.r.t Hinduism)" 2.MPCE_qrt "MPCE (w.r.t bottom 25\%)", nolab) ///
// 		booktabs title({Impact of presence of dependent family members on time spent in unpaid domestic and care work for women}) ///
// 		addnotes(State fixed effects are included.)
//         prefix(\multicolumn{@span}{c}{) suffix(}) ///             	
	eststo clear
	restore 	
}

** Impact of presence of working women in household 
foreach output in `outcome'{
	preserve 
	keep if Gender ==2 
	keep if women_working==1
	eststo : svy : reg `output' n_working_women `controls', absorb(state_codes) 
	restore
}

// esttab using "working_women.tex", replace ///
// 		b(3) se(3) nomtitle label star(* 0.10 ** 0.05  *** 0.01) nobaselevels r2 ///
// 		refcat(2.education "Education (w.r.t Illiterate)" 2.Sector "Sector (w.r.t Rural)" 2.Social_group "Social group (w.r.t ST)" 2.religion "Religion (w.r.t Hinduism)" 2.MPCE_qrt "MPCE (w.r.t bottom 25\%)", nolab) ///
//  booktabs title({Impact of total number of working women in hh on time spent in unpaid domestic and care work for women}) ///
//          addnotes(State fixed effects are included.)
eststo clear


** Participation in paid activities based on time spent in non-sna work 
preserve
keep if Age >= 15
replace paid_activity = 0 if paid_activity!=1

eststo : svy : probit paid_activity n_sna_time i.Gender `controls'
// esttab using "prob paid activity.tex" , replace ///
// 		b(3) se(3) nomtitle label star(* 0.10 ** 0.05  *** 0.01) nobaselevels r2 ///
// 		refcat(2.education "Education (w.r.t Illiterate)" 2.Sector "Sector (w.r.t Rural)" 2.Social_group "Social group (w.r.t ST)" 2.religion "Religion (w.r.t Hinduism)" 2.MPCE_qrt "MPCE (w.r.t bottom 25\%)", nolab) ///
//  booktabs title({Impact of time spent in non-sna activities on the probability of particiation in paid activity}) ///
         
eststo clear
restore


** Time spent on cooking depending on piped gas availability  
//defining piped gas 
destring(Primary_source_of_energey_for_co), replace
gen piped_gas =1 if inlist(Primary_source_of_energey_for_co,2,3,11)
replace piped_gas = 0 if piped_gas != 1

label define piped_gasl 1 "Piped Gas Present" 0 "No Piped Gas"
label values piped_gas piped_gasl
label variable piped_gas "Access to piped gas"

preserve 
keep if Gender ==2 
 
eststo : svy : reg cooking_time piped_gas `controls', absorb(state_codes) 
// esttab using "cooking time piped gas.tex", replace ///
// 		b(3) se(3) nomtitle label star(* 0.10 ** 0.05  *** 0.01) nobaselevels r2 ///
// 		refcat(2.education "Education (w.r.t Illiterate)" 2.Sector "Sector (w.r.t Rural)" 2.Social_group "Social group (w.r.t ST)" 2.religion "Religion (w.r.t Hinduism)" 2.MPCE_qrt "MPCE (w.r.t bottom 25\%)", nolab) ///
//  booktabs title({Impact of presence of piped gas in hh on time spent in cooking for women}) ///
//          addnotes(State fixed effects are included.)	
eststo clear 
restore 

** Time spent on household work depending on type of lighting source 
gen wired_source = 1 if Primary_source_of_energey_for_li=="1"
replace wired_source=0 if wired_source==.

label define wired_sourcel 1 "electricity" 2 "no electricity"
label values wired_source wired_sourcel
label variable wired_source "Access to electricity"

eststo: svy : reg hh_time wired_source `controls', absorb(state_codes) 

// esttab using "electricity.tex", replace ///
// 		b(3) se(3) nomtitle label star(* 0.10 ** 0.05  *** 0.01) nobaselevels r2 ///
// 		refcat(2.education "Education (w.r.t Illiterate)" 2.Sector "Sector (w.r.t Rural)" 2.Social_group "Social group (w.r.t ST)" 2.religion "Religion (w.r.t Hinduism)" 2.MPCE_qrt "MPCE (w.r.t bottom 25\%)", nolab) ///
//  booktabs title({Impact of presence of electricty in hh on time spent in unpaid domestic work for women}) ///
//          addnotes(State fixed effects are included.)
eststo clear
		

** Imapact of presence of person requiring special care on time spent in unpaid domestic work for women

// label define special_need 1 "Member requiring speical care with no caregiver present" 2" Member requiring speical care with no caregiver not present" 
destring(member_of_age_5_years_and_above_), replace 
rename member_of_age_5_years_and_above_ special_need
label variable special_need "Adults requiring special need present"

tab special_need 

// As there are many missing enteries for this variable - dropping the missing values 

preserve 
keep if special_need ==1 | special_need==2 
replace special_need=0 if special_need==2

label define special_need 1 "Member requiring speical care present but no cargiver" 0" Member requiring speical care with no caregiver not present" 

local controls "i.Sector Age i.Social_group i.religion i.MPCE_qrt i.education"
 
keep if Gender==2
eststo : svy : reg hh_time i.special_need `controls', absorb(state_codes) 
