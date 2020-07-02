%let  _sdtm=%sysfunc(datetime());
*********************************************************
*********************************************************
BPCIA: 201_Target Prices
Code to calculate target prices
*********************************************************
*********************************************************;
options mprint;

proc printto;run;

***** USER INPUTS ******************************************************************************************;
%let mode = main; *main = main interface, base = baseline interface;
%let label_monthly = y202005;
%let label_quarterly = y202004;
%let label_semi_annual = y202004;
%let label = &label_monthly.;

*%let mode = recon; *main = main interface, base = baseline interface;
*%let recon_label = pp1Initial;
****** REFERENCE PROGRAMS ***********************************************************************************;
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";

%let main = H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code;
%include "&main.\000 - Formats - BPCIA_MY3.sas";

%include "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code\000 - BPCIA_Interface_BPIDs.sas";

****** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
/*libname out "&dataDir.\07 - Processed Data";*/
/*libname out2 "&dataDir.\07 - Processed Data\Output";*/
libname tp "&dataDir.\08 - Target Price Data";

libname ref "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets" ;
libname bpciaref "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets" ;
libname genref "H:\Nonclient\Medicare Bundled Payment Reference\General\SAS Datasets" ;
libname cjrref "H:\Nonclient\Medicare Bundled Payment Reference\Program - CJR\SAS Datasets" ;


%macro modesetup;
%if &mode.=main %then %do;
libname out "&dataDir.\07 - Processed Data\";
libname out2 "&dataDir.\07 - Processed Data\Output";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\201 - MY3 Target Prices_&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=base %then %do;
libname out "&dataDir.\07 - Processed Data\Baseline Interface";
libname out2 "&dataDir.\07 - Processed Data\Baseline Interface\Output";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\201 - MY3 Baseline Target Prices_&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=dev %then %do;
libname out "&dataDir.\07 - Processed Data\Development";
libname out2 "&dataDir.\07 - Processed Data\Development\Output";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\201 - MY3 Dev Target Prices_&sysdate..log" print=print new;
run;
%end;
%mend modesetup;

%modesetup;


********************
********************
Calculation of Adjusted Target Prices
********************
********************;

data Peer_Group_pre Peer_Group_pre_baseline;
	set ref.Peer_Group_MY3;
	format ccn_join $6.;
	ccn_join = CCN;
	if length(compress(ccn_join)) = 5 then ccn_join = '0' || compress(ccn_join);

	format time_period $32. epi_start epi_end MMDDYY10.;
	time_period='Baseline - MY3';
	rel_dt=0;
	epi_start=mdy(10,1,2014);
	epi_end=mdy(9,30,2018);

	epi_dropped_flag=1;

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
	set ref.PAT_Factors_MY3;
	anchor_type='ip';
	if substr(Clinical_Episode,1,2) = 'OP' then anchor_type='op';
	if substr(Clinical_Episode,1,2) = 'MS' then anchor_type='ms';
	AMC = MTH;
	if anchor_type='op' then do;
		if Clinical_Episode = 'OP-Back & neck except spinal fusion' then Clinical_Episode = 'Back & neck except spinal fusion';
		if Clinical_Episode = 'OP-Cardiac defibrillator' then Clinical_Episode = 'Cardiac defibrillator';
		if Clinical_Episode = 'OP-Percutaneous coronary intervention' then Clinical_Episode = 'Percutaneous coronary intervention';
	end;
	if anchor_type='ms' then Clinical_Episode = 'Major joint replacement of the lower extremity';

	if Clinical_Episode = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		Clinical_Episode = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

	if Clinical_Episode = "Transcathether aortic valve replacement" then
		Clinical_Episode = "Endovascular Cardiac Valve Replacement" ;

	output;
	if anchor_type='ms' then do;
		anchor_type='ip'; output;
		anchor_type='op'; output;
	end;
run;

proc sort nodupkey data=PAT_Factors out=PAT_Factors_forBase;
	by Clinical_Episode anchor_type AMC MTH Urban_Rural Safety_Net Bed_Size Census_Div Year Quarter;
run;

data PAT_Factors_baseline;
	set ref.PAT_Factors_baseline_MY3;
	anchor_type='ip';
	if substr(Clinical_Episode,1,2) = 'OP' then anchor_type='op';
	if substr(Clinical_Episode,1,2) = 'MS' then anchor_type='ms';
	AMC = MTH;
	if anchor_type='op' then do;
		if Clinical_Episode = 'OP-Back & neck except spinal fusion' then Clinical_Episode = 'Back & neck except spinal fusion';
		if Clinical_Episode = 'OP-Cardiac defibrillator' then Clinical_Episode = 'Cardiac defibrillator';
		if Clinical_Episode = 'OP-Percutaneous coronary intervention' then Clinical_Episode = 'Percutaneous coronary intervention';
	end;
	if anchor_type='ms' then Clinical_Episode = 'Major joint replacement of the lower extremity';

	if Clinical_Episode = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		Clinical_Episode = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

	if Clinical_Episode = "Transcathether aortic valve replacement" then
		Clinical_Episode = "Endovascular Cardiac Valve Replacement" ;

	output;
	if anchor_type='ms' then do;
		anchor_type='ip'; output;
		anchor_type='op'; output;
	end;
run;

data TP_Components;
	set tp.TP_Components_MY3_all;
	format ccn_join $6.;
	ccn_join = ASSOC_ACH_CCN;
	if ccn_join = '' then ccn_join = CCN_TIN;
	if length(compress(ccn_join)) = 5 then ccn_join = '0' || ccn_join;

	if EPI_CAT = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPI_CAT = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

	if EPI_CAT = "Transcathether aortic valve replacement" then
		EPI_CAT = "Endovascular Cardiac Valve Replacement" ;

if EPI_CAT = "Inflammatory bowel disease" then        
	EPI_CAT = "Inflammatory Bowel Disease" ;

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
	set ref.TP_Risk_Parameters_MY3;

	if Clinical_Episode_Category = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		Clinical_Episode_Category = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

	if Clinical_Episode_Category = "Transcathether aortic valve replacement" then
		Clinical_Episode_Category = "Endovascular Cardiac Valve Replacement" ;
run;

proc sort nodupkey data=TP_Risk_Adj_Parameters out=TP_Risk_Adj_Parameters_forBase;
	by Clinical_Episode_Category Clinical_Episode_Type;
run;

data TP_Risk_Adj_Parameters_baseline;
	set ref.TP_Risk_Parameters_baseline_MY3;

	if Clinical_Episode_Category = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		Clinical_Episode_Category = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

	if Clinical_Episode_Category = "Transcathether aortic valve replacement" then
		Clinical_Episode_Category = "Endovascular Cardiac Valve Replacement" ;
run;

%MACRO TP(label, type);

%MACRO RunHosp(id1,id2,bpid1,bpid2,prov,reconref);

%if &type = P AND (&bpid1. = 1075 or &bpid1. = 2048 or &bpid1. = 2049 or &bpid1. = 2589 or &bpid1. = 5037) %then %do;
%let label = &label_quarterly.;
%end;

%else %if &type = P and &bpid1. = 1148 %then %do;
%let label = &label_semi_annual.; 
%end;

%else %if &type = P %then %do;
%let label = &label_monthly.; 
%end;

%else %if &type = B %then %do;
%let label = ybase; 
%end;

%else %if &type = R %then %do;
%let label = &recon_label.; 
%end;

data temp0;
	format BPID $9. EPI_ID_MILLIMAN $32. ;
	set out.epi_&label._&bpid1._&bpid2. ;
	if measure_year = 'MY3';
	if EPISODE_GROUP_NAME = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPISODE_GROUP_NAME = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

	if ANCHOR_TYPE = 'ip' then anchor_type_upper = 'IP';
	else if ANCHOR_TYPE = 'op' then anchor_type_upper = 'OP';
	if EPISODE_GROUP_NAME = 'Major joint replacement of the lower extremity' then anchor_type_upper = 'MS';

	HCC54=0;
	HCC55=0;
	DISABLED_HCC54=0;
	DISABLED_HCC55=0;

	drop TKA_FLAG PRIOR_HOSP_W_ANY_IP_FLAG_90 EPI_DROPPED_FLAG TARGET_PRICE TARGET_PRICE_REAL;
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

%if %substr(&label.,1,5)  ^= ybase %then %do;
	proc sql;
		create table temp1a_pre as
		select a.*, b.Major_Teaching_Hospital as ACADEMIC, b.Urban as URBAN_RURAL, b.SAFETY_NET, b.BED_SIZE as BED_SIZE_join, b.CENSUS_Division as CENSUS_Pre
		from temp1_prea as a left join Peer_Group as b
		on a.anc_ccn = b.ccn_join
			and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end;
	quit;
%end;
%else %do;
	proc sql;
		create table temp1a_pre as
		select a.*, b.Major_Teaching_Hospital, b.Urban as URBAN_RURAL, b.SAFETY_NET, b.BED_SIZE as BED_SIZE_join, b.CENSUS_Division as CENSUS_Pre
		from temp1_prea as a left join Peer_Group_forBase as b
		on a.anc_ccn = b.ccn_join;
	quit;
%end;

data temp1a;
	set temp1a_pre;
	format BED_SIZE $11.;
	CENSUS = input(CENSUS_Pre,12.);
	if BED_SIZE_join = 'Extra' then BED_SIZE = 'Extra Large';
	else Bed_SIZE = BED_SIZE_join;
run;

%if %substr(&label.,1,5)  ^= ybase %then %do;
	proc sql;
		create table temp2a as
		select a.*, b.*
		from temp1a as a left join TP_Risk_Adj_Parameters as b
		on a.EPISODE_GROUP_NAME = b.Clinical_Episode_Category
			and a.anchor_type_upper = b.Clinical_Episode_Type
			and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end;
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

%if %substr(&label.,1,5)  ^= ybase %then %do;
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
			and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end;
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
			and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end;
	quit;
%end;
%else %do;
	proc sql;
		create table temp3a_pre as
		select a.*, b.PAT_Factor as PAT_New
		from temp2a as a left join PAT_Factors_forBase as b
		on a.EPISODE_GROUP_NAME = b.Clinical_Episode
			and a.ANCHOR_TYPE=b.anchor_type
			and a.Major_Teaching_Hospital=b.MTH
			and a.URBAN_RURAL=b.Urban_Rural
			and a.SAFETY_NET=b.Safety_Net
			and a.BED_SIZE=b.Bed_Size
			and a.CENSUS=b.Census_Div
			and year(a.POST_DSCH_END_DT)=b.Year
			and qtr(a.POST_DSCH_END_DT)=b.Quarter;
	quit;

	proc sql;
		create table temp3a as
		select a.*, b.PAT_Factor as PAT_2020Q3
		from temp3a_pre as a left join PAT_Factors_forBase as b
		on a.EPISODE_GROUP_NAME = b.Clinical_Episode
			and a.ANCHOR_TYPE=b.anchor_type
			and a.Major_Teaching_Hospital=b.MTH
			and a.URBAN_RURAL=b.Urban_Rural
			and a.SAFETY_NET=b.Safety_Net
			and a.BED_SIZE=b.Bed_Size
			and a.CENSUS=b.Census_Div
			and b.Year=2020
			and b.Quarter=3;
	quit;
%end;


%if %substr(&label.,1,5)  ^= ybase %then %do;
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
			b.TIME_PERIOD,
			b.Prelim_TP,
	b.Final_TP,
	b.TP_Difference
		from temp3a as a 
			left join TP_Components as b
				on a.BPID = b.INITIATOR_BPID
				and a.EPISODE_GROUP_NAME = b.EPI_CAT
				and a.anchor_type_upper = b.EPI_TYPE
				and a.anc_ccn = b.ccn_join
				and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end;
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
			b.PAT_Adj as PAT_Historical_Adj,
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
			b.TIME_PERIOD,
			b.Prelim_TP,
	b.Final_TP,
	b.TP_Difference
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
	%if %substr(&label.,1,5)  = ybase %then %do; 
		DRG_CODE=DRG_2019; 
	%end;
	%else %do;
		if ANCHOR_TYPE = 'ip' then DRG_CODE = input(ANCHOR_CODE,$20.);
		else DRG_CODE = . ;
	%end;

	Epi_Year = year(POST_DSCH_END_DT);
	Epi_Qtr = qtr(POST_DSCH_END_DT);
	Epi_Half = 1;
	if Epi_Qtr in (3,4) then Epi_Half = 2;

	DRG_CD_061=0;
	DRG_CD_062=0;
	DRG_CD_063=0;
	DRG_CD_064=0;
	DRG_CD_066=0;
	DRG_CD_100=0;
	DRG_CD_177=0;
	DRG_CD_178=0;
	DRG_CD_179=0;
	DRG_CD_191=0;
	DRG_CD_192=0;
	DRG_CD_193=0;
	DRG_CD_195=0;
	DRG_CD_202=0;
	DRG_CD_203=0;
	DRG_CD_216=0;
	DRG_CD_217=0;
	DRG_CD_218=0;
	DRG_CD_219=0;
	DRG_CD_221=0;
	DRG_CD_222=0;
	DRG_CD_223=0;
	DRG_CD_224=0;
	DRG_CD_225=0;
	DRG_CD_226=0;
	DRG_CD_231=0;
	DRG_CD_232=0;
	DRG_CD_233=0;
	DRG_CD_234=0;
	DRG_CD_235=0;
	DRG_CD_242=0;
	DRG_CD_244=0;
	DRG_CD_246=0;
	DRG_CD_248=0;
	DRG_CD_249=0;
	DRG_CD_250=0;
	DRG_CD_251=0;
	DRG_CD_266=0;
	DRG_CD_281=0;
	DRG_CD_282=0;
	DRG_CD_292=0;
	DRG_CD_293=0;
	DRG_CD_308=0;
	DRG_CD_310=0;
	DRG_CD_329=0;
	DRG_CD_331=0;
	DRG_CD_377=0;
	DRG_CD_379=0;
	DRG_CD_385=0;
	DRG_CD_387=0;
	DRG_CD_388=0;
	DRG_CD_390=0;
	DRG_CD_441=0;
	DRG_CD_443=0;
	DRG_CD_453=0;
	DRG_CD_454=0;
	DRG_CD_455=0;
	DRG_CD_459=0;
	DRG_CD_461=0;
	DRG_CD_469=0;
	DRG_CD_471=0;
	DRG_CD_472=0;
	DRG_CD_473=0;
	DRG_CD_480=0;
	DRG_CD_482=0;
	DRG_CD_492=0;
	DRG_CD_494=0;
	DRG_CD_518=0;
	DRG_CD_519=0;
	DRG_CD_533=0;
	DRG_CD_534=0;
	DRG_CD_535=0;
	DRG_CD_602=0;
	DRG_CD_619=0;
	DRG_CD_620=0;
	DRG_CD_682=0;
	DRG_CD_684=0;
	DRG_CD_689=0;
	DRG_CD_870=0;
	DRG_CD_872=0;

	APC_5115=0;
	APC_5192=0;
	APC_5194=0;
	APC_5231=0;
	APC_5432=0;

	FY_2018=0;
	FY2018_DRG_453=0;
	FY2018_DRG_454=0;
	FY2018_DRG_455=0;
	FY2018_DRG_459=0;
	FY2018_DRG_471=0;
	FY2018_DRG_472=0;
	FY2018_DRG_473=0;

	if DRG_CODE = 061 then DRG_CD_061=1;
	if DRG_CODE = 062 then DRG_CD_062=1;
	if DRG_CODE = 063 then DRG_CD_063=1;
	if DRG_CODE = 064 then DRG_CD_064=1;
	if DRG_CODE = 066 then DRG_CD_066=1;
	if DRG_CODE = 100 then DRG_CD_100=1;
	if DRG_CODE = 177 then DRG_CD_177=1;
	if DRG_CODE = 178 then DRG_CD_178=1;
	if DRG_CODE = 179 then DRG_CD_179=1;
	if DRG_CODE = 191 then DRG_CD_191=1;
	if DRG_CODE = 192 then DRG_CD_192=1;
	if DRG_CODE = 193 then DRG_CD_193=1;
	if DRG_CODE = 195 then DRG_CD_195=1;
	if DRG_CODE = 202 then DRG_CD_202=1;
	if DRG_CODE = 203 then DRG_CD_203=1;
	if DRG_CODE = 216 then DRG_CD_216=1;
	if DRG_CODE = 217 then DRG_CD_217=1;
	if DRG_CODE = 218 then DRG_CD_218=1;
	if DRG_CODE = 219 then DRG_CD_219=1;
	if DRG_CODE = 221 then DRG_CD_221=1;
	if DRG_CODE = 222 then DRG_CD_222=1;
	if DRG_CODE = 223 then DRG_CD_223=1;
	if DRG_CODE = 224 then DRG_CD_224=1;
	if DRG_CODE = 225 then DRG_CD_225=1;
	if DRG_CODE = 226 then DRG_CD_226=1;
	if DRG_CODE = 231 then DRG_CD_231=1;
	if DRG_CODE = 232 then DRG_CD_232=1;
	if DRG_CODE = 233 then DRG_CD_233=1;
	if DRG_CODE = 234 then DRG_CD_234=1;
	if DRG_CODE = 235 then DRG_CD_235=1;
	if DRG_CODE = 242 then DRG_CD_242=1;
	if DRG_CODE = 244 then DRG_CD_244=1;
	if DRG_CODE = 246 then DRG_CD_246=1;
	if DRG_CODE = 248 then DRG_CD_248=1;
	if DRG_CODE = 249 then DRG_CD_249=1;
	if DRG_CODE = 250 then DRG_CD_250=1;
	if DRG_CODE = 251 then DRG_CD_251=1;
	if DRG_CODE = 266 then DRG_CD_266=1;
	if DRG_CODE = 281 then DRG_CD_281=1;
	if DRG_CODE = 282 then DRG_CD_282=1;
	if DRG_CODE = 292 then DRG_CD_292=1;
	if DRG_CODE = 293 then DRG_CD_293=1;
	if DRG_CODE = 308 then DRG_CD_308=1;
	if DRG_CODE = 310 then DRG_CD_310=1;
	if DRG_CODE = 329 then DRG_CD_329=1;
	if DRG_CODE = 331 then DRG_CD_331=1;
	if DRG_CODE = 377 then DRG_CD_377=1;
	if DRG_CODE = 379 then DRG_CD_379=1;
	if DRG_CODE = 385 then DRG_CD_385=1;
	if DRG_CODE = 387 then DRG_CD_387=1;
	if DRG_CODE = 388 then DRG_CD_388=1;
	if DRG_CODE = 390 then DRG_CD_390=1;
	if DRG_CODE = 441 then DRG_CD_441=1;
	if DRG_CODE = 443 then DRG_CD_443=1;
	if DRG_CODE = 453 then DRG_CD_453=1;
	if DRG_CODE = 454 then DRG_CD_454=1;
	if DRG_CODE = 455 then DRG_CD_455=1;
	if DRG_CODE = 459 then DRG_CD_459=1;
	if DRG_CODE = 461 then DRG_CD_461=1;
	if DRG_CODE = 469 then DRG_CD_469=1;
	if DRG_CODE = 471 then DRG_CD_471=1;
	if DRG_CODE = 472 then DRG_CD_472=1;
	if DRG_CODE = 473 then DRG_CD_473=1;
	if DRG_CODE = 480 then DRG_CD_480=1;
	if DRG_CODE = 482 then DRG_CD_482=1;
	if DRG_CODE = 492 then DRG_CD_492=1;
	if DRG_CODE = 494 then DRG_CD_494=1;
	if DRG_CODE = 518 then DRG_CD_518=1;
	if DRG_CODE = 519 then DRG_CD_519=1;
	if DRG_CODE = 533 then DRG_CD_533=1;
	if DRG_CODE = 534 then DRG_CD_534=1;
	if DRG_CODE = 535 then DRG_CD_535=1;
	if DRG_CODE = 602 then DRG_CD_602=1;
	if DRG_CODE = 619 then DRG_CD_619=1;
	if DRG_CODE = 620 then DRG_CD_620=1;
	if DRG_CODE = 682 then DRG_CD_682=1;
	if DRG_CODE = 684 then DRG_CD_684=1;
	if DRG_CODE = 689 then DRG_CD_689=1;
	if DRG_CODE = 870 then DRG_CD_870=1;
	if DRG_CODE = 872 then DRG_CD_872=1;
	*if ANCHOR_TYPE='op' and EPISODE_GROUP_NAME = 'Major joint replacement of the lower extremity' then DRG_CD_470=1;

	if PERF_APC = 5115 then APC_5115=1;
	if PERF_APC = 5192 then APC_5192=1;
	if PERF_APC = 5194 then APC_5194=1;
	if PERF_APC = 5231 then APC_5231=1;
	if PERF_APC = 5432 then APC_5432=1;

	if ANCHOR_END_DT >= mdy(10,1,2017) then FY_2018=1;
	if FY_2018=1 then do;
		if DRG_CODE = 453 then FY2018_DRG_453=1;
		if DRG_CODE = 454 then FY2018_DRG_454=1;
		if DRG_CODE = 455 then FY2018_DRG_455=1;
		if DRG_CODE = 459 then FY2018_DRG_459=1;
		if DRG_CODE = 471 then FY2018_DRG_471=1;
		if DRG_CODE = 472 then FY2018_DRG_472=1;
		if DRG_CODE = 473 then FY2018_DRG_473=1;
	end;

	HCC_CNT = sum(of HCC1 -- HCC189);
	HCC_CNT_1_3=0;
	HCC_CNT_4_6=0;
	HCC_CNT_7_PLUS=0;
	HCC_CNT_4_6_HCC_CNT_7_PLUS=0;
	if HCC_CNT > 0 then do;
		if HCC_CNT <= 3 then HCC_CNT_1_3=1;
		else if HCC_CNT <= 6 then HCC_CNT_4_6=1;
		else if HCC_CNT >= 7 then HCC_CNT_7_PLUS=1;
		if HCC_CNT >= 4 then HCC_CNT_4_6_HCC_CNT_7_PLUS=1;
	end; 


Pred_Price = (N1_P1 * EXP(
		  (BENE_AGE-50) * N1_Age_50
		+ (BENE_AGE-50) * (BENE_AGE-50) * N1_Age_50_SQ
		+ ANY_DUAL * N1_ANY_DUAL
		+ APC_5115 * N1_APC_5115
		+ APC_5192 * N1_APC_5192
		+ APC_5194 * N1_APC_5194
		+ APC_5231 * N1_APC_5231
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
		+ DRG_CD_061 * N1_DRG_CD_061
		+ DRG_CD_062 * N1_DRG_CD_062
		+ DRG_CD_063 * N1_DRG_CD_063
		+ DRG_CD_064 * N1_DRG_CD_064
		+ DRG_CD_066 * N1_DRG_CD_066
		+ DRG_CD_100 * N1_DRG_CD_100
		+ DRG_CD_177 * N1_DRG_CD_177
		+ DRG_CD_178 * N1_DRG_CD_178
		+ DRG_CD_179 * N1_DRG_CD_179
		+ DRG_CD_191 * N1_DRG_CD_191
		+ DRG_CD_192 * N1_DRG_CD_192
		+ DRG_CD_193 * N1_DRG_CD_193
		+ DRG_CD_195 * N1_DRG_CD_195
		+ DRG_CD_202 * N1_DRG_CD_202
		+ DRG_CD_203 * N1_DRG_CD_203
		+ DRG_CD_216 * N1_DRG_CD_216
		+ DRG_CD_217 * N1_DRG_CD_217
		+ DRG_CD_218 * N1_DRG_CD_218
		+ DRG_CD_219 * N1_DRG_CD_219
		+ DRG_CD_221 * N1_DRG_CD_221
		+ DRG_CD_222 * N1_DRG_CD_222
		+ DRG_CD_223 * N1_DRG_CD_223
		+ DRG_CD_224 * N1_DRG_CD_224
		+ DRG_CD_225 * N1_DRG_CD_225
		+ DRG_CD_226 * N1_DRG_CD_226
		+ DRG_CD_231 * N1_DRG_CD_231
		+ DRG_CD_232 * N1_DRG_CD_232
		+ DRG_CD_233 * N1_DRG_CD_233
		+ DRG_CD_234 * N1_DRG_CD_234
		+ DRG_CD_235 * N1_DRG_CD_235
		+ DRG_CD_242 * N1_DRG_CD_242
		+ DRG_CD_244 * N1_DRG_CD_244
		+ DRG_CD_246 * N1_DRG_CD_246
		+ DRG_CD_248 * N1_DRG_CD_248
		+ DRG_CD_249 * N1_DRG_CD_249
		+ DRG_CD_250 * N1_DRG_CD_250
		+ DRG_CD_251 * N1_DRG_CD_251
		+ DRG_CD_266 * N1_DRG_CD_266
		+ DRG_CD_281 * N1_DRG_CD_281
		+ DRG_CD_282 * N1_DRG_CD_282
		+ DRG_CD_292 * N1_DRG_CD_292
		+ DRG_CD_293 * N1_DRG_CD_293
		+ DRG_CD_308 * N1_DRG_CD_308
		+ DRG_CD_310 * N1_DRG_CD_310
		+ DRG_CD_329 * N1_DRG_CD_329
		+ DRG_CD_331 * N1_DRG_CD_331
		+ DRG_CD_377 * N1_DRG_CD_377
		+ DRG_CD_379 * N1_DRG_CD_379
		+ DRG_CD_385 * N1_DRG_CD_385
		+ DRG_CD_387 * N1_DRG_CD_387
		+ DRG_CD_388 * N1_DRG_CD_388
		+ DRG_CD_390 * N1_DRG_CD_390
		+ DRG_CD_441 * N1_DRG_CD_441
		+ DRG_CD_443 * N1_DRG_CD_443
		+ DRG_CD_453 * N1_DRG_CD_453
		+ DRG_CD_454 * N1_DRG_CD_454
		+ DRG_CD_455 * N1_DRG_CD_455
		+ DRG_CD_459 * N1_DRG_CD_459
		+ DRG_CD_461 * N1_DRG_CD_461
		+ DRG_CD_469 * N1_DRG_CD_469
		+ DRG_CD_471 * N1_DRG_CD_471
		+ DRG_CD_472 * N1_DRG_CD_472
		+ DRG_CD_473 * N1_DRG_CD_473
		+ DRG_CD_480 * N1_DRG_CD_480
		+ DRG_CD_482 * N1_DRG_CD_482
		+ DRG_CD_492 * N1_DRG_CD_492
		+ DRG_CD_494 * N1_DRG_CD_494
		+ DRG_CD_518 * N1_DRG_CD_518
		+ DRG_CD_519 * N1_DRG_CD_519
		+ DRG_CD_533 * N1_DRG_CD_533
		+ DRG_CD_534 * N1_DRG_CD_534
		+ DRG_CD_535 * N1_DRG_CD_535
		+ DRG_CD_602 * N1_DRG_CD_602
		+ DRG_CD_619 * N1_DRG_CD_619
		+ DRG_CD_620 * N1_DRG_CD_620
		+ DRG_CD_682 * N1_DRG_CD_682
		+ DRG_CD_684 * N1_DRG_CD_684
		+ DRG_CD_689 * N1_DRG_CD_689
		+ DRG_CD_870 * N1_DRG_CD_870
		+ DRG_CD_872 * N1_DRG_CD_872
		+ FRACTURE_FLAG * N1_FRACTURE_FLAG
		+ FY_2018 * N1_FY_2018
		+ FY2018_DRG_453 * N1_FY2018_DRG_453
		+ FY2018_DRG_454 * N1_FY2018_DRG_454
		+ FY2018_DRG_455 * N1_FY2018_DRG_455
		+ FY2018_DRG_459 * N1_FY2018_DRG_459
		+ FY2018_DRG_471 * N1_FY2018_DRG_471
		+ FY2018_DRG_472 * N1_FY2018_DRG_472
		+ FY2018_DRG_473 * N1_FY2018_DRG_473
		+ HCC_CNT_1_3 * N1_HCC_CNT_1_3
		+ HCC_CNT_4_6 * N1_HCC_CNT_4_6
		+ HCC_CNT_7_PLUS * N1_HCC_CNT_7_PLUS
		+ HCC_CNT_4_6_HCC_CNT_7_PLUS * N1_HCC_CNT_4_6_HCC_CNT_7_PLUS
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
		+ HEM_STROKE_FLAG * N1_HEM_STROKE_FLAG
		+ IBD_FISTULA_FLAG * N1_IBD_FISTULA_FLAG
		+ IBD_UC_FLAG * N1_IBD_UC_FLAG
		+ KNEE_ARTHRO_FLAG * N1_KNEE_ARTHRO_FLAG
		+ KNEE_ARTHRO_FRACTURE_FLAG * N1_KNEE_ARTHRO_FRACTURE_FLAG
		+ LTI * N1_LTI
		+ ORIGDS * N1_ORIGDS
		+ PRIOR_HOSP_W_NON_PAC_IP_FLAG_90 * N1_PRIOR_HOSP_W_NON_PAC_IP_FLAG
		+ PRIOR_PAC_FLAG * N1_PRIOR_PAC_FLAG
		+ SEPSIS_CARD_RESP_FAIL * N1_SEPSIS_CARD_RESP_FAIL
		+ N1_INTERCEPT
		+ (N1_SIGMA1*N1_SIGMA1)/2 
		))
		+
		(N2_P2 * EXP(
		  (BENE_AGE-50) * N2_Age_50
		+ (BENE_AGE-50) * (BENE_AGE-50) * N2_Age_50_SQ
		+ ANY_DUAL * N2_ANY_DUAL
		+ APC_5115 * N2_APC_5115
		+ APC_5192 * N2_APC_5192
		+ APC_5194 * N2_APC_5194
		+ APC_5231 * N2_APC_5231
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
		+ DRG_CD_061 * N2_DRG_CD_061
		+ DRG_CD_062 * N2_DRG_CD_062
		+ DRG_CD_063 * N2_DRG_CD_063
		+ DRG_CD_064 * N2_DRG_CD_064
		+ DRG_CD_066 * N2_DRG_CD_066
		+ DRG_CD_100 * N2_DRG_CD_100
		+ DRG_CD_177 * N2_DRG_CD_177
		+ DRG_CD_178 * N2_DRG_CD_178
		+ DRG_CD_179 * N2_DRG_CD_179
		+ DRG_CD_191 * N2_DRG_CD_191
		+ DRG_CD_192 * N2_DRG_CD_192
		+ DRG_CD_193 * N2_DRG_CD_193
		+ DRG_CD_195 * N2_DRG_CD_195
		+ DRG_CD_202 * N2_DRG_CD_202
		+ DRG_CD_203 * N2_DRG_CD_203
		+ DRG_CD_216 * N2_DRG_CD_216
		+ DRG_CD_217 * N2_DRG_CD_217
		+ DRG_CD_218 * N2_DRG_CD_218
		+ DRG_CD_219 * N2_DRG_CD_219
		+ DRG_CD_221 * N2_DRG_CD_221
		+ DRG_CD_222 * N2_DRG_CD_222
		+ DRG_CD_223 * N2_DRG_CD_223
		+ DRG_CD_224 * N2_DRG_CD_224
		+ DRG_CD_225 * N2_DRG_CD_225
		+ DRG_CD_226 * N2_DRG_CD_226
		+ DRG_CD_231 * N2_DRG_CD_231
		+ DRG_CD_232 * N2_DRG_CD_232
		+ DRG_CD_233 * N2_DRG_CD_233
		+ DRG_CD_234 * N2_DRG_CD_234
		+ DRG_CD_235 * N2_DRG_CD_235
		+ DRG_CD_242 * N2_DRG_CD_242
		+ DRG_CD_244 * N2_DRG_CD_244
		+ DRG_CD_246 * N2_DRG_CD_246
		+ DRG_CD_248 * N2_DRG_CD_248
		+ DRG_CD_249 * N2_DRG_CD_249
		+ DRG_CD_250 * N2_DRG_CD_250
		+ DRG_CD_251 * N2_DRG_CD_251
		+ DRG_CD_266 * N2_DRG_CD_266
		+ DRG_CD_281 * N2_DRG_CD_281
		+ DRG_CD_282 * N2_DRG_CD_282
		+ DRG_CD_292 * N2_DRG_CD_292
		+ DRG_CD_293 * N2_DRG_CD_293
		+ DRG_CD_308 * N2_DRG_CD_308
		+ DRG_CD_310 * N2_DRG_CD_310
		+ DRG_CD_329 * N2_DRG_CD_329
		+ DRG_CD_331 * N2_DRG_CD_331
		+ DRG_CD_377 * N2_DRG_CD_377
		+ DRG_CD_379 * N2_DRG_CD_379
		+ DRG_CD_385 * N2_DRG_CD_385
		+ DRG_CD_387 * N2_DRG_CD_387
		+ DRG_CD_388 * N2_DRG_CD_388
		+ DRG_CD_390 * N2_DRG_CD_390
		+ DRG_CD_441 * N2_DRG_CD_441
		+ DRG_CD_443 * N2_DRG_CD_443
		+ DRG_CD_453 * N2_DRG_CD_453
		+ DRG_CD_454 * N2_DRG_CD_454
		+ DRG_CD_455 * N2_DRG_CD_455
		+ DRG_CD_459 * N2_DRG_CD_459
		+ DRG_CD_461 * N2_DRG_CD_461
		+ DRG_CD_469 * N2_DRG_CD_469
		+ DRG_CD_471 * N2_DRG_CD_471
		+ DRG_CD_472 * N2_DRG_CD_472
		+ DRG_CD_473 * N2_DRG_CD_473
		+ DRG_CD_480 * N2_DRG_CD_480
		+ DRG_CD_482 * N2_DRG_CD_482
		+ DRG_CD_492 * N2_DRG_CD_492
		+ DRG_CD_494 * N2_DRG_CD_494
		+ DRG_CD_518 * N2_DRG_CD_518
		+ DRG_CD_519 * N2_DRG_CD_519
		+ DRG_CD_533 * N2_DRG_CD_533
		+ DRG_CD_534 * N2_DRG_CD_534
		+ DRG_CD_535 * N2_DRG_CD_535
		+ DRG_CD_602 * N2_DRG_CD_602
		+ DRG_CD_619 * N2_DRG_CD_619
		+ DRG_CD_620 * N2_DRG_CD_620
		+ DRG_CD_682 * N2_DRG_CD_682
		+ DRG_CD_684 * N2_DRG_CD_684
		+ DRG_CD_689 * N2_DRG_CD_689
		+ DRG_CD_870 * N2_DRG_CD_870
		+ DRG_CD_872 * N2_DRG_CD_872
		+ FRACTURE_FLAG * N2_FRACTURE_FLAG
		+ FY_2018 * N2_FY_2018
		+ FY2018_DRG_453 * N2_FY2018_DRG_453
		+ FY2018_DRG_454 * N2_FY2018_DRG_454
		+ FY2018_DRG_455 * N2_FY2018_DRG_455
		+ FY2018_DRG_459 * N2_FY2018_DRG_459
		+ FY2018_DRG_471 * N2_FY2018_DRG_471
		+ FY2018_DRG_472 * N2_FY2018_DRG_472
		+ FY2018_DRG_473 * N2_FY2018_DRG_473
		+ HCC_CNT_1_3 * N2_HCC_CNT_1_3
		+ HCC_CNT_4_6 * N2_HCC_CNT_4_6
		+ HCC_CNT_7_PLUS * N2_HCC_CNT_7_PLUS
		+ HCC_CNT_4_6_HCC_CNT_7_PLUS * N2_HCC_CNT_4_6_HCC_CNT_7_PLUS
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
		+ HEM_STROKE_FLAG * N2_HEM_STROKE_FLAG
		+ IBD_FISTULA_FLAG * N2_IBD_FISTULA_FLAG
		+ IBD_UC_FLAG * N2_IBD_UC_FLAG
		+ KNEE_ARTHRO_FLAG * N2_KNEE_ARTHRO_FLAG
		+ KNEE_ARTHRO_FRACTURE_FLAG * N2_KNEE_ARTHRO_FRACTURE_FLAG
		+ LTI * N2_LTI
		+ ORIGDS * N2_ORIGDS
		+ PRIOR_HOSP_W_NON_PAC_IP_FLAG_90 * N2_PRIOR_HOSP_W_NON_PAC_IP_FLAG
		+ PRIOR_PAC_FLAG * N2_PRIOR_PAC_FLAG
		+ SEPSIS_CARD_RESP_FAIL * N2_SEPSIS_CARD_RESP_FAIL
		+ N2_INTERCEPT
		+ (N2_SIGMA2*N2_SIGMA2)/2 
		))
		;
run;

proc sql;
	create table temp1b_pre as
	select a.*, b.Major_Teaching_Hospital, b.Urban as URBAN_RURAL, b.SAFETY_NET, b.BED_SIZE as BED_SIZE_join, b.CENSUS_Division as CENSUS_Pre
	from temp1_preb as a left join Peer_Group_baseline as b
	on a.anc_ccn = b.ccn_join;
/*		and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end;*/
quit;

data temp1b;
	set temp1b_pre;
	format BED_SIZE $11.;
	CENSUS = input(CENSUS_Pre,12.);
	if BED_SIZE_join = 'Extra' then BED_SIZE = 'Extra Large';
	else Bed_SIZE = BED_SIZE_join;
run;

proc sql;
	create table temp2b as
	select a.*, b.*
	from temp1b as a left join TP_Risk_Adj_Parameters_baseline as b
	on a.EPISODE_GROUP_NAME = b.Clinical_Episode_Category
		and a.anchor_type_upper = b.Clinical_Episode_Type;
		/*and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end;*/
quit;

proc sql;
	create table temp3b_pre as
	select a.*, b.PAT_Factor as PAT_New
	from temp2b as a left join PAT_Factors_baseline as b
	on a.EPISODE_GROUP_NAME = b.Clinical_Episode
		and a.ANCHOR_TYPE=b.anchor_type
		and a.Major_Teaching_Hospital=b.MTH
		and a.URBAN_RURAL=b.Urban_Rural
		and a.SAFETY_NET=b.Safety_Net
		and a.BED_SIZE=b.Bed_Size
		and a.CENSUS=b.Census_Div
		and year(a.POST_DSCH_END_DT)=b.Year
		and qtr(a.POST_DSCH_END_DT)=b.Quarter;
/*		and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end;*/
quit;

proc sql;
	create table temp3b as
	select a.*, b.PAT_Factor as PAT_2020Q3
	from temp3b_pre as a left join PAT_Factors_baseline as b
	on a.EPISODE_GROUP_NAME = b.Clinical_Episode
		and a.ANCHOR_TYPE=b.anchor_type
		and a.Major_Teaching_Hospital=b.MTH
		and a.URBAN_RURAL=b.Urban_Rural
		and a.SAFETY_NET=b.Safety_Net
		and a.BED_SIZE=b.Bed_Size
		and a.CENSUS=b.Census_Div
		and b.Year=2020
		and b.Quarter=3;
/*		and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end;*/
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
		b.PAT_Adj as PAT_Historical_Adj,
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
			/*and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end;*/
quit;

data temp5b;
	set temp4b;
	format DRG_CODE BEST12.;
	%if %substr(&label.,1,5)  = ybase %then %do; 
		DRG_CODE=DRG_2019;
	%end; 
	%else %do;
		if ANCHOR_TYPE = 'ip' then DRG_CODE = input(ANCHOR_CODE,$20.);
		else DRG_CODE = . ;
	%end;

	Epi_Year = year(POST_DSCH_END_DT);
	Epi_Qtr = qtr(POST_DSCH_END_DT);
	Epi_Half = 1;
	if Epi_Qtr in (3,4) then Epi_Half = 2;

	DRG_CD_061=0;
	DRG_CD_062=0;
	DRG_CD_063=0;
	DRG_CD_064=0;
	DRG_CD_066=0;
	DRG_CD_100=0;
	DRG_CD_177=0;
	DRG_CD_178=0;
	DRG_CD_179=0;
	DRG_CD_191=0;
	DRG_CD_192=0;
	DRG_CD_193=0;
	DRG_CD_195=0;
	DRG_CD_202=0;
	DRG_CD_203=0;
	DRG_CD_216=0;
	DRG_CD_217=0;
	DRG_CD_218=0;
	DRG_CD_219=0;
	DRG_CD_221=0;
	DRG_CD_222=0;
	DRG_CD_223=0;
	DRG_CD_224=0;
	DRG_CD_225=0;
	DRG_CD_226=0;
	DRG_CD_231=0;
	DRG_CD_232=0;
	DRG_CD_233=0;
	DRG_CD_234=0;
	DRG_CD_235=0;
	DRG_CD_242=0;
	DRG_CD_244=0;
	DRG_CD_246=0;
	DRG_CD_248=0;
	DRG_CD_249=0;
	DRG_CD_250=0;
	DRG_CD_251=0;
	DRG_CD_266=0;
	DRG_CD_281=0;
	DRG_CD_282=0;
	DRG_CD_292=0;
	DRG_CD_293=0;
	DRG_CD_308=0;
	DRG_CD_310=0;
	DRG_CD_329=0;
	DRG_CD_331=0;
	DRG_CD_377=0;
	DRG_CD_379=0;
	DRG_CD_385=0;
	DRG_CD_387=0;
	DRG_CD_388=0;
	DRG_CD_390=0;
	DRG_CD_441=0;
	DRG_CD_443=0;
	DRG_CD_453=0;
	DRG_CD_454=0;
	DRG_CD_455=0;
	DRG_CD_459=0;
	DRG_CD_461=0;
	DRG_CD_469=0;
	DRG_CD_471=0;
	DRG_CD_472=0;
	DRG_CD_473=0;
	DRG_CD_480=0;
	DRG_CD_482=0;
	DRG_CD_492=0;
	DRG_CD_494=0;
	DRG_CD_518=0;
	DRG_CD_519=0;
	DRG_CD_533=0;
	DRG_CD_534=0;
	DRG_CD_535=0;
	DRG_CD_602=0;
	DRG_CD_619=0;
	DRG_CD_620=0;
	DRG_CD_682=0;
	DRG_CD_684=0;
	DRG_CD_689=0;
	DRG_CD_870=0;
	DRG_CD_872=0;

	APC_5115=0;
	APC_5192=0;
	APC_5194=0;
	APC_5231=0;
	APC_5432=0;

	FY_2018=0;
	FY2018_DRG_453=0;
	FY2018_DRG_454=0;
	FY2018_DRG_455=0;
	FY2018_DRG_459=0;
	FY2018_DRG_471=0;
	FY2018_DRG_472=0;
	FY2018_DRG_473=0;

	if DRG_CODE = 061 then DRG_CD_061=1;
	if DRG_CODE = 062 then DRG_CD_062=1;
	if DRG_CODE = 063 then DRG_CD_063=1;
	if DRG_CODE = 064 then DRG_CD_064=1;
	if DRG_CODE = 066 then DRG_CD_066=1;
	if DRG_CODE = 100 then DRG_CD_100=1;
	if DRG_CODE = 177 then DRG_CD_177=1;
	if DRG_CODE = 178 then DRG_CD_178=1;
	if DRG_CODE = 179 then DRG_CD_179=1;
	if DRG_CODE = 191 then DRG_CD_191=1;
	if DRG_CODE = 192 then DRG_CD_192=1;
	if DRG_CODE = 193 then DRG_CD_193=1;
	if DRG_CODE = 195 then DRG_CD_195=1;
	if DRG_CODE = 202 then DRG_CD_202=1;
	if DRG_CODE = 203 then DRG_CD_203=1;
	if DRG_CODE = 216 then DRG_CD_216=1;
	if DRG_CODE = 217 then DRG_CD_217=1;
	if DRG_CODE = 218 then DRG_CD_218=1;
	if DRG_CODE = 219 then DRG_CD_219=1;
	if DRG_CODE = 221 then DRG_CD_221=1;
	if DRG_CODE = 222 then DRG_CD_222=1;
	if DRG_CODE = 223 then DRG_CD_223=1;
	if DRG_CODE = 224 then DRG_CD_224=1;
	if DRG_CODE = 225 then DRG_CD_225=1;
	if DRG_CODE = 226 then DRG_CD_226=1;
	if DRG_CODE = 231 then DRG_CD_231=1;
	if DRG_CODE = 232 then DRG_CD_232=1;
	if DRG_CODE = 233 then DRG_CD_233=1;
	if DRG_CODE = 234 then DRG_CD_234=1;
	if DRG_CODE = 235 then DRG_CD_235=1;
	if DRG_CODE = 242 then DRG_CD_242=1;
	if DRG_CODE = 244 then DRG_CD_244=1;
	if DRG_CODE = 246 then DRG_CD_246=1;
	if DRG_CODE = 248 then DRG_CD_248=1;
	if DRG_CODE = 249 then DRG_CD_249=1;
	if DRG_CODE = 250 then DRG_CD_250=1;
	if DRG_CODE = 251 then DRG_CD_251=1;
	if DRG_CODE = 266 then DRG_CD_266=1;
	if DRG_CODE = 281 then DRG_CD_281=1;
	if DRG_CODE = 282 then DRG_CD_282=1;
	if DRG_CODE = 292 then DRG_CD_292=1;
	if DRG_CODE = 293 then DRG_CD_293=1;
	if DRG_CODE = 308 then DRG_CD_308=1;
	if DRG_CODE = 310 then DRG_CD_310=1;
	if DRG_CODE = 329 then DRG_CD_329=1;
	if DRG_CODE = 331 then DRG_CD_331=1;
	if DRG_CODE = 377 then DRG_CD_377=1;
	if DRG_CODE = 379 then DRG_CD_379=1;
	if DRG_CODE = 385 then DRG_CD_385=1;
	if DRG_CODE = 387 then DRG_CD_387=1;
	if DRG_CODE = 388 then DRG_CD_388=1;
	if DRG_CODE = 390 then DRG_CD_390=1;
	if DRG_CODE = 441 then DRG_CD_441=1;
	if DRG_CODE = 443 then DRG_CD_443=1;
	if DRG_CODE = 453 then DRG_CD_453=1;
	if DRG_CODE = 454 then DRG_CD_454=1;
	if DRG_CODE = 455 then DRG_CD_455=1;
	if DRG_CODE = 459 then DRG_CD_459=1;
	if DRG_CODE = 461 then DRG_CD_461=1;
	if DRG_CODE = 469 then DRG_CD_469=1;
	if DRG_CODE = 471 then DRG_CD_471=1;
	if DRG_CODE = 472 then DRG_CD_472=1;
	if DRG_CODE = 473 then DRG_CD_473=1;
	if DRG_CODE = 480 then DRG_CD_480=1;
	if DRG_CODE = 482 then DRG_CD_482=1;
	if DRG_CODE = 492 then DRG_CD_492=1;
	if DRG_CODE = 494 then DRG_CD_494=1;
	if DRG_CODE = 518 then DRG_CD_518=1;
	if DRG_CODE = 519 then DRG_CD_519=1;
	if DRG_CODE = 533 then DRG_CD_533=1;
	if DRG_CODE = 534 then DRG_CD_534=1;
	if DRG_CODE = 535 then DRG_CD_535=1;
	if DRG_CODE = 602 then DRG_CD_602=1;
	if DRG_CODE = 619 then DRG_CD_619=1;
	if DRG_CODE = 620 then DRG_CD_620=1;
	if DRG_CODE = 682 then DRG_CD_682=1;
	if DRG_CODE = 684 then DRG_CD_684=1;
	if DRG_CODE = 689 then DRG_CD_689=1;
	if DRG_CODE = 870 then DRG_CD_870=1;
	if DRG_CODE = 872 then DRG_CD_872=1;
	*if ANCHOR_TYPE='op' and EPISODE_GROUP_NAME = 'Major joint replacement of the lower extremity' then DRG_CD_470=1;

	if PERF_APC = 5115 then APC_5115=1;
	if PERF_APC = 5192 then APC_5192=1;
	if PERF_APC = 5194 then APC_5194=1;
	if PERF_APC = 5231 then APC_5231=1;
	if PERF_APC = 5432 then APC_5432=1;

	if ANCHOR_END_DT >= mdy(10,1,2017) then FY_2018=1;
	if FY_2018=1 then do;
		if DRG_CODE = 453 then FY2018_DRG_453=1;
		if DRG_CODE = 454 then FY2018_DRG_454=1;
		if DRG_CODE = 455 then FY2018_DRG_455=1;
		if DRG_CODE = 459 then FY2018_DRG_459=1;
		if DRG_CODE = 471 then FY2018_DRG_471=1;
		if DRG_CODE = 472 then FY2018_DRG_472=1;
		if DRG_CODE = 473 then FY2018_DRG_473=1;
	end;

	HCC_CNT = sum(of HCC1 -- HCC189);
	HCC_CNT_1_3=0;
	HCC_CNT_4_6=0;
	HCC_CNT_7_PLUS=0;
	HCC_CNT_4_6_HCC_CNT_7_PLUS=0;
	if HCC_CNT > 0 then do;
		if HCC_CNT <= 3 then HCC_CNT_1_3=1;
		else if HCC_CNT <= 6 then HCC_CNT_4_6=1;
		else if HCC_CNT >= 7 then HCC_CNT_7_PLUS=1;
		if HCC_CNT >= 4 then HCC_CNT_4_6_HCC_CNT_7_PLUS=1;
	end; 


Pred_Price = (N1_P1 * EXP(
		  (BENE_AGE-50) * N1_Age_50
		+ (BENE_AGE-50) * (BENE_AGE-50) * N1_Age_50_SQ
		+ ANY_DUAL * N1_ANY_DUAL
		+ APC_5115 * N1_APC_5115
		+ APC_5192 * N1_APC_5192
		+ APC_5194 * N1_APC_5194
		+ APC_5231 * N1_APC_5231
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
		+ DRG_CD_061 * N1_DRG_CD_061
		+ DRG_CD_062 * N1_DRG_CD_062
		+ DRG_CD_063 * N1_DRG_CD_063
		+ DRG_CD_064 * N1_DRG_CD_064
		+ DRG_CD_066 * N1_DRG_CD_066
		+ DRG_CD_100 * N1_DRG_CD_100
		+ DRG_CD_177 * N1_DRG_CD_177
		+ DRG_CD_178 * N1_DRG_CD_178
		+ DRG_CD_179 * N1_DRG_CD_179
		+ DRG_CD_191 * N1_DRG_CD_191
		+ DRG_CD_192 * N1_DRG_CD_192
		+ DRG_CD_193 * N1_DRG_CD_193
		+ DRG_CD_195 * N1_DRG_CD_195
		+ DRG_CD_202 * N1_DRG_CD_202
		+ DRG_CD_203 * N1_DRG_CD_203
		+ DRG_CD_216 * N1_DRG_CD_216
		+ DRG_CD_217 * N1_DRG_CD_217
		+ DRG_CD_218 * N1_DRG_CD_218
		+ DRG_CD_219 * N1_DRG_CD_219
		+ DRG_CD_221 * N1_DRG_CD_221
		+ DRG_CD_222 * N1_DRG_CD_222
		+ DRG_CD_223 * N1_DRG_CD_223
		+ DRG_CD_224 * N1_DRG_CD_224
		+ DRG_CD_225 * N1_DRG_CD_225
		+ DRG_CD_226 * N1_DRG_CD_226
		+ DRG_CD_231 * N1_DRG_CD_231
		+ DRG_CD_232 * N1_DRG_CD_232
		+ DRG_CD_233 * N1_DRG_CD_233
		+ DRG_CD_234 * N1_DRG_CD_234
		+ DRG_CD_235 * N1_DRG_CD_235
		+ DRG_CD_242 * N1_DRG_CD_242
		+ DRG_CD_244 * N1_DRG_CD_244
		+ DRG_CD_246 * N1_DRG_CD_246
		+ DRG_CD_248 * N1_DRG_CD_248
		+ DRG_CD_249 * N1_DRG_CD_249
		+ DRG_CD_250 * N1_DRG_CD_250
		+ DRG_CD_251 * N1_DRG_CD_251
		+ DRG_CD_266 * N1_DRG_CD_266
		+ DRG_CD_281 * N1_DRG_CD_281
		+ DRG_CD_282 * N1_DRG_CD_282
		+ DRG_CD_292 * N1_DRG_CD_292
		+ DRG_CD_293 * N1_DRG_CD_293
		+ DRG_CD_308 * N1_DRG_CD_308
		+ DRG_CD_310 * N1_DRG_CD_310
		+ DRG_CD_329 * N1_DRG_CD_329
		+ DRG_CD_331 * N1_DRG_CD_331
		+ DRG_CD_377 * N1_DRG_CD_377
		+ DRG_CD_379 * N1_DRG_CD_379
		+ DRG_CD_385 * N1_DRG_CD_385
		+ DRG_CD_387 * N1_DRG_CD_387
		+ DRG_CD_388 * N1_DRG_CD_388
		+ DRG_CD_390 * N1_DRG_CD_390
		+ DRG_CD_441 * N1_DRG_CD_441
		+ DRG_CD_443 * N1_DRG_CD_443
		+ DRG_CD_453 * N1_DRG_CD_453
		+ DRG_CD_454 * N1_DRG_CD_454
		+ DRG_CD_455 * N1_DRG_CD_455
		+ DRG_CD_459 * N1_DRG_CD_459
		+ DRG_CD_461 * N1_DRG_CD_461
		+ DRG_CD_469 * N1_DRG_CD_469
		+ DRG_CD_471 * N1_DRG_CD_471
		+ DRG_CD_472 * N1_DRG_CD_472
		+ DRG_CD_473 * N1_DRG_CD_473
		+ DRG_CD_480 * N1_DRG_CD_480
		+ DRG_CD_482 * N1_DRG_CD_482
		+ DRG_CD_492 * N1_DRG_CD_492
		+ DRG_CD_494 * N1_DRG_CD_494
		+ DRG_CD_518 * N1_DRG_CD_518
		+ DRG_CD_519 * N1_DRG_CD_519
		+ DRG_CD_533 * N1_DRG_CD_533
		+ DRG_CD_534 * N1_DRG_CD_534
		+ DRG_CD_535 * N1_DRG_CD_535
		+ DRG_CD_602 * N1_DRG_CD_602
		+ DRG_CD_619 * N1_DRG_CD_619
		+ DRG_CD_620 * N1_DRG_CD_620
		+ DRG_CD_682 * N1_DRG_CD_682
		+ DRG_CD_684 * N1_DRG_CD_684
		+ DRG_CD_689 * N1_DRG_CD_689
		+ DRG_CD_870 * N1_DRG_CD_870
		+ DRG_CD_872 * N1_DRG_CD_872
		+ FRACTURE_FLAG * N1_FRACTURE_FLAG
		+ FY_2018 * N1_FY_2018
		+ FY2018_DRG_453 * N1_FY2018_DRG_453
		+ FY2018_DRG_454 * N1_FY2018_DRG_454
		+ FY2018_DRG_455 * N1_FY2018_DRG_455
		+ FY2018_DRG_459 * N1_FY2018_DRG_459
		+ FY2018_DRG_471 * N1_FY2018_DRG_471
		+ FY2018_DRG_472 * N1_FY2018_DRG_472
		+ FY2018_DRG_473 * N1_FY2018_DRG_473
		+ HCC_CNT_1_3 * N1_HCC_CNT_1_3
		+ HCC_CNT_4_6 * N1_HCC_CNT_4_6
		+ HCC_CNT_7_PLUS * N1_HCC_CNT_7_PLUS
		+ HCC_CNT_4_6_HCC_CNT_7_PLUS * N1_HCC_CNT_4_6_HCC_CNT_7_PLUS
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
		+ HEM_STROKE_FLAG * N1_HEM_STROKE_FLAG
		+ IBD_FISTULA_FLAG * N1_IBD_FISTULA_FLAG
		+ IBD_UC_FLAG * N1_IBD_UC_FLAG
		+ KNEE_ARTHRO_FLAG * N1_KNEE_ARTHRO_FLAG
		+ KNEE_ARTHRO_FRACTURE_FLAG * N1_KNEE_ARTHRO_FRACTURE_FLAG
		+ LTI * N1_LTI
		+ ORIGDS * N1_ORIGDS
		+ PRIOR_HOSP_W_NON_PAC_IP_FLAG_90 * N1_PRIOR_HOSP_W_NON_PAC_IP_FLAG
		+ PRIOR_PAC_FLAG * N1_PRIOR_PAC_FLAG
		+ SEPSIS_CARD_RESP_FAIL * N1_SEPSIS_CARD_RESP_FAIL
		+ N1_INTERCEPT
		+ (N1_SIGMA1*N1_SIGMA1)/2 
		))
		+
		(N2_P2 * EXP(
		  (BENE_AGE-50) * N2_Age_50
		+ (BENE_AGE-50) * (BENE_AGE-50) * N2_Age_50_SQ
		+ ANY_DUAL * N2_ANY_DUAL
		+ APC_5115 * N2_APC_5115
		+ APC_5192 * N2_APC_5192
		+ APC_5194 * N2_APC_5194
		+ APC_5231 * N2_APC_5231
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
		+ DRG_CD_061 * N2_DRG_CD_061
		+ DRG_CD_062 * N2_DRG_CD_062
		+ DRG_CD_063 * N2_DRG_CD_063
		+ DRG_CD_064 * N2_DRG_CD_064
		+ DRG_CD_066 * N2_DRG_CD_066
		+ DRG_CD_100 * N2_DRG_CD_100
		+ DRG_CD_177 * N2_DRG_CD_177
		+ DRG_CD_178 * N2_DRG_CD_178
		+ DRG_CD_179 * N2_DRG_CD_179
		+ DRG_CD_191 * N2_DRG_CD_191
		+ DRG_CD_192 * N2_DRG_CD_192
		+ DRG_CD_193 * N2_DRG_CD_193
		+ DRG_CD_195 * N2_DRG_CD_195
		+ DRG_CD_202 * N2_DRG_CD_202
		+ DRG_CD_203 * N2_DRG_CD_203
		+ DRG_CD_216 * N2_DRG_CD_216
		+ DRG_CD_217 * N2_DRG_CD_217
		+ DRG_CD_218 * N2_DRG_CD_218
		+ DRG_CD_219 * N2_DRG_CD_219
		+ DRG_CD_221 * N2_DRG_CD_221
		+ DRG_CD_222 * N2_DRG_CD_222
		+ DRG_CD_223 * N2_DRG_CD_223
		+ DRG_CD_224 * N2_DRG_CD_224
		+ DRG_CD_225 * N2_DRG_CD_225
		+ DRG_CD_226 * N2_DRG_CD_226
		+ DRG_CD_231 * N2_DRG_CD_231
		+ DRG_CD_232 * N2_DRG_CD_232
		+ DRG_CD_233 * N2_DRG_CD_233
		+ DRG_CD_234 * N2_DRG_CD_234
		+ DRG_CD_235 * N2_DRG_CD_235
		+ DRG_CD_242 * N2_DRG_CD_242
		+ DRG_CD_244 * N2_DRG_CD_244
		+ DRG_CD_246 * N2_DRG_CD_246
		+ DRG_CD_248 * N2_DRG_CD_248
		+ DRG_CD_249 * N2_DRG_CD_249
		+ DRG_CD_250 * N2_DRG_CD_250
		+ DRG_CD_251 * N2_DRG_CD_251
		+ DRG_CD_266 * N2_DRG_CD_266
		+ DRG_CD_281 * N2_DRG_CD_281
		+ DRG_CD_282 * N2_DRG_CD_282
		+ DRG_CD_292 * N2_DRG_CD_292
		+ DRG_CD_293 * N2_DRG_CD_293
		+ DRG_CD_308 * N2_DRG_CD_308
		+ DRG_CD_310 * N2_DRG_CD_310
		+ DRG_CD_329 * N2_DRG_CD_329
		+ DRG_CD_331 * N2_DRG_CD_331
		+ DRG_CD_377 * N2_DRG_CD_377
		+ DRG_CD_379 * N2_DRG_CD_379
		+ DRG_CD_385 * N2_DRG_CD_385
		+ DRG_CD_387 * N2_DRG_CD_387
		+ DRG_CD_388 * N2_DRG_CD_388
		+ DRG_CD_390 * N2_DRG_CD_390
		+ DRG_CD_441 * N2_DRG_CD_441
		+ DRG_CD_443 * N2_DRG_CD_443
		+ DRG_CD_453 * N2_DRG_CD_453
		+ DRG_CD_454 * N2_DRG_CD_454
		+ DRG_CD_455 * N2_DRG_CD_455
		+ DRG_CD_459 * N2_DRG_CD_459
		+ DRG_CD_461 * N2_DRG_CD_461
		+ DRG_CD_469 * N2_DRG_CD_469
		+ DRG_CD_471 * N2_DRG_CD_471
		+ DRG_CD_472 * N2_DRG_CD_472
		+ DRG_CD_473 * N2_DRG_CD_473
		+ DRG_CD_480 * N2_DRG_CD_480
		+ DRG_CD_482 * N2_DRG_CD_482
		+ DRG_CD_492 * N2_DRG_CD_492
		+ DRG_CD_494 * N2_DRG_CD_494
		+ DRG_CD_518 * N2_DRG_CD_518
		+ DRG_CD_519 * N2_DRG_CD_519
		+ DRG_CD_533 * N2_DRG_CD_533
		+ DRG_CD_534 * N2_DRG_CD_534
		+ DRG_CD_535 * N2_DRG_CD_535
		+ DRG_CD_602 * N2_DRG_CD_602
		+ DRG_CD_619 * N2_DRG_CD_619
		+ DRG_CD_620 * N2_DRG_CD_620
		+ DRG_CD_682 * N2_DRG_CD_682
		+ DRG_CD_684 * N2_DRG_CD_684
		+ DRG_CD_689 * N2_DRG_CD_689
		+ DRG_CD_870 * N2_DRG_CD_870
		+ DRG_CD_872 * N2_DRG_CD_872
		+ FRACTURE_FLAG * N2_FRACTURE_FLAG
		+ FY_2018 * N2_FY_2018
		+ FY2018_DRG_453 * N2_FY2018_DRG_453
		+ FY2018_DRG_454 * N2_FY2018_DRG_454
		+ FY2018_DRG_455 * N2_FY2018_DRG_455
		+ FY2018_DRG_459 * N2_FY2018_DRG_459
		+ FY2018_DRG_471 * N2_FY2018_DRG_471
		+ FY2018_DRG_472 * N2_FY2018_DRG_472
		+ FY2018_DRG_473 * N2_FY2018_DRG_473
		+ HCC_CNT_1_3 * N2_HCC_CNT_1_3
		+ HCC_CNT_4_6 * N2_HCC_CNT_4_6
		+ HCC_CNT_7_PLUS * N2_HCC_CNT_7_PLUS
		+ HCC_CNT_4_6_HCC_CNT_7_PLUS * N2_HCC_CNT_4_6_HCC_CNT_7_PLUS
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
		+ HEM_STROKE_FLAG * N2_HEM_STROKE_FLAG
		+ IBD_FISTULA_FLAG * N2_IBD_FISTULA_FLAG
		+ IBD_UC_FLAG * N2_IBD_UC_FLAG
		+ KNEE_ARTHRO_FLAG * N2_KNEE_ARTHRO_FLAG
		+ KNEE_ARTHRO_FRACTURE_FLAG * N2_KNEE_ARTHRO_FRACTURE_FLAG
		+ LTI * N2_LTI
		+ ORIGDS * N2_ORIGDS
		+ PRIOR_HOSP_W_NON_PAC_IP_FLAG_90 * N2_PRIOR_HOSP_W_NON_PAC_IP_FLAG
		+ PRIOR_PAC_FLAG * N2_PRIOR_PAC_FLAG
		+ SEPSIS_CARD_RESP_FAIL * N2_SEPSIS_CARD_RESP_FAIL
		+ N2_INTERCEPT
		+ (N2_SIGMA2*N2_SIGMA2)/2 
		))
		;
run;

data temp6;
	set temp5a temp5b;
run;

data tp_components_original;
	set tp.TP_Components_MY3_all;
	where time_period = 'Baseline - MY3';
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

	PAT = PAT_2020Q3;
	PAYMENT_RATIO = TARGET_PRICE_REAL / TARGET_PRICE;
	*PCMA = HBP / PAT / SBS / PAT_Historical_Adj;
	*if HBP = . then PCMA = PGP_ACH_BNCHMRK / PAT / SBS / PAT_Historical_Adj;
	PCMA = PCMA_ROUND;

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
	select a.*, coalesce(b.PERFORMANCE_PERIOD_EPI,1) as PERFORMANCE_PERIOD_EPI
	from t1 as a left join t2 as b
	on a.BPID=b.BPID and a.ANCHOR_TYPE=b.ANCHOR_TYPE and a.EPISODE_GROUP_NAME=b.EPISODE_GROUP_NAME;
quit;

***** Natural Disaster Exclusion *****;
proc sql;
	create table disaster as
	select distinct a.*, b.state, b.county
	from t3 as a left join genref.ccn_statecounty as b
	on a.anc_ccn = b.ccn;
quit;

proc sql;
	create table disaster2 as
	select distinct a.*, 
	 b.Disaster_Number as NATURAL_DISASTER_MONTHLY_NUM1
	from disaster as a left join cjrref.disasterarealist_milliman_0612 as b
	on sum(b.incident_start_date,-29) <= a.anchor_beg_dt <= sum(b.incident_end_date,29)
	and a.state = b.state
	and a.county = strip(b.county)
		;
quit;

data COVID;
	set cjrref.disasterarealist_milliman_0612;
	where county='';
	incident_end_date = mdy(12,31,2999);
run;

/*proc sql;*/
/*	create table disaster3 as*/
/*	select distinct a.*, */
/*	 b.Disaster_Number as NATURAL_DISASTER_MONTHLY_NUM2*/
/*	from disaster2 as a left join COVID as b*/
/*	on sum(b.incident_start_date,-29) <= a.anchor_beg_dt <= sum(b.incident_end_date,29)*/
/*	and a.state = b.state*/
/*		;*/
/*quit;*/

proc sql;
	create table disaster3 as
	select distinct a.*, 
	0 as NATURAL_DISASTER_MONTHLY_NUM2
	from disaster2 as a left join COVID as b
	on sum(b.incident_start_date,-29) <= a.anchor_beg_dt <= sum(b.incident_end_date,29)
	and a.state = b.state
		;
quit;

data t4;
	set disaster3;
	format NATURAL_DISASTER_MONTHLY $3.;

	NATURAL_DISASTER_MONTHLY_NUM = max(NATURAL_DISASTER_MONTHLY_NUM1,NATURAL_DISASTER_MONTHLY_NUM2);

	if NATURAL_DISASTER_MONTHLY_NUM>0 then do;
		NATURAL_DISASTER_MONTHLY='Yes';
%if &label. ^= ybase %then %do ;
		if EPI_STD_PMT_FCTR_WIN_1_99>TARGET_PRICE then do;
			EPI_STD_PMT_FCTR_WIN_1_99=.;
			TP_Adj=.;
		end;
%end ;
	end;
	else NATURAL_DISASTER_MONTHLY='No';
run;

proc sql;
create table t5 as 
	select a.*
		  ,b.BPCI_Episode_Idx
 /* from out2.tp_pp1Initial_1148_0000 AS A */
 from t4 AS A 
	left join bpciaref.BPCIA_DRG_Mapping_my3 as b
	on a.ANCHOR_CODE = b.code
;
quit;

proc sql;
create table t6 as
  select a.*
          ,b.Clinical_Episode
		  ,b.Short_name as clinical_episode_abbr
		  ,b.Short_name_2 as clinical_episode_abbr2
		  ,strip(BPID)||" - "||strip(b.Short_name) as BPID_ClinicalEp
	from t5 as a
	left join bpciaref.BPCIA_Clinical_Episode_Names_my3 as b
	on a.BPCI_Episode_Idx = b.BPCI_Episode_Index
;
quit;
	 
data out.tp_&label._&bpid1._&bpid2._MY3;
	set t6 (rename=(anchor_ccn=anchor_ccn_orig EPI_STD_PMT_FCTR_WIN_1_99=EPI_STD_PMT_FCTR_WIN_1_99_orig)) ;
	format HAS_TP $100. PERFORMANCE_PERIOD $3.;

	PGP_Offset_Amt_Real=0;
	if PGP_Offset < 1 and PGP_Offset ^= . then PGP_Offset_Amt_Real = TP_Adj / .97 * (1-(PGP_Offset/PGP_Offset_Adj)) * PAYMENT_RATIO;

	PAT_Amt_Real=0;
	PAT_Amt_Real = TP_Adj / .97 * (1-(PAT_New/PAT)) * PAYMENT_RATIO;

	Discount_Real=0;
	Discount_Real = (-1) * TP_Adj / .97 * .03 * PAYMENT_RATIO;

	ANCHOR_CCN = anc_ccn;

	Adjusted_TP_Real = TP_Adj * PAYMENT_RATIO;

	%if %substr(&label.,1,5)  = ybase %then %do;
		if EPI_SPEND_Original not in (0,.) then EPI_STD_PMT_FCTR_WIN_1_99 = EPI_STD_PMT_FCTR_WIN_1_99_orig * EPI_SPEND / EPI_SPEND_Original;
		else EPI_STD_PMT_FCTR_WIN_1_99=EPI_STD_PMT_FCTR_WIN_1_99_orig;
		EPI_STD_PMT_FCTR_WIN_1_99_Real = EPI_STD_PMT_FCTR_WIN_1_99 * PAYMENT_RATIO;
	%end;
	%else %do;
		EPI_STD_PMT_FCTR_WIN_1_99=EPI_STD_PMT_FCTR_WIN_1_99_orig;
		if EPI_DROPPED_FLAG = 0 then EPI_STD_PMT_FCTR_WIN_1_99_Real = EPI_STD_PMT_FCTR_WIN_1_99 * PAYMENT_RATIO;
		else EPI_STD_PMT_FCTR_WIN_1_99_Real = .;
	%end;
	*EPI_STD_PMT_FCTR_WIN_1_99_Real = EPI_STD_PMT_FCTR_WIN_1_99 * PAYMENT_RATIO;

	PAT_Adj = PAT_New;

	if TARGET_PRICE = . or PAYMENT_RATIO = . then do;
		EPI_STD_PMT_FCTR_WIN_1_99_Real = .;
		Adjusted_TP_Real = .;
		Discount_Real = .;
		PGP_Offset_Amt_Real = .;
		PAT_Amt_Real = .;
	end;

		HAS_TP="Yes";

	if Adjusted_TP_Real=. and NATURAL_DISASTER_MONTHLY ne 'Yes' then HAS_TP='No: Baseline Volume';
	if Adjusted_TP_Real=. and NATURAL_DISASTER_MONTHLY =  'Yes' then HAS_TP='No: Natural Disaster Policy';

	if PERFORMANCE_PERIOD_EPI = 1 then PERFORMANCE_PERIOD = 'Yes';
	else PERFORMANCE_PERIOD = 'No';

run;


data out2.tp_&label._&bpid1._&bpid2._MY3;
	set out.tp_&label._&bpid1._&bpid2._MY3 (rename=(ORIGDS=ORIGDS_orig LTI=LTI_orig FRACTURE_FLAG=FRACTURE_FLAG_orig ANY_DUAL=ANY_DUAL_orig KNEE_ARTHRO_FLAG=KNEE_ARTHRO_FLAG_orig PRIOR_HOSP_W_NON_PAC_IP_FLAG_90=PRIOR_HOSP_W_NON_PAC_IP_FLAG_ori PRIOR_PAC_FLAG=PRIOR_PAC_FLAG_orig
											HCC18=HCC18_orig HCC19=HCC19_orig HCC40=HCC40_orig HCC58=HCC58_orig HCC84=HCC84_orig HCC85=HCC85_orig HCC86=HCC86_orig HCC88=HCC88_orig HCC96=HCC96_orig HCC108=HCC108_orig HCC111=HCC111_orig));
	format ORIGDS LTI FRACTURE_FLAG ANY_DUAL KNEE_ARTHRO_FLAG TKA_FLAG PRIOR_HOSP_W_NON_PAC_IP_FLAG_90 PRIOR_HOSP_W_ANY_IP_FLAG_90
			 HCC18 HCC19 HCC40 HCC58 HCC84 HCC85 HCC86 HCC88 HCC96 HCC108 HCC111 $3. HCC_COUNT $6. ;

	if ORIGDS_orig=1 then ORIGDS='Yes'; else ORIGDS='No';
	if LTI_orig=1 then LTI='Yes'; else LTI='No';
	if FRACTURE_FLAG_orig=1 then FRACTURE_FLAG='Yes'; else FRACTURE_FLAG='No';
	if ANY_DUAL_orig=1 then ANY_DUAL='Yes'; else ANY_DUAL='No';
	if KNEE_ARTHRO_FLAG_orig=1 then KNEE_ARTHRO_FLAG='Yes'; else KNEE_ARTHRO_FLAG='No';
	if KNEE_ARTHRO_FLAG_orig=1 then TKA_FLAG='Yes'; else TKA_FLAG = 'No';
	if PRIOR_HOSP_W_NON_PAC_IP_FLAG_ori=1 then PRIOR_HOSP_W_NON_PAC_IP_FLAG_90='Yes'; else PRIOR_HOSP_W_NON_PAC_IP_FLAG_90='No';
	if PRIOR_HOSP_W_NON_PAC_IP_FLAG_ori=1 then PRIOR_HOSP_W_ANY_IP_FLAG_90='Yes'; else PRIOR_HOSP_W_ANY_IP_FLAG_90='No';
	if PRIOR_PAC_FLAG_orig=1 then PRIOR_PAC_FLAG='Yes'; else PRIOR_PAC_FLAG='No';
	if HCC_CNT=0 then HCC_COUNT='0';
	else if HCC_CNT<=3 then HCC_COUNT='1 to 3';
	else if HCC_CNT<=6 then HCC_COUNT='4 to 6';
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
		 DRG_CODE PERF_APC ORIGDS LTI FRACTURE_FLAG ANY_DUAL KNEE_ARTHRO_FLAG KNEE_ARTHRO_FRACTURE_FLAG PRIOR_HOSP_W_NON_PAC_IP_FLAG_90 PRIOR_PAC_FLAG PRIOR_HOSP_W_ANY_IP_FLAG_90
		 EPI_STD_PMT_FCTR_WIN_1_99_Real Adjusted_TP_Real Discount_Real PGP_Offset_Amt_Real PAT_Amt_Real 
		 PAT PAT_Adj PCMA PCMA_Adj PGP_ACH_PCMA PGP_PCMA_Adj CASE_MIX PGP_ACH_Ratio PGP_Offset PGP_Offset_Adj PAYMENT_RATIO 
		 HAS_TP PERFORMANCE_PERIOD
		 HCC_COUNT HCC18 HCC19 HCC40 HCC58 HCC84 HCC85 HCC86 HCC88 HCC96 HCC108 HCC111 NATURAL_DISASTER_MONTHLY TKA_FLAG
	Prelim_TP
	Final_TP
	TP_Difference
;
run;



%mend;

%runhosp(2586_0001,2586_0001,2586,0002,360027,1);
%runhosp(2586_0001,2586_0001,2586,0005,360082,1);
%runhosp(2586_0001,2586_0001,2586,0006,360077,1);
%runhosp(2586_0001,2586_0001,2586,0007,360230,1);
%runhosp(2586_0001,2586_0001,2586,0010,360143,1);
%runhosp(2586_0001,2586_0001,2586,0013,360180,1);
%runhosp(2586_0001,2586_0001,2586,0025,360364,0);
%runhosp(2586_0001,2586_0001,2586,0026,100289,0);
%runhosp(2586_0001,2586_0001,2586,0028,360087,0);
%runhosp(2586_0001,2586_0001,2586,0029,360091,0);
%runhosp(2586_0001,2586_0001,2586,0030,360144,0);
%runhosp(2586_0001,2586_0001,2586,0031,360010,0);
%runhosp(2586_0001,2586_0001,2586,0032,100105,0);
%runhosp(2586_0001,2586_0001,2586,0033,100044,0);
%runhosp(2586_0001,2586_0001,2586,0034,650003177,0);
%runhosp(2586_0001,2586_0001,2586,0035,340714585,0);
*%runhosp(2586_0001,2586_0001,2586,0036,341855775,0);
*%runhosp(2586_0001,2586_0001,2586,0038,,0);
%runhosp(2586_0001,2586_0001,2586,0039,341843403,0);
*%runhosp(2586_0001,2586_0001,2586,0040,113837554,0);
*%runhosp(2586_0001,2586_0001,2586,0041,,0);
*%runhosp(2586_0001,2586_0001,2586,0042,800410599,0);
*%runhosp(2586_0001,2586_0001,2586,0043,,0);
%runhosp(2586_0001,2586_0001,2586,0044,650029298,0);
%runhosp(2586_0001,2586_0001,2586,0045,650556041,0);
%runhosp(2586_0001,2586_0001,2586,0046,264215547,0);
%runhosp(1374_0001,1374_0001,1374,0004,420078,1);
%runhosp(1374_0001,1374_0001,1374,0008,420018,1);
%runhosp(1374_0001,1374_0001,1374,0009,420086,1);
%runhosp(1374_0001,1374_0001,1374,0012,420038,1);
%runhosp(1374_0001,1374_0001,1374,0013,420033,1);
%runhosp(1374_0001,1374_0001,1374,0014,420037,1);
%runhosp(1374_0001,1374_0001,1374,0015,420009,1);
%runhosp(1374_0001,1374_0001,1374,0017,420015,1);
%runhosp(1374_0001,1374_0001,1374,0018,420106,1);
%runhosp(7310_0001,7310_0001,7310,0002,070010,0);
%runhosp(7310_0001,7310_0001,7310,0003,070018,0);
%runhosp(7310_0001,7310_0001,7310,0004,070007,0);
%runhosp(7310_0001,7310_0001,7310,0005,410013,0);
%runhosp(7310_0001,7310_0001,7310,0006,070022,0);
%runhosp(7310_0001,7310_0001,7310,0007,070019,0);
%runhosp(7312_0001,7312_0001,7312,0002,521725543,0);
%runhosp(6054_0001,6054_0001,6054,0002,330019,1);
%runhosp(6055_0001,6055_0001,6055,0002,330194,1);
%runhosp(6056_0001,6056_0001,6056,0002,330201,1);
%runhosp(6057_0001,6057_0001,6057,0002,330221,1);
%runhosp(6058_0001,6058_0001,6058,0002,330233,1);
%runhosp(6059_0001,6059_0001,6059,0002,330397,1);
%runhosp(1209_0000,1209_0000,1209,0000,420004,1);
%runhosp(1028_0000,1028_0000,1028,0000,100008,0);
%runhosp(1103_0000,1103_0000,1103,0000,390004,1);
%runhosp(1167_0000,1167_0000,1167,0000,390173,1);
%runhosp(1368_0000,1368_0000,1368,0000,390049,1);
%runhosp(1461_0000,1461_0000,1461,0000,100296,0);
%runhosp(1634_0000,1634_0000,1634,0000,310012,1);
%runhosp(1803_0000,1803_0000,1803,0000,070017,0);
%runhosp(1958_0000,1958_0000,1958,0000,390183,1);
%runhosp(2070_0000,2070_0000,2070,0000,100084,1);
%runhosp(2214_0000,2214_0000,2214,0000,100285,0);
%runhosp(2215_0000,2215_0000,2215,0000,100230,0);
%runhosp(2216_0000,2216_0000,2216,0000,100154,0);
%runhosp(2302_0000,2302_0000,2302,0000,110074,1);
%runhosp(2317_0000,2317_0000,2317,0000,390330,0);
%runhosp(2374_0000,2374_0000,2374,0000,390326,1);
%runhosp(2376_0000,2376_0000,2376,0000,390035,1);
%runhosp(2378_0000,2378_0000,2378,0000,390197,1);
%runhosp(2379_0000,2379_0000,2379,0000,310060,1);
%runhosp(2451_0000,2451_0000,2451,0000,340173,0);
%runhosp(2452_0000,2452_0000,2452,0000,340069,0);
%runhosp(2461_0000,2461_0000,2461,0000,100314,0);
%runhosp(2468_0000,2468_0000,2468,0000,190111,0);
%runhosp(2587_0000,2587_0000,2587,0000,310014,1);
%runhosp(2594_0000,2594_0000,2594,0000,070035,1);
%runhosp(5038_0000,5038_0000,5038,0000,080007,1);
%runhosp(5043_0000,5043_0000,5043,0000,100002,1);
%runhosp(5050_0000,5050_0000,5050,0000,390194,1);
%runhosp(5154_0000,5154_0000,5154,0000,330005,1);
%runhosp(5215_0001,5215_0001,5215,0002,310044,1);
%runhosp(5215_0001,5215_0001,5215,0003,310092,1);
%runhosp(5263_0000,5263_0000,5263,0000,100281,1);
%runhosp(5264_0000,5264_0000,5264,0000,100038,1);
%runhosp(5282_0000,5282_0000,5282,0000,360155,1);
%runhosp(5394_0000,5394_0000,5394,0000,390267,1);
%runhosp(5397_0001,5397_0001,5397,0002,360137,1);
%runhosp(5397_0001,5397_0001,5397,0003,360359,1);
%runhosp(5397_0001,5397_0001,5397,0004,360041,1);
%runhosp(5397_0001,5397_0001,5397,0005,360145,1);
%runhosp(5397_0001,5397_0001,5397,0006,360192,1);
%runhosp(5397_0001,5397_0001,5397,0007,360075,1);
%runhosp(5397_0001,5397_0001,5397,0008,360078,1);
%runhosp(5397_0001,5397_0001,5397,0009,360002,1);
%runhosp(5397_0001,5397_0001,5397,0010,360123,1);
%runhosp(5478_0001,5478_0001,5478,0002,310015,1);
%runhosp(5479_0001,5479_0001,5479,0002,310051,1);
%runhosp(5480_0001,5480_0001,5480,0002,310017,1);
%runhosp(5481_0001,5481_0001,5481,0002,310028,1);
%runhosp(5746_0001,5746_0001,5746,0002,100007,1);
%runhosp(1688_0001,1688_0001,1688,0002,310588183,1);
%runhosp(1710_0001,1710_0001,1710,0002,560963485,1);
%runhosp(2941_0001,2941_0001,2941,0002,670067,0);
%runhosp(2956_0001,2956_0001,2956,0002,450853,0);
%runhosp(6049_0001,6049_0001,6049,0002,450880,1);
%runhosp(6051_0001,6051_0001,6051,0002,030112,1);
%runhosp(6052_0001,6052_0001,6052,0002,670076,1);
%runhosp(6053_0001,6053_0001,6053,0002,450883,1);
%runhosp(2974_0001,2974_0001,2974,0003,251716306,0);
%runhosp(2974_0001,2974_0001,2974,0007,232730785,0);


%MEND TP;

%TP(ybase, B);
%TP(&label_monthly., P);
*%TP(&recon_label, R); 

proc printto;run;
%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;

