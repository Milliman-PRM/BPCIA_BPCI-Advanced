%let _sdtm=%sysfunc(datetime());
options mprint nospool minoperator;
****************************************
****************************************
Comprehensive Joint Replacement
CJR: 310 CJR Recon Processing and Qlikview Code
Code to create tables for dashboard 
****************************************
****************************************;
 
******************************************************************************
RUN THIS PROGRAM IN ITS OWN SAS SESSION TO PREVENT ANY DATA ROLLUP ISSUES
******************************************************************************;

********************
Setup 
********************;

%let label = pp1Initial; *Recon label;
%let Prev_label = pp1Initial; *Previous Recon label;
%let Perf_label = y202002; *Most recent performance label;


proc printto;run;
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\310 - Recon Processing_&label._&sysdate..log" print=print new;
run;

%let norecon = '1209-0000',
'1686-0002', '1688-0002', '1696-0002', '1710-0002', '6049-0002', '6050-0002', '6051-0002', '6052-0002', '6053-0002'
; 
%let true_up = ''; /*Performance period for next true-up*/

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

libname ref "H:\Nonclient\Medicare Bundled Payment Reference\General\SAS Datasets" ;
libname bpciaref 'H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets';
libname cjrref "H:\Nonclient\Medicare Bundled Payment Reference\Program - CJR\SAS Datasets";

%let exportDir = R:\data\HIPAA\BPCIA_BPCI Advanced\13 - Reconciliation Output\Recon - &label.;


%macro ReconDashboard(id,reconref);
%if &reconref = 1 %then %do;
data TP_Components;
	set tp.TP_Components_all (rename=(EPI_COUNT=EPI_COUNT_Char));
	format ccn_join $6. epi_period_short $100.;
	epi_period_short = "PP1";
	ccn_join = ASSOC_ACH_CCN;
	if ccn_join = '' then ccn_join = CCN_TIN;
	if length(compress(ccn_join)) = 5 then ccn_join = '0' || ccn_join;

	if EPI_CAT = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPI_CAT = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

	EPI_COUNT = sum(EPI_COUNT_Char,0);

run; 

proc sort data=TP_Components;
	by INITIATOR_BPID EPI_CAT EPI_TYPE ccn_join descending rel_dt descending epi_start descending epi_end;
run;

proc sort nodupkey data=TP_Components;
	by INITIATOR_BPID EPI_CAT EPI_TYPE ccn_join rel_dt epi_start epi_end;
run;

*Pull CMS and Mill calculated totals (in standardized dollars) from 200 code output;
proc sql;
	create table recon_pre as
	select 
		ConvenerID
		,BPID
		,EPI_ID_MILLIMAN
		,episode_initiator
		,anc_ccn as ANCHOR_CCN
		,ANCHOR_AT_NPI
		,ANCHOR_OP_NPI
		,BENE_SK
		,MBI_ID
		,case when BENE_SRNM_NAME in ("","~") then "Unknown"
			else propcase(STRIP(BENE_SRNM_NAME)||", "||STRIP(BENE_GVN_NAME)) 
			end as PATIENT_NAME format = $255. length=255
		,BENE_AGE
		,BENE_DEATH_DT
		,ANCHOR_TYPE
		,anchor_type_upper
		,EPISODE_GROUP_NAME
		,ANCHOR_CODE
		,ANCHOR_APC
		,ANCHOR_BEG_DT
		,ANCHOR_END_DT
		,POST_DSCH_BEG_DT
		,POST_DSCH_END_DT
		,TOT_STD_ALLOWED as CMS_STD_ALLOWED
		,TOT_RAW_ALLOWED
		,EPI_STD_PMT_FCTR
		,EPI_STD_PMT_FCTR_WIN_1_99 
		,TARGET_PRICE as CMS_TARGET_PRICE
		,TARGET_PRICE_REAL as CMS_TARGET_PRICE_REAL
		,wage_index as CMS_Ratio_Real_Std
		,NATURAL_DISASTER_CCN_FLAG as NATURAL_DISASTER_CCN_FLAG_num
		,PERFORMANCE_PERIOD
		,case when DEATH_DUR_POSTDSCHRG = 1 then 'Yes' else 'No' end as death_flag
		,case when month(POST_DSCH_END_DT) < 10 then strip(put(year(POST_DSCH_END_DT),4.)||" M0"||strip(put(month(POST_DSCH_END_DT),2.)))
			 else strip(put(year(POST_DSCH_END_DT),4.)||" M"||strip(put(month(POST_DSCH_END_DT),2.))) 
			 end as Episode_End_YearMo
	from out2.epi_&label._&id.;
quit;

data recon_pre2;
	set recon_pre;
	format timeframe_filter epi_period_short $100.;
	if '01OCT2018'd le POST_DSCH_END_DT le '30JUN2019'd then timeframe_filter = "Performance Period 1";
	if '01JUL2019'd le POST_DSCH_END_DT le '31DEC2019'd then timeframe_filter = "Performance Period 2";
	if '01JAN2020'd le POST_DSCH_END_DT le '30JUN2020'd then timeframe_filter = "Performance Period 3";
	if '01JUL2020'd le POST_DSCH_END_DT le '31DEC2020'd then timeframe_filter = "Performance Period 4";
	if '01JAN2021'd le POST_DSCH_END_DT le '30JUN2021'd then timeframe_filter = "Performance Period 5";
	if '01JUL2021'd le POST_DSCH_END_DT le '31DEC2021'd then timeframe_filter = "Performance Period 6";
	if '01JAN2022'd le POST_DSCH_END_DT le '30JUN2022'd then timeframe_filter = "Performance Period 7";
	if '01JUL2022'd le POST_DSCH_END_DT le '31DEC2022'd then timeframe_filter = "Performance Period 8";
	if '01JAN2023'd le POST_DSCH_END_DT le '30JUN2023'd then timeframe_filter = "Performance Period 9";
	if '01JUL2023'd le POST_DSCH_END_DT le '31DEC2023'd then timeframe_filter = "Performance Period 10";

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

	format MEASURE_YEAR $10.;
	MEASURE_YEAR = 'MY1 & MY2';

	format DRG_APC $4.;
	DRG_APC = ANCHOR_CODE;
	if ANCHOR_TYPE_UPPER='OP' then DRG_APC = ANCHOR_APC;
	if length(DRG_APC)=2 then DRG_APC = "0"||DRG_APC;
run;

data chk_&label._&id._V2;
set out2.chk_&label._&id.;
	format timeframe_filter epi_period_short $100.;
	if '01OCT2018'd le POST_DSCH_END_DT le '30JUN2019'd then timeframe_filter = "Performance Period 1";
	if '01JUL2019'd le POST_DSCH_END_DT le '31DEC2019'd then timeframe_filter = "Performance Period 2";
	if '01JAN2020'd le POST_DSCH_END_DT le '30JUN2020'd then timeframe_filter = "Performance Period 3";
	if '01JUL2020'd le POST_DSCH_END_DT le '31DEC2020'd then timeframe_filter = "Performance Period 4";
	if '01JAN2021'd le POST_DSCH_END_DT le '30JUN2021'd then timeframe_filter = "Performance Period 5";
	if '01JUL2021'd le POST_DSCH_END_DT le '31DEC2021'd then timeframe_filter = "Performance Period 6";
	if '01JAN2022'd le POST_DSCH_END_DT le '30JUN2022'd then timeframe_filter = "Performance Period 7";
	if '01JUL2022'd le POST_DSCH_END_DT le '31DEC2022'd then timeframe_filter = "Performance Period 8";
	if '01JAN2023'd le POST_DSCH_END_DT le '30JUN2023'd then timeframe_filter = "Performance Period 9";
	if '01JUL2023'd le POST_DSCH_END_DT le '31DEC2023'd then timeframe_filter = "Performance Period 10";

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
	create table recon_pre3 as
	select a.*
		,b.total_allowed as Milliman_STD_ALLOWED
		,(b.total_diff*(-1)) as CMS_MILLIMAN_STD_DIFF
	from recon_pre2 as a left join chk_&label._&id._V2 as b
	on a.EPI_ID_MILLIMAN = b.EPI_ID_MILLIMAN
	and a.epi_period_short = b.epi_period_short;
quit;

data tp_&label._&id._V2;
set out2.tp_&label._&id.;
	format timeframe_filter epi_period_short $100.;
	if '01OCT2018'd le POST_DSCH_END_DT le '30JUN2019'd then timeframe_filter = "Performance Period 1";
	if '01JUL2019'd le POST_DSCH_END_DT le '31DEC2019'd then timeframe_filter = "Performance Period 2";
	if '01JAN2020'd le POST_DSCH_END_DT le '30JUN2020'd then timeframe_filter = "Performance Period 3";
	if '01JUL2020'd le POST_DSCH_END_DT le '31DEC2020'd then timeframe_filter = "Performance Period 4";
	if '01JAN2021'd le POST_DSCH_END_DT le '30JUN2021'd then timeframe_filter = "Performance Period 5";
	if '01JUL2021'd le POST_DSCH_END_DT le '31DEC2021'd then timeframe_filter = "Performance Period 6";
	if '01JAN2022'd le POST_DSCH_END_DT le '30JUN2022'd then timeframe_filter = "Performance Period 7";
	if '01JUL2022'd le POST_DSCH_END_DT le '31DEC2022'd then timeframe_filter = "Performance Period 8";
	if '01JAN2023'd le POST_DSCH_END_DT le '30JUN2023'd then timeframe_filter = "Performance Period 9";
	if '01JUL2023'd le POST_DSCH_END_DT le '31DEC2023'd then timeframe_filter = "Performance Period 10";

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
	create table recon_pre4 as
	select a.*
		,b.TP_Adj as Milliman_Target_Price
		,b.Adjusted_TP_Real as Milliman_Target_Price_Real
		,b.EPI_STD_PMT_FCTR_WIN_1_99_Real as CMS_STD_ALLOWED_Real
	from recon_pre3 as a left join tp_&label._&id._V2 as b
	on a.EPI_ID_MILLIMAN = b.EPI_ID_MILLIMAN
	and a.epi_period_short = b.epi_period_short;
quit;

proc sql;
	create table recon_pre5 as
	select a.*, 
		b.Prelim_PCMA,
		b.Final_PCMA
	from recon_pre4 as a 
		left join TP_Components as b
			on a.BPID = b.INITIATOR_BPID
			and a.EPISODE_GROUP_NAME = b.EPI_CAT
			and a.anchor_type_upper = b.EPI_TYPE
			and a.ANCHOR_CCN = b.ccn_join
			and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end
			and a.epi_period_short = b.epi_period_short;
quit;
	
data Recon_cost_&id._0 (drop = prfnpi);
	set out2.dme2_&label._&id.;
	npi_a = sup_npi;
run;

data Recon_cost_&id._1;
	format npi 8.;
	set out2.pb2_&label._&id. (in=a)
		Recon_cost_&id._0   (in=b);
		;
	if a then npi = prfnpi;
	else npi = npi_a;
format timeframe_filter epi_period_short $100.;
	if '01OCT2018'd le POST_DSCH_END_DT le '30JUN2019'd then timeframe_filter = "Performance Period 1";
	if '01JUL2019'd le POST_DSCH_END_DT le '31DEC2019'd then timeframe_filter = "Performance Period 2";
	if '01JAN2020'd le POST_DSCH_END_DT le '30JUN2020'd then timeframe_filter = "Performance Period 3";
	if '01JUL2020'd le POST_DSCH_END_DT le '31DEC2020'd then timeframe_filter = "Performance Period 4";
	if '01JAN2021'd le POST_DSCH_END_DT le '30JUN2021'd then timeframe_filter = "Performance Period 5";
	if '01JUL2021'd le POST_DSCH_END_DT le '31DEC2021'd then timeframe_filter = "Performance Period 6";
	if '01JAN2022'd le POST_DSCH_END_DT le '30JUN2022'd then timeframe_filter = "Performance Period 7";
	if '01JUL2022'd le POST_DSCH_END_DT le '31DEC2022'd then timeframe_filter = "Performance Period 8";
	if '01JAN2023'd le POST_DSCH_END_DT le '30JUN2023'd then timeframe_filter = "Performance Period 9";
	if '01JUL2023'd le POST_DSCH_END_DT le '31DEC2023'd then timeframe_filter = "Performance Period 10";

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
	create table Recon_cost_recon_&id. as
	select	distinct
			npi
		, epi_period_short
		,	EPI_ID_MILLIMAN
		,	sum(allowed) as provider_sum 
	from	Recon_cost_&id._1
	group by
			npi
		, epi_period_short
		,	EPI_ID_MILLIMAN
;
quit;

proc sql;
	create table recon_pre6 as
	select	distinct
			a.*
		,	case when b.provider_sum=. then 0
				 else b.provider_sum
			end as OP_PHYS_COSTS
	from	recon_pre5 as a
			left join
			Recon_cost_recon_&id. as b
			on	a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
				and
				a.ANCHOR_OP_NPI=b.npi
				and a.epi_period_short = b.epi_period_short
;
quit;

proc sql;
	create table recon_pre7 as
	select	distinct
			a.*
		,	case when b.provider_sum=. then 0
				 else b.provider_sum
			end as AT_PHYS_COSTS
	from	recon_pre6 as a
			left join
			Recon_cost_recon_&id. as b
			on	a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
				and
				a.ANCHOR_AT_NPI=b.npi
				and a.epi_period_short = b.epi_period_short
;
quit;

proc sql;
	create table recon_pre7_winz as
	select a.*, b.*
	from recon_pre7 as a left join bpciaref.BPCIA_Winsorization_PP1Initial as b
	on a.DRG_APC=b.DRG_APC;
quit;

data recon_pre8;
	set recon_pre7_winz;

	*Winsorize Milliman Costs;
	if Milliman_STD_ALLOWED < Low_Pct then Milliman_STD_ALLOWED = Low_Pct;
	if Milliman_STD_ALLOWED > High_Pct then Milliman_STD_ALLOWED = High_Pct;

	*Natural Disaster Exclusion;
	if NATURAL_DISASTER_CCN_FLAG_num=1 then do;
		if EPI_STD_PMT_FCTR_WIN_1_99 > CMS_TARGET_PRICE then do;
			CMS_STD_ALLOWED=0;
			CMS_STD_ALLOWED_Real=0;
			EPI_STD_PMT_FCTR_WIN_1_99=0;
			CMS_TARGET_PRICE=0;
			CMS_TARGET_PRICE_REAL=0;
		
			Milliman_STD_ALLOWED=0;
			Milliman_Target_Price=0;
			Milliman_Target_Price_Real=0;
		end;
	end;			

	Milliman_STD_ALLOWED_Real = Milliman_STD_ALLOWED * CMS_Ratio_Real_Std;
	DIFF_STD_ALLOWED_Real = Milliman_STD_ALLOWED_Real - CMS_STD_ALLOWED_Real ;
	Milliman_NPRA = Milliman_Target_Price_Real - Milliman_STD_ALLOWED_Real;
	CMS_NPRA = CMS_TARGET_PRICE_REAL - CMS_STD_ALLOWED_Real;

	format Milliman_CMS_Cost_Match $3.;
	Milliman_CMS_Cost_Match='No';
	if abs(DIFF_STD_ALLOWED_Real)<0.50 then Milliman_CMS_Cost_Match='Yes';

run;

data perf_epis;
	set out.epi_&Perf_label._&id. (keep=EPI_ID_MILLIMAN POST_DSCH_END_DT);

	format timeframe_filter epi_period_short $100.;
	if '01OCT2018'd le POST_DSCH_END_DT le '30JUN2019'd then timeframe_filter = "Performance Period 1";
	if '01JUL2019'd le POST_DSCH_END_DT le '31DEC2019'd then timeframe_filter = "Performance Period 2";
	if '01JAN2020'd le POST_DSCH_END_DT le '30JUN2020'd then timeframe_filter = "Performance Period 3";
	if '01JUL2020'd le POST_DSCH_END_DT le '31DEC2020'd then timeframe_filter = "Performance Period 4";
	if '01JAN2021'd le POST_DSCH_END_DT le '30JUN2021'd then timeframe_filter = "Performance Period 5";
	if '01JUL2021'd le POST_DSCH_END_DT le '31DEC2021'd then timeframe_filter = "Performance Period 6";
	if '01JAN2022'd le POST_DSCH_END_DT le '30JUN2022'd then timeframe_filter = "Performance Period 7";
	if '01JUL2022'd le POST_DSCH_END_DT le '31DEC2022'd then timeframe_filter = "Performance Period 8";
	if '01JAN2023'd le POST_DSCH_END_DT le '30JUN2023'd then timeframe_filter = "Performance Period 9";
	if '01JUL2023'd le POST_DSCH_END_DT le '31DEC2023'd then timeframe_filter = "Performance Period 10";

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
	Perf_Epi='Yes';
run;

proc sql;
	create table recon_pre9 as
	select a.*, coalesce(b.Perf_Epi,'No') as Epi_Perf_Data
	from recon_pre8 as a left join perf_epis as b
	on a.EPI_ID_MILLIMAN = b.EPI_ID_MILLIMAN
	and a.epi_period_short = b.epi_period_short;
quit;

proc sql;
	create table ccn_cms_epis as
	select epi_period_short, INITIATOR_BPID, EPI_CAT, EPI_TYPE, ccn_join, sum(EPI_COUNT) as CCN_CMS_EPI_COUNT
	from TP_Components
	where time_period not in ('Baseline - MY 1&2','10/01/2019 - 12/31/2019')
	group by epi_period_short, INITIATOR_BPID, EPI_CAT, EPI_TYPE, ccn_join;
quit;

proc sql;
	create table recon_CCN_pre as
	select epi_period_short, BPID, ANCHOR_CCN, anchor_type_upper, EPISODE_GROUP_NAME,
		count(distinct EPI_ID_MILLIMAN) as CCN_Milliman_EPI_Count,
		sum(CMS_STD_ALLOWED_Real) as CCN_CMS_ALLOWED_REAL,
		sum(Milliman_STD_ALLOWED_Real) as CCN_Milliman_ALLOWED_REAL,
		sum(Milliman_STD_ALLOWED_Real)-sum(CMS_STD_ALLOWED_Real) as CCN_DIFF_ALLOWED_REAL,
		avg(Milliman_Target_Price_Real) as CCN_Milliman_AVG_TP_REAL,
		sum(CMS_TARGET_PRICE_REAL) as CCN_CMS_TP_REAL,
		sum(Milliman_Target_Price_Real) as CCN_Milliman_TP_REAL,
		sum(Milliman_Target_Price_Real)-sum(CMS_TARGET_PRICE_REAL) as CCN_DIFF_TP_REAL,
		sum(Milliman_NPRA) as CCN_Milliman_NPRA,
		sum(CMS_NPRA) as CCN_CMS_NPRA,
		avg(Prelim_PCMA) as CCN_AVG_Prelim_PCMA,
		avg(Final_PCMA) as CCN_AVG_Final_PCMA
	from recon_pre9
	group by epi_period_short, BPID, ANCHOR_CCN, anchor_type_upper, EPISODE_GROUP_NAME;
quit;

proc sql;
	create table recon_CCN as
	select a.*, b.CCN_CMS_EPI_COUNT
	from recon_CCN_pre as a left join ccn_cms_epis as b
	on a.BPID = b.INITIATOR_BPID
		and a.EPISODE_GROUP_NAME = b.EPI_CAT
		and a.anchor_type_upper = b.EPI_TYPE
		and a.ANCHOR_CCN = b.ccn_join
		and a.epi_period_short = B.epi_period_short;
quit;

proc sql;
	create table recon_pre10 as
	select a.*, b.*
	from recon_pre9 as a left join recon_CCN as b
	on a.BPID=b.BPID
		and a.ANCHOR_CCN=b.ANCHOR_CCN
		and a.anchor_type_upper=b.anchor_type_upper
		and a.EPISODE_GROUP_NAME=b.EPISODE_GROUP_NAME
				and a.epi_period_short = B.epi_period_short;
quit;

proc sql;
	create table clin_cms_epis as
	select epi_period_short, INITIATOR_BPID, EPI_CAT, EPI_TYPE, sum(EPI_COUNT) as CLIN_CMS_EPI_COUNT
	from TP_Components
	where time_period not in ('Baseline - MY 1&2','10/01/2019 - 12/31/2019')
	group by epi_period_short, INITIATOR_BPID, EPI_CAT, EPI_TYPE;
quit;

proc sql;
	create table recon_clin_pre as
	select epi_period_short, BPID, anchor_type_upper, EPISODE_GROUP_NAME,
		count(distinct EPI_ID_MILLIMAN) as CLIN_Milliman_EPI_Count,
		sum(CMS_STD_ALLOWED_Real) as CLIN_CMS_ALLOWED_REAL,
		sum(Milliman_STD_ALLOWED_Real) as CLIN_Milliman_ALLOWED_REAL,
		sum(Milliman_STD_ALLOWED_Real)-sum(CMS_STD_ALLOWED_Real) as CLIN_DIFF_ALLOWED_REAL,
		avg(Milliman_Target_Price_Real) as CLIN_Milliman_AVG_TP_REAL,
		sum(CMS_TARGET_PRICE_REAL) as CLIN_CMS_TP_REAL,
		sum(Milliman_Target_Price_Real) as CLIN_Milliman_TP_REAL,
		sum(Milliman_Target_Price_Real)-sum(CMS_TARGET_PRICE_REAL) as CLIN_DIFF_TP_REAL,
		sum(Milliman_NPRA) as CLIN_Milliman_NPRA,
		sum(CMS_NPRA) as CLIN_CMS_NPRA,
		avg(Prelim_PCMA) as CLIN_AVG_Prelim_PCMA,
		avg(Final_PCMA) as CLIN_AVG_Final_PCMA
	from recon_pre9
	group by epi_period_short, BPID, anchor_type_upper, EPISODE_GROUP_NAME;
quit;

proc sql;
	create table recon_clin as
	select a.*, b.CLIN_CMS_EPI_COUNT
	from recon_clin_pre as a left join clin_cms_epis as b
	on a.BPID = b.INITIATOR_BPID
		and a.EPISODE_GROUP_NAME = b.EPI_CAT
		and a.anchor_type_upper = b.EPI_TYPE
		and a.epi_period_short = B.epi_period_short;
quit;

proc sql;
	create table recon_pre11_pre as
	select a.*, b.*
	from recon_pre10 as a left join recon_clin as b
	on a.BPID=b.BPID
		and a.anchor_type_upper=b.anchor_type_upper
		and a.EPISODE_GROUP_NAME=b.EPISODE_GROUP_NAME
		and a.epi_period_short = B.epi_period_short;
quit;

proc sql;
	create table cms_all_epis_pre as
	select epi_period_short, INITIATOR_BPID, 'All Episodes' as EPI_CAT, sum(EPI_COUNT) as ALLEPI_CMS_EPI_COUNT
	from TP_Components
	where time_period not in ('Baseline - MY 1&2','10/01/2019 - 12/31/2019')
	group by epi_period_short, INITIATOR_BPID;
quit;
/*
data cms_all_epis;
	set cms_all_epis_pre;
	BPID = INITIATOR_BPID;
	IF substr(BPID,1,4)||'_'||substr(BPID,6,4) = "&id.";
run;
*/
proc sql;
	create table recon_pre11 as
	select a.*, b.ALLEPI_CMS_EPI_COUNT
	from recon_pre11_pre as a left join cms_all_epis_pre as b
	on a.BPID = b.INITIATOR_BPID
	and a.epi_period_short = b.epi_period_short;
quit;
/*
proc sql;
	create table recon_ALL_EPI_pre_all as
	select BPID, anchor_type_upper, EPISODE_GROUP_NAME,
		count(distinct EPI_ID_MILLIMAN) as ALL_EPI_Milliman_EPI_Count,
		sum(CMS_STD_ALLOWED_Real) as ALL_EPI_CMS_ALLOWED_REAL,
		sum(Milliman_STD_ALLOWED_Real) as ALL_EPI_Milliman_ALLOWED_REAL,
		sum(Milliman_STD_ALLOWED_Real)-sum(CMS_STD_ALLOWED_Real) as ALL_EPI_DIFF_ALLOWED_REAL,
		avg(Milliman_Target_Price_Real) as ALL_EPI_Milliman_AVG_TP_REAL,
		sum(CMS_TARGET_PRICE_REAL) as ALL_EPI_CMS_TP_REAL,
		sum(Milliman_Target_Price_Real) as ALL_EPI_Milliman_TP_REAL,
		sum(Milliman_Target_Price_Real)-sum(CMS_TARGET_PRICE_REAL) as ALL_EPI_DIFF_TP_REAL,
		sum(Milliman_NPRA) as ALL_EPI_Milliman_NPRA,
		sum(CMS_NPRA) as ALL_EPI_CMS_NPRA,
		avg(Prelim_PCMA) as ALL_EPI_AVG_Prelim_PCMA,
		avg(Final_PCMA) as ALL_EPI_AVG_Final_PCMA
	from recon_pre9
	group by BPID;
quit;

proc sql;
	create table recon_pre11_all as
	select a.*, b.*
	from recon_clin_all as a left join recon_ALL_EPI_pre_all as b
	on a.BPID=b.BPID;
quit;
*/

proc sql;
	create table recon_pre12 as
	select a.*, b.*
	from recon_pre11 as a left join tp.Recon_Reports_all as b
	on a.BPID=b.INITIATOR_BPID;
quit;


proc sql;
	create table recon_bpid_pre as
	select epi_period_short, BPID,
		sum(Milliman_STD_ALLOWED_Real) as BPID_Milliman_ALLOWED_REAL,
		sum(Milliman_TARGET_PRICE_REAL) as BPID_Milliman_TP_REAL,
		sum(CMS_STD_ALLOWED_Real) as BPID_CMS_ALLOWED_REAL,
		sum(CMS_TARGET_PRICE_REAL) as BPID_CMS_TP_REAL,
		sum(CMS_NPRA) as CMS_Recon_Amount,
		'90%' as CMS_CQS_Adj_Pcnt,
		avg(CQS_Adjustment_Amount) as CMS_CQS_Adj_Amt,
		avg(Adj_Total_Recon_Amount) as CMS_Adjusted_Recon_Amount,
		sum(Milliman_NPRA)  as Milliman_Recon_Amount,
		avg(_20pct_Total_Perf_Target_Amount) as StopLoss_StopGain,
		avg(Cap_Adj_Total_Recon_Amount) as Capped_Adj_Recon_Amt,
		avg(EI_Repayment_Amount) as EI_Repayment_Amt,
		max(case when SRS_Reduction_Agreement_Signed='Y' then 1 else 0 end) as SRS_Reduction_Signed_num,
		avg(Potential_Reduction_Amount) as CMS_Potential_Reduction_Amt
	from recon_pre12
	group by epi_period_short, BPID;
quit;

proc sql;
	create table recon_bpid as
	select a.*, b.*
	from recon_pre12 as a left join recon_bpid_pre as b
	on a.BPID=b.BPID
	and a.epi_period_short = b.epi_period_short;
quit;

proc sql;
create table recon_pre13 as 
	select a.*
		  ,b.BPCI_Episode_Idx
	from recon_bpid as a
	left join bpciaref.BPCIA_DRG_Mapping as b
	on a.ANCHOR_CODE = b.code;
;
quit;
proc sql;
create table recon_pre14 as
  select a.*
          ,b.Clinical_Episode
		  ,b.Short_name as clinical_episode_abbr
		  ,b.Short_name_2 as clinical_episode_abbr2
		  ,strip(BPID)||" - "||strip(b.Short_name) as BPID_ClinicalEp
	from recon_pre13 as a
	left join bpciaref.BPCIA_Clinical_Episode_Names as b
	on a.BPCI_Episode_Idx = b.BPCI_Episode_Index
;
quit;

proc sql;
create table recon_pre15 as
  select a.*
  		 ,b.Facility_or_PGP_name__to_be_used as EI_facility_name
         ,b.Health_system_name as EI_system_name
		 ,propcase(c.fac_name) as Anchor_Facility_Name 
	from recon_pre14 as a
	left join bpciaref.bpcia_episode_initiator_info as b
	on a.BPID = b.BPCI_Advanced_ID_Number_2
	left join ref.ccns_codemap as c
	on a.anchor_ccn = c.ccn
;
quit;

proc sql;
create table recon_pre16a as
  select a.*
  		 ,case when a.anchor_ccn  = "" then "Unknown ()"
		  		when a.anchor_ccn  ^= "" and a.Anchor_Facility_name = "" then "Unknown ("||strip(a.anchor_ccn )||")"
		  		else strip(a.Anchor_facility_name)||" ("||strip(a.anchor_ccn )||")"
				end as Anchor_Fac_Code_Name
  		 , b.Provider_Organization_Name__Leg as at_npi_org_nm 
         , b.provider_first_name as at_npi_first_nm
		 , b.Provider_Last_Name__Legal_Name_ as at_npi_last_nm
		 , c.Provider_Organization_Name__Leg as op_npi_org_nm 
		 , c.provider_first_name as op_npi_first_nm
		 , c.Provider_Last_Name__Legal_Name_ as op_npi_last_nm
	from recon_pre15 as a
		left join ref.npi_data_v2 as b
			on a.ANCHOR_AT_NPI = input(b.npi,best12.)
		left join ref.npi_data_v2 as c
			on a.ANCHOR_OP_NPI = input(c.npi,best12.)
;
quit;

proc sql;
create table recon_pre16b as
	select a.*
			,(Case when stop_loss_stop_gain = 'Y' Then 'Yes' Else 'No' END) AS stop_loss_stop_gain_v2
		  ,case when b.mdc  = "" then "Not Available"
		  		else strip(c.mdc_short_name )||"-"||strip(b.mr_line_desc)
				end as MDC_Description
	from recon_pre16a as a
		left join ref.msdrgs as b
		on strip(a.ANCHOR_CODE) = strip(b.msdrg)
		left join ref.mdc as c
		on b.mdc = c.mdc and b.mdc_desc = c.mdc_desc
;
quit;

data recon_pre20;
	set recon_pre16b;
	drop stop_loss_stop_gain;
	Milliman_Adjusted_Recon_Amount = Milliman_Recon_Amount ;
	if Milliman_Recon_Amount > 0 then Milliman_Adjusted_Recon_Amount = Milliman_Recon_Amount*.9 ;
	DIFF_Adjusted_Recon_Amount = Milliman_Adjusted_Recon_Amount - CMS_Adjusted_Recon_Amount ;

	Milliman_CMS_Episode_Allowed = BPID_Milliman_ALLOWED_REAL / BPID_CMS_ALLOWED_REAL ;
	Milliman_CMS_Target_Price = BPID_Milliman_TP_REAL / BPID_CMS_TP_REAL ;
	Milliman_CMS_Reconciliation_Amt = Milliman_Adjusted_Recon_Amount / CMS_Adjusted_Recon_Amount ;

	client_type=0;
	if BPID in (&PMR_EI_lst.) then client_type=1;

	format NATURAL_DISASTER_CCN_FLAG $3.;
	if NATURAL_DISASTER_CCN_FLAG_num = 1 then NATURAL_DISASTER_CCN_FLAG = 'Yes';
	else NATURAL_DISASTER_CCN_FLAG = 'No';

	format SRS_Reduction_Signed $3.;
	if SRS_Reduction_Signed_num = 1 then SRS_Reduction_Signed = 'Yes';
	else SRS_Reduction_Signed = 'No';

	format operating_npi attending_npi $20. ;
	operating_npi = strip(anchor_op_NPI) ;
	attending_npi = strip(anchor_at_NPI);

	format attending_name operating_name episode_initiator1 $255.;
	if ANCHOR_AT_NPI in ("",".") then attending_name = "" ;
	else if ANCHOR_AT_NPI not in ("",".") and at_npi_last_nm ^= "" then attending_name = strip(propcase(at_npi_last_nm))||", "||strip(propcase(at_npi_first_nm))||" ("||strip(ANCHOR_AT_NPI)||")" ;
	else if ANCHOR_AT_NPI not in ("",".") and at_npi_last_nm = "" and at_npi_org_nm ^= "" then attending_name = strip(propcase(at_npi_org_nm))||" ("||strip(ANCHOR_AT_NPI)||")" ;
	else if ANCHOR_AT_NPI not in ("",".") and at_npi_last_nm = "" and at_npi_org_nm = "" then attending_name = "("||strip(ANCHOR_AT_NPI)||")" ;
	else attending_name = "Unknown ()";
	if ANCHOR_OP_NPI in ("",".") then operating_name = "" ;
	else if ANCHOR_OP_NPI not in ("",".") and op_npi_last_nm ^= "" then operating_name = strip(propcase(op_npi_last_nm))||", "||strip(propcase(op_npi_first_nm))||" ("||strip(ANCHOR_OP_NPI)||")" ;
	else if ANCHOR_OP_NPI not in ("",".") and op_npi_last_nm = "" and op_npi_org_nm ^= "" then operating_name = strip(propcase(op_npi_org_nm))||" ("||strip(ANCHOR_OP_NPI)||")" ;
	else if ANCHOR_OP_NPI not in ("",".") and op_npi_last_nm = "" and op_npi_org_nm = "" then operating_name = "("||strip(ANCHOR_OP_NPI)||")" ;
	else operating_name = "Unknown ()";

	if length(strip(episode_initiator))<=6 then episode_initiator1 = strip(put(episode_initiator,z6.));
		else episode_initiator1 = strip(episode_initiator);

	format Episode_Initiator_Use $76.;
	if Episode_Initiator  = "" then Episode_Initiator_Use="Unknown ()";
		else if Episode_Initiator  ^= "" and EI_facility_name = "" then Episode_Initiator_Use="Unknown ("||strip(Episode_Initiator1 )||")";
		else Episode_Initiator_Use=strip(EI_facility_name)||" ("||strip(BPID)||")";
	drop Episode_Initiator;

	format join_variable_recon $132.;
		join_variable_recon = strip(Measure_year)||"_"||strip(EPI_ID_Milliman);
run;

data recon;
	set recon_pre20;
	drop stop_loss_stop_gain_V2;
	if abs(Adj_Total_Recon_Amount) >= _20pct_Total_Perf_Target_Amount then Multiplier = _20pct_Total_Perf_Target_Amount / abs(Adj_Total_Recon_Amount);
	else Multiplier = 1;
	stop_loss_stop_gain = stop_loss_stop_gain_V2;
	if CMS_Recon_Amount > 0 then Adjust_Recon = CLIN_CMS_NPRA*.9;
	else Adjust_Recon = CLIN_CMS_NPRA;

	Capped_Recon = Adjust_Recon * Multiplier;
run;

data out.Recon_&label._&id.;
	set recon;
	No_Recon=0;
	if BPID in (&norecon.) then do;
		No_Recon=1;
		*AT_PHYS_COSTS=.;
		CCN_DIFF_ALLOWED_REAL=.;
		CCN_DIFF_TP_REAL=.;
		CCN_Milliman_ALLOWED_REAL=.;
		CCN_Milliman_AVG_TP_REAL=.;
		CCN_Milliman_EPI_Count=.;
		CCN_Milliman_TP_REAL=.;
		CLIN_DIFF_ALLOWED_REAL=.;
		CLIN_DIFF_TP_REAL=.;
		CLIN_Milliman_ALLOWED_REAL=.;
		CLIN_Milliman_AVG_TP_REAL=.;
		CLIN_Milliman_EPI_Count=.;
		CLIN_Milliman_TP_REAL=.;
		DIFF_Adjusted_Recon_Amount=.;
		DIFF_STD_ALLOWED_Real=.;
		Milliman_Adjusted_Recon_Amount=.;
		Milliman_CMS_Episode_Allowed=.;
		Milliman_CMS_Reconciliation_Amt=.;
		Milliman_CMS_Target_Price=.;
		*Milliman_NPRA=.;
		Milliman_STD_ALLOWED_Real=.;
		Milliman_Target_Price_Real=.;
		*OP_PHYS_COSTS=.;
		Milliman_CMS_Cost_Match='-';
	end;
run;
%end;
data Epi_Join_&label._&id.;
	format join_variable_recon $132. PERFORMANCE_PERIOD $3.;
	format clinical_episode_abbr $30.;
	format clinical_episode_abbr2 $11.;
	set %if &reconref. = 1 %then %do; 
			out.Recon_&label._&id. (in=b)
			out.epi_detail_&Perf_label._&id. (in=a)
			out.a_epi_detail_ybase_&id. (in=c)
		%end;
		%else %if &reconref. = 0 %then %do; 
			out.epi_detail_&Perf_label._&id. (in=a)
			out.a_epi_detail_ybase_&id. (in=c)
		%end;
		;

	recon_episode=0;
	%if &reconref. = 1 %then %do; 
		if b then recon_episode=1;
	%end;

	perf_episode=0;
	if a or c then do;
		if perf_period_epi_flag = 1 then PERFORMANCE_PERIOD = 'Yes';
			else PERFORMANCE_PERIOD = 'No';

		perf_episode=1;

		join_variable_recon = strip(Measure_year)||"_"||strip(EPI_ID_Milliman);
	end;

	if timeframe_filter  = "Performance Period 1" then epi_period_short = "PP1";
	else if timeframe_filter  = "Performance Period 2" then epi_period_short = "PP2";
	/*
	else if timeframe_filter  = "Performance Period 3" then epi_period_short = "PP3";
	else if timeframe_filter  = "Performance Period 4" then epi_period_short = "PP4";
	else if timeframe_filter  = "Performance Period 5" then epi_period_short = "PP5";
	else if timeframe_filter  = "Performance Period 6" then epi_period_short = "PP6";
	else if timeframe_filter  = "Performance Period 7" then epi_period_short = "PP7";
	else if timeframe_filter  = "Performance Period 8" then epi_period_short = "PP8";
	else if timeframe_filter  = "Performance Period 9" then epi_period_short = "PP9";
	else if timeframe_filter  = "Performance Period 10" then epi_period_short = "PP10";
	*/
	else epi_period_short = "";

	FR_JOIN = BPID||"_"||epi_period_short;

	keep measure_year EPI_ID_Milliman BPID Anchor_Fac_Code_Name ANCHOR_CODE operating_name attending_name client_type Episode_Initiator_Use clinical_episode_abbr timeframe_filter epi_period_short PERFORMANCE_PERIOD 
			join_variable_recon recon_episode perf_episode 
			EI_system_name BPID_ClinicalEp MDC_Description death_flag Episode_End_YearMo PATIENT_NAME Bene_SK FR_JOIN;
run;

proc sql;
	create table recon_epi_check as
	select MEASURE_YEAR, EPI_ID_Milliman, max(recon_episode) as recon_episode, max(perf_episode) as perf_episode 
	from Epi_Join_&label._&id.
	group by MEASURE_YEAR, epi_id_milliman;
quit;

data recon_epi_check2;
	set recon_epi_check;
	format IN_RECON_FLAG $3.;
	IN_RECON_FLAG = 'No';
	if recon_episode=1 and perf_episode=1 then IN_RECON_FLAG = 'Yes';
run;

proc sql;
	create table out.Epi_Join_&label._&id. as
	select b.*, a.*
	from Epi_Join_&label._&id. as a left join recon_epi_check2 as b
	on a.epi_id_milliman=b.epi_id_milliman
	and a.MEASURE_YEAR = b.MEASURE_YEAR;
quit;
	
proc sort nodupkey data=out.Epi_Join_&label._&id.; 
	by MEASURE_YEAR EPI_ID_Milliman;
run;

****************************************************************;

*delete work datasets*;
proc datasets lib=work memtype=data kill;
run;
quit;

%mend ReconDashboard;

*%ReconDashboard(1209_0000,1);
/*
%ReconDashboard(1148,0000,1);
%ReconDashboard(1167,0000,1);
%ReconDashboard(1343,0000,1);
%ReconDashboard(1368,0000,1);
%ReconDashboard(2379,0000,1);
%ReconDashboard(2587,0000,1);
%ReconDashboard(2607,0000,1);
%ReconDashboard(5479,0002,1);
*/

%ReconDashboard(2586_0002,0);
%ReconDashboard(2586_0005,0);
%ReconDashboard(2586_0006,0);
%ReconDashboard(2586_0007,0);
%ReconDashboard(2586_0010,0);
%ReconDashboard(2586_0013,0);
%ReconDashboard(2586_0025,0);
%ReconDashboard(2586_0026,0);
%ReconDashboard(2586_0028,0);
%ReconDashboard(2586_0029,0);
%ReconDashboard(2586_0030,0);
%ReconDashboard(2586_0031,0);
%ReconDashboard(2586_0032,0);
%ReconDashboard(2586_0033,0);
%ReconDashboard(2586_0034,0);
%ReconDashboard(2586_0035,0);
*%ReconDashboard(2586_0036,0);
*%ReconDashboard(2586_0038,0);
%ReconDashboard(2586_0039,0);
*%ReconDashboard(2586_0040,0);
*%ReconDashboard(2586_0041,0);
*%ReconDashboard(2586_0042,0);
*%ReconDashboard(2586_0043,0);
%ReconDashboard(2586_0044,0);
%ReconDashboard(2586_0045,0);
%ReconDashboard(2586_0046,0);
%ReconDashboard(1374_0004,1);
%ReconDashboard(1374_0008,1);
%ReconDashboard(1374_0009,1);
%ReconDashboard(1374_0012,0);
%ReconDashboard(1374_0013,0);
%ReconDashboard(1374_0014,0);
%ReconDashboard(1374_0015,0);
%ReconDashboard(1374_0017,0);
%ReconDashboard(1374_0018,0);
%ReconDashboard(1191_0002,1);
%ReconDashboard(7310_0002,0);
%ReconDashboard(7310_0003,0);
%ReconDashboard(7310_0004,0);
%ReconDashboard(7310_0005,0);
%ReconDashboard(7310_0006,0);
%ReconDashboard(7310_0007,0);
%ReconDashboard(7312_0002,0);
%ReconDashboard(6054_0002,1);
%ReconDashboard(6055_0002,1);
%ReconDashboard(6056_0002,1);
%ReconDashboard(6057_0002,1);
%ReconDashboard(6058_0002,1);
%ReconDashboard(6059_0002,1);
%ReconDashboard(1209_0000,1);
%ReconDashboard(1028_0000,0);
%ReconDashboard(1075_0000,1);
%ReconDashboard(1102_0000,1);
%ReconDashboard(1103_0000,1);
%ReconDashboard(1104_0000,1);
%ReconDashboard(1105_0000,1);
%ReconDashboard(1106_0000,1);
%ReconDashboard(1148_0000,1);
%ReconDashboard(1167_0000,1);
%ReconDashboard(1343_0000,1);
%ReconDashboard(1368_0000,1);
%ReconDashboard(1461_0000,0);
%ReconDashboard(1634_0000,1);
*%ReconDashboard(1803_0000,0);
%ReconDashboard(1958_0000,1);
%ReconDashboard(2048_0000,1);
%ReconDashboard(2049_0000,1);
%ReconDashboard(2070_0000,1);
%ReconDashboard(2214_0000,0);
%ReconDashboard(2215_0000,0);
%ReconDashboard(2216_0000,0);
%ReconDashboard(2302_0000,1);
%ReconDashboard(2317_0000,0);
%ReconDashboard(2374_0000,1);
%ReconDashboard(2376_0000,1);
%ReconDashboard(2378_0000,1);
%ReconDashboard(2379_0000,1);
%ReconDashboard(2451_0000,0);
%ReconDashboard(2452_0000,0);
%ReconDashboard(2461_0000,0);
%ReconDashboard(2468_0000,0);
%ReconDashboard(2587_0000,1);
%ReconDashboard(2589_0000,1);
%ReconDashboard(2594_0000,1);
%ReconDashboard(2607_0000,1);
%ReconDashboard(5037_0000,1);
%ReconDashboard(5038_0000,1);
%ReconDashboard(5043_0000,1);
%ReconDashboard(5050_0000,1);
%ReconDashboard(5154_0000,1);
%ReconDashboard(5215_0002,1);
%ReconDashboard(5215_0003,1);
%ReconDashboard(5229_0000,1);
%ReconDashboard(5263_0000,1);
%ReconDashboard(5264_0000,1);
%ReconDashboard(5282_0000,1);
%ReconDashboard(5392_0004,1);
%ReconDashboard(5394_0000,1);
%ReconDashboard(5395_0000,1);
%ReconDashboard(5397_0002,1);
%ReconDashboard(5397_0003,1);
%ReconDashboard(5397_0004,1);
%ReconDashboard(5397_0005,1);
%ReconDashboard(5397_0006,1);
%ReconDashboard(5397_0007,1);
%ReconDashboard(5397_0008,1);
%ReconDashboard(5397_0009,1);
%ReconDashboard(5397_0010,1);
%ReconDashboard(5478_0002,1);
%ReconDashboard(5479_0002,1);
%ReconDashboard(5480_0002,1);
%ReconDashboard(5481_0002,1);
%ReconDashboard(5746_0002,1);
%ReconDashboard(1686_0002,1);
%ReconDashboard(1688_0002,1);
%ReconDashboard(1696_0002,1);
%ReconDashboard(1710_0002,1);
%ReconDashboard(2941_0002,0);
%ReconDashboard(2956_0002,0);
%ReconDashboard(6049_0002,1);
%ReconDashboard(6050_0002,1);
%ReconDashboard(6051_0002,1);
%ReconDashboard(6052_0002,1);
%ReconDashboard(6053_0002,1);
%ReconDashboard(2974_0003,0);
%ReconDashboard(2974_0007,0);



data out.All_Recon_&label. out.All_Recon_pmr_&label. out.All_Recon_oth_&label. out.All_Recon_ccf_&label.;
	set out.Recon_&label._: ;
	output out.All_Recon_&label.;
	if BPID in (&PMR_EI_lst.) then output out.All_Recon_pmr_&label.;
	else if BPID in (&NON_PMR_EI_lst.) then output out.All_Recon_oth_&label.;
	else if BPID in (&CCF_lst.) then output out.All_Recon_ccf_&label.;
run;

data out.All_Epi_Join_&label. out.All_Epi_Join_pmr_&label. out.All_Epi_Join_oth_&label. out.All_Epi_Join_ccf_&label.;
	set out.Epi_Join_&label._: ;
	output out.All_Epi_Join_&label.;
	if BPID in (&PMR_EI_lst.) then output out.All_Epi_Join_pmr_&label.;
	else if BPID in (&NON_PMR_EI_lst.) then output out.All_Epi_Join_oth_&label.;
	else if BPID in (&CCF_lst.) then output out.All_Epi_Join_ccf_&label.;
run;

%sas_2_csv(out.All_Recon_&label.,Recon.csv);
%sas_2_csv(out.All_Epi_Join_&label.,Epi_Detail_Recon_Join.csv);
%sas_2_csv(out.All_Recon_pmr_&label.,Recon_pmr.csv);
%sas_2_csv(out.All_Epi_Join_pmr_&label.,Epi_Detail_Recon_Join_pmr.csv);
%sas_2_csv(out.All_Recon_oth_&label.,Recon_oth.csv);
%sas_2_csv(out.All_Epi_Join_oth_&label.,Epi_Detail_Recon_Join_oth.csv);
%sas_2_csv(out.All_Recon_ccf_&label.,Recon_ccf.csv);
%sas_2_csv(out.All_Epi_Join_ccf_&label.,Epi_Detail_Recon_Join_ccf.csv);

/*
******************* Create Demo Output *************************;
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

%macro RunHosp(bpid1,bpid2);

data out3.Recon_&bpid1._&bpid2.;
	set out.Recon_&label._&bpid1._&bpid2. (rename=(BPID=BPID_o));

	BPID = put(BPID_o,$masked_bpid.);

	BENE_SK = 123456789;
	MBI_ID="987654321";

	if BENE_GENDER="Female" then BENE_GENDER="F";
	else if BENE_GENDER="Male" then BENE_GENDER="M";

	BPID_ClinicalEp = strip(BPID)||" - "||strip(clinical_episode_abbr);
	BPID_ClinicalEp_ccn = strip(BPID)||" - "||strip(clinical_episode_abbr)||" - "||strip(anchor_ccn);

	join_variable_recon = strip(Measure_year)||"_"||strip(EPI_ID_Milliman);

	format ANCHOR_BEG_DT0 ANCHOR_END_DT0 DOD0 BENE_DOB0 mmddyy10. ; 
	ANCHOR_BEG_DT0 = ANCHOR_BEG_DT ; 
	ANCHOR_END_DT0 = ANCHOR_END_DT ; 
	DOD0 = DOD ; 
	BENE_DOB0 = BENE_DOB ; 

anchor_beg_dt = intnx('year',intnx('day', ANCHOR_BEG_DT, floor(ranuni(7)*60)),10,'sameday');	
 increment = anchor_beg_dt - ANCHOR_BEG_DT0;

  	%macro date(date);
		&date. = &date.0 + increment;
	%mend date;

	%date(anchor_end_dt);
	%date(DOD);
run;

data Epi_Join_&bpid1._&bpid2.;
	format join_variable_recon $132. PERFORMANCE_PERIOD $3.;
	set out3.Recon_&bpid1._&bpid2. (in=b)
		out.epi_detail_&Perf_label._&bpid1._&bpid2. (in=a)
		out.epi_detail_ybase_&bpid1._&bpid2. (in=c)
		;

	recon_episode=0;
	if b then recon_episode=1;

	perf_episode=0;
	if a or c then do;
		if perf_period_epi_flag = 1 then PERFORMANCE_PERIOD = 'Yes';
			else PERFORMANCE_PERIOD = 'No';

		perf_episode=1;

		BPID = put(BPID,$masked_bpid.);

		if BENE_GENDER="Female" then BENE_GENDER="F";
		else if BENE_GENDER="Male" then BENE_GENDER="M";

		BENE_SK = 123456789;
		MBI_ID="987654321";

		BPID_ClinicalEp = strip(BPID)||" - "||strip(clinical_episode_abbr);
		BPID_ClinicalEp_ccn = strip(BPID)||" - "||strip(clinical_episode_abbr)||" - "||strip(anchor_ccn);

		join_variable_recon = strip(Measure_year)||"_"||strip(EPI_ID_Milliman);
	end;

	if timeframe_filter  = "Performance Period 1" then epi_period_short = "PP1";
	else if timeframe_filter  = "Performance Period 2" then epi_period_short = "PP2";
	
	*else if timeframe_filter  = "Performance Period 3" then epi_period_short = "PP3";
	*else if timeframe_filter  = "Performance Period 4" then epi_period_short = "PP4";
	*else if timeframe_filter  = "Performance Period 5" then epi_period_short = "PP5";
	*else if timeframe_filter  = "Performance Period 6" then epi_period_short = "PP6";
	*else if timeframe_filter  = "Performance Period 7" then epi_period_short = "PP7";
	*else if timeframe_filter  = "Performance Period 8" then epi_period_short = "PP8";
	*else if timeframe_filter  = "Performance Period 9" then epi_period_short = "PP9";
	*else if timeframe_filter  = "Performance Period 10" then epi_period_short = "PP10";
	
	else epi_period_short = "";

	keep measure_year EPI_ID_Milliman BPID Anchor_Fac_Code_Name ANCHOR_CODE operating_name attending_name client_type Episode_Initiator_Use clinical_episode_abbr timeframe_filter epi_period_short PERFORMANCE_PERIOD 
			join_variable_recon recon_episode perf_episode
			EI_system_name BPID_ClinicalEp MDC_Description death_flag Episode_End_YearMo PATIENT_NAME Bene_SK;
run;

proc sql;
	create table recon_epi_check as
	select EPI_ID_Milliman, max(recon_episode) as recon_episode, max(perf_episode) as perf_episode 
	from Epi_Join_&bpid1._&bpid2.
	group by epi_id_milliman;
quit;

data recon_epi_check2;
	set recon_epi_check;
	format IN_RECON_FLAG $3.;

	IN_RECON_FLAG = 'No';
	if recon_episode=1 and perf_episode=1 then IN_RECON_FLAG = 'Yes';
run;

proc sql;
	create table out3.Epi_Join_&bpid1._&bpid2. as
	select b.*, a.*
	from Epi_Join_&bpid1._&bpid2. as a left join recon_epi_check2 as b
	on a.epi_id_milliman=b.epi_id_milliman;
quit;
	
proc sort nodupkey data=out3.Epi_Join_&bpid1._&bpid2.; 
	by EPI_ID_Milliman;

%mend;

%runhosp(1148,0000);
%runhosp(1167,0000);
%runhosp(1343,0000);
%runhosp(1368,0000);
%runhosp(2379,0000);
%runhosp(2587,0000);
%runhosp(2607,0000);
%runhosp(5479,0002);

data out3.All_Recon_Demo;
	set out3.Recon_: ;
run;

data out3.All_Epi_Join_Demo;
	set out3.Epi_Join_: ;
run;

%sas_2_csv(out3.All_Recon_Demo,Recon_Demo.csv);
%sas_2_csv(out3.All_Epi_Join_Demo,Epi_Detail_Recon_Join_Demo.csv);
*/
proc printto;run;
%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;
