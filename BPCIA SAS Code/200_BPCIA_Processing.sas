%let  _sdtm=%sysfunc(datetime());
*********************************************************
BPCIA: 200_Main_Processing
Code to process imported data in preparation for dashboard data creation
*********************************************************;
options mprint;

***** USER INPUTS ******************************************************************************************;
/* turn on for baseline */
*%let mode = main; *main = main interface, base = baseline interface, recon = reconciliation;
*%let label = ybase; *Turn on for baseline data, turn off for quarterly data;
*%let vers = B; *B for baseline, P for Performance;

/*turn on for performance */
%let mode = main; *main = main interface, base = baseline interface, recon = reconciliation;
%let label_monthly = y202005; *Turn off for baseline data, turn on for quarterly data;
%let label_quarterly = y202004; *Turn off for baseline data, turn on for quarterly data;
%let label_semi_annual = y202004; *Turn off for baseline data, turn on for quarterly data;
%let label = &label_monthly.; *Turn off for baseline data, turn on for quarterly data;
%let vers = P; *B for baseline, P for Performance;


%let quarterly = N; /* Y if quarterly; N if not quarterly */
%let semi_annual = N; /* Y if quarterly; N if not quarterly */


/*turn on for recon */
*%let mode = recon; *main = main interface, base = baseline interface, recon = reconciliation;
*%let label = PP1T_PP2I; *Turn off for baseline data, turn on for quarterly data;
*%let vers = P; *B for baseline, P for Performance;


/****** REFERENCE PROGRAMS ***********************************************************************************;*/
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";

%let main = H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code;
%include "&main.\000 - Formats - BPCIA.sas";
%include "&main.\000 - Formats - COVID.sas";
%include "&main.\000 - Formats - BPCIA_MY3.sas";
%include "&main.\000 - Formats_PartB_ICD9_Excl.sas";
%include "&main.\000 - Formats_PartB_ICD10_Excl.sas";
%include "&main.\000 - Formats - Hemophilia Clotting Factors.sas";
%include "&main.\000 - Formats - Isolated CABG.sas";
%include "&main.\000 - BPCIA_Interface_BPIDs.sas";
%include "&main.\000 - Formats_PartB_HCPCS_Excl.sas";
%include "&main.\000 - Formats - Hemophilia Clotting Factors_MY3.sas";
%include "&main.\000 - Formats - Cardiac Rehab.sas";

%let main2 = H:\Nonclient\Medicare Bundled Payment Reference\General\SAS Code;
%include "&main2.\000 - CMMI - Formats - Map ServiceCats.sas";
%include "&main2.\001 - CMMI - Formats - Remap ServiceCats_CJR.sas";
%include "&main2.\000 - NPI Format.sas";

%let main3 = H:\Nonclient\Medicare Bundled Payment Reference\Program - CJR\SAS Code;
%include "&main3.\006_Formats_Complications_ICD9_D12-D18.sas";
%include "&main3.\006_Formats_Complications_ICD9_D111.sas";
%include "&main3.\006_Formats_Complications_ICD10_Exclusions.sas";
%include "&main3.\006_Formats_Complications_ICD10_Outcomes.sas";
%include "&main3.\006A_Formats_Readmission_ICD9.sas";
%include "&main3.\006A_Formats_THATKA_ICD10.sas";


%include "H:\OCM - Oncology Care Model\44 - Oncology Care Model 2020\Work Papers\SAS\000_Additional_IP_Readmissions_Formats.sas" ;
%include "H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\299_200 Macro Support.sas" ;



proc printto;run;


***** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
libname in "&dataDir.\06 - Imported Raw Data";
/*libname out "&dataDir.\07 - Processed Data";*/
libname tp "&dataDir.\08 - Target Price Data";

libname ref "H:\Nonclient\Medicare Bundled Payment Reference\General\SAS Datasets" ;
libname bpcia 'H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets';
libname cjrref "H:\Nonclient\Medicare Bundled Payment Reference\Program - CJR\SAS Datasets";
libname bpciaref "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets"; 

%macro modesetup;
%if &mode.=main %then %do;
libname out "&dataDir.\07 - Processed Data\";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\200 - BPCIA Processing_&label._&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=base %then %do;
libname out "&dataDir.\07 - Processed Data\Baseline Interface Demo";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\200 - Baseline BPCIA Processing_&label._&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=dev %then %do;
libname out "&dataDir.\07 - Processed Data\Development";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\200 - Dev BPCIA Processing_&label._&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=recon %then %do;
libname out "&dataDir.\07 - Processed Data\Recon";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\200 - Recon BPCIA Processing_&label._&sysdate..log" print=print new;
run;
%end;
%mend modesetup;

%modesetup;
*****;

%MACRO ExcludeReadmits(DRG);
	
	DRG_temp = put(&DRG.,$3.);

	if MEASURE_YEAR = 'MY1 & MY2' then do;
		Exclude = put(DRG_temp,$DRG_excl.);
	end;
	else if MEASURE_YEAR = 'MY3' then do;
		Exclude = put(DRG_temp,$DRG_excl_MY3_.);
	end;

%mend;

%MACRO SERVICE_CHECK(svc);
proc sql;
	create table t_&svc. as
	select MEASURE_YEAR, EPI_ID_MILLIMAN, sum(std_allowed) as std_allowed, sum(std_allowed_calc) as std_allowed_calc
	from out.&svc._&label._&bpid1._&bpid2.
	group by MEASURE_YEAR, EPI_ID_MILLIMAN;
quit;
%mend;


%MACRO RunHosp(id1,id2,bpid1,bpid2,prov);


/* quarterly update */
%if &vers. = P and &mode.= main and (&bpid1. = 1075 or &bpid1. = 2048 or &bpid1. = 2049 or &bpid1. = 2589 or &bpid1. = 5037) %then %do;
%let label = &label_quarterly.;
%end;

%else %if &vers. = P and &mode.= main and (&bpid1. = 1148) %then %do;
%let label = &label_semi_annual.;
%end;

%else %if &vers. = P and &mode.= main %then %do;
%let label = &label_monthly.; 
%end;

data TP_Components_all_V2;
	set tp.TP_Components_all;
	format MEASURE_YEAR $10.;
MEASURE_YEAR = 'MY1 & MY2';
run;

data TP_Components_my3_all_V2;
	set tp.TP_Components_my3_all;
	format MEASURE_YEAR $10.;
MEASURE_YEAR = 'MY3';
run;

data TP_Components_all_combined;
set TP_Components_my3_all_V2 TP_Components_all_V2;
run;

data TP_Components;
	set TP_Components_all_combined;
	format ccn_join $6.;
	ccn_join = ASSOC_ACH_CCN;
	if ccn_join = '' then ccn_join = CCN_TIN;
	if length(compress(ccn_join)) = 5 then ccn_join = '0' || ccn_join;

	if EPI_CAT = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPI_CAT = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;
	if EPI_CAT = "Transcathether aortic valve replacement" then
		EPI_CAT = "Endovascular Cardiac Valve Replacement" ;

run; 

proc sort data=TP_Components;
	by MEASURE_YEAR INITIATOR_BPID EPI_CAT EPI_TYPE ccn_join descending rel_dt descending epi_start descending epi_end;
run;

proc sort nodupkey data=TP_Components out=TP_Components_forBase;
	by MEASURE_YEAR INITIATOR_BPID EPI_CAT EPI_TYPE ccn_join;
run;

proc sort nodupkey data=TP_Components;
	by MEASURE_YEAR INITIATOR_BPID EPI_CAT EPI_TYPE ccn_join rel_dt epi_start epi_end Performance_period;
run;

data bpcia_performance_episodes_v2;
	set bpcia.bpcia_performance_episodes;
	format MEASURE_YEAR $10.;
MEASURE_YEAR = 'MY1 & MY2';
run;

data bpcia_performance_epi_my3_V2;
	set bpcia.bpcia_performance_episodes_my3;
	format MEASURE_YEAR $10.;
MEASURE_YEAR = 'MY3';
run;

data bpcia_performance_episodes;
set bpcia_performance_epi_my3_V2 bpcia_performance_episodes_v2;
run;

/****
combines
bpciaref.bpcia_episode_initiator_info
& bpciaref.bpcia_episode_initiator_info_my3 ***/
data bpcia_epi_initiator_info_V1;
	set bpciaref.bpcia_episode_initiator_info;
	drop User_Access_Termination_Date Data_Deletion_Date Health_system_interface_abbrevia;
	*format MEASURE_YEAR $10.;
	*User_Access_Termination_Date_v2 = input(User_Access_Termination_Date, Date9.);
	*Data_Deletion_Date_v2 = input(Data_Deletion_Date, Date9.);
	Health_system_interface_abbr_v2 = input(Health_system_interface_abbrevia, $27.);
*MEASURE_YEAR = 'MY1 & MY2';
run;

/*
data bpcia_epi_initiator_info_mp3_V1;
	set bpciaref.bpcia_episode_initiator_info_my3;
	drop User_Access_Termination_Date Data_Deletion_Date Health_system_interface_abbrevia;
	format MEASURE_YEAR $10.;
	*User_Access_Termination_Date_v2 = input(User_Access_Termination_Date, Date9.);
	*Data_Deletion_Date_v2 = input(Data_Deletion_Date, Date9.);
	Health_system_interface_abbr_v2 = input(Health_system_interface_abbrevia, $27.);
MEASURE_YEAR = 'MY3';
run;
*/
data bpcia_epi_initiator_combined;
set bpcia_epi_initiator_info_V1;
*User_Access_Termination_Date = User_Access_Termination_Date_v2;
*Data_Deletion_Date = Data_Deletion_Date_v2;
Health_system_interface_abbrevia = Health_system_interface_abbr_V2;
run;

/*****
bpcia_clinical_episode_names
bpcia_clinical_episode_names_my3
*******/
data bpcia_clin_epi_names_v2;
	set bpciaref.bpcia_clinical_episode_names;
	drop short_name short_name_2;
	format MEASURE_YEAR $10.;
	short_name_V2 = input(short_name, $30.);
	short_name_2_V2 = input(short_name_2, $11.);
MEASURE_YEAR = 'MY1 & MY2';
run;

data bpcia_clin_epi_names_my3_v2;
	set bpciaref.bpcia_clinical_episode_names_my3;
	drop short_name short_name_2;
	format MEASURE_YEAR $10.;
	short_name_V2 = input(short_name, $30.);
	short_name_2_V2 = input(short_name_2, $11.);
MEASURE_YEAR = 'MY3';
run;

data bpcia_clin_epi_names_combined;
set bpcia_clin_epi_names_v2 bpcia_clin_epi_names_my3_v2;
short_name = short_name_v2;
short_name_2 = short_name_2_v2;
run;

/*******
*******/
data bpcia_drg_mapping_V2;
	set bpciaref.bpcia_drg_mapping;
	format MEASURE_YEAR $10.;
MEASURE_YEAR = 'MY1 & MY2';
run;

data bpcia_drg_mapping_my3_V2;
	set bpciaref.bpcia_drg_mapping_my3;
	format MEASURE_YEAR $10.;
MEASURE_YEAR = 'MY3';
run;

data bpcia_drg_mapping_combined;
set bpcia_drg_mapping_V2 bpcia_drg_mapping_my3_V2;
run;

data epi0_pre;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $132. ;
	set %if %substr(&label.,1,5)  = ybase %then %do; in.epi_&label._&id1. %end; %else %do; in.epi_&label._&id2. %end; 
	(rename=(EPISODE_GROUP_NAME=EPISODE_GROUP_NAME_orig));	

	format Measure_year2 $4.;
	if measure_year = 'MY1 & MY2' then Measure_year2 = 'MY12'; 
	else if measure_year = 'MY3' then Measure_year2 = 'MY3';
	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-"||compress(Measure_Year2)||"-"||compress(EPISODE_ID);

	if measure_year = 'MY3' then EPISODE_GROUP_NAME = substr(EPISODE_GROUP_NAME_orig,4,length(EPISODE_GROUP_NAME_orig)-3);
	else EPISODE_GROUP_NAME = EPISODE_GROUP_NAME_orig; 

	if ANCHOR_TYPE in ('ip','IP') then anchor_type_upper = 'IP';
	else if ANCHOR_TYPE in ('op','OP') then anchor_type_upper = 'OP';
	else anchor_type_upper = 'MS';

	if EPISODE_GROUP_NAME = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPISODE_GROUP_NAME = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;
	if EPISODE_GROUP_NAME = "Transcathether aortic valve replacement" then
		EPISODE_GROUP_NAME = "Endovascular Cardiac Valve Replacement" ;
run;

proc sql;
	create table epi_pre as
	select a.*, B.BPID AS CHECK_BPID, (case when B.BPID IS NOT NULL THEN 'Yes' else 'No' END) as PERFORMANCE_PERIOD,
	b.EPISODE_GROUP_NAME_USE AS CHECK_NAMEB, a.EPISODE_GROUP_NAME AS CHECK_NAMEA
	from epi0_pre as a left join bpcia_performance_episodes as b
	on a.BPID=b.BPID and a.anchor_type_upper=b.ANCHOR_TYPE and a.EPISODE_GROUP_NAME=b.EPISODE_GROUP_NAME_USE
and A.measure_year = B.measure_year;
quit;

********************
Episode Beneficiary Detail
********************;
data epi0 out.epiexc_&label._&bpid1._&bpid2. perf_epis0;
	set epi_pre (rename= (ATTRIBUTED_PVDR_GROUP_ID=EPISODE_INITIATOR ANCHOR_TRIGGER_CD=ANCHOR_CODE ANCHOR_PROVIDER=ANCHOR_CCN ));

	if EPISODE_INITIATOR = "&PROV." ;

	ref_year = year(ANCHOR_BEG_DT) ;
		%if &bpid1. ^= 2586 %then %do;
	if PERFORMANCE_PERIOD = 'Yes';
		%end;
	%if %substr(&label.,1,5)  = ybase %then %do;
		DROP_EPISODE = 0;
		DROPFLAG_NOT_CONT_ENR_AB_NO_C = 0;
		DROPFLAG_ESRD = 0;
		DROPFLAG_OTHER_PRIMARY_PAYER = 0;
		DROPFLAG_NO_BENE_ENR_INFO = 0;
		DROPFLAG_LOS_GT_59 = 0;
		DROPFLAG_NON_HIGHEST_J1 = 0;
		DROPFLAG_TRANS_W_CAH_CANCER = 0;
		DROPFLAG_DEATH_DUR_ANCHOR = 0;
	%end;

	Epi_Pre_Data=0;
	Epi_Post_Data=0;
	 
	if MEASURE_YEAR = 'MY3' AND ANCHOR_BEG_DT < mdy(10,1,2015) then Epi_Pre_Data=1;
	if MEASURE_YEAR = 'MY3' AND  POST_DSCH_END_DT >= mdy(10,1,2018) then Epi_Post_Data=1;
	if MEASURE_YEAR = 'MY1 & MY2' AND ANCHOR_BEG_DT < mdy(1,1,2014) then Epi_Pre_Data=1;
	if MEASURE_YEAR = 'MY1 & MY2' AND  POST_DSCH_END_DT >= mdy(1,1,2017) then Epi_Post_Data=1;
	DROPFLAG_Predata=0;
	if Epi_Pre_Data=1 then do;
		DROPFLAG_Predata=1;
		DROP_EPISODE=1;
	end;

	if MEASURE_YEAR = 'MY3' then do;
		DROPFLAG_ACO_MSSP_OVERLAP = 0;
	end;
	%if %substr(&label.,1,5)  = ybase %then %do;
		else if MEASURE_YEAR ^= 'MY3' then do;
			format BENE_SRNM_NAME BENE_GVN_NAME $32.;
			BENE_SRNM_NAME ='';
			BENE_GVN_NAME ='';
		end;
	%end;

	%if %substr(&label.,1,5)  = ybase %then %do;
		if length(ANCHOR_CODE)=3 then do;
			if length(compress(DRG_2019))=3 then ANCHOR_CODE = compress(DRG_2019);
			else ANCHOR_CODE = '0' || compress(DRG_2019);
		end;
		format DROPFLAG_PRELIM_CJR_OVERLAP BEST12.
		DROPFLAG_PRELIM_BPCI_A_OVERLAP BEST12.
		MULT_ATTR_PROVS BEST12. memberid MBI_ID $20. CNT_ATTR_PGP BEST12. ;
		DROPFLAG_PRELIM_CJR_OVERLAP = .;
		DROPFLAG_PRELIM_BPCI_A_OVERLAP = .;
		MULT_ATTR_PROVS = .;
		memberid = BENE_SK;
		MBI_ID = '.';
		CNT_ATTR_PGP = .;
/*
		format FLAG_OVERLAP BEST12. MULT_ATTR_PROVS BEST12. memberid MBI_ID $20. CNT_ATTR_PGP BEST12. ;
		FLAG_OVERLAP = .;
		MULT_ATTR_PROVS = .;
		memberid = BENE_SK;
		MBI_ID = '.';
		CNT_ATTR_PGP = .;
		*/
	%end;
	%if %substr(&label.,1,5) ^= ybase %then %do;
		format memberid $20.;
		memberid = MBI_ID;
	%end;
	%if &mode. = recon %then %do;
		format DROPFLAG_PRELIM_CJR_OVERLAP BEST12.
		DROPFLAG_PRELIM_BPCI_A_OVERLAP BEST12.
		MULT_ATTR_PROVS BEST12. CNT_ATTR_PGP BEST12. ;
		DROPFLAG_PRELIM_CJR_OVERLAP = .;
		DROPFLAG_PRELIM_BPCI_A_OVERLAP = .;
		MULT_ATTR_PROVS = .;
		CNT_ATTR_PGP = .;
		DROP_EPISODE = 0;
	/*
		format FLAG_OVERLAP BEST12. MULT_ATTR_PROVS BEST12. CNT_ATTR_PGP BEST12. ;
		FLAG_OVERLAP = .;
		MULT_ATTR_PROVS = .;
		CNT_ATTR_PGP = .;
		DROP_EPISODE = 0;
	*/
	%end;

	format anc_ccn $6. epi_period_short $100.;
	anc_ccn = put(ANCHOR_CCN,$6.);
	if length(compress(ANCHOR_CCN))=5 then anc_ccn = put('0' || compress(ANCHOR_CCN),$6.);

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

	DROPFLAG_NON_PERF_EPI=0;
	%if %substr(&label.,1,5) ^= ybase %then %do;
		if PERFORMANCE_PERIOD = 'No' then do;
			DROPFLAG_NON_PERF_EPI=1;
		end;
	%end;

	DROP_EPISODE2=0;
	%if %substr(&label.,1,5) ^= ybase %then %do;
	DROP_EPISODE2=MAX(DROPFLAG_Predata, 
					  DROPFLAG_NOT_CONT_ENR_AB_NO_C, DROPFLAG_ESRD, DROPFLAG_OTHER_PRIMARY_PAYER, 
					  DROPFLAG_NO_BENE_ENR_INFO, DROPFLAG_NON_ACH, DROPFLAG_LOS_GT_59, 
					  DROPFLAG_EXCLUDED_STATE, DROPFLAG_NON_HIGHEST_J1, DROPFLAG_TRANS_W_CAH_CANCER, 
					  DROPFLAG_CJR, DROPFLAG_RCH_DEMO, DROPFLAG_RURAL_PA, 
					  DROPFLAG_ACO_MSSP_OVERLAP, DROPFLAG_ACO_CEC_OVERLAP, DROPFLAG_ACO_NEXTGEN_OVERLAP, 
					  DROPFLAG_ACO_VERMONTAP_OVERLAP, DROPFLAG_DEATH_DUR_ANCHOR);
	%end;
	if Epi_Pre_Data=1 then DROP_EPISODE2=1;

	if DROP_EPISODE2 ^= 0 then output out.epiexc_&label._&bpid1._&bpid2.;
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
		and a.anc_ccn = b.ccn_join
		and A.MEASURE_YEAR = B.MEASURE_YEAR;
quit;

data tempepi_prea tempepi_preb;
	set tempepi_pre;
	if EPI_DROPPED_FLAG = 0 then output tempepi_prea;
	else output tempepi_preb;
run;

%if %substr(&label.,1,5) ^= ybase %then %do;
	proc sql;
		create table tempepi_prea2 as
		select a.*, b.TARGET_PRICE_REAL, b.TARGET_PRICE 
		from tempepi_prea as a left join TP_Components as b
			on a.BPID = b.INITIATOR_BPID
			and a.EPISODE_GROUP_NAME = b.EPI_CAT
			and a.anchor_type_upper = b.EPI_TYPE
			and a.anc_ccn = b.ccn_join
			 and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end
			 AND STRIP(A.epi_period_short) = STRIP(B.performance_period)
			and A.MEASURE_YEAR = B.MEASURE_YEAR;
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
			and a.anc_ccn = b.ccn_join
			and A.MEASURE_YEAR = B.MEASURE_YEAR;
	quit;
%end;

%if %substr(&label.,1,5) ^= ybase %then %do;
proc sql;
	create table tempepi_preb2 as
	select a.*, b.TARGET_PRICE_REAL, b.TARGET_PRICE 
	from tempepi_preb as a left join TP_Components as b
		on a.BPID = b.INITIATOR_BPID
		and a.EPISODE_GROUP_NAME = b.EPI_CAT
		and a.anchor_type_upper = b.EPI_TYPE
		and a.anc_ccn = b.ccn_join
		and b.epi_start <= a.ANCHOR_END_DT <= b.epi_end
		AND A.epi_period_short = B.performance_period
		and A.MEASURE_YEAR = B.MEASURE_YEAR;
quit;
%end;
%else %do;
proc sql;
	create table tempepi_preb2 as
	select a.*, b.TARGET_PRICE_REAL, b.TARGET_PRICE 
	from tempepi_preb as a left join TP_Components as b
		on a.BPID = b.INITIATOR_BPID
		and a.EPISODE_GROUP_NAME = b.EPI_CAT
		and a.anchor_type_upper = b.EPI_TYPE
		and a.anc_ccn = b.ccn_join
		and A.MEASURE_YEAR = B.MEASURE_YEAR;
	quit;
%end;

data epi_pre;
	set tempepi_prea2 tempepi_preb2;
	format wage_index 8.4;
	wage_index = TARGET_PRICE_REAL / TARGET_PRICE ;
	if wage_index = . then wage_index = 1;
	proc sort; by MEASURE_YEAR EPI_ID_MILLIMAN;
run;


********************
Inpatient Hospital Claims
********************;

data ip1 ;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $132. ;
	format costgrp type $50.;
	set %if %substr(&label.,1,5)  = ybase %then %do; in.ip_&label._&id1.; %end; %else %do; in.ip_&label._&id2.; %end;
	allowed=STAY_ALLOWED;
	std_allowed=STAY_STD_ALLOWED;

	%if %substr(&label.,1,5) ^= ybase %then %do;
		format memberid $20.;
		memberid = MBI_ID;
	%end;
	%else %do;
		format memberid $20.;
		memberid = BENE_SK;
	%end;

	format Measure_year2 $4.;
	if measure_year = 'MY1 & MY2' then Measure_year2 = 'MY12'; 
	else if measure_year = 'MY3' then Measure_year2 = 'MY3';
	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-"||compress(Measure_Year2)||"-"||compress(EPISODE_ID);

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

proc sort data=ip1 ; by measure_Year EPI_ID_MILLIMAN BENE_SK STAY_ADMSN_DT IP_STAY_ID;
run;
	
proc sort data=epi_pre ; by measure_Year EPI_ID_MILLIMAN ;
run;


*** capturing admissions only for analyzed CCN by merging with screened episode file *** ;
data ip2 noipccn;
	merge ip1(in=a) epi_pre(in=b) ; by measure_Year EPI_ID_MILLIMAN ;
	if a and b=0 then output noipccn ;
	if a and b;
	
	output ip2 ;
run;

*** pro-rate ip data ***;
data gm_los_cast;
set ref.gm_los;
drg_cast = input(drg, $12.);
run;

proc sql ;
	create table ip3 as
	select a.*, b.Geometric_mean_LOS,Special_pay_drg_flag, Final_rule_drg_flag
	from ip2 as a
		left join gm_los_cast as b
			on a.stay_drg_cd = b.drg_cast
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
	else if dos - ANCHOR_END_DT le 29 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 59 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT le 89 then timeframe = 3 ;

	COVID_FLAG = .;
	if STAY_dschrgdt >= MDY(1,27,2020) THEN COVID_FLAG = 0;
	array dx2(*) DGNSCD01-DGNSCD25;
	do i = 1 to dim(dx2);
			if put(dx2[i],$COVID_ONE.)='Y' and STAY_dschrgdt >= MDY(1,27,2020) then do;
				if timeframe = 0 then COVID_FLAG = 3;
				else COVID_FLAG = 2;
			end;
			if put(dx2[i],$COVID_TWO.)='Y' and STAY_dschrgdt >= MDY(1,27,2020) then do;
				if timeframe = 0 then COVID_FLAG = 3;
				else COVID_FLAG = 2;
			end;
	end;

	* sequestration *;
	if not missing(STAY_dschrgdt) and STAY_dschrgdt <= mdy(3,31,2013) then do;
		allowed = allowed * .98;
		std_allowed = std_allowed * .98;
	end;
	if missing(STAY_dschrgdt) and STAY_THRU_DT <= mdy(3,31,2013) then do; 
		allowed = allowed * .98;
		std_allowed = std_allowed * .98;
	end;

	TAVR=0;
	if MEASURE_YEAR = 'MY3' and ANCHOR_CODE in ('246','247','248','249','250','251') then do;
		array prx(*) PRCDRCD01 - PRCDRCD25;
		do i = 1 to dim(prx);
			if put(prx[i],$TAVR_10ICD.)='Y' then do;
				TAVR=1;
				allowed=0;
				std_allowed=0;
			end;
		end;
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

	if STAY_DRG_CD = '-' then do;
		array dx(*) DGNSCD01-DGNSCD25;
		array px(*) PRDCRCD01-PRDCRCD25;
		do i = 1 to 25;
			dx(i) = '';
			px(i)='';
		end;			
		AD_DGNS = '';
		STAY_DRG_CD='';
	end;


	%if %substr(&label.,1,5)  = ybase %then %do;
		array tran(*) TRANS_IP_STAY_1 - TRANS_IP_STAY_13;
	%end;
	%else %do;
		array tran(*) TRANS_IP_STAY_1 - TRANS_IP_STAY_7;
	%end;
	TRANSFER_STAY=0;
	if orig_transfer > 0 then do;
		do i=1 to dim(tran);
			if IP_STAY_ID = tran[i] then TRANSFER_STAY = i;
		end;
	end;

	std_allowed_calc = std_allowed;
		std_allowed = std_cost_epi_total;
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
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $132. ;
	format costgrp type $50.;
	set %if %substr(&label.,1,5)  = ybase %then %do; in.snf_&label._&id1.; %end; %else %do; in.snf_&label._&id2.; %end;
	type='SNF';	
	allowed = CLM_ALLOWED;

	format Measure_year2 $4.;
	if measure_year = 'MY1 & MY2' then Measure_year2 = 'MY12'; 
	else if measure_year = 'MY3' then Measure_year2 = 'MY3';
	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-"||compress(Measure_Year2)||"-"||compress(EPISODE_ID);


	costgrp = 'SNF';

run;
proc sort data=snf ; by MEASURE_YEAR EPI_ID_MILLIMAN ; run;

*** Capturing SNF recs for CCN by merging against screened episode file *** ;
data snf2 nosnfccn ;
	merge snf(in=a) epi(in=b) ; by MEASURE_YEAR EPI_ID_MILLIMAN ;
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
		std_allowed = std_cost_epi_total;
	if std_allowed <= 0 then delete;

	std_allowed_wage = std_allowed*wage_index;

	proc sort; by MEASURE_YEAR costgrp type EPI_ID_MILLIMAN admsn_dt dos provider;
run;

proc means data=snf3 noprint;
	by MEASURE_YEAR costgrp type EPI_ID_MILLIMAN admsn_dt dos provider;
	id ConvenerID BPID BENE_SK CURHIC_UNEQ EPISODE_INITIATOR ANCHOR_TYPE Anchor_code ANCHOR_CCN FRACTURE_flag ANCHOR_BEG_DT ANCHOR_END_DT
		POST_DSCH_BEG_DT POST_DSCH_END_DT TOT_STD_ALLOWED TOT_RAW_ALLOWED TOT_STD_ALLOWED_IP TOT_STD_ALLOWED_OPL TOT_STD_ALLOWED_DM TOT_STD_ALLOWED_PB TOT_STD_ALLOWED_SN TOT_STD_ALLOWED_HS TOT_STD_ALLOWED_HH_NONRAP 
		wage_index Any_Dual 
		CLAIMNO DGNSCD01-DGNSCD25
		bene_gender bene_birth_dt bene_death_dt 
	%if %substr(&label.,1,5) ^= ybase %then %do; mbi_id %end;
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
	else if dos - ANCHOR_END_DT le 29 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 59 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT le 89 then timeframe = 3 ;

	else if FROM_DT - ANCHOR_END_DT le 29 then timeframe = 1 ;
	else if FROM_DT - ANCHOR_END_DT le 59 then timeframe = 2 ;
	else if FROM_DT - ANCHOR_END_DT le 89 then timeframe = 3 ;

	if dschrgdt=. then util_day = max(1,thru_dt-admsn_dt);
	else util_day = max(1,dschrgdt-admsn_dt);

	days1 = THRU_DT - admsn_dt + 1;
	days2 = POST_DSCH_END_DT - THRU_DT;

	if THRU_DT gt POST_DSCH_END_DT then do ;
		days1 = POST_DSCH_END_DT - admsn_dt + 1;
		days2 = THRU_DT - POST_DSCH_END_DT;
	end;

	COVID_FLAG = .;
	if dschrgdt >= MDY(1,27,2020) THEN COVID_FLAG = 0;
	array dx(*) DGNSCD01-DGNSCD25;
	do i = 1 to dim(dx);
			if put(dx[i],$COVID_ONE.)='Y' and dschrgdt >= MDY(1,27,2020) then do;
				if timeframe = 0 then COVID_FLAG = 3;
				else COVID_FLAG = 2;
			end;
			if put(dx[i],$COVID_TWO.)='Y' and dschrgdt >= MDY(1,27,2020) then do;
				if timeframe = 0 then COVID_FLAG = 3;
				else COVID_FLAG = 2;
			end;
	end;

run;

********************
Home Health Agency Claims
********************;

***Merge HHA Header and Detail File Logic***;
data hha1  ;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $132. ;
	set %if %substr(&label.,1,5)  = ybase %then %do; in.hha_&label._&id1. %end; %else %do; in.hha_&label._&id2. %end; (rename=(PROVIDER=PROVIDER_NUM));
	format costgrp type $50. PROVIDER $20.;
	type = 'HH'; * We do not have the information to determine HH_A, HH_B, and LUPA;
	
	allowed = CLM_ALLOWED  ;

	format Measure_year2 $4.;
	if measure_year = 'MY1 & MY2' then Measure_year2 = 'MY12'; 
	else if measure_year = 'MY3' then Measure_year2 = 'MY3';
	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-"||compress(Measure_Year2)||"-"||compress(EPISODE_ID);

	PROVIDER = put(compress(PROVIDER_NUM),$20.);
	if length(compress(PROVIDER_NUM))=5 then PROVIDER = put('0' || compress(PROVIDER_NUM),$20.);

	costgrp='HH';
	if LUPAIND='L' then costgrp = 'LUPA';

run;
proc sort data=hha1; by measure_Year EPI_ID_MILLIMAN; run;

*** Recombine with episode file ***;
data out.hha_&label._&bpid1._&bpid2. nohhaccn;
	merge hha1(in=a) epi(in=b) ; by measure_Year EPI_ID_MILLIMAN ;
	if a and b=0 then output nohhaccn;
	if a and b;

	format dos DATE9.;
	dos = FROM_DT;

	*** timeframe is field to keep and will be output for exhibits *** ;
	*** 0 = Anchor, Post-Acute: 1 = 0-30 days, 2 = 31-60 days, 3 =  61-90 days *** ;
	*if THRU_DT le ANCHOR_BEG_DT then delete;
	if dos gt POST_DSCH_END_DT then delete ;
	else if dos < ANCHOR_END_DT and THRU_DT <= ANCHOR_END_DT then timeframe = 0 ;
	else if dos - ANCHOR_END_DT le 29 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 59 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT LE 89 then timeframe = 3 ;

	array rvcntr(*) RVCNTR01 - RVCNTR45;
	array hcpcs(*) HCPSCD01 - HCPSCD45;
	array util(*) utilday01 - utilday45;
	array revdt(*) REV_DT01 - REV_DT45;
	array pror(*) pro_util01 - pro_util45;
	util_day = max(1,thru_dt-FROM_DT);
	prorate_day = POST_DSCH_END_DT - FROM_DT + 1;
	*Proration;

	COVID_FLAG = .;
	if thru_dt >= MDY(1,27,2020) THEN COVID_FLAG = 0;
	array dx(*) DGNSCD01-DGNSCD25;
	do i = 1 to dim(dx);
			if put(dx[i],$COVID_ONE.)='Y' and thru_dt >= MDY(1,27,2020) then do;
				if timeframe = 0 then COVID_FLAG = 3;
				else COVID_FLAG = 2;
			end;
			if put(dx[i],$COVID_TWO.)='Y' and thru_dt >= MDY(1,27,2020) then do;
				if timeframe = 0 then COVID_FLAG = 3;
				else COVID_FLAG = 2;
			end;
	end;

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
		std_allowed = std_cost_epi_total;
	if std_allowed <= 0 then delete;

	std_allowed_wage = std_allowed*wage_index;

	output out.hha_&label._&bpid1._&bpid2.;
run;


********************
Outpatient Hospital Claims
********************;

data op ;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $132. ;
	format costgrp $50.;
	set %if %substr(&label.,1,5)  = ybase %then %do; in.op_&label._&id1. %end; %else %do; in.op_&label._&id2. %end; (rename=(PROVIDER=PROVIDER_NUM));
	new_rev = put(REV_CNTR,3.);
/*	type = compress('OP_' || put(new_rev,$revcode.));*/
	allowed = LINE_ALLOWED;
	std_allowed = LINE_STD_ALLOWED;
	util_day = max(1,thru_dt-FROM_DT);

	format PROVIDER $20.;
	PROVIDER = put(PROVIDER_NUM,$20.);

	format Measure_year2 $4.;
	if measure_year = 'MY1 & MY2' then Measure_year2 = 'MY12'; 
	else if measure_year = 'MY3' then Measure_year2 = 'MY3';
	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-"||compress(Measure_Year2)||"-"||compress(EPISODE_ID);

	* cost group *;
	costgrp = 'OTHER';

run;

********************************************************added new step for new REV mapping ;
proc sql;
create table op2 as
select a.*
		,b.rev_mapping as type length =50 
from op as a
left join cjrref.REV_final as b
on a.rev_cntr = b.new_rev 
;
quit;

***************************************************************************************************;

proc sort data=op2 ; by measure_Year EPI_ID_MILLIMAN BENE_SK REV_DT CLAIMNO ;

*** Capturing OP recs for CCN by merging against screened episode file. *** ;
data 	op_pre_&label._&bpid1._&bpid2.
		partbexc1_&label._&bpid1._&bpid2.
		noopccn 
		er_&label._&bpid1._&bpid2.;
	merge op2(in=a) epi(in=b) ; by measure_Year EPI_ID_MILLIMAN ;
	if a and b=0 then output noopccn ;
	if a and b;	
	
	format dos DATE9.;
	dos = rev_dt;
	if missing(rev_dt) then dos = from_dt ;

	if put(hcpcs_cd,$Hemo_JCodes.) = 'X' and Measure_Year = 'MY1 & MY2' then do; *Set hemophilia clotting factors claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;
	if put(hcpcs_cd,$Hemo_JCodes_MY3_.) = 'X' and Measure_Year = 'MY3' then do; *Set hemophilia clotting factors claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;
	if put(hcpcs_cd,$PartBDrug_Excl.) = 'X' and Measure_Year = 'MY3' then do; *Set excluded Part B Drug claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;
	if ANCHOR_CODE in ('385','386','387') and Measure_Year = 'MY3' and put(hcpcs_cd,$PartBDrug_IBD_Excl.) = 'X' then do; *Set excluded IBD Part B Drug claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;
	if put(hcpcs_cd,$CardRehab_Excl.) = 'X' and Measure_Year = 'MY3' then do; *Set Cardiac Rehab claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;

	*if ANCHOR_CLAIMNO = CLAIMNO/* and ANCHOR_LINEITEM = LINEITEM*/ then type = 'OP_Idx' ;
	if ANCHOR_TYPE = 'op' and dos <= ANCHOR_END_DT then type = 'OP_Idx' ;

	*** timeframe is field to keep and will be output for exhibits *** ;
	*** 0 = Anchor, Post-Acute: 1 = 0-30 days, 2 = 31-60 days, 3 =  61-90 days *** ;
	*if FROM_DT lt ANCHOR_END_DT then delete ;
	if dos gt POST_DSCH_END_DT then delete ;
	else if type = 'OP_Idx' then timeframe = 0 ;
	else if dos < ANCHOR_END_DT then timeframe = 0 ;
	else if dos - ANCHOR_END_DT le 29 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 59 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT le 89 then timeframe = 3 ;	

	COVID_FLAG = .;
	if dos >= MDY(1,27,2020) THEN COVID_FLAG = 0;
	array dx(*) DGNSCD01-DGNSCD25;
	do i = 1 to dim(dx);
			if put(dx[i],$COVID_ONE.)='Y' and dos >= MDY(1,27,2020) then do;
				if timeframe = 0 then COVID_FLAG = 3;
				else COVID_FLAG = 2;
			end;
			if put(dx[i],$COVID_TWO.)='Y' and dos >= MDY(1,27,2020) then do;
				if timeframe = 0 then COVID_FLAG = 3;
				else COVID_FLAG = 2;
			end;
	end;

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
		std_allowed = std_cost_epi_total;
	if std_allowed <= 0 then delete;

	std_allowed_wage = std_allowed*wage_index;

	if RSTUSIND in ('H') then output partbexc1_&label._&bpid1._&bpid2.;
	else output op_pre_&label._&bpid1._&bpid2.;
run;

proc sort nodupkey data=er_&label._&bpid1._&bpid2.;
	by measure_Year EPI_ID_MILLIMAN claimno;
run;

proc sql;
	create table op_pre2_&label._&bpid1._&bpid2. as
	select a.*, coalesce(b.ER_flag_Line,0) as ER_flag_Claim
	from op_pre_&label._&bpid1._&bpid2. as a left join er_&label._&bpid1._&bpid2. as b
	on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN and a.claimno=b.claimno
	and a.measure_Year = B.measure_Year;
quit;

data op_pre3_&label._&bpid1._&bpid2.;
	set op_pre2_&label._&bpid1._&bpid2.;
	if ER_flag_Claim=1 then do;
		timeframe = 0 ;
		if type ^= 'OP_Idx' then type = 'OP_ER';
	end;
	if claimno=ANCHOR_CLAIMNO and LINEITEM=ANCHOR_LINEITEM then type='OP_Idx';
run;


proc sql;
create table op_ER as
			select distinct a.*
					,1 as IP_visit_flag
			from op_pre3_&label._&bpid1._&bpid2. as a
			left join out.ip_&label._&bpid1._&bpid2. as b
			on a.epi_id_milliman = b.epi_id_milliman and (a.dos = b.dos or sum(a.dos,1) = b.dos)
			and a.measure_Year = B.measure_Year
			where a.type = "OP_ER" and b.type in ("IP_d","IP_s","IP_Idx")
 ; 

 *Merge flags for overlapping admissions to original dataset;
create table op_ER2 as
		  select distinct 
				 a.*
				,b.IP_visit_flag
		    from op_pre3_&label._&bpid1._&bpid2. as a
			left join op_ER as b
			on a.epi_id_milliman = b.epi_id_milliman and a.dos = b.dos and a.type = b.type
			and a.measure_Year = B.measure_Year
   ;
quit; 

*Change ER visits to ER - stand alone or ER - preceding admit based on overlap with inpatient admissions on the same day;
data op_&label._&bpid1._&bpid2.;
set op_ER2;
	if type = "OP_ER" then do;
    	if IP_visit_flag = 1 then type3 = "OP_ER_R";
		 else type3 = "OP_ER_S";
	end;
run;

********************
Carrier (Professional Part B) Claims
********************;

data bcarrier1 ;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $132. ;
	format costgrp $50.;
	format LINEITEM $9.;
	set %if %substr(&label.,1,5)  = ybase %then %do; in.pb_&label._&id1. %end; %else %do; in.pb_&label._&id2. %end; (rename=(LINEITEM=LINEITEM2));
/*	type = compress('Prof_' || put(HCPCS_CD,$hcpcs.));*/
	util_day = max(1,thru_dt-FROM_DT);

	format Measure_year2 $4.;
	if measure_year = 'MY1 & MY2' then Measure_year2 = 'MY12'; 
	else if measure_year = 'MY3' then Measure_year2 = 'MY3';
	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-"||compress(Measure_Year2)||"-"||compress(EPISODE_ID);


	LINEITEM = strip(LINEITEM2);

	allowed = LINE_ALLOWED;
	std_allowed = LINE_STD_ALLOWED;

	* cost group *;
	costgrp = 'OTHER';

run;

********************************************************added new step for new HCPCS mapping ;

/* Joins PB codes (HCPCS) to SAS out File with new mapping */
proc sql;
create table bcarrier2 as
select a.*
		,b.hcpcs_mapping as type length =50 
from bcarrier1 as a
left join cjrref.HCPCS_final as b
on a.HCPCS_CD = b.proc and b.Year = year(a.expnsdt1)
;
quit;

data bcarrier2_1 ;
set bcarrier2 ;
where type ^= ''; 
run ; 

/* Captures any missing HCPCS that might not have a year */
proc sql;
create table bcarrier3 as
select a.*
		,b.hcpcs_mapping as type1 length =50 
from bcarrier2 as a
left join cjrref.HCPCS_final as b
on a.HCPCS_CD = b.proc and b.earliest_year = 1
where a.type = '' 
;
quit;

data bcarrier3_1(drop=type1) ;
		set bcarrier3 (drop=type) ;
		type=type1 ;
		
run ; 

/*Stacks the two datasets together to form one BCarrier Filer */
data bcarrier4;
		set bcarrier2_1 
			 bcarrier3_1 ;	
run ; 

proc sort data=bcarrier4 out=pb; by measure_Year EPI_ID_MILLIMAN BENE_SK EXPNSDT1 CLAIMNO; run;

*** Capturing Part B recs for CCN by merging against screened episode file, removing non-episodal claims  *** ;
data out.pb_&label._&bpid1._&bpid2.
	 partbexc2_&label._&bpid1._&bpid2. 
	 partbdt2_&label._&bpid1._&bpid2. 
	 nopbccn ;
	merge pb(in=a) epi(in=b) ; by measure_Year EPI_ID_MILLIMAN ;
	if a and b=0 then output nopbccn ;
	if a and b;

	format dos DATE9.;
	dos = EXPNSDT1;

	if put(hcpcs_cd,$Hemo_JCodes.) = 'X' and Measure_Year = 'MY1 & MY2' then do; *Set hemophilia clotting factors claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;
	if put(hcpcs_cd,$Hemo_JCodes_MY3_.) = 'X' and Measure_Year = 'MY3' then do; *Set hemophilia clotting factors claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;
	if put(hcpcs_cd,$PartBDrug_Excl.) = 'X' and Measure_Year = 'MY3' then do; *Set excluded Part B Drug claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;
	if ANCHOR_CODE in ('385','386','387') and Measure_Year = 'MY3' and put(hcpcs_cd,$PartBDrug_IBD_Excl.) = 'X' then do; *Set excluded IBD Part B Drug claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;
	if put(hcpcs_cd,$CardRehab_Excl.) = 'X' and Measure_Year = 'MY3' and PLCSRVC in (11,22) then do; *Set Cardiac Rehab claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;

	*** timeframe is field to keep and will be output for exhibits *** ;
	*** 0 = Anchor, Post-Acute: 1 = 0-30 days, 2 = 31-60 days, 3 =  61-90 days *** ;
	if dos < ANCHOR_END_DT then timeframe = 0;
	else if dos = ANCHOR_END_DT and (PLCSRVC=21 or ANCHOR_TYPE = 'op') then timeframe = 0;
	else if dos - ANCHOR_END_DT le 29 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 59 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT le 89 then timeframe = 3 ;
	
	COVID_FLAG = .;
	if dos >= MDY(1,27,2020) THEN COVID_FLAG = 0;
	array dx(*) DGNSCD01-DGNSCD25;
	do i = 1 to dim(dx);
			if put(dx[i],$COVID_ONE.)='Y' and dos >= MDY(1,27,2020) then do;
				COVID_FLAG = 1;
			end;
			if put(dx[i],$COVID_TWO.)='Y' and dos >= MDY(1,27,2020) then do;
				COVID_FLAG = 1;
			end;
	end;

	std_allowed_calc = std_allowed;
		std_allowed = std_cost_epi_total;
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
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $132. ;
	format costgrp type $50.;
	set %if %substr(&label.,1,5)  = ybase %then %do; in.dme_&label._&id1. ; %end; %else %do; in.dme_&label._&id2. ; %end;
	allowed = LINE_ALLOWED;
	std_allowed = LINE_STD_ALLOWED;

	type = 'DME';
	util_day = max(1,thru_dt-FROM_DT);

	format Measure_year2 $4.;
	if measure_year = 'MY1 & MY2' then Measure_year2 = 'MY12'; 
	else if measure_year = 'MY3' then Measure_year2 = 'MY3';
	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-"||compress(Measure_Year2)||"-"||compress(EPISODE_ID);

	* cost group *;
	costgrp = 'OTHER';

run;
proc sort data=dme ; by measure_Year EPI_ID_MILLIMAN BENE_SK EXPNSDT1 CLAIMNO; run;

*** Capturing DME recs for CCN by merging against screened episode file, removing non-episodal claims *** ;
data out.dme_&label._&bpid1._&bpid2. 
	nodmeccn ;
	merge dme(in=a) epi(in=b) ; by measure_Year EPI_ID_MILLIMAN ;
	if a and b=0 then output nodmeccn ;
	if a and b;
		
	if put(hcpcs_cd,$Hemo_JCodes.) = 'X' and Measure_Year = 'MY1 & MY2' then do; *Set hemophilia clotting factors claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;
	if put(hcpcs_cd,$Hemo_JCodes_MY3_.) = 'X' and Measure_Year = 'MY3' then do; *Set hemophilia clotting factors claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;
	if put(hcpcs_cd,$PartBDrug_Excl.) = 'X' and Measure_Year = 'MY3' then do; *Set excluded Part B Drug claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;
	if ANCHOR_CODE in ('385','386','387') and Measure_Year = 'MY3' and put(hcpcs_cd,$PartBDrug_IBD_Excl.) = 'X' then do; *Set excluded IBD Part B Drug claims to 0*;
		allowed = 0; 
		std_allowed = 0;
	end;

	format dos DATE9.;
	dos = EXPNSDT1;

	*** timeframe is field to keep and will be output for exhibits *** ;
	*** 0 = Anchor, Post-Acute: 1 = 0-30 days, 2 = 31-60 days, 3 =  61-90 days *** ;
	*if dos lt ANCHOR_BEG_DT then delete ;
	if dos gt POST_DSCH_END_DT then delete ;
	else if dos < ANCHOR_END_DT then timeframe = 0;
	else if dos - ANCHOR_END_DT le 29 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 59 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT le 89 then timeframe = 3 ;

	COVID_FLAG = .;
	if dos >= MDY(1,27,2020) THEN COVID_FLAG = 0;
	array dx(*) DGNSCD01-DGNSCD25;
	do i = 1 to dim(dx);
			if put(dx[i],$COVID_ONE.)='Y' and dos >= MDY(1,27,2020) then do;
				COVID_FLAG = 1;
			end;
			if put(dx[i],$COVID_TWO.)='Y' and dos >= MDY(1,27,2020) then do;
				COVID_FLAG = 1;
			end;
	end;

	std_allowed_calc = std_allowed;
		std_allowed = std_cost_epi_total;
	if std_allowed <= 0 then delete;

	std_allowed_wage = std_allowed*wage_index;

	output out.dme_&label._&bpid1._&bpid2.;
run;



********************
Hospice Claims
********************;	

data hs ;
	format ConvenerID BPID $9. EPI_ID_MILLIMAN $132. ;
	format costgrp type $50.;
	set %if %substr(&label.,1,5)  = ybase %then %do; in.hs_&label._&id1.; %end; %else %do; in.hs_&label._&id2.; %end;
	type='HS';	
	allowed = CLM_ALLOWED;
	util_day = max(1,thru_dt-FROM_DT);

	format Measure_year2 $4.;
	if measure_year = 'MY1 & MY2' then Measure_year2 = 'MY12'; 
	else if measure_year = 'MY3' then Measure_year2 = 'MY3';
	BPID = "&BPID1." || "-" || "&BPID2.";
	ConvenerID = tranwrd("&id2.","_","-");
	EPI_ID_MILLIMAN = BPID || "-&vers.-"||compress(Measure_Year2)||"-"||compress(EPISODE_ID);

	* cost group *;
	costgrp = 'OTHER';

run;
proc sort data=hs ; by measure_Year EPI_ID_MILLIMAN ; run;

*** Capturing Hosp recs for CCN by merging against screened episode file *** ;
data hs2 nohsccn;
	merge hs(in=a) epi(in=b) ; by measure_Year EPI_ID_MILLIMAN ;
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
	else if dos - ANCHOR_END_DT le 29 then timeframe = 1 ;
	else if dos - ANCHOR_END_DT le 59 then timeframe = 2 ;
	else if dos - ANCHOR_END_DT le 89 then timeframe = 3 ;

	COVID_FLAG = .;
	if THRU_DT >= MDY(1,27,2020) THEN COVID_FLAG = 0;
	array dx(*) DGNSCD01-DGNSCD25;
	do i = 1 to dim(dx);
			if put(dx[i],$COVID_ONE.)='Y' and THRU_DT >= MDY(1,27,2020) then do;
				if timeframe = 0 then COVID_FLAG = 3;
				else COVID_FLAG = 2;
			end;
			if put(dx[i],$COVID_TWO.)='Y' and THRU_DT >= MDY(1,27,2020) then do;
				if timeframe = 0 then COVID_FLAG = 3;
				else COVID_FLAG = 2;
			end;
	end;

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
		std_allowed = std_cost_epi_total;
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
	set out.ip_&label._&bpid1._&bpid2. (keep=type Measure_Year EPI_ID_MILLIMAN BENE_SK STAY_ADMSN_DT STAY_DSCHRGDT STAY_DRG_CD STAY_THRU_DT
						rename=(STAY_ADMSN_DT=ADMSN_DT STAY_DSCHRGDT=DSCHRGDT STAY_DRG_CD=DRG_CD STAY_THRU_DT=THRU_DT)) 
		out.snf_&label._&bpid1._&bpid2.(keep=type Measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO ADMSN_DT DSCHRGDT FROM_DT THRU_DT
						rename=(ADMSN_DT=ADMSN_DT2 DSCHRGDT=DSCHRGDT2 FROM_DT=ADMSN_DT THRU_DT=DSCHRGDT));
		rename type=type2 ;
run;

data tmp2;
	set out.pb_&label._&bpid1._&bpid2. (keep=type Measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO expnsdt1 LINEITEM THRU_DT)
		out.dme_&label._&bpid1._&bpid2. (in=a keep=type Measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO expnsdt1 LINEITEM THRU_DT) ;
run;

proc sql;
  create table ip_snf_bcarrier1 as
  	select a.ADMSN_DT, a.ADMSN_DT2, a.type2, a.DRG_CD, a.DSCHRGDT, b.*
	from tmp1 as a left join tmp2 as b
	on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN and 
	   a.ADMSN_DT <= b.EXPNSDT1 <= a.DSCHRGDT
	and A.measure_Year = B.measure_Year; 
quit;

proc sort data=ip_snf_bcarrier1 ; 	by measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM;

** The same physician claim will map to 2 different IP/SNF claims when the ADMSN_DT=DSCHRGDT in SQL step above **;
data dupl okay  ;
	set ip_snf_bcarrier1 ; by measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM;
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
	by measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ADMSN_DT DSCHRGDT;
run;
data h1;
	set heirarchy1 ;
	by measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ADMSN_DT DSCHRGDT;

	*** take latest of acute stays *** ;
	IF LAST.LINEITEM ;
run;

proc sort data=h1 ;
	by measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM;
run;
data other2 ;
	merge other(in=a) 
		  h1(in=b KEEP=measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM) ;
	BY measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM;
	if a and b=0 ;
run;
proc sort data=other2 ;
	by measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ADMSN_DT DSCHRGDT;
run;

data h2;
	set other2 ; BY measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ADMSN_DT DSCHRGDT;
	*** take latest of all other stays *** ;
	if LAST.LINEITEM ;
run;

data partb(keep = measure_Year type2 EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM facility_admsn_dt facility_drg)
	 dme(keep = measure_Year type2 EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM facility_admsn_dt facility_drg);
	set okay h1 h2;
	if missing(type) then delete ; *** removes admissions where no Part B claims were found. *** ;
	format facility_Admsn_DT DATE9.;
	facility_Admsn_DT = ADMSN_DT ;
	if type2 = "SNF" then facility_Admsn_DT= ADMSN_DT2;
	FACILITY_DRG = DRG_CD;

	if type = "DME" then output DME ;
	else output partb ;
run;

proc sort data=partb ; by measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ;
proc sort data=DME ; by measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ;
run;

proc sort data=out.pb_&label._&bpid1._&bpid2. out=bcarrier ; by measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ;
proc sort data=out.dme_&label._&bpid1._&bpid2. out=dme_lines ; by measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ;
run;

data pb2_&label._&bpid1._&bpid2.;
	merge bcarrier(in=a) partb(in=b) ; by measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ;
	if a ;
	if a and b then do ;
		*EXPNSDT1 = FACILITY_Admsn_DT ;
		dos = EXPNSDT1;
	end ;
	*** calculating timeframe *** ;
	IF type2 = "IP_Idx" then timeframe = 0 ;
	else if EXPNSDT1 <= ANCHOR_END_DT then timeframe = 0 ;
	else if EXPNSDT1 - ANCHOR_END_DT le 29 then timeframe = 1 ;
	else if EXPNSDT1 - ANCHOR_END_DT le 59 then timeframe = 2 ;
	else if EXPNSDT1 - ANCHOR_END_DT le 89 then timeframe = 3 ;
run;

data out.dme2_&label._&bpid1._&bpid2.;
	merge dme_lines(in=a) dme(in=b) ; by measure_Year EPI_ID_MILLIMAN BENE_SK CLAIMNO LINEITEM ;
	if a ;
	if a and b then do ;
		*EXPNSDT1 = FACILITY_Admsn_DT ;
		dos = EXPNSDT1;
	end ;
	*** calculating timeframe *** ;
	IF type2 = "IP_Idx" then timeframe = 0 ;
	else if EXPNSDT1 < ANCHOR_END_DT then timeframe = 0 ;
	else if EXPNSDT1 - ANCHOR_END_DT le 29 then timeframe = 1 ;
	else if EXPNSDT1 - ANCHOR_END_DT le 59 then timeframe = 2 ;
	else if EXPNSDT1 - ANCHOR_END_DT le 89 then timeframe = 3 ;
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
	class measure_Year ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=IPsum (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=out.snf_&label._&bpid1._&bpid2.;
	class measure_Year ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=SNFsum (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=out.hha_&label._&bpid1._&bpid2.;
	class measure_Year ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=HHAsum (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=op_&label._&bpid1._&bpid2.;
	class measure_Year ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=OPsum (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=pb2_&label._&bpid1._&bpid2.;
	class measure_Year ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=PBsum (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=out.dme2_&label._&bpid1._&bpid2.;
	class measure_Year ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=DMEsum (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=out.hs_&label._&bpid1._&bpid2.;
	class measure_Year ConvenerID BPID EPISODE_INITIATOR anchor_code EPI_ID_MILLIMAN anchor_beg_dt anchor_end_dt timeframe;
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
	class measure_Year ConvenerID BPID EPI_ID_MILLIMAN EPISODE_INITIATOR anchor_code anchor_beg_dt anchor_end_dt;
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
			and a.measure_Year=b.measure_Year
			and b.type = 'IP_Idx'
			and a.ANCHOR_STAY_ID=b.IP_STAY_ID;
quit; 

*** merge on NPI names and STUS_CD description onto episode summary file ***;
/* adds provider info */
data epi_post1_formats ;
set epi_post1 ;
anchor_at_NPI_char = strip(put(anchor_at_NPI,best12.));
Provider_Org_Name__Leg_at = put(anchor_at_NPI_char, $NPI_ORG.);
Provider_First_Name_at = put(anchor_at_NPI_char, $NPI_FNAME.);
Provider_Last_Name_at = put(anchor_at_NPI_char, $NPI_LNAME.);
drop anchor_at_NPI_char;
run;

proc sql ;
	create table epi_post2 as
	select a.*
		, Provider_Org_Name__Leg_at as at_npi_org_nm 
		, provider_first_name_at as at_npi_first_nm
		, Provider_Last_Name_at as at_npi_last_nm
	from epi_post1_formats as a;
quit;

/* adds provider info */
data epi_post2_formats ;
set epi_post2 ;
anchor_op_NPI_char = strip(put(anchor_op_NPI,best12.));
Provider_Org_Name__Leg_op = put(anchor_op_NPI_char, $NPI_ORG.);
Provider_First_Name_op = put(anchor_op_NPI_char, $NPI_FNAME.);
Provider_Last_Name_op = put(anchor_op_NPI_char, $NPI_LNAME.);
drop anchor_op_NPI_char;
run;

proc sql;
	create table epi_post3 as
	select a.*
		, Provider_Org_Name__Leg_op as op_npi_org_nm
		, provider_first_name_op as op_npi_first_nm
		, Provider_Last_Name_op as op_npi_last_nm
	from epi_post2_formats as a ;
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
		mbi_id bene_gender bene_birth_dt bene_death_dt Measure_year
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
	class MEASURE_YEAR ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe type dos STAY_DSCHRGDT PROVIDER
		  BENE_SK STAY_DRG_CD ANCHOR_CCN;
	var util_day allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=ipsum1 (rename=(STAY_DSCHRGDT=DSCHRG_DT) drop=_type_ _freq_) sum=;
run;

proc sql;
	create table snfsum1 as 
		select MEASURE_YEAR, ConvenerID, BPID, EPI_ID_MILLIMAN, ANCHOR_TYPE 
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
		group by MEASURE_YEAR, ConvenerID, BPID, EPI_ID_MILLIMAN, ANCHOR_TYPE 
			  ,type
			  ,PROVIDER
			  ,admsn_dt
			  ;
quit;

proc summary nway missing data=out.hha_&label._&bpid1._&bpid2.;
	class MEASURE_YEAR ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe type dos PROVIDER
		  BENE_SK CLAIMNO;
	var util_day allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=hhasum1 (drop=_type_ _freq_) sum=;
run;

proc summary nway missing data=op_&label._&bpid1._&bpid2.;
	class MEASURE_YEAR ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe type type3 dos PROVIDER
		  BENE_SK CLAIMNO;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=opsum1 (drop=_type_ _freq_) sum=;
run;

proc summary nway missing data=pb2_&label._&bpid1._&bpid2.;
	class MEASURE_YEAR ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe type type2 dos
		  BENE_SK CLAIMNO;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=pbsum1 (drop=_type_ _freq_) sum=;
run;

proc summary nway missing data=out.dme2_&label._&bpid1._&bpid2.;
	class MEASURE_YEAR ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe type type2 dos
		  BENE_SK CLAIMNO;
	var allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=dmesum1 (drop=_type_ _freq_) sum=;
run;

proc summary nway missing data=out.hs_&label._&bpid1._&bpid2.;
	class MEASURE_YEAR ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe type /*type*/ dos
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

	format sumcat1 $50.; *Added new variable sumcat1 and new format sub_three to distinguish ER - Stand Alone and ER - W/ in 1 day;
	if missing(type3) then sumcat1 = '';
	else sumcat1 = put(type3, $sub_three.);
	if type = 'HS' then sumcat1 = 'HS';

run;

***Summarize SNF and HH Claims***;

proc summary nway missing data=snfsum1;
	class measure_Year ConvenerID BPID EPI_ID_MILLIMAN timeframe;
	output out=snf_sum_admits (drop=_type_ rename= (_freq_=SNF_admits));
run;

proc sort data=snfsum1 ;
	by measure_Year ConvenerID BPID EPI_ID_MILLIMAN timeframe dos;
run;

proc sort nodupkey data=snfsum1 out=snf_add2;
	by measure_Year ConvenerID BPID EPI_ID_MILLIMAN timeframe;
run;

data snf_add3 (rename=(dos=dos2 PROVIDER=CCN2 DSCHRGDT=DSCHRG_DT2));
	merge snfsum1 (in=a) snf_add2(in=b);
	by measure_Year ConvenerID BPID EPI_ID_MILLIMAN timeframe dos PROVIDER;
	if a;
	if not b;
run;

proc sort data=snf_add3;
	by measure_Year ConvenerID BPID EPI_ID_MILLIMAN timeframe dos2;
run;

proc sort nodupkey data=snf_add3 out=snf_add4;
	by measure_Year ConvenerID BPID EPI_ID_MILLIMAN timeframe;
run;

data snf_add2a (rename=(dos=dos1 PROVIDER=CCN1 DSCHRGDT=DSCHRG_DT));
	set snf_add2;
run;

data snf_summary1;
	merge snf_sum_admits (in=a) snf_add2a(in=b);
	by measure_Year ConvenerID BPID EPI_ID_MILLIMAN timeframe;
	if a;
run;

data snf_summary2;
	merge snf_summary1 (in=a) snf_add4(in=b);
	by measure_Year ConvenerID BPID EPI_ID_MILLIMAN timeframe;
	if a;
	sumcat = "SNF_F";
run;

proc summary nway missing data=out.hha_&label._&bpid1._&bpid2.;
	class measure_Year ConvenerID BPID EPI_ID_MILLIMAN timeframe;
	var THRU_DT;
	output out=hha_summary1 (drop=_type_ _freq_) max(THRU_DT)= DSCHRG_DT;
run;

data hha_summary2;
	set hha_summary1;
	sumcat= "HH";
run;

** First CCN and dos **;
proc sort data=all_clm; by MEASURE_YEAR ConvenerID BPID EPI_ID_MILLIMAN timeframe sumcat sumcat1 dos; run;
proc sort nodupkey data=all_clm
	out=first_dos_ccn (keep=MEASURE_YEAR ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat sumcat1 dos DSCHRG_DT provider STAY_DRG_CD);
	by measure_Year ConvenerID BPID EPI_ID_MILLIMAN timeframe sumcat sumcat1;
run;

proc summary nway missing data=all_clm;
	class MEASURE_YEAR ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat sumcat1
		  BENE_SK CLAIMNO;
	var util_day allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=pre1 (drop=_type_ _freq_) sum=;
run;
proc summary nway missing data=pre1;
	class MEASURE_YEAR ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat sumcat1;
	var util_day allowed std_allowed std_allowed_wage std_allowed_calc;
	output out=pre2 (drop=_type_ rename=_freq_=claims) sum=;
run;

proc sort data=first_dos_ccn ; by MEASURE_YEAR ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat sumcat1; run;
data pre3;
	merge pre2(in=a) first_dos_ccn(in=b);
	by MEASURE_YEAR ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat sumcat1;
	if not (a and b) then error;
run;

proc sort data=epi_totals ; by measure_Year ConvenerID BPID EPI_ID_MILLIMAN ; run;
proc sort data=pre3 ; by measure_Year ConvenerID BPID EPI_ID_MILLIMAN ; run;

data data3pre1;
	merge epi_totals (in=a) pre3(in=b);
	by measure_Year ConvenerID BPID EPI_ID_MILLIMAN;
	if not (a and b) then error;
	proc sort; by measure_Year ConvenerID BPID EPI_ID_MILLIMAN;
run;

proc sort data=data3pre1 ; by measure_Year ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat; run;

data data3pre2;
	merge data3pre1 (in=a) snf_summary2(drop=allowed std_allowed std_allowed_wage std_allowed_calc util_day in=b);
	by measure_Year ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat;
	if a;
	if sumcat="SNF_F" then claims=SNF_admits;
	drop SNF_admits dos1 CCN1;
run;

data out.data3_&label._&bpid1._&bpid2.(drop=provider);
	merge data3pre2 (in=a) hha_summary2(in=b);
	by measure_Year ConvenerID BPID EPI_ID_MILLIMAN timeframe sumcat;
	if a;
	format provider_ccn $6.;
	PROVIDER_CCN=provider;
	if length(compress(provider))=5 then PROVIDER_CCN = put('0' || compress(provider),$6.);
	proc sort; by measure_Year ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE timeframe sumcat sumcat1;
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

		proc sort; by measure_Year EPI_ID_MILLIMAN STAY_ADMSN_DT;
		proc sort nodupkey; by measure_Year EPI_ID_MILLIMAN;
	run;

	proc sql;
		create table epi2_&label._&bpid1._&bpid2. as
		select a.*, coalesce(b.Mortality_CABG,'N/A') as Mortality_CABG
		from epi_&label._&bpid1._&bpid2. as a left join CABG_Mortality_&bpid1._&bpid2. as b
		on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
		and A.measure_year = B.measure_Year;
	quit;

	data out.epi_&label._&bpid1._&bpid2.;
		set epi2_&label._&bpid1._&bpid2.;
		if EPISODE_GROUP_NAME ^= 'Coronary artery bypass graft' then Mortality_CABG = '-';
	run;

****** QUALITY MEASURES *************************************************************************************;
%include "H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\402 - BPCIA THA-TKA Complications.sas";
%include "H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\403 - BPCIA All-Cause Unplanned Readmission.sas";
%include "H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\404 - Excess Days in Acute Care.sas";


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
	select MEASURE_YEAR, EPI_ID_MILLIMAN, sum(std_allowed) as std_allowed, max(IP_Prorate) as IP_Prorate, sum(std_allowed_calc) as std_allowed_calc
	from out.ip_&label._&bpid1._&bpid2.
	group by MEASURE_YEAR, EPI_ID_MILLIMAN;
quit;

proc sql;
	create table chk_&label._&bpid1._&bpid2. as
	select A.MEASURE_YEAR, a.ConvenerID, a.BPID, a.TOT_STD_ALLOWED, a.EPI_ID_MILLIMAN, a.ANCHOR_TYPE, a.EPISODE_GROUP_NAME, a.ANCHOR_CODE, a.Epi_Pre_data, a.Epi_Post_data, c.IP_Prorate,
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
				 and A.measure_year = B.measure_Year 
		left join t_ip as c
			on a.EPI_ID_MILLIMAN=c.EPI_ID_MILLIMAN
				and A.measure_year = C.measure_Year
		left join t_dme2 as d
			on a.EPI_ID_MILLIMAN=d.EPI_ID_MILLIMAN
			 and A.measure_year = D.measure_Year
		left join t_pb2 as e
			on a.EPI_ID_MILLIMAN=e.EPI_ID_MILLIMAN
			and A.measure_year = E.measure_Year
		left join t_snf as f
			on a.EPI_ID_MILLIMAN=f.EPI_ID_MILLIMAN
			and A.measure_year = F.measure_Year
		left join t_hs as g
			on a.EPI_ID_MILLIMAN=g.EPI_ID_MILLIMAN
			and A.measure_year = G.measure_Year
		left join t_hha as h
			on a.EPI_ID_MILLIMAN=h.EPI_ID_MILLIMAN
			 and A.measure_year = H.measure_Year ;
quit;

data out.chk_&label._&bpid1._&bpid2.;
	format measure_Year ConvenerID BPID EPI_ID_MILLIMAN ANCHOR_TYPE EPISODE_GROUP_NAME ANCHOR_CODE Epi_Pre_data Epi_Post_data IP_Prorate Milliman_CMS_Discrepancy TOT_STD_ALLOWED total_allowed total_diff;
	set chk_&label._&bpid1._&bpid2.;

	total_allowed = round(sum(op_allowed,ip_allowed,dme_allowed,pb_allowed,snf_allowed,hs_allowed,hha_allowed),.01);
	total_diff = round(round(TOT_STD_ALLOWED,.01) - total_allowed,.01);

	Milliman_CMS_Discrepancy='Yes';
	if total_diff<0.50 then Milliman_CMS_Discrepancy='No';
run;


proc sql;
	create table out.data1_&label._&bpid1._&bpid2. as
	select a.*, b.Milliman_CMS_Discrepancy, b.Epi_Pre_data, b.Epi_Post_data
	from data1_&label._&bpid1._&bpid2. as a left join out.chk_&label._&bpid1._&bpid2. as b
	on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
	AND a.measure_year = B.measure_Year;
quit;
 

****** Summary Output File *************************************************************************************;
%CLINEPI;


<<<<<<< Updated upstream
delete work datasets;
=======
/*delete work datasets;*/
>>>>>>> Stashed changes
proc datasets lib=work memtype=data kill;
run;
quit;

%mend;

/* Run Calls */
%runhosp(6051_0001,6051_0001,6051,0002,030112);
%runhosp(1209_0000,1209_0000,1209,0000,420004);
%runhosp(6055_0001,6055_0001,6055,0002,330194);
%runhosp(1191_0001,1191_0001,1191,0002,61440790);
%runhosp(2586_0001,2586_0001,2586,0002,360027);
%runhosp(2586_0001,2586_0001,2586,0005,360082);
%runhosp(2586_0001,2586_0001,2586,0006,360077);
%runhosp(2586_0001,2586_0001,2586,0007,360230);
%runhosp(2586_0001,2586_0001,2586,0010,360143);
%runhosp(2586_0001,2586_0001,2586,0013,360180);
%runhosp(2586_0001,2586_0001,2586,0025,360364);
%runhosp(2586_0001,2586_0001,2586,0026,100289);
%runhosp(2586_0001,2586_0001,2586,0028,360087);
%runhosp(2586_0001,2586_0001,2586,0029,360091);
%runhosp(2586_0001,2586_0001,2586,0030,360144);
%runhosp(2586_0001,2586_0001,2586,0031,360010);
%runhosp(2586_0001,2586_0001,2586,0032,100105);
%runhosp(2586_0001,2586_0001,2586,0033,100044);
%runhosp(2586_0001,2586_0001,2586,0034,650003177);
%runhosp(2586_0001,2586_0001,2586,0035,340714585);
*%runhosp(2586_0001,2586_0001,2586,0036,341855775);
*%runhosp(2586_0001,2586_0001,2586,0038,);
%runhosp(2586_0001,2586_0001,2586,0039,341843403);
*%runhosp(2586_0001,2586_0001,2586,0040,113837554);
*%runhosp(2586_0001,2586_0001,2586,0041,);
*%runhosp(2586_0001,2586_0001,2586,0042,800410599);
*%runhosp(2586_0001,2586_0001,2586,0043,);
%runhosp(2586_0001,2586_0001,2586,0044,650029298);
%runhosp(2586_0001,2586_0001,2586,0045,650556041);
%runhosp(2586_0001,2586_0001,2586,0046,264215547);
%runhosp(1374_0001,1374_0001,1374,0004,420078);
%runhosp(1374_0001,1374_0001,1374,0008,420018);
%runhosp(1374_0001,1374_0001,1374,0009,420086);
%runhosp(1374_0001,1374_0001,1374,0012,420038);
%runhosp(1374_0001,1374_0001,1374,0013,420033);
%runhosp(1374_0001,1374_0001,1374,0014,420037);
%runhosp(1374_0001,1374_0001,1374,0015,420009);
%runhosp(1374_0001,1374_0001,1374,0017,420015);
%runhosp(1374_0001,1374_0001,1374,0018,420106);
%runhosp(1191_0001,1191_0001,1191,0002,61440790);
%runhosp(7310_0001,7310_0001,7310,0002,070010);
%runhosp(7310_0001,7310_0001,7310,0003,070018);
%runhosp(7310_0001,7310_0001,7310,0004,070007);
%runhosp(7310_0001,7310_0001,7310,0005,410013);
%runhosp(7310_0001,7310_0001,7310,0006,070022);
%runhosp(7310_0001,7310_0001,7310,0007,070019);
%runhosp(7312_0001,7312_0001,7312,0002,521725543);
%runhosp(6054_0001,6054_0001,6054,0002,330019);
%runhosp(6055_0001,6055_0001,6055,0002,330194);
%runhosp(6056_0001,6056_0001,6056,0002,330201);
%runhosp(6057_0001,6057_0001,6057,0002,330221);
%runhosp(6058_0001,6058_0001,6058,0002,330233);
%runhosp(6059_0001,6059_0001,6059,0002,330397);
%runhosp(1209_0000,1209_0000,1209,0000,420004);
%runhosp(1028_0000,1028_0000,1028,0000,100008);
%runhosp(1075_0000,1075_0000,1075,0000,360133);
%runhosp(1102_0000,1102_0000,1102,0000,390001);
%runhosp(1103_0000,1103_0000,1103,0000,390004);
%runhosp(1104_0000,1104_0000,1104,0000,390048);
%runhosp(1105_0000,1105_0000,1105,0000,390006);
%runhosp(1106_0000,1106_0000,1106,0000,390270);
%runhosp(1148_0000,1148_0000,1148,0000,310008);
%runhosp(1167_0000,1167_0000,1167,0000,390173);
%runhosp(1343_0000,1343_0000,1343,0000,232856880);
%runhosp(1368_0000,1368_0000,1368,0000,390049);
%runhosp(1461_0000,1461_0000,1461,0000,100296);
%runhosp(1634_0000,1634_0000,1634,0000,310012);
%runhosp(1803_0000,1803_0000,1803,0000,070017);
%runhosp(1958_0000,1958_0000,1958,0000,390183);
%runhosp(2048_0000,2048_0000,2048,0000,360079);
%runhosp(2049_0000,2049_0000,2049,0000,360239);
%runhosp(2070_0000,2070_0000,2070,0000,100084);
%runhosp(2214_0000,2214_0000,2214,0000,100285);
%runhosp(2215_0000,2215_0000,2215,0000,100230);
%runhosp(2216_0000,2216_0000,2216,0000,100154);
%runhosp(2302_0000,2302_0000,2302,0000,110074);
%runhosp(2317_0000,2317_0000,2317,0000,390330);
%runhosp(2374_0000,2374_0000,2374,0000,390326);
%runhosp(2376_0000,2376_0000,2376,0000,390035);
%runhosp(2378_0000,2378_0000,2378,0000,390197);
%runhosp(2379_0000,2379_0000,2379,0000,310060);
%runhosp(2451_0000,2451_0000,2451,0000,340173);
%runhosp(2452_0000,2452_0000,2452,0000,340069);
%runhosp(2461_0000,2461_0000,2461,0000,100314);
%runhosp(2468_0000,2468_0000,2468,0000,190111);
%runhosp(2587_0000,2587_0000,2587,0000,310014);
%runhosp(2589_0000,2589_0000,2589,0000,360132);
%runhosp(2594_0000,2594_0000,2594,0000,070035);
%runhosp(2607_0000,2607_0000,2607,0000,223700669);
%runhosp(5037_0000,5037_0000,5037,0000,360360);
%runhosp(5038_0000,5038_0000,5038,0000,080007);
%runhosp(5043_0000,5043_0000,5043,0000,100002);
%runhosp(5050_0000,5050_0000,5050,0000,390194);
%runhosp(5154_0000,5154_0000,5154,0000,330005);
%runhosp(5215_0001,5215_0001,5215,0002,310044);
%runhosp(5215_0001,5215_0001,5215,0003,310092);
%runhosp(5229_0000,5229_0000,5229,0000,390009);
%runhosp(5263_0000,5263_0000,5263,0000,100281);
%runhosp(5264_0000,5264_0000,5264,0000,100038);
%runhosp(5282_0000,5282_0000,5282,0000,360155);
%runhosp(5392_0001,5392_0001,5392,0004,110184);
%runhosp(5394_0000,5394_0000,5394,0000,390267);
%runhosp(5395_0000,5395_0000,5395,0000,390050);
%runhosp(5397_0001,5397_0001,5397,0002,360137);
%runhosp(5397_0001,5397_0001,5397,0003,360359);
%runhosp(5397_0001,5397_0001,5397,0004,360041);
%runhosp(5397_0001,5397_0001,5397,0005,360145);
%runhosp(5397_0001,5397_0001,5397,0006,360192);
%runhosp(5397_0001,5397_0001,5397,0007,360075);
%runhosp(5397_0001,5397_0001,5397,0008,360078);
%runhosp(5397_0001,5397_0001,5397,0009,360002);
%runhosp(5397_0001,5397_0001,5397,0010,360123);
%runhosp(5478_0001,5478_0001,5478,0002,310015);
%runhosp(5479_0001,5479_0001,5479,0002,310051);
%runhosp(5480_0001,5480_0001,5480,0002,310017);
%runhosp(5481_0001,5481_0001,5481,0002,310028);
%runhosp(5746_0001,5746_0001,5746,0002,100007);
%runhosp(1686_0001,1686_0001,1686,0002,752661095);
%runhosp(1688_0001,1688_0001,1688,0002,310588183);
%runhosp(1696_0001,1696_0001,1696,0002,571141121);
%runhosp(1710_0001,1710_0001,1710,0002,560963485);
%runhosp(2941_0001,2941_0001,2941,0002,670067);
%runhosp(2956_0001,2956_0001,2956,0002,450853);
%runhosp(6049_0001,6049_0001,6049,0002,450880);
%runhosp(6050_0001,6050_0001,6050,0002,450874);
%runhosp(6051_0001,6051_0001,6051,0002,030112);
%runhosp(6052_0001,6052_0001,6052,0002,670076);
%runhosp(6053_0001,6053_0001,6053,0002,450883);
%runhosp(2974_0001,2974_0001,2974,0003,251716306);
%runhosp(2974_0001,2974_0001,2974,0007,232730785);
%runhosp(5916_0001,5916_0001,5916,0002,411861374);



%MACRO CLINOUT;
%if %substr(&label.,1,5) ^= ybase and &mode. ^= recon %then %do;
	%if &mode. ^= dev %then %do;
		data out.clinepi_&label.;
			set out.clinepi_&label_monthly.: 
				%if &quarterly = N %then %do;
			out.clinepi_&label_quarterly.:
			%end;
					%if &label_semi_annual. != &label_quarterly. %then %do;
			out.clinepi_&label_semi_annual.:
			%end;
			;
		run;

		proc export data= out.clinepi_&label.
		        outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\99 - Investigations\_Number of Episodes\Summary of Number of Episodes_&label._&sysdate..csv"
		        dbms=csv replace; 
		run;
	%end;
%end;
%mend;
%CLINOUT;



proc printto;run;


%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;

