%let  _sdtm=%sysfunc(datetime());
*********************************************************
*********************************************************
BPCIA: 201_Target Prices
Code to calculate target prices
*********************************************************
*********************************************************;
options mprint;

proc printto;run;
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\201 - Target Prices_&sysdate..log" print=print new;
run;

****** REFERENCE PROGRAMS ***********************************************************************************;
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";

%let main = H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code;
%include "&main.\000 - Formats - BPCIA.sas";

%include "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code\000 - BPCIA_Interface_BPIDs.sas";

****** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
libname out "&dataDir.\07 - Processed Data";
libname out2 "&dataDir.\07 - Processed Data\Output";
libname tp "&dataDir.\08 - Target Price Data";

libname ref "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets" ;

%let transmit_date = '04APR2019'd; *Change for every Update*;


********************
********************
Calculation of Adjusted Target Prices
********************
********************;

data Peer_Group_pre Peer_Group_pre_baseline;
	set tp.Peer_Group_all;
	format ccn_join $6.;
	ccn_join = CCN;
	if length(compress(ccn_join)) = 5 then ccn_join = '0' || ccn_join;

	output Peer_Group_pre;
	if epi_dropped_flag = 1 then output Peer_Group_pre_baseline;
run; 

proc sort data=Peer_Group_pre;
	by ccn_join descending rel_dt descending epi_start descending epi_end;
run;

proc sort nodupkey data=Peer_Group_pre out=Peer_Group;
	by ccn_join rel_dt epi_start epi_end;
run;

proc sort nodupkey data=Peer_Group_pre out=Peer_Group_forBase;
	by ccn_join;
run;

proc sort nodupkey data=Peer_Group_pre_baseline out=Peer_Group_baseline;
	by ccn_join rel_dt epi_start epi_end;
run;

data PAT_Factors;
	set ref.PAT_Factors;
	anchor_type='ip';
	if substr(Clinical_Episode,1,2) = 'OP' then anchor_type='op';
	if anchor_type='op' then do;
		if Clinical_Episode = 'OP - Back & neck except spinal fusion' then Clinical_Episode = 'Back & neck except spinal fusion';
		if Clinical_Episode = 'OP - Cardiac defibrillator' then Clinical_Episode = 'Cardiac defibrillator';
		if Clinical_Episode = 'OP - Percutaneous coronary intervention' then Clinical_Episode = 'Percutaneous coronary intervention';
	end;

	if Clinical_Episode = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		Clinical_Episode = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;
run;

proc sort nodupkey data=PAT_Factors out=PAT_Factors_forBase;
	by Clinical_Episode anchor_type AMC Urban_Rural Safety_Net Bed_Size Census_Div Year Quarter;
run;

data PAT_Factors_baseline;
	set ref.PAT_Factors_baseline;
	anchor_type='ip';
	if substr(Clinical_Episode,1,2) = 'OP' then anchor_type='op';
	if anchor_type='op' then do;
		if Clinical_Episode = 'OP - Back & neck except spinal fusion' then Clinical_Episode = 'Back & neck except spinal fusion';
		if Clinical_Episode = 'OP - Cardiac defibrillator' then Clinical_Episode = 'Cardiac defibrillator';
		if Clinical_Episode = 'OP - Percutaneous coronary intervention' then Clinical_Episode = 'Percutaneous coronary intervention';
	end;

	if Clinical_Episode = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		Clinical_Episode = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;
run;

data TP_Components;
	set tp.TP_Components_all;
	format ccn_join $6.;
	ccn_join = ASSOC_ACH_CCN;
	if ccn_join = '' then ccn_join = CCN_TIN;
	if length(compress(ccn_join)) = 5 then ccn_join = '0' || ccn_join;

	if EPI_CAT = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPI_CAT = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

run; 

proc sort data=TP_Components;
	by INITIATOR_BPID EPI_CAT EPI_TYPE ccn_join descending rel_dt descending epi_start descending epi_end;
run;

proc sort nodupkey data=TP_Components out=TP_Components_forBase;
	by INITIATOR_BPID EPI_CAT EPI_TYPE ccn_join;
run;

proc sort nodupkey data=TP_Components;
	by INITIATOR_BPID EPI_CAT EPI_TYPE ccn_join rel_dt epi_start epi_end;
run;

data TP_Risk_Adj_Parameters;
	set ref.TP_Risk_Adj_Parameters;

	if Clinical_Episode_Category = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		Clinical_Episode_Category = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;
run;

proc sort nodupkey data=TP_Risk_Adj_Parameters out=TP_Risk_Adj_Parameters_forBase;
	by Clinical_Episode_Category Clinical_Episode_Type;
run;

data TP_Risk_Adj_Parameters_baseline;
	set ref.TP_Risk_Adj_Parameters_baseline;

	if Clinical_Episode_Category = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		Clinical_Episode_Category = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;
run;

%MACRO TP(label);

%MACRO RunHosp(id1,id2,bpid1,bpid2,prov);

data temp0;
	format BPID $9. EPI_ID_MILLIMAN $32. ;
	set out.epi_&label._&bpid1._&bpid2. ;

	if EPISODE_GROUP_NAME = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPISODE_GROUP_NAME = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

	if ANCHOR_TYPE = 'ip' then anchor_type_upper = 'IP';
	else if ANCHOR_TYPE = 'op' then anchor_type_upper = 'OP';
	else anchor_type_upper = ANCHOR_TYPE;

	drop EPI_DROPPED_FLAG;
run;

proc sql;
	create table temp1_pre as
	select a.*, b.EPI_DROPPED_FLAG
	from temp0 as a 
		left join TP_Components_forBase as b
			on a.BPID = b.INITIATOR_BPID
			and a.EPISODE_GROUP_NAME = b.EPI_CAT
			and a.anchor_type_upper = b.EPI_TYPE
			and a.anc_ccn = b.ccn_join;
quit;

data temp1_prea temp1_preb;
	set temp1_pre;
	if EPI_DROPPED_FLAG = 0 then output temp1_prea;
	else output temp1_preb;
run;

%if &label. ^= ybase %then %do;
	proc sql;
		create table temp1a_pre as
		select a.*, b.ACADEMIC, b.URBAN_RURAL, b.SAFETY_NET, b.BED_SIZE, b.CENSUS as CENSUS_Pre
		from temp1_prea as a left join Peer_Group as b
		on a.anc_ccn = b.ccn_join
			and b.epi_start <= a.ANCHOR_BEG_DT <= b.epi_end;
	quit;
%end;
%else %do;
	proc sql;
		create table temp1a_pre as
		select a.*, b.ACADEMIC, b.URBAN_RURAL, b.SAFETY_NET, b.BED_SIZE, b.CENSUS as CENSUS_Pre
		from temp1_prea as a left join Peer_Group_forBase as b
		on a.anc_ccn = b.ccn_join;
	quit;
%end;

data temp1a;
	set temp1a_pre;
	CENSUS = input(CENSUS_Pre,12.);
run;

%if &label. ^= ybase %then %do;
	proc sql;
		create table temp2a as
		select a.*, b.*
		from temp1a as a left join TP_Risk_Adj_Parameters as b
		on a.EPISODE_GROUP_NAME = b.Clinical_Episode_Category
			and a.anchor_type_upper = b.Clinical_Episode_Type
			and b.epi_start <= a.ANCHOR_BEG_DT <= b.epi_end;
	quit;
%end;
%else %do;
proc sql;
		create table temp2a as
		select a.*, b.*
		from temp1a as a left join TP_Risk_Adj_Parameters_forBase as b
		on a.EPISODE_GROUP_NAME = b.Clinical_Episode_Category
			and a.anchor_type_upper = b.Clinical_Episode_Type;
	quit;
%end;

%if &label. ^= ybase %then %do;
	proc sql;
		create table temp3a_pre as
		select a.*, b.PAT_Factor as PAT_New
		from temp2a as a left join PAT_Factors as b
		on a.EPISODE_GROUP_NAME = b.Clinical_Episode
			and a.ANCHOR_TYPE=b.anchor_type
			and a.ACADEMIC=b.AMC
			and a.URBAN_RURAL=b.Urban_Rural
			and a.SAFETY_NET=b.Safety_Net
			and a.BED_SIZE=b.Bed_Size
			and a.CENSUS=b.Census_Div
			and year(a.POST_DSCH_END_DT)=b.Year
			and qtr(a.POST_DSCH_END_DT)=b.Quarter
			and b.epi_start <= a.ANCHOR_BEG_DT <= b.epi_end;
	quit;

	proc sql;
		create table temp3a as
		select a.*, b.PAT_Factor as PAT_2019Q3
		from temp3a_pre as a left join PAT_Factors as b
		on a.EPISODE_GROUP_NAME = b.Clinical_Episode
			and a.ANCHOR_TYPE=b.anchor_type
			and a.ACADEMIC=b.AMC
			and a.URBAN_RURAL=b.Urban_Rural
			and a.SAFETY_NET=b.Safety_Net
			and a.BED_SIZE=b.Bed_Size
			and a.CENSUS=b.Census_Div
			and b.Year=2019
			and b.Quarter=3
			and b.epi_start <= a.ANCHOR_BEG_DT <= b.epi_end;
	quit;
%end;
%else %do;
	proc sql;
		create table temp3a_pre as
		select a.*, b.PAT_Factor as PAT_New
		from temp2a as a left join PAT_Factors_forBase as b
		on a.EPISODE_GROUP_NAME = b.Clinical_Episode
			and a.ANCHOR_TYPE=b.anchor_type
			and a.ACADEMIC=b.AMC
			and a.URBAN_RURAL=b.Urban_Rural
			and a.SAFETY_NET=b.Safety_Net
			and a.BED_SIZE=b.Bed_Size
			and a.CENSUS=b.Census_Div
			and year(a.POST_DSCH_END_DT)=b.Year
			and qtr(a.POST_DSCH_END_DT)=b.Quarter;
	quit;

	proc sql;
		create table temp3a as
		select a.*, b.PAT_Factor as PAT_2019Q3
		from temp3a_pre as a left join PAT_Factors_forBase as b
		on a.EPISODE_GROUP_NAME = b.Clinical_Episode
			and a.ANCHOR_TYPE=b.anchor_type
			and a.ACADEMIC=b.AMC
			and a.URBAN_RURAL=b.Urban_Rural
			and a.SAFETY_NET=b.Safety_Net
			and a.BED_SIZE=b.Bed_Size
			and a.CENSUS=b.Census_Div
			and b.Year=2019
			and b.Quarter=3;
	quit;
%end;

%if &label. ^= ybase %then %do;
	proc sql;
		create table temp4a as
		select a.*, 
			b.PGP_ACH,
			b.CCN_TIN,
			b.ASSOC_ACH_CCN,
			b.CCN_JOIN,
			b.EPI_TYPE,
			b.EPI_CAT,
			b.EPI_COUNT,
			b.COUNT_GT_40,
			b.EPI_CAT_ADJ,
			b.EPI_CAT_SHORT,
			b.EPI_CAT_2,
			b.EPI_SPEND,
			b.AMT,
			b.ACH_EFF,
			b.SBS,
			b.PCMA,
			b.PAT,
			b.HBP,
			b.PGP_EFF,
			b.PGP_OFFSET,
			b.PGP_OFFSET_ADJ,
			b.PGP_ACH_PCMA,
			b.CASE_MIX,
			b.PGP_ACH_BNCHMRK,
			b.TARGET_PRICE,
			b.PAYMENT_RATIO,
			b.TARGET_PRICE_REAL,
			b.EPI_INDEX,
			b.BPID_CHANGE,
			b.EPI_DROPPED_FLAG,
			b.TIME_PERIOD
		from temp3a as a 
			left join TP_Components as b
				on a.BPID = b.INITIATOR_BPID
				and a.EPISODE_GROUP_NAME = b.EPI_CAT
				and a.anchor_type_upper = b.EPI_TYPE
				and a.anc_ccn = b.ccn_join
				and b.epi_start <= a.ANCHOR_BEG_DT <= b.epi_end;
	quit;
%end;
%else %do;
proc sql;
		create table temp4a as
		select a.*, 
			b.PGP_ACH,
			b.CCN_TIN,
			b.ASSOC_ACH_CCN,
			b.CCN_JOIN,
			b.EPI_TYPE,
			b.EPI_CAT,
			b.EPI_COUNT,
			b.COUNT_GT_40,
			b.EPI_CAT_ADJ,
			b.EPI_CAT_SHORT,
			b.EPI_CAT_2,
			b.EPI_SPEND,
			b.AMT,
			b.ACH_EFF,
			b.SBS,
			b.PCMA,
			b.PAT,
			b.HBP,
			b.PGP_EFF,
			b.PGP_OFFSET,
			b.PGP_OFFSET_ADJ,
			b.PGP_ACH_PCMA,
			b.CASE_MIX,
			b.PGP_ACH_BNCHMRK,
			b.TARGET_PRICE,
			b.PAYMENT_RATIO,
			b.TARGET_PRICE_REAL,
			b.EPI_INDEX,
			b.BPID_CHANGE,
			b.EPI_DROPPED_FLAG,
			b.TIME_PERIOD
		from temp3a as a 
			left join TP_Components_forBase as b
				on a.BPID = b.INITIATOR_BPID
				and a.EPISODE_GROUP_NAME = b.EPI_CAT
				and a.anchor_type_upper = b.EPI_TYPE
				and a.anc_ccn = b.ccn_join;
	quit;
%end;

data temp5a;
	set temp4a;
	format DRG_CODE BEST12.;
	%if &label. = ybase %then %do; 
		DRG_CODE=DRG_2018; 
	%end;
	%else %do;
		if ANCHOR_TYPE = 'ip' then DRG_CODE = input(ANCHOR_CODE,$20.);
		else DRG_CODE = . ;
	%end;

	Epi_Year = year(POST_DSCH_END_DT);
	Epi_Qtr = qtr(POST_DSCH_END_DT);
	Epi_Half = 1;
	if Epi_Qtr in (3,4) then Epi_Half = 2;

	DRG_CD_062=0;
	DRG_CD_063=0;
	DRG_CD_064=0;
	DRG_CD_065=0;
	DRG_CD_066=0;
	DRG_CD_178=0;
	DRG_CD_179=0;
	DRG_CD_191=0;
	DRG_CD_192=0;
	DRG_CD_193=0;
	DRG_CD_194=0;
	DRG_CD_195=0;
	DRG_CD_202=0;
	DRG_CD_203=0;
	DRG_CD_217=0;
	DRG_CD_218=0;
	DRG_CD_219=0;
	DRG_CD_220=0;
	DRG_CD_221=0;
	DRG_CD_223=0;
	DRG_CD_224=0;
	DRG_CD_225=0;
	DRG_CD_226=0;
	DRG_CD_227=0;
	DRG_CD_232=0;
	DRG_CD_233=0;
	DRG_CD_234=0;
	DRG_CD_235=0;
	DRG_CD_236=0;
	DRG_CD_243=0;
	DRG_CD_244=0;
	DRG_CD_247=0;
	DRG_CD_248=0;
	DRG_CD_249=0;
	DRG_CD_250=0;
	DRG_CD_251=0;
	DRG_CD_266=0;
	DRG_CD_267=0;
	DRG_CD_273=0;
	DRG_CD_274=0;
	DRG_CD_281=0;
	DRG_CD_282=0;
	DRG_CD_292=0;
	DRG_CD_293=0;
	DRG_CD_309=0;
	DRG_CD_310=0;
	DRG_CD_330=0;
	DRG_CD_331=0;
	DRG_CD_378=0;
	DRG_CD_379=0;
	DRG_CD_389=0;
	DRG_CD_390=0;
	DRG_CD_442=0;
	DRG_CD_443=0;
	DRG_CD_454=0;
	DRG_CD_455=0;
	DRG_CD_460=0;
	DRG_CD_462=0;
	DRG_CD_470=0;
	DRG_CD_472=0;
	DRG_CD_473=0;
	DRG_CD_481=0;
	DRG_CD_482=0;
	DRG_CD_493=0;
	DRG_CD_494=0;
	DRG_CD_519=0;
	DRG_CD_520=0;
	DRG_CD_534=0;
	DRG_CD_535=0;
	DRG_CD_536=0;
	DRG_CD_603=0;
	DRG_CD_683=0;
	DRG_CD_684=0;
	DRG_CD_690=0;
	DRG_CD_871=0;
	DRG_CD_872=0;
	APC_5193=0;
	APC_5194=0;
	APC_5232=0;
	APC_5432=0;

	if DRG_CODE = 062 then DRG_CD_062=1;
	if DRG_CODE = 063 then DRG_CD_063=1;
	if DRG_CODE = 064 then DRG_CD_064=1;
	if DRG_CODE = 065 then DRG_CD_065=1;
	if DRG_CODE = 066 then DRG_CD_066=1;
	if DRG_CODE = 178 then DRG_CD_178=1;
	if DRG_CODE = 179 then DRG_CD_179=1;
	if DRG_CODE = 191 then DRG_CD_191=1;
	if DRG_CODE = 192 then DRG_CD_192=1;
	if DRG_CODE = 193 then DRG_CD_193=1;
	if DRG_CODE = 194 then DRG_CD_194=1;
	if DRG_CODE = 195 then DRG_CD_195=1;
	if DRG_CODE = 202 then DRG_CD_202=1;
	if DRG_CODE = 203 then DRG_CD_203=1;
	if DRG_CODE = 217 then DRG_CD_217=1;
	if DRG_CODE = 218 then DRG_CD_218=1;
	if DRG_CODE = 219 then DRG_CD_219=1;
	if DRG_CODE = 220 then DRG_CD_220=1;
	if DRG_CODE = 221 then DRG_CD_221=1;
	if DRG_CODE = 223 then DRG_CD_223=1;
	if DRG_CODE = 224 then DRG_CD_224=1;
	if DRG_CODE = 225 then DRG_CD_225=1;
	if DRG_CODE = 226 then DRG_CD_226=1;
	if DRG_CODE = 227 then DRG_CD_227=1;
	if DRG_CODE = 232 then DRG_CD_232=1;
	if DRG_CODE = 233 then DRG_CD_233=1;
	if DRG_CODE = 234 then DRG_CD_234=1;
	if DRG_CODE = 235 then DRG_CD_235=1;
	if DRG_CODE = 236 then DRG_CD_236=1;
	if DRG_CODE = 243 then DRG_CD_243=1;
	if DRG_CODE = 244 then DRG_CD_244=1;
	if DRG_CODE = 247 then DRG_CD_247=1;
	if DRG_CODE = 248 then DRG_CD_248=1;
	if DRG_CODE = 249 then DRG_CD_249=1;
	if DRG_CODE = 250 then DRG_CD_250=1;
	if DRG_CODE = 251 then DRG_CD_251=1;
	if DRG_CODE = 266 then DRG_CD_266=1;
	if DRG_CODE = 267 then DRG_CD_267=1;
	if DRG_CODE = 273 then DRG_CD_273=1;
	if DRG_CODE = 274 then DRG_CD_274=1;
	if DRG_CODE = 281 then DRG_CD_281=1;
	if DRG_CODE = 282 then DRG_CD_282=1;
	if DRG_CODE = 292 then DRG_CD_292=1;
	if DRG_CODE = 293 then DRG_CD_293=1;
	if DRG_CODE = 309 then DRG_CD_309=1;
	if DRG_CODE = 310 then DRG_CD_310=1;
	if DRG_CODE = 330 then DRG_CD_330=1;
	if DRG_CODE = 331 then DRG_CD_331=1;
	if DRG_CODE = 378 then DRG_CD_378=1;
	if DRG_CODE = 379 then DRG_CD_379=1;
	if DRG_CODE = 389 then DRG_CD_389=1;
	if DRG_CODE = 390 then DRG_CD_390=1;
	if DRG_CODE = 442 then DRG_CD_442=1;
	if DRG_CODE = 443 then DRG_CD_443=1;
	if DRG_CODE = 454 then DRG_CD_454=1;
	if DRG_CODE = 455 then DRG_CD_455=1;
	if DRG_CODE = 460 then DRG_CD_460=1;
	if DRG_CODE = 462 then DRG_CD_462=1;
	if DRG_CODE = 470 then DRG_CD_470=1;
	if DRG_CODE = 472 then DRG_CD_472=1;
	if DRG_CODE = 473 then DRG_CD_473=1;
	if DRG_CODE = 481 then DRG_CD_481=1;
	if DRG_CODE = 482 then DRG_CD_482=1;
	if DRG_CODE = 493 then DRG_CD_493=1;
	if DRG_CODE = 494 then DRG_CD_494=1;
	if DRG_CODE = 519 then DRG_CD_519=1;
	if DRG_CODE = 520 then DRG_CD_520=1;
	if DRG_CODE = 534 then DRG_CD_534=1;
	if DRG_CODE = 535 then DRG_CD_535=1;
	if DRG_CODE = 536 then DRG_CD_536=1;
	if DRG_CODE = 603 then DRG_CD_603=1;
	if DRG_CODE = 683 then DRG_CD_683=1;
	if DRG_CODE = 684 then DRG_CD_684=1;
	if DRG_CODE = 690 then DRG_CD_690=1;
	if DRG_CODE = 871 then DRG_CD_871=1;
	if DRG_CODE = 872 then DRG_CD_872=1;
	if PERF_APC = 5193 then APC_5193=1;
	if PERF_APC = 5194 then APC_5194=1;
	if PERF_APC = 5232 then APC_5232=1;
	if PERF_APC = 5432 then APC_5432=1;

	HCC_CNT = sum(of HCC1 -- HCC189);
	HCC_CNT_1_3=0;
	HCC_CNT_4_6=0;
	HCC_CNT_7_PLUS=0;
	if HCC_CNT > 0 then do;
		if HCC_CNT <= 3 then HCC_CNT_1_3=1;
		else if HCC_CNT <= 6 then HCC_CNT_4_6=1;
		else if HCC_CNT >= 7 then HCC_CNT_7_PLUS=1;
	end; 


Pred_Price = (N1_P1 * EXP(
		  (BENE_AGE-50) * N1_Age_50
		+ (BENE_AGE-50) * (BENE_AGE-50) * N1_Age_50_SQ
		+ ANY_DUAL * N1_ANY_DUAL
		+ APC_5193 * N1_APC_5193
		+ APC_5194 * N1_APC_5194
		+ APC_5232 * N1_APC_5232
		+ APC_5432 * N1_APC_5432
		+ CANCER_IMMUNE * N1_CANCER_IMMUNE
		+ CHF_COPD * N1_CHF_COPD
		+ CHF_RENAL * N1_CHF_RENAL
		+ COPD_CARD_RESP_FAIL * N1_COPD_CARD_RESP_FAIL
		+ DIABETES_CHF * N1_DIABETES_CHF
		+ DISABLED_HCC110 * N1_DISABLED_HCC110
		+ DISABLED_HCC176 * N1_DISABLED_HCC176
		+ DISABLED_HCC34 * N1_DISABLED_HCC34
		+ DISABLED_HCC46 * N1_DISABLED_HCC46
		+ DISABLED_HCC54 * N1_DISABLED_HCC54
		+ DISABLED_HCC55 * N1_DISABLED_HCC55
		+ DISABLED_HCC6 * N1_DISABLED_HCC6
		+ DRG_CD_062 * N1_DRG_CD_062
		+ DRG_CD_063 * N1_DRG_CD_063
		+ DRG_CD_064 * N1_DRG_CD_064
		+ DRG_CD_065 * N1_DRG_CD_065
		+ DRG_CD_066 * N1_DRG_CD_066
		+ DRG_CD_178 * N1_DRG_CD_178
		+ DRG_CD_179 * N1_DRG_CD_179
		+ DRG_CD_191 * N1_DRG_CD_191
		+ DRG_CD_192 * N1_DRG_CD_192
		+ DRG_CD_193 * N1_DRG_CD_193
		+ DRG_CD_194 * N1_DRG_CD_194
		+ DRG_CD_195 * N1_DRG_CD_195
		+ DRG_CD_202 * N1_DRG_CD_202
		+ DRG_CD_203 * N1_DRG_CD_203
		+ DRG_CD_217 * N1_DRG_CD_217
		+ DRG_CD_218 * N1_DRG_CD_218
		+ DRG_CD_219 * N1_DRG_CD_219
		+ DRG_CD_220 * N1_DRG_CD_220
		+ DRG_CD_221 * N1_DRG_CD_221
		+ DRG_CD_223 * N1_DRG_CD_223
		+ DRG_CD_224 * N1_DRG_CD_224
		+ DRG_CD_225 * N1_DRG_CD_225
		+ DRG_CD_226 * N1_DRG_CD_226
		+ DRG_CD_227 * N1_DRG_CD_227
		+ DRG_CD_232 * N1_DRG_CD_232
		+ DRG_CD_233 * N1_DRG_CD_233
		+ DRG_CD_234 * N1_DRG_CD_234
		+ DRG_CD_235 * N1_DRG_CD_235
		+ DRG_CD_236 * N1_DRG_CD_236
		+ DRG_CD_243 * N1_DRG_CD_243
		+ DRG_CD_244 * N1_DRG_CD_244
		+ DRG_CD_247 * N1_DRG_CD_247
		+ DRG_CD_248 * N1_DRG_CD_248
		+ DRG_CD_249 * N1_DRG_CD_249
		+ DRG_CD_250 * N1_DRG_CD_250
		+ DRG_CD_251 * N1_DRG_CD_251
		+ DRG_CD_266 * N1_DRG_CD_266
		+ DRG_CD_267 * N1_DRG_CD_267
		+ DRG_CD_273 * N1_DRG_CD_273
		+ DRG_CD_274 * N1_DRG_CD_274
		+ DRG_CD_281 * N1_DRG_CD_281
		+ DRG_CD_282 * N1_DRG_CD_282
		+ DRG_CD_292 * N1_DRG_CD_292
		+ DRG_CD_293 * N1_DRG_CD_293
		+ DRG_CD_309 * N1_DRG_CD_309
		+ DRG_CD_310 * N1_DRG_CD_310
		+ DRG_CD_330 * N1_DRG_CD_330
		+ DRG_CD_331 * N1_DRG_CD_331
		+ DRG_CD_378 * N1_DRG_CD_378
		+ DRG_CD_379 * N1_DRG_CD_379
		+ DRG_CD_389 * N1_DRG_CD_389
		+ DRG_CD_390 * N1_DRG_CD_390
		+ DRG_CD_442 * N1_DRG_CD_442
		+ DRG_CD_443 * N1_DRG_CD_443
		+ DRG_CD_454 * N1_DRG_CD_454
		+ DRG_CD_455 * N1_DRG_CD_455
		+ DRG_CD_460 * N1_DRG_CD_460
		+ DRG_CD_462 * N1_DRG_CD_462
		+ DRG_CD_470 * N1_DRG_CD_470
		+ DRG_CD_472 * N1_DRG_CD_472
		+ DRG_CD_473 * N1_DRG_CD_473
		+ DRG_CD_481 * N1_DRG_CD_481
		+ DRG_CD_482 * N1_DRG_CD_482
		+ DRG_CD_493 * N1_DRG_CD_493
		+ DRG_CD_494 * N1_DRG_CD_494
		+ DRG_CD_519 * N1_DRG_CD_519
		+ DRG_CD_520 * N1_DRG_CD_520
		+ DRG_CD_534 * N1_DRG_CD_534
		+ DRG_CD_535 * N1_DRG_CD_535
		+ DRG_CD_536 * N1_DRG_CD_536
		+ DRG_CD_603 * N1_DRG_CD_603
		+ DRG_CD_683 * N1_DRG_CD_683
		+ DRG_CD_684 * N1_DRG_CD_684
		+ DRG_CD_690 * N1_DRG_CD_690
		+ DRG_CD_871 * N1_DRG_CD_871
		+ DRG_CD_872 * N1_DRG_CD_872
		+ FRACTURE_FLAG * N1_FRACTURE_FLAG
		+ HCC_CNT_1_3 * N1_HCC_CNT_1_3
		+ HCC_CNT_4_6 * N1_HCC_CNT_4_6
		+ HCC_CNT_7_PLUS * N1_HCC_CNT_7_PLUS
		+ HCC1 * N1_HCC1
		+ HCC10 * N1_HCC10
		+ HCC100 * N1_HCC100
		+ HCC103 * N1_HCC103
		+ HCC104 * N1_HCC104
		+ HCC106 * N1_HCC106
		+ HCC107 * N1_HCC107
		+ HCC108 * N1_HCC108
		+ HCC11 * N1_HCC11
		+ HCC110 * N1_HCC110
		+ HCC111 * N1_HCC111
		+ HCC112 * N1_HCC112
		+ HCC114 * N1_HCC114
		+ HCC115 * N1_HCC115
		+ HCC12 * N1_HCC12
		+ HCC122 * N1_HCC122
		+ HCC124 * N1_HCC124
		+ HCC134 * N1_HCC134
		+ HCC135 * N1_HCC135
		+ HCC136 * N1_HCC136
		+ HCC137 * N1_HCC137
		+ HCC157 * N1_HCC157
		+ HCC158 * N1_HCC158
		+ HCC161 * N1_HCC161
		+ HCC162 * N1_HCC162
		+ HCC166 * N1_HCC166
		+ HCC167 * N1_HCC167
		+ HCC169 * N1_HCC169
		+ HCC17 * N1_HCC17
		+ HCC170 * N1_HCC170
		+ HCC173 * N1_HCC173
		+ HCC176 * N1_HCC176
		+ HCC18 * N1_HCC18
		+ HCC186 * N1_HCC186
		+ HCC188 * N1_HCC188
		+ HCC189 * N1_HCC189
		+ HCC19 * N1_HCC19
		+ HCC2 * N1_HCC2
		+ HCC21 * N1_HCC21
		+ HCC22 * N1_HCC22
		+ HCC23 * N1_HCC23
		+ HCC27 * N1_HCC27
		+ HCC28 * N1_HCC28
		+ HCC29 * N1_HCC29
		+ HCC33 * N1_HCC33
		+ HCC34 * N1_HCC34
		+ HCC35 * N1_HCC35
		+ HCC39 * N1_HCC39
		+ HCC40 * N1_HCC40
		+ HCC46 * N1_HCC46
		+ HCC47 * N1_HCC47
		+ HCC48 * N1_HCC48
		+ HCC54 * N1_HCC54
		+ HCC55 * N1_HCC55
		+ HCC57 * N1_HCC57
		+ HCC58 * N1_HCC58
		+ HCC6 * N1_HCC6
		+ HCC70 * N1_HCC70
		+ HCC71 * N1_HCC71
		+ HCC72 * N1_HCC72
		+ HCC73 * N1_HCC73
		+ HCC74 * N1_HCC74
		+ HCC75 * N1_HCC75
		+ HCC76 * N1_HCC76
		+ HCC77 * N1_HCC77
		+ HCC78 * N1_HCC78
		+ HCC79 * N1_HCC79
		+ HCC8 * N1_HCC8
		+ HCC80 * N1_HCC80
		+ HCC82 * N1_HCC82
		+ HCC83 * N1_HCC83
		+ HCC84 * N1_HCC84
		+ HCC85 * N1_HCC85
		+ HCC86 * N1_HCC86
		+ HCC87 * N1_HCC87
		+ HCC88 * N1_HCC88
		+ HCC9 * N1_HCC9
		+ HCC96 * N1_HCC96
		+ HCC99 * N1_HCC99
		+ LTI * N1_LTI
		+ ORIGDS * N1_ORIGDS
		+ PRIOR_HOSP_W_ANY_IP_FLAG_90 * N1_PRIOR_HOSP_W_ANY_IP_FLAG_90
		+ SEPSIS_CARD_RESP_FAIL * N1_SEPSIS_CARD_RESP_FAIL
		+ TKA_FLAG * N1_TKA_FLAG
		+ TKA_FRACTURE_FLAG * N1_TKA_FRACTURE_FLAG
		+ N1_INTERCEPT
		+ (N1_SIGMA1*N1_SIGMA1)/2 
		))
		+
		(N2_P2 * EXP(
		  (BENE_AGE-50) * N2_Age_50
		+ (BENE_AGE-50) * (BENE_AGE-50) * N2_Age_50_SQ
		+ ANY_DUAL * N2_ANY_DUAL
		+ APC_5193 * N2_APC_5193
		+ APC_5194 * N2_APC_5194
		+ APC_5232 * N2_APC_5232
		+ APC_5432 * N2_APC_5432
		+ CANCER_IMMUNE * N2_CANCER_IMMUNE
		+ CHF_COPD * N2_CHF_COPD
		+ CHF_RENAL * N2_CHF_RENAL
		+ COPD_CARD_RESP_FAIL * N2_COPD_CARD_RESP_FAIL
		+ DIABETES_CHF * N2_DIABETES_CHF
		+ DISABLED_HCC110 * N2_DISABLED_HCC110
		+ DISABLED_HCC176 * N2_DISABLED_HCC176
		+ DISABLED_HCC34 * N2_DISABLED_HCC34
		+ DISABLED_HCC46 * N2_DISABLED_HCC46
		+ DISABLED_HCC54 * N2_DISABLED_HCC54
		+ DISABLED_HCC55 * N2_DISABLED_HCC55
		+ DISABLED_HCC6 * N2_DISABLED_HCC6
		+ DRG_CD_062 * N2_DRG_CD_062
		+ DRG_CD_063 * N2_DRG_CD_063
		+ DRG_CD_064 * N2_DRG_CD_064
		+ DRG_CD_065 * N2_DRG_CD_065
		+ DRG_CD_066 * N2_DRG_CD_066
		+ DRG_CD_178 * N2_DRG_CD_178
		+ DRG_CD_179 * N2_DRG_CD_179
		+ DRG_CD_191 * N2_DRG_CD_191
		+ DRG_CD_192 * N2_DRG_CD_192
		+ DRG_CD_193 * N2_DRG_CD_193
		+ DRG_CD_194 * N2_DRG_CD_194
		+ DRG_CD_195 * N2_DRG_CD_195
		+ DRG_CD_202 * N2_DRG_CD_202
		+ DRG_CD_203 * N2_DRG_CD_203
		+ DRG_CD_217 * N2_DRG_CD_217
		+ DRG_CD_218 * N2_DRG_CD_218
		+ DRG_CD_219 * N2_DRG_CD_219
		+ DRG_CD_220 * N2_DRG_CD_220
		+ DRG_CD_221 * N2_DRG_CD_221
		+ DRG_CD_223 * N2_DRG_CD_223
		+ DRG_CD_224 * N2_DRG_CD_224
		+ DRG_CD_225 * N2_DRG_CD_225
		+ DRG_CD_226 * N2_DRG_CD_226
		+ DRG_CD_227 * N2_DRG_CD_227
		+ DRG_CD_232 * N2_DRG_CD_232
		+ DRG_CD_233 * N2_DRG_CD_233
		+ DRG_CD_234 * N2_DRG_CD_234
		+ DRG_CD_235 * N2_DRG_CD_235
		+ DRG_CD_236 * N2_DRG_CD_236
		+ DRG_CD_243 * N2_DRG_CD_243
		+ DRG_CD_244 * N2_DRG_CD_244
		+ DRG_CD_247 * N2_DRG_CD_247
		+ DRG_CD_248 * N2_DRG_CD_248
		+ DRG_CD_249 * N2_DRG_CD_249
		+ DRG_CD_250 * N2_DRG_CD_250
		+ DRG_CD_251 * N2_DRG_CD_251
		+ DRG_CD_266 * N2_DRG_CD_266
		+ DRG_CD_267 * N2_DRG_CD_267
		+ DRG_CD_273 * N2_DRG_CD_273
		+ DRG_CD_274 * N2_DRG_CD_274
		+ DRG_CD_281 * N2_DRG_CD_281
		+ DRG_CD_282 * N2_DRG_CD_282
		+ DRG_CD_292 * N2_DRG_CD_292
		+ DRG_CD_293 * N2_DRG_CD_293
		+ DRG_CD_309 * N2_DRG_CD_309
		+ DRG_CD_310 * N2_DRG_CD_310
		+ DRG_CD_330 * N2_DRG_CD_330
		+ DRG_CD_331 * N2_DRG_CD_331
		+ DRG_CD_378 * N2_DRG_CD_378
		+ DRG_CD_379 * N2_DRG_CD_379
		+ DRG_CD_389 * N2_DRG_CD_389
		+ DRG_CD_390 * N2_DRG_CD_390
		+ DRG_CD_442 * N2_DRG_CD_442
		+ DRG_CD_443 * N2_DRG_CD_443
		+ DRG_CD_454 * N2_DRG_CD_454
		+ DRG_CD_455 * N2_DRG_CD_455
		+ DRG_CD_460 * N2_DRG_CD_460
		+ DRG_CD_462 * N2_DRG_CD_462
		+ DRG_CD_470 * N2_DRG_CD_470
		+ DRG_CD_472 * N2_DRG_CD_472
		+ DRG_CD_473 * N2_DRG_CD_473
		+ DRG_CD_481 * N2_DRG_CD_481
		+ DRG_CD_482 * N2_DRG_CD_482
		+ DRG_CD_493 * N2_DRG_CD_493
		+ DRG_CD_494 * N2_DRG_CD_494
		+ DRG_CD_519 * N2_DRG_CD_519
		+ DRG_CD_520 * N2_DRG_CD_520
		+ DRG_CD_534 * N2_DRG_CD_534
		+ DRG_CD_535 * N2_DRG_CD_535
		+ DRG_CD_536 * N2_DRG_CD_536
		+ DRG_CD_603 * N2_DRG_CD_603
		+ DRG_CD_683 * N2_DRG_CD_683
		+ DRG_CD_684 * N2_DRG_CD_684
		+ DRG_CD_690 * N2_DRG_CD_690
		+ DRG_CD_871 * N2_DRG_CD_871
		+ DRG_CD_872 * N2_DRG_CD_872
		+ FRACTURE_FLAG * N2_FRACTURE_FLAG
		+ HCC_CNT_1_3 * N2_HCC_CNT_1_3
		+ HCC_CNT_4_6 * N2_HCC_CNT_4_6
		+ HCC_CNT_7_PLUS * N2_HCC_CNT_7_PLUS
		+ HCC1 * N2_HCC1
		+ HCC10 * N2_HCC10
		+ HCC100 * N2_HCC100
		+ HCC103 * N2_HCC103
		+ HCC104 * N2_HCC104
		+ HCC106 * N2_HCC106
		+ HCC107 * N2_HCC107
		+ HCC108 * N2_HCC108
		+ HCC11 * N2_HCC11
		+ HCC110 * N2_HCC110
		+ HCC111 * N2_HCC111
		+ HCC112 * N2_HCC112
		+ HCC114 * N2_HCC114
		+ HCC115 * N2_HCC115
		+ HCC12 * N2_HCC12
		+ HCC122 * N2_HCC122
		+ HCC124 * N2_HCC124
		+ HCC134 * N2_HCC134
		+ HCC135 * N2_HCC135
		+ HCC136 * N2_HCC136
		+ HCC137 * N2_HCC137
		+ HCC157 * N2_HCC157
		+ HCC158 * N2_HCC158
		+ HCC161 * N2_HCC161
		+ HCC162 * N2_HCC162
		+ HCC166 * N2_HCC166
		+ HCC167 * N2_HCC167
		+ HCC169 * N2_HCC169
		+ HCC17 * N2_HCC17
		+ HCC170 * N2_HCC170
		+ HCC173 * N2_HCC173
		+ HCC176 * N2_HCC176
		+ HCC18 * N2_HCC18
		+ HCC186 * N2_HCC186
		+ HCC188 * N2_HCC188
		+ HCC189 * N2_HCC189
		+ HCC19 * N2_HCC19
		+ HCC2 * N2_HCC2
		+ HCC21 * N2_HCC21
		+ HCC22 * N2_HCC22
		+ HCC23 * N2_HCC23
		+ HCC27 * N2_HCC27
		+ HCC28 * N2_HCC28
		+ HCC29 * N2_HCC29
		+ HCC33 * N2_HCC33
		+ HCC34 * N2_HCC34
		+ HCC35 * N2_HCC35
		+ HCC39 * N2_HCC39
		+ HCC40 * N2_HCC40
		+ HCC46 * N2_HCC46
		+ HCC47 * N2_HCC47
		+ HCC48 * N2_HCC48
		+ HCC54 * N2_HCC54
		+ HCC55 * N2_HCC55
		+ HCC57 * N2_HCC57
		+ HCC58 * N2_HCC58
		+ HCC6 * N2_HCC6
		+ HCC70 * N2_HCC70
		+ HCC71 * N2_HCC71
		+ HCC72 * N2_HCC72
		+ HCC73 * N2_HCC73
		+ HCC74 * N2_HCC74
		+ HCC75 * N2_HCC75
		+ HCC76 * N2_HCC76
		+ HCC77 * N2_HCC77
		+ HCC78 * N2_HCC78
		+ HCC79 * N2_HCC79
		+ HCC8 * N2_HCC8
		+ HCC80 * N2_HCC80
		+ HCC82 * N2_HCC82
		+ HCC83 * N2_HCC83
		+ HCC84 * N2_HCC84
		+ HCC85 * N2_HCC85
		+ HCC86 * N2_HCC86
		+ HCC87 * N2_HCC87
		+ HCC88 * N2_HCC88
		+ HCC9 * N2_HCC9
		+ HCC96 * N2_HCC96
		+ HCC99 * N2_HCC99
		+ LTI * N2_LTI
		+ ORIGDS * N2_ORIGDS
		+ PRIOR_HOSP_W_ANY_IP_FLAG_90 * N2_PRIOR_HOSP_W_ANY_IP_FLAG_90
		+ SEPSIS_CARD_RESP_FAIL * N2_SEPSIS_CARD_RESP_FAIL
		+ TKA_FLAG * N2_TKA_FLAG
		+ TKA_FRACTURE_FLAG * N2_TKA_FRACTURE_FLAG
		+ N2_INTERCEPT
		+ (N2_SIGMA2*N2_SIGMA2)/2 
		))
		;
run;

proc sql;
	create table temp1b_pre as
	select a.*, b.ACADEMIC, b.URBAN_RURAL, b.SAFETY_NET, b.BED_SIZE, b.CENSUS as CENSUS_Pre
	from temp1_preb as a left join Peer_Group_baseline as b
	on a.anc_ccn = b.ccn_join;
		/*and b.epi_start <= a.ANCHOR_BEG_DT <= b.epi_end;*/
quit;

data temp1b;
	set temp1b_pre;
	CENSUS = input(CENSUS_Pre,12.);
run;

proc sql;
	create table temp2b as
	select a.*, b.*
	from temp1b as a left join TP_Risk_Adj_Parameters_baseline as b
	on a.EPISODE_GROUP_NAME = b.Clinical_Episode_Category
		and a.anchor_type_upper = b.Clinical_Episode_Type;
		/*and b.epi_start <= a.ANCHOR_BEG_DT <= b.epi_end;*/
quit;

proc sql;
	create table temp3b_pre as
	select a.*, b.PAT_Factor as PAT_New
	from temp2b as a left join PAT_Factors_baseline as b
	on a.EPISODE_GROUP_NAME = b.Clinical_Episode
		and a.ANCHOR_TYPE=b.anchor_type
		and a.ACADEMIC=b.AMC
		and a.URBAN_RURAL=b.Urban_Rural
		and a.SAFETY_NET=b.Safety_Net
		and a.BED_SIZE=b.Bed_Size
		and a.CENSUS=b.Census_Div
		and year(a.POST_DSCH_END_DT)=b.Year
		and qtr(a.POST_DSCH_END_DT)=b.Quarter;
		/*and b.epi_start <= a.ANCHOR_BEG_DT <= b.epi_end;*/
quit;

proc sql;
	create table temp3b as
	select a.*, b.PAT_Factor as PAT_2019Q3
	from temp3b_pre as a left join PAT_Factors_baseline as b
	on a.EPISODE_GROUP_NAME = b.Clinical_Episode
		and a.ANCHOR_TYPE=b.anchor_type
		and a.ACADEMIC=b.AMC
		and a.URBAN_RURAL=b.Urban_Rural
		and a.SAFETY_NET=b.Safety_Net
		and a.BED_SIZE=b.Bed_Size
		and a.CENSUS=b.Census_Div
		and b.Year=2019
		and b.Quarter=3;
		/*and b.epi_start <= a.ANCHOR_BEG_DT <= b.epi_end;*/
quit;

proc sql;
	create table temp4b as
	select a.*, 
		b.PGP_ACH,
		b.CCN_TIN,
		b.ASSOC_ACH_CCN,
		b.CCN_JOIN,
		b.EPI_TYPE,
		b.EPI_CAT,
		b.EPI_COUNT,
		b.COUNT_GT_40,
		b.EPI_CAT_ADJ,
		b.EPI_CAT_SHORT,
		b.EPI_CAT_2,
		b.EPI_SPEND,
		b.AMT,
		b.ACH_EFF,
		b.SBS,
		b.PCMA,
		b.PAT,
		b.HBP,
		b.PGP_EFF,
		b.PGP_OFFSET,
		b.PGP_OFFSET_ADJ,
		b.PGP_ACH_PCMA,
		b.CASE_MIX,
		b.PGP_ACH_BNCHMRK,
		b.TARGET_PRICE,
		b.PAYMENT_RATIO,
		b.TARGET_PRICE_REAL,
		b.EPI_INDEX,
		b.BPID_CHANGE,
		b.EPI_DROPPED_FLAG,
		b.TIME_PERIOD
	from temp3b as a 
		left join TP_Components as b
			on a.BPID = b.INITIATOR_BPID
			and a.EPISODE_GROUP_NAME = b.EPI_CAT
			and a.anchor_type_upper = b.EPI_TYPE
			and a.anc_ccn = b.ccn_join;
			/*and b.epi_start <= a.ANCHOR_BEG_DT <= b.epi_end;*/
quit;

data temp5b;
	set temp4b;
	format DRG_CODE BEST12.;
	%if &label. = ybase %then %do; 
		DRG_CODE=DRG_2018;
	%end; 
	%else %do;
		if ANCHOR_TYPE = 'ip' then DRG_CODE = input(ANCHOR_CODE,$20.);
		else DRG_CODE = . ;
	%end;

	Epi_Year = year(POST_DSCH_END_DT);
	Epi_Qtr = qtr(POST_DSCH_END_DT);
	Epi_Half = 1;
	if Epi_Qtr in (3,4) then Epi_Half = 2;

	DRG_CD_062=0;
	DRG_CD_063=0;
	DRG_CD_064=0;
	DRG_CD_065=0;
	DRG_CD_066=0;
	DRG_CD_178=0;
	DRG_CD_179=0;
	DRG_CD_191=0;
	DRG_CD_192=0;
	DRG_CD_193=0;
	DRG_CD_194=0;
	DRG_CD_195=0;
	DRG_CD_202=0;
	DRG_CD_203=0;
	DRG_CD_217=0;
	DRG_CD_218=0;
	DRG_CD_219=0;
	DRG_CD_220=0;
	DRG_CD_221=0;
	DRG_CD_223=0;
	DRG_CD_224=0;
	DRG_CD_225=0;
	DRG_CD_226=0;
	DRG_CD_227=0;
	DRG_CD_232=0;
	DRG_CD_233=0;
	DRG_CD_234=0;
	DRG_CD_235=0;
	DRG_CD_236=0;
	DRG_CD_243=0;
	DRG_CD_244=0;
	DRG_CD_247=0;
	DRG_CD_248=0;
	DRG_CD_249=0;
	DRG_CD_250=0;
	DRG_CD_251=0;
	DRG_CD_266=0;
	DRG_CD_267=0;
	DRG_CD_273=0;
	DRG_CD_274=0;
	DRG_CD_281=0;
	DRG_CD_282=0;
	DRG_CD_292=0;
	DRG_CD_293=0;
	DRG_CD_309=0;
	DRG_CD_310=0;
	DRG_CD_330=0;
	DRG_CD_331=0;
	DRG_CD_378=0;
	DRG_CD_379=0;
	DRG_CD_389=0;
	DRG_CD_390=0;
	DRG_CD_442=0;
	DRG_CD_443=0;
	DRG_CD_454=0;
	DRG_CD_455=0;
	DRG_CD_460=0;
	DRG_CD_462=0;
	DRG_CD_470=0;
	DRG_CD_472=0;
	DRG_CD_473=0;
	DRG_CD_481=0;
	DRG_CD_482=0;
	DRG_CD_493=0;
	DRG_CD_494=0;
	DRG_CD_519=0;
	DRG_CD_520=0;
	DRG_CD_534=0;
	DRG_CD_535=0;
	DRG_CD_536=0;
	DRG_CD_603=0;
	DRG_CD_683=0;
	DRG_CD_684=0;
	DRG_CD_690=0;
	DRG_CD_871=0;
	DRG_CD_872=0;
	APC_5193=0;
	APC_5194=0;
	APC_5232=0;
	APC_5432=0;

	if DRG_CODE = 062 then DRG_CD_062=1;
	if DRG_CODE = 063 then DRG_CD_063=1;
	if DRG_CODE = 064 then DRG_CD_064=1;
	if DRG_CODE = 065 then DRG_CD_065=1;
	if DRG_CODE = 066 then DRG_CD_066=1;
	if DRG_CODE = 178 then DRG_CD_178=1;
	if DRG_CODE = 179 then DRG_CD_179=1;
	if DRG_CODE = 191 then DRG_CD_191=1;
	if DRG_CODE = 192 then DRG_CD_192=1;
	if DRG_CODE = 193 then DRG_CD_193=1;
	if DRG_CODE = 194 then DRG_CD_194=1;
	if DRG_CODE = 195 then DRG_CD_195=1;
	if DRG_CODE = 202 then DRG_CD_202=1;
	if DRG_CODE = 203 then DRG_CD_203=1;
	if DRG_CODE = 217 then DRG_CD_217=1;
	if DRG_CODE = 218 then DRG_CD_218=1;
	if DRG_CODE = 219 then DRG_CD_219=1;
	if DRG_CODE = 220 then DRG_CD_220=1;
	if DRG_CODE = 221 then DRG_CD_221=1;
	if DRG_CODE = 223 then DRG_CD_223=1;
	if DRG_CODE = 224 then DRG_CD_224=1;
	if DRG_CODE = 225 then DRG_CD_225=1;
	if DRG_CODE = 226 then DRG_CD_226=1;
	if DRG_CODE = 227 then DRG_CD_227=1;
	if DRG_CODE = 232 then DRG_CD_232=1;
	if DRG_CODE = 233 then DRG_CD_233=1;
	if DRG_CODE = 234 then DRG_CD_234=1;
	if DRG_CODE = 235 then DRG_CD_235=1;
	if DRG_CODE = 236 then DRG_CD_236=1;
	if DRG_CODE = 243 then DRG_CD_243=1;
	if DRG_CODE = 244 then DRG_CD_244=1;
	if DRG_CODE = 247 then DRG_CD_247=1;
	if DRG_CODE = 248 then DRG_CD_248=1;
	if DRG_CODE = 249 then DRG_CD_249=1;
	if DRG_CODE = 250 then DRG_CD_250=1;
	if DRG_CODE = 251 then DRG_CD_251=1;
	if DRG_CODE = 266 then DRG_CD_266=1;
	if DRG_CODE = 267 then DRG_CD_267=1;
	if DRG_CODE = 273 then DRG_CD_273=1;
	if DRG_CODE = 274 then DRG_CD_274=1;
	if DRG_CODE = 281 then DRG_CD_281=1;
	if DRG_CODE = 282 then DRG_CD_282=1;
	if DRG_CODE = 292 then DRG_CD_292=1;
	if DRG_CODE = 293 then DRG_CD_293=1;
	if DRG_CODE = 309 then DRG_CD_309=1;
	if DRG_CODE = 310 then DRG_CD_310=1;
	if DRG_CODE = 330 then DRG_CD_330=1;
	if DRG_CODE = 331 then DRG_CD_331=1;
	if DRG_CODE = 378 then DRG_CD_378=1;
	if DRG_CODE = 379 then DRG_CD_379=1;
	if DRG_CODE = 389 then DRG_CD_389=1;
	if DRG_CODE = 390 then DRG_CD_390=1;
	if DRG_CODE = 442 then DRG_CD_442=1;
	if DRG_CODE = 443 then DRG_CD_443=1;
	if DRG_CODE = 454 then DRG_CD_454=1;
	if DRG_CODE = 455 then DRG_CD_455=1;
	if DRG_CODE = 460 then DRG_CD_460=1;
	if DRG_CODE = 462 then DRG_CD_462=1;
	if DRG_CODE = 470 then DRG_CD_470=1;
	if DRG_CODE = 472 then DRG_CD_472=1;
	if DRG_CODE = 473 then DRG_CD_473=1;
	if DRG_CODE = 481 then DRG_CD_481=1;
	if DRG_CODE = 482 then DRG_CD_482=1;
	if DRG_CODE = 493 then DRG_CD_493=1;
	if DRG_CODE = 494 then DRG_CD_494=1;
	if DRG_CODE = 519 then DRG_CD_519=1;
	if DRG_CODE = 520 then DRG_CD_520=1;
	if DRG_CODE = 534 then DRG_CD_534=1;
	if DRG_CODE = 535 then DRG_CD_535=1;
	if DRG_CODE = 536 then DRG_CD_536=1;
	if DRG_CODE = 603 then DRG_CD_603=1;
	if DRG_CODE = 683 then DRG_CD_683=1;
	if DRG_CODE = 684 then DRG_CD_684=1;
	if DRG_CODE = 690 then DRG_CD_690=1;
	if DRG_CODE = 871 then DRG_CD_871=1;
	if DRG_CODE = 872 then DRG_CD_872=1;
	if PERF_APC = 5193 then APC_5193=1;
	if PERF_APC = 5194 then APC_5194=1;
	if PERF_APC = 5232 then APC_5232=1;
	if PERF_APC = 5432 then APC_5432=1;

	HCC_CNT = sum(of HCC1 -- HCC189);
	HCC_CNT_1_3=0;
	HCC_CNT_4_6=0;
	HCC_CNT_7_PLUS=0;
	if HCC_CNT > 0 then do;
		if HCC_CNT <= 3 then HCC_CNT_1_3=1;
		else if HCC_CNT <= 6 then HCC_CNT_4_6=1;
		else if HCC_CNT >= 7 then HCC_CNT_7_PLUS=1;
	end; 


Pred_Price = (N1_P1 * EXP(
		  (BENE_AGE-50) * N1_Age_50
		+ (BENE_AGE-50) * (BENE_AGE-50) * N1_Age_50_SQ
		+ ANY_DUAL * N1_ANY_DUAL
		+ APC_5193 * N1_APC_5193
		+ APC_5194 * N1_APC_5194
		+ APC_5232 * N1_APC_5232
		+ APC_5432 * N1_APC_5432
		+ CANCER_IMMUNE * N1_CANCER_IMMUNE
		+ CHF_COPD * N1_CHF_COPD
		+ CHF_RENAL * N1_CHF_RENAL
		+ COPD_CARD_RESP_FAIL * N1_COPD_CARD_RESP_FAIL
		+ DIABETES_CHF * N1_DIABETES_CHF
		+ DISABLED_HCC110 * N1_DISABLED_HCC110
		+ DISABLED_HCC176 * N1_DISABLED_HCC176
		+ DISABLED_HCC34 * N1_DISABLED_HCC34
		+ DISABLED_HCC46 * N1_DISABLED_HCC46
		+ DISABLED_HCC54 * N1_DISABLED_HCC54
		+ DISABLED_HCC55 * N1_DISABLED_HCC55
		+ DISABLED_HCC6 * N1_DISABLED_HCC6
		+ DRG_CD_062 * N1_DRG_CD_062
		+ DRG_CD_063 * N1_DRG_CD_063
		+ DRG_CD_064 * N1_DRG_CD_064
		+ DRG_CD_065 * N1_DRG_CD_065
		+ DRG_CD_066 * N1_DRG_CD_066
		+ DRG_CD_178 * N1_DRG_CD_178
		+ DRG_CD_179 * N1_DRG_CD_179
		+ DRG_CD_191 * N1_DRG_CD_191
		+ DRG_CD_192 * N1_DRG_CD_192
		+ DRG_CD_193 * N1_DRG_CD_193
		+ DRG_CD_194 * N1_DRG_CD_194
		+ DRG_CD_195 * N1_DRG_CD_195
		+ DRG_CD_202 * N1_DRG_CD_202
		+ DRG_CD_203 * N1_DRG_CD_203
		+ DRG_CD_217 * N1_DRG_CD_217
		+ DRG_CD_218 * N1_DRG_CD_218
		+ DRG_CD_219 * N1_DRG_CD_219
		+ DRG_CD_220 * N1_DRG_CD_220
		+ DRG_CD_221 * N1_DRG_CD_221
		+ DRG_CD_223 * N1_DRG_CD_223
		+ DRG_CD_224 * N1_DRG_CD_224
		+ DRG_CD_225 * N1_DRG_CD_225
		+ DRG_CD_226 * N1_DRG_CD_226
		+ DRG_CD_227 * N1_DRG_CD_227
		+ DRG_CD_232 * N1_DRG_CD_232
		+ DRG_CD_233 * N1_DRG_CD_233
		+ DRG_CD_234 * N1_DRG_CD_234
		+ DRG_CD_235 * N1_DRG_CD_235
		+ DRG_CD_236 * N1_DRG_CD_236
		+ DRG_CD_243 * N1_DRG_CD_243
		+ DRG_CD_244 * N1_DRG_CD_244
		+ DRG_CD_247 * N1_DRG_CD_247
		+ DRG_CD_248 * N1_DRG_CD_248
		+ DRG_CD_249 * N1_DRG_CD_249
		+ DRG_CD_250 * N1_DRG_CD_250
		+ DRG_CD_251 * N1_DRG_CD_251
		+ DRG_CD_266 * N1_DRG_CD_266
		+ DRG_CD_267 * N1_DRG_CD_267
		+ DRG_CD_273 * N1_DRG_CD_273
		+ DRG_CD_274 * N1_DRG_CD_274
		+ DRG_CD_281 * N1_DRG_CD_281
		+ DRG_CD_282 * N1_DRG_CD_282
		+ DRG_CD_292 * N1_DRG_CD_292
		+ DRG_CD_293 * N1_DRG_CD_293
		+ DRG_CD_309 * N1_DRG_CD_309
		+ DRG_CD_310 * N1_DRG_CD_310
		+ DRG_CD_330 * N1_DRG_CD_330
		+ DRG_CD_331 * N1_DRG_CD_331
		+ DRG_CD_378 * N1_DRG_CD_378
		+ DRG_CD_379 * N1_DRG_CD_379
		+ DRG_CD_389 * N1_DRG_CD_389
		+ DRG_CD_390 * N1_DRG_CD_390
		+ DRG_CD_442 * N1_DRG_CD_442
		+ DRG_CD_443 * N1_DRG_CD_443
		+ DRG_CD_454 * N1_DRG_CD_454
		+ DRG_CD_455 * N1_DRG_CD_455
		+ DRG_CD_460 * N1_DRG_CD_460
		+ DRG_CD_462 * N1_DRG_CD_462
		+ DRG_CD_470 * N1_DRG_CD_470
		+ DRG_CD_472 * N1_DRG_CD_472
		+ DRG_CD_473 * N1_DRG_CD_473
		+ DRG_CD_481 * N1_DRG_CD_481
		+ DRG_CD_482 * N1_DRG_CD_482
		+ DRG_CD_493 * N1_DRG_CD_493
		+ DRG_CD_494 * N1_DRG_CD_494
		+ DRG_CD_519 * N1_DRG_CD_519
		+ DRG_CD_520 * N1_DRG_CD_520
		+ DRG_CD_534 * N1_DRG_CD_534
		+ DRG_CD_535 * N1_DRG_CD_535
		+ DRG_CD_536 * N1_DRG_CD_536
		+ DRG_CD_603 * N1_DRG_CD_603
		+ DRG_CD_683 * N1_DRG_CD_683
		+ DRG_CD_684 * N1_DRG_CD_684
		+ DRG_CD_690 * N1_DRG_CD_690
		+ DRG_CD_871 * N1_DRG_CD_871
		+ DRG_CD_872 * N1_DRG_CD_872
		+ FRACTURE_FLAG * N1_FRACTURE_FLAG
		+ HCC_CNT_1_3 * N1_HCC_CNT_1_3
		+ HCC_CNT_4_6 * N1_HCC_CNT_4_6
		+ HCC_CNT_7_PLUS * N1_HCC_CNT_7_PLUS
		+ HCC1 * N1_HCC1
		+ HCC10 * N1_HCC10
		+ HCC100 * N1_HCC100
		+ HCC103 * N1_HCC103
		+ HCC104 * N1_HCC104
		+ HCC106 * N1_HCC106
		+ HCC107 * N1_HCC107
		+ HCC108 * N1_HCC108
		+ HCC11 * N1_HCC11
		+ HCC110 * N1_HCC110
		+ HCC111 * N1_HCC111
		+ HCC112 * N1_HCC112
		+ HCC114 * N1_HCC114
		+ HCC115 * N1_HCC115
		+ HCC12 * N1_HCC12
		+ HCC122 * N1_HCC122
		+ HCC124 * N1_HCC124
		+ HCC134 * N1_HCC134
		+ HCC135 * N1_HCC135
		+ HCC136 * N1_HCC136
		+ HCC137 * N1_HCC137
		+ HCC157 * N1_HCC157
		+ HCC158 * N1_HCC158
		+ HCC161 * N1_HCC161
		+ HCC162 * N1_HCC162
		+ HCC166 * N1_HCC166
		+ HCC167 * N1_HCC167
		+ HCC169 * N1_HCC169
		+ HCC17 * N1_HCC17
		+ HCC170 * N1_HCC170
		+ HCC173 * N1_HCC173
		+ HCC176 * N1_HCC176
		+ HCC18 * N1_HCC18
		+ HCC186 * N1_HCC186
		+ HCC188 * N1_HCC188
		+ HCC189 * N1_HCC189
		+ HCC19 * N1_HCC19
		+ HCC2 * N1_HCC2
		+ HCC21 * N1_HCC21
		+ HCC22 * N1_HCC22
		+ HCC23 * N1_HCC23
		+ HCC27 * N1_HCC27
		+ HCC28 * N1_HCC28
		+ HCC29 * N1_HCC29
		+ HCC33 * N1_HCC33
		+ HCC34 * N1_HCC34
		+ HCC35 * N1_HCC35
		+ HCC39 * N1_HCC39
		+ HCC40 * N1_HCC40
		+ HCC46 * N1_HCC46
		+ HCC47 * N1_HCC47
		+ HCC48 * N1_HCC48
		+ HCC54 * N1_HCC54
		+ HCC55 * N1_HCC55
		+ HCC57 * N1_HCC57
		+ HCC58 * N1_HCC58
		+ HCC6 * N1_HCC6
		+ HCC70 * N1_HCC70
		+ HCC71 * N1_HCC71
		+ HCC72 * N1_HCC72
		+ HCC73 * N1_HCC73
		+ HCC74 * N1_HCC74
		+ HCC75 * N1_HCC75
		+ HCC76 * N1_HCC76
		+ HCC77 * N1_HCC77
		+ HCC78 * N1_HCC78
		+ HCC79 * N1_HCC79
		+ HCC8 * N1_HCC8
		+ HCC80 * N1_HCC80
		+ HCC82 * N1_HCC82
		+ HCC83 * N1_HCC83
		+ HCC84 * N1_HCC84
		+ HCC85 * N1_HCC85
		+ HCC86 * N1_HCC86
		+ HCC87 * N1_HCC87
		+ HCC88 * N1_HCC88
		+ HCC9 * N1_HCC9
		+ HCC96 * N1_HCC96
		+ HCC99 * N1_HCC99
		+ LTI * N1_LTI
		+ ORIGDS * N1_ORIGDS
		+ PRIOR_HOSP_W_ANY_IP_FLAG_90 * N1_PRIOR_HOSP_W_ANY_IP_FLAG_90
		+ SEPSIS_CARD_RESP_FAIL * N1_SEPSIS_CARD_RESP_FAIL
		+ TKA_FLAG * N1_TKA_FLAG
		+ TKA_FRACTURE_FLAG * N1_TKA_FRACTURE_FLAG
		+ N1_INTERCEPT
		+ (N1_SIGMA1*N1_SIGMA1)/2 
		))
		+
		(N2_P2 * EXP(
		  (BENE_AGE-50) * N2_Age_50
		+ (BENE_AGE-50) * (BENE_AGE-50) * N2_Age_50_SQ
		+ ANY_DUAL * N2_ANY_DUAL
		+ APC_5193 * N2_APC_5193
		+ APC_5194 * N2_APC_5194
		+ APC_5232 * N2_APC_5232
		+ APC_5432 * N2_APC_5432
		+ CANCER_IMMUNE * N2_CANCER_IMMUNE
		+ CHF_COPD * N2_CHF_COPD
		+ CHF_RENAL * N2_CHF_RENAL
		+ COPD_CARD_RESP_FAIL * N2_COPD_CARD_RESP_FAIL
		+ DIABETES_CHF * N2_DIABETES_CHF
		+ DISABLED_HCC110 * N2_DISABLED_HCC110
		+ DISABLED_HCC176 * N2_DISABLED_HCC176
		+ DISABLED_HCC34 * N2_DISABLED_HCC34
		+ DISABLED_HCC46 * N2_DISABLED_HCC46
		+ DISABLED_HCC54 * N2_DISABLED_HCC54
		+ DISABLED_HCC55 * N2_DISABLED_HCC55
		+ DISABLED_HCC6 * N2_DISABLED_HCC6
		+ DRG_CD_062 * N2_DRG_CD_062
		+ DRG_CD_063 * N2_DRG_CD_063
		+ DRG_CD_064 * N2_DRG_CD_064
		+ DRG_CD_065 * N2_DRG_CD_065
		+ DRG_CD_066 * N2_DRG_CD_066
		+ DRG_CD_178 * N2_DRG_CD_178
		+ DRG_CD_179 * N2_DRG_CD_179
		+ DRG_CD_191 * N2_DRG_CD_191
		+ DRG_CD_192 * N2_DRG_CD_192
		+ DRG_CD_193 * N2_DRG_CD_193
		+ DRG_CD_194 * N2_DRG_CD_194
		+ DRG_CD_195 * N2_DRG_CD_195
		+ DRG_CD_202 * N2_DRG_CD_202
		+ DRG_CD_203 * N2_DRG_CD_203
		+ DRG_CD_217 * N2_DRG_CD_217
		+ DRG_CD_218 * N2_DRG_CD_218
		+ DRG_CD_219 * N2_DRG_CD_219
		+ DRG_CD_220 * N2_DRG_CD_220
		+ DRG_CD_221 * N2_DRG_CD_221
		+ DRG_CD_223 * N2_DRG_CD_223
		+ DRG_CD_224 * N2_DRG_CD_224
		+ DRG_CD_225 * N2_DRG_CD_225
		+ DRG_CD_226 * N2_DRG_CD_226
		+ DRG_CD_227 * N2_DRG_CD_227
		+ DRG_CD_232 * N2_DRG_CD_232
		+ DRG_CD_233 * N2_DRG_CD_233
		+ DRG_CD_234 * N2_DRG_CD_234
		+ DRG_CD_235 * N2_DRG_CD_235
		+ DRG_CD_236 * N2_DRG_CD_236
		+ DRG_CD_243 * N2_DRG_CD_243
		+ DRG_CD_244 * N2_DRG_CD_244
		+ DRG_CD_247 * N2_DRG_CD_247
		+ DRG_CD_248 * N2_DRG_CD_248
		+ DRG_CD_249 * N2_DRG_CD_249
		+ DRG_CD_250 * N2_DRG_CD_250
		+ DRG_CD_251 * N2_DRG_CD_251
		+ DRG_CD_266 * N2_DRG_CD_266
		+ DRG_CD_267 * N2_DRG_CD_267
		+ DRG_CD_273 * N2_DRG_CD_273
		+ DRG_CD_274 * N2_DRG_CD_274
		+ DRG_CD_281 * N2_DRG_CD_281
		+ DRG_CD_282 * N2_DRG_CD_282
		+ DRG_CD_292 * N2_DRG_CD_292
		+ DRG_CD_293 * N2_DRG_CD_293
		+ DRG_CD_309 * N2_DRG_CD_309
		+ DRG_CD_310 * N2_DRG_CD_310
		+ DRG_CD_330 * N2_DRG_CD_330
		+ DRG_CD_331 * N2_DRG_CD_331
		+ DRG_CD_378 * N2_DRG_CD_378
		+ DRG_CD_379 * N2_DRG_CD_379
		+ DRG_CD_389 * N2_DRG_CD_389
		+ DRG_CD_390 * N2_DRG_CD_390
		+ DRG_CD_442 * N2_DRG_CD_442
		+ DRG_CD_443 * N2_DRG_CD_443
		+ DRG_CD_454 * N2_DRG_CD_454
		+ DRG_CD_455 * N2_DRG_CD_455
		+ DRG_CD_460 * N2_DRG_CD_460
		+ DRG_CD_462 * N2_DRG_CD_462
		+ DRG_CD_470 * N2_DRG_CD_470
		+ DRG_CD_472 * N2_DRG_CD_472
		+ DRG_CD_473 * N2_DRG_CD_473
		+ DRG_CD_481 * N2_DRG_CD_481
		+ DRG_CD_482 * N2_DRG_CD_482
		+ DRG_CD_493 * N2_DRG_CD_493
		+ DRG_CD_494 * N2_DRG_CD_494
		+ DRG_CD_519 * N2_DRG_CD_519
		+ DRG_CD_520 * N2_DRG_CD_520
		+ DRG_CD_534 * N2_DRG_CD_534
		+ DRG_CD_535 * N2_DRG_CD_535
		+ DRG_CD_536 * N2_DRG_CD_536
		+ DRG_CD_603 * N2_DRG_CD_603
		+ DRG_CD_683 * N2_DRG_CD_683
		+ DRG_CD_684 * N2_DRG_CD_684
		+ DRG_CD_690 * N2_DRG_CD_690
		+ DRG_CD_871 * N2_DRG_CD_871
		+ DRG_CD_872 * N2_DRG_CD_872
		+ FRACTURE_FLAG * N2_FRACTURE_FLAG
		+ HCC_CNT_1_3 * N2_HCC_CNT_1_3
		+ HCC_CNT_4_6 * N2_HCC_CNT_4_6
		+ HCC_CNT_7_PLUS * N2_HCC_CNT_7_PLUS
		+ HCC1 * N2_HCC1
		+ HCC10 * N2_HCC10
		+ HCC100 * N2_HCC100
		+ HCC103 * N2_HCC103
		+ HCC104 * N2_HCC104
		+ HCC106 * N2_HCC106
		+ HCC107 * N2_HCC107
		+ HCC108 * N2_HCC108
		+ HCC11 * N2_HCC11
		+ HCC110 * N2_HCC110
		+ HCC111 * N2_HCC111
		+ HCC112 * N2_HCC112
		+ HCC114 * N2_HCC114
		+ HCC115 * N2_HCC115
		+ HCC12 * N2_HCC12
		+ HCC122 * N2_HCC122
		+ HCC124 * N2_HCC124
		+ HCC134 * N2_HCC134
		+ HCC135 * N2_HCC135
		+ HCC136 * N2_HCC136
		+ HCC137 * N2_HCC137
		+ HCC157 * N2_HCC157
		+ HCC158 * N2_HCC158
		+ HCC161 * N2_HCC161
		+ HCC162 * N2_HCC162
		+ HCC166 * N2_HCC166
		+ HCC167 * N2_HCC167
		+ HCC169 * N2_HCC169
		+ HCC17 * N2_HCC17
		+ HCC170 * N2_HCC170
		+ HCC173 * N2_HCC173
		+ HCC176 * N2_HCC176
		+ HCC18 * N2_HCC18
		+ HCC186 * N2_HCC186
		+ HCC188 * N2_HCC188
		+ HCC189 * N2_HCC189
		+ HCC19 * N2_HCC19
		+ HCC2 * N2_HCC2
		+ HCC21 * N2_HCC21
		+ HCC22 * N2_HCC22
		+ HCC23 * N2_HCC23
		+ HCC27 * N2_HCC27
		+ HCC28 * N2_HCC28
		+ HCC29 * N2_HCC29
		+ HCC33 * N2_HCC33
		+ HCC34 * N2_HCC34
		+ HCC35 * N2_HCC35
		+ HCC39 * N2_HCC39
		+ HCC40 * N2_HCC40
		+ HCC46 * N2_HCC46
		+ HCC47 * N2_HCC47
		+ HCC48 * N2_HCC48
		+ HCC54 * N2_HCC54
		+ HCC55 * N2_HCC55
		+ HCC57 * N2_HCC57
		+ HCC58 * N2_HCC58
		+ HCC6 * N2_HCC6
		+ HCC70 * N2_HCC70
		+ HCC71 * N2_HCC71
		+ HCC72 * N2_HCC72
		+ HCC73 * N2_HCC73
		+ HCC74 * N2_HCC74
		+ HCC75 * N2_HCC75
		+ HCC76 * N2_HCC76
		+ HCC77 * N2_HCC77
		+ HCC78 * N2_HCC78
		+ HCC79 * N2_HCC79
		+ HCC8 * N2_HCC8
		+ HCC80 * N2_HCC80
		+ HCC82 * N2_HCC82
		+ HCC83 * N2_HCC83
		+ HCC84 * N2_HCC84
		+ HCC85 * N2_HCC85
		+ HCC86 * N2_HCC86
		+ HCC87 * N2_HCC87
		+ HCC88 * N2_HCC88
		+ HCC9 * N2_HCC9
		+ HCC96 * N2_HCC96
		+ HCC99 * N2_HCC99
		+ LTI * N2_LTI
		+ ORIGDS * N2_ORIGDS
		+ PRIOR_HOSP_W_ANY_IP_FLAG_90 * N2_PRIOR_HOSP_W_ANY_IP_FLAG_90
		+ SEPSIS_CARD_RESP_FAIL * N2_SEPSIS_CARD_RESP_FAIL
		+ TKA_FLAG * N2_TKA_FLAG
		+ TKA_FRACTURE_FLAG * N2_TKA_FRACTURE_FLAG
		+ N2_INTERCEPT
		+ (N2_SIGMA2*N2_SIGMA2)/2 
		))
		;
run;

data temp6;
	set temp5a temp5b;
run;

data tp_components_original;
	set tp.TP_Components_all;
	where time_period = 'Baseline';
	format ccn_join $6.;
	ccn_join = ASSOC_ACH_CCN;
	if ccn_join = '' then ccn_join = CCN_TIN;
	if length(compress(ccn_join)) = 5 then ccn_join = '0' || ccn_join;

	if EPI_CAT = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPI_CAT = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;
run;

proc sql;
	create table temp7 as
	select a.*, b.EPI_SPEND as EPI_SPEND_original
	from temp6 as a 
		left join tp_components_original as b
			on a.BPID = b.INITIATOR_BPID
			and a.EPISODE_GROUP_NAME = b.EPI_CAT
			and a.anchor_type_upper = b.EPI_TYPE
			and a.anc_ccn = b.ccn_join;
quit;

data t1;
	set temp7 (rename=(PCMA=PCMA_ROUND PAYMENT_RATIO=PAYMENT_RATIO_ROUND PAT=PAT_ROUND));

	PAT = PAT_2019Q3;
	PAYMENT_RATIO = TARGET_PRICE_REAL / TARGET_PRICE;
	PCMA = HBP / PAT / SBS;
	if HBP = . then PCMA = PGP_ACH_BNCHMRK / PAT / SBS;

	PCMA_Adj = Pred_Price/Amt;
	if length(compress(EPISODE_INITIATOR)) > 6 then do;
		PGP_PCMA_Adj = Pred_Price/Amt;
		PGP_ACH_Ratio = PGP_PCMA_Adj / PCMA;
		TP_Adj = TARGET_PRICE / CASE_MIX * PGP_ACH_Ratio;
	end;
	else TP_Adj = TARGET_PRICE / PCMA * PCMA_Adj;
run;

data t2;
	set ref.bpcia_performance_episodes;
	PERFORMANCE_PERIOD_EPI=1;
run;


proc sql;
	create table t3 as
	select a.*, coalesce(b.PERFORMANCE_PERIOD_EPI,0) as PERFORMANCE_PERIOD_EPI
	from t1 as a left join t2 as b
	on a.BPID=b.BPID and a.ANCHOR_TYPE=b.ANCHOR_TYPE and a.EPISODE_GROUP_NAME=b.EPISODE_GROUP_NAME;
quit;
	 
data out.tp_&label._&bpid1._&bpid2.;
	set t3 (rename=(anchor_ccn=anchor_ccn_orig EPI_STD_PMT_FCTR_WIN_1_99=EPI_STD_PMT_FCTR_WIN_1_99_orig)) ;
	format HAS_TP PERFORMANCE_PERIOD COMP_EP_FLAG $3.;

	/*if (&transmit_date. - anchor_end_dt) >= 60 then COMP_EP_FLAG = 'Yes';
	else COMP_EP_FLAG = 'No';*/
	COMP_EP_FLAG = 'Yes';

	PGP_Offset_Amt_Real=0;
	if PGP_Offset < 1 and PGP_Offset ^= . then PGP_Offset_Amt_Real = TP_Adj / .97 * (1-(PGP_Offset/PGP_Offset_Adj)) * PAYMENT_RATIO;

	PAT_Amt_Real=0;
	PAT_Amt_Real = TP_Adj / .97 * (1-(PAT_New/PAT)) * PAYMENT_RATIO;

	Discount_Real=0;
	Discount_Real = (-1) * TP_Adj / .97 * .03 * PAYMENT_RATIO;

	ANCHOR_CCN = anc_ccn;

	Adjusted_TP_Real = TP_Adj * PAYMENT_RATIO;

	%if &label. = ybase %then %do;
		if EPI_SPEND_Original ^= 0 then EPI_STD_PMT_FCTR_WIN_1_99 = EPI_STD_PMT_FCTR_WIN_1_99_orig * EPI_SPEND / EPI_SPEND_Original;
		EPI_STD_PMT_FCTR_WIN_1_99_Real = EPI_STD_PMT_FCTR_WIN_1_99 * PAYMENT_RATIO;
	%end;
	%else %do;
		EPI_STD_PMT_FCTR_WIN_1_99=EPI_STD_PMT_FCTR_WIN_1_99_orig;
		if EPI_DROPPED_FLAG = 0 then EPI_STD_PMT_FCTR_WIN_1_99_Real = EPI_STD_PMT_FCTR_WIN_1_99 * PAYMENT_RATIO;
		else EPI_STD_PMT_FCTR_WIN_1_99_Real = .;
	%end;
	*EPI_STD_PMT_FCTR_WIN_1_99_Real = EPI_STD_PMT_FCTR_WIN_1_99 * PAYMENT_RATIO;

	PAT_Adj = PAT_New;

	if TARGET_PRICE = . or PAYMENT_RATIO = . or COMP_EP_FLAG = 'No' then do;
		EPI_STD_PMT_FCTR_WIN_1_99_Real = .;
		Adjusted_TP_Real = .;
		Discount_Real = .;
		PGP_Offset_Amt_Real = .;
		PAT_Amt_Real = .;
	end;

	HAS_TP="Yes";
	if Adjusted_TP_Real=. then HAS_TP='No';

	if PERFORMANCE_PERIOD_EPI = 1 then PERFORMANCE_PERIOD = 'Yes';
	else PERFORMANCE_PERIOD = 'No';

run;

data out2.tp_&label._&bpid1._&bpid2.;
	set out.tp_&label._&bpid1._&bpid2. (rename=(ORIGDS=ORIGDS_orig LTI=LTI_orig FRACTURE_FLAG=FRACTURE_FLAG_orig ANY_DUAL=ANY_DUAL_orig TKA_FLAG=TKA_FLAG_orig PRIOR_HOSP_W_ANY_IP_FLAG_90=PRIOR_HOSP_W_ANY_IP_FLAG_90_orig
											HCC18=HCC18_orig HCC19=HCC19_orig HCC40=HCC40_orig HCC58=HCC58_orig HCC84=HCC84_orig HCC85=HCC85_orig HCC86=HCC86_orig HCC88=HCC88_orig HCC96=HCC96_orig HCC108=HCC108_orig HCC111=HCC111_orig));
	format ORIGDS LTI FRACTURE_FLAG ANY_DUAL TKA_FLAG PRIOR_HOSP_W_ANY_IP_FLAG_90 
			HCC_COUNT HCC18 HCC19 HCC40 HCC58 HCC84 HCC85 HCC86 HCC88 HCC96 HCC108 HCC111 $3. ;

	if ORIGDS_orig=1 then ORIGDS='Yes'; else ORIGDS='No';
	if LTI_orig=1 then LTI='Yes'; else LTI='No';
	if FRACTURE_FLAG_orig=1 then FRACTURE_FLAG='Yes'; else FRACTURE_FLAG='No';
	if ANY_DUAL_orig=1 then ANY_DUAL='Yes'; else ANY_DUAL='No';
	if TKA_FLAG_orig=1 then TKA_FLAG='Yes'; else TKA_FLAG='No';
	if PRIOR_HOSP_W_ANY_IP_FLAG_90_orig=1 then PRIOR_HOSP_W_ANY_IP_FLAG_90='Yes'; else PRIOR_HOSP_W_ANY_IP_FLAG_90='No';

	if HCC_CNT=0 then HCC_COUNT='0';
	else if HCC_CNT<=3 then HCC_COUNT='1-3';
	else if HCC_CNT<=6 then HCC_COUNT='4-6';
	else if HCC_CNT>=7 then HCC_COUNT='7+';

	if HCC18_orig=1 then HCC18='Yes'; else HCC18='No';
	if HCC19_orig=1 then HCC19='Yes'; else HCC19='No';
	if HCC40_orig=1 then HCC40='Yes'; else HCC40='No';
	if HCC58_orig=1 then HCC58='Yes'; else HCC58='No';
	if HCC84_orig=1 then HCC84='Yes'; else HCC84='No';
	if HCC85_orig=1 then HCC85='Yes'; else HCC85='No';
	if HCC86_orig=1 then HCC86='Yes'; else HCC86='No';
	if HCC88_orig=1 then HCC88='Yes'; else HCC88='No';
	if HCC96_orig=1 then HCC96='Yes'; else HCC96='No';
	if HCC108_orig=1 then HCC108='Yes'; else HCC108='No';
	if HCC111_orig=1 then HCC111='Yes'; else HCC111='No';


	keep BPID EPI_ID_MILLIMAN EPISODE_ID EPISODE_INITIATOR EPISODE_GROUP_NAME ANCHOR_TYPE ANCHOR_CODE ANCHOR_CCN
		 DRG_CODE PERF_APC ORIGDS LTI FRACTURE_FLAG ANY_DUAL TKA_FLAG TKA_FRACTURE_FLAG PRIOR_HOSP_W_ANY_IP_FLAG_90
		 EPI_STD_PMT_FCTR_WIN_1_99_Real Adjusted_TP_Real Discount_Real PGP_Offset_Amt_Real PAT_Amt_Real 
		 PAT PAT_Adj PCMA PCMA_Adj PGP_ACH_PCMA PGP_PCMA_Adj CASE_MIX PGP_ACH_Ratio PGP_Offset PGP_Offset_Adj PAYMENT_RATIO 
		 HAS_TP PERFORMANCE_PERIOD
		 HCC_COUNT HCC18 HCC19 HCC40 HCC58 HCC84 HCC85 HCC86 HCC88 HCC96 HCC108 HCC111
		;
run;


%mend;

/*
%runhosp(1148_0000,1148_0000,1148,0000,310008);
%runhosp(1167_0000,1167_0000,1167,0000,390173);
%runhosp(1343_0000,1343_0000,1343,0000,232856880);
%runhosp(1368_0000,1368_0000,1368,0000,390049);
%runhosp(2379_0000,2379_0000,2379,0000,310060);
%runhosp(2587_0000,2587_0000,2587,0000,310014);
%runhosp(2607_0000,2607_0000,2607,0000,223700669);
%runhosp(1931_0001,5479_0001,5479,0002,310051);


%runhosp(1032_0000,1032_0000,1032,0000,260886056);
%runhosp(1075_0000,1075_0000,1075,0000,360133);
%runhosp(1125_0000,1125_0000,1125,0000,070025);
%runhosp(1167_0000,1167_0000,1167,0000,390173);
%runhosp(1148_0000,1148_0000,1148,0000,310008);

%runhosp(1374_0001,1374_0001,1374,0004,420078);
*/

%runhosp(1125_0000,1125_0000,1125,0000,070025);
%runhosp(1148_0000,1148_0000,1148,0000,310008);
%runhosp(1167_0000,1167_0000,1167,0000,390173);
%runhosp(1209_0000,1209_0000,1209,0000,420004);
%runhosp(1343_0000,1343_0000,1343,0000,232856880);
%runhosp(1368_0000,1368_0000,1368,0000,390049);
%runhosp(1374_0001,1374_0001,1374,0004,420078);
%runhosp(1374_0001,1374_0001,1374,0008,420018);
%runhosp(1374_0001,1374_0001,1374,0009,420086);
%runhosp(1686_0001,1686_0001,1686,0002,752661095);
%runhosp(1688_0001,1688_0001,1688,0002,310588183);
%runhosp(1696_0001,1696_0001,1696,0002,571141121);
%runhosp(1710_0001,1710_0001,1710,0002,560963485);
%runhosp(1958_0000,1958_0000,1958,0000,390183);
%runhosp(2070_0000,2070_0000,2070,0000,100084);
%runhosp(2374_0000,2374_0000,2374,0000,390326);
%runhosp(2376_0000,2376_0000,2376,0000,390035);
%runhosp(2378_0000,2378_0000,2378,0000,390197);
%runhosp(2379_0000,2379_0000,2379,0000,310060);
%runhosp(2586_0001,2586_0001,2586,0002,360027);
%runhosp(2586_0001,2586_0001,2586,0003,360364);
%runhosp(2586_0001,2586_0001,2586,0004,100289);
%runhosp(2586_0001,2586_0001,2586,0005,360082);
%runhosp(2586_0001,2586_0001,2586,0006,360077);
%runhosp(2586_0001,2586_0001,2586,0007,360230);
%runhosp(1075_0000,1075_0000,1075,0000,360133);
%runhosp(2586_0001,2586_0001,2586,0009,360087);
%runhosp(2586_0001,2586_0001,2586,0010,360143);
%runhosp(2586_0001,2586_0001,2586,0011,360091);
%runhosp(2586_0001,2586_0001,2586,0012,360144);
%runhosp(2586_0001,2586_0001,2586,0013,360180);
%runhosp(2586_0001,2586_0001,2586,0014,360010);
%runhosp(2586_0001,2586_0001,2586,0015,650003177);
%runhosp(2586_0001,2586_0001,2586,0016,340714585);
%runhosp(2586_0001,2586_0001,2586,0017,341855775);
%runhosp(2586_0001,2586_0001,2586,0020,341843403);
%runhosp(2586_0001,2586_0001,2586,0021,113837554);
%runhosp(2586_0001,2586_0001,2586,0023,800410599);
%runhosp(2594_0000,2594_0000,2594,0000,070035);
%runhosp(2048_0000,2048_0000,2048,0000,360079);
%runhosp(2049_0000,2049_0000,2049,0000,360239);
%runhosp(2607_0000,2607_0000,2607,0000,223700669);
%runhosp(5038_0000,5038_0000,5038,0000,080007);
%runhosp(5050_0000,5050_0000,5050,0000,390194);
%runhosp(2587_0000,2587_0000,2587,0000,310014);
%runhosp(2589_0000,2589_0000,2589,0000,360132);
%runhosp(5154_0000,5154_0000,5154,0000,330005);
%runhosp(5282_0000,5282_0000,5282,0000,360155);
%runhosp(2631_0000,2631_0000,2631,0000,290021);
%runhosp(5037_0000,5037_0000,5037,0000,360360);
%runhosp(1931_0001,5478_0001,5478,0002,310015);
%runhosp(5043_0000,5043_0000,5043,0000,100002);
%runhosp(1931_0001,5479_0001,5479,0002,310051);
%runhosp(1931_0001,5480_0001,5480,0002,310017);
%runhosp(5215_0001,5215_0001,5215,0003,310092);
%runhosp(5215_0001,5215_0001,5215,0002,310044);
%runhosp(5229_0000,5229_0000,5229,0000,390009);
%runhosp(5263_0000,5263_0000,5263,0000,100281);
%runhosp(5264_0000,5264_0000,5264,0000,100038);
%runhosp(1931_0001,5481_0001,5481,0002,310028);
%runhosp(5394_0000,5394_0000,5394,0000,390267);
%runhosp(5395_0000,5395_0000,5395,0000,390050);
%runhosp(5397_0001,5397_0001,5397,0002,360137);
%runhosp(5397_0001,5397_0001,5397,0005,360145);
%runhosp(5397_0001,5397_0001,5397,0004,360041);
%runhosp(5397_0001,5397_0001,5397,0008,360078);
%runhosp(5397_0001,5397_0001,5397,0003,360359);
%runhosp(5397_0001,5397_0001,5397,0006,360192);
%runhosp(5397_0001,5397_0001,5397,0009,360002);
%runhosp(5397_0001,5397_0001,5397,0010,360123);
%runhosp(5105_0001,5916_0001,5916,0002,411861374);
%runhosp(5387_0001,6049_0001,6049,0002,450880);
%runhosp(5387_0001,6050_0001,6050,0002,450874);
%runhosp(5387_0001,6051_0001,6051,0002,030112);
%runhosp(5387_0001,6052_0001,6052,0002,670076);
%runhosp(5387_0001,6053_0001,6053,0002,450883);
%runhosp(5397_0001,5397_0001,5397,0007,360075);
%runhosp(1102_0000,1102_0000,1102,0000,390001);
%runhosp(1105_0000,1105_0000,1105,0000,390006);
%runhosp(1106_0000,1106_0000,1106,0000,390270);
%runhosp(1103_0000,1103_0000,1103,0000,390004);
%runhosp(1104_0000,1104_0000,1104,0000,390048);
%runhosp(5398_0001,5392_0001,5392,0004,110184);
%runhosp(5424_0001,6054_0001,6054,0002,330019);
%runhosp(5424_0001,6055_0001,6055,0002,330194);
%runhosp(5424_0001,6056_0001,6056,0002,330201);
%runhosp(5424_0001,6057_0001,6057,0002,330221);
%runhosp(5424_0001,6058_0001,6058,0002,330233);
%runhosp(5424_0001,6059_0001,6059,0002,330397);
%runhosp(1907_0000,5746_0001,5746,0002,100007);
%runhosp(1191_0001,1191_0001,1191,0002,61440790);


%MEND TP;

%TP(ybase);
%TP(y201903);

data All_Target_Prices;
	format BPID EPI_ID_MILLIMAN EPISODE_ID EPISODE_INITIATOR EPISODE_GROUP_NAME ANCHOR_TYPE ANCHOR_CODE ANCHOR_CCN
		 DRG_CODE PERF_APC ORIGDS LTI FRACTURE_FLAG ANY_DUAL TKA_FLAG TKA_FRACTURE_FLAG PRIOR_HOSP_W_ANY_IP_FLAG_90
		 EPI_STD_PMT_FCTR_WIN_1_99_Real Adjusted_TP_Real Discount_Real PGP_Offset_Amt_Real PAT_Amt_Real 
		 PAT PAT_Adj PCMA PCMA_Adj PGP_ACH_PCMA PGP_PCMA_Adj CASE_MIX PGP_ACH_Ratio PGP_Offset PGP_Offset_Adj PAYMENT_RATIO 
		 HAS_TP PERFORMANCE_PERIOD 
		 HCC_COUNT HCC18 HCC19 HCC40 HCC58 HCC84 HCC85 HCC86 HCC88 HCC96 HCC108 HCC111
		 ;
	set out2.tp_: ;
	if EPISODE_GROUP_NAME = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then 
		EPISODE_GROUP_NAME = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis";
run;

*Should be 0 observations;
data check;
	set All_Target_Prices;
	if (Adjusted_TP_Real > 0 and EPI_STD_PMT_FCTR_WIN_1_99_Real = .) or 
		(Adjusted_TP_Real = . and EPI_STD_PMT_FCTR_WIN_1_99_Real > 0) ;
run;
proc sql;
	create table check2 as
	select BPID, EPISODE_INITIATOR, ANCHOR_CCN, EPISODE_GROUP_NAME, ANCHOR_TYPE, count(*) as Episodes
	from check
	group by BPID, EPISODE_INITIATOR, ANCHOR_CCN, EPISODE_GROUP_NAME, ANCHOR_TYPE;
quit;
proc sql;
	create table check3 as
	select BPID, count(*) as BPID_Episodes
	from All_Target_Prices
	group by BPID;
quit;
proc sql;
	create table check4 as
	select a.*, b.BPID_Episodes, a.Episodes/b.BPID_Episodes as Percent_BPID_Epis
	from check2 as a left join check3 as b
	on a.BPID=b.BPID;
quit;

data All_Target_Prices_1 All_Target_Prices_Premier All_Target_Prices_NonPremier All_Target_Prices_Baseline;
	set All_Target_Prices;

	if BPID in (&PMR_EI_lst.) or BPID in (&NON_PMR_EI_lst.) then output All_Target_Prices_1;

	if BPID in (&PMR_EI_lst.) then output All_Target_Prices_Premier;
	else if BPID in (&NON_PMR_EI_lst.) then output All_Target_Prices_NonPremier;
	else if BPID in (&BASELINE_lst.) then output All_Target_Prices_Baseline;
run;
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
            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Target Prices_Premier.csv"
            dbms=csv replace; 
run;
proc export data= All_Target_Prices_NonPremier
            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Target Prices_Non-Premier.csv"
            dbms=csv replace; 
run;
proc export data= All_Target_Prices_Baseline
            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Target Prices_Baseline.csv"
            dbms=csv replace; 
run;


proc printto;run;
%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;


