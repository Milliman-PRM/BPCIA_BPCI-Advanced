******** Send Email when SAS is complete ********;
*Enabling the SMTP e-mail interface;
options emailsys = SMTP;
*Specifying a single SMTP server;
options emailhost = smtp.milliman.com;
* Add to and from email addresses;
%let to_email = sumudu.dehipawala@milliman.com;
%let from_email = sumudu.dehipawala@milliman.com;

%let _sdtm=%sysfunc(datetime());
options mprint nospool;
****************************************
****************************************
BPCI Advanced
BPCIA: 302_Qlikview Stacking Code
Code to stack the created tables for Qlik View interface
****************************************
****************************************;

******************************************************************************
RUN THIS PROGRAM IN ITS OWN SAS SESSION TO PREVENT ANY DATA ROLLUP ISSUES
******************************************************************************

********************
Setup 
********************;

****** USER INPUTS ******************************************************************************************;
/*%let label = ybase; *Baseline/Performance data label;*/
%let label = y201903;

%let mode=FULL; *DEV or FULL;


****** REFERENCE PROGRAMS ***********************************************************************************;
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";
%include "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code\000 - BPCIA_Interface_BPIDs.sas";

****** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;

%macro modesetup;
%if &mode.=DEV %then %do;
libname out "&dataDir.\07 - Processed Data\Testing";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\302 - DEV Qlikview Stacking Code_&label._&sysdate..log";
run;
%end;
%else %do;
libname out "&dataDir.\07 - Processed Data\Test";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\302 - Qlikview Stacking Code2_&label._&sysdate..log";
run;
%end;
%mend modesetup;

%modesetup;

libname bench "R:\client work\CMS_PAC_Bundle_Processing\Benchmark Releases\v.201811";

****** EXPORT INFO *****************************************************************************************;
/*%let exportDir = R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles;*/


* * * * * * * * * * * * * * ONLY RUN WHEN BASELINE AND PERFORMANCE ARE RUN * * * * * * * * * * * * * * ;
%macro stacking(exportDir);

*Stack Output files - Files with baseline and perf data use output, files with perf data only use the perf data;
%macro stack_output(file);

	data out.all_&file.;
		set out.&file._:;
		%if &file = ccn_enc %then %do;
			fac_counter = _N_;
		%end;
		%else %if &file = provider %then %do;
			prov_counter = _N_;
		%end;
	run;

%mend stack_output;


%stack_output(epi_detail);
%stack_output(pjourney);
%stack_output(pjourneyagg);
%stack_output(prov_detail);
%stack_output(util);
%stack_output(perf); 
%stack_output(phys_summ);
%stack_output(pat_detail);
%stack_output(exclusions);
%stack_output(comp);


*not for qlikview;
/*%stack_output(provider);*/
/*%stack_output(ccn_enc);*/

*FUTURE USE;
/*%stack_output(perf_base); *Baseline only;*/
/*%stack_output(tff_exclusions,output); *Excluded episodes;*/
/*%stack_output(claims_lag,&label.);*/
/*%stack_output(tp_variability,&label.); *20170831 Update: Add new target price variability;*/
/*%stack_output(tff_detail_output); *All episodes;*/

*** ADDING PREMIER BENCHMARKS *****;
data benchmarks_pmr;
	set bench.benchmarks_bpcia_pmr_17;
	where fracture = "N/A";
run;

proc sql;
	create table p1 as
	select a.*
		,b.*
	from out.all_perf as a
	left join benchmarks_pmr as b
	on a.Anchor_code = b.drg
	and timeframe_id = b._id 
	and client_type = 1
	order by epi_id_milliman, timeframe
;
quit;

data benchmarks_base;
	set out.baseline_final_benchmark;
run;

proc sql;
	create table b1 as
	select 	a.*,
			b.*
	from p1 as a
	left join benchmarks_base as b
	on a.Anchor_code = b.Anchor_code
	and a.timeframe = b.timeframe
	and a.BPID = b.BPID 
	order by epi_id_milliman, timeframe
;
quit;


data out.all_perf;
	set b1;
run;


/********** CALCULATE AND ADD PREMIER PERFORMANCE PAC BENCHMARKS ************;*/
/*proc sql;*/
/*	create table p1 as*/
/*	select	b.anchor_yearmo*/
/*		,	b.anchor_yearqtr*/
/*		,	b.anchor_year*/
/*		,	a.*	*/
/*	from out.all_perf as a left join out.all_epi_detail as b*/
/*	on a.epi_id_milliman = b.epi_id_Milliman*/
/*;*/
/*quit;*/
/**/
/*%macro timeview(time);*/
/**/
/*%if &time = All %then %do;*/
/*proc sql;*/
/*	create table p_&time. as*/
/*	select 	anchor_code*/
/*		,	timeframe*/
/*		,	sum(count) as PMR_anchor_n_&time.*/
/*		,	sum(IP_UTIL) as PMR_IP_UTIL_&time.*/
/*		,	sum(IP_DAYS) as PMR_IP_DAYS_&time.*/
/*		,	sum(IRF_UTIL) as PMR_IRF_UTIL_&time.*/
/*		,	sum(IRF_DAYS) as PMR_IRF_DAYS_&time.*/
/*		,	sum(SNF_UTIL) as PMR_SNF_UTIL_&time.*/
/*		,	sum(SNF_DAYS) as PMR_SNF_DAYS_&time.*/
/*		,	sum(HH_UTIL) as PMR_HH_UTIL_&time.*/
/*		,	client_type*/
/*	from p1*/
/*	where client_type = 1*/
/*	group by anchor_code*/
/*		,	timeframe*/
/*		,	client_type*/
/*%end;*/
/**/
/*%else %do;*/
/*proc sql;*/
/*	create table p_&time. as*/
/*	select 	anchor_&time.*/
/*		,	anchor_code*/
/*		,	timeframe*/
/*		,	sum(count) as PMR_anchor_n_&time.*/
/*		,	sum(IP_UTIL) as PMR_IP_UTIL_&time.*/
/*		,	sum(IP_DAYS) as PMR_IP_DAYS_&time.*/
/*		,	sum(IRF_UTIL) as PMR_IRF_UTIL_&time.*/
/*		,	sum(IRF_DAYS) as PMR_IRF_DAYS_&time.*/
/*		,	sum(SNF_UTIL) as PMR_SNF_UTIL_&time.*/
/*		,	sum(SNF_DAYS) as PMR_SNF_DAYS_&time.*/
/*		,	sum(HH_UTIL) as PMR_HH_UTIL_&time.*/
/*		,	client_type*/
/*	from p1*/
/*	where client_type = 1*/
/*	group by anchor_&time.*/
/*		,	anchor_code*/
/*		,	timeframe*/
/*		,	client_type*/
/*	*/
/*%end;*/
/*;*/
/*quit;*/
/**/
/*%mend timeview;*/
/**/
/*%timeview(YearMo);*/
/*%timeview(YearQtr);*/
/*%timeview(Year);*/
/*%timeview(All);*/
/**/
/*proc sql;*/
/*	create table out.all_perf as*/
/*	select 	a.**/
/*		,	b.**/
/*		,	c.**/
/*		,	d.**/
/*		,	e.**/
/*	from p1 as a*/
/*		left join p_yearmo as b*/
/*		on a.anchor_yearmo = b.anchor_yearmo and a.anchor_code = b.anchor_code and a.timeframe = b.timeframe and a.client_type = b.client_type*/
/*		left join p_yearqtr as c*/
/*		on a.anchor_yearqtr = c.anchor_yearqtr and a.anchor_code = c.anchor_code and a.timeframe = c.timeframe and a.client_type = c.client_type*/
/*		left join p_year as d*/
/*		on a.anchor_year = d.anchor_year and a.anchor_code = d.anchor_code and a.timeframe = d.timeframe and a.client_type = d.client_type*/
/*		left join p_all as e*/
/*		on a.anchor_code = e.anchor_code and a.timeframe = e.timeframe and a.client_type = e.client_type*/
/*		order by anchor_yearmo, anchor_yearqtr, anchor_year, anchor_code, epi_id_milliman, timeframe*/
/*;*/
/*quit;*/




%if &mode.^=DEV %then %do;
******** SEPARATE FILES INTO TWO SEPARATE INTERFACE OUTPUT FILES *************;
%macro separate(file);

	data out.all_&file._1 out.all_&file._2 check_&file.;
		set out.all_&file.;
		if BPID in (&PMR_EI_lst.,&NON_PMR_EI_lst.) then output out.all_&file._1;
		else if BPID in (&BASELINE_lst.) then output out.all_&file._2;
		else output check_&file.;
	run;

%mend separate;

%separate(epi_detail);
%separate(pjourney);
%separate(pjourneyagg);
%separate(prov_detail);
%separate(util);
%separate(perf); 
%separate(phys_summ);
%separate(exclusions);
%separate(pat_detail);
%separate(comp);


******* EXPORT QVW_FILES *******;
%macro exp(num);
%sas_2_csv(out.all_epi_detail_&num.,epi_detail_&num..csv);
%sas_2_csv(out.all_pjourney_&num.,pjourney_&num..csv);
%sas_2_csv(out.all_pjourneyagg_&num.,pjourneyagg_&num..csv);
%sas_2_csv(out.all_prov_detail_&num.,prov_detail_&num..csv);
%sas_2_csv(out.all_util_&num.,utilization_&num..csv);
%sas_2_csv(out.all_perf_&num.,performance_&num..csv);
%sas_2_csv(out.all_phys_summ_&num.,phys_summary_&num..csv);
%sas_2_csv(out.all_exclusions_&num.,exclusions_&num..csv);
%sas_2_csv(out.all_pat_detail_&num.,patient_detail_&num..csv);
%sas_2_csv(out.all_comp_&num.,comp_&num..csv);

%mend exp;

%exp(1);
/*%exp(2);*/

%end;
%else %do;
******* EXPORT QVW_FILES *******;
%sas_2_csv(out.all_epi_detail,epi_detail.csv);
%sas_2_csv(out.all_pjourney,pjourney.csv);
%sas_2_csv(out.all_pjourneyagg,pjourneyagg.csv);
%sas_2_csv(out.all_prov_detail,prov_detail.csv);
%sas_2_csv(out.all_util,utilization.csv);
%sas_2_csv(out.all_perf,performance.csv);
%sas_2_csv(out.all_phys_summ,phys_summary.csv);
%sas_2_csv(out.all_exclusions,exclusions.csv);
%sas_2_csv(out.all_pat_detail,patient_detail.csv);
%sas_2_csv(out.all_comp,comp.csv);

*not for qlikview;
/*%sas_2_csv(out.all_provider,provider.csv);*/
/*%sas_2_csv(out.all_ccn_enc,pac.csv);*/

*FUTURE USE;
/*%sas_2_csv(out.all_perf_base,performance_base.csv);*/
/*%sas_2_csv(out.all_tff_exclusions,exclu_timeframe_filter.csv);*/
/*%sas_2_csv(out.all_claims_lag,claims_lag.csv);*/
/*%sas_2_csv(out.all_tp_variability,tp_variability.csv);*/
/*%sas_2_csv(out.all_tff_detail_output,timeframe_filter.csv);*/
%end;

%mend stacking;


/********** 20170118 - CREATE FILES FOR DEMO ***************************************************************;*/
%macro stackingdemo(exportDir,bpid1,bpid2,bpid3,bpid4,bpid5,bpid6,bpid7,bpid8,bpid9,bpid10);

*Stack Output files - Files with baseline and perf data use output, files with perf data only use the perf data;
%macro stack_output_demo(file,file2);

	data out.all_&file._demo;
		set 
		%if &file = exclusions %then %do;
			out.&file._&file2._&bpid1._0000
			out.&file._&file2._&bpid2._0000
			out.&file._&file2._&bpid3._0000
			out.&file._&file2._&bpid4._0000
			out.&file._&file2._&bpid5._0000
			out.&file._&file2._&bpid6._0000
			out.&file._&file2._&bpid7._0000
/*			out.&file._&file2._&bpid8._0034*/
/*			out.&file._&file2._&bpid9._0064*/
			out.&file._&file2._&bpid10._0002
		;
		%end;
		%else %do;
			out.&file._ybase_&bpid1._0000
			out.&file._ybase_&bpid2._0000
			out.&file._ybase_&bpid3._0000
			out.&file._ybase_&bpid4._0000
			out.&file._ybase_&bpid5._0000
			out.&file._ybase_&bpid6._0000
			out.&file._ybase_&bpid7._0000
/*			out.&file._ybase_&bpid8._0034*/
/*			out.&file._ybase_&bpid9._0064*/
			out.&file._ybase_&bpid10._0002
			out.&file._&file2._&bpid1._0000
			out.&file._&file2._&bpid2._0000
			out.&file._&file2._&bpid3._0000
			out.&file._&file2._&bpid4._0000
			out.&file._&file2._&bpid5._0000
			out.&file._&file2._&bpid6._0000
			out.&file._&file2._&bpid7._0000
/*			out.&file._&file2._&bpid8._0034*/
/*			out.&file._&file2._&bpid9._0064*/
			out.&file._&file2._&bpid10._0002;
		%end;

		*20180610 Update - Overwrite BPID;
		if BPID ="&bpid1.-0000" then BPID = "1111-0000";
		else if BPID = "&bpid2.-0000" then BPID = "2222-0000";
		else if BPID = "&bpid3.-0000" then BPID = "3333-0000";
		else if BPID = "&bpid4.-0000" then BPID = "4444-0000";
		else if BPID = "&bpid5.-0000" then BPID = "5555-0000";
		else if BPID = "&bpid6.-0000" then BPID = "6666-0000";
		else if BPID = "&bpid7.-0000" then BPID = "7777-0000";
/*		else if BPID = "&bpid8.-0034" then BPID = "8888-0000";*/
/*		else if BPID = "&bpid9.-0064" then BPID = "9999-0000";*/
		else if BPID = "&bpid10.-0002" then BPID = "1010-0000";


	%if &file = epi_detail %then %do;

/*SM 20190506 Scrambling Update*/
		format ANCHOR_BEG_DT mmddy10. ;
		BENE_GENDER=gender2 ;	
/*SM 20190506 Scrambling Update*/


/*	    *20170821 Update: Mask identifiable variables;*/
/*		BENE_HIC_NUM = "123456789";*/
/*		anchor_med_rec_num = "123456789";*/
		BENE_SK = 123456789;
		MBI_ID="987654321";


/*SM 20190506 Scrambling Update*/
		if BENE_GENDER = 'Male' then gender2 = 'E' ;
		if BENE_GENDER = 'Female' then gender2 = 'L' ;
		if BENE_GENDER = '-' then gender2 = 'P' ;

		if  BPID = "1111-0000"  then do; Anchor_Fac_Code_Name = 'Facility 1 (BPID 1111)'; EI_system_name = "Health System 1"; EI_facility_abbr = 'Facility 1 (BPID 1111)' ; end;
		if  BPID = "2222-0000"  then do; Anchor_Fac_Code_Name = 'Facility 1 (BPID 2222)'; EI_system_name = "Health System 1"; EI_facility_abbr = 'Facility 1 (BPID 2222)' ; end;
		if  BPID = "3333-0000"  then do; Anchor_Fac_Code_Name = 'Facility 1 (BPID 3333)'; EI_system_name = "Health System 1"; EI_facility_abbr = 'Facility 1 (BPID 3333)' ; end;
		if  BPID = "4444-0000"  then do; Anchor_Fac_Code_Name = 'Facility 1 (BPID 4444)'; EI_system_name = "Health System 1"; EI_facility_abbr = 'Facility 1 (BPID 4444)' ; end;
		if  BPID = "5555-0000"  then do; Anchor_Fac_Code_Name = 'Facility 1 (BPID 5555)'; EI_system_name = "Health System 1"; EI_facility_abbr = 'Facility 1 (BPID 5555)' ; end;
		if  BPID = "6666-0000"  then do; Anchor_Fac_Code_Name = 'Facility 1 (BPID 6666)'; EI_system_name = "Health System 1"; EI_facility_abbr = 'Facility 1 (BPID 6666)' ; end;
		if  BPID = "7777-0000"  then do; Anchor_Fac_Code_Name = 'Facility 1 (BPID 7777)'; EI_system_name = "Health System 1"; EI_facility_abbr = 'Facility 1 (BPID 7777)' ; end;
		if  BPID = "8888-0000"  then do; Anchor_Fac_Code_Name = 'Facility 1 (BPID 8888)'; EI_system_name = "Health System 1"; EI_facility_abbr = 'Facility 1 (BPID 8888)' ; end;
		if  BPID = "9999-0000"  then do; Anchor_Fac_Code_Name = 'Facility 1 (BPID 9999)'; EI_system_name = "Health System 1"; EI_facility_abbr = 'Facility 1 (BPID 9999)' ; end;
		if  BPID = "1010-0000"  then do; Anchor_Fac_Code_Name = 'Facility 1 (BPID 1010)'; EI_system_name = "Health System 1"; EI_facility_abbr = 'Facility 1 (BPID 1010)' ; end;


		if BENE_GENDER="Female" then BENE_GENDER="F";
		else if BENE_GENDER="Male" then BENE_GENDER="M";

		BPID_ClinicalEp = strip(BPID)||" - "||strip(clinical_episode_abbr);
		BPID_ClinicalEp_ccn = strip(BPID)||" - "||strip(clinical_episode_abbr)||" - "||strip(anchor_ccn);
	%end;

/*Masking identifiable dates*/

	ANCHOR_BEG_DT=intnx('year',intnx('day', ANCHOR_BEG_DT, floor(ranuni(7)*60)),10,'sameday') ;
	Anchor_Year=put(year(ANCHOR_BEG_DT),4.) ;
	if month(ANCHOR_BEG_DT) < 10 then Anchor_YearMo=put(year(ANCHOR_BEG_DT), 4.)||'M0'||strip(month(ANCHOR_BEG_DT)) ;
	else Anchor_YearMo = put(year(ANCHOR_BEG_DT), 4.)||' M'||strip(month(ANCHOR_BEG_DT)) ;

	increment = ANCHOR_BEG_DT - ANCHOR_BEG_DT0 ;

	%macro date(date) ;

		format &date.0 mmddyy10. ;
		&date.0=&date. ;

	%of &date.=BENE_BIRTH_DT %then %do ;
	&date.=&date.0+(-3*increment) ;

	%end ;

	%else %do ;
		&date.=&date.0+increment ;
	%end ;

	%mend date ;

	%date (ANCHOR_END_DT) ;
	%date (BENE_DEATH_DT) ;
	%date (BENE_BIRTH_DT) ;
	%date (END_DATE) ;
	%date (BEGIN_DATE) ;
	%date (T0_IP_IDX_STARTDATE) ;
	%date (T0_IP_IDX_ENDDATE) ;

	%date (T1_IP_A_FAC_STARTDATE) ;
	%date (T12_IP_A_FAC_STARTDATE) ;
	%date (T2_IP_A_FAC_STARTDATE) ;
	%date (T3_IP_A_FAC_STARTDATE) ;
	%date (T4_IP_A_FAC_STARTDATE) ;

	%date (T1_IP_A_FAC_ENDDATE) ;
	%date (T12_IP_A_FAC_ENDDATE) ;
	%date (T2_IP_A_FAC_ENDDATE) ;
	%date (T3_IP_A_FAC_ENDDATE) ;
	%date (T4_IP_A_FAC_ENDDATE) ;

	%date (T1_HH_STARTDATE) ;
	%date (T12_HH_STARTDATE) ;
	%date (T2_HH_STARTDATE) ;
	%date (T3_HH_STARTDATE) ;
	%date (T4_HH_STARTDATE) ;

	%date (T1_HH_ENDDATE) ;
	%date (T12_HH_ENDDATE) ;
	%date (T2_HH_ENDDATE) ;
	%date (T3_HH_ENDDATE) ;
	%date (T4_HH_ENDDATE) ;

	%date (T1_IRF_STARTDATE) ;
	%date (T12_IRF_STARTDATE) ;
	%date (T2_IRF_STARTDATE) ;
	%date (T3_IRF_STARTDATE) ;
	%date (T4_IRF_STARTDATE) ;

	%date (T1_IRF_ENDDATE) ;
	%date (T12_IRF_ENDDATE) ;
	%date (T2_IRF_ENDDATE) ;
	%date (T3_IRF_ENDDATE) ;
	%date (T4_IRF_ENDDATE) ;

	%date (T1_LTAC_STARTDATE) ;
	%date (T12_LTAC_STARTDATE) ;
	%date (T2_LTAC_STARTDATE) ;
	%date (T3_LTAC_STARTDATE) ;
	%date (T4_LTAC_STARTDATE) ;

	%date (T1_LTAC_ENDDATE) ;
	%date (T12_LTAC_ENDDATE) ;
	%date (T2_LTAC_ENDDATE) ;
	%date (T3_LTAC_ENDDATE) ;
	%date (T4_LTAC_ENDDATE) ;

	%date (T1_IP_O_FAC_STARTDATE) ;
	%date (T12_IP_O_FAC_STARTDATE) ;
	%date (T2_IP_O_FAC_STARTDATE) ;
	%date (T3_IP_O_FAC_STARTDATE) ;
	%date (T4_IP_O_FAC_STARTDATE) ;

	%date (T1_IP_O_FAC_ENDDATE) ;
	%date (T12_IP_O_FAC_ENDDATE) ;
	%date (T2_IP_O_FAC_ENDDATE) ;
	%date (T3_IP_O_FAC_ENDDATE) ;
	%date (T4_IP_O_FAC_ENDDATE) ;

	%date (T1_SNF1_STARTDATE) ;
	%date (T12_SNF1_STARTDATE) ;
	%date (T2_SNF1_STARTDATE) ;
	%date (T3_SNF_STARTDATE) ;
	%date (T4_SNF_STARTDATE) ;

	%date (T1_SNF1_ENDDATE) ;
	%date (T12_SNF_ENDDATE) ;
	%date (T2_SNF1_ENDDATE) ;
	%date (T3_SNF1_ENDDATE) ;
	%date (T4_SNF_ENDDATE) ;

	%date (T1_SNF2_STARTDATE) ;
	%date (T2_SNF2_STARTDATE) ;
	%date (T3_SNF2_STARTDATE) ;
	%date (T1_SNF2_ENDDATE) ;
	%date (T2_SNF2_ENDDATE) ;
	%date (T3_SNF2_ENDDATE) ;

	%end date;

/*SM 20190506 Scrambling Update*/

	%if &file = pjourney %then %do;
		/*	*20170821 Update: Mask identifiable variables;*/
		array d_name(*) d_first_name d_second_name d_third_name d1-d90;

		do i = 1 to dim(d_name);
			if substr(d_name[i],1,2)="HH" then d_name[i] = "HH: Home Health Agency (123456)";
			else if substr(d_name[i],1,3)="SNF" then d_name[i] = "SNF: Skilled Nursing Facility (123456)";
			else if substr(d_name[i],1,3)="IRF" then d_name[i] = "IRF: Inpatient Rehab Facility (123456)";
			else if substr(d_name[i],1,4)="LTCH" then d_name[i] = "LTCH: Long Term Care Hospital (123456)";
			else if substr(d_name[i],1,14)="Anchor Readmit" then d_name[i] = "Anchor Readmit: Anchor Hospital (123456)";
			else if substr(d_name[i],1,13)="Other Readmit" then d_name[i] = "Other Readmit: Other Hospital (123456)";
			else if substr(d_name[i],1,7)="Hospice" then d_name[i] = "Hospice: Hospice Facility (123456)";
		end;

		array v_name(*) v1-v90;

		do i = 1 to dim(v_name);
			if substr(v_name[i],1,11)="Observation" then v_name[i] = "Observation: Provider (123456): MM/DD/YY ";
			else if substr(v_name[i],1,18)="Emergency Room - S" then v_name[i] = "Emergency Room - Stand Alone: Provider (123456): MM/DD/YY";
			else if substr(v_name[i],1,18)="Emergency Room - P" then v_name[i] = "Emergency Room - Preceding Admit: Provider (123456): MM/DD/YY";
			else if substr(v_name[i],1,9)="Operating" then v_name[i] = "Operating Physician Visit: Provider (123456): MM/DD/YY";
			else if substr(v_name[i],1,5)="Other" then v_name[i] = "Other Physician Visit: Provider (123456): MM/DD/YY";
			else if substr(v_name[i],1,7)="Therapy" then v_name[i] = "Therapy: Provider (123456): MM/DD/YY";
			else if substr(v_name[i],1,2)="HH" then v_name[i] = "HH: Provider (123456):";
		end;
	%end;

	%if &file = pjourneyagg %then %do;
		/*	*20170821 Update: mask names;*/
		if substr(d_name,1,2)="HH" then d_name = "HH: Home Health Agency (123456)";
			else if substr(d_name,1,3)="SNF" then d_name = "SNF: Skilled Nursing Facility (123456)";
			else if substr(d_name,1,3)="IRF" then d_name = "IRF: Inpatient Rehab Facility (123456)";
			else if substr(d_name,1,4)="LTCH" then d_name = "LTCH: Long Term Care Hospital (123456)";
			else if substr(d_name,1,14)="Anchor Readmit" then d_name = "Anchor Readmit: Anchor Hospital (123456)";
			else if substr(d_name,1,13)="Other Readmit" then d_name = "Other Readmit: Other Hospital (123456)";
			else if substr(d_name,1,7)="Hospice" then d_name = "Hospice: Hospice Facility (123456)";
	%end;

	%if &file = ccn_enc %then %do;
		/*	*20170821 Update: mask HIC number;*/
/*		readmit_med_rec_number = "123456789";*/
		fac_counter = _N_;
	%end;

	%if &file = exclusions %then %do;

/*SM 05072019 SCRAMBLING UPDATE*/
		format BENE_GENDER=gender2 ;
		format BENE_BIRTH_DT mmddyy10. ;
		BENE_BIRTH_DT=DOB ;
		DOB=intnx('year',intnx('day',BENE_BIRTH_DT,floor(ranuni(7)*60)),10,'sameday');
		increment=dob - BENE_BIRTH_DT ;

		%macro date(date);

			&date. = &date.0 + increment;

		%mend date;

		%date(BENE_BIRTH_DT);
		%date(BENE_DEATH_DT);
		%date(ANCHOR_BEG_DT);
		%date(ANCHOR_END_DT);
		%date(Anchor_Year);

/*SM 05072019 SCRAMBLING UPDATE*/

		/*	*20181226 Update: mask bene sk;*/
		BENE_SK = "123456789";
		MBI_ID="987654321";

/*SM 05072019 SCRAMBLING UPDATE*/
		if BENE_GENDER="Female" then BENE_GENDER="R";
		else if BENE_GENDER="Male" then BENE_GENDER="T";
/*SM 05072019 SCRAMBLING UPDATE*/

	%end;

	%if &file = patient_detail %then %do;

/*SM 05072019 SCRAMBLING UPDATE*/
		format end_date begin_date mmddyy10. ;
		end_date=end_date1 ;
		end_date1=intnx('year',intnx('day',end_date,floor(ranuni(7)*60)),10,'sameday');
		increment=end_date - end_date1 ;

		%macro date(date);

			&date. = &date.0 + increment;

		%mend date;

		%date(end_date);
		%date(begin_date);
		
	%end ;
/*SM 05072019 SCRAMBLING UPDATE*/

	%if &file = provider %then %do;
		prov_counter= _N_;
	%end;
/*SM 05072019 SCRAMBLING UPDATE*/
	%if &file=performance %then %do ;

		format complication_startdate complication_enddate mmddy10. ;
		complication_startdate1 = intnx('year',intnx('day', complication_startdate, floor(ranuni(7)*60)),10,'sameday') ;
		increment = complication_startdate1 - complication_startdate ;

 		%macro date(date) ;
			&date. = &date.0 = increment ;
		%mend date ;
		%date (complication_enddate1) ;

	% end ; 
/*SM 05072019 SCRAMBLING UPDATE*/
	run;



%mend stack_output_demo;

*&file2 will change to "output" once the performance data is available;
%stack_output_demo(epi_detail,&label.);
%stack_output_demo(pjourney,&label.);
%stack_output_demo(pjourneyagg,&label.);
%stack_output_demo(pat_detail,&label.);
%stack_output_demo(prov_detail,&label.);
%stack_output_demo(util,&label.);
%stack_output_demo(phys_summ,&label.);
%stack_output_demo(exclusions,&label.);
%stack_output_demo(comp,&label.);


*NOT FOR QLIKVIEW;
/*%stack_output_demo(provider,&label.);*/
/*%stack_output_demo(ccn_enc,&label.);*/

* FOR FUTURE USE;
/*%stack_output_demo(perf_base,&label.); *Baseline only;*/
/*%stack_output_demo(tff_epi_detail,&label.); *All episodes;*/
/*%stack_output_demo(tff_exclusions,&label.); *Excluded episodes;*/
*Always use the label as &file2;
/*%stack_output_demo(claims_lag,&label.);*/
/*%stack_output_demo(tp_variability,&label.); *20170831 Update: Add new target price variability*;*/


*performance file (needs to be rerun outside of macro to incorporate PMR benchmark variables;
data out.all_perf_demo;
	set out.all_perf;
	if BPID in ("&bpid1.-0000","&bpid2.-0000","&bpid3.-0000","&bpid4.-0000","&bpid5.-0000","&bpid6.-0000","&bpid7.-0000","&bpid10.-0002");

	*20180610 Update - Overwrite BPID;
	if BPID ="&bpid1.-0000" then BPID = "1111-0000";
	else if BPID = "&bpid2.-0000" then BPID = "2222-0000";
	else if BPID = "&bpid3.-0000" then BPID = "3333-0000";
	else if BPID = "&bpid4.-0000" then BPID = "4444-0000";
	else if BPID = "&bpid5.-0000" then BPID = "5555-0000";
	else if BPID = "&bpid6.-0000" then BPID = "6666-0000";
	else if BPID = "&bpid7.-0000" then BPID = "7777-0000";
/*	else if BPID = "&bpid8.-0034" then BPID = "8888-0000";*/
/*	else if BPID = "&bpid9.-0064" then BPID = "9999-0000";*/
	else if BPID = "&bpid10.-0002" then BPID = "1010-0000";
run;

******* EXPORT QVW_FILES *******;
%sas_2_csv(out.all_epi_detail_demo,epi_detail_demo.csv);
%sas_2_csv(out.all_pjourney_demo,pjourney_demo.csv);
%sas_2_csv(out.all_pjourneyagg_demo,pjourneyagg_demo.csv);
%sas_2_csv(out.all_pat_detail_demo,patient_detail_demo.csv);
%sas_2_csv(out.all_prov_detail_demo, prov_detail_demo.csv);
%sas_2_csv(out.all_util_demo,utilization_demo.csv);
%sas_2_csv(out.all_perf_demo,performance_demo.csv);
%sas_2_csv(out.all_phys_summ_demo,phys_summary_demo.csv);
%sas_2_csv(out.all_exclusions_demo,exclusions_demo.csv);
%sas_2_csv(out.all_comp_demo,comp_demo.csv);

*NOT FOR QLIKVIEW;
/*%sas_2_csv(out.all_provider_demo,provider_demo.csv);*/
/*%sas_2_csv(out.all_ccn_enc_demo,pac_demo.csv);*/

*FOR FUTURE USE;
/*%sas_2_csv(out.all_perf_base_demo,performance_base_demo.csv);*/
/*%sas_2_csv(out.all_tff_epi_detail_demo,timeframe_filter_demo.csv);*/
/*%sas_2_csv(out.all_tff_exclusions_demo,exclu_timeframe_filter_demo.csv);*/
/*%sas_2_csv(out.all_claims_lag_demo,claims_lag_demo.csv);*/
/*%sas_2_csv(out.all_tp_variability_demo,tp_variability_demo.csv);*/


%mend stackingdemo;


* * * * * * * * * * * * * * ONLY RUN WHEN SPILITTING PREMIER AND OTHER * * * * * * * * * * * * * * ;
%macro stacking_pre_other(exportDir,name);

*Stack Output files - Files with baseline and perf data use output, files with perf data only use the perf data;
%macro stack_output(file);

	data out.all_&file._&name.;
		set out.&file._:;
		%if &file = ccn_enc %then %do;
			fac_counter = _N_;
		%end;
		%else %if &file = provider %then %do;
			prov_counter = _N_;
		%end;

		%if &name = CCF %then %do;
		where BPID in (&BASELINE_lst.) ; 
		%end ;
		%else %if &name = MIL %then %do ;
		where BPID in (&NON_PMR_EI_lst.) ; 
		%end; 
		%else %if &name = PMR %then %do ;
		where BPID in (&PMR_EI_lst.) ; 
		%end; 

	run;

%mend stack_output;


%stack_output(epi_detail);
%stack_output(pjourney);
%stack_output(pjourneyagg);
%stack_output(prov_detail);
%stack_output(util);
%stack_output(perf); 
%stack_output(phys_summ);
%stack_output(pat_detail);
%stack_output(exclusions);
%stack_output(comp);


*not for qlikview;
/*%stack_output(provider);*/
/*%stack_output(ccn_enc);*/

*FUTURE USE;
/*%stack_output(perf_base); *Baseline only;*/
/*%stack_output(exclusions);*/
/*%stack_output(tff_exclusions,output); *Excluded episodes;*/
/*%stack_output(claims_lag,&label.);*/
/*%stack_output(tp_variability,&label.); *20170831 Update: Add new target price variability;*/
/*%stack_output(tff_detail_output); *All episodes;*/


*** PREMIER BENCHMARKS ******;
data benchmarks_pmr;
	set bench.benchmarks_bpcia_pmr_17;
	where fracture = "N/A";
run;

proc sql;
	create table p1 as
	select a.*
		,b.*
	from out.all_perf_&name. as a
	left join benchmarks_pmr as b
	on a.Anchor_code = b.drg
	and timeframe_id = b._id 
	and client_type = 1
	order by epi_id_milliman, timeframe
;
quit;
*** BASELINE BENCHMARKS ******;
data benchmarks_base;
	set out.baseline_final_benchmark;
run;

proc sql;
	create table b1 as
	select a.*
		,b.*
	from p1 as a
	left join benchmarks_base as b
	on  a.BPID=b.BPID
	and a.Anchor_code = b.Anchor_code
	and a.timeframe_id = b.timeframe_id 
	order by epi_id_milliman, timeframe
;
quit;


data out.all_perf_&name.;
	set b1;
run;

/********** CALCULATE AND ADD PREMIER PERFORMANCE PAC BENCHMARKS ************;*/
/*proc sql;*/
/*	create table p1 as*/
/*	select	b.anchor_yearmo*/
/*		,	b.anchor_yearqtr*/
/*		,	b.anchor_year*/
/*		,	a.*	*/
/*	from out.all_perf_&name. as a left join out.all_epi_detail_&name. as b*/
/*	on a.epi_id_milliman = b.epi_id_Milliman*/
/*;*/
/*quit;*/
/**/
/*%macro timeview(time);*/
/**/
/*%if &time = All %then %do;*/
/*proc sql;*/
/*	create table p_&time. as*/
/*	select 	anchor_code*/
/*		,	timeframe*/
/*		,	sum(count) as PMR_anchor_n_&time.*/
/*		,	sum(IP_UTIL) as PMR_IP_UTIL_&time.*/
/*		,	sum(IP_DAYS) as PMR_IP_DAYS_&time.*/
/*		,	sum(IRF_UTIL) as PMR_IRF_UTIL_&time.*/
/*		,	sum(IRF_DAYS) as PMR_IRF_DAYS_&time.*/
/*		,	sum(SNF_UTIL) as PMR_SNF_UTIL_&time.*/
/*		,	sum(SNF_DAYS) as PMR_SNF_DAYS_&time.*/
/*		,	sum(HH_UTIL) as PMR_HH_UTIL_&time.*/
/*		,	client_type*/
/*	from p1*/
/*	where client_type = 1*/
/*	group by anchor_code*/
/*		,	timeframe*/
/*		,	client_type*/
/*%end;*/
/**/
/*%else %do;*/
/*proc sql;*/
/*	create table p_&time. as*/
/*	select 	anchor_&time.*/
/*		,	anchor_code*/
/*		,	timeframe*/
/*		,	sum(count) as PMR_anchor_n_&time.*/
/*		,	sum(IP_UTIL) as PMR_IP_UTIL_&time.*/
/*		,	sum(IP_DAYS) as PMR_IP_DAYS_&time.*/
/*		,	sum(IRF_UTIL) as PMR_IRF_UTIL_&time.*/
/*		,	sum(IRF_DAYS) as PMR_IRF_DAYS_&time.*/
/*		,	sum(SNF_UTIL) as PMR_SNF_UTIL_&time.*/
/*		,	sum(SNF_DAYS) as PMR_SNF_DAYS_&time.*/
/*		,	sum(HH_UTIL) as PMR_HH_UTIL_&time.*/
/*		,	client_type*/
/*	from p1*/
/*	where client_type = 1*/
/*	group by anchor_&time.*/
/*		,	anchor_code*/
/*		,	timeframe*/
/*		,	client_type*/
/*	*/
/*%end;*/
/*;*/
/*quit;*/
/**/
/*%mend timeview;*/
/**/
/*%timeview(YearMo);*/
/*%timeview(YearQtr);*/
/*%timeview(Year);*/
/*%timeview(All);*/
/**/
/*proc sql;*/
/*	create table out.all_perf_&name. as*/
/*	select 	a.**/
/*		,	b.**/
/*		,	c.**/
/*		,	d.**/
/*		,	e.**/
/*	from p1 as a*/
/*		left join p_yearmo as b*/
/*		on a.anchor_yearmo = b.anchor_yearmo and a.anchor_code = b.anchor_code and a.timeframe = b.timeframe and a.client_type = b.client_type*/
/*		left join p_yearqtr as c*/
/*		on a.anchor_yearqtr = c.anchor_yearqtr and a.anchor_code = c.anchor_code and a.timeframe = c.timeframe and a.client_type = c.client_type*/
/*		left join p_year as d*/
/*		on a.anchor_year = d.anchor_year and a.anchor_code = d.anchor_code and a.timeframe = d.timeframe and a.client_type = d.client_type*/
/*		left join p_all as e*/
/*		on a.anchor_code = e.anchor_code and a.timeframe = e.timeframe and a.client_type = e.client_type*/
/*		order by anchor_yearmo, anchor_yearqtr, anchor_year, anchor_code, epi_id_milliman, timeframe*/
/*;*/
/*quit;*/


******* EXPORT QVW_FILES *******;
%sas_2_csv(out.all_epi_detail_&name.,epi_detail.csv);
%sas_2_csv(out.all_pjourney_&name.,pjourney.csv);
%sas_2_csv(out.all_pjourneyagg_&name.,pjourneyagg.csv);
%sas_2_csv(out.all_prov_detail_&name.,prov_detail.csv);
%sas_2_csv(out.all_util_&name.,utilization.csv);
%sas_2_csv(out.all_perf_&name.,performance.csv);
%sas_2_csv(out.all_phys_summ_&name.,phys_summary.csv);
%sas_2_csv(out.all_pat_detail_&name.,patient_detail.csv);
%sas_2_csv(out.all_exclusions_&name.,exclusions.csv);
%sas_2_csv(out.all_comp_&name.,comp.csv);

*not for qlikview;
/*%sas_2_csv(out.all_provider,provider.csv);*/
/*%sas_2_csv(out.all_ccn_enc,pac.csv);*/

*FUTURE USE;
/*%sas_2_csv(out.all_perf_base,performance_base.csv);*/
/*%sas_2_csv(out.all_exclusions,exclusions.csv);*/
/*%sas_2_csv(out.all_tff_exclusions,exclu_timeframe_filter.csv);*/
/*%sas_2_csv(out.all_claims_lag,claims_lag.csv);*/
/*%sas_2_csv(out.all_tp_variability,tp_variability.csv);*/
/*%sas_2_csv(out.all_tff_detail_output,timeframe_filter.csv);*/


%mend stacking_pre_other;

/*************;*/
/**/
*** FULL RUN ***;
/*%stacking(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles);*/

*** DEMO RUN ***;
%stackingdemo(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Test,1148,1167,1343,1368,2379,2587,2607,5084,5084,5479);

*** DEVELOPMENT RUN ***;
/*%stacking(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Development);*/

*** PREMIER RUN ***;
/*%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Premier, PMR);*/

*** MILLIMAN RUN ***;
/*%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Milliman, MIL);*/

*** CCF RUN ***;
/*%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\CCF, CCF);*/


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
