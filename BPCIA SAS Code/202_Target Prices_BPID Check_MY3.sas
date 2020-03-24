%let  _sdtm=%sysfunc(datetime());
*********************************************************
*********************************************************
BPCIA: 202_Target Prices Check
Code to calculate target prices
*********************************************************
*********************************************************;
options mprint;


****** USER INPUTS ******************************************************************************************;
%let mode = base; *main = main interface, base = baseline interface;

%let label = ybase3;


proc printto;run;

%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
libname in "&dataDir.\06 - Imported Raw Data";
/*libname out "&dataDir.\07 - Processed Data";*/
libname tp "&dataDir.\08 - Target Price Data";

libname ref "H:\Nonclient\Medicare Bundled Payment Reference\General\SAS Datasets" ;


%macro modesetup;
%if &mode.=main %then %do;
libname out "&dataDir.\07 - Processed Data";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\202 - Target Prices Check_&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=base %then %do;
libname out "&dataDir.\07 - Processed Data\Baseline Interface";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\202 - Baseline Target Prices Check_&sysdate..log" print=print new;
run;
%end;
%mend modesetup;

%modesetup;

data test01;
	set in.epi_&label._: (rename=(EPISODE_GROUP_NAME=EPISODE_GROUP_NAME_orig));
	*where DROP_EPISODE=0;
	if ANCHOR_BEG_DT < mdy(10,1,2015) then Epi_Pre_Data=1;
	else Epi_Pre_Data=0;
	EPISODE_GROUP_NAME = substr(EPISODE_GROUP_NAME_orig,4,length(EPISODE_GROUP_NAME_orig)-3);
	if ANCHOR_TYPE = 'ip' then anchor_type_upper = 'IP';
	else if ANCHOR_TYPE = 'op' then anchor_type_upper = 'OP';
	else anchor_type_upper = ANCHOR_TYPE;
	if EPISODE_GROUP_NAME = 'Major joint replacement of the lower extremity' then anchor_type_upper = 'MS';
run;

proc sql;
	create table test02 as
	select ATTRIBUTED_PVDR_GROUP_ID, EPISODE_GROUP_NAME, anchor_type_upper,max(Epi_Pre_Data) as Epi_Pre_Data
	from test01
	group by ATTRIBUTED_PVDR_GROUP_ID, EPISODE_GROUP_NAME, anchor_type_upper
	having Epi_Pre_Data=0;
quit;

proc sql;
	create table test03 as
	select a.ATTRIBUTED_PVDR_GROUP_ID, a.EPISODE_GROUP_NAME, a.anchor_type_upper
	from test01 as a inner join test02 as b
	on a.ATTRIBUTED_PVDR_GROUP_ID = b.ATTRIBUTED_PVDR_GROUP_ID
	and a.EPISODE_GROUP_NAME = b.EPISODE_GROUP_NAME
	and a.anchor_type_upper = b.anchor_type_upper;
quit;

proc sort nodupkey data=test03;
	by ATTRIBUTED_PVDR_GROUP_ID EPISODE_GROUP_NAME anchor_type_upper;
run;

data test04;
	set out.tp_&label._:;
	if ANCHOR_TYPE = 'ip' then anc_type = 'IP';
	else if ANCHOR_TYPE = 'op' then anc_type = 'OP';
	if EPISODE_GROUP_NAME = 'Major joint replacement of the lower extremity' then anc_type = 'MS';
run;

proc sql;
	create table bpid_list as
	select a.*, b.bpid
	from test03 as a left join test04 as b
	on a.ATTRIBUTED_PVDR_GROUP_ID = b.EPISODE_INITIATOR;
quit;
proc sort nodupkey data=bpid_list; by ATTRIBUTED_PVDR_GROUP_ID EPISODE_GROUP_NAME anchor_type_upper; run;

proc sql;
	create table test05 as
	select BPID, EPISODE_INITIATOR, ANCHOR_CCN, EPISODE_GROUP_NAME, anc_type, count(*) as BPID_EPI_COUNT
	from test04
	group by BPID, EPISODE_INITIATOR, ANCHOR_CCN, EPISODE_GROUP_NAME, anc_type;
quit;

proc sql;
	create table test06 as
	select a.*
	from test05 as a inner join test03 as b
	on a.EPISODE_INITIATOR = b.ATTRIBUTED_PVDR_GROUP_ID
	and a.EPISODE_GROUP_NAME = b.EPISODE_GROUP_NAME
	and a.anc_type = b.anchor_type_upper;
quit;

proc sql;
	create table test07 as
	select a.*, b.EPI_COUNT
	from test06 as a inner join tp.tp_components_my3_all as b
	on a.BPID=b.INITIATOR_BPID and a.EPISODE_GROUP_NAME=b.EPI_CAT and a.anc_type=b.EPI_TYPE and a.ANCHOR_CCN=b.ASSOC_ACH_CCN;
quit;

data test08;
	set test07;
	if EPI_COUNT=BPID_EPI_COUNT;
	if EPI_COUNT > 40;
run;

proc sql;
	create table test09 as
	select a.*
	from test04 as a inner join test08 as b
	on a.BPID=b.BPID 
		and a.EPISODE_INITIATOR=b.EPISODE_INITIATOR 
		and a.ANCHOR_CCN=b.ANCHOR_CCN 
		and a.EPISODE_GROUP_NAME=b.EPISODE_GROUP_NAME
		and a.anc_type=b.anc_type;
quit;


*****************************************************************;
*Checks;

proc sql;
	create table PCMA_Check as 
	select BPID, EPISODE_INITIATOR, ANCHOR_CCN, EPISODE_GROUP_NAME, anc_type, sum(PCMA_Adj)/count(*) as avg_PCMA_Adj, sum(PCMA)/count(*) as avg_PCMA
	from test09
	group by BPID, EPISODE_INITIATOR, ANCHOR_CCN, EPISODE_GROUP_NAME, anc_type;
quit;
data t1;
	set PCMA_Check;
	if round(avg_PCMA_Adj,.0000001)^=round(avg_PCMA,.0000001);
run;

proc sql;
	create table Target_Price_Check as 
	select BPID, EPISODE_INITIATOR, ANCHOR_CCN, EPISODE_GROUP_NAME, anc_type, sum(Adjusted_TP_Real)/count(*) as Adj_Target_Price, avg(TARGET_PRICE_REAL) as TARGET_PRICE_REAL
	from test09
	group by BPID, EPISODE_INITIATOR, ANCHOR_CCN, EPISODE_GROUP_NAME, anc_type;
quit;

proc sql;
	create table PAT_Check_pre as
	select BPID, EPISODE_INITIATOR, ANCHOR_CCN, EPISODE_GROUP_NAME, anc_type, sum(PAT_2020Q3)/count(*) as Calculated_PAT, sum(PAT_ROUND)/count(*) as CMS_PAT
	from test04
	group by BPID, EPISODE_INITIATOR, ANCHOR_CCN, EPISODE_GROUP_NAME, anc_type;
quit; 

data PAT_Check;
	set PAT_Check_pre;
	if CMS_PAT ^= .;
	if round(Calculated_PAT,0.01) ^= round(CMS_PAT,0.01);
run;

data All_PCMA_Check_pre;
	set test04;
	if TARGET_PRICE ^= .;
run;

proc sql;
	create table All_PCMA_Check as
	select Epi_Year, Epi_Qtr, avg(PCMA_Adj) as Avg_PCMA_Adj
	from All_PCMA_Check_pre
	group by Epi_Year, Epi_Qtr
	order by Epi_Year, Epi_Qtr;
quit;

%MACRO EXPORT;
%if &mode.=main %then %do;
	proc export data= PCMA_Check
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Checks\TP PCMA Check.csv"
	            dbms=csv replace; 
	run;

	proc export data= Target_Price_Check
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Checks\TP Price Check.csv"
	            dbms=csv replace; 
	run;

	proc export data= PAT_Check
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Checks\TP PAT Check.csv"
	            dbms=csv replace; 
	run;

	proc export data= All_PCMA_Check
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Checks\TP PCMA Trend Check.csv"
	            dbms=csv replace; 
	run;
%end;
%else %if &mode.=base %then %do;
	proc export data= PCMA_Check
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Checks\Baseline TP PCMA Check.csv"
	            dbms=csv replace; 
	run;

	proc export data= Target_Price_Check
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Checks\Baseline TP Price Check.csv"
	            dbms=csv replace; 
	run;

	proc export data= PAT_Check
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Checks\Baseline TP PAT Check.csv"
	            dbms=csv replace; 
	run;

	proc export data= All_PCMA_Check
	            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Checks\Baseline TP PCMA Trend Check.csv"
	            dbms=csv replace; 
	run;
%end;
%mend EXPORT;

%EXPORT;

proc printto;run;
%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;


data test_pre;
	set test04;
	proc sort nodupkey; by BPID EPISODE_GROUP_NAME_orig;
run;
proc sql;
	create table test as
	select BPID, count(*) as Epis
	from test_pre
	group by BPID
	order by (calculated Epis) desc;
quit;

data temp;
	set test04;
	where substr(anc_ccn,1,1) = '0';
	proc sort nodupkey; by bpid;
run;

