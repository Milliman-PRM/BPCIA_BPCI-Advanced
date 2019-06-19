%let  _sdtm=%sysfunc(datetime());
*********************************************************
BPCIA: 200_Main_Processing
Code to process imported data in preparation for dashboard data creation
*********************************************************;
options mprint;

/*
***** CHECK BEFORE RUNNING *****
	1) Label Var (18-19)
	2) Vers Var (22)
	3) Type Var (25-26)
********************************
*/

***** USER INPUTS ******************************************************************************************;
%let mode = main; *main = main interface, base = baseline interface;

*%let label = ybase; *Turn on for baseline data, turn off for quarterly data;
%let label = y201905; *Turn off for baseline data, turn on for quarterly data;


%let vers = P; *B for baseline, P for Performance;


*%let type = recon; *Turn on for recon;
%let type = notrecon; *Turn on for baseline/monthly;

***** REFERENCE PROGRAMS ***********************************************************************************;
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";

%let main = H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code;
%include "&main.\000 - Formats - BPCIA.sas";
%include "&main.\000 - Formats_PartB_ICD9_Excl.sas";
%include "&main.\000 - Formats_PartB_ICD10_Excl.sas";
%include "&main.\000 - Formats - Hemophilia Clotting Factors.sas";
%include "&main.\000 - Formats - Isolated CABG.sas";
%include "&main.\000 - BPCIA_Interface_BPIDs.sas";

%let main2 = H:\Nonclient\Medicare Bundled Payment Reference\General\SAS Code;
%include "&main2.\000 - CMMI - Formats - Map ServiceCats.sas";
%include "&main2.\001 - CMMI - Formats - Remap ServiceCats_CJR.sas";

%let main3 = H:\Nonclient\Medicare Bundled Payment Reference\Program - CJR\SAS Code;
%include "&main3.\006_Formats_Complications_ICD9_D12-D18.sas";
%include "&main3.\006_Formats_Complications_ICD9_D111.sas";
%include "&main3.\006_Formats_Complications_ICD10_Exclusions.sas";
%include "&main3.\006_Formats_Complications_ICD10_Outcomes.sas";
%include "&main3.\006A_Formats_Readmission_ICD9.sas";
%include "&main3.\006A_Formats_THATKA_ICD10.sas";

%include "H:\OCM - Oncology Care Model\44 - Oncology Care Model 2019\Work Papers\SAS\000_Additional_IP_Readmissions_Formats.sas" ;
%include "H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\299_200 Macro Support.sas" ;


proc printto;run;


***** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
libname in "&dataDir.\06 - Imported Raw Data";
/*libname out "&dataDir.\07 - Processed Data";*/
libname tp "&dataDir.\08 - Target Price Data";

libname ref "H:\Nonclient\Medicare Bundled Payment Reference\General\SAS Datasets" ;
libname bpcia 'H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets';

%macro modesetup;
%if &mode.=main %then %do;
libname out "&dataDir.\07 - Processed Data\";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\200 - BPCIA Processing_&label._&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=base %then %do;
libname out "&dataDir.\07 - Processed Data\Baseline Interface Demo";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\200 - Baseline BPCIA Processing_&label._&sysdate..log" print=print new;
run;
%end;
%mend modesetup;

%modesetup;
*****;

%MACRO ExcludeReadmits(DRG);
	
	DRG_temp = put(&DRG.,z3.);

	Exclude = put(DRG_temp,$DRG_excl.);

%mend;

%MACRO SERVICE_CHECK(svc);
proc sql;
	create table t_&svc. as
	select EPI_ID_MILLIMAN, sum(std_allowed) as std_allowed, sum(std_allowed_calc) as std_allowed_calc
	from out.&svc._&label._&bpid1._&bpid2.
	group by EPI_ID_MILLIMAN;
quit;
%mend;


%MACRO RunHosp(id1,id2,bpid1,bpid2,prov);

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

data bpcia_performance_episodes;
	set bpcia.bpcia_performance_episodes;
	PERFORMANCE_PERIOD='Yes';
run;

data epi0_pre;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $32. ;
	set %if &label. = ybase %then %do; in.epi_&label._&id1. %end; %else %do; in.epi_&label._&id2. %end; ;	

	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-" || compress(EPISODE_ID);

	if ANCHOR_TYPE = 'ip' then anchor_type_upper = 'IP';
	else if ANCHOR_TYPE = 'op' then anchor_type_upper = 'OP';
	else anchor_type_upper = ANCHOR_TYPE;

	if EPISODE_GROUP_NAME = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPISODE_GROUP_NAME = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;
run;

proc sql;
	create table epi_pre as
	select a.*, coalesce(b.PERFORMANCE_PERIOD,'No') as PERFORMANCE_PERIOD
	from epi0_pre as a left join bpcia_performance_episodes as b
	on a.BPID=b.BPID and a.ANCHOR_TYPE=b.ANCHOR_TYPE and a.EPISODE_GROUP_NAME=b.EPISODE_GROUP_NAME;
quit;

********************
Episode Beneficiary Detail
********************;
data epi0 out.epiexc_&label._&bpid1._&bpid2. perf_epis0;
	set epi_pre (rename= (ATTRIBUTED_PVDR_GROUP_ID=EPISODE_INITIATOR ANCHOR_TRIGGER_CD=ANCHOR_CODE ANCHOR_PROVIDER=ANCHOR_CCN ));

	if EPISODE_INITIATOR = "&PROV." ;

	ref_year = year(ANCHOR_BEG_DT) ;
	
	Epi_2013=0;
	Epi_2017=0;
	if year(ANCHOR_BEG_DT) <= 2013 then Epi_2013=1;
	if year(POST_DSCH_END_DT) >= 2017 then Epi_2017=1;
	DROPFLAG_2013=0;
	if Epi_2013=1 then do;
		DROPFLAG_2013=1;
		DROP_EPISODE=1;
	end;

	%if &label. = ybase %then %do;
		if length(ANCHOR_CODE)=3 then do;
			if length(compress(DRG_2018))=3 then ANCHOR_CODE = compress(DRG_2018);
			else ANCHOR_CODE = '0' || compress(DRG_2018);
		end;

		format FLAG_OVERLAP BEST12. MULT_ATTR_PROVS BEST12. memberid MBI_ID $20. BENE_GENDER $6. BENE_BIRTH_DT MMDDYY10. BENE_DEATH_DT MMDDYY10. CNT_ATTR_PGP BEST12. ;
		FLAG_OVERLAP = .;
		MULT_ATTR_PROVS = .;
		memberid = BENE_SK;
		MBI_ID = '.';
		BENE_GENDER = '.';
		BENE_BIRTH_DT = .;
		BENE_DEATH_DT = .;
		if POST_DSCH_END_DT <= (ANCHOR_END_DT + 89) and DEATH_DUR_POSTDSCHRG = 1 then BENE_DEATH_DT = POST_DSCH_END_DT;

		CNT_ATTR_PGP = .;
	%end;
	%if &label. ^= ybase %then %do;
		format memberid BENE_SK $20.;
		memberid = MBI_ID;
		BENE_SK = '.';
	%end;

	format anc_ccn $6.;
	anc_ccn = put(ANCHOR_CCN,$6.);
	if length(compress(ANCHOR_CCN))=5 then anc_ccn = put('0' || compress(ANCHOR_CCN),$6.);

	DROPFLAG_NON_PERF_EPI=0;
	%if &label. ^= ybase %then %do;
		if PERFORMANCE_PERIOD = 'No' then do;
			DROPFLAG_NON_PERF_EPI=1;
		end;
	%end;	

	if DROP_EPISODE ^= 0 then output out.epiexc_&label._&bpid1._&bpid2.;
	else if DROPFLAG_NON_PERF_EPI=1 then output perf_epis0;
	else output epi0;
run;

%EXCLUSIONFILE;

proc sql;
	create table tempepi_pre as
	select a.*, b.EPI_DROPPED_FLAG
	from epi1 as a left join TP_Components_forBase as b
		on a.BPID = b.INITIATOR_BPID
		and a.EPISODE_GROUP_NAME = b.EPI_CAT
		and a.anchor_type_upper = b.EPI_TYPE
		and a.anc_ccn = b.ccn_join;
quit;

data tempepi_prea tempepi_preb;
	set tempepi_pre;
	if EPI_DROPPED_FLAG = 0 then output tempepi_prea;
	else output tempepi_preb;
run;

%if &label. ^= ybase %then %do;
	proc sql;
		create table tempepi_prea2 as
		select a.*, b.TARGET_PRICE_REAL, b.TARGET_PRICE 
		from tempepi_prea as a left join TP_Components as b
			on a.BPID = b.INITIATOR_BPID
			and a.EPISODE_GROUP_NAME = b.EPI_CAT
			and a.anchor_type_upper = b.EPI_TYPE
			and a.anc_ccn = b.ccn_join
			and b.epi_start <= a.ANCHOR_BEG_DT <= b.epi_end;
	quit;
%end;
%else %do;
	proc sql;
		create table tempepi_prea2 as
		select a.*, b.TARGET_PRICE_REAL, b.TARGET_PRICE 
		from tempepi_prea as a left join TP_Components_forBase as b
			on a.BPID = b.INITIATOR_BPID
			and a.EPISODE_GROUP_NAME = b.EPI_CAT
			and a.anchor_type_upper = b.EPI_TYPE
			and a.anc_ccn = b.ccn_join;
	quit;
%end;

proc sql;
	create table tempepi_preb2 as
	select a.*, b.TARGET_PRICE_REAL, b.TARGET_PRICE 
	from tempepi_preb as a left join TP_Components as b
		on a.BPID = b.INITIATOR_BPID
		and a.EPISODE_GROUP_NAME = b.EPI_CAT
		and a.anchor_type_upper = b.EPI_TYPE
		and a.anc_ccn = b.ccn_join;
quit;

data epi_pre;
	set tempepi_prea2 tempepi_preb2;
	format wage_index 8.4;
	wage_index = TARGET_PRICE_REAL / TARGET_PRICE ;
	if wage_index = . then wage_index = 1;
	proc sort; by EPI_ID_MILLIMAN;
run;


********************
Inpatient Hospital Claims
********************;

data ip1 ;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $32. ;
	format costgrp type $50.;
	set %if &label. = ybase %then %do; in.ip_&label._&id1.; %end; %else %do; in.ip_&label._&id2.; %end;
	allowed=STAY_ALLOWED;
	std_allowed=STAY_STD_ALLOWED;

	%if &label. ^= ybase %then %do;
		format BENE_SK $20.;
		BENE_SK = '.';
	%end;

	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-" || compress(EPISODE_ID);

	* Use provider number to define type of IP facility claim is for *;
	pv = substr(PROVIDER,3,4);
	pv2 = substr(PROVIDER,3,1);

	type = 'IP';

	util_day = max(1,STAY_dschrgdt-STAY_ADMSN_DT);

	if '3025'=< pv and pv <='3099' then type='IP_Rehab';
	if pv2 in ('T','R') then type='IP_Rehab';
	if STAY_DRG_CD in ('945','946') then type='IP_Rehab';

	if '2000' <= pv and pv <= '2299' then type='IP_LTAC';

	ipps = 0;
	if '0001' <= pv and pv <= '0899' then ipps = 1;
	else if '1300' <= pv and pv <= '1399' then ipps = 1;
	else if '450880' <= PROVIDER and PROVIDER <= '450894' then ipps = 1;

	costgrp = 'OTHER';
	if ipps=1 then costgrp = 'IPPS';
	else if type='IP_Rehab' then costgrp='IRF';
run;

proc sort data=ip1 ; by EPI_ID_MILLIMAN BENE_SK STAY_ADMSN_DT IP_STAY_ID;
run;
	

*** capturing admissions only for analyzed CCN by merging with screened episode file *** ;
data ip2 noipccn;
	merge ip1(in=a) epi_pre(in=b) ; by EPI_ID_MILLIMAN ;
	if a and b=0 then output noipccn ;
	if a and b;
	
	output ip2 ;
run;

*** pro-rate ip data ***;
proc sql ;
	create table ip3 as
	select a.*, b.Geometric_mean_LOS,Special_pay_drg_flag, Final_rule_drg_flag
	from ip2 as a
		left join ref.gm_los as b
			on a.stay_drg_cd = b.drg
			and b.fromdate le a.STAY_ADMSN_DT le b.thrudate
	;
quit;

data ip_&label._&bpid1._&bpid2. out.FrChk_&label._&bpid1._&bpid2. readexc_&label._&bpid1._&bpid2.;
	set ip3 (rename=(TRANSFER_STAY=orig_transfer));

	format dos DATE9.;
	dos = STAY_ADMSN_DT;

	if ANCHOR_STAY_ID = IP_STAY_ID then type = 'IP_Idx';
	if STAY_ADMSN_DT >= ANCHOR_BEG_DT and STAY_DSCHRGDT <= ANCHOR_END_DT and ipps=1 then type = 'IP_Idx';

	*** timeframe is field to keep and will be output for exhibits *** ;
	*** 0 = Anchor, Post-Acute: 1 = 0-30 days, 2 = 31-60 days, 3 =  61-90 days *** ;
	day_difference = dos - ANCHOR_END_DT;
	if type = "IP_Idx" then timeframe = 0 ;
	else if STAY_ADMSN_DT < ANCHOR_BEG_DT and STAY_dschrgdt > ANCHOR_END_DT then do;
		timeframe = 1;
		early_flag = 1;
	end;
	else if dos gt POST_DSCH_END_DT then delete ;
	else if dos - ANCHOR_END_DT le 30 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 60 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT le 90 then timeframe = 3 ;

	* sequestration *;
	if not missing(STAY_dschrgdt) and STAY_dschrgdt <= mdy(3,31,2013) then do;
		allowed = allowed * .98;
		std_allowed = std_allowed * .98;
	end;
	if missing(STAY_dschrgdt) and STAY_THRU_DT <= mdy(3,31,2013) then do; 
		allowed = allowed * .98;
		std_allowed = std_allowed * .98;
	end;

	if FRACTURE_FLAG = 1 then output out.FrChk_&label._&bpid1._&bpid2.;

	format anc_ccn $6.;
	anc_ccn = put(ANCHOR_CCN,$6.);
	if length(compress(ANCHOR_CCN))=5 then anc_ccn = put('0' || compress(ANCHOR_CCN),$6.);
	if type = 'IP' then do;
		if anc_ccn = PROVIDER then type = 'IP_s';
		else type = 'IP_d';
	end;
	if type in ('IP_s','IP_d') then do ;
		%ExcludeReadmits(STAY_DRG_CD);
	end ;

	IP_Prorate=0;
	days1 = STAY_dschrgdt - STAY_ADMSN_DT + 1;
	days2 = POST_DSCH_END_DT - STAY_dschrgdt;
	if STAY_dschrgdt gt POST_DSCH_END_DT then do ;
		days1 = POST_DSCH_END_DT - STAY_ADMSN_DT + 1;
		days2 = STAY_DSCHRGDT - POST_DSCH_END_DT;
		if days1 > Geometric_mean_LOS then do;
			allowed=allowed;
			std_allowed=std_allowed;
		end;
		else do;
			IP_Prorate=1;
			allowed=allowed*min((days1+1)/(days1+days2),1);
			std_allowed=std_allowed*min((days1+1)/(days1+days2),1);
		end;
	end;

	%if &label. = ybase %then %do;
		format AD_DGNS $20.;
		AD_DGNS = '';
	%end;

	%if &label. = ybase %then %do;
		array tran(*) TRANS_IP_STAY_1 - TRANS_IP_STAY_13;
	%end;
	%else %do;
		array tran(*) TRANS_IP_STAY_1 - TRANS_IP_STAY_6;
	%end;
	TRANSFER_STAY=0;
	if orig_transfer > 0 then do;
		do i=1 to dim(tran);
			if IP_STAY_ID = tran[i] then TRANSFER_STAY = i;
		end;
	end;

	std_allowed_calc = std_allowed;
	%if &label. ^= ybase %then %do;
		std_allowed = std_cost_epi_total;
	%end;
	if std_allowed <= 0 then delete;

	std_allowed_wage = std_allowed*wage_index;

	if Exclude ='1' then output readexc_&label._&bpid1._&bpid2.;
	else output ip_&label._&bpid1._&bpid2.;

run;

%TRANS_EXC;

********************
Skilled Nursing Facility Claims
********************;

data snf ;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $32. ;
	format costgrp type $50.;
	set %if &label. = ybase %then %do; in.snf_&label._&id1.; %end; %else %do; in.snf_&label._&id2.; %end;
	type='SNF';	
	allowed = CLM_ALLOWED;

	%if &label. ^= ybase %then %do;
		format BENE_SK $20.;
		BENE_SK = '.';
	%end;

	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-" || compress(EPISODE_ID);

	costgrp = 'SNF';

	%if &label. = ybase %then %do;
		format DGNSCD01-DGNSCD25 $20.;
		array dx(*) DGNSCD01-DGNSCD25;
		do i = 1 to dim(dx);
			dx(i) = '';
		end;
	%end;

run;
proc sort data=snf ; by EPI_ID_MILLIMAN ; run;

*** Capturing SNF recs for CCN by merging against screened episode file *** ;
data snf2 nosnfccn ;
	merge snf(in=a) epi(in=b) ; by EPI_ID_MILLIMAN ;
	if a and b then output snf2 ;
	else if a and b=0 then output nosnfccn ;
run;

data snf3 ;
	set snf2 (rename = (PROVIDER=PROVIDER_NUM));

	format dos DATE9. dschrgdt mmddyy10. PROVIDER $20.;
	dos = admsn_dt;
	PROVIDER = put(PROVIDER_NUM,$20.);

	*if from_dt lt ANCHOR_END_DT then delete;
	*if dos gt POST_DSCH_END_DT then delete ;
	if from_dt gt POST_DSCH_END_DT then delete ;

	days1 = THRU_DT - FROM_DT + 1;
	days2 = POST_DSCH_END_DT - THRU_DT;

	if THRU_DT gt POST_DSCH_END_DT then do ;

		days1 = POST_DSCH_END_DT - FROM_DT + 1;
		days2 = THRU_DT - POST_DSCH_END_DT;
	
		pd = allowed / (days1+days2);
		pd2 = std_allowed / (days1+days2);
		allowed = days1*pd ;
		std_allowed = days1*pd2 ;
	end ;

	if dschrgdt=. then dschrgdt = thru_dt;

	std_allowed_calc = std_allowed;
	%if &label. ^= ybase %then %do;
		std_allowed = std_cost_epi_total;
	%end;
	if std_allowed <= 0 then delete;

	std_allowed_wage = std_allowed*wage_index;

	proc sort; by costgrp type EPI_ID_MILLIMAN admsn_dt dos provider;
run;

proc means data=snf3 noprint;
	by costgrp type EPI_ID_MILLIMAN admsn_dt dos provider;
	id ConvenerID BPID BENE_SK CURHIC_UNEQ EPISODE_INITIATOR ANCHOR_TYPE Anchor_code ANCHOR_CCN FRACTURE_flag ANCHOR_BEG_DT ANCHOR_END_DT
		POST_DSCH_BEG_DT POST_DSCH_END_DT TOT_STD_ALLOWED TOT_RAW_ALLOWED TOT_STD_ALLOWED_IP TOT_STD_ALLOWED_OPL TOT_STD_ALLOWED_DM TOT_STD_ALLOWED_PB TOT_STD_ALLOWED_SN TOT_STD_ALLOWED_HS TOT_STD_ALLOWED_HH_NONRAP 
		wage_index Any_Dual 
		CLAIMNO DGNSCD01-DGNSCD25
	%if &label. ^= ybase %then %do; mbi_id bene_gender bene_birth_dt bene_death_dt %end;
	;
	output out = snf4
	min(FROM_DT)=FROM_DT
	max(THRU_DT)=THRU_DT
	max(dschrgdt)=dschrgdt
	sum(allowed)=allowed													
	sum(std_allowed)=std_allowed
	sum(std_allowed_wage)=std_allowed_wage
	sum(std_allowed_calc)=std_allowed_calc
	;														
run;	

data out.snf_&label._&bpid1._&bpid2. ;
	set snf4;

	*** timeframe is field to keep and will be output for exhibits *** ;
	*** 0 = Anchor, Post-Acute: 1 = 0-30 days, 2 = 31-60 days, 3 =  61-90 days *** ;
	if dos < ANCHOR_END_DT and dschrgdt <= ANCHOR_END_DT then timeframe = 0 ;
	else if dos - ANCHOR_END_DT le 30 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 60 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT le 90 then timeframe = 3 ;

	else if FROM_DT - ANCHOR_END_DT le 30 then timeframe = 1 ;
	else if FROM_DT - ANCHOR_END_DT le 60 then timeframe = 2 ;
	else if FROM_DT - ANCHOR_END_DT le 90 then timeframe = 3 ;

	if dschrgdt=. then util_day = max(1,thru_dt-admsn_dt);
	else util_day = max(1,dschrgdt-admsn_dt);

	days1 = THRU_DT - admsn_dt + 1;
	days2 = POST_DSCH_END_DT - THRU_DT;

	if THRU_DT gt POST_DSCH_END_DT then do ;
		days1 = POST_DSCH_END_DT - admsn_dt + 1;
		days2 = THRU_DT - POST_DSCH_END_DT;
	end;

run;

********************
Home Health Agency Claims
********************;

***Merge HHA Header and Detail File Logic***;
data hha1  ;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $32. ;
	set %if &label. = ybase %then %do; in.hha_&label._&id1. %end; %else %do; in.hha_&label._&id2. %end; (rename=(PROVIDER=PROVIDER_NUM));
	format costgrp type $50. PROVIDER $20.;
	type = 'HH'; * We do not have the information to determine HH_A, HH_B, and LUPA;
	
	allowed = CLM_ALLOWED  ;

	%if &label. ^= ybase %then %do;
		format BENE_SK $20.;
		BENE_SK = '.';
	%end;

	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-" || compress(EPISODE_ID);

	PROVIDER = put(compress(PROVIDER_NUM),$20.);
	if length(compress(PROVIDER_NUM))=5 then PROVIDER = put('0' || compress(PROVIDER_NUM),$20.);

	costgrp='HH';
	if LUPAIND='L' then costgrp = 'LUPA';

	%if &label. = ybase %then %do;
		format DGNSCD01-DGNSCD25 $20.;
		array dx(*) DGNSCD01-DGNSCD25;
		do i = 1 to dim(dx);
			dx(i) = '';
		end;
	%end;

run;
proc sort data=hha1; by EPI_ID_MILLIMAN; run;

*** Recombine with episode file ***;
data out.hha_&label._&bpid1._&bpid2. nohhaccn;
	merge hha1(in=a) epi(in=b) ; by EPI_ID_MILLIMAN ;
	if a and b=0 then output nohhaccn;
	if a and b;

	format dos DATE9.;
	dos = FROM_DT;

	*** timeframe is field to keep and will be output for exhibits *** ;
	*** 0 = Anchor, Post-Acute: 1 = 0-30 days, 2 = 31-60 days, 3 =  61-90 days *** ;
	*if THRU_DT le ANCHOR_BEG_DT then delete;
	if dos gt POST_DSCH_END_DT then delete ;
	else if dos < ANCHOR_END_DT and THRU_DT <= ANCHOR_END_DT then timeframe = 0 ;
	else if dos - ANCHOR_END_DT le 30 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 60 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT LE 90 then timeframe = 3 ;

	array rvcntr(*) RVCNTR01 - RVCNTR45;
	array hcpcs(*) HCPSCD01 - HCPSCD45;
	array util(*) utilday01 - utilday45;
	array revdt(*) REV_DT01 - REV_DT45;
	array pror(*) pro_util01 - pro_util45;
	util_day = max(1,thru_dt-FROM_DT);
	prorate_day = POST_DSCH_END_DT - FROM_DT + 1;
	*Proration;

	days1 = THRU_DT - FROM_DT + 1;
	days2 = POST_DSCH_END_DT - THRU_DT;

	if LUPAIND = 'L' then do;	
		do i=1 to 45;
			util[i]=0;
			pror[i]=0;
			if rvcntr[i] not in (.,1,23) and hcpcs[i] not in ('','Q5001') then do;
				util[i]=1;
				if revdt[i] <= POST_DSCH_END_DT then pror[i]=1;
			end;
		end;
		util_day = sum(of utilday01 -- utilday45);
		prorate_day = sum(of pro_util01 -- pro_util45);

		if THRU_DT gt POST_DSCH_END_DT then do ;
			allowed = allowed*prorate_day/util_day ;
			std_allowed = std_allowed*prorate_day/util_day ;
		end ;
	end;
	else do;
		if THRU_DT gt POST_DSCH_END_DT then do ;

			days1 = POST_DSCH_END_DT - FROM_DT + 1;
			days2 = THRU_DT - POST_DSCH_END_DT;
		
			pd = allowed / (days1+days2);
			pd2 = std_allowed / (days1+days2);
			allowed = days1*pd ;
			std_allowed = days1*pd2 ;
		end ;
	end;

	std_allowed_calc = std_allowed;
	%if &label. ^= ybase %then %do;
		std_allowed = std_cost_epi_total;
	%end;
	if std_allowed <= 0 then delete;

	std_allowed_wage = std_allowed*wage_index;

	output out.hha_&label._&bpid1._&bpid2.;
run;


********************
Outpatient Hospital Claims
********************;

data op ;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $32. ;
	format costgrp type $50.;
	set %if &label. = ybase %then %do; in.op_&label._&id1. %end; %else %do; in.op_&label._&id2. %end; (rename=(PROVIDER=PROVIDER_NUM));
	new_rev = put(REV_CNTR,3.);
	type = compress('OP_' || put(new_rev,$revcode.));
	allowed = LINE_ALLOWED;
	std_allowed = LINE_STD_ALLOWED;
	util_day = max(1,thru_dt-FROM_DT);
	if put(hcpcs_cd,$Hemo_JCodes.) = 'X' then do; *Set hemophilia clotting factors claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;

	format PROVIDER $20.;
	PROVIDER = put(PROVIDER_NUM,$20.);

	%if &label. ^= ybase %then %do;
		format BENE_SK $20.;
		BENE_SK = '.';
	%end;

	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-" || compress(EPISODE_ID);

	* cost group *;
	costgrp = 'OTHER';

	%if &label. = ybase %then %do;
		format DGNSCD01-DGNSCD25 $20.;
		array dx(*) DGNSCD01-DGNSCD25;
		do i = 1 to dim(dx);
			dx(i) = '';
		end;
	%end;

run;

proc sort data=op ; by EPI_ID_MILLIMAN BENE_SK REV_DT CLAIMNO ;

*** Capturing OP recs for CCN by merging against screened episode file. *** ;
data 	op_pre_&label._&bpid1._&bpid2.
		partbexc1_&label._&bpid1._&bpid2.
		noopccn 
		er_&label._&bpid1._&bpid2.;
	merge op(in=a) epi(in=b) ; by EPI_ID_MILLIMAN ;
	if a and b=0 then output noopccn ;
	if a and b;	
	
	format dos DATE9.;
	dos = rev_dt;
	if missing(rev_dt) then dos = from_dt ;

	*if ANCHOR_CLAIMNO = CLAIMNO/* and ANCHOR_LINEITEM = LINEITEM*/ then type = 'OP_Idx' ;
	if ANCHOR_TYPE = 'op' and dos <= ANCHOR_END_DT then type = 'OP_Idx' ;

	*** timeframe is field to keep and will be output for exhibits *** ;
	*** 0 = Anchor, Post-Acute: 1 = 0-30 days, 2 = 31-60 days, 3 =  61-90 days *** ;
	*if FROM_DT lt ANCHOR_END_DT then delete ;
	if dos gt POST_DSCH_END_DT then delete ;
	else if type = 'OP_Idx' then timeframe = 0 ;
	else if dos < ANCHOR_END_DT then timeframe = 0 ;
	else if dos - ANCHOR_END_DT le 30 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 60 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT le 90 then timeframe = 3 ;	

	ER_flag_Line=0;
	if new_rev in (450,451,452,456,459,981) then do;
		if dos=ANCHOR_BEG_DT or dos=(ANCHOR_BEG_DT-1) then do;
			timeframe = 0 ;
			type = 'OP_ER';
			ER_flag_Line=1;
			output er_&label._&bpid1._&bpid2.;
		end;
	end;

	std_allowed_calc = std_allowed;
	%if &label. ^= ybase %then %do;
		std_allowed = std_cost_epi_total;
	%end;
	if std_allowed <= 0 then delete;

	std_allowed_wage = std_allowed*wage_index;

	if RSTUSIND in ('H') then output partbexc1_&label._&bpid1._&bpid2.;
	else output op_pre_&label._&bpid1._&bpid2.;
run;

proc sort nodupkey data=er_&label._&bpid1._&bpid2.;
	by EPI_ID_MILLIMAN claimno;
run;

proc sql;
	create table op_pre2_&label._&bpid1._&bpid2. as
	select a.*, coalesce(b.ER_flag_Line,0) as ER_flag_Claim
	from op_pre_&label._&bpid1._&bpid2. as a left join er_&label._&bpid1._&bpid2. as b
	on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN and a.claimno=b.claimno;
quit;

data op_&label._&bpid1._&bpid2.;
	set op_pre2_&label._&bpid1._&bpid2.;
	if ER_flag_Claim=1 then do;
		timeframe = 0 ;
		if type ^= 'OP_Idx' then type = 'OP_ER';
	end;
	if claimno=ANCHOR_CLAIMNO and LINEITEM=ANCHOR_LINEITEM then type='OP_Idx';
run;

********************
Carrier (Professional Part B) Claims
********************;

data bcarrier1 ;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $32. ;
	format costgrp type $50.;
	format LINEITEM $9.;
	set %if &label. = ybase %then %do; in.pb_&label._&id1. %end; %else %do; in.pb_&label._&id2. %end; (rename=(LINEITEM=LINEITEM2));
	type = compress('Prof_' || put(HCPCS_CD,$hcpcs.));
	*type = "Prof";
	util_day = max(1,thru_dt-FROM_DT);

	%if &label. ^= ybase %then %do;
		format BENE_SK $20.;
		BENE_SK = '.';
	%end;

	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-" || compress(EPISODE_ID);

	LINEITEM = strip(LINEITEM2);

	allowed = LINE_ALLOWED;
	std_allowed = LINE_STD_ALLOWED;
	if put(hcpcs_cd,$Hemo_JCodes.) = 'X' then do; *Set hemophilia clotting factors claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;

	* cost group *;
	costgrp = 'OTHER';

	%if &label. = ybase %then %do;
		format DGNSCD01-DGNSCD12 $20.;
		array dx(*) DGNSCD01-DGNSCD12;
		do i = 1 to dim(dx);
			dx(i) = '';
		end;
	%end;

run;

proc sort data=bcarrier1 out=pb; by EPI_ID_MILLIMAN BENE_SK EXPNSDT1 CLAIMNO; run;

*** Capturing Part B recs for CCN by merging against screened episode file, removing non-episodal claims  *** ;
data out.pb_&label._&bpid1._&bpid2.
	 partbexc2_&label._&bpid1._&bpid2. 
	 partbdt2_&label._&bpid1._&bpid2. 
	 nopbccn ;
	merge pb(in=a) epi(in=b) ; by EPI_ID_MILLIMAN ;
	if a and b=0 then output nopbccn ;
	if a and b;

	format dos DATE9.;
	dos = EXPNSDT1;

	*** timeframe is field to keep and will be output for exhibits *** ;
	*** 0 = Anchor, Post-Acute: 1 = 0-30 days, 2 = 31-60 days, 3 =  61-90 days *** ;
	if dos < ANCHOR_END_DT then timeframe = 0;
	else if dos = ANCHOR_END_DT and (PLCSRVC=21 or ANCHOR_TYPE = 'op') then timeframe = 0;
	else if dos - ANCHOR_END_DT le 30 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 60 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT le 90 then timeframe = 3 ;
	
	std_allowed_calc = std_allowed;
	%if &label. ^= ybase %then %do;
		std_allowed = std_cost_epi_total;
	%end;
	if std_allowed <= 0 then delete;

	std_allowed_wage = std_allowed*wage_index;

	*if dos = ANCHOR_END_DT and PLCSRVC ^= 21 then output partbexc2_&label._&bpid1._&bpid2.;
	*if dos lt ANCHOR_BEG_DT then output partbdt2_&label._&bpid1._&bpid2. ; 
	if dos gt POST_DSCH_END_DT then output partbdt2_&label._&bpid1._&bpid2. ;
	*20170409 - Exclude OCM PBPM payments;
	else if HCPCS_CD = 'G9678' then output partbdt2_&label._&bpid1._&bpid2. ;
	else output out.pb_&label._&bpid1._&bpid2. ;

run;


********************
Durable Medical Equipment Claims
********************;	

data dme ;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $32. ;
	format costgrp type $50.;
	set %if &label. = ybase %then %do; in.dme_&label._&id1. ; %end; %else %do; in.dme_&label._&id2. ; %end;
	allowed = LINE_ALLOWED;
	std_allowed = LINE_STD_ALLOWED;
	if put(hcpcs_cd,$Hemo_JCodes.) = 'X' then do; *Set hemophilia clotting factors claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;
	type = 'DME';
	util_day = max(1,thru_dt-FROM_DT);

	%if &label. ^= ybase %then %do;
		format BENE_SK $20.;
		BENE_SK = '.';
	%end;

	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-" || compress(EPISODE_ID);

	* cost group *;
	costgrp = 'OTHER';

	%if &label. = ybase %then %do;
		format DGNSCD01-DGNSCD12 $20.;
		array dx(*) DGNSCD01-DGNSCD12;
		do i = 1 to dim(dx);
			dx(i) = '';
		end;
	%end;

run;
proc sort data=dme ; by EPI_ID_MILLIMAN BENE_SK EXPNSDT1 CLAIMNO; run;

*** Capturing DME recs for CCN by merging against screened episode file, removing non-episodal claims *** ;
data out.dme_&label._&bpid1._&bpid2. 
	nodmeccn ;
	merge dme(in=a) epi(in=b) ; by EPI_ID_MILLIMAN ;
	if a and b=0 then output nodmeccn ;
	if a and b;
		
	format dos DATE9.;
	dos = EXPNSDT1;

	*** timeframe is field to keep and will be output for exhibits *** ;
	*** 0 = Anchor, Post-Acute: 1 = 0-30 days, 2 = 31-60 days, 3 =  61-90 days *** ;
	*if dos lt ANCHOR_BEG_DT then delete ;
	if dos gt POST_DSCH_END_DT then delete ;
	else if dos < ANCHOR_END_DT then timeframe = 0;
	else if dos - ANCHOR_END_DT le 30 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 60 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT le 90 then timeframe = 3 ;

	std_allowed_calc = std_allowed;
	%if &label. ^= ybase %then %do;
		std_allowed = std_cost_epi_total;
	%end;
	if std_allowed <= 0 then delete;

	std_allowed_wage = std_allowed*wage_index;

	output out.dme_&label._&bpid1._&bpid2.;
run;



********************
Hospice Claims
********************;	

data hs ;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $32. ;
	format costgrp type $50.;
	set %if &label. = ybase %then %do; in.hs_&label._&id1.; %end; %else %do; in.hs_&label._&id2.; %end;
	type='HS';	
	allowed = CLM_ALLOWED;
	util_day = max(1,thru_dt-FROM_DT);

	%if &label. ^= ybase %then %do;
		format BENE_SK $20.;
		BENE_SK = '.';
	%end;

	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-" || compress(EPISODE_ID);

	* cost group *;
	costgrp = 'OTHER';

	%if &label. = ybase %then %do;
		format DGNSCD01-DGNSCD25 $20.;
		array dx(*) DGNSCD01-DGNSCD25;
		do i = 1 to dim(dx);
			dx(i) = '';
		end;
	%end;

run;
proc sort data=hs ; by EPI_ID_MILLIMAN ; run;

*** Capturing Hosp recs for CCN by merging against screened episode file *** ;
data hs2 nohsccn;
	merge hs(in=a) epi(in=b) ; by EPI_ID_MILLIMAN ;
	if a and b then output hs2 ;
	else if a and b=0 then output nohsccn ;
run;

data out.hs_&label._&bpid1._&bpid2. hsexcl_&label._&bpid1._&bpid2. ;
	set hs2 ;

	format dos DATE9.;
	dos = FROM_DT;

	*** timeframe is field to keep and will be output for exhibits *** ;
	*** 0 = Anchor, Post-Acute: 1 = 0-30 days, 2 = 31-60 days, 3 =  61-90 days *** ;
	*if dos lt ANCHOR_BEG_DT then delete;
	if dos gt POST_DSCH_END_DT then delete ;
	else if dos < ANCHOR_END_DT and THRU_DT <= ANCHOR_END_DT then timeframe = 0 ;
	else if dos - ANCHOR_END_DT le 30 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 60 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT le 90 then timeframe = 3 ;

	days1 = THRU_DT - FROM_DT + 1;
	days2 = POST_DSCH_END_DT - THRU_DT;

	if THRU_DT gt POST_DSCH_END_DT then do ;

		days1 = POST_DSCH_END_DT - FROM_DT + 1;
		days2 = THRU_DT - POST_DSCH_END_DT;
	
		pd = allowed / (days1+days2);
		pd2 = std_allowed / (days1+days2);
		allowed = days1*pd ;
		std_allowed = days1*pd2 ;
	end ;

	std_allowed_calc = std_allowed;
	%if &label. ^= ybase %then %do;
		std_allowed = std_cost_epi_total;
	%end;
	if std_allowed <= 0 then delete;

	std_allowed_wage = std_allowed*wage_index;

	format bill_type $2.;
	bill_type = fac_type || typesrvc;

	if (DEMONUM01 = '73' or DEMONUM02 = '73' or DEMONUM03 = '73' or DEMONUM04 = '73' or DEMONUM05 = '73')
		and bill_type in ('81','82') then output hsexcl_&label._&bpid1._&bpid2.;
	else output out.hs_&label._&bpid1._&bpid2.;
run;


******************************MA New Code******************************;
********************
Attach Prof Claims and DME to IP/SNF
********************;

data tmp1;
	set out.ip_&label._&bpid1._&bpid2. (keep=type EPI_ID_MILLIMAN BENE_SK STAY_ADMSN_DT STAY_DSCHRGDT STAY_DRG_CD STAY_THRU_DT
						rename=(STAY_ADMSN_DT=ADMSN_DT STAY_DSCHRGDT=DSCHRGDT STAY_DRG_CD=DRG_CD STAY_THRU_DT=THRU_DT)) 
		out.snf_&label._&bpid1._&bpid2.(keep=type EPI_ID_MILLIMAN BENE_SK CLAIMNO ADMSN_DT DSCHRGDT FROM_DT THRU_DT
						rename=(ADMSN_DT=ADMSN_DT2 DSCHRGDT=DSCHRGDT2 FROM_DT=ADMSN_DT THRU_DT=DSCHRGDT));
		rename type=type2 ;
run;

data tmp2;
	set out.pb_&label._&bpid1._&bpid2. (keep=type EPI_ID_MILLIMAN BENE_SK CLAIMNO expnsdt1 LINEITEM THRU_DT)
		out.dme_&label._&bpid1._&bpid2. (in=a keep=type EPI_ID_MILLIMAN BENE_SK CLAIMNO expnsdt1 LINEITEM THRU_DT) ;
run;

proc sql;
  create table ip_snf_bcarrier1 as
  	select a.ADMSN_DT, a.ADMSN_DT2, a.type2, a.DRG_CD, a.DSCHRGDT, b.*
	from tmp1 as a left join tmp2 as b
	on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN and 
	   a.ADMSN_DT <= b.EXPNSDT1 <= a.DSCHRGDT; 
quit;

proc sort data=ip_snf_bcarrier1 ; 	by EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM;

** The same physician claim will map to 2 different IP/SNF claims when the ADMSN_DT=DSCHRGDT in SQL step above **;
data dupl okay  ;
	set ip_snf_bcarrier1 ; by EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM;
	if first.LINEITEM and last.LINEITEM  then output okay ;
	else output dupl ;
run ;

*** Rule of thumb, associate professional claims that match to more than one inpatient admission or snf claim *** ;
*** to heirarchy:  Inpatient (Acute) first, then to latest of claims 										  *** ;
*** Example: A Part B claim incurred 1/10/2010 matches to an inpatient stay with discharge date 1/10/2010 and *** ;
*** a SNF stay with admission date 1/10/2010 so the same claim is output twice. Since the inpatient stay 	  *** ;
*** is the highest in heirarchy, the professional dollars will be associated with the inpatient stay only. 	  *** ;

data heirarchy1 other  ;
	set dupl ;
	if type2 in ("IP_d","IP_s","IP_Idx") then output heirarchy1  ;
	else output other  ;
run;
proc sort data=heirarchy1 ;
	by EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ADMSN_DT DSCHRGDT;
run;
data h1;
	set heirarchy1 ;
	by EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ADMSN_DT DSCHRGDT;

	*** take latest of acute stays *** ;
	IF LAST.LINEITEM ;
run;

proc sort data=h1 ;
	by EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM;
run;
data other2 ;
	merge other(in=a) 
		  h1(in=b KEEP=EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM) ;
	BY EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM;
	if a and b=0 ;
run;
proc sort data=other2 ;
	by EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ADMSN_DT DSCHRGDT;
run;

data h2;
	set other2 ; BY EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ADMSN_DT DSCHRGDT;
	*** take latest of all other stays *** ;
	if LAST.LINEITEM ;
run;

data partb(keep = type2 EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM facility_admsn_dt facility_drg)
	 dme(keep = type2 EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM facility_admsn_dt facility_drg);
	set okay h1 h2;
	if missing(type) then delete ; *** removes admissions where no Part B claims were found. *** ;
	format facility_Admsn_DT DATE9.;
	facility_Admsn_DT = ADMSN_DT ;
	if type2 = "SNF" then facility_Admsn_DT= ADMSN_DT2;
	FACILITY_DRG = DRG_CD;

	if type = "DME" then output DME ;
	else output partb ;
run;

proc sort data=partb ; by EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ;
proc sort data=DME ; by EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ;
run;

proc sort data=out.pb_&label._&bpid1._&bpid2. out=bcarrier ; by EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ;
proc sort data=out.dme_&label._&bpid1._&bpid2. out=dme_lines ; by EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ;
run;

data pb2_&label._&bpid1._&bpid2.;
	merge bcarrier(in=a) partb(in=b) ; by EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ;
	if a ;
	if a and b then do ;
		*EXPNSDT1 = FACILITY_Admsn_DT ;
		dos = EXPNSDT1;
	end ;
	*** calculating timeframe *** ;
	IF type2 = "IP_Idx" then timeframe = 0 ;
	else if EXPNSDT1 <= ANCHOR_END_DT then timeframe = 0 ;
	else if EXPNSDT1 - ANCHOR_END_DT le 30 then timeframe = 1 ;
	else if EXPNSDT1 - ANCHOR_END_DT le 60 then timeframe = 2 ;
	else if EXPNSDT1 - ANCHOR_END_DT le 90 then timeframe = 3 ;
run;

data out.dme2_&label._&bpid1._&bpid2.;
	merge dme_lines(in=a) dme(in=b) ; by EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ;
	if a ;
	if a and b then do ;
		*EXPNSDT1 = FACILITY_Admsn_DT ;
		dos = EXPNSDT1;
	end ;
	*** calculating timeframe *** ;
	IF type2 = "IP_Idx" then timeframe = 0 ;
	else if EXPNSDT1 < ANCHOR_END_DT then timeframe = 0 ;
	else if EXPNSDT1 - ANCHOR_END_DT le 30 then timeframe = 1 ;
	else if EXPNSDT1 - ANCHOR_END_DT le 60 then timeframe = 2 ;
	else if EXPNSDT1 - ANCHOR_END_DT le 90 then timeframe = 3 ;
run;


********************
********************
Calculate episode level allowed 
Assign Episode Risk Corridors
   1. Adjust episode and national numbers to 2012 wage index
   2. Apply growth factor (trend) 
********************
********************;

proc summary nway missing data=out.ip_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=IPsum (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=out.snf_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=SNFsum (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=out.hha_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=HHAsum (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=op_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=OPsum (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=pb2_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=PBsum (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=out.dme2_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=DMEsum (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=out.hs_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=HSsum (drop=_type_ _freq_) sum=;
run;

data episum_&label._&bpid1._&bpid2.;
	set IPsum(in=ip) OPsum(in=op) PBsum(in=pb)
		DMEsum(in=dme) HHAsum(in=hh) SNFsum(in=snf) HSsum(in=hs);
	format typ $3.;
	if ip then typ="ip";
	else if op then typ="op";
	else if pb then typ="pb";
	else if dme then typ="dme";
	else if hh then typ="hh";
	else if snf then typ="snf";
	else if hs then typ="hs";
run;

proc summary nway missing data=episum_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPI_ID_MILLIMAN EPISODE_INITIATOR anchor_code anchor_beg_dt anchor_end_dt;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out= epi_totals (drop = _type_ _freq_) sum=;
run;


****
Report 1
****;

*** merge anchor NPIs and STUS_CD onto episode summary file ***;
proc sql ;
	create table epi_post1 as
	select a.*, b.stus_cd as anchor_stus_cd /*b.CLM_MDCL_REC*/
	from epi as a 
		left join out.ip_&label._&bpid1._&bpid2. as b
			on a.EPI_ID_MILLIMAN = b.EPI_ID_MILLIMAN 
			and b.type = 'IP_Idx'
			and a.ANCHOR_STAY_ID=b.IP_STAY_ID;
quit; 

*** merge on NPI names and STUS_CD description onto episode summary file ***;
proc sql ;
	create table epi_post2 as
	select a.*
		, b.Provider_Organization_Name__Leg as at_npi_org_nm 
		, b.provider_first_name as at_npi_first_nm
		, b.Provider_Last_Name__Legal_Name_ as at_npi_last_nm
	from epi_post1 as a left join ref.npi_data as b
	on a.anchor_at_NPI = input(b.npi,best12.);
quit;

proc sql;
	create table epi_post3 as
	select a.*
		, b.Provider_Organization_Name__Leg as op_npi_org_nm
		, b.provider_first_name as op_npi_first_nm
		, b.Provider_Last_Name__Legal_Name_ as op_npi_last_nm
	from epi_post2 as a left join ref.npi_data as b
	on a.anchor_op_NPI = input(b.npi,best12.);
quit;

proc sql;
	create table epi_post4 as
	select a.*, b.stus_cd_desc
	from epi_post3 as a left join ref.stus_cd_desc as b
	on a.anchor_stus_cd = b.stus_cd ;
quit; 

data data1_&label._&bpid1._&bpid2.;
	set epi_post4;

	keep
		ConvenerID BPID EPI_ID_MILLIMAN EPISODE_INITIATOR EPISODE_ID bene_sk CURHIC_UNEQ ANCHOR_TYPE anchor_code any_dual bene_age ANCHOR_BEG_DT ANCHOR_END_DT anchor_allowed_amt
		stus_cd_desc anchor_at_NPI anchor_op_NPI anchor_stus_cd at_npi_org_nm at_npi_first_nm at_npi_last_nm op_npi_first_nm op_npi_last_nm op_npi_org_nm fracture_flag
		mbi_id bene_gender bene_birth_dt bene_death_dt
		;

run;


****
Report 2 - Claims Lag
****;
/*%if &label ^= ybaseqq or &label ^= ybasey34 %then %do;*/
/**/
/*data data2pre1;*/
/*	set out.ip_&label._&id._&bpid1._&bpid2. (keep= EPISODE_INITIATOR anchor_drg EPI_ID_MILLIMAN EPISODE_IDx anchor_beg_dt anchor_end_dt CLM_PD_DT timeframe allowed std_allowed)*/
/*		out.snf_&label._&id._&bpid1._&bpid2. (keep= EPISODE_INITIATOR anchor_drg EPI_ID_MILLIMAN EPISODE_IDx anchor_beg_dt anchor_end_dt CLM_PD_DT timeframe allowed std_allowed)*/
/*		out.hha_&label._&id._&bpid1._&bpid2. (keep= EPISODE_INITIATOR anchor_drg EPI_ID_MILLIMAN EPISODE_IDx anchor_beg_dt anchor_end_dt CLM_PD_DT timeframe allowed std_allowed)*/
/*		out.op_&label._&id._&bpid1._&bpid2. (keep= EPISODE_INITIATOR anchor_drg EPI_ID_MILLIMAN EPISODE_IDx anchor_beg_dt anchor_end_dt CLM_PD_DT timeframe allowed std_allowed)*/
/*		out.crrier2_&label._&id._&bpid1._&bpid2.(keep= EPISODE_INITIATOR anchor_drg EPI_ID_MILLIMAN EPISODE_IDx anchor_beg_dt anchor_end_dt CLM_PD_DT timeframe allowed std_allowed)*/
/*		out.dme2_&label._&id._&bpid1._&bpid2. (keep= EPISODE_INITIATOR anchor_drg EPI_ID_MILLIMAN EPISODE_IDx anchor_beg_dt anchor_end_dt CLM_PD_DT timeframe allowed std_allowed)*/
/*		out.hs_&label._&id._&bpid1._&bpid2. (keep= EPISODE_INITIATOR anchor_drg EPI_ID_MILLIMAN EPISODE_IDx anchor_beg_dt anchor_end_dt CLM_PD_DT timeframe allowed std_allowed);*/
/*	Paid_YearMo = 100*year(CLM_PD_DT)+ month(CLM_PD_DT);*/
/*run;*/
/**/
/*proc summary nway missing data=data2pre1;*/
/*	class EPISODE_INITIATOR Paid_YearMo EPISODE_IDx EPI_ID_MILLIMAN anchor_DRG ANCHOR_BEG_DT ANCHOR_END_DT;*/
/*	var allowed std_allowed;*/
/*	output out= out.data2_&label._&id._&bpid1._&bpid2. (drop= _type_ _freq_) sum=;*/
/*run;*/
/**/
/*%end;*/


****
Report 3
****;

proc summary nway missing data=out.ip_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe type dos STAY_DSCHRGDT PROVIDER
		  BENE_SK STAY_DRG_CD ANCHOR_CCN;
	var util_day allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=ipsum1 (rename=(STAY_DSCHRGDT=DSCHRG_DT) drop=_type_ _freq_) sum=;
run;

proc sql;
	create table snfsum1 as 
		select ConvenerID, BPID, EPI_ID_MILLIMAN, ANCHOR_TYPE 
			  ,type
			  ,PROVIDER
			  ,admsn_dt as dos
			  ,min(timeframe) as timeframe
			  ,coalesce(max(DSCHRGDT),max(thru_dt)) as DSCHRGDT
			  ,sum(allowed) as allowed
			  ,sum(std_allowed) as std_allowed
			  ,sum(std_allowed_wage) as std_allowed_wage
			  ,sum(std_allowed_calc) as std_allowed_calc
			  ,sum(util_day) as util_day
		from out.snf_&label._&bpid1._&bpid2.
		group by ConvenerID, BPID, EPI_ID_MILLIMAN, ANCHOR_TYPE 
			  ,type
			  ,PROVIDER
			  ,admsn_dt
			  ;
quit;

proc summary nway missing data=out.hha_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe type dos PROVIDER
		  BENE_SK CLAIMNO;
	var util_day allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=hhasum1 (drop=_type_ _freq_) sum=;
run;

proc summary nway missing data=op_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe type dos PROVIDER
		  BENE_SK CLAIMNO;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=opsum1 (drop=_type_ _freq_) sum=;
run;

proc summary nway missing data=pb2_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe type type2 dos
		  BENE_SK CLAIMNO;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=pbsum1 (drop=_type_ _freq_) sum=;
run;

proc summary nway missing data=out.dme2_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe type type2 dos
		  BENE_SK CLAIMNO;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=dmesum1 (drop=_type_ _freq_) sum=;
run;

proc summary nway missing data=out.hs_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe type /*type*/ dos
		  BENE_SK CLAIMNO;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=hssum1 (drop=_type_ _freq_) sum=;
run;

data all_clm;
	set ipsum1 snfsum1 hhasum1 opsum1 pbsum1 dmesum1 hssum1;

	format sumcat $50.;
	if timeframe = 0 then sumcat = put(type, $sub_one.);
	else if type = 'HS' then sumcat = 'Other';

	else do;
		if missing(type2) then do;
			sumcat = put(type, $sub_two.);
			if (substr(sumcat,1,2)='IP' or substr(sumcat,1,3)='SNF') then sumcat = compress(sumcat|| '_F');
		end;
		else sumcat = compress(put(type2, $sub_two.) || '_P');
	end;

	if timeframe = 0 and type = 'OP_ER' then sumcat = 'OP_ER';

run;

***Summarize SNF and HH Claims***;

proc summary nway missing data=snfsum1;
	class ConvenerID BPID EPI_ID_MILLIMAN timeframe;
	output out=snf_sum_admits (drop=_type_ rename= (_freq_=SNF_admits));
run;

proc sort data=snfsum1 ;
	by ConvenerID BPID EPI_ID_MILLIMAN timeframe dos;
run;

proc sort nodupkey data=snfsum1 out=snf_add2;
	by ConvenerID BPID EPI_ID_MILLIMAN timeframe;
run;

data snf_add3 (rename=(dos=dos2 PROVIDER=CCN2 DSCHRGDT=DSCHRG_DT2));
	merge snfsum1 (in=a) snf_add2(in=b);
	by ConvenerID BPID EPI_ID_MILLIMAN timeframe dos PROVIDER;
	if a;
	if not b;
run;

proc sort data=snf_add3;
	by ConvenerID BPID EPI_ID_MILLIMAN timeframe dos2;
run;

proc sort nodupkey data=snf_add3 out=snf_add4;
	by ConvenerID BPID EPI_ID_MILLIMAN timeframe;
run;

data snf_add2a (rename=(dos=dos1 PROVIDER=CCN1 DSCHRGDT=DSCHRG_DT));
	set snf_add2;
run;

data snf_summary1;
	merge snf_sum_admits (in=a) snf_add2a(in=b);
	by ConvenerID BPID EPI_ID_MILLIMAN timeframe;
	if a;
run;

data snf_summary2;
	merge snf_summary1 (in=a) snf_add4(in=b);
	by ConvenerID BPID EPI_ID_MILLIMAN timeframe;
	if a;
	sumcat = "SNF_F";
run;

proc summary nway missing data=out.hha_&label._&bpid1._&bpid2.;
	class ConvenerID BPID EPI_ID_MILLIMAN timeframe;
	var THRU_DT;
	output out=hha_summary1 (drop=_type_ _freq_) max(THRU_DT)= DSCHRG_DT;
run;

data hha_summary2;
	set hha_summary1;
	sumcat= "HH";
run;

** First CCN and dos **;
proc sort data=all_clm; by ConvenerID BPID EPI_ID_MILLIMAN timeframe sumcat dos; run;
proc sort nodupkey data=all_clm
	out=first_dos_ccn (keep=ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat dos DSCHRG_DT provider STAY_DRG_CD);
	by ConvenerID BPID EPI_ID_MILLIMAN timeframe sumcat;
run;

proc summary nway missing data=all_clm;
	class ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat
		  BENE_SK CLAIMNO;
	var util_day allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=pre1 (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=pre1;
	class ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat;
	var util_day allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=pre2 (drop=_type_ rename=_freq_=claims) sum=;
run;

data pre3;
	merge pre2(in=a) first_dos_ccn(in=b);
	by ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat;
	if not (a and b) then error;
run;
proc sort data=epi_totals ; by ConvenerID BPID EPI_ID_MILLIMAN ; run;

data data3pre1;
	merge epi_totals (in=a) pre3(in=b);
	by ConvenerID BPID EPI_ID_MILLIMAN;
	if not (a and b) then error;
	proc sort; by ConvenerID BPID EPI_ID_MILLIMAN;
run;

data data3pre2;
	merge data3pre1 (in=a) snf_summary2(drop=allowed std_allowed std_allowed_wage std_allowed_calc util_day in=b);
	by ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat;
	if a;
	if sumcat="SNF_F" then claims=SNF_admits;
	drop SNF_admits dos1 CCN1;
run;

data out.data3_&label._&bpid1._&bpid2.(drop=provider);
	merge data3pre2 (in=a) hha_summary2(in=b);
	by ConvenerID BPID EPI_ID_MILLIMAN timeframe sumcat;
	if a;
	format provider_ccn $6.;
	PROVIDER_CCN=provider;
	if length(compress(provider))=5 then PROVIDER_CCN = put('0' || compress(provider),$6.);
	proc sort; by ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat;
run;

**** CALCULATE CABG MORTALITY QUALITY MEASURE ****;
	data CABG_Mortality_&bpid1._&bpid2.;
		set out.ip_&label._&bpid1._&bpid2.;
		if EPISODE_GROUP_NAME='Coronary artery bypass graft'
			and type='IP_Idx' /* keeps only index stays */
			and BENE_AGE>=65
			and ('0001' <= pv and pv <= '0899') /* keeps only short-term acute care hospitals */
			and stus_cd ne '07' /* stus_cd indicates that a patient was discharged against medical advice */
		;

		include_CABG=0;
		exclude_CABG=0;
		array px(*) PRCDRCD01-PRCDRCD25;
		if STAY_DSCHRGDT >= '01OCT2015'd then do i=1 to dim(px);
			if put(px[i],$CABG_10Inc.)='Y' then include_CABG=1;
			if put(px[i],$CABG_10Exc.)='Y' then exclude_CABG=1;
		end;
		else do i=1 to dim(px);
			if put(px[i],$CABG_9Inc.)='Y' then include_CABG=1;
			if put(px[i],$CABG_9Exc.)='Y' then exclude_CABG=1;
		end;
		if include_CABG=1 and exclude_CABG=0;

		format Mortality_CABG $3.;
		Mortality_CABG = 'No';
		if STAY_THRU_DT <= BENE_DEATH_DT <= STAY_THRU_DT+30 then Mortality_CABG = 'Yes';

		proc sort; by EPI_ID_MILLIMAN STAY_ADMSN_DT;
		proc sort nodupkey; by EPI_ID_MILLIMAN;
	run;

	proc sql;
		create table epi2_&label._&bpid1._&bpid2. as
		select a.*, coalesce(b.Mortality_CABG,'N/A') as Mortality_CABG
		from epi_&label._&bpid1._&bpid2. as a left join CABG_Mortality_&bpid1._&bpid2. as b
		on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN;
	quit;

	data out.epi_&label._&bpid1._&bpid2.;
		set epi2_&label._&bpid1._&bpid2.;
		if EPISODE_GROUP_NAME ^= 'Coronary artery bypass graft' then Mortality_CABG = '-';
	run;

****** QUALITY MEASURES *************************************************************************************;
%include "H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\402 - BPCIA THA-TKA Complications.sas";
%include "H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\403 - BPCIA All-Cause Unplanned Readmission.sas";
%include "H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\404 - Excess Days in Acute Care.sas";


**********************************************;
*************** Checking Files ***************;
**********************************************;

%SERVICE_CHECK(op);
*%SERVICE_CHECK(ip);
%SERVICE_CHECK(dme2);
%SERVICE_CHECK(pb2);
%SERVICE_CHECK(snf);
%SERVICE_CHECK(hs);
%SERVICE_CHECK(hha);
proc sql;
	create table t_ip as
	select EPI_ID_MILLIMAN, sum(std_allowed) as std_allowed, max(IP_Prorate) as IP_Prorate, sum(std_allowed_calc) as std_allowed_calc
	from out.ip_&label._&bpid1._&bpid2.
	group by EPI_ID_MILLIMAN;
quit;

proc sql;
	create table chk_&label._&bpid1._&bpid2. as
	select a.ConvenerID, a.BPID, a.TOT_STD_ALLOWED, a.EPI_ID_MILLIMAN, a.ANCHOR_TYPE, a.EPISODE_GROUP_NAME, a.ANCHOR_CODE, a.Epi_2013, a.Epi_2017, c.IP_Prorate,
		a.TOT_STD_ALLOWED_OPL, coalesce(b.std_allowed,0) as op_allowed, round(a.TOT_STD_ALLOWED_OPL-coalesce(b.std_allowed,0),.01) as op_diff, 
		a.TOT_STD_ALLOWED_IP, coalesce(c.std_allowed,0) as ip_allowed, round(a.TOT_STD_ALLOWED_IP-coalesce(c.std_allowed,0),.01) as ip_diff, 
		a.TOT_STD_ALLOWED_DM, coalesce(d.std_allowed,0) as dme_allowed, round(a.TOT_STD_ALLOWED_DM-coalesce(d.std_allowed,0),.01) as dme_diff, 
		a.TOT_STD_ALLOWED_PB, coalesce(e.std_allowed,0) as pb_allowed, round(a.TOT_STD_ALLOWED_PB-coalesce(e.std_allowed,0),.01) as pb_diff, 
		a.TOT_STD_ALLOWED_SN, coalesce(f.std_allowed,0) as snf_allowed, round(a.TOT_STD_ALLOWED_SN-coalesce(f.std_allowed,0),.01) as snf_diff, 
		a.TOT_STD_ALLOWED_HS, coalesce(g.std_allowed,0) as hs_allowed, round(a.TOT_STD_ALLOWED_HS-coalesce(g.std_allowed,0),.01) as hs_diff, 
		a.TOT_STD_ALLOWED_HH_NONRAP, coalesce(h.std_allowed,0) as hha_allowed, round(a.TOT_STD_ALLOWED_HH_NONRAP-coalesce(h.std_allowed,0),.01) as hha_diff, 
		a.ANCHOR_BEG_DT, a.ANCHOR_END_DT, a.POST_DSCH_BEG_DT, a.POST_DSCH_END_DT,
		round(coalesce(b.std_allowed_calc,0)-coalesce(b.std_allowed,0),.01) as op_calc_diff,
		round(coalesce(c.std_allowed_calc,0)-coalesce(c.std_allowed,0),.01) as ip_calc_diff, 
		round(coalesce(d.std_allowed_calc,0)-coalesce(d.std_allowed,0),.01) as dme_calc_diff,
		round(coalesce(e.std_allowed_calc,0)-coalesce(e.std_allowed,0),.01) as pb_calc_diff,
		round(coalesce(f.std_allowed_calc,0)-coalesce(f.std_allowed,0),.01) as snf_calc_diff,
		round(coalesce(g.std_allowed_calc,0)-coalesce(g.std_allowed,0),.01) as hs_calc_diff,
		round(coalesce(h.std_allowed_calc,0)-coalesce(h.std_allowed,0),.01) as hha_calc_diff
	from out.epi_&label._&bpid1._&bpid2. as a
		left join t_op as b
			on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
		left join t_ip as c
			on a.EPI_ID_MILLIMAN=c.EPI_ID_MILLIMAN
		left join t_dme2 as d
			on a.EPI_ID_MILLIMAN=d.EPI_ID_MILLIMAN
		left join t_pb2 as e
			on a.EPI_ID_MILLIMAN=e.EPI_ID_MILLIMAN
		left join t_snf as f
			on a.EPI_ID_MILLIMAN=f.EPI_ID_MILLIMAN
		left join t_hs as g
			on a.EPI_ID_MILLIMAN=g.EPI_ID_MILLIMAN
		left join t_hha as h
			on a.EPI_ID_MILLIMAN=h.EPI_ID_MILLIMAN;
quit;

data out.chk_&label._&bpid1._&bpid2.;
	format ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE EPISODE_GROUP_NAME ANCHOR_CODE Epi_2013 Epi_2017 IP_Prorate Milliman_CMS_Discrepancy TOT_STD_ALLOWED total_allowed total_diff;
	set chk_&label._&bpid1._&bpid2.;

	total_allowed = round(sum(op_allowed,ip_allowed,dme_allowed,pb_allowed,snf_allowed,hs_allowed,hha_allowed),.01);
	total_diff = round(round(TOT_STD_ALLOWED,.01) - total_allowed,.01);

	Milliman_CMS_Discrepancy='Yes';
	if total_diff=0 then Milliman_CMS_Discrepancy='No';
run;


proc sql;
	create table out.data1_&label._&bpid1._&bpid2. as
	select a.*, b.Milliman_CMS_Discrepancy, b.Epi_2013, b.Epi_2017
	from data1_&label._&bpid1._&bpid2. as a left join out.chk_&label._&bpid1._&bpid2. as b
	on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN;
quit;
 

****** Summary Output File *************************************************************************************;
%CLINEPI;


*delete work datasets;
proc datasets lib=work memtype=data kill;
run;
quit;

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

%MACRO CLINOUT;
%if &label. ^= ybase %then %do;
	data out.clinepi_&label.;
		set out.clinepi_&label._:;
	run;

	proc export data= out.clinepi_&label.
	        outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\88 - Documentation\50 - BPCI Advanced 2019\Checking Documentation\_Data Summary\Summary of Number of Episodes_&label._&sysdate..csv"
	        dbms=csv replace; 
	run;
%end;
%mend;
%CLINOUT;


proc printto;run;


%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;

