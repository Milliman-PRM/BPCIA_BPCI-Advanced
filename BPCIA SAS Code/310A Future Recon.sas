%let _sdtm=%sysfunc(datetime());

%let label = y202003; *Recon label;
*%let Prev_label = y202002; *Previous Recon label;
*%let Perf_label = y202003; *Most recent performance label;
%let Recon_label = pp1Initial; *Most recent performance label;
%let transmit_date = '13MAR2020'd;*Change for every Update*; 
%let Perf_label_monthly = y202003; *Most recent performance label;
%let Perf_label_quarterly = y202002;
/*
quarterly
Y if quarterly
N if not quarterly
next quarterly is month 202004
*/
%let quarterly = N; 
proc printto;run;
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\310A - Qlikview Code_&label._&sysdate..log" print=print new;

%let main = H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code;
%include "&main.\000 - Formats - BPCIA.sas";
%include "&main.\000 - BPCIA_Interface_BPIDs.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";

***** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
libname in "&dataDir.\06 - Imported Raw Data";
libname out "&dataDir.\07 - Processed Data";
libname out2 "&dataDir.\07 - Processed Data\Recon";
libname out3 "&dataDir.\07 - Processed Data\Demo";
libname tp "&dataDir.\08 - Target Price Data";
*libname recon "&dataDir.\09 - Reconciliation Reports\PP1 Initial\Other\Stacked Files";

libname ref "H:\Nonclient\Medicare Bundled Payment Reference\General\SAS Datasets" ;
libname bpciaref 'H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets';
libname cjrref "H:\Nonclient\Medicare Bundled Payment Reference\Program - CJR\SAS Datasets";

%let exportDir = R:\data\HIPAA\BPCIA_BPCI Advanced\13 - Reconciliation Output\Recon - &Recon_label.;

%macro FutureRecon(id,reconref);

%if &id. = 1075_0000 or &id. = 2048_0000 or &id. = 2049_0000 or &id. = 2589_0000 or &id. = 5037_0000 %then %do;
%let label = &Perf_label_quarterly.;
%end;

%else %do;
%let label = &Perf_label_monthly.; 
%end;

data tp_stack;
set out.tp_&label._&id.: (Drop=Census_Pre);
run;

data tp_&label._&id. ;
    set tp_stack (in=a) 
tp_stack (in=b where=(max(DROPFLAG_PRELIM_CJR_OVERLAP, DROPFLAG_PRELIM_BPCI_A_OVERLAP)=0))
tp_stack (in=c where=(DROPFLAG_PRELIM_CJR_OVERLAP=0))
tp_stack (in=d where=(DROPFLAG_PRELIM_BPCI_A_OVERLAP=0));
    format FUTURE_RECON_OVERLAP_FLAG $30.;
    if a=1 then FUTURE_RECON_OVERLAP_FLAG = 'None';
	else if b=1 then FUTURE_RECON_OVERLAP_FLAG = 'Both BPCIA and CJR Episodes';
	else if c=1 then FUTURE_RECON_OVERLAP_FLAG = 'CJR Episodes';
	else if d=1 then FUTURE_RECON_OVERLAP_FLAG = 'BPCIA Episodes';
run;

proc sql;
create table future_recon1A_pre as 
	select a.*
		  ,b.BPCI_Episode_Idx
		  ,case when (&transmit_date. - A.POST_DSCH_END_DT) >= 60 then "Yes" else "No" end as COMP_EP_FLAG 
 /* from out.tp_y202001_1148_0000 AS A */   
 from tp_&label._&id.  AS A 
	left join bpciaref.BPCIA_DRG_Mapping as b
	on a.ANCHOR_CODE = b.code
where has_tp = 'Yes' 
and (&transmit_date. - A.POST_DSCH_END_DT) >= 60
;
quit;

data future_recon1A;
	set future_recon1A_pre;
	drop Clinical_Episode clinical_episode_abbr clinical_episode_abbr2 BPID_ClinicalEp;
run;

proc sql;
create table future_recon1B as
  select a.*
          ,b.Clinical_Episode
		  ,b.Short_name as clinical_episode_abbr
		  ,b.Short_name_2 as clinical_episode_abbr2
		  ,strip(BPID)||" - "||strip(b.Short_name) as BPID_ClinicalEp
	from future_recon1A as a
	left join bpciaref.BPCIA_Clinical_Episode_Names as b
	on a.BPCI_Episode_Idx = b.BPCI_Episode_Index
;
quit;


proc sql;
create table future_recon1B_all as
  select a.*
          ,b.Clinical_Episode
		  ,'All Episodes' as clinical_episode_abbr
		  ,b.Short_name_2 as clinical_episode_abbr2
		  ,strip(BPID)||" - "||strip(b.Short_name) as BPID_ClinicalEp
	from future_recon1A as a
	left join bpciaref.BPCIA_Clinical_Episode_Names as b
	on a.BPCI_Episode_Idx = b.BPCI_Episode_Index
;
quit;

data future_recon1C;
set future_recon1B future_recon1B_all;
	if '01OCT2018'd le POST_DSCH_END_DT le '30JUN2019'd then epi_period_short = "PP1";
	if '01JUL2019'd le POST_DSCH_END_DT le '31DEC2019'd then epi_period_short = "PP2";
	if '01JAN2020'd le POST_DSCH_END_DT le '30JUN2020'd then epi_period_short = "PP3";
	if '01JUL2020'd le POST_DSCH_END_DT le '31DEC2020'd then epi_period_short = "PP4";
	if '01JAN2021'd le POST_DSCH_END_DT le '30JUN2021'd then epi_period_short = "PP5";
	if '01JUL2021'd le POST_DSCH_END_DT le '31DEC2021'd then epi_period_short = "PP6";
	if '01JAN2022'd le POST_DSCH_END_DT le '30JUN2022'd then epi_period_short = "PP7";
	if '01JUL2022'd le POST_DSCH_END_DT le '31DEC2022'd then epi_period_short = "PP8";
	if '01JAN2023'd le POST_DSCH_END_DT le '30JUN2023'd then epi_period_short = "PP9";
	if '01JUL2023'd le POST_DSCH_END_DT le '31DEC2023'd then epi_period_short = "PP10";
run;

proc sql;
create table future_recon1 as 
select FUTURE_RECON_OVERLAP_FLAG, BPID, epi_period_short, clinical_episode_abbr, COUNT(*) AS EPISODE_COUNT, 
SUM(EPI_STD_PMT_FCTR_WIN_1_99_Real) AS TRUED_UP_COST,
SUM(adjusted_TP_Real) as TRUEDUP_TP,
SUM(adjusted_TP_Real) - SUM(EPI_STD_PMT_FCTR_WIN_1_99_Real) AS TRUED_UP_NPRA
from future_recon1C
group by FUTURE_RECON_OVERLAP_FLAG, BPID, clinical_episode_abbr, epi_period_short
;
quit;

proc sql;
create table future_recon2 as
SELECT *, TRUED_UP_NPRA AS RECON_AMT, TRUED_UP_NPRA AS ALLEPI_TrueUp, TRUEDUP_TP AS ALLEPI_TP
FROM future_recon1
;
quit;

proc sql;
create table future_recon3_pre as
SELECT *, (CASE WHEN recon_amt> 0 then recon_amt*0.9 else recon_amt END) AS ALLEPI_ADJ_RECON,
(CASE WHEN recon_amt> 0 then recon_amt*0.9 else recon_amt END) AS ALLEPI_ADJ_RECON_Q10,
(CASE WHEN recon_amt> 0 then recon_amt*0.92 else recon_amt*.98 END) AS ALLEPI_ADJ_RECON_Q8,
(CASE WHEN recon_amt> 0 then recon_amt*0.94 else recon_amt*.96 END) AS ALLEPI_ADJ_RECON_Q6,
(CASE WHEN recon_amt> 0 then recon_amt*0.96 else recon_amt*.94 END) AS ALLEPI_ADJ_RECON_Q4,
(CASE WHEN recon_amt> 0 then recon_amt*0.98 else recon_amt*.92 END) AS ALLEPI_ADJ_RECON_Q2,
(CASE WHEN recon_amt> 0 then recon_amt*1 else recon_amt*.9 END) AS ALLEPI_ADJ_RECON_Q0
FROM future_recon2
;
quit;
/*
proc sql;
UPDATE future_recon3
SET ALLEPI_TrueUp = (SELECT RECON_AMT
FROM future_recon2
where clinical_episode_abbr = 'All Episodes')
;
quit;
*/
data future_recon3_pre2;
	set future_recon3_pre;
	where clinical_episode_abbr = 'All Episodes';
run;

proc sql;
	create table future_recon3 as
	select 

b.ALLEPI_ADJ_RECON, 
b.ALLEPI_ADJ_RECON_Q0,
b.ALLEPI_ADJ_RECON_Q2,
b.ALLEPI_ADJ_RECON_Q4,
b.ALLEPI_ADJ_RECON_Q6,
b.ALLEPI_ADJ_RECON_Q8,
b.ALLEPI_ADJ_RECON_Q10,
b.RECON_AMT as ALLEPI_TrueUp, 
b.ALLEPI_TP,  a.*
	from future_recon3_pre as a left join future_recon3_pre2 as b
	on a.BPID=b.BPID and a.epi_period_short=b.epi_period_short
	and a.FUTURE_RECON_OVERLAP_FLAG = b.FUTURE_RECON_OVERLAP_FLAG;
quit;


proc sql;
create table future_recon4 as
SELECT *, 
(CASE WHEN ALLEPI_TrueUp> 0  then recon_amt*0.90 else recon_amt END) AS ADJ_RECON,
(CASE WHEN ALLEPI_TrueUp> 0  then recon_amt*0.90 else recon_amt END) AS Recon_AMT_QA10,
(CASE WHEN ALLEPI_TrueUp> 0  then recon_amt*0.92 else recon_amt*.98 END) AS Recon_AMT_QA8,
(CASE WHEN ALLEPI_TrueUp> 0  then recon_amt*0.94 else recon_amt*.96 END) AS Recon_AMT_QA6,
(CASE WHEN ALLEPI_TrueUp> 0  then recon_amt*0.96 else recon_amt*.94 END) AS Recon_AMT_QA4,
(CASE WHEN ALLEPI_TrueUp> 0  then recon_amt*0.98 else recon_amt*.92 END) AS Recon_AMT_QA2,
(CASE WHEN ALLEPI_TrueUp> 0  then recon_amt else recon_amt*.90 END) AS Recon_AMT_QA0,
(CASE WHEN clinical_episode_abbr = 'All Episodes' THEN 'ZZZZZZZZZZZZZZZZZZ' ELSE clinical_episode_abbr END) AS SORT_VARIABLE
FROM future_recon3
;
quit;

	proc sort data=future_recon4 out=future_recon5;
	by epi_period_short SORT_VARIABLE;
	run;

		data future_recon6;
	set future_recon5;
	SORT_NUMBER_BPID = monotonic();
	run;

	proc sql;
	create table clinical_episode_names_1 as 
	select distinct short_name
	from bpciaref.BPCIA_Clinical_Episode_Names
	;
	quit;

	proc sql;
	create table clinical_episode_names_2 as 
	select distinct 'All Episodes' as short_name
	from bpciaref.BPCIA_Clinical_Episode_Names
	;
	quit;

	data clinical_episode_names_3;
set clinical_episode_names_1 clinical_episode_names_2;
run;

proc sql;
create table clinical_episode_names_4 as
SELECT *, 
lower(CASE WHEN short_name = 'All Episodes' THEN 'ZZZZZZZZZZZZZZZZZZ' ELSE short_name END) AS SORT_VARIABLE
FROM clinical_episode_names_3
;
quit;

	proc sort data=clinical_episode_names_4 out=clinical_episode_names_5;
	by SORT_VARIABLE;
	run;

	data clinical_episode_names_6;
	set clinical_episode_names_5;
	SORT_NUMBER = monotonic();
	run;

	proc sql;
	create table future_recon7 as
	SELECT A.*, B.SORT_NUMBER
	FROM future_recon6	A
		INNER JOIN clinical_episode_names_6 B
			ON A.clinical_episode_abbr = B.short_name
			;
			quit;
/*
proc sql;
create table adj_recon_multiplier as
select Initiator_BPID, (CASE WHEN ABS(Cap_Adj_Total_Recon_Amount) = ABS(_20pct_Total_Perf_Target_Amount) THEN ABS(Cap_Adj_Total_Recon_Amount)/ABS(Adj_Total_Recon_Amount) ELSE 1 END) AS MULTIPLIER 
from recon.reconciliation_report
;
quit;
*/
%if &reconref. = 1 %then %do;
proc sql;
create table recon_distinct as
select distinct
BPID,
epi_period_short,
clinical_episode_abbr,
CLIN_CMS_TP_REAL,
CLIN_CMS_ALLOWED_REAL,
CLIN_CMS_EPI_COUNT,
CLIN_CMS_NPRA
/*
Stop_Loss_Stop_Gain,
BPID_CMS_ALLOWED_REAL,
BPID_CMS_TP_REAL,
CMS_RECON_Amount, 
CMS_adjusted_recon_amount,
StopLoss_StopGain,
Capped_adj_recon_Amt
*/
 from out.recon_&recon_label._&id.
/* from out.recon_pp1initial_1148_0000 */
;
quit;

proc sql;
create table recon_distinct2 as
select distinct
BPID,
epi_period_short,
Stop_Loss_Stop_Gain,
BPID_CMS_ALLOWED_REAL,
BPID_CMS_TP_REAL,
CMS_RECON_Amount, 
CMS_adjusted_recon_amount,
StopLoss_StopGain,
Capped_adj_recon_Amt,
ALLEPI_CMS_EPI_COUNT
 from out.recon_&recon_label._&id.
/* from out.recon_pp1initial_1148_0000 */
;
quit;
%end;
%else %do;
data recon_distinct;
	set _NULL_;
run;
data recon_distinct2;
	set _NULL_;
run;
%end;

	proc sql;
	create table future_recon7_multiplier as
	select FUTURE_RECON_OVERLAP_FLAG, BPID, epi_period_short,
	clinical_episode_abbr,
	(CASE WHEN ABS(ALLEPI_ADJ_RECON) >= ABS(ALLEPI_TP*0.20) THEN ABS(ALLEPI_TP*0.20)/ABS(ALLEPI_ADJ_RECON) ELSE 1 END) AS MULTIPLIER,
	(CASE WHEN ABS(ALLEPI_ADJ_RECON_Q0) >= ABS(ALLEPI_TP*0.20) THEN ABS(ALLEPI_TP*0.20)/ABS(ALLEPI_ADJ_RECON_Q0) ELSE 1 END) AS MULTIPLIER_Q0 ,
	(CASE WHEN ABS(ALLEPI_ADJ_RECON_Q2) >= ABS(ALLEPI_TP*0.20) THEN ABS(ALLEPI_TP*0.20)/ABS(ALLEPI_ADJ_RECON_Q2) ELSE 1 END) AS MULTIPLIER_Q2 ,
	(CASE WHEN ABS(ALLEPI_ADJ_RECON_Q4) >= ABS(ALLEPI_TP*0.20) THEN ABS(ALLEPI_TP*0.20)/ABS(ALLEPI_ADJ_RECON_Q4) ELSE 1 END) AS MULTIPLIER_Q4 ,
	(CASE WHEN ABS(ALLEPI_ADJ_RECON_Q6) >= ABS(ALLEPI_TP*0.20) THEN ABS(ALLEPI_TP*0.20)/ABS(ALLEPI_ADJ_RECON_Q6) ELSE 1 END) AS MULTIPLIER_Q6 ,
	(CASE WHEN ABS(ALLEPI_ADJ_RECON_Q8) >= ABS(ALLEPI_TP*0.20) THEN ABS(ALLEPI_TP*0.20)/ABS(ALLEPI_ADJ_RECON_Q8) ELSE 1 END) AS MULTIPLIER_Q8 ,
	(CASE WHEN ABS(ALLEPI_ADJ_RECON_Q10) >= ABS(ALLEPI_TP*0.20) THEN ABS(ALLEPI_TP*0.20)/ABS(ALLEPI_ADJ_RECON_Q10) ELSE 1 END) AS MULTIPLIER_Q10 
	FROM future_recon7
			;
			quit;

	proc sql;
	create table future_recon8 as
	select A.FUTURE_RECON_OVERLAP_FLAG, A.BPID, A.epi_period_short,
	A.clinical_episode_abbr,
EPISODE_COUNT,
TRUED_UP_COST, TRUEDUP_TP,	TRUED_UP_NPRA,	RECON_AMT,	ADJ_RECON*Multiplier AS ADJ_RECON,	
Recon_AMT_QA10*MULTIPLIER_Q10 AS Recon_AMT_QA10,	Recon_AMT_QA8*MULTIPLIER_Q8 AS Recon_AMT_QA8,	Recon_AMT_QA6*MULTIPLIER_Q6 AS Recon_AMT_QA6,	
Recon_AMT_QA4*MULTIPLIER_Q4 AS Recon_AMT_QA4,	Recon_AMT_QA2*MULTIPLIER_Q2 AS Recon_AMT_QA2 ,	Recon_AMT_QA0*MULTIPLIER_Q0 AS Recon_AMT_QA0, ALLEPI_TrueUp, ALLEPI_TP,
SORT_NUMBER_BPID, SORT_NUMBER, Multiplier,
(CASE WHEN min(B.Multiplier,MULTIPLIER_Q10,MULTIPLIER_Q8,MULTIPLIER_Q6,MULTIPLIER_Q4,MULTIPLIER_Q2,MULTIPLIER_Q0) ^= 1 THEN 'Yes' ELSE 'No' END) AS RECON_TRUEDUP_STOP,
(CASE WHEN (ALLEPI_TP*.2) <= abs(ALLEPI_ADJ_RECON) THEN 'Yes' ELSE 'No' END)  AS TRUEDUP_STOP,
%if &reconref. = 1 %then %do;
(CASE WHEN E.Stop_loss_Stop_gain IS NOT NULL and E.Stop_loss_Stop_gain = 'Yes' THEN 'Yes'  ELSE 'No' END)  AS CMS_CURRENT_STOP,
E.BPID_CMS_ALLOWED_REAL,
E.BPID_CMS_TP_REAL,
E.CMS_RECON_Amount, 
E.CMS_adjusted_recon_amount AS CMS_adjusted_recon_amount,
E.StopLoss_StopGain,
E.Capped_adj_recon_Amt AS Capped_adj_recon_Amt,
E.ALLEPI_CMS_EPI_COUNT,
D.CLIN_CMS_TP_REAL,
D.CLIN_CMS_ALLOWED_REAL,
D.CLIN_CMS_EPI_COUNT,
D.CLIN_CMS_NPRA
%end;
%else %do;
'-' as CMS_CURRENT_STOP,
. as BPID_CMS_ALLOWED_REAL,
. as BPID_CMS_TP_REAL,
. as CMS_RECON_Amount, 
. as CMS_adjusted_recon_amount,
. as StopLoss_StopGain,
. as Capped_adj_recon_Amt,
. as ALLEPI_CMS_EPI_COUNT,
. as CLIN_CMS_TP_REAL,
. as CLIN_CMS_ALLOWED_REAL,
. as CLIN_CMS_EPI_COUNT,
. as CLIN_CMS_NPRA
%end;
	FROM future_recon7	A
		INNER JOIN future_recon7_multiplier B
			ON A.BPID = B.BPID
			AND A.epi_period_short = B.epi_period_short
			AND A.clinical_episode_abbr = B.clinical_episode_abbr
			AND A.FUTURE_RECON_OVERLAP_FLAG = B.FUTURE_RECON_OVERLAP_FLAG
		LEFT OUTER JOIN tp.recon_reports_all C
			ON A.BPID = C.Convener_ID
		%if &reconref. = 1 %then %do;
			LEFT OUTER JOIN recon_distinct  D
					ON A.BPID = D.BPID
				AND A.epi_period_short = D.epi_period_short	
				AND A.clinical_episode_abbr= D.clinical_episode_abbr	
			LEFT OUTER JOIN recon_distinct2  E
					ON A.BPID = E.BPID
				AND A.epi_period_short = E.epi_period_short	
		%end;
			;
			quit;


data future_recon9;
set future_recon8;
	if CLINICAL_EPISODE_ABBR = 'All Episodes' then do;
		CLIN_CMS_TP_REAL = BPID_CMS_TP_REAL;
		CLIN_CMS_ALLOWED_REAL = BPID_CMS_ALLOWED_REAL;
		CLIN_CMS_EPI_COUNT = ALLEPI_CMS_EPI_COUNT;
		CLIN_CMS_NPRA = CMS_Recon_Amount;
		CLIN_CMS_RECON_AMT = CMS_ADJUSTED_RECON_AMOUNT;
	end;

	if CMS_RECON_Amount>0 then CLIN_CMS_RECON_AMT = CLIN_CMS_NPRA*0.9;
	else CLIN_CMS_RECON_AMT = CLIN_CMS_NPRA;

	recon_mult = Capped_adj_recon_Amt / CMS_adjusted_recon_amount;
	CLIN_CMS_CAP_RECON_AMT=CLIN_CMS_RECON_AMT*recon_mult;

	FR_JOIN = BPID||"_"||epi_period_short;
run;

data out.TP_Var_&label._&id.;
	format CMS_CURRENT_STOP $3.;
	set future_recon9;
	if CMS_CURRENT_STOP = 'N' then CMS_CURRENT_STOP = 'No';
	if CMS_CURRENT_STOP = 'Y' then CMS_CURRENT_STOP = 'Yes';
run;

*delete work datasets*;
proc datasets lib=work memtype=data kill;
run;
quit;

%mend FutureRecon;

*%FutureRecon(5746_0002,1);


%FutureRecon(2586_0002,1);
%FutureRecon(2586_0005,1);
%FutureRecon(2586_0006,1);
%FutureRecon(2586_0007,1);
%FutureRecon(2586_0010,1);
%FutureRecon(2586_0013,1);
%FutureRecon(2586_0025,0);
%FutureRecon(2586_0026,0);
%FutureRecon(2586_0028,0);
%FutureRecon(2586_0029,0);
%FutureRecon(2586_0030,0);
%FutureRecon(2586_0031,0);
%FutureRecon(2586_0032,0);
%FutureRecon(2586_0033,0);
%FutureRecon(2586_0034,0);
%FutureRecon(2586_0035,0);
*%FutureRecon(2586_0036,0);
*%FutureRecon(2586_0038,0);
%FutureRecon(2586_0039,0);
*%FutureRecon(2586_0040,0);
*%FutureRecon(2586_0041,0);
*%FutureRecon(2586_0042,0);
*%FutureRecon(2586_0043,0);
%FutureRecon(2586_0044,0);
%FutureRecon(2586_0045,0);
%FutureRecon(2586_0046,0);
%FutureRecon(1374_0004,1);
%FutureRecon(1374_0008,1);
%FutureRecon(1374_0009,1);
%FutureRecon(1374_0012,0);
%FutureRecon(1374_0013,0);
%FutureRecon(1374_0014,0);
%FutureRecon(1374_0015,0);
%FutureRecon(1374_0017,0);
%FutureRecon(1374_0018,0);
%FutureRecon(1191_0002,1);
%FutureRecon(7310_0002,0);
%FutureRecon(7310_0003,0);
%FutureRecon(7310_0004,0);
%FutureRecon(7310_0005,0);
%FutureRecon(7310_0006,0);
%FutureRecon(7310_0007,0);
%FutureRecon(7312_0002,0);
%FutureRecon(6054_0002,1);
%FutureRecon(6055_0002,1);
%FutureRecon(6056_0002,1);
%FutureRecon(6057_0002,1);
%FutureRecon(6058_0002,1);
%FutureRecon(6059_0002,1);
%FutureRecon(1209_0000,1);
%FutureRecon(1028_0000,0);
%FutureRecon(1075_0000,1);
%FutureRecon(1102_0000,1);
%FutureRecon(1103_0000,1);
%FutureRecon(1104_0000,1);
%FutureRecon(1105_0000,1);
%FutureRecon(1106_0000,1);
%FutureRecon(1148_0000,1);
%FutureRecon(1167_0000,1);
%FutureRecon(1343_0000,1);
%FutureRecon(1368_0000,1);
%FutureRecon(1461_0000,0);
%FutureRecon(1634_0000,1);
*%FutureRecon(1803_0000,0);
%FutureRecon(1958_0000,1);
%FutureRecon(2048_0000,1);
%FutureRecon(2049_0000,1);
%FutureRecon(2070_0000,1);
%FutureRecon(2214_0000,0);
%FutureRecon(2215_0000,0);
%FutureRecon(2216_0000,0);
%FutureRecon(2302_0000,1);
%FutureRecon(2317_0000,0);
%FutureRecon(2374_0000,1);
%FutureRecon(2376_0000,1);
%FutureRecon(2378_0000,1);
%FutureRecon(2379_0000,1);
%FutureRecon(2451_0000,0);
%FutureRecon(2452_0000,0);
%FutureRecon(2461_0000,0);
%FutureRecon(2468_0000,0);
%FutureRecon(2587_0000,1);
%FutureRecon(2589_0000,1);
%FutureRecon(2594_0000,1);
%FutureRecon(2607_0000,1);
%FutureRecon(5037_0000,1);
%FutureRecon(5038_0000,1);
%FutureRecon(5043_0000,1);
%FutureRecon(5050_0000,1);
%FutureRecon(5154_0000,1);
%FutureRecon(5215_0002,1);
%FutureRecon(5215_0003,1);
%FutureRecon(5229_0000,1);
%FutureRecon(5263_0000,1);
%FutureRecon(5264_0000,1);
%FutureRecon(5282_0000,1);
%FutureRecon(5392_0004,1);
%FutureRecon(5394_0000,1);
%FutureRecon(5395_0000,1);
%FutureRecon(5397_0002,1);
%FutureRecon(5397_0003,1);
%FutureRecon(5397_0004,1);
%FutureRecon(5397_0005,1);
%FutureRecon(5397_0006,1);
%FutureRecon(5397_0007,1);
%FutureRecon(5397_0008,1);
%FutureRecon(5397_0009,1);
%FutureRecon(5397_0010,1);
%FutureRecon(5478_0002,1);
%FutureRecon(5479_0002,1);
%FutureRecon(5480_0002,1);
%FutureRecon(5481_0002,1);
%FutureRecon(5746_0002,1);
%FutureRecon(1686_0002,1);
%FutureRecon(1688_0002,1);
%FutureRecon(1696_0002,1);
%FutureRecon(1710_0002,1);
%FutureRecon(2941_0002,0);
%FutureRecon(2956_0002,0);
%FutureRecon(6049_0002,1);
%FutureRecon(6050_0002,1);
%FutureRecon(6051_0002,1);
%FutureRecon(6052_0002,1);
%FutureRecon(6053_0002,1);
%FutureRecon(2974_0003,0);
%FutureRecon(2974_0007,0);
%FutureRecon(5916_0002,1);

data out.TP_Var_&label. out.TP_Var_pmr_&label. out.TP_Var_oth_&label. out.TP_Var_ccf_&label.;
	set out.TP_Var_&Perf_label_monthly._: 
				%if &quarterly = N %then %do;
			out.TP_Var_&Perf_label_quarterly._:
			%end;
			 ;
	output out.TP_Var_&label.;
	if BPID in (&PMR_EI_lst.) then output out.TP_Var_pmr_&label.;
	else if BPID in (&NON_PMR_EI_lst.) then output out.TP_Var_oth_&label.;
	else if BPID in (&CCF_lst.) then output out.TP_Var_ccf_&label.;
run;

%sas_2_csv(out.TP_Var_&label.,TP_Variability.csv);
%sas_2_csv(out.TP_Var_pmr_&label.,TP_Variability_pmr.csv);
%sas_2_csv(out.TP_Var_oth_&label.,TP_Variability_oth.csv);
%sas_2_csv(out.TP_Var_ccf_&label.,TP_Variability_ccf.csv);



/*********************************************
DEMO
*********************************************/
proc format; value $masked_bpid
'1148-0000'='1111-0000'
'1167-0000'='2222-0000'
'1343-0000'='3333-0000'
'1368-0000'='4444-0000'
'2379-0000'='5555-0000'
'2587-0000'='6666-0000'
'2607-0000'='7777-0000'
'5479-0002'='8888-0000'
other='';
run;

********************
********************
Calculation of Adjusted Target Prices
********************
********************;
%macro RunHosp2(id);

data out3.TP_Var_&label._&id.;
	format BPID $9.;
	set out.TP_Var_&label._&id. (rename=(BPID=BPID_o));

	BPID = put(BPID_o,$masked_bpid.);
	IF FR_JOIN = '' THEN FR_JOIN = BPID||"_"||epi_period_short;
	*episode_count = 100;

run;

%mend;

%runhosp2(1148_0000);
%runhosp2(1167_0000);
%runhosp2(1343_0000);
%runhosp2(1368_0000);
%runhosp2(2379_0000);
%runhosp2(2587_0000);
%runhosp2(2607_0000);
%runhosp2(5479_0002);


data All_TP_Var_Demo;
	set out3.TP_Var_&label.: ;
	FR_JOIN = BPID||"_"||epi_period_short;
run;


%sas_2_csv(All_TP_Var_Demo,TP_Variability_Demo.csv);


proc printto;run;
%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;

