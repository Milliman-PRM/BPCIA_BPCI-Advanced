%let _sdtm=%sysfunc(datetime());
options mprint nospool;
****************************************
****************************************
Select episodes to output to interface 
****************************************
****************************************;

******************************************************************************
RUN THIS PROGRAM IN ITS OWN SAS SESSION TO PREVENT ANY DATA ROLLUP ISSUES
******************************************************************************

********************
Setup 
********************;
options minoperator mlogic;
******* RUN AFTER BASELINE AND PERFORMANCE ARE RUN *****************************************;

****** USER INPUTS ******************************************************************************************;
%let mode = main; *main = main interface, base = baseline interface;
%let label_monthly = y202003; 
%let label_quarterly = y202002; 
%include "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code\000 - BPCIA_Interface_BPIDs.sas";


proc printto;run;
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\301 - Qlikview Code_&label._&sysdate..log" print=print new;
run; 

****** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
libname out "&dataDir.\07 - Processed Data";
libname out2 "&dataDir.\07 - Processed Data\Output";

********************
********************
Calculation of Monthly Reports Datasets
********************
********************;

%macro selection(bpid1,bpid2,epi_idx);
%let id = &bpid1._&bpid2.;

%if &bpid1. = 1075 or &bpid1. = 2048 or &bpid1. = 2049 or &bpid1. = 2589 or &bpid1. = 5037 %then %do;
%let label = &label_quarterly.;
%end;

%else %do;
%let label = &label_monthly.; 
%end;
*************** PART 1: CREATE DEDUPED LIST OF FINAL EPISODES FOR INTERFACE **************************************;


data all_epi_pre_ybase;
       /* set out.epi_detail_ybase_5746_0002; */		
        set out.epi_detail_ybase_&id.;
		if MEASURE_YEAR = 'MY1 & MY2' THEN MY = 2;
		if MEASURE_YEAR = 'MY3' THEN MY = 1;
	run;

proc sort data=all_epi_pre_ybase ;
	by BPID BENE_SK clinical_episode anchor_beg_dt anchor_end_dt MY;
	run;

proc sort nodupkey data=all_epi_pre_ybase out=out.epi_ID_to_use_&id. (keep=BPID BENE_SK clinical_episode anchor_beg_dt anchor_end_dt MEASURE_YEAR EPI_ID_MILLIMAN);
	by BPID BENE_SK clinical_episode anchor_beg_dt anchor_end_dt;
	run;

proc sql;
create table out.timeframe_filter_&id. as
select distinct a.BPID, b.EPI_ID_MILLIMAN, a.EPI_ID_MILLIMAN as EPI_ID_MILLIMAN_original, a.timeframe_filter
from all_epi_pre_ybase as a
left join
out.epi_ID_to_use_&id. as b
on A.BENE_SK = B.BENE_SK
		AND A.clinical_episode = B.clinical_episode
		AND A.anchor_beg_dt = B.anchor_beg_dt
		AND A.anchor_end_dt = B.anchor_end_dt
;
quit;

	
%macro epi_picker(file);

proc sql;
create table all_epi_ybase as
select a.*
from  out.&file._ybase_&id. AS A
	inner join out.epi_ID_to_use_&id. AS B
		on A.EPI_ID_MILLIMAN = B.EPI_ID_MILLIMAN
		;
		quit;

data out.A_&file._ybase_&id.;
set all_epi_ybase;
run;

%mend epi_picker;
/**/
/*%macro epi_picker_V2(file);*/
/**/
/*proc sql;*/
/*create table out.A_&file._ybase_&id. AS */
/*select **/
/*from out.&file._ybase_&id. (obs=0);*/
/*quit;*/
/**/
/**/
/*%mend epi_picker_V2;*/
*All tables, excluding time period tables and tables that use performance data only;

%epi_picker(epi_detail);
%epi_picker(pjourney);
%epi_picker(pjourneyagg);
%epi_picker(prov_detail);
%epi_picker(util);
%epi_picker(perf);
%epi_picker(phys_summ);
%epi_picker(pat_detail);
%epi_picker(comp);
*%epi_picker_V2(bpid_member);

data tp_stack;
set out2.tp_ybase_&id.: ;
run;
 
proc sql;
create table all_epi_ybase as
select a.*
from  tp_stack AS A
	inner join out.epi_ID_to_use_&id. AS B
		on A.EPI_ID_MILLIMAN = B.EPI_ID_MILLIMAN
		;
		quit;

data out.A_tp_&id.;
set all_epi_ybase out2.tp_&label._&id.:;
run;
%mend selection;

**********************************************************************************************************;
* RUN FOR ALL FACILITIES, INCLUDING THOSE WITH NO PERFORMANCE EPISODES;

*%selection(5746,0002,0);


%Selection(2586,0002,1);
%Selection(2586,0005,1);
%Selection(2586,0006,1);
%Selection(2586,0007,1);
%Selection(2586,0010,1);
%Selection(2586,0013,1);
%Selection(2586,0025,1);
%Selection(2586,0026,1);
%Selection(2586,0028,1);
%Selection(2586,0029,1);
%Selection(2586,0030,1);
%Selection(2586,0031,1);
%Selection(2586,0032,1);
%Selection(2586,0033,1);
%Selection(2586,0034,1);
%Selection(2586,0035,1);
*%Selection(2586,0036,1);
*%Selection(2586,0038,1);
%Selection(2586,0039,1);
*%Selection(2586,0040,1);
*%Selection(2586,0041,1);
*%Selection(2586,0042,1);
*%Selection(2586,0043,1);
%Selection(2586,0044,1);
%Selection(2586,0045,1);
%Selection(2586,0046,1);
%Selection(1374,0004,0);
%Selection(1374,0008,0);
%Selection(1374,0009,0);
%Selection(1374,0012,1);
%Selection(1374,0013,1);
%Selection(1374,0014,1);
%Selection(1374,0015,1);
%Selection(1374,0017,1);
%Selection(1374,0018,1);
%Selection(1191,0002,0);
%Selection(7310,0002,1);
%Selection(7310,0003,1);
%Selection(7310,0004,1);
%Selection(7310,0005,1);
%Selection(7310,0006,1);
%Selection(7310,0007,1);
%Selection(7312,0002,1);
%Selection(6054,0002,0);
%Selection(6055,0002,0);
%Selection(6056,0002,0);
%Selection(6057,0002,0);
%Selection(6058,0002,0);
%Selection(6059,0002,0);
%Selection(1209,0000,0);
%Selection(1028,0000,1);
%Selection(1075,0000,0);
%Selection(1102,0000,0);
%Selection(1103,0000,0);
%Selection(1104,0000,0);
%Selection(1105,0000,0);
%Selection(1106,0000,0);
%Selection(1148,0000,0);
%Selection(1167,0000,0);
%Selection(1343,0000,0);
%Selection(1368,0000,0);
%Selection(1461,0000,1);
%Selection(1634,0000,0);
*%Selection(1803,0000,1);
%Selection(1958,0000,0);
%Selection(2048,0000,0);
%Selection(2049,0000,0);
%Selection(2070,0000,0);
%Selection(2214,0000,1);
%Selection(2215,0000,1);
%Selection(2216,0000,1);
%Selection(2302,0000,0);
%Selection(2317,0000,1);
%Selection(2374,0000,0);
%Selection(2376,0000,0);
%Selection(2378,0000,0);
%Selection(2379,0000,0);
%Selection(2451,0000,1);
%Selection(2452,0000,1);
%Selection(2461,0000,1);
%Selection(2468,0000,1);
%Selection(2587,0000,0);
%Selection(2589,0000,0);
%Selection(2594,0000,0);
%Selection(2607,0000,0);
%Selection(5037,0000,0);
%Selection(5038,0000,0);
%Selection(5043,0000,0);
%Selection(5050,0000,0);
%Selection(5154,0000,0);
%Selection(5215,0002,0);
%Selection(5215,0003,0);
%Selection(5229,0000,0);
%Selection(5263,0000,0);
%Selection(5264,0000,0);
%Selection(5282,0000,0);
%Selection(5392,0004,0);
%Selection(5394,0000,0);
%Selection(5395,0000,0);
%Selection(5397,0002,0);
%Selection(5397,0003,0);
%Selection(5397,0004,0);
%Selection(5397,0005,0);
%Selection(5397,0006,0);
%Selection(5397,0007,0);
%Selection(5397,0008,0);
%Selection(5397,0009,0);
%Selection(5397,0010,0);
%Selection(5478,0002,0);
%Selection(5479,0002,0);
%Selection(5480,0002,0);
%Selection(5481,0002,0);
%Selection(5746,0002,0);
%Selection(1686,0002,0);
%Selection(1688,0002,0);
%Selection(1696,0002,0);
%Selection(1710,0002,0);
%Selection(2941,0002,1);
%Selection(2956,0002,1);
%Selection(6049,0002,0);
%Selection(6050,0002,0);
%Selection(6051,0002,0);
%Selection(6052,0002,0);
%Selection(6053,0002,0);
%Selection(2974,0003,1);
%Selection(2974,0007,1);



data All_Target_Prices_1 All_Target_Prices_Premier All_Target_Prices_NonPremier All_Target_Prices_CCF All_Target_Prices_Dev;
	set out.A_tp_:;

	if BPID in (&PMR_EI_lst.) or BPID in (&NON_PMR_EI_lst.) then output All_Target_Prices_1;
	if BPID in (&DEV_EI_lst.) then output All_Target_Prices_Dev;
	if BPID in (&PMR_EI_lst.) then output All_Target_Prices_Premier;
	else if BPID in (&NON_PMR_EI_lst.) then output All_Target_Prices_NonPremier;
	else if BPID in (&CCF_lst.) then output All_Target_Prices_CCF;

run;

%MACRO EXPORT;
%if &mode.=main %then %do;
	/*
	proc export data= All_Target_Prices
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Target Prices.csv"
	            dbms=csv replace; 
	run;
	*/
	proc export data= All_Target_Prices_1
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Target Prices_1.csv"
	            dbms=csv replace; 
	run;
	proc export data= All_Target_Prices_Premier
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Target Prices_PMR.csv"
	            dbms=csv replace; 
	run;
	proc export data= All_Target_Prices_NonPremier
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Target Prices_oth.csv"
	            dbms=csv replace; 
	run;
	proc export data= All_Target_Prices_Dev
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Target Prices_Dev.csv"
	            dbms=csv replace; 
	run;

	proc export data= All_Target_Prices_CCF
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Target Prices_CCF.csv"
	            dbms=csv replace; 
	run;
%end;
%else %if &mode.=base %then %do;
	/*
	proc export data= All_Target_Prices
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Baseline Target Prices.csv"
	            dbms=csv replace; 
	run;
	*/
	proc export data= All_Target_Prices_1
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Baseline Target Prices_1.csv"
	            dbms=csv replace; 
	run;
	proc export data= All_Target_Prices_Premier
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Baseline Target Prices_PMR.csv"
	            dbms=csv replace; 
	run;
	proc export data= All_Target_Prices_NonPremier
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Baseline Target Prices_oth.csv"
	            dbms=csv replace; 
	run;
	proc export data= All_Target_Prices_Dev
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Target Prices_Dev.csv"
	            dbms=csv replace; 
	run;
	proc export data= All_Target_Prices_CCF
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Baseline Target Prices_CCF.csv"
	            dbms=csv replace; 
	run;
%end;
%else %if &mode.=recon %then %do;
	/*
	proc export data= All_Target_Prices
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Recon Target Prices.csv"
	            dbms=csv replace; 
	run;
	*/
	proc export data= All_Target_Prices_1
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Recon Target Prices_1.csv"
	            dbms=csv replace; 
	run;
	proc export data= All_Target_Prices_Premier
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Recon Target Prices_PMR.csv"
	            dbms=csv replace; 
	run;
	proc export data= All_Target_Prices_NonPremier
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Recon Target Prices_oth.csv"
	            dbms=csv replace; 
	run;
	proc export data= All_Target_Prices_Dev
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Target Prices_Dev.csv"
	            dbms=csv replace; 
	run;
	proc export data= All_Target_Prices_CCF
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Recon Target Prices_CCF.csv"
	            dbms=csv replace; 
	run;
%end;
%mend EXPORT;

%EXPORT;

proc printto;run;
%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;
