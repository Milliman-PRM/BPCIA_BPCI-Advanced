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
%let label = y202002; 
%include "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code\000 - BPCIA_Interface_BPIDs.sas";


proc printto;run;
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\301 - Qlikview Code_&label._&sysdate..log" print=print new;
run; 

****** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
libname out "&dataDir.\07 - Processed Data";


********************
********************
Calculation of Monthly Reports Datasets
********************
********************;

%macro selection(bpid1,bpid2,epi_idx);
%let id = &bpid1._&bpid2.;

*************** PART 1: CREATE DEDUPED LIST OF FINAL EPISODES FOR INTERFACE **************************************;


data all_epi_pre_ybase;
        set out.epi_detail_ybase_&id.;
	run;

	proc sql;
	create table epi_combos as
	select distinct BENE_SK, clinical_episode, anchor_beg_dt, anchor_end_dt, 
max(Case when MEASURE_YEAR = 'MY1 & MY2' THEN EPI_ID_MILLIMAN ELSE '' END) AS EPI_ID_MILLIMAN_MY12,
max(Case when MEASURE_YEAR = 'MY3' THEN EPI_ID_MILLIMAN ELSE '' END) AS EPI_ID_MILLIMAN_MY3
from all_epi_pre_ybase
group by BENE_SK, clinical_episode, anchor_beg_dt, anchor_end_dt
;
quit;

	proc sql;
	create table epi_combos_use as
	select *, (CASE WHEN EPI_ID_MILLIMAN_MY3 <> '' THEN EPI_ID_MILLIMAN_MY3 ELSE EPI_ID_MILLIMAN_MY12 END) AS EPI_ID_MILLIMAN_TO_USE
from epi_combos
;
quit;

	proc sql;
	create table epi_combos_use_out as
	select timeframe_filter, EPI_ID_MILLIMAN_TO_USE
from epi_combos_use A
	INNER JOIN all_epi_pre_ybase B
		ON A.EPI_ID_MILLIMAN_MY12 = B.EPI_ID_MILLIMAN

UNION ALL

	select timeframe_filter, EPI_ID_MILLIMAN_TO_USE
from epi_combos_use A
	INNER JOIN all_epi_pre_ybase B
		ON A.EPI_ID_MILLIMAN_MY3 = B.EPI_ID_MILLIMAN
;
quit;

data out.epi_ID_to_use_&id.;
        set epi_combos_use_out;
	run;


******** PART 2: PULL EPISODES FOR FINAL OUTPUT FROM RESPECTIVE FILES ****************************************************;
*Pulls relevant episodes from the main source file based on the relevant flags and matching episode IDs;

%macro epi_picker(file);

proc sql;
create table all_epi_ybase as
select a.*
from  out.&file._ybase_&id. A
	inner join epi_combos_use B
		on A.EPI_ID_MILLIMAN = B.EPI_ID_MILLIMAN_TO_USE
		;
		quit;

data out.1_&file._ybase_&id.;
set all_epi_ybase;
run;

%mend epi_picker;

*All tables, excluding time period tables and tables that use performance data only;

%epi_picker(epi_detail);
%epi_picker(pjourney);
%epi_picker(pjourneyagg);
%epi_picker(pat_detail);
%epi_picker(prov_detail);
%epi_picker(comp);
%epi_picker(util);
%epi_picker(perf);
%epi_picker(phys_summ);
%epi_picker(bpid_member);
%mend;

data tp_stack;
set out2.tp_ybase_&id. out2.tp_ybase_&id._MY3;
run;
 
proc sql;
create table all_epi_ybase as
select a.*
from  tp_stack A
	inner join epi_combos_use B
		on A.EPI_ID_MILLIMAN = B.EPI_ID_MILLIMAN_TO_USE
		;
		quit;

data out.1_tp_&id.;
set all_epi_ybase out2.tp_&label._&id.:;
run;

**********************************************************************************************************;
* RUN FOR ALL FACILITIES, INCLUDING THOSE WITH NO PERFORMANCE EPISODES;

%selection(5746,0002,0);
/*
%selection(2586,0002,1);
%selection(2586,0005,1);
%selection(2586,0006,1);
%selection(2586,0007,1);
%selection(2586,0010,1);
%selection(2586,0013,1);
%selection(2586,0025,1);
%selection(2586,0026,1);
%selection(2586,0028,1);
%selection(2586,0029,1);
%selection(2586,0030,1);
%selection(2586,0031,1);
%selection(2586,0032,1);
%selection(2586,0033,1);
%selection(2586,0034,1);
%selection(2586,0035,1);
%selection(2586,0036,1);
%selection(2586,0038,1);
%selection(2586,0039,1);
%selection(2586,0040,1);
%selection(2586,0041,1);
%selection(2586,0042,1);
%selection(2586,0043,1);
%selection(2586,0044,1);
%selection(2586,0045,1);
%selection(2586,0046,1);
%selection(1374,0004,0);
%selection(1374,0008,0);
%selection(1374,0009,0);
%selection(1374,0012,1);
%selection(1374,0013,1);
%selection(1374,0014,1);
%selection(1374,0015,1);
%selection(1374,0017,1);
%selection(1374,0018,1);
%selection(1191,0002,0);
%selection(7310,0002,1);
%selection(7310,0003,1);
%selection(7310,0004,1);
%selection(7310,0005,1);
%selection(7310,0006,1);
%selection(7310,0007,1);
%selection(7312,0002,1);
%selection(6054,0002,0);
%selection(6055,0002,0);
%selection(6056,0002,0);
%selection(6057,0002,0);
%selection(6058,0002,0);
%selection(6059,0002,0);
%selection(1209,0000,0);
%selection(1028,0000,1);
%selection(1075,0000,0);
%selection(1102,0000,0);
%selection(1103,0000,0);
%selection(1104,0000,0);
%selection(1105,0000,0);
%selection(1106,0000,0);
%selection(1148,0000,0);
%selection(1167,0000,0);
%selection(1368,0000,0);
%selection(1461,0000,1);
%selection(1634,0000,1);
%selection(1803,0000,1);
%selection(1958,0000,0);
%selection(2048,0000,0);
%selection(2049,0000,0);
%selection(2070,0000,0);
%selection(2214,0000,1);
%selection(2215,0000,1);
%selection(2216,0000,1);
%selection(2302,0000,0);
%selection(2317,0000,1);
%selection(2374,0000,0);
%selection(2376,0000,0);
%selection(2378,0000,0);
%selection(2379,0000,0);
%selection(2451,0000,1);
%selection(2452,0000,1);
%selection(2461,0000,1);
%selection(2468,0000,1);
%selection(2587,0000,0);
%selection(2589,0000,0);
%selection(2594,0000,0);
%selection(2607,0000,0);
%selection(5037,0000,0);
%selection(5038,0000,0);
%selection(5043,0000,0);
%selection(5050,0000,0);
%selection(5154,0000,0);
%selection(5215,0002,0);
%selection(5215,0003,0);
%selection(5263,0000,0);
%selection(5264,0000,0);
%selection(5282,0000,0);
%selection(5392,0004,0);
%selection(5394,0000,0);
%selection(5397,0002,0);
%selection(5397,0003,0);
%selection(5397,0004,0);
%selection(5397,0005,0);
%selection(5397,0006,0);
%selection(5397,0007,0);
%selection(5397,0008,0);
%selection(5397,0009,0);
%selection(5397,0010,0);
%selection(5478,0002,0);
%selection(5479,0002,0);
%selection(5480,0002,0);
%selection(5481,0002,0);
%selection(5746,0002,0);
%selection(1686,0002,0);
%selection(1688,0002,0);
%selection(1696,0002,0);
%selection(1710,0002,0);
%selection(2941,0002,1);
%selection(2956,0002,1);
%selection(6049,0002,0);
%selection(6050,0002,0);
%selection(6051,0002,0);
%selection(6052,0002,0);
%selection(6053,0002,0);
%selection(2974,0003,1);
%selection(2974,0007,1);
*/


data All_Target_Prices_1 All_Target_Prices_Premier All_Target_Prices_NonPremier All_Target_Prices_CCF All_Target_Prices_Dev;
	set out.1_tp_:;

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
