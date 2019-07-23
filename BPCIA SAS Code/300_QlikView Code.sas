******** Send Email when SAS is complete ********;
*Enabling the SMTP e-mail interface;
options emailsys = SMTP;
*Specifying a single SMTP server;
options emailhost = smtp.milliman.com;
* Add to and from email addresses;
%let to_email = shachi.mistry@milliman.com;
%let from_email = shachi.mistry@milliman.com;

%let _sdtm=%sysfunc(datetime());
options minoperator mprint nospool;
****************************************
****************************************
Bundled Payments for Care Improvement Advanced
BPCIA: 300_Qlikview Code
Code to create tables for dashboard 
****************************************
****************************************;

******************************************************************************
RUN THIS PROGRAM IN ITS OWN SAS SESSION TO PREVENT ANY DATA ROLLUP ISSUES
******************************************************************************
*****************
SET UP
*****************;

****** USER INPUTS ******************************************************************************************;
* TURN ON FOR BASELINE / TURN OFF FOR PERFORMANCE *****;
/*%let label = ybase; *Update with change in period;*/
/*%let prevlabel = ybase;*/
/*%let reporting_period=201806;*Change for every Update*; */

* TURN ON FOR PERFORMANCE / TURN OFF FOR BASELINE *****;
%let label = y201906; *Update with change in period;
%let prevlabel = y201905; *Update with the prior period;
%let reporting_period=201906;*Change for every Update*; 

* UPDATE WITH EVERY PERF UPDATE *****;
%let transmit_date = '17MAY2019'd;*Change for every Update*; 

* MAIN VS BASELINE INTERFACE *****;
%let mode = dev; *main=main interface, base = baseline interface;

proc printto;run;

****** REFERENCE PROGRAMS ***********************************************************************************;
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";

%let main = H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code;
%include "&main.\000 - BPCIA_Interface_BPIDs.sas";
%include "&main.\000 - Formats_Taxonomy_Provider_Specialty_Codes.sas";

%let main2 = H:\Nonclient\Medicare Bundled Payment Reference\General\SAS Code;
%include "&main2.\009 - Formats - Clinical Visits.sas";

****** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
libname in "&dataDir.\06 - Imported Raw Data\";

%macro modesetup;
%if &mode.=main %then %do;
libname out "&dataDir.\07 - Processed Data";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\300 - Qlikview Code_&label._&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=base %then %do;
libname out "&dataDir.\07 - Processed Data\Baseline Interface Demo";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\300 - Baseline Qlikview Code_&label._&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=dev %then %do;
libname out "&dataDir.\07 - Processed Data\Development";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\300 - Dev Qlikview Code_&label._&sysdate..log" print=print new;
run;
%end;
%mend modesetup;

%modesetup;

libname ref "H:\Nonclient\Medicare Bundled Payment Reference\General\SAS Datasets" ;
libname bpciaref "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets"; 
libname bench "R:\client work\CMS_PAC_Bundle_Processing\Benchmark Releases\v.201811";

****** EXPORT INFO *****************************************************************************************;
%let exportDir = R:\data\HIPAA\BPCIA_BPCI Advanced\90 - Sasout;


********************
********************
Calculation of Monthly Reports Datasets
********************
********************;

*** For Easy Troubleshooting of Macro Code ***;
/**/
/*%let label = y2017m03;*/
/*%let id = 310001;*/

/*Code to create anchor and post-acute values (T0-T3)*/
%macro expand_timeframes; 

proc sql;

*!! BPCIA JL Update - had to recode for OP index costs*;
create table report6 as
	select distinct EPI_ID_MILLIMAN
		  /*TIMEFRAME 0: ANCHOR INFORMATION*/
/*		  , 0 as Other_Anchor_Facility *Dummy Variables for BPCIA *;*/
		  ,case when timeframe in (0) and sumcat in ('IP_idx') then std_allowed_wage 
				when timeframe in (0) and anchor_type = "op" and sumcat = "N" then std_allowed_wage else . end as T0_IP_IDX_ALLOWED
		  ,case when timeframe in (0) and sumcat in ('IP_idx') then util_day else . end as T0_IP_IDX_UTIL_DAYS
		  ,case when timeframe in (0) and sumcat in ('IP_idx') then PROVIDER_CCN 
				when timeframe in (0) and anchor_type = "op" and sumcat = "N" then PROVIDER_CCN else "" end as T0_IP_IDX_CCN
		  ,case when timeframe in (0) and sumcat in ('IP_idx') then ANCHOR_BEG_DT 
				when timeframe in (0) and anchor_type = "op" and sumcat = "N" then dos else . end as T0_IP_IDX_STARTDATE format=mmddyy10.
		  ,case when timeframe in (0) and sumcat in ('IP_idx') then ANCHOR_END_DT else . end as T0_IP_IDX_ENDDATE format=mmddyy10.

		  /*TIMEFRAME 0: ANCHOR OTHER INFORMATION*/
		  ,case when timeframe in (0) and sumcat in ('Ambulance') then std_allowed_wage else . end as T0_AMBULANCE_ALLOWED
		  ,case when timeframe in (0) and (sumcat in ('Other','IP_s_F','IP_d_F','IP_LTAC_F','IP_Rehab_F','HH','SNF','OP_Rehab') or (anchor_type in ('ip') and sumcat in ('N')))  then std_allowed_wage else . end as T0_OTHER_ALLOWED
		  ,case when timeframe in (0) and sumcat in ('Anesthesia') then std_allowed_wage else . end as T0_ANESTHESIA_ALLOWED
		  ,case when timeframe in (0) and sumcat in ('Cardiovascular') then std_allowed_wage else . end as T0_CARDIO_ALLOWED
		  ,case when timeframe in (0) and sumcat in ('DME') then std_allowed_wage else . end as T0_DME_ALLOWED
		  ,case when timeframe in (0) and sumcat in ('Pathology') then std_allowed_wage else . end as T0_PATHOLOGY_ALLOWED
		  ,case when timeframe in (0) and sumcat in ('Radiology') then std_allowed_wage else . end as T0_RADIOLOGY_ALLOWED
		  ,case when timeframe in (0) and sumcat in ('Prof_IPVisits') then std_allowed_wage else . end as T0_PROF_IP_ALLOWED
		  ,case when timeframe in (0) and sumcat in ('Prof_Surgery') then std_allowed_wage else . end as T0_PROF_SURG_ALLOWED
		  ,case when timeframe in (0) and sumcat in ('OP_ER') then std_allowed_wage else . end as T0_EMERGENCY_ALLOWED


	%do TB=1 %to 3;
		  /*TIMEFRAME &TB.: READMIT ANCHOR INFORMATION*/
		  ,case when timeframe in (&TB.) and sumcat in ('IP_s_F') then std_allowed_wage else . end as T&TB._IP_A_FAC_ALLOWED
		  ,case when timeframe in (&TB.) and sumcat in ('IP_s_F') then util_day else . end as T&TB._IP_A_FAC_DAYS
		  ,case when timeframe in (&TB.) and sumcat in ('IP_s_F') then claims else . end as T&TB._IP_A_FAC_COUNT
		  ,case when timeframe in (&TB.) and sumcat in ('IP_s_F') then PROVIDER_CCN else "" end as T&TB._IP_A_FAC_CCN
		  ,case when timeframe in (&TB.) and sumcat in ('IP_s_F') then dos else . end as T&TB._IP_A_FAC_STARTDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('IP_s_F') then DSCHRG_DT else . end as T&TB._IP_A_FAC_ENDDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('IP_s_P') then std_allowed_wage else . end as T&TB._IP_A_PROF_ALLOWED

		  /*TIMEFRAME &TB.: ANCHOR OTHER INFORMATION*/
		  ,case when timeframe in (&TB.) and sumcat in ('IP_d_F') then std_allowed_wage else . end as T&TB._IP_O_FAC_ALLOWED
		  ,case when timeframe in (&TB.) and sumcat in ('IP_d_F') then util_day else . end as T&TB._IP_O_FAC_DAYS
		  ,case when timeframe in (&TB.) and sumcat in ('IP_d_F') then claims else . end as T&TB._IP_O_FAC_COUNT
		  ,case when timeframe in (&TB.) and sumcat in ('IP_d_F') then PROVIDER_CCN else "" end as T&TB._IP_O_FAC_CCN
		  ,case when timeframe in (&TB.) and sumcat in ('IP_d_F') then dos else . end as T&TB._IP_O_FAC_STARTDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('IP_d_F') then DSCHRG_DT else . end as T&TB._IP_O_FAC_ENDDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('IP_d_P') then std_allowed_wage else . end as T&TB._IP_O_PROF_ALLOWED

		  /*TIMEFRAME &TB.: LTAC INFORMATION*/
		  ,case when timeframe in (&TB.) and sumcat in ('IP_LTAC_F') then std_allowed_wage else . end as T&TB._LTAC_ALLOWED
		  ,case when timeframe in (&TB.) and sumcat in ('IP_LTAC_F') then util_day else . end as T&TB._LTAC_DAYS
		  ,case when timeframe in (&TB.) and sumcat in ('IP_LTAC_F') then PROVIDER_CCN else "" end as T&TB._LTAC_CCN
		  ,case when timeframe in (&TB.) and sumcat in ('IP_LTAC_F') then dos else . end as T&TB._LTAC_STARTDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('IP_LTAC_F') then DSCHRG_DT else . end as T&TB._LTAC_ENDDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('IP_LTAC_P') then std_allowed_wage else . end as T&TB._LTAC_PROF_ALLOWED

		  /*TIMEFRAME &TB.: IRF INFORMATION*/
		  ,case when timeframe in (&TB.) and sumcat in ('IP_Rehab_F') then std_allowed_wage else . end as T&TB._IRF_ALLOWED
		  ,case when timeframe in (&TB.) and sumcat in ('IP_Rehab_F') then util_day else . end as T&TB._IRF_DAYS
		  ,case when timeframe in (&TB.) and sumcat in ('IP_Rehab_F') then PROVIDER_CCN else "" end as T&TB._IRF_CCN
		  ,case when timeframe in (&TB.) and sumcat in ('IP_Rehab_F') then dos else . end as T&TB._IRF_STARTDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('IP_Rehab_F') then DSCHRG_DT else . end as T&TB._IRF_ENDDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('IP_Rehab_P') then std_allowed_wage else . end as T&TB._IRF_PROF_ALLOWED

		  /*TIMEFRAME &TB.: HH INFORMATION*/
		  ,case when timeframe in (&TB.) and sumcat in ('HH') then std_allowed_wage else . end as T&TB._HH_ALLOWED
		  ,case when timeframe in (&TB.) and sumcat in ('HH') then PROVIDER_CCN else "" end as T&TB._HH_CCN
		  ,case when timeframe in (&TB.) and sumcat in ('HH') then dos else . end as T&TB._HH_STARTDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('HH') then DSCHRG_DT else . end as T&TB._HH_ENDDATE format=mmddyy10.

		  /*TIMEFRAME &TB.: SNF INFORMATION*/
		  ,case when timeframe in (&TB.) and sumcat in ('SNF_F') then std_allowed_wage else . end as T&TB._SNF1_ALLOWED
		  ,case when timeframe in (&TB.) and sumcat in ('SNF_F') then PROVIDER_CCN else "" end as T&TB._SNF1_CCN
		  ,case when timeframe in (&TB.) and sumcat in ('SNF_F') then dos else . end as T&TB._SNF1_STARTDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('SNF_F') then DSCHRG_DT else . end as T&TB._SNF1_ENDDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('SNF_F') then CCN2 else "" end as T&TB._SNF2_CCN
		  ,case when timeframe in (&TB.) and sumcat in ('SNF_F') then dos2 else . end as T&TB._SNF2_STARTDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('SNF_F') then DSCHRG_DT2 else . end as T&TB._SNF2_ENDDATE format=mmddyy10.
		  ,case when timeframe in (&TB.) and sumcat in ('SNF_F') then util_day else . end as T&TB._SNF_DAYS
		  ,case when timeframe in (&TB.) and sumcat in ('SNF_F') then claims else . end as T&TB._SNF_COUNT
		  ,case when timeframe in (&TB.) and sumcat in ('SNF_P') then std_allowed_wage else . end as T&TB._SNF_PROF_ALLOWED

		  /*TIMEFRAME &TB.: OTHER ALLOWED COSTS*/
		  ,case when timeframe in (&TB.) and sumcat in ('Ambulance') then std_allowed_wage else . end as T&TB._AMBULANCE_ALLOWED
		  ,case when timeframe in (&TB.) and sumcat in ('PartB_Rx') then std_allowed_wage else . end as T&TB._PARTB_RX_ALLOWED
		  ,case when timeframe in (&TB.) and sumcat in ('Pathology') then std_allowed_wage else . end as T&TB._PATHOLOGY_ALLOWED
		  ,case when timeframe in (&TB.) and sumcat in ('Radiology') then std_allowed_wage else . end as T&TB._RADIOLOGY_ALLOWED 
		  ,case when timeframe in (&TB.) and sumcat in ('OP_Rehab') then std_allowed_wage else . end as T&TB._OP_REHAB_ALLOWED
		  ,case when timeframe in (&TB.) and sumcat in ('Other') then std_allowed_wage else . end as T&TB._OTHER_ALLOWED
	%end;

		  /*TIMEFRAME 4: READMIT ANCHOR INFORMATION*/
		  ,case when sumcat in ('IP_s_F') then sum(std_allowed_wage) else . end as T4_IP_A_FAC_ALLOWED
		  ,case when sumcat in ('IP_s_P') then sum(std_allowed_wage) else . end as T4_IP_A_PROF_ALLOWED
		  ,case when sumcat in ('IP_d_F') then sum(util_day) else . end as T4_IP_O_FAC_DAYS
		  ,case when sumcat in ('IP_d_F') then sum(claims) else . end as T4_IP_O_FAC_COUNT

		  /*TIMEFRAME 4: ANCHOR OTHER INFORMATION*/
		  ,case when sumcat in ('IP_d_F') then sum(std_allowed_wage) else . end as T4_IP_O_FAC_ALLOWED
		  ,case when sumcat in ('IP_d_P') then sum(std_allowed_wage) else . end as T4_IP_O_PROF_ALLOWED
		  ,case when sumcat in ('IP_s_F') then sum(util_day) else . end as T4_IP_A_FAC_DAYS
		  ,case when sumcat in ('IP_s_F') then sum(claims) else . end as T4_IP_A_FAC_COUNT

		  /*TIMEFRAME 4: LTAC INFORMATION*/
		  ,case when sumcat in ('IP_LTAC_F') then sum(std_allowed_wage) else . end as T4_LTAC_ALLOWED
		  ,case when sumcat in ('IP_LTAC_P') then sum(std_allowed_wage) else . end as T4_LTAC_PROF_ALLOWED
		  ,case when sumcat in ('IP_LTAC_F') then sum(util_day) else . end as T4_LTAC_DAYS

		  /*TIMEFRAME 4: IRF INFORMATION*/
		  ,case when sumcat in ('IP_Rehab_F') then sum(std_allowed_wage) else . end as T4_IRF_ALLOWED
		  ,case when sumcat in ('IP_Rehab_P') then sum(std_allowed_wage) else . end as T4_IRF_PROF_ALLOWED
		  ,case when sumcat in ('IP_Rehab_F') then sum(util_day) else . end as T4_IRF_DAYS

		  /*TIMEFRAME 4: HH INFORMATION*/
		  ,sum(case when sumcat in ('HH') and timeframe ^=0 then std_allowed_wage else . end) as T4_HH_ALLOWED

		  /*TIMEFRAME 4: SNF INFORMATION*/
		  ,sum(case when sumcat in ('SNF_F') and timeframe ^=0 then std_allowed_wage else . end) as T4_SNF_ALLOWED
		  ,sum(case when sumcat in ('SNF_P') and timeframe ^=0 then std_allowed_wage else . end) as T4_SNF_PROF_ALLOWED
		  ,sum(case when sumcat in ('SNF_F') and timeframe ^=0 then util_day else . end) as T4_SNF_DAYS
		  ,sum(case when sumcat in ('SNF_F') and timeframe ^=0 then claims else . end) as T4_SNF_COUNT

		  /*TIMEFRAME 4: OTHER ALLOWED COSTS*/
		  ,sum(case when sumcat in ('Ambulance') and timeframe ^=0 then std_allowed_wage else . end) as T4_AMBULANCE_ALLOWED
		  ,sum(case when sumcat in ('PartB_Rx') and timeframe ^=0 then std_allowed_wage else . end) as T4_PARTB_RX_ALLOWED
		  ,sum(case when sumcat in ('Pathology') and timeframe ^=0 then std_allowed_wage else . end) as T4_PATHOLOGY_ALLOWED
		  ,sum(case when sumcat in ('Radiology') and timeframe ^=0 then std_allowed_wage else . end) as T4_RADIOLOGY_ALLOWED
		  ,sum(case when sumcat in ('OP_Rehab') and timeframe ^=0 then std_allowed_wage else . end) as T4_OP_REHAB_ALLOWED
		  ,sum(case when sumcat in ('Other') and timeframe ^=0 then std_allowed_wage else . end) as T4_OTHER_ALLOWED

	from out.data3_&label._&bpid1._&bpid2. /*Might change based off the new 200 code */
	group by EPI_ID_MILLIMAN,sumcat
;

create table report6_1 as
	select distinct EPI_ID_MILLIMAN
		  /*TIMEFRAME 0: ANCHOR INFORMATION*/
		  ,sum(T0_IP_IDX_ALLOWED) as T0_IP_IDX_ALLOWED
		  ,sum(T0_IP_IDX_UTIL_DAYS) as T0_IP_IDX_UTIL_DAYS
		  ,min(T0_IP_IDX_CCN) as T0_IP_IDX_CCN
		  ,min(T0_IP_IDX_STARTDATE) as T0_IP_IDX_STARTDATE format=mmddyy10.
		  ,max(T0_IP_IDX_ENDDATE) as T0_IP_IDX_ENDDATE format=mmddyy10.
/*		  ,sum(Other_Anchor_Facility ) as Other_Anchor_Facility *Dummy Variables for BPCIA *;*/
		  ,sum(T0_EMERGENCY_ALLOWED) as T0_EMERGENCY_ALLOWED /*Dummy Variables for BPCIA */

		  /*TIMEFRAME 0: OTHER ANCHOR*/
		  ,sum(T0_AMBULANCE_ALLOWED) as T0_AMBULANCE_ALLOWED
		  ,sum(T0_ANESTHESIA_ALLOWED) as T0_ANESTHESIA_ALLOWED
		  ,sum(T0_CARDIO_ALLOWED) as T0_CARDIO_ALLOWED
		  ,sum(T0_DME_ALLOWED) as T0_DME_ALLOWED
		  ,sum(T0_OTHER_ALLOWED) as T0_OTHER_ALLOWED
		  ,sum(T0_PATHOLOGY_ALLOWED) as T0_PATHOLOGY_ALLOWED
		  ,sum(T0_PROF_IP_ALLOWED) as T0_PROF_IP_ALLOWED
		  ,sum(T0_PROF_SURG_ALLOWED) as T0_PROF_SURG_ALLOWED
		  ,sum(T0_RADIOLOGY_ALLOWED) as T0_RADIOLOGY_ALLOWED
		  ,sum(sum(T0_IP_IDX_ALLOWED),sum(T0_AMBULANCE_ALLOWED),sum(T0_ANESTHESIA_ALLOWED),sum(T0_CARDIO_ALLOWED),sum(T0_DME_ALLOWED),
		  	   sum(T0_OTHER_ALLOWED),sum(T0_PATHOLOGY_ALLOWED),sum(T0_PROF_IP_ALLOWED),sum(T0_PROF_SURG_ALLOWED),sum(T0_RADIOLOGY_ALLOWED),
			   sum(T0_EMERGENCY_ALLOWED))
			   as T0_TOTAL_ALLOWED
		  ,sum(sum(T0_AMBULANCE_ALLOWED),sum(T0_ANESTHESIA_ALLOWED),sum(T0_CARDIO_ALLOWED),sum(T0_DME_ALLOWED),
		  	   sum(T0_OTHER_ALLOWED),sum(T0_PATHOLOGY_ALLOWED),sum(T0_PROF_IP_ALLOWED),sum(T0_PROF_SURG_ALLOWED),sum(T0_RADIOLOGY_ALLOWED),
			   sum(T0_EMERGENCY_ALLOWED))
			   as T0_NONFACILITY_ALLOWED
		 
%do tp=1 %to 3;
		  /*TIMEFRAME &TP: READMIT ANCHOR INFORMATION*/
		  ,sum(T&TP._IP_A_FAC_ALLOWED) as T&TP._IP_A_FAC_ALLOWED
		  ,sum(T&TP._IP_A_FAC_DAYS) as T&TP._IP_A_FAC_DAYS
		  ,sum(T&TP._IP_A_FAC_COUNT) as T&TP._IP_A_FAC_COUNT
		  ,min(T&TP._IP_A_FAC_CCN) as T&TP._IP_A_FAC_CCN
		  ,min(T&TP._IP_A_FAC_STARTDATE) as T&TP._IP_A_FAC_STARTDATE format=mmddyy10.
		  ,max(T&TP._IP_A_FAC_ENDDATE) as T&TP._IP_A_FAC_ENDDATE format=mmddyy10.
		  ,sum(T&TP._IP_A_PROF_ALLOWED) as T&TP._IP_A_PROF_ALLOWED

		  /*TIMEFRAME &TP: ANCHOR OTHER INFORMATION*/
		  ,sum(T&TP._IP_O_FAC_ALLOWED) as T&TP._IP_O_FAC_ALLOWED
		  ,sum(T&TP._IP_O_FAC_DAYS) as T&TP._IP_O_FAC_DAYS
		  ,sum(T&TP._IP_O_FAC_COUNT) as T&TP._IP_O_FAC_COUNT
		  ,min(T&TP._IP_O_FAC_CCN) as T&TP._IP_O_FAC_CCN
		  ,min(T&TP._IP_O_FAC_STARTDATE) as T&TP._IP_O_FAC_STARTDATE format=mmddyy10.
		  ,max(T&TP._IP_O_FAC_ENDDATE) as T&TP._IP_O_FAC_ENDDATE format=mmddyy10.
		  ,sum(T&TP._IP_O_PROF_ALLOWED) as T&TP._IP_O_PROF_ALLOWED

		  /*TIMEFRAME &TP: LTAC INFORMATION*/
		  ,sum(T&TP._LTAC_ALLOWED) as T&TP._LTAC_ALLOWED
		  ,sum(T&TP._LTAC_DAYS) as T&TP._LTAC_DAYS
		  ,min(T&TP._LTAC_CCN) as T&TP._LTAC_CCN
 		  ,min(T&TP._LTAC_STARTDATE) as T&TP._LTAC_STARTDATE format=mmddyy10.
		  ,max(T&TP._LTAC_ENDDATE) as T&TP._LTAC_ENDDATE format=mmddyy10.
		  ,sum(T&TP._LTAC_PROF_ALLOWED) as T&TP._LTAC_PROF_ALLOWED

		  /*TIMEFRAME &TP: IRF INFORMATION*/
		  ,sum(T&TP._IRF_ALLOWED) as T&TP._IRF_ALLOWED
 		  ,sum(T&TP._IRF_DAYS) as T&TP._IRF_DAYS
		  ,min(T&TP._IRF_CCN) as T&TP._IRF_CCN 
		  ,min(T&TP._IRF_STARTDATE) as T&TP._IRF_STARTDATE format=mmddyy10.
		  ,max(T&TP._IRF_ENDDATE) as T&TP._IRF_ENDDATE format=mmddyy10.
		  ,sum(T&TP._IRF_PROF_ALLOWED) as T&TP._IRF_PROF_ALLOWED

		  /*TIMEFRAME &TP: HH INFORMATION*/
		  ,sum(T&TP._HH_ALLOWED) as T&TP._HH_ALLOWED
		  ,min(T&TP._HH_CCN) as T&TP._HH_CCN
		  ,min(T&TP._HH_STARTDATE) as T&TP._HH_STARTDATE format=mmddyy10.
		  ,max(T&TP._HH_ENDDATE) as T&TP._HH_ENDDATE format=mmddyy10.

		  /*TIMEFRAME &TP: SNF INFORMATION*/
		  ,sum(T&TP._SNF1_ALLOWED) as T&TP._SNF1_ALLOWED
		  ,min(T&TP._SNF1_CCN) as T&TP._SNF1_CCN
		  ,min(T&TP._SNF1_STARTDATE) as T&TP._SNF1_STARTDATE format=mmddyy10.
		  ,max(T&TP._SNF1_ENDDATE) as T&TP._SNF1_ENDDATE format=mmddyy10.
		  ,min(T&TP._SNF2_CCN) as T&TP._SNF2_CCN
		  ,min(T&TP._SNF2_STARTDATE) as T&TP._SNF2_STARTDATE format=mmddyy10.
		  ,max(T&TP._SNF2_ENDDATE) as T&TP._SNF2_ENDDATE format=mmddyy10.
		  ,sum(T&TP._SNF_DAYS) as T&TP._SNF_DAYS
		  ,sum(T&TP._SNF_COUNT) as T&TP._SNF_COUNT
		  ,sum(T&TP._SNF_PROF_ALLOWED) as T&TP._SNF_PROF_ALLOWED

		  /*TIMEFRAME &TP: OTHER ALLOWED COSTS*/
		 ,sum(T&TP._AMBULANCE_ALLOWED) as T&TP._AMBULANCE_ALLOWED
		  ,sum(T&TP._PARTB_RX_ALLOWED) as T&TP._PARTB_RX_ALLOWED
		  ,sum(T&TP._PATHOLOGY_ALLOWED) as T&TP._PATHOLOGY_ALLOWED
		  ,sum(T&TP._RADIOLOGY_ALLOWED) as T&TP._RADIOLOGY_ALLOWED
		  ,sum(T&TP._OP_REHAB_ALLOWED) as T&TP._OP_REHAB_ALLOWED
		  ,sum(T&TP._OTHER_ALLOWED) as T&TP._OTHER_ALLOWED

		  /*TIMEFRAME &TP: SUM OF COSTS*/
		  ,sum(max(T&TP._IP_A_FAC_ALLOWED),max(T&TP._IP_A_PROF_ALLOWED),max(T&TP._IP_O_FAC_ALLOWED),max(T&TP._IP_O_PROF_ALLOWED)
			  ,max(T&TP._LTAC_ALLOWED),max(T&TP._LTAC_PROF_ALLOWED),max(T&TP._IRF_ALLOWED),max(T&TP._IRF_PROF_ALLOWED),max(T&TP._HH_ALLOWED)
			  ,max(T&TP._SNF1_ALLOWED),max(T&TP._SNF_PROF_ALLOWED),max(T&TP._AMBULANCE_ALLOWED),max(T&TP._PARTB_RX_ALLOWED)
			  ,max(T&TP._PATHOLOGY_ALLOWED),max(T&TP._RADIOLOGY_ALLOWED),max(T&TP._OP_REHAB_ALLOWED),max(T&TP._OTHER_ALLOWED)) as T&TP._TOTAL_ALLOWED
%end;

		  /*TIMEFRAME 4: READMIT ANCHOR INFORMATION*/
		  ,max(T4_IP_A_FAC_ALLOWED) as T4_IP_A_FAC_ALLOWED
		  ,max(T4_IP_A_PROF_ALLOWED) as T4_IP_A_PROF_ALLOWED 
		  ,max(T4_IP_O_FAC_DAYS) as T4_IP_O_FAC_DAYS 
		  ,max(T4_IP_O_FAC_COUNT) as T4_IP_O_FAC_COUNT 


		  /*TIMEFRAME 4: ANCHOR OTHER INFORMATION*/
		  ,max(T4_IP_O_FAC_ALLOWED) as T4_IP_O_FAC_ALLOWED 
		  ,max(T4_IP_O_PROF_ALLOWED) as T4_IP_O_PROF_ALLOWED 
		  ,max(T4_IP_A_FAC_DAYS) as T4_IP_A_FAC_DAYS
		  ,max(T4_IP_A_FAC_COUNT) as T4_IP_A_FAC_COUNT 

		  /*TIMEFRAME 4: LTAC INFORMATION*/
		  ,max(T4_LTAC_ALLOWED) as T4_LTAC_ALLOWED 
		  ,max(T4_LTAC_PROF_ALLOWED) as T4_LTAC_PROF_ALLOWED 
		  ,max(T4_LTAC_DAYS) as T4_LTAC_DAYS 

		  /*TIMEFRAME 4: IRF INFORMATION*/
		  ,max(T4_IRF_ALLOWED) as T4_IRF_ALLOWED 
		  ,max(T4_IRF_PROF_ALLOWED) as T4_IRF_PROF_ALLOWED 
		  ,max(T4_IRF_DAYS) as T4_IRF_DAYS 

		  /*TIMEFRAME 4: HH INFORMATION*/
		  ,max(T4_HH_ALLOWED) as T4_HH_ALLOWED 

		  /*TIMEFRAME 4: SNF INFORMATION*/
		  ,max(T4_SNF_ALLOWED) as  T4_SNF_ALLOWED
		  ,max(T4_SNF_PROF_ALLOWED) as T4_SNF_PROF_ALLOWED 
		  ,max(T4_SNF_DAYS) as T4_SNF_DAYS
		  ,max(T4_SNF_COUNT) as T4_SNF_COUNT 

		  /*TIMEFRAME 4: OTHER ALLOWED COSTS*/
		  ,max(T4_AMBULANCE_ALLOWED) as T4_AMBULANCE_ALLOWED
		  ,max(T4_PARTB_RX_ALLOWED) as T4_PARTB_RX_ALLOWED
		  ,max(T4_PATHOLOGY_ALLOWED) as T4_PATHOLOGY_ALLOWED
		  ,max(T4_RADIOLOGY_ALLOWED) as T4_RADIOLOGY_ALLOWED
		  ,max(T4_OP_REHAB_ALLOWED) as T4_OP_REHAB_ALLOWED
		  ,max(T4_OTHER_ALLOWED) as T4_OTHER_ALLOWED

		  /*TIMEFRAME 4: TOTAL ALLOWED COSTS*/
		  ,sum(max(T4_IP_A_FAC_ALLOWED),max(T4_IP_A_PROF_ALLOWED),max(T4_IP_O_FAC_ALLOWED),max(T4_IP_O_PROF_ALLOWED)
			  ,max(T4_LTAC_ALLOWED),max(T4_LTAC_PROF_ALLOWED),max(T4_IRF_ALLOWED),max(T4_IRF_PROF_ALLOWED),max(T4_HH_ALLOWED)
			  ,max(T4_SNF_ALLOWED),max(T4_SNF_PROF_ALLOWED),max(T4_AMBULANCE_ALLOWED),max(T4_PARTB_RX_ALLOWED),max(T4_PATHOLOGY_ALLOWED)
			  ,max(T4_RADIOLOGY_ALLOWED),max(T4_OP_REHAB_ALLOWED),max(T4_OTHER_ALLOWED),sum(T0_IP_IDX_ALLOWED),max(T0_AMBULANCE_ALLOWED)
			  ,max(T0_ANESTHESIA_ALLOWED),max(T0_CARDIO_ALLOWED),max(T0_DME_ALLOWED)
			  ,sum(T0_OTHER_ALLOWED),max(T0_PATHOLOGY_ALLOWED),max(T0_PROF_IP_ALLOWED)
			  ,max(T0_PROF_SURG_ALLOWED),max(T0_RADIOLOGY_ALLOWED),max(T0_EMERGENCY_ALLOWED)) as T4_TOTAL_ALLOWED

	from report6
	group by EPI_ID_MILLIMAN
;
quit;

/*1-60 Days - JL Added 20170830*/
proc sql;
create table report6_2 as
	select	distinct
			a.*
		  /*TIMEFRAME 1_2: READMIT ANCHOR INFORMATION*/
		  ,sum(T1_IP_A_FAC_ALLOWED,T2_IP_A_FAC_ALLOWED) as T12_IP_A_FAC_ALLOWED
		  ,sum(T1_IP_A_PROF_ALLOWED,T2_IP_A_PROF_ALLOWED) as T12_IP_A_PROF_ALLOWED 
		  ,sum(T1_IP_A_FAC_DAYS,T2_IP_A_FAC_DAYS) as T12_IP_A_FAC_DAYS
		  ,sum(T1_IP_A_FAC_COUNT,T2_IP_A_FAC_COUNT) as T12_IP_A_FAC_COUNT 

		  /*TIMEFRAME 1_2: ANCHOR OTHER INFORMATION*/
		  ,sum(T1_IP_O_FAC_ALLOWED,T2_IP_O_FAC_ALLOWED) as T12_IP_O_FAC_ALLOWED
		  ,sum(T1_IP_O_PROF_ALLOWED,T2_IP_O_PROF_ALLOWED) as T12_IP_O_PROF_ALLOWED 
		  ,sum(T1_IP_O_FAC_DAYS,T2_IP_O_FAC_DAYS) as T12_IP_O_FAC_DAYS
		  ,sum(T1_IP_O_FAC_COUNT,T2_IP_O_FAC_COUNT) as T12_IP_O_FAC_COUNT 

		  /*TIMEFRAME 1_2: LTAC INFORMATION*/
		  ,sum(T1_LTAC_ALLOWED,T2_LTAC_ALLOWED) as T12_LTAC_ALLOWED 
		  ,sum(T1_LTAC_PROF_ALLOWED,T2_LTAC_PROF_ALLOWED) as T12_LTAC_PROF_ALLOWED 
		  ,sum(T1_LTAC_DAYS,T2_LTAC_DAYS) as T12_LTAC_DAYS 

		  /*TIMEFRAME 1_2: IRF INFORMATION*/
		  ,sum(T1_IRF_ALLOWED,T2_IRF_ALLOWED) as T12_IRF_ALLOWED
		  ,sum(T1_IRF_PROF_ALLOWED,T2_IRF_PROF_ALLOWED) as T12_IRF_PROF_ALLOWED 
		  ,sum(T1_IRF_DAYS,T2_IRF_DAYS) as T12_IRF_DAYS 

		  /*TIMEFRAME 1_2: HH INFORMATION*/
		  ,sum(T1_HH_ALLOWED,T2_HH_ALLOWED) as T12_HH_ALLOWED 

		  /*TIMEFRAME 1_2: SNF INFORMATION*/
		  ,sum(T1_SNF1_ALLOWED,T2_SNF1_ALLOWED) as  T12_SNF_ALLOWED
		  ,sum(T1_SNF_PROF_ALLOWED,T2_SNF_PROF_ALLOWED) as T12_SNF_PROF_ALLOWED 
		  ,sum(T1_SNF_DAYS,T2_SNF_DAYS) as T12_SNF_DAYS
		  ,sum(T1_SNF_COUNT,T2_SNF_COUNT) as T12_SNF_COUNT 

		  /*TIMEFRAME 1_2: OTHER ALLOWED COSTS*/
		  ,sum(T1_AMBULANCE_ALLOWED,T2_AMBULANCE_ALLOWED) as T12_AMBULANCE_ALLOWED
		  ,sum(T1_PARTB_RX_ALLOWED,T2_PARTB_RX_ALLOWED) as T12_PARTB_RX_ALLOWED
		  ,sum(T1_PATHOLOGY_ALLOWED,T2_PATHOLOGY_ALLOWED) as T12_PATHOLOGY_ALLOWED
		  ,sum(T1_RADIOLOGY_ALLOWED,T2_RADIOLOGY_ALLOWED) as T12_RADIOLOGY_ALLOWED
		  ,sum(T1_OP_REHAB_ALLOWED,T2_OP_REHAB_ALLOWED) as T12_OP_REHAB_ALLOWED
		  ,sum(T1_OTHER_ALLOWED,T2_OTHER_ALLOWED) as T12_OTHER_ALLOWED

		  /*TIMEFRAME 1_2: TOTAL ALLOWED COSTS*/
		  ,sum(T1_IP_A_FAC_ALLOWED,T1_IP_A_PROF_ALLOWED,T1_IP_O_FAC_ALLOWED,T1_IP_O_PROF_ALLOWED
			  ,T1_LTAC_ALLOWED,T1_LTAC_PROF_ALLOWED,T1_IRF_ALLOWED,T1_IRF_PROF_ALLOWED,T1_HH_ALLOWED
			  ,T1_SNF1_ALLOWED,T1_SNF_PROF_ALLOWED,T1_AMBULANCE_ALLOWED,T1_PARTB_RX_ALLOWED
			  ,T1_PATHOLOGY_ALLOWED,T1_RADIOLOGY_ALLOWED,T1_OP_REHAB_ALLOWED,T1_OTHER_ALLOWED
			  ,T2_IP_A_FAC_ALLOWED,T2_IP_A_PROF_ALLOWED,T2_IP_O_FAC_ALLOWED,T2_IP_O_PROF_ALLOWED
			  ,T2_LTAC_ALLOWED,T2_LTAC_PROF_ALLOWED,T2_IRF_ALLOWED,T2_IRF_PROF_ALLOWED,T2_HH_ALLOWED
			  ,T2_SNF1_ALLOWED,T2_SNF_PROF_ALLOWED,T2_AMBULANCE_ALLOWED,T2_PARTB_RX_ALLOWED
			  ,T2_PATHOLOGY_ALLOWED,T2_RADIOLOGY_ALLOWED,T2_OP_REHAB_ALLOWED,T2_OTHER_ALLOWED
			) as T12_TOTAL_ALLOWED
	from report6_1 as a
;
quit;
%mend expand_timeframes; 


/*MAIN MACRO FOR DASHBOARD DATASETS*/

%macro dashboard(bpid1,bpid2,epi_idx);

/*********************************************************************************************/
/* Code to Create Episode-level Detailed Dataset**********************************************/
/*********************************************************************************************/

proc sort data=out.data3_&label._&bpid1._&bpid2. out=report6_total_details;
	by EPI_ID_MILLIMAN  dos;
	where timeframe not in (0);
run;

/*Code to create "total episode values" (T4)*/
data report6_total_details2 (keep = BPID 				epi_id_milliman T4_IP_A_FAC_CCN 		T4_IP_A_FAC_STARTDATE 		T4_IP_A_FAC_ENDDATE
		   							T4_IP_O_FAC_CCN 	T4_IP_O_FAC_STARTDATE 		T4_IP_O_FAC_ENDDATE
								   	T4_LTAC_CCN 		T4_LTAC_STARTDATE 			T4_LTAC_ENDDATE
								   	T4_IRF_CCN 			T4_IRF_STARTDATE 			T4_IRF_ENDDATE
						 		   	T4_HH_CCN 			T4_HH_STARTDATE 			T4_HH_ENDDATE 
								   	T4_SNF_CCN 			T4_SNF_STARTDATE 			T4_SNF_ENDDATE);
	set report6_total_details;
	by epi_id_milliman;

	length T4_IP_A_FAC_CCN 		T4_IP_O_FAC_CCN 	T4_LTAC_CCN 	T4_IRF_CCN 		T4_HH_CCN 	T4_SNF_CCN $12;
	
	retain T4_IP_A_FAC_CCN 		T4_IP_A_FAC_STARTDATE 		T4_IP_A_FAC_ENDDATE
		   T4_IP_O_FAC_CCN 		T4_IP_O_FAC_STARTDATE 		T4_IP_O_FAC_ENDDATE
		   T4_LTAC_CCN 			T4_LTAC_STARTDATE 			T4_LTAC_ENDDATE
		   T4_IRF_CCN 			T4_IRF_STARTDATE 			T4_IRF_ENDDATE
 		   T4_HH_CCN 			T4_HH_STARTDATE 			T4_HH_ENDDATE 
		   T4_SNF_CCN 			T4_SNF_STARTDATE 			T4_SNF_ENDDATE;

	format T4_IP_A_FAC_STARTDATE 		T4_IP_A_FAC_ENDDATE
	   	   T4_IP_O_FAC_STARTDATE 		T4_IP_O_FAC_ENDDATE
	       T4_LTAC_STARTDATE 			T4_LTAC_ENDDATE
	       T4_IRF_STARTDATE 			T4_IRF_ENDDATE
 	       T4_HH_STARTDATE 				T4_HH_ENDDATE 
	       T4_SNF_STARTDATE 			T4_SNF_ENDDATE mmddyy10.;


	if first.epi_id_milliman then do;
		   T4_IP_A_FAC_CCN=''; 	T4_IP_A_FAC_STARTDATE=.;	T4_IP_A_FAC_ENDDATE=.;
		   T4_IP_O_FAC_CCN=''; 	T4_IP_O_FAC_STARTDATE=.; 	T4_IP_O_FAC_ENDDATE=.;
		   T4_LTAC_CCN=''; 		T4_LTAC_STARTDATE=.; 		T4_LTAC_ENDDATE=.;
		   T4_IRF_CCN=''; 		T4_IRF_STARTDATE=.; 		T4_IRF_ENDDATE=.;
 		   T4_HH_CCN=''; 		T4_HH_STARTDATE=.; 			T4_HH_ENDDATE=.;
		   T4_SNF_CCN=''; 		T4_SNF_STARTDATE=.; 		T4_SNF_ENDDATE=.;
	end;

	if sumcat in ('IP_s_F') and (T4_IP_A_FAC_STARTDATE in (.) or dos < T4_IP_A_FAC_STARTDATE) then do;
			T4_IP_A_FAC_CCN = PROVIDER_CCN; 		
			T4_IP_A_FAC_STARTDATE = dos;	 	
			T4_IP_A_FAC_ENDDATE = DSCHRG_DT;	
	end;

	else if sumcat in ('IP_d_F') and (T4_IP_O_FAC_STARTDATE in (.) or dos < T4_IP_O_FAC_STARTDATE) then do;
			T4_IP_O_FAC_CCN = PROVIDER_CCN; 		
			T4_IP_O_FAC_STARTDATE = dos;	 	
			T4_IP_O_FAC_ENDDATE = DSCHRG_DT;	
	end;

	else if sumcat in ('IP_LTAC_F') and (T4_LTAC_STARTDATE in (.) or dos < T4_LTAC_STARTDATE) then do;
			T4_LTAC_CCN = PROVIDER_CCN; 		
			T4_LTAC_STARTDATE = dos;	 	
			T4_LTAC_ENDDATE = DSCHRG_DT;	
	end;

	else if sumcat in ('IP_Rehab_F') and (T4_IRF_STARTDATE in (.) or dos < T4_IRF_STARTDATE) then do;
			T4_IRF_CCN = PROVIDER_CCN; 		
			T4_IRF_STARTDATE = dos;	 	
			T4_IRF_ENDDATE = DSCHRG_DT;	
	end;

	else if sumcat in ('HH') and (T4_HH_STARTDATE in (.) or dos < T4_HH_STARTDATE) then do;
			T4_HH_CCN = PROVIDER_CCN; 		
			T4_HH_STARTDATE = dos;	 	
			T4_HH_ENDDATE = DSCHRG_DT;	
	end;

	else if sumcat in ('SNF_F') and (T4_SNF_STARTDATE in (.) or dos < T4_SNF_STARTDATE) then do;
			T4_SNF_CCN = PROVIDER_CCN; 		
			T4_SNF_STARTDATE = dos;	 	
			T4_SNF_ENDDATE = DSCHRG_DT;	
	end;


	if last.epi_id_milliman then output;

run;

/*Code to create "total episode values" (T12) - JL Added 20170831*/
data report6_total_details1a;
	set report6_total_details;
	where timeframe in (1,2);
run;

data report6_total_details2a (keep = epi_id_milliman bpid T12_IP_A_FAC_CCN T12_IP_A_FAC_STARTDATE 		T12_IP_A_FAC_ENDDATE
		   							T12_IP_O_FAC_CCN 		T12_IP_O_FAC_STARTDATE 		T12_IP_O_FAC_ENDDATE
								   	T12_LTAC_CCN 			T12_LTAC_STARTDATE 			T12_LTAC_ENDDATE
								   	T12_IRF_CCN 			T12_IRF_STARTDATE 			T12_IRF_ENDDATE
						 		   	T12_HH_CCN 				T12_HH_STARTDATE 			T12_HH_ENDDATE 
								   	T12_SNF_CCN 			T12_SNF_STARTDATE 			T12_SNF_ENDDATE);
	set report6_total_details1a;
	by epi_id_milliman;

	length T12_IP_A_FAC_CCN 	T12_IP_O_FAC_CCN	T12_LTAC_CCN
		   T12_IRF_CCN 			T12_HH_CCN 			T12_SNF_CCN $12;
	
	retain T12_IP_A_FAC_CCN 	T12_IP_A_FAC_STARTDATE 		T12_IP_A_FAC_ENDDATE
		   T12_IP_O_FAC_CCN 	T12_IP_O_FAC_STARTDATE 		T12_IP_O_FAC_ENDDATE
		   T12_LTAC_CCN 		T12_LTAC_STARTDATE 			T12_LTAC_ENDDATE
		   T12_IRF_CCN 			T12_IRF_STARTDATE 			T12_IRF_ENDDATE
 		   T12_HH_CCN 			T12_HH_STARTDATE 			T12_HH_ENDDATE 
		   T12_SNF_CCN 			T12_SNF_STARTDATE 			T12_SNF_ENDDATE;

	format T12_IP_A_FAC_STARTDATE 		T12_IP_A_FAC_ENDDATE
	   	   T12_IP_O_FAC_STARTDATE 		T12_IP_O_FAC_ENDDATE
	       T12_LTAC_STARTDATE 			T12_LTAC_ENDDATE
	       T12_IRF_STARTDATE 			T12_IRF_ENDDATE
 	       T12_HH_STARTDATE 			T12_HH_ENDDATE 
	       T12_SNF_STARTDATE 			T12_SNF_ENDDATE mmddyy10.;


	if first.epi_id_milliman then do;
		   T12_IP_A_FAC_CCN=''; 	T12_IP_A_FAC_STARTDATE=.;	T12_IP_A_FAC_ENDDATE=.;
		   T12_IP_O_FAC_CCN=''; 	T12_IP_O_FAC_STARTDATE=.; 	T12_IP_O_FAC_ENDDATE=.;
		   T12_LTAC_CCN=''; 		T12_LTAC_STARTDATE=.; 		T12_LTAC_ENDDATE=.;
		   T12_IRF_CCN=''; 			T12_IRF_STARTDATE=.; 		T12_IRF_ENDDATE=.;
 		   T12_HH_CCN=''; 			T12_HH_STARTDATE=.; 		T12_HH_ENDDATE=.;
		   T12_SNF_CCN=''; 			T12_SNF_STARTDATE=.; 		T12_SNF_ENDDATE=.;
	end;
	
	if sumcat in ('IP_s_F') and (T12_IP_A_FAC_STARTDATE in (.) or dos < T12_IP_A_FAC_STARTDATE) then do;
			T12_IP_A_FAC_CCN = PROVIDER_CCN; 		
			T12_IP_A_FAC_STARTDATE = dos;	 	
			T12_IP_A_FAC_ENDDATE = DSCHRG_DT;	
	end;

	else if sumcat in ('IP_d_F') and (T12_IP_O_FAC_STARTDATE in (.) or dos < T12_IP_O_FAC_STARTDATE) then do;
			T12_IP_O_FAC_CCN = PROVIDER_CCN; 		
			T12_IP_O_FAC_STARTDATE = dos;	 	
			T12_IP_O_FAC_ENDDATE = DSCHRG_DT;	
	end;

	else if sumcat in ('IP_LTAC_F') and (T12_LTAC_STARTDATE in (.) or dos < T12_LTAC_STARTDATE) then do;
			T12_LTAC_CCN = PROVIDER_CCN; 		
			T12_LTAC_STARTDATE = dos;	 	
			T12_LTAC_ENDDATE = DSCHRG_DT;	
	end;

	else if sumcat in ('IP_Rehab_F') and (T12_IRF_STARTDATE in (.) or dos < T12_IRF_STARTDATE) then do;
			T12_IRF_CCN = PROVIDER_CCN; 		
			T12_IRF_STARTDATE = dos;	 	
			T12_IRF_ENDDATE = DSCHRG_DT;	
	end;

	else if sumcat in ('HH') and (T12_HH_STARTDATE in (.) or dos < T12_HH_STARTDATE) then do;
			T12_HH_CCN = PROVIDER_CCN; 		
			T12_HH_STARTDATE = dos;	 	
			T12_HH_ENDDATE = DSCHRG_DT;	
	end;

	else if sumcat in ('SNF_F') and (T12_SNF_STARTDATE in (.) or dos < T12_SNF_STARTDATE) then do;
			T12_SNF_CCN = PROVIDER_CCN; 		
			T12_SNF_STARTDATE = dos;	 	
			T12_SNF_ENDDATE = DSCHRG_DT;	
	end;

	if last.epi_id_milliman then output;

run;

%expand_timeframes

/*Combine T4 and T0-T3 timeframes*/
proc sql;
	create table report6_combined0 as
		select distinct a.*
			  ,b.*
		from report6_2 as a
			full join report6_total_details2 as b
			on a.epi_id_milliman = b.epi_id_milliman
	order by a.epi_id_milliman
		;
quit;


/*Combine T12 and T0-T4 timeframes - 20170831 - JL Update*/
proc sql;
	create table report6_combined as
		select	distinct
				a.*
			,	b.*
		from	report6_combined0 as a
				full join
				report6_total_details2a as b
				on a.epi_id_milliman = b.epi_id_milliman
		order by a.epi_id_milliman
;
quit;

proc contents data=report6_combined varnum;
run ; 


*BPCIA Update: Identify transfers - anchor facility DRGs and costs;
*identify and keep cost and DRG of very first facility;
proc sort data = out.ip_&label._&bpid1._&bpid2. out = ip_test; by epi_id_milliman transfer_stay stay_admsn_dt;
where type = 'IP_Idx';
run;

data dgcd1 (rename=(DGNSCD01 = primary_diag_code PRCDRCD01 = primary_proc_code AD_DGNS = admitting_diag_code));
	set ip_test;
	format anchor_facility_code $20.; length anchor_facility_code $20; 
	retain anchor_facility_code anchor_facility_cost;
	by epi_id_milliman;
	if first.epi_id_milliman then do;
		anchor_facility_code = strip(put(stay_drg_cd,$z3.));
		anchor_facility_cost = std_allowed_wage;
		transfer_flag = 0;
	end;
	else transfer_flag = 1;
	if last.epi_id_milliman then output;
run;

/*add description for primary diagnosis code to anchor */
/*add description for primary procedure code to anchor*/
/*add description for admitting diagnosis code to anchor*/
proc sql;


	create table dgcd2 as	
		select a.*
			,lowcase(b.diag_desc) as primary_diag_desc
			,lowcase(c.ICD9PROC_DESC) as primary_proc_desc
			,lowcase(d.diag_desc) as admitting_diag_desc
		from dgcd1 as a
		left join ref.Icd9diag_codemap as b
		on a.primary_diag_code = b.diag
		and ((a.STAY_DSCHRGDT < '01OCT2015'd and b.version = 9) or (a.STAY_DSCHRGDT >= '01OCT2015'd and b.version = 0)) 
		left join ref.Icd9proc_codemap as c
		on a.primary_proc_code = c.ICD9Proc
		and ((a.STAY_DSCHRGDT < '01OCT2015'd and c.version = 9) or (a.STAY_DSCHRGDT >= '01OCT2015'd and c.version = 0))	
		left join ref.Icd9diag_codemap as d
		on a.admitting_diag_code = d.diag
		and ((a.STAY_DSCHRGDT < '01OCT2015'd and d.version = 9) or (a.STAY_DSCHRGDT >= '01OCT2015'd and d.version = 0))
 
;
;


/*	create table dgcd3 as	*/
/*		select a.**/
/*		from dgcd2 as a*/

/*;*/


/*create combined code-description values for primary diag, admitting diag, and primary proc*/
	create table dgcd3 as 
		select a.*
		,case when primary_diag_code ="" then ""
			when primary_diag_code ^="" and primary_diag_desc ="" then primary_diag_code
			else strip(primary_diag_code)||": "||strip(primary_diag_desc)
				end as primary_diag_with_desc
		,case when admitting_diag_code ="" then ""
			when admitting_diag_code ^="" and admitting_diag_desc ="" then admitting_diag_code
			else strip(admitting_diag_code)||": "||strip(admitting_diag_desc)
				end as admitting_diag_with_desc
		,case when primary_proc_code ="" then ""
			when primary_proc_code ^="" and primary_proc_desc ="" then primary_proc_code
			else strip(primary_proc_code)||": "||strip(primary_proc_desc)
				end as primary_proc_with_desc
		from dgcd2 as a; 

/*add diagnosis and procedure anchor information to episode detail*/
proc sql;
create table report6_comb_drgs as
	 select a.*
		   ,b.primary_diag_code
		   ,b.primary_diag_desc
		   ,b.primary_diag_with_desc
		   ,b.admitting_diag_code
		   ,b.admitting_diag_desc
		   ,b.admitting_diag_with_desc
		   ,b.primary_proc_code
		   ,b.primary_proc_desc
		   ,b.primary_proc_with_desc
		   ,b.anchor_facility_code
		   ,b.anchor_facility_cost
		   ,b.transfer_flag
	from report6_combined as a
		left join dgcd3 as b
	on a.epi_id_milliman = b.epi_id_milliman 
	;
quit;

/*EPISODE DETAIL Starts */ 

data data1_&label._&bpid1._&bpid2. ;
	set out.data1_&label._&bpid1._&bpid2. ;
	format operating_npi attending_npi episode_initiator1 $20. ;
	operating_npi = strip(anchor_op_NPI) ;
	attending_npi = strip(anchor_at_NPI);
	if length(strip(episode_initiator))<=6 then episode_initiator1 = strip(put(episode_initiator,z6.));
		else episode_initiator1 = strip(episode_initiator);
run ;

/*Identify performance period episodes*/ 
data bpcia_performance_episodes;
	set bpciaref.bpcia_performance_episodes;

	perf_period_epi_flag=1;

run;


/*create unique identifiers, metatdata, and other column modifications for output*/ 
proc sql;
create table Episode_Detail_1 as 
	select 
		 a.BPID
		,a.EPI_ID_MILLIMAN
		,a.EPISODE_ID
		,put(a.EPISODE_INITIATOR,best6.) as EPISODE_INITIATOR
		,EPISODE_INITIATOR1
		,a.Milliman_CMS_Discrepancy
		,a.anchor_type
		,a.ANCHOR_CODE
		,a.FRACTURE_FLAG
		,coalesce(b.anchor_facility_code,a.anchor_code) as Anchor_First_Facility_Code
		,case when anchor_type = "op" and b.transfer_flag = . then b.T0_IP_IDX_ALLOWED else b.anchor_facility_cost end as Anchor_first_facility_cost
		,case when anchor_type = "op" and b.transfer_flag = . then 0 else sum(b.T0_IP_IDX_ALLOWED,b.anchor_facility_cost*-1) end as Anchor_other_facility_allowed
		,b.transfer_flag
		,strip(strip(a.bene_sk)||strip(a.ANCHOR_CODE)||strip(put(a.anchor_beg_dt,10.))) as EncounterID
		,"&reporting_period." as DataYearMo
		,put(year(a.anchor_beg_dt),4.)||" Q"||put(qtr(a.anchor_beg_dt),1.) as Anchor_YearQtr
		,case when month(a.anchor_beg_dt) < 10 then strip(put(year(a.anchor_beg_dt),4.)||" M0"||strip(put(month(a.anchor_beg_dt),2.)))
		 else strip(put(year(a.anchor_beg_dt),4.)||" M"||strip(put(month(a.anchor_beg_dt),2.))) 
		 end as Anchor_YearMo
		,year(a.anchor_beg_dt) as Anchor_Year	
		,a.bene_sk	
		,case when a.BENE_AGE = 999 then .
			else a.BENE_AGE 
			end as age	
		  ,a.ANCHOR_BEG_DT
		 ,a.ANCHOR_END_DT 
		 ,a.ANCHOR_ALLOWED_AMT	
		,case when a.anchor_type = "op" then "N/A"
			  when a.stus_cd_desc = "Discharged/transferred to a long term care hospitals" then "LTCH"
			  when a.stus_cd_desc = "Discharged/transferred to an inpatient rehabilitation facility including distinct parts units of a hospital" then "IRF"
			  when a.stus_cd_desc = "Discharged/transferred to home care of organized home health service organization" then "Home Health"
			  when a.stus_cd_desc = "Discharged/transferred to skilled nursing facility (SNF)" then "SNF"
			  else "Other"
			  end as anchor_dschrg_status
		,a.attending_npi	
		,a.operating_npi
		,a.anchor_stus_cd	
		,case when attending_npi in ("",".") then "" 		/*20180615 MK CHANGE*/ /*20170425 - JL Update: Update physician name */
			when attending_npi not in ("",".") and a.at_npi_last_nm ^= "" then strip(propcase(a.at_npi_last_nm))||", "||strip(propcase(a.at_npi_first_nm))||" ("||strip(attending_npi)||")"
			when attending_npi not in ("",".") and a.at_npi_last_nm = "" and at_npi_org_nm ^= "" then strip(propcase(at_npi_org_nm))||" ("||strip(attending_npi)||")"
			when attending_npi not in ("",".") and a.at_npi_last_nm = "" and at_npi_org_nm = "" then "("||strip(attending_npi)||")"
			else "Unknown ()"
		 end as attending_name length=255
		,case when operating_npi in ("",".") then "" 	/*20180615 MK CHANGE*/	/*20170425 - JL Update: Update physician name */
			when operating_npi not in ("",".") and a.op_npi_last_nm ^= "" then strip(propcase(a.op_npi_last_nm))||", "||strip(propcase(a.op_npi_first_nm))||" ("||strip(operating_npi)||")"
			when operating_npi not in ("",".") and a.op_npi_last_nm = "" and op_npi_org_nm ^= "" then strip(propcase(op_npi_org_nm))||" ("||strip(operating_npi)||")"
			when operating_npi not in ("",".") and a.op_npi_last_nm = "" and op_npi_org_nm = "" then "("||strip(operating_npi)||")"
			else "Unknown ()"
		 end as operating_name length=255
		,case when operating_npi in ("",".") then "" /*20180615 MK CHANGE*/	/*20170717 - JL Update: Add OP abbrev */
			when operating_npi not in ("",".") and a.op_npi_last_nm ^= "" then strip(upcase(a.op_npi_last_nm))||", "||strip(upcase(substr(a.op_npi_first_nm,1,1)))||". - "||substr(operating_npi,7,4) 
			when operating_npi not in ("",".") and a.op_npi_last_nm = "" and op_npi_org_nm ^= "" then strip(upcase(substr(a.op_npi_org_nm,1,10)))||". - "||substr(operating_npi,7,4) 
			when operating_npi not in ("",".") and a.op_npi_last_nm = "" and op_npi_org_nm = "" then "("||strip(operating_npi)||")"
		 end as OP_abbr length=100
		,at_npi_last_nm
		,at_npi_first_nm
		,op_npi_last_nm
		,op_npi_first_nm
		,case when T1_IP_A_FAC_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as READMIT_A_FLAG1
		,case when T1_IP_O_FAC_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as READMIT_O_FLAG1
		,case when (T1_IP_A_FAC_STARTDATE ^= . or T1_IP_O_FAC_STARTDATE ^= .) then 'Yes'
			  else 'No'
			  end as READMIT_B_FLAG1
		,case when T1_LTAC_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as LTAC_FLAG1
		,case when T1_IRF_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as IRF_FLAG1
		,case when T1_HH_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as HH_FLAG1
		,case when (T1_SNF1_STARTDATE ^= . or T1_SNF2_STARTDATE ^= .) then 'Yes'
			  else 'No'
			  end as SNF_FLAG1
		,case when T12_IP_A_FAC_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as READMIT_A_FLAG12
		,case when T12_IP_O_FAC_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as READMIT_O_FLAG12
		,case when (T12_IP_A_FAC_STARTDATE ^= . or T12_IP_O_FAC_STARTDATE ^= .) then 'Yes'
			  else 'No'
			  end as READMIT_B_FLAG12
		,case when T12_LTAC_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as LTAC_FLAG12
		,case when T12_IRF_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as IRF_FLAG12
		,case when T12_HH_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as HH_FLAG12
		,case when T12_SNF_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as SNF_FLAG12
		,case when T4_IP_A_FAC_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as READMIT_A_FLAG4
		,case when T4_IP_O_FAC_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as READMIT_O_FLAG4
		,case when (T4_IP_A_FAC_STARTDATE ^= . or T4_IP_O_FAC_STARTDATE ^= .) then 'Yes'
			  else 'No'
			  end as READMIT_B_FLAG4
		,case when T4_LTAC_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as LTAC_FLAG4
		,case when T4_IRF_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as IRF_FLAG4
		,case when T4_HH_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as HH_FLAG4
		,case when T4_SNF_STARTDATE ^= . then 'Yes'
			  else 'No'
			  end as SNF_FLAG4
		/*20170831 - Update end*/
		,case when a.BENE_AGE < 65 then 'Under 65'
			 when 65 <= a.BENE_AGE <= 70 then '65 - 70'
			 when 71 <= a.BENE_AGE <= 75 then '71 - 75'
			 when 76 <= a.BENE_AGE <= 80 then '76 - 80'
			 when 81 <= a.BENE_AGE <= 85 then '81 - 85'
			 when 86 <= a.BENE_AGE <= 90 then '86 - 90'
			 when 91 <= a.BENE_AGE <= 95 then '91 - 95'
			 when 96 <= a.BENE_AGE <= 100 then '96 - 100'
			 when a.BENE_AGE > 100 then '101 and Older'
			 end as Age_Group
		/*Update 20181201: Add performance beneficiary information*/
		%if &label = ybase %then %do;
		,"-" as bene_gender length=10
		,. as bene_birth_dt
		,a.bene_death_dt
		,"-" as MBI_ID length=20
		%end;
		%else %do;
		,a.bene_gender length=10
		,a.bene_birth_dt
		,a.bene_death_dt
		,a.MBI_ID length=20
		%end;
		,b.*
from data1_&label._&bpid1._&bpid2. as a
	left join report6_comb_drgs as b
	on a.epi_id_milliman = b.epi_id_milliman
	;
quit ; 


proc sql;
create table Episode_Detail_1a as 
	select 
		a.*
		,put(b.anchor_ccn,z6.) as anchor_ccn
		,b.curhic_uneq
		,case when b.DEATH_DUR_POSTDSCHRG = 1 then 'Yes' else 'No' end as death_flag
		%if &label = ybase %then %do;
		,"-" as flag_overlap length=10
		,"-" as mult_attr_provs length=10
		%end;
		%else %do;
		,case when b.flag_overlap = 1 then "Yes" else "No" end as flag_overlap length=10
		,case when b.mult_attr_provs = 1 then "Yes" else "No" end as mult_attr_provs length=10
		%end;
		,b.Mortality_CABG
	from Episode_Detail_1 as a
		left join
		out.epi_&label._&bpid1._&bpid2. as b
		on a.epi_id_milliman = b.epi_id_milliman
;
proc sql;
create table Episode_Detail_3 as
	select a.*
		  ,b.msdrg_description as anchor_description
		  ,case when b.mdc  = "" then "Not Available"
		  		else strip(c.mdc_short_name )||"-"||strip(b.mr_line_desc)
				end as MDC_Description
		,d.proc_desc as hcpcs_desc	
	from Episode_Detail_1a as a
		left join ref.msdrgs as b
		on strip(a.ANCHOR_CODE) = strip(b.msdrg)
		left join ref.mdc as c
		on b.mdc = c.mdc and b.mdc_desc = c.mdc_desc
	  	left join ref.hcpcs as d
		on strip(a.anchor_code)=d.proc
;

create table Episode_Detail_4 as 
	select a.*
		  ,b.Facility_or_PGP_name__to_be_used as EI_facility_name
		  ,b.Facility_or_PGP_name_abbreviatio as EI_facility_abbr
		  ,b.Health_system_name as EI_system_name
		  ,b.Health_system_interface_abbrevia as EI_system_abbr
		  ,propcase(c.fac_name) as Anchor_Facility_Name 
	from Episode_Detail_3 as a
	left join bpciaref.bpcia_episode_initiator_info as b
	on a.bpid = b.BPCI_Advanced_ID_Number_2
	left join ref.ccns_codemap as c
	on a.anchor_ccn = c.ccn;

create table Episode_Detail_5 as
	select a.*
		  ,case when anchor_ccn  = "" then "Unknown ()"
		  		when anchor_ccn  ^= "" and Anchor_Facility_name = "" then "Unknown ("||strip(anchor_ccn )||")"
		  		else strip(Anchor_facility_name)||" ("||strip(anchor_ccn )||")"
				end as Anchor_Fac_Code_Name
		  ,case when ANCHOR_CODE ="" then ""
		  		when ANCHOR_CODE ^= "" and anchor_description ^= "" then strip(ANCHOR_CODE)||": "||strip(anchor_description)
				end as anchor_drg_description
		,case when ANCHOR_CODE ="" then ""
		  		when ANCHOR_CODE ^= "" and hcpcs_desc ^= "" then strip(ANCHOR_CODE)||": "||strip(hcpcs_desc)
				end as anchor_hcpcs_description
		,case when a.anchor_type = "op" then "Not Available" else primary_diag_with_desc end as primary_diag_with_desc1
		,case when a.anchor_type = "op" then calculated anchor_hcpcs_description else primary_proc_with_desc end as primary_proc_with_desc1
		,case when ANCHOR_CODE ="" then ""
				when ANCHOR_CODE ^= "" and anchor_description ^= "" then strip(ANCHOR_CODE)||": "||strip(anchor_description)
		  		when ANCHOR_CODE ^= "" and hcpcs_desc ^= "" then strip(ANCHOR_CODE)||": "||strip(hcpcs_desc)
				end as anchor_code_description
		,case when Episode_Initiator  = "" then "Unknown ()"
		  		when Episode_Initiator  ^= "" and EI_facility_name = "" then "Unknown ("||strip(Episode_Initiator1 )||")"
		  		else strip(EI_facility_name)||" ("||strip(BPID)||")"
				end as Episode_Initiator_Use
		,case when length(episode_initiator1)>6 then 'PGP' else 'ACH' end as EI_type
	from Episode_Detail_4 as a;

quit;

*Get first CCN for each post-acute care type for total;
data episode_ccns (keep = epi_id_milliman timeframe sumcat clm_provider ccn2 dos );
	set report6_total_details;
	where sumcat in ('IP_s_F','IP_d_F','IP_LTAC_F','IP_Rehab_F','HH','SNF_F');
	clm_provider = strip(Provider_CCN);
	run;
proc sort data = episode_ccns;
	by epi_id_milliman sumcat dos;
run;

data episode_ccns_a (drop=CCN2 timeframe sumcat dos);
set episode_ccns;
by epi_id_milliman sumcat dos;
if first.sumcat then do;

		if sumcat = 'IP_s_F' then do;
				type = "T4_IP_A_FAC_CCN_NAME";
			end;
			if sumcat = 'IP_d_F' then do;
				type = "T4_IP_O_FAC_CCN_NAME";
			end;
			if sumcat = 'IP_LTAC_F' then do;
				type = "T4_LTAC_CCN_NAME";
			end;
			if sumcat = 'IP_Rehab_F' then do;
				type = "T4_IRF_CCN_NAME";
			end;
			if sumcat = 'HH' then do;
				type = "T4_HH_CCN_NAME";
			end;
			if sumcat = 'SNF_F' then do;
				type = "T4_SNF_CCN_NAME";
			end;
			output;
		end;
run;

/*standardize CCN data for each post-acute time period*/
data episode_ccns2 (drop=CCN2 timeframe sumcat dos);
	set episode_ccns(drop=CCN2 in=a)
		episode_ccns (drop=clm_provider in=b)
		episode_ccns_a (in=c);

		if a then do;
			if sumcat = 'IP_s_F' then do;
				type = "T"||strip(timeframe)||"_IP_A_FAC_CCN_NAME";
			end;
			if sumcat = 'IP_d_F' then do;
				type = "T"||strip(timeframe)||"_IP_O_FAC_CCN_NAME";
			end;
			if sumcat = 'IP_LTAC_F' then do;
				type = "T"||strip(timeframe)||"_LTAC_CCN_NAME";
			end;
			if sumcat = 'IP_Rehab_F' then do;
				type = "T"||strip(timeframe)||"_IRF_CCN_NAME";
			end;
			if sumcat = 'HH' then do;
				type = "T"||strip(timeframe)||"_HH_CCN_NAME";
			end;
			if sumcat = 'SNF_F' then do;
				type = "T"||strip(timeframe)||"_SNF1_CCN_NAME";
			end;
		output;
		end;

		if b then do;
			clm_provider=ccn2;
			type = "T"||strip(timeframe)||"_SNF2_CCN_NAME";
			
			if ccn2^='' then output;
		end;
		if c then output;
run;

/*Get CCN Name for all post-acute values*/
proc sql;
	create table episode_ccns3 as 
		select a.*
			,case when substr(clm_provider,3,1) in ("Z") then tranwrd(clm_provider,"Z","1")
			  	when substr(clm_provider,3,1) in ("R") then tranwrd(clm_provider,"R","1")
				when substr(clm_provider,3,1) in ("M") then tranwrd(clm_provider,"M","1")
			  	when substr(clm_provider,3,1) in ("S") then tranwrd(clm_provider,"S","0")
				when substr(clm_provider,3,1) in ("T") then tranwrd(clm_provider,"T","0")
				when substr(clm_provider,3,1) in ("U") then tranwrd(clm_provider,"U","0")
				else clm_provider
				end as provider_ccn_use
		from episode_ccns2 as a
		;

	create table episode_ccns4 as
		select distinct a.*
			,case when b.fac_name = "" then "Unknown ("||strip(a.provider_ccn_use)||")"
				else strip(propcase(b.fac_name))||" ("||strip(a.provider_ccn_use)||")" end as CCN_Name
			,strip(epi_id_milliman) as key
	from episode_ccns3 as a
	left join ref.ccns_codemap as b
	on a.provider_ccn_use = b.ccn
	order by key;
quit;


/*transpose data from long to wide*/
proc transpose data=episode_ccns4 out=episode_ccns5 (drop=_NAME_);
	by key;
	ID type;
	var CCN_NAME;
	run;
/*create shell dataset to ensure all Name variables exist*/
data episode_ccns6;
	length T1_IP_A_FAC_CCN_NAME T1_IP_O_FAC_CCN_NAME T1_LTAC_CCN_NAME T1_IRF_CCN_NAME T1_HH_CCN_NAME T1_SNF1_CCN_NAME T1_SNF2_CCN_NAME
		   T2_IP_A_FAC_CCN_NAME T2_IP_O_FAC_CCN_NAME T2_LTAC_CCN_NAME T2_IRF_CCN_NAME T2_HH_CCN_NAME T2_SNF1_CCN_NAME T2_SNF2_CCN_NAME
		   T3_IP_A_FAC_CCN_NAME T3_IP_O_FAC_CCN_NAME T3_LTAC_CCN_NAME T3_IRF_CCN_NAME T3_HH_CCN_NAME T3_SNF1_CCN_NAME T3_SNF2_CCN_NAME $59;
	retain T1_IP_A_FAC_CCN_NAME T1_IP_O_FAC_CCN_NAME T1_LTAC_CCN_NAME T1_IRF_CCN_NAME T1_HH_CCN_NAME T1_SNF1_CCN_NAME T1_SNF2_CCN_NAME
		   T2_IP_A_FAC_CCN_NAME T2_IP_O_FAC_CCN_NAME T2_LTAC_CCN_NAME T2_IRF_CCN_NAME T2_HH_CCN_NAME T2_SNF1_CCN_NAME T2_SNF2_CCN_NAME
		   T3_IP_A_FAC_CCN_NAME T3_IP_O_FAC_CCN_NAME T3_LTAC_CCN_NAME T3_IRF_CCN_NAME T3_HH_CCN_NAME T3_SNF1_CCN_NAME T3_SNF2_CCN_NAME "";

	set episode_ccns5;

run;


/*combine CCN Names with episode detail and create final episode detail dataset*/
proc sql;
create table Episode_Detail_6 as 
	select a.*
		  ,b.*
		  ,c.BPCI_Episode_Idx
	from Episode_Detail_5 as a
	left join Episode_CCNs6 as b
	on a.epi_id_milliman = b.key
	left join bpciaref.BPCIA_DRG_Mapping as c
	on a.ANCHOR_CODE = c.code;
;
/*Added the Clinical Episode Names to Episode_Detail */
proc sql;
create table Episode_Detail_7 as
  select a.*
          ,b.Clinical_Episode
		  ,b.Short_name as clinical_episode_abbr
		  ,b.Short_name_2 as clinical_episode_abbr2
		  ,strip(BPID)||" - "||strip(b.Short_name) as BPID_ClinicalEp
		  ,strip(BPID)||" - "||strip(b.Short_name)||" - "||strip(anchor_ccn) as BPID_ClinicalEp_ccn
	from Episode_Detail_6 as a
	left join bpciaref.BPCIA_Clinical_Episode_Names as b
	on a.BPCI_Episode_Idx = b.BPCI_Episode_Index
;
	create table out.epi_detail_&label._&bpid1._&bpid2. as
	select distinct a.*
			,b.TOT_STD_ALLOWED as cms_standardized /*Looking for EPI TOTAL */
			%if label = ybase %then %do;
			,b.EPI_STD_PMT_FCTR
			%end;
			%else %do;
			,0 as EPI_STD_PMT_FCTR
			%end;
			,b.WINSORIZE_EPI_1_99
			,b.EPI_STD_PMT_FCTR_WIN_1_99
			,b.ref_year
			,case when a.BPID in (&PMR_EI_lst.)
					then 1 else 0 end as client_type
			%if &label = ybase %then %do;
			,"BASE" as period
			,"Baseline (2014 - 2016)" as timeframe_filter format = $100. length=100 
			%end;
			%else %do;
			,"PERF" as period
			, case when '01OCT2018'd le POST_DSCH_END_DT le '30JUN2019'd then "Performance Period 1"
				   when '01JUL2019'd le POST_DSCH_END_DT le '31DEC2019'd then "Performance Period 2"
				   when '01JAN2020'd le POST_DSCH_END_DT le '30JUN2020'd then "Performance Period 3"
				   when '01JUL2020'd le POST_DSCH_END_DT le '31DEC2020'd then "Performance Period 4"
				   when '01JAN2021'd le POST_DSCH_END_DT le '30JUN2021'd then "Performance Period 5"
				   when '01JUL2021'd le POST_DSCH_END_DT le '31DEC2021'd then "Performance Period 6"
				   when '01JAN2022'd le POST_DSCH_END_DT le '30JUN2022'd then "Performance Period 7"
				   when '01JUL2022'd le POST_DSCH_END_DT le '31DEC2022'd then "Performance Period 8"
				   when '01JAN2023'd le POST_DSCH_END_DT le '30JUN2023'd then "Performance Period 9"
				   when '01JUL2023'd le POST_DSCH_END_DT le '31DEC2023'd then "Performance Period 10"
			end as timeframe_filter format = $100. length=100
			%end;
			,case when (&transmit_date. - b.POST_DSCH_END_DT) >= 60 then "Yes" else "No" end as COMP_EP_FLAG
			,b.POST_DSCH_END_DT as epi_end_date
			,case when month(b.POST_DSCH_END_DT) < 10 then strip(put(year(b.POST_DSCH_END_DT),4.)||" M0"||strip(put(month(b.POST_DSCH_END_DT),2.)))
			 else strip(put(year(b.POST_DSCH_END_DT),4.)||" M"||strip(put(month(b.POST_DSCH_END_DT),2.))) 
			 end as Episode_End_YearMo
			%if &label = ybase %then %do;
			,"Unknown" as PATIENT_NAME format = $255. length=255
			%end;
			%else %do;
			,case when b.BENE_SRNM_NAME in ("","~") then "Unknown"
			else propcase(STRIP(b.BENE_SRNM_NAME)||", "||STRIP(b.BENE_GVN_NAME)) 
			end as PATIENT_NAME format = $255. length=255
			%end;
			,b.CNT_ATTR_PGP
			from episode_detail_7 as a 
			left join out.epi_&label._&bpid1._&bpid2. as b
			on a.epi_id_milliman = b.epi_id_milliman
;
quit ;

/*/*********************************************************************************************/*/
/*/*Code to create a CCN-level observational dataset********************************************/*/
/*/*********************************************************************************************/*/;
data ccn_enc_ip (keep=BPID anchor_ccn claimno EPISODE_INITIATOR epi_id_milliman drg_cd type allowed std_allowed_wage provider_ccn0 admsn_dt DSCHRGDT util_day timeframe GEO_BENE_SK pdgns_cd pproc_cd transfer_stay admitting_diag_code DGNSCD02-DGNSCD25 edac_flag);
	set		out.ipr_&label._&bpid1._&bpid2.;
/*	where timeframe ^=0 ; */
	format DRG_CD $3.;
	provider_ccn0=PROVIDER;
	drg_cd =STAY_DRG_CD;
	DSCHRGDT = STAY_DSCHRGDT;
	admsn_dt = STAY_ADMSN_DT;
	GEO_BENE_SK = BENE_SK;
	pdgns_cd = DGNSCD01 ;
	pproc_cd = PRCDRCD01 ;
	claimno = IP_STAY_ID;
	admitting_diag_code = AD_DGNS ;
run;

proc sql;
	create table ccn_enc_ip_a as
		select distinct GEO_BENE_SK
			  ,claimno
			  ,anchor_ccn
			  ,BPID  
			  ,epi_id_milliman
			  ,EPISODE_INITIATOR
			  ,drg_cd 
			  ,type
			  ,sum(allowed) as allowed 
			  ,sum(std_allowed_wage) as std_allowed_wage
			  ,provider_ccn0
			  ,admsn_dt 
			  ,DSCHRGDT
			  ,max(util_day) as util_day 
			  ,pdgns_cd 
			  ,pproc_cd
			  ,timeframe
			  ,admitting_diag_code
			  ,DGNSCD02,DGNSCD03,DGNSCD04,DGNSCD05,DGNSCD06,DGNSCD07,DGNSCD08,DGNSCD09,DGNSCD10,DGNSCD11,DGNSCD12,DGNSCD13,DGNSCD14,DGNSCD15,DGNSCD16,DGNSCD17,DGNSCD18,DGNSCD19,DGNSCD20,DGNSCD21,DGNSCD22,DGNSCD23,DGNSCD24,DGNSCD25
			  ,edac_flag
		from ccn_enc_ip
		group by 
			  GEO_BENE_SK
			  ,claimno
			  ,anchor_ccn
			  ,BPID
			  ,epi_id_milliman
			  ,EPISODE_INITIATOR
			  ,drg_cd 
			  ,type
			  ,provider_ccn0
			  ,admsn_dt 
			  ,DSCHRGDT
			  ,pdgns_cd 
			  ,pproc_cd
			  ,timeframe
			  ,admitting_diag_code
			  ,DGNSCD02,DGNSCD03,DGNSCD04,DGNSCD05,DGNSCD06,DGNSCD07,DGNSCD08,DGNSCD09,DGNSCD10,DGNSCD11,DGNSCD12,DGNSCD13,DGNSCD14,DGNSCD15,DGNSCD16,DGNSCD17,DGNSCD18,DGNSCD19,DGNSCD20,DGNSCD21,DGNSCD22,DGNSCD23,DGNSCD24,DGNSCD25
			  ,edac_flag
		; 
quit; 

*!! JL BPCIA update: Temporary - to fix formats and rename variables to get them all to stack;
data ccn_enc_snf;
set out.snf_&label._&bpid1._&bpid2. (keep= EPISODE_INITIATOR claimno BPID epi_id_milliman type allowed std_allowed_wage PROVIDER admsn_dt DSCHRGDT THRU_DT util_day timeframe DGNSCD01-DGNSCD25 rename=(PROVIDER=provider_ccn0 DGNSCD01=pdgns_cd /*util_day = util_day_pre*/)) ;
/*	util_day = min(util_day_pre,90);*/
run;

data ccn_enc_hha;
set out.hha_&label._&bpid1._&bpid2.(keep=BENE_SK  claimno anchor_ccn EPISODE_INITIATOR BPID epi_id_milliman type allowed std_allowed_wage PROVIDER timeframe DGNSCD01-DGNSCD25 FROM_DT THRU_DT util_day
											 rename=(BENE_SK=GEO_BENE_SK DGNSCD01=pdgns_cd FROM_DT=admsn_dt THRU_DT=DSCHRGDT) in=d) ;
	provider_ccn0 = strip(provider);
run;

data ccn_enc_op;
	set out.op_&label._&bpid1._&bpid2. (keep= bene_sk claimno anchor_ccn EPISODE_INITIATOR BPID epi_id_milliman type allowed std_allowed_wage PROVIDER dos timeframe DGNSCD01-DGNSCD25 at_npi HCPCS_CD  REV_CNTR edac_flag in=c rename=(PROVIDER=provider_ccn0 bene_sk = geo_bene_sk DGNSCD01=pdgns_cd)) ;
	ADMSN_DT = dos;
	DSCHRGDT = dos;
run;

data ccn_enc_hs (drop=provider);
	set out.hs_&label._&bpid1._&bpid2. (keep= bene_sk claimno anchor_ccn EPISODE_INITIATOR BPID epi_id_milliman type allowed std_allowed_wage PROVIDER dos timeframe DGNSCD01-DGNSCD25 thru_dt util_day in=c rename=(bene_sk=geo_bene_sk dos = admsn_dt DGNSCD01=pdgns_cd thru_dt = dschrgdt));
	provider_ccn0 = input(provider,$20.);
run;
*;

data ccn_enc(drop=provider_ccn0);
set		
		ccn_enc_ip_a (keep=GEO_BENE_SK anchor_ccn EPISODE_INITIATOR BPID epi_id_milliman drg_cd type allowed std_allowed_wage provider_ccn0 admsn_dt DSCHRGDT util_day  pdgns_cd pproc_cd timeframe admitting_diag_code DGNSCD02-DGNSCD25 edac_flag)
		ccn_enc_snf
		ccn_enc_hha
		ccn_enc_op
		ccn_enc_hs
;
	if length(strip(provider_ccn0))<6 then provider_ccn = "0"||strip(provider_ccn0);
	else provider_ccn = strip(provider_ccn0);
run;

proc sql;
	create table ccn_enc2 as
		select distinct GEO_BENE_SK, claimno
			  ,anchor_CCN
			  ,BPID
			  ,EPISODE_INITIATOR
			  ,epi_id_milliman
			  ,type
			  ,provider_ccn
			  ,drg_cd
			  ,pdgns_cd
			  ,pproc_cd
			  ,max(at_npi) as at_npi
			  ,timeframe
			  ,admsn_dt
			  ,hcpcs_cd
			  ,rev_cntr
			  ,admitting_diag_code
			  ,DGNSCD02,DGNSCD03,DGNSCD04,DGNSCD05,DGNSCD06,DGNSCD07,DGNSCD08,DGNSCD09,DGNSCD10,DGNSCD11,DGNSCD12,DGNSCD13,DGNSCD14,DGNSCD15,DGNSCD16,DGNSCD17,DGNSCD18,DGNSCD19,DGNSCD20,DGNSCD21,DGNSCD22,DGNSCD23,DGNSCD24,DGNSCD25
			  ,max(dschrgdt) as dschrgdt format=mmddyy10.
			  ,sum(util_day) as util_day
			  ,sum(allowed) as allowed
			  ,sum(std_allowed_wage) as std_allowed_wage
			  ,edac_flag
		from ccn_enc
		group by GEO_BENE_SK, claimno
			  ,anchor_CCN
			  ,BPID
			  ,EPISODE_INITIATOR
			  ,epi_id_milliman
			  ,type
			  ,provider_ccn
			  ,drg_cd
			  ,pdgns_cd
			  ,pproc_cd
			  ,timeframe
			  ,admsn_dt
			  ,hcpcs_cd
			  ,rev_cntr
			  ,admitting_diag_code
			  ,DGNSCD02,DGNSCD03,DGNSCD04,DGNSCD05,DGNSCD06,DGNSCD07,DGNSCD08,DGNSCD09,DGNSCD10,DGNSCD11,DGNSCD12,DGNSCD13,DGNSCD14,DGNSCD15,DGNSCD16,DGNSCD17,DGNSCD18,DGNSCD19,DGNSCD20,DGNSCD21,DGNSCD22,DGNSCD23,DGNSCD24,DGNSCD25
			  ,edac_flag
		order by BPID, epi_id_milliman,type,admsn_dt;
	quit;

	/*combine records with 1 or less days between discharge and admission to the same post-acute type as a single event*/
data ccn_enc3;
	set ccn_enc2;
	by BPID epi_id_milliman type admsn_dt;

/*	at_npi2 = strip(input(at_npi,$20.));*/

	retain last_dt;

	if first.type then do;
		episode + 1;
		last_dt = .;
	end;

	if intck('day',last_dt,admsn_dt)>=1 then episode+1;

	last_dt = dschrgdt;

		run;

data ccn_enc3a;
	set ccn_enc3;
	by BPID epi_id_milliman type admsn_dt;
	if first.BPID then counter = 0;

	counter + 1;

run; 

/*summarize post-acute encounters by episode# created in step above*/
proc sql;
	create table ccn_enc4 as
		select anchor_CCN
		,BPID
		,EPISODE_INITIATOR
			  ,epi_id_milliman
			  ,type
			  ,provider_ccn
			  ,GEO_BENE_SK, claimno
			  ,substr(provider_ccn,3,1) as third_digit
			  ,case when substr(provider_ccn,3,1) in ("Z") then tranwrd(provider_ccn,"Z","1")
			  	when substr(provider_ccn,3,1) in ("R") then tranwrd(provider_ccn,"R","1")
				when substr(provider_ccn,3,1) in ("M") then tranwrd(provider_ccn,"M","1")
			  	when substr(provider_ccn,3,1) in ("S") then tranwrd(provider_ccn,"S","0")
				when substr(provider_ccn,3,1) in ("T") then tranwrd(provider_ccn,"T","0")
        		when substr(provider_ccn,3,1) in ("U") then tranwrd(provider_ccn,"U","0")
				else provider_ccn 
				end as provider_ccn_use
			  ,drg_cd
			  ,pdgns_cd
			  ,pproc_cd
			  ,timeframe
			  ,hcpcs_cd
			  ,rev_cntr
			  ,admitting_diag_code
			  ,DGNSCD02,DGNSCD03,DGNSCD04,DGNSCD05,DGNSCD06,DGNSCD07,DGNSCD08,DGNSCD09,DGNSCD10,DGNSCD11,DGNSCD12,DGNSCD13,DGNSCD14,DGNSCD15,DGNSCD16,DGNSCD17,DGNSCD18,DGNSCD19,DGNSCD20,DGNSCD21,DGNSCD22,DGNSCD23,DGNSCD24,DGNSCD25
			  ,at_npi
			  ,counter
			  ,min(admsn_dt) as startdate format=mmddyy10.
			  ,max(dschrgdt) as enddate format=mmddyy10.
			  ,sum(allowed) as allowed
			  ,sum(std_allowed_wage) as std_allowed_wage
			  ,sum(util_day) as util_day
			  ,edac_flag
	from ccn_enc3a
	group by episode
			,anchor_ccn
			 ,BPID
			 ,EPISODE_INITIATOR
		      ,epi_id_milliman
			  ,type
			  ,provider_ccn
			  ,GEO_BENE_SK, claimno
			  ,drg_cd 
			  ,pdgns_cd 
			  ,pproc_cd
			  ,at_npi
			  ,timeframe
			  ,hcpcs_cd
			  ,rev_cntr
			  ,admitting_diag_code
			  ,DGNSCD02,DGNSCD03,DGNSCD04,DGNSCD05,DGNSCD06,DGNSCD07,DGNSCD08,DGNSCD09,DGNSCD10,DGNSCD11,DGNSCD12,DGNSCD13,DGNSCD14,DGNSCD15,DGNSCD16,DGNSCD17,DGNSCD18,DGNSCD19,DGNSCD20,DGNSCD21,DGNSCD22,DGNSCD23,DGNSCD24,DGNSCD25
			  ,counter
			  ,edac_flag
;
quit; 

proc sql;
create table ccn_enc5 as 
		select a.ANCHOR_BEG_DT
			,a.EncounterID
			,a.DataYearMo
			,a.Anchor_YearQtr
			,a.Anchor_YearMo
			,a.Anchor_Year	
			,b.*
			,case when b.timeframe = 0 then "Anchor"
			  		when b.timeframe = 1 then "1 - 30 Days"
					when b.timeframe = 2 then "31 - 60 Days"
					when b.timeframe = 3 then "61 - 90 Days"
					end as timeframe2
		from out.epi_detail_&label._&bpid1._&bpid2. as a
		right join ccn_enc4 as b
		on a.epi_id_milliman = b.epi_id_milliman
		and a.BPID = b.BPID
	;

/*add CCN Names to CCN post-acute episodes*/
	create table ccn_enc6 as
		select a.*
			,propcase(b.fac_name) as CCN_Name
		from ccn_enc5 as a
		left join ref.ccns_codemap as b
		on a.provider_ccn_use = b.ccn
		order by epi_id_milliman;

/*add msdrg description to CCN post-acute episodes*/
	create table ccn_enc8 as	
		select distinct a.*
			,case when a.PDGNS_CD = "" then "" 
			 else b.diag_desc 
			 end as prim_diag_desc
			,case when a.PPROC_CD = "" then "" 
			 else c.ICD9PROC_DESC 
			 end as prim_proc_desc
			,d.MSDRG_DESCRIPTION as drg_desc
			,e.proc_desc as hcpcs_desc	
		from ccn_enc6 as a
		left join ref.Icd9diag_codemap as b
		on a.PDGNS_CD = b.diag
		and ((a.enddate < '01OCT2015'd and b.version = 9) or (a.enddate >= '01OCT2015'd and b.version = 0)) 
		left join ref.Icd9proc_codemap as c
		on a.PPROC_CD = c.ICD9Proc
		and ((a.enddate < '01OCT2015'd and c.version = 9) or (a.enddate >= '01OCT2015'd and c.version = 0)) 
		left join ref.msdrgs as d
		on strip(drg_cd) = d.msdrg
		left join ref.hcpcs as e
		on a.hcpcs_cd=e.proc
;

proc sql;
create table ccn_enc10 as
		select distinct a.*
		      ,case when PDGNS_CD ="" then ""
			  		when PDGNS_CD ^="" and prim_diag_desc = "" then strip(PDGNS_CD)
					else strip(PDGNS_CD)||": "||strip(lowcase(prim_diag_desc))
					end as prim_diag_with_desc
			  ,case when PPROC_CD ="" then ""
			  		when PPROC_CD ^="" and prim_proc_desc = "" then strip(PPROC_CD)
					else strip(PPROC_CD)||": "||strip(lowcase(prim_proc_desc))
					end as prim_proc_with_desc
			  ,case when hcpcs_cd ="" then ""
			  		when hcpcs_cd ^="" and hcpcs_desc = "" then strip(hcpcs_cd)
					else strip(hcpcs_cd)||": "||strip(lowcase(hcpcs_desc))
					end as hcpcs_with_desc
			  ,case when Provider_CCN = "" then "Unknown ()"
			  		when Provider_CCN ^= "" and CCN_Name = "" then "Unknown ("||strip(Provider_CCN)||")"
					when Provider_CCN ^= "" and CCN_Name ^="" and third_digit='S' then "Psychiatric unit of "||strip(CCN_Name)||" ("||strip(Provider_CCN)||")"
					when Provider_CCN ^= "" and CCN_Name ^="" and third_digit='T' then "Rehabilitation unit of "||strip(CCN_Name)||" ("||strip(Provider_CCN)||")"
					when Provider_CCN ^= "" and CCN_Name ^="" and third_digit='Z' then "Swing-bed of "||strip(CCN_Name)||" ("||strip(Provider_CCN)||")"
					when Provider_CCN ^= "" and CCN_Name ^="" and third_digit='R' then "Rehabilitation unit of "||strip(CCN_Name)||" ("||strip(Provider_CCN)||")"
					when Provider_CCN ^= "" and CCN_Name ^="" and third_digit='M' then "Psychiatric unit of "||strip(CCN_Name)||" ("||strip(Provider_CCN)||")"
					when Provider_CCN ^= "" and CCN_Name ^="" and third_digit='U' then "Swing-bed of "||strip(CCN_Name)||" ("||strip(Provider_CCN)||")"
					else strip(CCN_Name)||" ("||strip(Provider_CCN)||")"
					end as CCN_Name_Desc
			  ,case when drg_cd ='' then ""
			  		when drg_cd ^='' and drg_desc = "" then strip(drg_cd)
					else strip(put(input(drg_cd,best3.),z3.))||": "||strip(drg_desc)
					end as drg_with_desc
			  ,case when type in ('IP_Idx','OP_Idx') then 'Anchor Admit'
					when type in ('IP_s','IP_d') then 'Readmit'
			  		when type in ('SNF') then 'SNF'
					when type in ('IP_Rehab') then 'IRF'
					when type in ('IP_LTAC') then 'LTCH'
					when type in ('HH') then 'Home Health'
					when type in ('HS') then 'Hospice'
					when type in ('OP_ER') then 'Emergency'
					when type in ('OP_Rehab') then 'Rehab'
					when type in ('OP_Ambulance','OP_Other','OP_PartBRx','OP_PartBRx-Chemotherapy','OP_Pathology'
								 ,'OP_Radiology-CT','OP_Radiology-Gen','OP_Radiology-MRI','OP_Radiology-PET'
								 ,'OP_Surgery-ASC','OP_Surgery-OP') then 'Outpatient'
					end as CareType length =50
			  ,case when type in ('OP_ER') and a.at_npi = . and b.Provider_Last_Name__Legal_Name_ = "" then "Unknown ()"
			   	  when type in ('OP_ER') and a.at_npi ^= . and b.Provider_Last_Name__Legal_Name_ = ""  and Provider_Organization_Name__Leg ^="" then strip(propcase(Provider_Organization_Name__Leg))||" ("||strip(put(a.at_npi,best12.))||")"
			      when type in ('OP_ER') and a.at_npi ^= . and b.Provider_Last_Name__Legal_Name_ = ""  then "Unknown"||" ("||strip(put(a.at_npi,best12.))||")" 
				  when type in ('OP_ER') then strip(propcase(b.Provider_Last_Name__Legal_Name_))||", "||strip(propcase(b.Provider_First_Name))||" ("||strip(put(a.at_npi,best12.))||")" 
			   end as ER_Physician
		from ccn_enc8 as a
		left join ref.npi_data as b
			on strip(put(a.at_npi,best12.))=b.npi
;
quit ; 

*20190422 SD Update : Identify stand-alone ER visits;
*Output file that just includes the ER visits with overlapping IP admissions;
proc sql;
create table ccn_enc_ER as
			select distinct a.*
					,1 as IP_visit_flag
			from ccn_enc10 as a
			left join ccn_enc10 as b
			on a.epi_id_milliman = b.epi_id_milliman and (a.startdate = b.startdate or sum(a.startdate,1) = b.startdate)
			where a.caretype = "Emergency" and b.type in ("IP_d","IP_s","IP_Idx")
 ; 

 *Merge flags for overlapping admissions to original dataset;
create table ccn_enc10a as
		  select distinct 
				 a.*
				,b.IP_visit_flag
		    from ccn_enc10 as a
			left join ccn_enc_ER as b
			on a.epi_id_milliman = b.epi_id_milliman and a.startdate = b.startdate and a.caretype = b.caretype
   ;
quit; 

*Change ER visits to ER - stand alone or ER - preceding admit based on overlap with inpatient admissions on the same day;
data ccn_enc10b;
set ccn_enc10a;
	if caretype = "Emergency" then do;
    	if IP_visit_flag = 1 then caretype = "Emergency - Preceding Admit";
		 else caretype = "Emergency - Stand Alone";
	end;
run;

/*********************************************************************************************/
/*Make Complications detail*/
/*********************************************************************************************/
proc sql;

	create table ccn_enc11 as 
		select a.*
			,b.cc_denom as cc_elig
			from ccn_enc10b as a
			left join out.Cc_sum_&label._&bpid1._&bpid2. as b
			on a.EPI_ID_MILLIMAN = b.EPI_ID_MILLIMAN
			;

	create table out.comp_&label._&bpid1._&bpid2. as 
		select a.anchor_ccn
			  ,a.BPID
			  ,a.EPI_ID_MILLIMAN
			  ,a.provider_ccn
			  ,a.cc_elig
			  ,case when a.cc_elig = 0 then 'N/A'
					when b.complication = '' then 'None'		  		
			  		else b.complication end as complication
			  ,startdate as complication_startdate format= mmddyy10.
			  ,enddate as complication_enddate format= mmddyy10.
			  ,allowed as complication_allowed
			  ,std_allowed_wage as complication_std_allowed
			  ,ccn_name_desc as complication_ccn_name_desc
			  ,caretype as complication_caretype
			  ,timeframe2 as complication_timeframe2
			  ,case when b.complication ^= '' then 1 else 0 end as cc_flag
				/*20170905 - Complications timeframe update*/
			  ,case when b.complication ^= '' and complication_timeframe2 = 'Anchor' then 1 
					else 0 end as cc_flag_anchor
			  ,case when b.complication ^= '' and complication_timeframe2 = '1 - 30 Days' then 1 
					else 0 end as cc_flag_1_30
			  ,case when b.complication ^= '' and complication_timeframe2 in ('1 - 30 Days','31 - 60 Days') then 1 
					else 0 end as cc_flag_1_60
			  ,case when b.complication ^= '' and complication_timeframe2 in ('1 - 30 Days','31 - 60 Days','61 - 90 Days') then 1
					else 0 end as cc_flag_1_90
	from ccn_enc11 as a
	inner join out.cc_det_&label._&bpid1._&bpid2. as b
	on a.EPI_ID_MILLIMAN = b.EPI_ID_MILLIMAN 
	and a.provider_ccn = b.provider
	and a.startdate = b.stay_admsn_dt
	and a.caretype in ('Anchor Admit','Readmit')
		;
quit;


/*********************************************************************************************/
/*********************************************************************************************/


/*********************************************************************************************/
/*Code to create a NPI-level observational dataset********************************************/
/*********************************************************************************************/;

/*break out attending physicians from episode detail*/;

data dataprov_a (rename=(attending_npi=provider_npi attending_name=provider_name at_npi_last_nm=npi_last_nm at_npi_first_nm=npi_first_nm));
	set out.epi_detail_&label._&bpid1._&bpid2.  (keep= anchor_CCN  BPID EncounterID epi_id_milliman  DataYearMo Anchor_YearQtr Anchor_YearMo Anchor_Year ANCHOR_BEG_DT 
						 ANCHOR_END_DT attending_npi attending_name at_npi_last_nm at_npi_first_nm );	
	length physician_type $35;
	where attending_npi ^= ".";
	Physician_type = 'Attending MD';

run;

/*break out operating physicians from episode detail*/
data dataprov_b (rename=(operating_npi=provider_npi operating_name=provider_name op_npi_last_nm=npi_last_nm op_npi_first_nm=npi_first_nm));
	set out.epi_detail_&label._&bpid1._&bpid2.  (keep= anchor_CCN EncounterID BPID epi_id_milliman  DataYearMo Anchor_YearQtr Anchor_YearMo Anchor_Year ANCHOR_BEG_DT 
						 ANCHOR_END_DT operating_npi operating_name op_npi_last_nm op_npi_first_nm);
	length physician_type $35;
	where operating_npi ^= ".";
	Physician_type = 'Operating MD';

run;


/*stack and sort attending and operating physicians*/
data dataprov_c;
	set dataprov_a
		dataprov_b;

run;

proc sort data=dataprov_c;
	by EncounterID BPID epi_id_milliman  provider_npi;
run;

/*Create one record per episode-NPI*/
data dataprov_d;
	set dataprov_c;
	by EncounterID BPID epi_id_milliman  provider_npi;

	if first.provider_npi and last.provider_npi then output;
	else if last.provider_npi then do;
		Physician_type = 'Attending & Operating MD';
		output;
	end;

run;

*20180524 JL UPDATE: Output for physician summary table*;
proc sql;
	create table out.phys_summ_&label._&bpid1._&bpid2. as
	select a.BPID
		,a.epi_id_milliman
		,a.provider_name as at_op_provider_name
		,a.physician_type as at_op_role
		,case when a.provider_npi in ("",".") then ""
			when a.npi_last_nm = '' and substr(a.provider_name,1,7) = 'Unknown' then "Unknown - "||substr(a.provider_npi,7,4) 
			when a.npi_last_nm = '' and a.provider_name ne '' then strip(upcase(substr(a.provider_name,1,10)))||" - "||substr(a.provider_npi,7,4)
			else strip(upcase(a.npi_last_nm))||", "||strip(upcase(substr(a.npi_first_nm,1,1)))||". - "||substr(a.provider_npi,7,4) 
		 end as at_op_abbr
	from dataprov_d as a
;
quit;
*20180524 JL UPDATE END;

/*Grab all professional claims and attach NPI, primary diagnosis and primary procedure code*/
data npi_level;
	length npi $15;
	set out.pb2_&label._&bpid1._&bpid2. 
		out.dme2_&label._&bpid1._&bpid2. (in=b)
		;
	retain counter;

	npi = strip(prfnpi);
	if b then prfnpi = strip(sup_npi);
	counter + 1;
run;

proc sql;
	create table npi_level_a as
	select a.anchor_CCN
		,a.epi_id_milliman
		,a.BPID
		,a.EXPNSDT1 as service_date
		,sum(a.allowed) as allowed
		,sum(a.std_allowed_wage) as std_allowed_wage
		,a.type
		,a.timeframe
		,edac_flag
		,strip(put(a.PRFNPI,15.)) as PRFNPI_A
		,a.HCPCS_CD as HCPCS_CD_A
		,a.DGNSCD01 as primary_diag_cd
		,a.DGNSCD02,a.DGNSCD03,a.DGNSCD04,a.DGNSCD05,a.DGNSCD06,a.DGNSCD07,a.DGNSCD08,a.DGNSCD09,a.DGNSCD10,a.DGNSCD11,a.DGNSCD12
	from npi_level as a 
	group by a.anchor_CCN
			,a.epi_id_milliman
			,a.BPID
			,service_date
			,a.type
			,a.timeframe
			,edac_flag
			,PRFNPI_A
			,HCPCS_CD_A
			,primary_diag_cd
			,a.DGNSCD02,a.DGNSCD03,a.DGNSCD04,a.DGNSCD05,a.DGNSCD06,a.DGNSCD07,a.DGNSCD08,a.DGNSCD09,a.DGNSCD10,a.DGNSCD11,a.DGNSCD12
	;
quit ; 

proc sql ; 
	create table npi_level_b as 
		 select 
		a.ANCHOR_BEG_DT
		,a.EncounterID
		,a.DataYearMo
		,a.Anchor_YearQtr
		,a.Anchor_YearMo
		,a.Anchor_Year	
		,b.*
	from out.epi_detail_&label._&bpid1._&bpid2. as a
	inner join npi_level_a as b
	on a.epi_id_milliman = b.epi_id_milliman
	and a.BPID = b.BPID
	;

/*create various descriptive information information and attach provider names*/
	create table npi_level1a as
		select a.ANCHOR_BEG_DT
			  ,a.anchor_CCN
			  ,a.EncounterID
			  ,a.BPID
			  ,a.DataYearMo
			  ,a.Anchor_YearQtr
			  ,a.Anchor_YearMo
			  ,a.Anchor_Year
			  ,a.epi_id_milliman
			  ,a.service_date
			  ,a.allowed
			  ,a.std_allowed_wage
			  ,(a.allowed/2) as cap_50percent
			  ,a.type
			  ,a.primary_diag_cd
			  ,a.DGNSCD02,a.DGNSCD03,a.DGNSCD04,a.DGNSCD05,a.DGNSCD06,a.DGNSCD07,a.DGNSCD08,a.DGNSCD09,a.DGNSCD10,a.DGNSCD11,a.DGNSCD12
			  ,a.hcpcs_cd_A as hcpcs_cd
			  ,case when a.PRFNPI_A in ("",".") then "Unknown ()"	/*20170522 Update: Change name logic and add last 4 digits of NPI to physician abbreviation*/
					when a.PRFNPI_A ^= "" and b.Provider_Last_Name__Legal_Name_ ^= "" then strip(propcase(b.Provider_Last_Name__Legal_Name_))||", "||strip(propcase(b.Provider_First_Name))||" ("||strip(a.PRFNPI_A)||")" 
				    when a.PRFNPI_A ^= "" and b.Provider_Last_Name__Legal_Name_ = ""  and Provider_Organization_Name__Leg ^= "" then strip(propcase(Provider_Organization_Name__Leg))||" ("||strip(a.PRFNPI_A)||")"
					when a.PRFNPI_A ^= "" and b.Provider_Last_Name__Legal_Name_ = "" and Provider_Organization_Name__Leg = "" then "("||strip(a.PRFNPI_A)||")"
				    else "Unknown ()" end as Physician

  				,case when a.PRFNPI_A in ("",".") then "Unknown ()"	/*20170522 Update: Change name logic and add last 4 digits of NPI to physician abbreviation*/
					when a.PRFNPI_A ^= "" and b.Provider_Last_Name__Legal_Name_ ^= "" then strip(propcase(b.Provider_Last_Name__Legal_Name_))||", "||strip(upcase(substr(b.Provider_First_Name,1,1)))||". - "||substr(a.PRFNPI_A,7,4)
				    when a.PRFNPI_A ^= "" and b.Provider_Last_Name__Legal_Name_ = ""  and Provider_Organization_Name__Leg ^= "" then strip(propcase(Provider_Organization_Name__Leg))||". - "||substr(a.PRFNPI_A,7,4)
					when a.PRFNPI_A ^= "" and b.Provider_Last_Name__Legal_Name_ = "" and Provider_Organization_Name__Leg = "" then "("||strip(a.PRFNPI_A)||")"
				    else "Unknown ()" end as physician_abbr
			  ,a.PRFNPI_A as provider_npi
			  ,a.timeframe
			  ,case when a.timeframe = 0 then "Anchor"
			  		when a.timeframe = 1 then "1 - 30 Days"
					when a.timeframe = 2 then "31 - 60 Days"
					when a.timeframe = 3 then "61 - 90 Days"
					end as timeframe2
			/*20170905 - Provider timeframe update */
			  ,case when a.timeframe in (1) then 1
			  		else 0
					end as prov_timeframe_1_30
			  ,case when a.timeframe in (1,2) then 1
			  		else 0
					end as prov_timeframe_1_60
			  ,case when a.timeframe in (1,2,3) then 1
			  		else 0
					end as prov_timeframe_1_90
			  ,case when a.timeframe in (0,1,2,3) then 1
					else 0
					end as prov_timeframe_all	
			  ,a.edac_flag
	from npi_level_b as a
	left join ref.npi_data as b
	on a.PRFNPI_A=b.npi
	;
quit;

proc sql;
create table npi_level1b as
		select 	distinct 
				a.*
			,	b.Healthcare_Provider_Taxonomy_Co as Taxonomy_Code	
		from npi_level1a as a
		left join ref.npi_taxonomy as b
		on a.provider_npi=b.npi
;
quit ; 

data npi_level1c;
	set npi_level1b;
	
	format provider_special_code $2.;
	provider_special_code=put(Taxonomy_Code,$TAX_SPEC.);
run;

proc sql;
create table npi_level1 as
		select 	distinct 
				a.*
			,case when b.prov_type_description2 ^="" then b.prov_type_description2
					else "OSP" end as provider_specialty
		from npi_level1c as a
		left join ref.specialty_code_descriptions as b
		on a.provider_special_code=b.medicare_specialty_code
;
quit ; 

proc sql;
create table npi_level2 as
		select 	distinct 
				a.*
			%if &label = ybase %then %do;
				,"" as prim_diag_with_desc
			%end;
			%else %do;
				,case when primary_diag_cd ="" then ""
				when primary_diag_cd ^="" and b.diag_desc ="" then primary_diag_cd
				else strip(primary_diag_cd)||": "||strip(lowcase(b.diag_desc))
				end as prim_diag_with_desc
			%end;
		from npi_level1 as a
		left join ref.Icd9diag_codemap as b
		on a.primary_diag_cd = b.diag
		and ((a.service_date < '01OCT2015'd and b.version = 9) or (a.service_date >= '01OCT2015'd and b.version = 0)) 
;
quit ; 


proc sql;
create table npi_level3 as	
		select a.*
			,case when a.hcpcs_cd = "" then "" 
			 else lowcase(b.proc_desc) 
			 end as prof_hcpcs_desc
		    ,case when hcpcs_cd ="" then ""
			  	when hcpcs_cd ^="" and lowcase(b.proc_desc)  = "" then strip(hcpcs_cd)
				else strip(hcpcs_cd)||": "||strip(lowcase(b.proc_desc))
				end as prof_hcpcs_code_desc

			,case when type in ('DME') then "DME Supplier"
				when type not in ('DME') and c.Physician_type = "" then "Other" 
				else c.Physician_type end as physician_role
			,c.Physician_type
			,case when calculated physician_role in ('Operating MD','Attending & Operating MD') then 'Yes'
			   	  else 'No' end as Op_MD_flag
			,case when calculated physician_role in ('Attending MD','Attending & Operating MD') then 'Yes'
			   	  else 'No' end as At_MD_flag
		from npi_level2 as a
		left join ref.HCPCS as b
		on a.hcpcs_cd = b.proc
		left join dataprov_d as c
		on strip(a.provider_npi)=strip(c.provider_npi)
		and a.EncounterID = c.EncounterID
;


*20190422 SD Update : Identify stand-alone ER visits;
*Output file that just includes the ER visits with overlapping IP admissions;

create table npi_level_ER_0 as
			select distinct a.*
					,1 as IP_visit_flag
			from npi_level3 as a
			left join ccn_enc11 as b
			on a.epi_id_milliman = b.epi_id_milliman and (a.service_date = b.startdate or sum(a.service_date,1) = b.startdate)
			where a.type = "Prof_ER" and b.type in ("IP_d","IP_s","IP_Idx")
 ; 

 *Merge flags for overlapping admissions to original dataset;
create table npi_level4 as
		  select distinct 
				 a.*
				,b.IP_visit_flag
		    from npi_level3 as a
			left join npi_level_ER_0 as b
			on a.epi_id_milliman = b.epi_id_milliman and a.service_date = b.service_date and a.type = b.type
   ;

quit; 

*Change ER visits to ER - stand alone or ER - preceding admit based on overlap with inpatient admissions on the same day;
data out.provider_&label._&bpid1._&bpid2.;
set npi_level4;
	if type = "Prof_ER" then do;
    	if IP_visit_flag = 1 then type = "Prof_ER_P";
		 else type = "Prof_ER_S";
	end;
run;


/*********************************************************************************************/
/*Code to create Patient Journey dataset  ****************************************************/
/*********************************************************************************************/

*Make Hospice provider field character;
data pj_hs;
	set out.hs_&label._&bpid1._&bpid2.;
	provider1 = put(provider,z6.);
run;

data patientjourney_1 ;
	retain  epi_id_milliman type provider_ccn admsn_dt dschrgdt;
	set out.op_&label._&bpid1._&bpid2. (keep =  epi_id_milliman type provider_num from_dt thru_dt anchor_beg_dt anchor_end_dt BPID std_allowed_wage util_day in = a rename=(from_dt = admsn_dt thru_dt=dschrgdt provider_num=provider)) 
		out.ip_&label._&bpid1._&bpid2. (keep =  epi_id_milliman type provider STAY_ADMSN_DT STAY_DSCHRGDT anchor_beg_dt anchor_end_dt BPID std_allowed_wage util_day in = b rename=(STAY_ADMSN_DT = admsn_dt STAY_DSCHRGDT=dschrgdt)) 
		out.snf_&label._&bpid1._&bpid2. (keep =  epi_id_milliman type provider admsn_dt dschrgdt thru_dt anchor_beg_dt anchor_end_dt BPID std_allowed_wage util_day in = c rename =(thru_dt=dichrgdt2 util_day = util_day_pre))
		out.hha_&label._&bpid1._&bpid2. (keep =  epi_id_milliman type provider from_dt thru_dt anchor_beg_dt anchor_end_dt BPID std_allowed_wage util_day in = d rename=(from_dt = admsn_dt thru_dt = dschrgdt))
		pj_hs (keep =  epi_id_milliman type provider1 from_dt thru_dt anchor_beg_dt anchor_end_dt BPID std_allowed_wage util_day in = d rename=(from_dt = admsn_dt thru_dt = dschrgdt provider1 = provider));

		provider=strip(Provider); /*20180615 MK UPDATE*/
		if length(provider)=5 then provider="0"||provider; /*20180615 MK UPDATE*/

	if a and type ^= "OP_Idx" then delete;
	
	if c then util_day = min(util_day_pre,90);

	if type in ('OP_Idx','IP_Idx') then do;
		type = "";
		admsn_dt = .;
		dschrgdt = .;
	end;

		if substr(Provider,3,1) in ("Z") then provider_ccn = tranwrd(Provider,"Z","1");
		else if substr(Provider,3,1) in ("R") then provider_ccn = tranwrd(Provider,"R","1");
		else if substr(Provider,3,1) in ("M") then provider_ccn = tranwrd(Provider,"M","1");
		else if substr(Provider,3,1) in ("S") then provider_ccn = tranwrd(Provider,"S","0");
		else if substr(Provider,3,1) in ("T") then provider_ccn = tranwrd(Provider,"T","0");
		else if substr(Provider,3,1) in ("U") then provider_ccn = tranwrd(Provider,"U","0");
		else provider_ccn = Provider ;

	third_digit = substr(strip(Provider),3,1);

	/*20180221 - MB Update Change Label to (Anchor/Other Readmit) */
	if type = 'IP_Rehab' then type = 'IRF';
	else if type = 'IP_s' then type = 'Anchor Readmit';
	else if type = 'IP_d' then type = 'Other Readmit';
	else if type = 'IP_LTAC' then type = 'LTCH';
	else if type = 'HS' then type = "Hospice";

	*20170807 - Add rank_order variable to prioritize hierarchy;
	if substr(type,1,6) = "Anchor" or substr(type,1,5) = "Other" then rank_order = 1;
	else if type = "LTCH" then rank_order = 2;
	else if type = "IRF" then rank_order = 3;
	else if type = "SNF" then rank_order = 4;
	else if type = "Hospice" then rank_order = 5;
	else if type = "HH" then rank_order = 6;

	if dschrgdt = . then dschrgdt = dichrgdt2;

run;

proc sql;
	create table patientjourney_1a as 
		select a.*
			  ,case when type in ('OP_Idx','IP_Idx') then ''
				else propcase(fac_name) end as provider_name
			  ,case when Provider = "" then "Unknown ()"
			  		when Provider ^= "" and fac_name = "" then "Unknown ("||strip(propcase(Provider))||")"
					when Provider ^= "" and fac_name ^="" and third_digit='S' then "Psychiatric unit of "||strip(propcase(fac_name))||" ("||strip(Provider)||")"
					when Provider ^= "" and fac_name ^="" and third_digit='T' then "Rehabilitation unit of "||strip(propcase(fac_name))||" ("||strip(Provider)||")"
					when Provider ^= "" and fac_name ^="" and third_digit='Z' then "Swing-bed of "||strip(propcase(fac_name))||" ("||strip(Provider)||")"
					when Provider ^= "" and fac_name ^="" and third_digit='R' then "Rehabilitation unit of "||strip(propcase(fac_name))||" ("||strip(Provider)||")"
					when Provider ^= "" and fac_name ^="" and third_digit='M' then "Psychiatric unit of "||strip(propcase(fac_name))||" ("||strip(Provider)||")"
					when Provider ^= "" and fac_name ^="" and third_digit='U' then "Swing-bed of "||strip(propcase(fac_name))||" ("||strip(Provider)||")"
					else strip(propcase(fac_name))||" ("||strip(Provider)||")"
					end as Fac_Name_Desc format=$255.

		from patientjourney_1 as a
		left join ref.ccns_codemap as b
		on a.provider_ccn=b.ccn
		;
quit;

proc sort data = patientjourney_1a nodupkey;
	by epi_id_milliman admsn_dt rank_order; *20170807 - Add rank_order to sort statement;
run;

data patientjourney_1b (drop=provider);
	set patientjourney_1a;
	start_date = admsn_dt - anchor_end_dt;
	end_date = dschrgdt - anchor_end_dt;
	if end_date = . or end_date >=0;
run;



data patientjourney_2 (drop = i start_date end_date provider_ccn type admsn_dt dschrgdt provider 
		start_date2 end_date2 start_date_lag end_date_lag type2 type_lag);
	set patientjourney_1b;
	length provider d1-d90 d_first d_first_name d_second d_second_name d_third d_third_name type2 type_lag $255;	
	format d1-d90 type2 provider type_lag $255.;

	by epi_id_milliman;

	if type ^="" then do;
		if provider_name ^= '' then do;
			provider = strip(type)||": "||strip(Fac_Name_Desc);
		end;
		else do;
			provider = strip(type)||": "||strip(Fac_Name_Desc);
		end;
	end;
	else do;
		provider = "";
	end;

	retain start_date2 end_date2 type2 d1-d90 d_first d_first_name d_first_cost d_first_util_days d_second d_second_name d_second_cost d_second_util_days d_third d_third_name d_third_cost d_third_util_days rank2 rank_lag;

	if first.epi_id_milliman then do;

		start_date2 = start_date;
		end_date2 = end_date;
		type2 = type;
		rank2 = rank_order;
		start_date_lag = .;
		end_date_lag = .;
		type_lag = .;
		rank_lag = .;
		d_first_cost = .;
		d_first_util_days = .;  
 		d_second_cost = .;  
		d_second_util_days = .;  
		d_third_cost = .;  
		d_third_util_days = .;  

		d1 = ''; d2 = ''; d3 = ''; d4 = ''; d5 = ''; d6 = ''; d7 = ''; d8 = ''; d9 = '';
		d10 = ''; d11 = ''; d12 = ''; d13 = ''; d14 = ''; d15 = ''; d16 = ''; d17 = ''; d18 = ''; d19 = '';
		d20 = ''; d21 = ''; d22 = ''; d23 = ''; d24 = ''; d25 = ''; d26 = ''; d27 = ''; d28 = ''; d29 = '';
		d30 = ''; d31 = ''; d32 = ''; d33 = ''; d34 = ''; d35 = ''; d36 = ''; d37 = ''; d38 = ''; d39 = '';
		d40 = ''; d41 = ''; d42 = ''; d43 = ''; d44 = ''; d45 = ''; d46 = ''; d47 = ''; d48 = ''; d49 = '';
		d50 = ''; d51 = ''; d52 = ''; d53 = ''; d54 = ''; d55 = ''; d56 = ''; d57 = ''; d58 = ''; d59 = '';
		d60 = ''; d61 = ''; d62 = ''; d63 = ''; d64 = ''; d65 = ''; d66 = ''; d67 = ''; d68 = ''; d69 = '';
		d70 = ''; d71 = ''; d72 = ''; d73 = ''; d74 = ''; d75 = ''; d76 = ''; d77 = ''; d78 = ''; d79 = '';
		d80 = ''; d81 = ''; d82 = ''; d83 = ''; d84 = ''; d85 = ''; d86 = ''; d87 = ''; d88 = ''; d89 = '';
		d90 = ''; 
		d_first = ''; d_first_name = ''; d_second = ''; d_second_name = ''; d_third = ''; d_third_name = '';
	end;

	else do;
		start_date_lag = start_date2;
		end_date_lag = end_date2;
		type_lag = type2;
		rank_lag = rank2;
		start_date2 = start_date;
		end_date2 = end_date;
		type2 = type;
		rank2 = rank_order;
	end;

	array d(*) d1-d90 ;
	 
	do i=1 to 90;
	/*Assign provider for each day*/
		if start_date <= (i-1) <= end_date then do;
			if d{i} = "" then do;
				d{i} = provider;
			end;
			else if d{i} ^= "" and end_date_lag = start_date2 then do;
				d{i} = provider;
			end;
			else if d{i} ^= "" and rank_lag >= rank2 then do;
				d{i} = provider;
			end;
		end;
	/*Assign first PAC site - facilities within 2 days of discharge, HH within 4-5 days of discharge*/
		if d1 ^= '' and d1 = provider and start_date <= 0 then do;
			d_first = type;
			d_first_name = provider;
			d_first_cost = std_allowed_wage;
			d_first_util_days = util_day; 
		end;
		else if d_first = '' and d2 ^= '' and start_date = 1 then do;
			d_first = type;
			d_first_name = provider;
			d_first_cost = std_allowed_wage;
			d_first_util_days = util_day; 
		end;
		else if d_first = '' and d3 ^= '' and start_date = 2 then do;
			d_first = type;
			d_first_name = provider;
			d_first_cost = std_allowed_wage;
			d_first_util_days = util_day; 
		end;
		else if d_first = '' and d4 ^= '' and start_date = 3 and type = 'HH' then do;
			d_first = type;
			d_first_name = provider;
			d_first_cost = std_allowed_wage;
			d_first_util_days = util_day; 
		end;
		else if d_first = '' and d5 ^= '' and start_date = 4 and type = 'HH' then do;
			d_first = type;
			d_first_name = provider;
			d_first_cost = std_allowed_wage;
			d_first_util_days = util_day; 
		end;
	end;

	/*Assign second PAC site*/
	if start_date >= 0 and d_second = '' then do;
		if provider ^= d_first_name then do; /*If next site is different from first site*/
			if type = 'HH' then do;
				d_second = type;
				d_second_name = provider;
				d_second_cost = std_allowed_wage;  
 				d_second_util_days = util_day;  

			end;
			else if type = 'SNF' and type_lag = 'SNF' then do;
				if start_date - end_date_lag <=3 then do;
					d_second = type;
					d_second_name = provider;
					d_second_cost = std_allowed_wage;  
					d_second_util_days = util_day;  
				end;
				else if start_date - end_date_lag > 3 then do;
					d_second = 'Home';
					d_second_name = 'Home';
					d_third = type;
					d_third_name = provider;
					d_third_cost = std_allowed_wage;  
  					d_third_util_days = util_day;   
				end;
			end;
			else if start_date - end_date_lag > 1 then do;
				if type_lag = 'HH' and start_date - end_date_lag < 4 then do;
					d_second = type;
					d_second_name = provider;
					d_second_cost = std_allowed_wage;  
					d_second_util_days = util_day;  
				end;
				else if type_lag = 'HH' and end_date_lag < 0 then do;
					d_second = type;
					d_second_name = provider;
					d_second_cost = std_allowed_wage;  
					d_second_util_days = util_day;  
				end;
				else do;
					d_second = 'Home';
					d_second_name = 'Home';
					d_third = type;
					d_third_name = provider;
					d_third_cost = std_allowed_wage;  
  					d_third_util_days = util_day;  
				end;
			end;
			else do;
				d_second = type;
				d_second_name = provider;
				d_second_cost = std_allowed_wage;  
  				d_second_util_days = util_day;  

			end;
		end;
		else if provider = d_first_name then do; /*If next site is same as previous and it is the same SNF within 3 days, it should be continuous*/
			if type = 'SNF' and type_lag = 'SNF' then do;
				if start_date - end_date_lag <=3 then do;
					/*Nothing - allow space for next provider*/
				end;
				else if start_date - end_date_lag > 3 then do;
					d_second = 'Home';
					d_second_name = 'Home';
					d_third = type;
					d_third_name = provider;
					d_third_cost = std_allowed_wage;  
 					d_third_util_days = util_day; 
				end;
			end; 
			else if type = 'HH' and type_lag = 'HH' then do; end; /*20180212 JL UPDATE*/
			else if start_date - end_date_lag > 1 then do;
				d_second = 'Home';
				d_second_name = 'Home';
				end;
		end;
	end;
	/*Assign 3rd PAC site*/
	if d_second ^= '' and d_third = '' then do;
		if provider ^= d_second_name then do; /*If next site is different from first site*/
			if type = 'HH' then do;
				d_third = type;
				d_third_name = provider;
				d_third_cost = std_allowed_wage;  
 				d_third_util_days = util_day;
			end;
			else if type = 'SNF' and type_lag = 'SNF' then do;
				if start_date - end_date_lag <=3 then do;
					d_third = type;
					d_third_name = provider;
					d_third_cost = std_allowed_wage;  
 					d_third_util_days = util_day;  
				end;
				else if start_date - end_date_lag > 3 then do;
					d_third = 'Home';
					d_third_name = 'Home';
				end;
			end;
			else if start_date - end_date_lag > 1 then do;
				if d_second ^= 'Home' then do;
					if type_lag = 'HH' and start_date - end_date_lag < 4 then do;
						d_third = type;
						d_third_name = provider;
						d_third_cost = std_allowed_wage;  
 		 				d_third_util_days = util_day;  
					end;
					else do;
						d_third = 'Home';
						d_third_name = 'Home';
					end;
				end;
				else do;
					d_third = type;
					d_third_name = provider;
					d_third_cost = std_allowed_wage;  
 					d_third_util_days = util_day;  
				end;
			end;
			else do;
				d_third = type;
				d_third_name = provider;
				d_third_cost = std_allowed_wage;  
  				d_third_util_days = util_day;  
			end;
		end;
		else if provider = d_second_name then do; /*If next site is same as previous and it is the same SNF within 3 days, it should be continuous*/
			if type = 'SNF' and type_lag = 'SNF' then do;
				if start_date - end_date_lag <=3 then do;
				/*Nothing - allow space for next provider*/
				end;
				else if start_date - end_date_lag > 3 then do;
					d_third = 'Home';
					d_third_name = 'Home';
				end;
			end; 
			else do ; end ;
/*			else if start_date - end_date_lag > 1 then do; *20180212 JL UPDATE;*/
/*				d_third = 'Home';*/
/*				d_third_name = 'Home';*/
/*			end;*/
		end;
	end;

	if last.epi_id_milliman then do;
		if d_first = '' then do;
			d_first = 'Home';
			d_first_name = 'Home';
		end;
		if d_second = '' then do;
			if d_first = 'Home' or d90 = d_first_name then do;
				d_second = 'No change';
				d_second_name = 'No change';
			end;
			else do;
				d_second = 'Home';
				d_second_name = 'Home';
			end;
		end;
		if d_third = '' then do;
			if d_second in ('Home','No change') or d90 = d_second_name then do;
				d_third = 'No change';
				d_third_name = 'No change';
			end;
			else do;
				d_third = 'Home';
				d_third_name = 'Home';
			end;
		end;
		output;
	end;

run;

proc sql;
create table patientjourney_3 as
	select a.EncounterID
		,a.DataYearMo
		,a.Anchor_YearQtr
		,a.Anchor_YearMo
		,a.Anchor_Year	
		,a.bene_death_dt
		,a.anchor_end_dt
		,b.*
		,case when d_first in ("Other Readmit","Anchor Readmit") then "Readmit" else d_first end as d_first_2
	from out.epi_detail_&label._&bpid1._&bpid2. as a
	right join patientjourney_2 as b
	on a.epi_id_milliman = b.epi_id_milliman
	;
	quit ; 

	proc sort data = patientjourney_3 out = pjourney_2;by epi_id_milliman;run;

proc transpose data = pjourney_2 out = pjourney_agg_1
	name= d_number
	prefix=d_type;
	var d_first d_second d_third;
	by epi_id_milliman;
run;

proc transpose data = pjourney_2 (drop= d_first d_second d_third rename=(d_first_name=d_first d_second_name=d_second d_third_name=d_third)) out = pjourney_agg_2
	name= d_number
	prefix=d_name;
	var d_first d_second d_third;
	by epi_id_milliman;
run;

data pjourney_agg_1 (drop=d_type1 rename=d_type2=d_type1); 
	set pjourney_agg_1; 
	where epi_id_milliman ^= ""; 
	format d_type2 $50.; length d_type2 $50;
	d_type2 = coalescec(d_type1,"");
run;

data pjourney_agg_2 (drop=d_name1 rename=d_name2=d_name1); 
	set pjourney_agg_2; 
	where epi_id_milliman ^= ""; 
	format d_name2 $255.; length d_name2 $255;
	d_name2 = coalescec(d_name1,"");
run;

proc sql;
	create table out.pjourneyagg_&label._&bpid1._&bpid2. as
	select a.epi_id_milliman
	   , c.BPID  /*Dummy Variables for BPCIA */
		,case when a.d_number = 'd_first' then 'FIRST'
			when a.d_number = 'd_second' then 'SECOND'
			when a.d_number = 'd_third' then 'THIRD' end as d_number /*20170118 JL:clarify labeling for QVW*/
		,a.d_type1 as d_type
		,b.d_name1 as d_name
/*		,c.Anchor_CCN*/
		,c.ANCHOR_BEG_DT
		,c.ANCHOR_END_DT
	from pjourney_agg_1 as a left join pjourney_agg_2 as b
		on a.epi_id_milliman = b.epi_id_milliman and a.d_number=b.d_number
		left join patientjourney_3 as c
		on a.epi_id_milliman = c.epi_id_milliman
;
quit;



/********************************************************************************************/
/*code to create source of readmission*******************************************************/
/********************************************************************************************/
*20171204 - JL Update: Add source of readmit information;
proc sort data= patientjourney_1a;
	by  epi_id_milliman admsn_dt dschrgdt;
run; 

data readmit_source;
	set patientjourney_1a;
	length source_type readmit_source_type $20;
	length source_name readmit_source $85;
	where type ^='';
	by epi_id_milliman admsn_dt dschrgdt;

	retain last_discharge source_name source_type;

	if first.epi_id_milliman then do;
		last_discharge = .;
		source_name = '';
		source_type = '';
	end;

	if last_discharge ^= . and type in ('Other Readmit','Anchor Readmit') then do;
		if intck('day',last_discharge,admsn_dt) <= 1 then do;
			readmit_days = intck('day',last_discharge,admsn_dt);
			readmit_source = source_name;
			readmit_source_type = source_type;
		end;
	end;

	last_discharge = dschrgdt;
	source_name = Fac_Name_Desc;
	source_type = type;
	
if type in ('Other Readmit','Anchor Readmit') then output;

run;

*20190422 - SD Update: Adding emergency Information;
data ccn_enc_er_claims ; 
set ccn_enc11  ;
where substr(caretype,1,9) = "Emergency" ; 
run ; 

proc sort data= ccn_enc_er_claims nodupkey;
	by  epi_id_milliman startdate enddate;
run;  

data prov_er_claims ; 
set out.provider_&label._&bpid1._&bpid2.;
where substr(type,1,7) = "Prof_ER" ; 
run ; 

proc sort data= prov_er_claims nodupkey;
	by  epi_id_milliman service_date;
run;  

proc sql ; 
create table readmit_source1 as
			select distinct a.*
					 ,b.startdate as er_admsn_dt
					 ,b.enddate as er_dschrgdt
					 ,b.CCN_Name_Desc
					 ,b.caretype as er_type
					 ,c.service_date as prov_service_date
					 ,c.Physician as prov_Provider
					 ,c.type as prov_type
			from readmit_source as a
			left join ccn_enc_er_claims as b
			on a.epi_id_milliman = b.epi_id_milliman and  (a.admsn_dt = b.enddate or a.admsn_dt = sum(b.enddate,1) )
			left join prov_er_claims as c
			on a.epi_id_milliman = c.epi_id_milliman and  (a.admsn_dt = c.service_date or a.admsn_dt = sum(c.service_date,1))
;
quit ; 

data readmit_source2 ;
set readmit_source1 ;
if readmit_source_type not in ( 'SNF', 'IRF', 'LTCH') then do ;
		if er_type ^= '' then do;
			readmit_days = intck('day',er_dschrgdt,admsn_dt);
			readmit_source = CCN_Name_Desc;
			readmit_source_type = er_type;
		end;
		else if er_type = '' and prov_type ^= '' then do;
			readmit_days = intck('day',prov_service_date,admsn_dt);
			readmit_source = prov_Provider;
			readmit_source_type = prov_type;
		end;
end ; 
	run ; 

*This sorting is done to remove duplicates in instances where there are mutliple ER providers on the same day.;

proc sort data=readmit_source2 out=readmit_source3 ; 
by epi_id_milliman type provider_ccn  admsn_dt dschrgdt std_allowed_wage er_admsn_dt er_dschrgdt er_type ;
run ; 

proc sort data=readmit_source3 out=readmit_source4 nodupkey ; 
by epi_id_milliman type provider_ccn  admsn_dt dschrgdt std_allowed_wage ;
run ;


proc sql;
create table ccn_enc12 as 
	select a.*
		  ,b.readmit_source as source_of_admit
		  ,case when b.readmit_source_type = "Other Readmit" then "Other Facility" /* 20180126 Updated the naming */ 
				when b.readmit_source_type = "Anchor Readmit" then "Anchor Facility"
				when b.readmit_source_type = "Prof_ER_P" then "Emergency - Preceding Admit"
				else b.readmit_source_type end as source_of_admit_type length =50
	from ccn_enc11 as a
		left join readmit_source4 as b
	on a.epi_id_milliman = b.epi_id_milliman
	and a.startdate=admsn_dt
	and a.enddate=dschrgdt
	and a.CCN_Name_Desc=b.Fac_Name_Desc
;
quit;

/*********************************************************************************************/
/*Code to create %readmission rate from post-acute facilities*********************************/
/*********************************************************************************************/

data post_acute_readmits;
	set patientjourney_1;
	where type in ('Other Readmit','Anchor Readmit');
run;

data post_acute_snfirf;
	set patientjourney_1;
	where type in ('SNF','IRF','LTCH','Hospice');
run;

proc sql;
	create table snfirf_readmit as
		select distinct a.epi_id_milliman
			  ,a.admsn_dt
			  ,a.dschrgdt
			  ,a.BPID
			  ,a.provider_ccn
			  ,b.provider_ccn as readmit_ccn
			  ,b.admsn_dt as readmit_admit
			  ,b.dschrgdt as readmit_dschrg
			  ,b.util_day as readmit_LOS		/*20170421: Update readmit LOS*/
			  ,1 as snfirf_readmit_flag
			  ,b.third_digit
		from post_acute_snfirf as a
		,post_acute_readmits as b
		where a.epi_id_milliman = b.epi_id_milliman
		and a.BPID = b.BPID
		and a.dschrgdt <= b.admsn_dt
		and intck('day',a.dschrgdt,b.admsn_dt) <= 1
		;

	create table snfirf_readmit2 as 
		select a.*
			  ,propcase(b.fac_name) as Readmit_Name
			  ,case when readmit_ccn = "" then "Unknown ()"
			  		when readmit_ccn ^= "" and b.fac_name = "" then "Unknown ("||strip(readmit_ccn)||")"
					when readmit_ccn ^= "" and b.fac_name ^="" and third_digit='S' then "Psychiatric unit of "||strip(propcase(b.fac_name))||" ("||strip(readmit_ccn)||")"
					when readmit_ccn ^= "" and b.fac_name ^="" and third_digit='T' then "Rehabilitation unit of "||strip(propcase(b.fac_name))||" ("||strip(readmit_ccn)||")"
					when readmit_ccn ^= "" and b.fac_name ^="" and third_digit='Z' then "Swing-bed of "||strip(propcase(b.fac_name))||" ("||strip(readmit_ccn)||")"
					when readmit_ccn ^= "" and b.fac_name ^="" and third_digit='R' then "Rehabilitation unit of "||strip(propcase(b.fac_name))||" ("||strip(readmit_ccn)||")"
					when readmit_ccn ^= "" and b.fac_name ^="" and third_digit='M' then "Psychiatric unit of "||strip(propcase(b.fac_name))||" ("||strip(readmit_ccn)||")"
					when readmit_ccn ^= "" and b.fac_name ^="" and third_digit='U' then "Swing-bed of "||strip(propcase(b.fac_name))||" ("||strip(readmit_ccn)||")"
					else strip(propcase(b.fac_name))||" ("||strip(readmit_ccn)||")"
					end as Readmit_Name_Desc
		from snfirf_readmit as a
		left join ref.ccns_codemap as b
		on readmit_ccn = b.ccn
		;
quit;

*20170707 JL Update: Dedup rows for SNF/IRF stays where there were two readmits happening within the day after discharge;
proc sort data = snfirf_readmit2 out=snfirf_readmit2a; by epi_id_milliman admsn_dt readmit_admit; run;
proc sort data = snfirf_readmit2a out=snfirf_readmit3 nodupkey; by epi_id_milliman admsn_dt; run;

proc sql;
	create table ccn_enc13 as
		select distinct a.*
		      ,b.readmit_ccn
			  ,b.readmit_name
			  ,b.readmit_name_desc
			  ,b.readmit_los
			  ,b.snfirf_readmit_flag
			  /*20170905 - fac_timeframe update*/
			  ,case when a.timeframe in (1) then 1
			  		else 0
					end as fac_timeframe_1_30
			  ,case when a.timeframe in (1,2) then 1
			  		else 0
					end as fac_timeframe_1_60
			  ,case when a.timeframe in (1,2,3) then 1
			  		else 0
					end as fac_timeframe_1_90
			  ,case when a.timeframe in (0,1,2,3) then 1
			  		else 0
					end as fac_timeframe_all
		from ccn_enc12 as a
		left join snfirf_readmit3 as b
		on a.epi_id_milliman = b.epi_id_milliman 
		and a.BPID = b.BPID
		and a.provider_ccn_use = b.provider_ccn
		and a.startdate = b.admsn_dt
	;

quit;

/*20181026 - readmission quality measure update*/
proc sql;
	create table out.ccn_enc_&label._&bpid1._&bpid2. as
		select 	distinct a.*
			, 	b.UNPLANNED_READMIT_FLAG
			,	b.HAS_READMISSION
			,	b.transfer_stay
		from ccn_enc13 as a
		left join out.ipr_&label._&bpid1._&bpid2. as b
		on a.epi_id_milliman = b.epi_id_milliman 
		and a.BPID = b.BPID
		and a.type = b.type
		and a.startdate = b.stay_admsn_dt
		and a.enddate = b.stay_dschrgdt
		and a.timeframe=b.timeframe
		and a.DRG_CD=put(b.stay_drg_cd,3.)
		and a.provider_ccn=b.provider
	;

quit; 

/*20181026 - readmission quality measure update end*/

/*********************************************************************************************/
/*********************************************************************************************/


*********************************************************************************************/
/*Code to identify clinical visits in post-acute period***************************************/
/*********************************************************************************************/ ;
data op;
	set out.ccn_enc_&label._&bpid1._&bpid2. (keep=BPID Epi_id_Milliman type provider_ccn CCN_Name_Desc startdate HCPCS_CD rev_cntr std_allowed_wage edac_flag rename=(CCN_Name_Desc=Provider startdate = service_date));
	if substr(type,1,2) = "OP" and type ^= "OP_Idx";
	rev_ctr = put(rev_cntr,$3.);
run;

data prov;
	set out.provider_&label._&bpid1._&bpid2.(keep=BPID Epi_id_Milliman type provider_npi Physician service_date HCPCS_CD Op_MD_flag At_MD_flag std_allowed_wage timeframe2 edac_flag rename=(Physician=Provider));
	where timeframe2 ^= "Anchor";
run;

data hh_hdr1;
	set out.ccn_enc_&label._&bpid1._&bpid2.  (keep=BPID GEO_BENE_SK claimno startdate Anchor_CCN Epi_id_Milliman type provider_ccn CCN_Name_Desc rename=(CCN_Name_Desc=Provider /*provider_ccn=provider_ccn1*/));
	if substr(type,1,2) = "HH";
run;

*20180720 - transpose dates, rev center, and hcpcs to set up long list of dates;
proc sort data = out.hha_&label._&bpid1._&bpid2. out=hh_hdr2aa; by epi_id_milliman claimno;run;
proc sort data = out.hha_&label._&bpid1._&bpid2. out=hh_hdr2bb; by epi_id_milliman claimno;run;
proc sort data = out.hha_&label._&bpid1._&bpid2. out=hh_hdr2cc; by epi_id_milliman claimno;run;

proc transpose data = hh_hdr2aa out=hh_hdr2a;
	by epi_id_milliman claimno;
	var rvcntr01-rvcntr45;
run;

proc transpose data = hh_hdr2bb out=hh_hdr2b;
	by epi_id_milliman claimno;
	var rev_dt01-rev_dt45;
run;

proc transpose data = hh_hdr2cc out=hh_hdr2c;
	by epi_id_milliman claimno;
	var hcpscd01-hcpscd45;
run;

data hh_hdr2a1 (drop=_NAME_ col1);
	set hh_hdr2a /*(rename=(col1=rvcntr))*/;
	num = substr(_NAME_,7,2);
	rvcntr=coalesce(col1,".");
	if rvcntr ^= .;
run;

data hh_hdr2b1 (drop=_NAME_);
	set hh_hdr2b /*(rename=(col1=rev_dt))*/;
	num = substr(_NAME_,7,2);
	rev_dt=coalesce(col1,".");
	if rev_dt ^= .;
run;

data hh_hdr2c1 (drop=_NAME_);
	set hh_hdr2c /*(rename=(col1=hcpcs))*/;
	num = substr(_NAME_,7,2);
	hcpcs=coalescec(col1,"");
	if hcpcs ^= "";
/*	hcpcs2 = put(hcpcs,$20.);*/
run;

*inner join to find lines where none of the three components are missing;
proc sql;
	create table hh_hdr3 as
	select a.*
		,b.rev_dt
		,c.hcpcs
	from hh_hdr2a1 as a
	inner join hh_hdr2b1 as b
	on a.epi_id_milliman = b.epi_id_milliman and a.claimno = b.claimno and a.num = b.num
	inner join hh_hdr2c1 as c
	on a.epi_id_milliman = c.epi_id_milliman and a.claimno = c.claimno and a.num = c.num
	where a.rvcntr not in (1,23) and c.hcpcs ^= "Q5001"
;
quit;

*join visit dates to header HH file;
proc sql;
	create table hh_visits as
	select	distinct
			a.*
		,	b.rev_dt as service_date
	from	hh_hdr1 as a
			inner join hh_hdr3 as b
			on a.epi_id_milliman = b.epi_id_milliman and a.claimno = b.claimno
;
quit ;
*20180720 update end;

data visits;
	format provider $298. clinic_visit_type $50.; length provider $298 clinic_visit_type $50;
	set op(in=a) prov(in=b) hh_visits(in=c) ;/*MB ADDITION HH INDICATORS 20180126*/
	hierarchy = 0;
	if a or b then do ; /*MB ADDITION HH INDICATORS 20180126*/
	if put(HCPCS_CD,$Obs_HCPCS.) = 'Y' or put(REV_CTR,$Obs_Revenue_CD.) = 'Y' then do; 
		hierarchy = 1; clinic_visit_type = "Observation"; end;
	else if put(HCPCS_CD,$ER_HCPCS.) = 'Y' or put(REV_CTR,$ER_Revenue_CD.) = 'Y' then do; 
		hierarchy = 2; clinic_visit_type = "Emergency Room"; end;
	else if put(HCPCS_CD,$Physician_visits_HCPCS.) = 'Y' and Op_MD_flag = "Yes" then do; 
		hierarchy = 3; clinic_visit_type = "Operating Physician Visit"; end;
	else if put(HCPCS_CD,$Physician_visits_HCPCS.) = 'Y' and Op_MD_flag = "No" then do; 
		hierarchy = 4; clinic_visit_type = "Other Physician Visit"; end;
	else if put(HCPCS_CD,$Therapy_HCPCS.) = 'Y' then do; 
		hierarchy = 5; clinic_visit_type = "Therapy"; end;
end;

/*MB ADDITION HH INDICATORS 20180126*/
	else if c then do;
		hierarchy = 6; clinic_visit_type = "HH";
	end;
 /*MB ADDITION HH INDICATORS 20180126*/
	if hierarchy > 0;
run;

proc sort; by epi_id_milliman service_date hierarchy type descending std_allowed_wage;

run;
			
proc sort data = visits nodupkey out=visits2; by epi_id_milliman service_date; run;

*Join anchor end date to file for later calculation;
proc sql;
	create table visits3a as
	select a.*
		,b.anchor_end_dt
	from visits2 as a
	left join out.epi_detail_&label._&bpid1._&bpid2. as b
	on a.epi_id_milliman = b.epi_id_milliman
;
quit;

proc sql;
	create table visits_ER as
	select distinct a.*
		,1 as IP_visit_flag
	from visits3a as a
	left join out.ccn_enc_&label._&bpid1._&bpid2. as b
	on a.epi_id_milliman = b.epi_id_milliman and (a.service_date = b.startdate or sum(a.service_date,1) = b.startdate)
	where a.clinic_visit_type = "Emergency Room" and b.type in ("IP_d","IP_s")
;
*Merge flags for overlapping admissions to original dataset;
	create table visits3b as
	select a.*
		,b.IP_visit_flag
	from visits3a as a
	left join visits_ER as b
	on a.epi_id_milliman = b.epi_id_milliman and a.service_date = b.service_date and a.type = b.type
;
quit;

*Change ER visits to ER - stand alone or ER - preceding admit based on overlap with inpatient admissions on the same day;
data visits3;
	set visits3b;
	if clinic_visit_type = "Emergency Room" then do;
		if IP_visit_flag = 1 then clinic_visit_type = "Emergency Room - Preceding Admit";
		else clinic_visit_type = "Emergency Room - Stand Alone";
	end;
run;

*Assign visits for each day of post-acute period;
data visits4 (keep = epi_id_milliman v1-v90);
	set visits3;

	format visit_provider $255.; length visit_provider $255;

	start_date = service_date - anchor_end_dt;

	if clinic_visit_type ^="" then visit_provider = strip(clinic_visit_type)||": "||strip(provider)||": "||strip(put(service_date,$mmddyy10.));
	else visit_provider = "";

	by epi_id_milliman; 

	retain v1-v90;
	length v1-v90 $255;

	if first.epi_id_milliman then do;

		v1 = ''; v2 = ''; v3 = ''; v4 = ''; v5 = ''; v6 = ''; v7 = ''; v8 = ''; v9 = '';
		v10 = ''; v11 = ''; v12 = ''; v13 = ''; v14 = ''; v15 = ''; v16 = ''; v17 = ''; v18 = ''; v19 = '';
		v20 = ''; v21 = ''; v22 = ''; v23 = ''; v24 = ''; v25 = ''; v26 = ''; v27 = ''; v28 = ''; v29 = '';
		v30 = ''; v31 = ''; v32 = ''; v33 = ''; v34 = ''; v35 = ''; v36 = ''; v37 = ''; v38 = ''; v39 = '';
		v40 = ''; v41 = ''; v42 = ''; v43 = ''; v44 = ''; v45 = ''; v46 = ''; v47 = ''; v48 = ''; v49 = '';
		v50 = ''; v51 = ''; v52 = ''; v53 = ''; v54 = ''; v55 = ''; v56 = ''; v57 = ''; v58 = ''; v59 = '';
		v60 = ''; v61 = ''; v62 = ''; v63 = ''; v64 = ''; v65 = ''; v66 = ''; v67 = ''; v68 = ''; v69 = '';
		v70 = ''; v71 = ''; v72 = ''; v73 = ''; v74 = ''; v75 = ''; v76 = ''; v77 = ''; v78 = ''; v79 = '';
		v80 = ''; v81 = ''; v82 = ''; v83 = ''; v84 = ''; v85 = ''; v86 = ''; v87 = ''; v88 = ''; v89 = '';
		v90 = ''; 
	end;

	array v(*) v1-v90 ;
	 
	do i=1 to 90;
	/*Assign provider for each day*/
		if start_date = (i-1) then do;
			v{i} = visit_provider;
		end;
	end;

	if last.epi_id_milliman then output;
run;

*Join to PAC pjourney file to output final pjourney file;

proc sql ;
	create table patientjourney_4 as 
	select a.* ,
		   b.* 
	from patientjourney_3 as a 
	left join visits4 as b 
	on a.epi_id_milliman=b.epi_id_milliman ;
quit ;

data out.pjourney_&label._&bpid1._&bpid2. (drop=i);
	set patientjourney_4 ;
	array d(*) d1-d90 ;
	array v(*) v1-v90 ;
	do i=1 to 90 ;
		if bene_death_dt ne . then do ;
			if  anchor_end_dt + i - 1 > bene_death_dt then do ;
				d(i)="Deceased";
				v(i)="Deceased";
			end ;
		else if  anchor_end_dt + i - 1 = bene_death_dt then v(i)="Deceased: " || put (bene_death_dt, mmddyy10.);
		end ;
	end ;
run ;

*Create output table of all PAC and clinic visit types for all episodes as QVW filter;
data util_table (keep= BPID epi_id_milliman type);
	set patientjourney_1b (keep= BPID epi_id_milliman type)
		visits3 (keep= BPID epi_id_milliman clinic_visit_type rename=(clinic_visit_type=type))
	;
	where type ^= "";
	if type = "Other Readmit" then type = "Other Readmit"; /*20171107 JL Update - clean up label*/
	if type = "Anchor Readmit" then type = "Anchor Readmit";
run;

proc sort data = util_table nodupkey out = out.util_&label._&bpid1._&bpid2.; by epi_id_milliman type; run;




*********************************************************************************************/
/*** Code to create Patient Detail Report  ***************************************************/
/*********************************************************************************************/
*20180723 UPDATE: update the HH visits logic;
*Count number of unique visits for each claim;
proc sql;
	create table hh_hdr4 as
	select epi_id_milliman
		,claimno
		,count(*) as hh_visits
	from hh_hdr3
	group by epi_id_milliman, claimno
;
quit;

proc sql;
	create table ccn_hh as
	select a.*
		,case when type = "HH" then b.hh_visits else a.util_day end as util_day2
	from out.ccn_enc_&label._&bpid1._&bpid2. as a
	left join hh_hdr4 as b
	on a.epi_id_milliman=b.epi_id_milliman and a.claimno=b.claimno
;
quit;

data out.ccn_enc_&label._&bpid1._&bpid2. (rename=(util_day2=util_day));
	set ccn_hh (drop=util_day);
run;
*20180723 UPDATE END;

* Code to start the creation of the Patient Detail Report;
proc sql;
create table patient_detail1 as
	select 

/*Inpatient Anchor info - pulled from CCN file to include transfers*/
	 epi_id_milliman
	,BPID
	,CCN_Name_desc as service_provider
	,'Anchor Hospital Stay' as caretype
	,startdate as begin_date 
	,enddate as end_date 
	,'' as attending_name 
	,'' as operating_name
	,'' as ER_Physician
	,prim_diag_with_desc as primary_diag
	,prim_proc_with_desc as primary_proc
	,drg_with_desc as msdrg
	,-1 as timeframe
	,'Anchor' as timeframe2
	,'Anchor' as timeframe3
	,std_allowed_wage
	,util_day		/*20170323 JL Add*/

	,'' as physician_abbr
	,'' as physician_role
	,. as prov_timeframe_1_30
	,. as prov_timeframe_1_60
	,. as prov_timeframe_1_90
	,. as prov_timeframe_all
	,"" as Op_MD_Flag
	,"" as At_MD_Flag

	,'' as source_of_admit
	,'' as source_of_admit_type
	,'' as readmit_ccn
	,'' as readmit_name
	,'' as readmit_name_desc
	,. as readmit_LOS
	,. as snfirf_readmit_flag
	,0 as fac_timeframe_1_30
	,0 as fac_timeframe_1_60
	,0 as fac_timeframe_1_90
	,1 as fac_timeframe_all
	,"Facility" as claim_category
	,admitting_diag_code
    ,DGNSCD02,DGNSCD03,DGNSCD04,DGNSCD05,DGNSCD06,DGNSCD07,DGNSCD08,DGNSCD09,DGNSCD10,DGNSCD11,DGNSCD12,DGNSCD13,DGNSCD14,DGNSCD15,DGNSCD16,DGNSCD17,DGNSCD18,DGNSCD19,DGNSCD20,DGNSCD21,DGNSCD22,DGNSCD23,DGNSCD24,DGNSCD25
	,edac_flag
	,UNPLANNED_READMIT_FLAG
	,HAS_READMISSION
	,'' as provider_specialty
	,TRANSFER_STAY
	from out.ccn_enc_&label._&bpid1._&bpid2.
	where type = "IP_Idx"

union all

/*Outpatient Anchor info*/
	select
		 epi_id_milliman
		,BPID
		,CCN_Name_desc as service_provider
		,'Anchor Hospital Stay' as caretype
		,startdate as begin_date 
		,enddate as end_date 
		,'' as attending_name 
		,'' as operating_name
		,'' as ER_Physician
		,prim_diag_with_desc as primary_diag
		,hcpcs_with_desc  as primary_proc
		,drg_with_desc as msdrg
		,-1 as timeframe
		,'Anchor' as timeframe2
		,'Anchor' as timeframe3
		,std_allowed_wage
		,util_day		/*20170323 JL Add*/

		,'' as physician_abbr
		,'' as physician_role
		,. as prov_timeframe_1_30
		,. as prov_timeframe_1_60
		,. as prov_timeframe_1_90
		,. as prov_timeframe_all
		,"" as Op_MD_Flag
		,"" as At_MD_Flag

		,'' as source_of_admit
		,'' as source_of_admit_type
		,'' as readmit_ccn
		,'' as readmit_name
		,'' as readmit_name_desc
		,. as readmit_LOS
		,. as snfirf_readmit_flag
		,0 as fac_timeframe_1_30
		,0 as fac_timeframe_1_60
		,0 as fac_timeframe_1_90
		,1 as fac_timeframe_all
		,"Facility" as claim_category
		,admitting_diag_code
		,DGNSCD02
		,DGNSCD03
		,DGNSCD04
		,DGNSCD05
		,DGNSCD06
		,DGNSCD07
		,DGNSCD08
		,DGNSCD09
		,DGNSCD10
		,DGNSCD11
		,DGNSCD12
		,DGNSCD13
		,DGNSCD14
		,DGNSCD15
		,DGNSCD16
		,DGNSCD17
		,DGNSCD18
		,DGNSCD19
		,DGNSCD20
		,DGNSCD21
		,DGNSCD22
		,DGNSCD23
		,DGNSCD24
		,DGNSCD25
		,edac_flag
		,. as UNPLANNED_READMIT_FLAG
		,. as HAS_READMISSION
		,'' as provider_specialty
		,0 as TRANSFER_STAY
		from out.ccn_enc_&label._&bpid1._&bpid2.
		where type = "OP_Idx"

union all

	select
		 epi_id_milliman 
		,BPID
		,physician as service_provider
		,type as caretype
		,service_date as begin_date 
		,. as end_date 
		,'' as attending_name
		,'' as operating_name
		,'' as ER_Physician
		,prim_diag_with_desc as primary_diag 
		,prof_hcpcs_code_desc as primary_proc
		,'' as msdrg
		,case when (timeframe = 0 and type in ('Prof_ER_P','Prof_ER_S') and service_date <= ANCHOR_BEG_DT) then -2 else timeframe end as timeframe
		,timeframe2
		,case when timeframe2 = 'Anchor' then 'Anchor' else 'Post-Acute' end as timeframe3
		,std_allowed_wage
		,. as util_day		/*20170323 JL Add*/

		,physician_abbr
		,physician_role
		,prov_timeframe_1_30
		,prov_timeframe_1_60
		,prov_timeframe_1_90
		,prov_timeframe_all
		,Op_MD_Flag
		,At_MD_Flag

		,'' as source_of_admit
		,'' as source_of_admit_type
		,'' as readmit_ccn
		,'' as readmit_name
		,'' as readmit_name_desc
		,. as readmit_LOS
		,. as snfirf_readmit_flag
		,. as fac_timeframe_1_30
		,. as fac_timeframe_1_60
		,. as fac_timeframe_1_90
		,. as fac_timeframe_all
		,"Provider" as claim_category
		,'' as admitting_diag_code
		,DGNSCD02
		,DGNSCD03
		,DGNSCD04
		,DGNSCD05
		,DGNSCD06
		,DGNSCD07
		,DGNSCD08
		,DGNSCD09
		,DGNSCD10
		,DGNSCD11
		,DGNSCD12
		,'' as DGNSCD13
		,'' as DGNSCD14
		,'' as DGNSCD15
		,'' as DGNSCD16
		,'' as DGNSCD17
		,'' as DGNSCD18
		,'' as DGNSCD19
		,'' as DGNSCD20
		,'' as DGNSCD21
		,'' as DGNSCD22
		,'' as DGNSCD23
		,'' as DGNSCD24
		,'' as DGNSCD25
		,edac_flag
		,. as UNPLANNED_READMIT_FLAG
		,. as HAS_READMISSION
		,provider_specialty
		,0 as TRANSFER_STAY
	from out.provider_&label._&bpid1._&bpid2.

union all

	select
		a.epi_id_milliman
		,a.BPID
		,a.CCN_Name_Desc as service_provider
		,a.caretype
		,a.startdate as begin_date format=mmddyy10.
		,a.enddate as end_date format=mmddyy10.
		,'' as attending_name /*Need to fix with CCN_ENC */
		,'' as operating_name
		,ER_Physician
		,prim_diag_with_desc as primary_diag
		,case when substr(caretype,1,3) in ('Eme','Out','Pro','Reh') then hcpcs_with_desc else prim_proc_with_desc end as primary_proc
		,drg_with_desc as msdrg
		,case when (timeframe = 0 and caretype in ('Emergency - Preceding Admit','Emergency - Stand Alone') and startdate <= ANCHOR_BEG_DT) then -2 else timeframe end as timeframe
		,a.timeframe2
		,case when a.timeframe2 = 'Anchor' then 'Anchor' else 'Post-Acute' end as timeframe3
		,a.std_allowed_wage
		,a.util_day		

		,'' as physician_abbr
		,'' as physician_role
		,. as prov_timeframe_1_30
		,. as prov_timeframe_1_60
		,. as prov_timeframe_1_90
		,. as prov_timeframe_all
		,"" as Op_MD_Flag
		,"" as At_MD_Flag

		,source_of_admit
		,source_of_admit_type
		,readmit_ccn
		,readmit_name
		,readmit_name_desc
		,readmit_LOS
		,snfirf_readmit_flag
		,fac_timeframe_1_30
		,fac_timeframe_1_60
		,fac_timeframe_1_90
		,fac_timeframe_all
		,"Facility" as claim_category
		,admitting_diag_code
		,DGNSCD02,DGNSCD03,DGNSCD04,DGNSCD05,DGNSCD06,DGNSCD07,DGNSCD08,DGNSCD09,DGNSCD10,DGNSCD11,DGNSCD12,DGNSCD13,DGNSCD14,DGNSCD15,DGNSCD16,DGNSCD17,DGNSCD18,DGNSCD19,DGNSCD20,DGNSCD21,DGNSCD22,DGNSCD23,DGNSCD24,DGNSCD25
		,edac_flag
		,UNPLANNED_READMIT_FLAG
		,HAS_READMISSION
		,'' as provider_specialty
		,case when TRANSFER_STAY=. then 0 else TRANSFER_STAY end as TRANSFER_STAY
	from out.ccn_enc_&label._&bpid1._&bpid2. as a
	where timeframe2 ^= 'Anchor' or (timeframe2 = 'Anchor' and caretype in ('Emergency - Preceding Admit','Emergency - Stand Alone','Rehab','Outpatient','Home Health','Hospice','LTCH','SNF','IRF'))

	order by BPID, epi_id_milliman, begin_date;

quit;

proc sql;
	create table patient_Detail2_pre as 
	select encounterid
	,datayearmo
	,anchor_yearqtr
	,anchor_yearmo
	,anchor_year
	,age 
	,anchor_beg_dt 
	,anchor_end_dt  
	,anchor_code 
	,Anchor_Fac_Code_Name 
	,Episode_Initiator
	,case when (b.timeframe = 0 and b.end_date <= a.anchor_end_dt and b.begin_date <= a.anchor_beg_dt and b.end_date^=. ) then -3 else b.timeframe end as timeframe
	,b.*
	,case when timeframe ^= 0 and Caretype = 'Outpatient'  then 0/*Create a Rank variable to rank Outpatient before  and Prof emergency Claims before Readmit claims if they occur on the same day*/
			when timeframe ^= 0 and substr(Caretype,1,7) = 'Prof_ER' or substr(Caretype,1,2) = 'Em'  then 1 
		 	when Caretype = 'Readmit' then 2
			else 3 end as rank3
	from out.epi_detail_&label._&bpid1._&bpid2. as a
	,patient_detail1 as b
	where a.epi_id_milliman = b.epi_id_milliman
	and a.BPID = b.BPID
	order by BPID, epi_id_milliman, timeframe, transfer_stay, begin_date, rank3, end_date desc;
quit;

data patient_Detail2;
	set patient_Detail2_pre;
	end_date_drop = end_date;
	if end_date_drop=. then end_date_drop=mdy(12,31,2099);
	if end_date_drop=mdy(12,31,2099) and (substr(Caretype,1,7) = 'Prof_ER' or substr(Caretype,1,2) = 'Em') then end_date_drop=mdy(12,30,2099);
	if end_date_drop=mdy(12,31,2099) and Caretype = 'Outpatient' then end_date_drop=mdy(12,29,2099);
	proc sort; by BPID epi_id_milliman timeframe transfer_stay begin_date rank3 end_date_drop;
run;

data patient_detail3 (drop=counter);
	set patient_detail2;
	by BPID epi_id_Milliman ;
	length claimid $12 caretype_long $50.;
	format begin_date end_date mmddyy10.;


	retain counter;

	if first.epi_id_milliman then do;
		counter = 1;
	end;

	claimid = "Claim"||strip(put(counter,4.));

	counter+1;

/*	if timeframe <=0 then timeframe = 'Anchor';*/
	/*20180625 MK Addition*/
	if substr(caretype,1,2)='HH' then caretype_long='Home Health';
	else if substr(caretype,1,3)='SNF' then caretype_long= 'Skilled Nursing Facility';
	else if substr(caretype,1,3)='IRF' then caretype_long= 'Inpatient Rehab Facility';
	else if substr(caretype,1,4)='LTAC' then caretype_long= 'Long Term Care Hospital';
	else if substr(caretype,1,2)='IP' then caretype_long= 'Acute Inpatient Hospital';
	else if substr(caretype,1,4)='Ambu' then caretype_long= 'Ambulance';
	else if substr(caretype,1,4)='Anes' then caretype_long= 'Anesthesia';
	else if substr(caretype,1,9)='Prof_Card' then caretype_long= 'Cardiovascular Testing';
	else if substr(caretype,1,8)='Prof_Oth' then caretype_long= 'Professional - Other';
	else if substr(caretype,1,4)='Path' then caretype_long= 'Pathology';
	else if substr(caretype,1,7)='Prof_IP' then caretype_long= 'Professional - Inpatient';
	else if substr(caretype,1,7)='Prof_Su' then caretype_long= 'Professional - Surgery';
	else if substr(caretype,1,7)='Prof_An' then caretype_long= 'Professional - Anesthesia';
	else if substr(caretype,1,7)='Prof_Ra' then caretype_long= 'Professional - Radiology';
	else if substr(caretype,1,9)='Prof_Path' then caretype_long= 'Professional - Pathology';
	else if substr(caretype,1,7)='Prof_Am' then caretype_long= 'Professional - Ambulance';
	else if substr(caretype,1,7)='Prof_Re' then caretype_long= 'Professional - Rehab';
	else if substr(caretype,1,9)='Prof_ER_P' then caretype_long= 'Professional - Emergency Preceding Admit';
	else if substr(caretype,1,9)='Prof_ER_S' then caretype_long= 'Professional - Emergency Stand Alone';
	else if substr(caretype,1,9)='Prof_Part' then caretype_long= 'Part B Pharmacy';
	else if substr(caretype,1,4)='Radi' then caretype_long= 'Radiology';
	else if substr(caretype,1,5)='Rehab' then caretype_long= 'Outpatient - Rehab';
	else if substr(caretype,1,4)='Anch' then caretype_long= 'Anchor Hospital Stay';
	else if substr(caretype,1,2)='OP' then caretype_long= 'Outpatient';
	else if substr(caretype,1,3)='DME' then caretype_long= 'DME';
	else if substr(caretype,1,13)='Emergency - P' then caretype_long= 'Emergency - Preceding Admit';
	else if substr(caretype,1,13)='Emergency - S' then caretype_long= 'Emergency - Stand Alone';
	else caretype_long=caretype;
	/*20180625 MK Addition*/
run;

data patient_detail4;
	set patient_detail3;
	format UNPLANNED_READMIT_FLAG_USE HAS_READMISSION_USE service_provider_ccn $12.;

	if UNPLANNED_READMIT_FLAG = 9 then UNPLANNED_READMIT_FLAG_USE = 'Transfer';
            else if UNPLANNED_READMIT_FLAG = 1 then UNPLANNED_READMIT_FLAG_USE = 'Yes';
            else if UNPLANNED_READMIT_FLAG = 0 then UNPLANNED_READMIT_FLAG_USE = 'No';
            else UNPLANNED_READMIT_FLAG_USE = '';

    if HAS_READMISSION = 9 then HAS_READMISSION_USE = 'Transfer';
            else if HAS_READMISSION = 1 then HAS_READMISSION_USE = 'Yes';
            else if HAS_READMISSION = 0 then HAS_READMISSION_USE = 'No';
            else HAS_READMISSION_USE = '';
	service_provider_ccn = scan(service_provider, 2, '()');	 

		if claim_category='Facility' then service_provider_ccn = scan(service_provider, -2, '()');
			else  service_provider_ccn='.';

		*** Identification of Short Term Acute and CAH stays for readmissions *** ;
	pv = substr(service_provider_ccn,3,4);
	readm_cand = 0;
	if '0001' <= pv and pv <= '0899' then readm_cand = 1;
	else if '1300' <= pv and pv <= '1399' then readm_cand = 1;
	*** Identification of PPS-exempts cancer hospital admissions for to be excluded for readmissions *** ;
	else if service_provider_ccn in ('050146','050660','100079','100271','220162','330154','330354','360242','390196','450076','500138') then readm_cand=0;  
run;

data bpcia_episode_initiator_info;
	set bpciaref.bpcia_episode_initiator_info;
	djrle = sum(Double_joint_replacement_of_the_,0);
	mjrle = sum(Major_joint_replacement_of_the_l,0);
	comp_flag_num = max(djrle,mjrle);
	if comp_flag_num = 1 then Comp_Flag='1';
	else Comp_Flag = '';
run;

proc sql;
	create table out.pat_detail_&label._&bpid1._&bpid2. as
		select distinct
			a.*
			,b.ALL as All_Flag
			,b.ALL_IP as PSI_Flag
			,b.Coronary_artery_bypass_graft as CABG_Flag
			,b.Acute_myocardial_infarction as AMI_Flag
			,b.Comp_Flag
		from patient_detail4 as a left join 
			bpcia_episode_initiator_info as b
			on a.BPID = b.BPCI_Advanced_ID_Number_2
;
quit;


proc sort data=out.pat_detail_&label._&bpid1._&bpid2.; by BPID epi_id_milliman timeframe transfer_stay begin_date rank3 end_date_drop; run;


/*********************************************************************************************/
/*** Code to create an attending/operating physician detail table  ***************************/
/*********************************************************************************************/

proc sql;
create table provider_sum1 as 
	select distinct
		 epi_id_milliman
		,BPID
		,physician 
		,physician_abbr
		,physician_role
		,anchor_yearmo
		,anchor_yearqtr
		,anchor_year
	from out.provider_&label._&bpid1._&bpid2.
	where physician_type in ('Operating MD','Attending MD','Attending & Operating MD') /*Changed to Physician Type */
	;

create table out.prov_detail_&label._&bpid1._&bpid2. as 
	select distinct a.*
			,sum(T0_IP_IDX_ALLOWED) as prov_ancfac_allowed
			,sum(T0_NONFACILITY_ALLOWED) as prov_nonfac_allowed
			,sum(T4_IP_A_FAC_ALLOWED,T4_IP_A_PROF_ALLOWED,T4_IP_O_FAC_ALLOWED,T4_IP_O_PROF_ALLOWED) as prov_readmits_allowed
			,sum(T4_LTAC_ALLOWED,T4_LTAC_PROF_ALLOWED) as prov_ltch_allowed
			,sum(T4_IRF_ALLOWED,T4_IRF_PROF_ALLOWED) as prov_irf_allowed
			,sum(T4_HH_ALLOWED) as prov_hh_allowed
			,sum(T4_SNF_ALLOWED,T4_SNF_PROF_ALLOWED) as prov_snf_allowed
			,sum(T4_AMBULANCE_ALLOWED,T4_PARTB_RX_ALLOWED,T4_PATHOLOGY_ALLOWED,T4_RADIOLOGY_ALLOWED,T4_OP_REHAB_ALLOWED,T4_OTHER_ALLOWED) as prov_other_allowed
			,sum(T4_TOTAL_ALLOWED) as prov_total_allowed
	from provider_sum1 as a
	left join out.epi_detail_&label._&bpid1._&bpid2. as b
	on a.epi_id_milliman = b.epi_id_milliman
	and a.BPID = b.BPID
	group by
		b.epi_id_milliman
		,a.BPID
		,a.physician 
		,a.physician_abbr
		,a.physician_role
		,a.anchor_yearmo
		,a.anchor_yearqtr
		,a.anchor_year
	;

quit;



/*********************************************************************************************/
/*********************************************************************************************/

/*********************************************************************************************/
/*** Code to create Performance Benchmarks table  ********************************************/
/*********************************************************************************************/

data perf (keep=epi_id_milliman anchor_code FRACTURE_FLAG frac_flag_filter BPID);
	set out.epi_&label._&bpid1._&bpid2.;
		 if FRACTURE_FLAG=1 then frac_flag_filter = "Yes" ;
			else frac_flag_filter = "No" ;  /*MB Code to create a chracter fracture variable */
/*		where type = ('IP_Idx');*/

run;

data perf0a;
	set perf(in=a)
		perf(in=b)
		perf(in=c)
		perf(in=d)
		perf(in=e);

		Count = 1;

		if a then timeframe = 1;
		else if b then timeframe = 2;
		else if c then timeframe = 3;
		else if d then timeframe = 4;
		else if e then timeframe = 5;


run;

data perf1 (keep = BPID epi_id_milliman anchor_code timeframe IP_UTIL IP_DAYS IRF_UTIL IRF_DAYS LTAC_UTIL LTAC_DAYS SNF_UTIL SNF_DAYS HH_UTIL);
	set out.ip_&label._&bpid1._&bpid2. (in=d keep = BPID epi_id_milliman anchor_code type stay_admsn_dt stay_dschrgdt timeframe POST_DSCH_BEG_DT POST_DSCH_END_DT anchor_end_dt util_day days1 rename=(stay_admsn_dt=admsn_dt stay_dschrgdt=dschrgdt))
		out.snf_&label._&bpid1._&bpid2. (in=e keep = BPID epi_id_milliman anchor_code type admsn_dt dschrgdt timeframe POST_DSCH_BEG_DT POST_DSCH_END_DT anchor_end_dt from_dt thru_dt util_day)
		out.hha_&label._&bpid1._&bpid2. (in=f keep = BPID epi_id_milliman anchor_code type timeframe POST_DSCH_END_DT anchor_end_dt util_day); 
	
			if type in ('IP_d','IP_s') then do;
					IP_UTIL = 1;
					if post_dsch_end_dt < dschrgdt then IP_DAYS = sum(post_dsch_end_dt - max(post_dsch_beg_dt,admsn_dt),1);
					else if admsn_dt = dschrgdt then IP_DAYS = 1;
					else IP_DAYS = dschrgdt - max(post_dsch_beg_dt,admsn_dt);
			end;
			else if type in ('IP_Rehab') then do;
					IRF_UTIL = 1;
					if post_dsch_end_dt < dschrgdt then IRF_DAYS = sum(post_dsch_end_dt - max(post_dsch_beg_dt,admsn_dt),1);
					else if admsn_dt = dschrgdt then IRF_DAYS = 1;
					else IRF_DAYS = dschrgdt - max(post_dsch_beg_dt,admsn_dt);
			end;
			else if type in ('IP_LTAC') then do;
					LTAC_UTIL = 1;
					if post_dsch_end_dt < dschrgdt then LTAC_DAYS = sum(post_dsch_end_dt - max(post_dsch_beg_dt,admsn_dt),1);
					else if admsn_dt = dschrgdt then LTAC_DAYS = 1;
					else LTAC_DAYS = dschrgdt - max(post_dsch_beg_dt,admsn_dt);
			end;
			else if type in ('SNF') then do;
					SNF_UTIL = 1;
					SNF_DAYS =min(post_dsch_end_dt,dschrgdt)-max(post_dsch_beg_dt,admsn_dt)+1; 
/*					if post_dsch_end_dt < dschrgdt then SNF_DAYS = sum(post_dsch_end_dt - max(post_dsch_beg_dt,admsn_dt),1);*/
/*					else if admsn_dt = dschrgdt then SNF_DAYS = 1;*/
/*					else SNF_DAYS = dschrgdt - max(post_dsch_beg_dt,admsn_dt) ;*/
			end;
			else if type in ('HH') then do;
					HH_UTIL = 1;
			end;
run;

proc sql;
	create table perf_UTIL as
		select epi_id_milliman, anchor_code,timeframe, BPID
			,case when sum(IP_UTIL) > 0 then 1 else 0 end as IP_UTIL
			,case when sum(IRF_UTIL) > 0 then 1 else 0 end as IRF_UTIL
			,case when sum(LTAC_UTIL) > 0 then 1 else 0 end as LTAC_UTIL
			,case when sum(SNF_UTIL) > 0 then 1 else 0 end as SNF_UTIL
			,case when sum(HH_UTIL) > 0 then 1 else 0 end as HH_UTIL

			,sum(IP_DAYS) as IP_DAYS
			,sum(IRF_DAYS) as IRF_DAYS
			,sum(LTAC_DAYS) as LTAC_DAYS
			,sum(SNF_DAYS) as SNF_DAYS



		from perf1
		where timeframe ^=0
		group by epi_id_milliman, anchor_code,timeframe, BPID
		;
quit;

proc sql;
	create table perf_UTIL2 as
		select epi_id_milliman, anchor_code, BPID
			,case when sum(IP_UTIL) > 0 then 1 else 0 end as IP_UTIL
			,case when sum(IRF_UTIL) > 0 then 1 else 0 end as IRF_UTIL
			,case when sum(LTAC_UTIL) > 0 then 1 else 0 end as LTAC_UTIL
			,case when sum(SNF_UTIL) > 0 then 1 else 0 end as SNF_UTIL
			,case when sum(HH_UTIL) > 0 then 1 else 0 end as HH_UTIL

			,sum(IP_DAYS) as IP_DAYS
			,sum(IRF_DAYS) as IRF_DAYS
			,sum(LTAC_DAYS) as LTAC_DAYS
			,sum(SNF_DAYS) as SNF_DAYS



		from perf1
		where timeframe ^=0
		group by epi_id_milliman, anchor_code, BPID
		;
quit;

proc sql;
	create table perf_UTIL3 as
		select epi_id_milliman, anchor_code, BPID
			,case when sum(IP_UTIL) > 0 then 1 else 0 end as IP_UTIL
			,case when sum(IRF_UTIL) > 0 then 1 else 0 end as IRF_UTIL
			,case when sum(LTAC_UTIL) > 0 then 1 else 0 end as LTAC_UTIL
			,case when sum(SNF_UTIL) > 0 then 1 else 0 end as SNF_UTIL
			,case when sum(HH_UTIL) > 0 then 1 else 0 end as HH_UTIL

			,sum(IP_DAYS) as IP_DAYS
			,sum(IRF_DAYS) as IRF_DAYS
			,sum(LTAC_DAYS) as LTAC_DAYS
			,sum(SNF_DAYS) as SNF_DAYS



		from perf1
		where timeframe in (1,2)
		group by epi_id_milliman, anchor_code, BPID
		;
quit;

data perf_util4;
	set perf_util (in=a)
		perf_util2 (in=b)
		perf_util3 (in=c);

		if b then timeframe = 4;
		else if c then timeframe = 5;

run;

proc sql;
	create table perf_util5 as
		select a.*
			,case when IP_UTIL = . then 0 else IP_UTIL end as IP_UTIL
			,case when IRF_UTIL = . then 0 else IRF_UTIL end as IRF_UTIL 
			,case when LTAC_UTIL = . then 0 else LTAC_UTIL end as LTAC_UTIL 
			,case when SNF_UTIL = . then 0 else SNF_UTIL end as SNF_UTIL 
			,case when HH_UTIL = . then 0 else HH_UTIL end as HH_UTIL 
			,case when IP_DAYS = . then 0 else IP_DAYS end as IP_DAYS 
			,case when IRF_DAYS = . then 0 else IRF_DAYS end as IRF_DAYS
			,case when LTAC_DAYS = . then 0 else LTAC_DAYS end as LTAC_DAYS  
			,case when SNF_DAYS = . then 0 else SNF_DAYS end as SNF_DAYS 
			,case when a.timeframe = 1 then '1 - 30 Days'
			when a.timeframe = 2 then '31 - 60 Days'
			when a.timeframe = 3 then '61 - 90 Days'
			when a.timeframe = 4 then '1 - 90 Days'
			when a.timeframe = 5 then '1 - 60 Days'
				end as timeframe2
			,case when a.timeframe = 1 then '0_30'
			when a.timeframe = 2 then '31_60'
			when a.timeframe = 3 then '61_90'
			when a.timeframe = 4 then '0_90'
			when a.timeframe = 5 then '0_60'
				end as timeframe_id
		from perf0a as a
		left join perf_util4 as b
		on a.epi_id_milliman = b.epi_id_milliman
		and a.timeframe = b.timeframe
		;
quit; 

proc sql;
	create table perf_util7  as 
		select a.*
		from perf_util5 as a
		;

	create table perf_util8  as 
		select a.*
			,b.encounterid
			,b.client_type
		from perf_util7 as a
		,out.epi_detail_&label._&bpid1._&bpid2. as b
		where a.epi_id_milliman= b.epi_id_milliman
		;
quit ;

*set up benchmark file;
data benchmarks;
	set bench.benchmarks_bpcia_17;
	where fracture = "N/A";
run;

proc sql ;
	create table perf_util9  as 
		select a.*
			  ,b.*
		from perf_util8 as a 
		left join benchmarks as b
		on a.Anchor_code = b.drg
		and timeframe_id = b._id 
		order by epi_id_milliman, timeframe
		;
	quit ; 

/*SD ADDITION START 20190304 - Mortality rates DURING episode*/
proc sql;
	create table epi_DOD as
	select	distinct
			epi_id_milliman
		,	bene_death_dt
		,	case when bene_death_dt=. then 0 
			  	 when bene_death_dt <= (ANCHOR_END_DT + 29) then 1
				 else 0
			end as DOD_1
		,	case when bene_death_dt=. then 0 
			  	 when (ANCHOR_END_DT + 30) <= bene_death_dt <= (ANCHOR_END_DT + 59) then 1
				 else 0
			end as DOD_2
		,	case when bene_death_dt=. then 0 
			  	 when (ANCHOR_END_DT + 60) <= bene_death_dt <= (ANCHOR_END_DT + 89) then 1
				 else 0
			end as DOD_3
		,	case when bene_death_dt=. then 0 
			  	 when bene_death_dt <= (ANCHOR_END_DT + 89) then 1
				 else 0
			end as DOD_4
		,	case when bene_death_dt=. then 0 
			  	 when bene_death_dt <= (ANCHOR_END_DT + 59) then 1
				 else 0
			end as DOD_5
	from	out.epi_detail_&label._&bpid1._&bpid2.
;
quit;

proc sql;
	create table out.perf_&label._&bpid1._&bpid2. as 
		select	distinct
				a.*
			,	case when a.timeframe=1 then b.DOD_1
					 when a.timeframe=2 then b.DOD_2
					 when a.timeframe=3 then b.DOD_3
					 when a.timeframe=4 then b.DOD_4
					 when a.timeframe=5 then b.DOD_5
				else 0
				end as DOD_N
		from	perf_util9 as a
				left join
				epi_DOD as b
				on	a.epi_id_milliman = b.epi_id_milliman
		;
quit;
/*SD ADDITION END 20190304 - Mortality rates DURING episode*/

*20190501 JL Update - calculate baseline benchmarks during baseline run only (join later);
%if &label = ybase %then %do;
proc sql;
	create table baseline_util  as 
		select distinct 	
 				BPID
				,anchor_code
				,timeframe
				,timeframe2
				,timeframe_id
				,count(*) as epi_total
				,sum(IP_UTIL) as base_fip_n
				,sum(IRF_UTIL) as base_irf_n
				,sum(SNF_UTIL) as base_snf_n
				,sum(HH_UTIL) as base_hh_n
				,sum(IP_DAYS) as base_ip_days
				,sum(IRF_DAYS) as base_irf_days
				,sum(SNF_DAYS) as base_snf_days
				,sum(DOD_N) as base_dod_n
		from out.perf_&label._&bpid1._&bpid2. as a
		group by BPID
				,anchor_code
				,timeframe
				,timeframe2
				,timeframe_id
;
quit;

proc sql;
	create table out.baseline_benchmark_&bpid1._&bpid2.  as 
		select distinct 	
				*
				,base_fip_n/epi_total as base_fip_freq
				,base_irf_n/epi_total as base_irf_freq
				,base_snf_n/epi_total as base_snf_freq
				,base_hh_n/epi_total as base_hh_freq
				,base_dod_n/epi_total as base_dod_freq
				,base_ip_days/base_fip_n as base_fip_avg_days
				,base_irf_days/base_irf_n as base_irf_avg_days
				,base_snf_days/base_snf_n as base_snf_avg_days
		from baseline_util as a
		order by BPID
				,anchor_code
				,timeframe
				,timeframe2
				,timeframe_id
;
quit;
%end;
*20190501 JL update end;

Proc sql ; 
	create table episode_detail_10 as
		select a.*
			,b.IP_UTIL	
			,b.IRF_UTIL	
			,b.LTAC_UTIL	
			,b.SNF_UTIL	
			,b.HH_UTIL	
			,b.IP_DAYS	
			,b.IRF_DAYS	
			,b.LTAC_DAYS	
			,b.SNF_DAYS
			,b.wm_fip_freq as wm_fip_freq_1_90
			,b.wm_irf_freq as wm_irf_freq_1_90
			,b.wm_snf_freq as wm_snf_freq_1_90
			,b.wm_snf_avg_days as wm_snf_avg_days_1_90
			,b.wm_hha_freq as wm_hha_freq_1_90
			,b.lm_fip_freq as lm_fip_freq_1_90
			,b.lm_irf_freq as lm_irf_freq_1_90
			,b.lm_snf_freq as lm_snf_freq_1_90
			,b.lm_snf_avg_days as lm_snf_avg_days_1_90
			,b.lm_hha_freq as lm_hha_freq_1_90
			,b.DOD_N
	/*JL Update - 20170829*/
			,	sum((case when a.T1_IP_A_FAC_DAYS = . then 0 else a.T1_IP_A_FAC_DAYS end)
				   ,(case when a.T1_IP_O_FAC_DAYS = . then 0 else a.T1_IP_O_FAC_DAYS end)
				   ) as IP_Days1
			,	sum((case when a.T2_IP_A_FAC_DAYS = . then 0 else a.T2_IP_A_FAC_DAYS end)
				   ,(case when a.T2_IP_O_FAC_DAYS = . then 0 else a.T2_IP_O_FAC_DAYS end)
				   ) as IP_Days2
			,	sum((case when a.T12_IP_A_FAC_DAYS = . then 0 else a.T12_IP_A_FAC_DAYS end)
				   ,(case when a.T12_IP_O_FAC_DAYS = . then 0 else a.T12_IP_O_FAC_DAYS end)
				   ) as IP_Days12
			,	sum((case when a.T3_IP_A_FAC_DAYS = . then 0 else a.T3_IP_A_FAC_DAYS end)
				   ,(case when a.T3_IP_O_FAC_DAYS = . then 0 else a.T3_IP_O_FAC_DAYS end)
				   ) as IP_Days3
 		from 
			out.epi_detail_&label._&bpid1._&bpid2. as a
			left join out.perf_&label._&bpid1._&bpid2. as b
			on a.epi_id_milliman = b.epi_id_milliman 
			and timeframe = 4
			;

*20170707 JL: Add flag for presence of OP provider claim that matches OP provider listed on anchor claim;
	create table op_prov as
		select distinct a.epi_id_milliman
			,a.operating_npi
			,b.provider_npi
		from episode_detail_10 as a
		left join out.provider_&label._&bpid1._&bpid2. as b
		on a.epi_id_milliman = b.epi_id_milliman and a.operating_npi = b.provider_npi
		where b.physician_role in ('Operating MD','Attending & Operating MD')
		;

*20180524 JL: Add flag for presence of AT provider claim that matches AT provider listed on anchor claim;
	create table at_prov as
		select distinct a.epi_id_milliman
			,a.attending_npi
			,b.provider_npi
		from episode_detail_10 as a
		left join out.provider_&label._&bpid1._&bpid2. as b
		on a.epi_id_milliman = b.epi_id_milliman and a.attending_npi = b.provider_npi
		where b.physician_role in ('Attending MD','Attending & Operating MD')
		;

*20170606 JL: Add final complications flag to episode detail table ;

	create table episode_detail_11 as
		select distinct a.*
			,b.cc_denom
			,c.cc_flag
			,case when c.cc_flag eq . then 0 else max(c.cc_flag) end as cc_numer
			,case when c.cc_flag_anchor eq . then 0 else max(c.cc_flag_anchor) end as cc_numer_anchor
			,case when c.cc_flag_1_30 eq . then 0 else max(c.cc_flag_1_30) end as cc_numer_1_30
			,case when c.cc_flag_1_60 eq . then 0 else max(c.cc_flag_1_60) end as cc_numer_1_60
			,case when c.cc_flag_1_90 eq . then 0 else max(c.cc_flag_1_90) end as cc_numer_1_90
			,case when c.cc_flag = 1 then "Yes"
			when b.cc_denom = 1 then "No"
			else "N/A" end as complication_status 
			,case when a.operating_npi in ("",".") then "N/A"	
					when d.provider_npi ne '' then 'Yes' else 'No' end as op_prov_flag
			,case when a.attending_npi in ("",".") then "N/A"
					when e.provider_npi ne '' then 'Yes' else 'No' end as at_prov_flag
		from episode_detail_10 as a
		left join out.Cc_sum_&label._&bpid1._&bpid2. as b
		on a.epi_id_milliman = b.epi_id_milliman
		left join out.comp_&label._&bpid1._&bpid2. as c
		on a.epi_id_milliman = c.epi_id_milliman
		left join op_prov as d
		on a.epi_id_milliman = d.epi_id_milliman
		left join at_prov as e
		on a.epi_id_milliman = e.epi_id_milliman
		group by a.epi_id_milliman
;

*SD: Add performance period episode flag to table ;
create table episode_detail_12 as
		select distinct a.*
			,b.perf_period_epi_flag
		from episode_detail_11 as a
			left join bpcia_performance_episodes as b
			on	a.BPID = b.BPID
				and
				a.Clinical_Episode = b.EPISODE_GROUP_NAME_USE
				and
				a.ANCHOR_TYPE=b.ANCHOR_TYPE

;

*20181113 SD: Sum final excess days to episode level ;
	create table all_cause_days as
			select distinct epi_id_milliman
			,edac_flag
			,excess_ip_readmit_days
			,excess_op_ed_days
			,sum(excess_op_obs_days,excess_pb_obs_days) as excess_obs_days
			,total_excess_days
	from out.ipr_&label._&bpid1._&bpid2.
	where type in ('IP_Idx')
;
*20181113 SD: Add final excess days and complications flags to episode detail table ;

	create table episode_detail_13 as
		select distinct a.*
			,b.edac_flag
			,b.excess_ip_readmit_days
			,b.excess_op_ed_days
			,b.excess_obs_days
			,b.total_excess_days
		%if &mode. = main %then %do;
			,case when perf_period_epi_flag=. then '-'
			when clinical_episode_abbr2 not in('AMI') then '-'
			when b.total_excess_days >0 then "Yes"
			when b.total_excess_days =0 then "No" else "N/A"
			end as excess_days_status2
			,case when perf_period_epi_flag=. then'-'
			when clinical_episode_abbr2 not in('MJRLE','DJRLE') then '-'
				else complication_status end as complication_status2
			,case when perf_period_epi_flag=. then '-'
				else mortality_CABG end as mortality_CABG2
		%end;
		%else %if &mode.=base %then %do;
			,case when clinical_episode_abbr2 not in('AMI') then '-'
			when b.total_excess_days >0 then "Yes"
			when b.total_excess_days =0 then "No" else "N/A"
			end as excess_days_status2
			,case when clinical_episode_abbr2 not in('MJRLE','DJRLE') then '-'
				else complication_status end as complication_status2
			,mortality_CABG as mortality_CABG2
		%end;
		from episode_detail_12 as a
			left join all_cause_days as b
			on a.epi_id_milliman = b.epi_id_milliman
;

*20181113 SD: Add final unplanned readmission flag to episode detail table ;
	create table epi_level_readm_flag as
		select EPI_ID_MILLIMAN
			 , sum(HAS_READMISSION) as unplanned_readmit_flag
		from out.ipr_&label._&bpid1._&bpid2.
		where HAS_READMISSION ^=9
		group by EPI_ID_MILLIMAN;
;

		create table episode_detail_14 as
		select distinct a.*
		%if &mode.=main %then %do;
			,case when perf_period_epi_flag=. then "-"
				when b.unplanned_readmit_flag>0 then "Yes"
				when b.unplanned_readmit_flag=0 then "No"
				else "N/A" end as unplanned_readmit_status
		%end;
		%else %if &mode.=base %then %do;
			,case when b.unplanned_readmit_flag>0 then "Yes"
				when b.unplanned_readmit_flag=0 then "No"
				else "N/A" end as unplanned_readmit_status
		%end;
		from episode_detail_13 as a
			left join epi_level_readm_flag as b
			on a.epi_id_milliman = b.epi_id_milliman

;

*Use performance period flag on epi_detail file to limit readmissions on patient detail file*;
proc sql;
	create table out.pat_detail_&label._&bpid1._&bpid2. as
		select distinct a.*
						,b.perf_period_epi_flag
						%if &mode.=main %then %do;
						,case when b.perf_period_epi_flag=. then 0
							else a.readm_cand end as readm_cand2
						,case when b.perf_period_epi_flag^=. and a.readm_cand=1 and b.unplanned_readmit_status='Yes' and
							((caretype_long='Anchor Hospital Stay' and msdrg^='') or caretype_long='Readmit') then 1
							else 0 end as elig_readm_cand_with_unplanned
						,case when b.perf_period_epi_flag^=. and a.edac_flag='Yes' and excess_days_status2='Yes' then 1
							else 0 end as elig_edac_cand_with_edac
						%end;
						%else %if &mode.=base %then %do;
						,a.readm_cand as readm_cand2
						,case when a.readm_cand=1 and b.unplanned_readmit_status='Yes' and
							((caretype_long='Anchor Hospital Stay' and msdrg^='') or caretype_long='Readmit') then 1
							else 0 end as elig_readm_cand_with_unplanned
						,case when a.edac_flag='Yes' and excess_days_status2='Yes' then 1
							else 0 end as elig_edac_cand_with_edac
						%end;
		from out.pat_detail_&label._&bpid1._&bpid2. as a
		left join episode_detail_14 as b
		on a.epi_id_milliman = b.epi_id_milliman
;
quit;

***** EPISODE INDEX CREATION *****;
proc sort data = episode_detail_14 out = episode_detail_14a; by epi_id_milliman anchor_beg_dt anchor_end_dt;run;

******* NEW EPISODE INDEX CREATION - RUN ONCE FOR FIRST TIME RUN ONLY ************************************;
%macro epi_idx_first;

data episode_detail_15 (rename = (counter2=episode_index));
	set episode_detail_14a;
	format counter2 $20.; length counter2 $20;
	counter + 1;
	%if &label = ybase %then %do;
	counter2 = strip(counter||"-B");
	%end;
	%else %do;
	counter2 = strip(counter||"-P");
	%end;
run;

data out.epi_idx_&label._&bpid1._&bpid2.;
	set episode_detail_15 (keep=bpid epi_id_milliman MBI_ID counter episode_index anchor_beg_dt anchor_end_dt);
	format recent_label $10.; length recent_label $10;
	recent_label = "&label.";
run;

%mend epi_idx_first;

******* EPISODE INDEX CREATION - RUN FOR EACH UPDATE ************************************;
%macro epi_idx_update;
* Use epi_idx from previous months - sort by dates, with missing indexes at the bottom;
proc sql;
	create table episode1a as
	select distinct
			a.*
		,	b.counter
		,	b.episode_index
	from out.epi_detail_&label._&bpid1._&bpid2. as a
	left join out.epi_idx_&prevlabel._&bpid1._&bpid2. as b
	on a.epi_id_milliman = b.epi_id_milliman
	order by counter desc, epi_id_milliman, anchor_beg_dt, anchor_end_dt
	;
quit;

* Take the highest counter value;
%let max_epi_idx = 0;

proc sql;
	select distinct max(counter) into: max_epi_idx 
	from out.epi_idx_&prevlabel._&bpid1._&bpid2.
;
quit;

* Add new episode indexes for new episodes starting with the highest number;
data episode (drop=max_epi_idx);
	set episode1a;
	format max_epi_idx 8.;
	retain max_epi_idx;

	if _N_=1 then max_epi_idx=%eval(&max_epi_idx.);

	max_epi_idx=max(max_epi_idx,counter);
	if counter=. then do;
		counter=sum(max_epi_idx,1);
		max_epi_idx=counter;
	end;
run;

*Add newest episodes to existing list - recent_label indicates the most recent time period that the episode was in the data;
data epi_list (keep= bpid epi_id_milliman counter episode_index recent_label anchor_beg_dt anchor_end_dt MBI_ID);
	set episode;
	format recent_label $10.; length recent_label $10;
	recent_label = "&label.";
	if episode_index = "" then do;
		%if &label = ybase %then %do;
		episode_index = strip(counter||"-B");
		%end;
		%else %do;
		episode_index = strip(counter||"-P");
		%end;
	end;
run;

data epi_list2;
	set 
	out.epi_idx_&prevlabel._&bpid1._&bpid2.
	epi_list;
run;

* Output the comprehensive list of episode indexes for all episodes that have entered the program;
proc sort data = epi_list2; by epi_id_milliman descending recent_label; run;
proc sort data = epi_list2 nodupkey out=out.epi_idx_&label._&bpid1._&bpid2.; by epi_id_milliman; run;

* Join the episode index to the episode file;
proc sql;
	create table episode_detail_15 as
	select a.*
		,b.counter
		,b.episode_index
	from episode_detail_14a as a
	left join out.epi_idx_&label._&bpid1._&bpid2. as b
	on a.epi_id_milliman = b.epi_id_milliman
;
quit;

%mend epi_idx_update;

%if &epi_idx. = 1 %then %do;
	%epi_idx_first;
%end;
%else %do;
	%epi_idx_update;
%end;

/*********************************************************************************************/
/*********************************************************************************************/
*20190422 SD: Adding Emergency claims from Provider and Facility Reports to get ER Utilization for the Episode Detail Report;

* Isolating EPI_IDS within the provider table;
proc sql ;
create table er_prov as
	select distinct
	     epi_id_milliman
		,'Yes' as Er_start_flag
	from out.provider_&label._&bpid1._&bpid2. a
	where substr(type,1,7)= 'Prof_ER'  and service_date ^= . 
;

*Isolating EPI_IDS within the Facility table;
create table er_ccn as
	select distinct
	     epi_id_milliman
		,'Yes' as Er_start_flag
	from out.ccn_enc_&label._&bpid1._&bpid2. as a
	where substr(caretype,1,2)= 'Em' and startdate ^= . 
;
quit;

*Stacking and deduping Epi_ids;
data Er_prov_ccn ;
set er_prov er_ccn ; 
run ;

proc sort data = Er_prov_ccn nodupkey;
by epi_id_milliman ; 
run ; 

proc sql ;
	create table out.epi_detail_&label._&bpid1._&bpid2. as
	select distinct a.*
					, case when b.Er_start_flag ^= '' then 'Yes'
						else 'No'
						end as Er_Flag4
	from 	episode_detail_15 as a
				left join Er_prov_ccn as b
				on a.epi_id_milliman = b.epi_id_milliman
;

quit;



/*********************************************************************************************/
/*Code to create exclusions dataset********************************************/
/*********************************************************************************************/
%if &label ^= ybase %then %do;
/*create descriptive columns*/;
proc sql;
create table exclusions1 as
	select 
		a.BPID
		,"&reporting_period." as DataYearMo
		,put(year(a.anchor_beg_dt),4.)||" Q"||put(qtr(a.anchor_beg_dt),1.) as Anchor_YearQtr
		,case when month(a.anchor_beg_dt) < 10 then strip(put(year(a.anchor_beg_dt),4.)||" M0"||strip(put(month(a.anchor_beg_dt),2.)))
		 else strip(put(year(a.anchor_beg_dt),4.)||" M"||strip(put(month(a.anchor_beg_dt),2.))) 
		 end as Anchor_YearMo
		,year(a.anchor_beg_dt) as Anchor_Year	
		,a.anchor_ccn
		,case when a.anchor_ccn ^= . and d.fac_name = "" then "Unknown ("||strip(put(a.anchor_ccn,z6.))||")"
			else strip(propcase(d.fac_name))||" ("||strip(put(a.anchor_ccn,z6.))||")"
			end as Anchor_Fac_Code_Name
		,a.epi_id_milliman
		,a.bene_sk
		,a.bene_age
		,a.bene_gender length=10
		,a.bene_birth_dt
		,a.bene_death_dt
		,a.MBI_ID length=20
		,case when a.flag_overlap = 1 then "Yes" else "No" end as flag_overlap length=10
		,case when a.mult_attr_provs = 1 then "Yes" else "No" end as mult_attr_provs length=10
		,a.anchor_type
		,a.anchor_code
		,c.Clinical_Episode
		,c.Short_name as clinical_episode_abbr
		,c.Short_name_2 as clinical_episode_abbr2
		,a.anchor_beg_dt
		,a.anchor_end_dt
		,"PERF" as period
		,case when '01OCT2018'd le POST_DSCH_END_DT le '30JUN2019'd then "Performance Period 1"
			  when '01JUL2019'd le POST_DSCH_END_DT le '31DEC2019'd then "Performance Period 2"
			  when '01JAN2020'd le POST_DSCH_END_DT le '30JUN2020'd then "Performance Period 3"
			  when '01JUL2020'd le POST_DSCH_END_DT le '31DEC2020'd then "Performance Period 4"
			  when '01JAN2021'd le POST_DSCH_END_DT le '30JUN2021'd then "Performance Period 5"
			  when '01JUL2021'd le POST_DSCH_END_DT le '31DEC2021'd then "Performance Period 6"
			  when '01JAN2022'd le POST_DSCH_END_DT le '30JUN2022'd then "Performance Period 7"
			  when '01JUL2022'd le POST_DSCH_END_DT le '31DEC2022'd then "Performance Period 8"
			  when '01JAN2023'd le POST_DSCH_END_DT le '30JUN2023'd then "Performance Period 9"
			  when '01JUL2023'd le POST_DSCH_END_DT le '31DEC2023'd then "Performance Period 10"
		 end as timeframe_filter format = $100. length=100
/*		,a.DROPFLAG_NON_ACH*/
/*		,a.DROPFLAG_EXCLUDED_STATE*/
/*		,a.DROPFLAG_NOT_CONT_ENR_AB_NO_C*/
/*		,a.DROPFLAG_ESRD*/
/*		,a.DROPFLAG_OTHER_PRIMARY_PAYER*/
/*		,a.DROPFLAG_NO_BENE_ENR_INFO*/
/*		,a.DROPFLAG_LOS_GT_59*/
/*		,a.DROPFLAG_NON_HIGHEST_J1*/
/*		,a.DROPFLAG_DEATH_DUR_ANCHOR*/
/*		,a.DROPFLAG_TRANS_W_CAH_CANCER*/
/*		,a.DROPFLAG_RCH_DEMO*/
/*		,a.DROPFLAG_RURAL_PA*/
/*		,a.DROPFLAG_CJR*/
/*		,0 as DROPFLAG_READMIT_NEW_EP_MIL*/
/*		,0 as DROPFLAG_READMIT_ANCHOR_DRG_MIL*/
/*		,case when max(a.DROPFLAG_CJR,a.DROPFLAG_NOT_CONT_ENR_AB_NO_C,a.DROPFLAG_ESRD,a.DROPFLAG_OTHER_PRIMARY_PAYER,a.DROPFLAG_DEATH_DUR_ANCHOR)=0*/
/*			and max(a.DROPFLAG_NON_ACH,a.DROPFLAG_EXCLUDED_STATE,a.DROPFLAG_TRANS_W_CAH_CANCER,a.DROPFLAG_RCH_DEMO*/
/*			,a.DROPFLAG_RURAL_PA,a.DROPFLAG_LOS_GT_59,a.DROPFLAG_NON_HIGHEST_J1,a.DROPFLAG_NO_BENE_ENR_INFO)=1*/
/*			then 1 else 0 end as DROPFLAG_OTHER*/
		,case
			when a.DROPFLAG_CJR = 1 then 1 /*facility level exclusion*/
			when a.DROPFLAG_ACO_MSSP_OVERLAP = 1 then 2 /*facility level exclusion*/
			when a.DROPFLAG_ACO_CEC_OVERLAP = 1 then 3 /*facility level exclusion*/
			when a.DROPFLAG_ACO_NEXTGEN_OVERLAP = 1 then 4 /*facility level exclusion*/
			when a.DROPFLAG_ACO_VERMONTAP_OVERLAP = 1 then 5 /*facility level exclusion*/
			when a.DROPFLAG_NOT_CONT_ENR_AB_NO_C = 1 then 6 /*episode level exclusions*/
			when a.DROPFLAG_ESRD = 1 then 7 /*episode level exclusions*/
			when a.DROPFLAG_OTHER_PRIMARY_PAYER = 1 then 8 /*episode level exclusions*/
			when a.DROPFLAG_DEATH_DUR_ANCHOR = 1 then 9 /*episode level exclusions*/
			when a.DROPFLAG_NON_ACH = 1 then 10 /*facility level exclusion*/
			when a.DROPFLAG_EXCLUDED_STATE = 1 then 11 /*facility level exclusion*/
			when a.DROPFLAG_TRANS_W_CAH_CANCER = 1 then 12 /*facility level exclusion*/
			when a.DROPFLAG_RCH_DEMO = 1 then 13 /*facility level exclusion*/
			when a.DROPFLAG_RURAL_PA = 1 then 14 /*facility level exclusion*/
			when a.DROPFLAG_LOS_GT_59 = 1 then 15 /*episode level exclusions*/
			when a.DROPFLAG_NON_HIGHEST_J1 = 1 then 16 /*episode level exclusions*/
			when a.DROPFLAG_NO_BENE_ENR_INFO = 1 then 17 /*data exclusion*/
			when a.DROPFLAG_READMIT_EPI = 1 then 18 /*Milliman exclusion*/
			when a.DROPFLAG_MJRLE_EPI = 1 then 19 /*Milliman exclusion*/
			when a.DROPFLAG_NOT_PERF_EP_MIL = 1 then 20 /*Milliman exclusion*/
			when a.DROPFLAG_TRANS_EPI = 1 then 21 /*Milliman exclusion*/
            end as dropreason
		,case
			when a.DROPFLAG_CJR = 1 then "CJR hospital with MJRLE MS-DRG" /*facility level exclusion*/
			when a.DROPFLAG_ACO_MSSP_OVERLAP = 1 then "Beneficiary aligned with Medicare Shared Savings Program Track 3 (ACO)" /*facility level exclusion*/
			when a.DROPFLAG_ACO_CEC_OVERLAP = 1 then "Beneficiary aligned with Comprehensive ESRD Care (ACO)" /*facility level exclusion*/
			when a.DROPFLAG_ACO_NEXTGEN_OVERLAP = 1 then "Beneficiary aligned with Next Generation (ACO)" /*facility level exclusion*/
			when a.DROPFLAG_ACO_VERMONTAP_OVERLAP = 1 then "Beneficiary aligned with Vermont All Payer (ACO)" /*facility level exclusion*/
			when a.DROPFLAG_NOT_CONT_ENR_AB_NO_C = 1 then "No Part A/B or in Part C" /*episode level exclusions*/
			when a.DROPFLAG_ESRD = 1 then "ESRD" /*episode level exclusions*/
			when a.DROPFLAG_OTHER_PRIMARY_PAYER = 1 then "Medicare not primary payer" /*episode level exclusions*/
			when a.DROPFLAG_DEATH_DUR_ANCHOR = 1 then "Death during anchor" /*episode level exclusions*/
			when a.DROPFLAG_NON_ACH = 1 then "Triggered by non-ACH" /*facility level exclusion*/
			when a.DROPFLAG_EXCLUDED_STATE = 1 then "State not eligible for BPCIA" /*facility level exclusion*/
			when a.DROPFLAG_TRANS_W_CAH_CANCER = 1 then "Transfer to CAH or cancer hospital" /*facility level exclusion*/
			when a.DROPFLAG_RCH_DEMO = 1 then "Rural Community Hospital Demo" /*facility level exclusion*/
			when a.DROPFLAG_RURAL_PA = 1 then "PA Rural Health Model"/*facility level exclusion*/
			when a.DROPFLAG_LOS_GT_59 = 1 then "LOS greater than 59 days" /*episode level exclusions*/
			when a.DROPFLAG_NON_HIGHEST_J1 = 1 then "Triggering OP line not highest ranking J1" /*episode level exclusions*/
			when a.DROPFLAG_NO_BENE_ENR_INFO = 1 then "Missing beneficiary info" /*data exclusion*/
			when a.DROPFLAG_READMIT_EPI = 1 then "Admission inclu. in prev. episode" /*Milliman exclusion*/
			when a.DROPFLAG_MJRLE_EPI = 1 then "Readmit starts new episode" /*Milliman exclusion*/
			when a.DROPFLAG_NOT_PERF_EP_MIL = 1 then "Not a performance period clinical episode" /*Milliman exclusion*/
			when a.DROPFLAG_TRANS_EPI = 1 then "Transfer incorrectly assigned" /*Milliman exclusion*/
			end as exclusion_description length=100
		, case when a.DROPFLAG_READMIT_EPI=1 or a.DROPFLAG_MJRLE_EPI=1 or a.DROPFLAG_NOT_PERF_EP_MIL=1 or a.DROPFLAG_TRANS_EPI=1 then "MIL" else "CMS" end as source length=50
		, case when a.BENE_SRNM_NAME in ("","~") then "Unknown"
			else propcase(STRIP(a.BENE_SRNM_NAME)||", "||STRIP(a.BENE_GVN_NAME)) 
			end as PATIENT_NAME format = $255. length=255
	from out.epiexc_perf_&label._&bpid1._&bpid2.	as a
	left join bpciaref.BPCIA_DRG_Mapping as b
	on a.ANCHOR_CODE = b.code
	left join bpciaref.BPCIA_Clinical_Episode_Names as c
	on b.BPCI_Episode_Idx = c.BPCI_Episode_Index
	left join ref.ccns_codemap as d
	on put(a.anchor_ccn,z6.) = d.ccn;

;
quit;

data out.exclusions_&label._&bpid1._&bpid2. ;
	set exclusions1;
	*CMS exclusions;
	DROPFLAG_CJR = 0;
	DROPFLAG_ACO_MSSP_OVERLAP = 0;
	DROPFLAG_ACO_CEC_OVERLAP = 0;
	DROPFLAG_ACO_NEXTGEN_OVERLAP = 0;
	DROPFLAG_ACO_VERMONTAP_OVERLAP =0;
	DROPFLAG_NOT_CONT_ENR_AB_NO_C = 0;
	DROPFLAG_ESRD = 0;
	DROPFLAG_OTHER_PRIMARY_PAYER = 0;
	DROPFLAG_DEATH_DUR_ANCHOR = 0;
	DROPFLAG_NON_ACH = 0;
	DROPFLAG_EXCLUDED_STATE = 0;
	DROPFLAG_TRANS_W_CAH_CANCER = 0;
	DROPFLAG_RCH_DEMO = 0;
	DROPFLAG_RURAL_PA = 0;
	DROPFLAG_LOS_GT_59 = 0;
	DROPFLAG_NON_HIGHEST_J1 = 0;
	DROPFLAG_NO_BENE_ENR_INFO = 0;
	DROPFLAG_OTHER = 0; *flag for combined category;
	*Milliman- calculated exclusions;
	DROPFLAG_READMIT_ANCHOR_DRG_MIL = 0;
	DROPFLAG_READMIT_NEW_EP_MIL = 0;
	DROPFLAG_NOT_PERF_EP_MIL = 0;
	DROPFLAG_TRANS_EPI_MIL = 0;
	
	*Flags with hierarchy applied (only one flag = 1 for each episode);
	if dropreason = 1 then DROPFLAG_CJR = 1;
	else if dropreason = 2 then DROPFLAG_ACO_MSSP_OVERLAP = 1;
	else if dropreason = 3 then DROPFLAG_ACO_CEC_OVERLAP = 1;
	else if dropreason = 4 then DROPFLAG_ACO_NEXTGEN_OVERLAP = 1;
	else if dropreason = 5 then DROPFLAG_ACO_VERMONTAP_OVERLAP = 1;
	else if dropreason = 6 then DROPFLAG_NOT_CONT_ENR_AB_NO_C = 1;
	else if dropreason = 7 then DROPFLAG_ESRD = 1;
	else if dropreason = 8 then DROPFLAG_OTHER_PRIMARY_PAYER = 1;
	else if dropreason = 9 then DROPFLAG_DEATH_DUR_ANCHOR = 1;
	else if dropreason = 10 then DROPFLAG_NON_ACH = 1;
	else if dropreason = 11 then DROPFLAG_EXCLUDED_STATE = 1;
	else if dropreason = 12 then DROPFLAG_TRANS_W_CAH_CANCER = 1;
	else if dropreason = 13 then DROPFLAG_RCH_DEMO = 1;
	else if dropreason = 14 then DROPFLAG_RURAL_PA = 1;
	else if dropreason = 15 then DROPFLAG_LOS_GT_59 = 1;
	else if dropreason = 16 then DROPFLAG_NON_HIGHEST_J1 = 1;
	else if dropreason = 17 then DROPFLAG_NO_BENE_ENR_INFO = 1;
	else if dropreason = 18 then DROPFLAG_READMIT_ANCHOR_DRG_MIL = 1;
	else if dropreason = 19 then DROPFLAG_READMIT_NEW_EP_MIL = 1;
	else if dropreason = 20 then DROPFLAG_NOT_PERF_EP_MIL = 1;
	else if dropreason = 21 then DROPFLAG_TRANS_EPI_MIL = 1;

	DROPFLAG_ACO = max(DROPFLAG_ACO_MSSP_OVERLAP, DROPFLAG_ACO_CEC_OVERLAP, DROPFLAG_ACO_NEXTGEN_OVERLAP, DROPFLAG_ACO_VERMONTAP_OVERLAP);
	DROPFLAG_OTHER = max(DROPFLAG_NON_ACH,DROPFLAG_EXCLUDED_STATE,DROPFLAG_TRANS_W_CAH_CANCER,DROPFLAG_RCH_DEMO,
			DROPFLAG_RURAL_PA,DROPFLAG_LOS_GT_59,DROPFLAG_NON_HIGHEST_J1,DROPFLAG_NO_BENE_ENR_INFO,DROPFLAG_NOT_PERF_EP_MIL,DROPFLAG_TRANS_EPI_MIL);
run;

%end;
/*********************************************************************************************/
/*********************************************************************************************/

*** ADD BACK IN FOR PERFORMANCE DATA *****;
*Create time filter file - tff=timeframe filter;
/*data out.tff_detail_output_&bpid1._&bpid2. (keep= epi_id_Milliman anchor_beg_dt anchor_end_dt timeframe_filter BPID);*/
/*	set out.epi_detail_&label._&bpid1._&bpid2.;*/
/*	format timeframe_filter $100. BPID $20.; length timeframe_filter $100;*/
/*	BPID = BPID ; */
/*		timeframe_filter = "Baseline - Years 1 and 2 (2012 - 2014)"; */
/*	*/
/*run ; */

*delete work datasets;
proc datasets lib=work memtype=data kill;
run;
quit;

%mend dashboard;

*MACRO RUNS;


/*%Dashboard(1125,0000,0);*/
/*%Dashboard(1148,0000,0);*/
/*%Dashboard(1167,0000,0);*/
/*%Dashboard(1209,0000,0);*/
/*%Dashboard(1343,0000,0);*/
/*%Dashboard(1368,0000,0);*/
/*%Dashboard(1374,0004,0);*/
/*%Dashboard(1374,0008,0);*/
/*%Dashboard(1374,0009,0);*/
/*%Dashboard(1686,0002,0);*/
/*%Dashboard(1688,0002,0);*/
/*%Dashboard(1696,0002,0);*/
/*%Dashboard(1710,0002,0);*/
/*%Dashboard(1958,0000,0);*/
/*%Dashboard(2070,0000,0);*/
/*%Dashboard(2374,0000,0);*/
/*%Dashboard(2376,0000,0);*/
/*%Dashboard(2378,0000,0);*/
/*%Dashboard(2379,0000,0);*/
/*%Dashboard(1075,0000,0);*/
/*%Dashboard(2594,0000,0);*/
/*%Dashboard(2048,0000,0);*/
/*%Dashboard(2049,0000,0);*/
/*%Dashboard(2607,0000,0);*/
/*%Dashboard(5038,0000,0);*/
/*%Dashboard(5050,0000,0);*/
/*%Dashboard(2587,0000,0);*/
/*%Dashboard(2589,0000,0);*/
/*%Dashboard(5154,0000,0);*/
/*%Dashboard(5282,0000,0);*/
/*%Dashboard(2631,0000,0);*/
/*%Dashboard(5037,0000,0);*/
/*%Dashboard(5478,0002,0);*/
/*%Dashboard(5043,0000,0);*/
/*%Dashboard(5479,0002,0);*/
/*%Dashboard(5480,0002,0);*/
/*%Dashboard(5215,0003,0);*/
/*%Dashboard(5215,0002,0);*/
/*%Dashboard(5229,0000,0);*/
/*%Dashboard(5263,0000,0);*/
/*%Dashboard(5264,0000,0);*/
/*%Dashboard(5481,0002,0);*/
/*%Dashboard(5394,0000,0);*/
/*%Dashboard(5395,0000,0);*/
/*%Dashboard(5397,0002,0);*/
/*%Dashboard(5397,0005,0);*/
/*%Dashboard(5397,0004,0);*/
/*%Dashboard(5397,0008,0);*/
/*%Dashboard(5397,0003,0);*/
/*%Dashboard(5397,0006,0);*/
/*%Dashboard(5397,0009,0);*/
/*%Dashboard(5397,0010,0);*/
/*%Dashboard(5916,0002,0);*/
/*%Dashboard(6049,0002,0);*/
/*%Dashboard(6050,0002,0);*/
/*%Dashboard(6051,0002,0);*/
/*%Dashboard(6052,0002,0);*/
/*%Dashboard(6053,0002,0);*/
/*%Dashboard(5397,0007,0);*/
/*%Dashboard(1102,0000,0);*/
/*%Dashboard(1105,0000,0);*/
/*%Dashboard(1106,0000,0);*/
/*%Dashboard(1103,0000,0);*/
/*%Dashboard(1104,0000,0);*/
/*%Dashboard(5392,0004,0);*/
/*%Dashboard(6054,0002,0);*/
/*%Dashboard(6055,0002,0);*/
/*%Dashboard(6056,0002,0);*/
/*%Dashboard(6057,0002,0);*/
/*%Dashboard(6058,0002,0);*/
/*%Dashboard(6059,0002,0);*/
/*%Dashboard(5746,0002,0);*/
/*%Dashboard(1191,0002,0);*/



*CCF ONLY;
/*%Dashboard(2586,0002,0);*/
/*%Dashboard(2586,0003,0);*/
/*%Dashboard(2586,0004,0);*/
/*%Dashboard(2586,0005,0);*/
/*%Dashboard(2586,0006,0);*/
/*%Dashboard(2586,0007,0);*/
/*%Dashboard(2586,0009,0);*/
/*%Dashboard(2586,0010,0);*/
/*%Dashboard(2586,0011,0);*/
/*%Dashboard(2586,0012,0);*/
/*%Dashboard(2586,0013,0);*/
/*%Dashboard(2586,0014,0);*/
/*%Dashboard(2586,0015,0);*/
/*%Dashboard(2586,0016,0);*/
/*%Dashboard(2586,0017,0);*/
/*%Dashboard(2586,0020,0);*/
/*%Dashboard(2586,0021,0);*/
/*%Dashboard(2586,0023,0);*/



*DEMO/DEV ONLY;
%Dashboard(1148,0000,0);
%Dashboard(1167,0000,0);
%Dashboard(1343,0000,0);
%Dashboard(1368,0000,0);
%Dashboard(2379,0000,0);
%Dashboard(2587,0000,0);
%Dashboard(2607,0000,0);
%Dashboard(5479,0002,0);



******************************************************************************************************************;
;

%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;

proc printto;run;

%put It took &_runtm minutes to run the program;

* Email Report ;
filename myemail EMAIL
to="&to_email."
from = "&from_email."
subject="SAS run complete";

data _null_;
file myemail;
put "It took &_runtm. minutes to run the program";

run;
filename myemail clear;

