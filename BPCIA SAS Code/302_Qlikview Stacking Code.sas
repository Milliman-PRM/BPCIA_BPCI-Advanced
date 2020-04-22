/******** Send Email when SAS is complete ********;
*Enabling the SMTP e-mail interface;
options emailsys = SMTP;
*Specifying a single SMTP server;
options emailhost = smtp.milliman.com;
* Add to and from email addresses;
%let to_email = shachi.mistry@milliman.com;
%let from_email = shachi.mistry@milliman.com;
*/
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
%let label = y202003;

%let mode=main; *Base=Baseline Interface, Main=Main Interface;

****** REFERENCE PROGRAMS ***********************************************************************************;
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";
%include "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code\000 - BPCIA_Interface_BPIDs.sas";

****** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;

%macro modesetup;
%if &mode.=main %then %do;
libname out "&dataDir.\07 - Processed Data";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\302 - Qlikview Stacking Code_&label._&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=base %then %do;
libname out "&dataDir.\07 - Processed Data\Baseline Interface Demo";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\302 - Baseline Interface Qlikview Stacking Code_&label._&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=dev %then %do;
libname out "&dataDir.\07 - Processed Data\Development";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\302 - Dev Interface Qlikview Stacking Code_&label._&sysdate..log" print=print new;
run;
%end;
%mend modesetup;

%modesetup;

libname bench "R:\client work\CMS_PAC_Bundle_Processing\Benchmark Releases\v.201912\sasout";

****** EXPORT INFO *****************************************************************************************;
/*%let exportDir = R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles;*/

%macro stack_output(file);

	data out.all_&file.;
		set out.A_&file._ybase: out.&file._y20:;
		%if &file = ccn_enc %then %do;
			fac_counter = _N_;
		%end;
		%else %if &file = provider %then %do;
			prov_counter = _N_;
		%end;
		%else %if &file = epi_detail %then %do;
			format join_variable_recon $132.;
			join_variable_recon = strip(Measure_year)||"_"||strip(EPI_ID_Milliman);
			if primary_diag_with_desc1 = 'Not Available' then primary_diag_with_desc1 = '-';
			if primary_diag_with_desc1 = '' then primary_diag_with_desc1 = 'Not Available';
			if primary_proc_with_desc1 = '-' then primary_proc_with_desc1 = 'Not Available';
			if primary_proc_with_desc1 = '' then primary_proc_with_desc1 = '-';
			if flag_overlap = '' then flag_overlap = '-';
			if mult_attr_provs = '' then mult_attr_provs = '-';
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
%stack_output(comp);
%stack_output(bpid_member);

%macro stack_output_timefilter(file);

data out.all_&file.;

		set out.&file.:(keep=BPID EPI_ID_MILLIMAN timeframe_filter)  out.epi_detail_y20:(keep=BPID EPI_ID_MILLIMAN timeframe_filter);

	run;

%mend stack_output_timefilter;

%stack_output_timefilter(timeframe_filter);

%macro stack_output_e(file);

	data out.all_&file.;
		set out.&file._y20:;
	run;

%mend stack_output_e;
%stack_output_e(exclusions);


data benchmarks_pmr;
	set bench.benchmarks_bpcia_pmr_18;
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

*** ADDING BASELINE BENCHMARKS TO PERF FILE *****;

data benchmarks_base;
	set out.baseline_benchmark_:;
run;

proc sql;
	create table b1 as
	select 	a.*,
			b.*
	from p1 as a
	left join benchmarks_base as b
	on  a.BPID=b.BPID
	and a.Anchor_code = b.Anchor_code
	and a.timeframe_id = b.timeframe_id 
	order by epi_id_milliman, timeframe
;
quit;

data out.all_perf;
	set b1;
run;


/********** 20170118 - CREATE FILES FOR DEMO ***************************************************************;*/
%macro stackingdemo(exportDir,bpid1,bpid2,bpid3,bpid4,bpid5,bpid6,bpid7,bpid8);

*Stack Output files - Files with baseline and perf data use output, files with perf data only use the perf data;
%macro stack_output_demo(file,file2);

	data out.all_&file._demo;
		set 

		%if &mode.=base %then %do ;
			out.&file._ybase_&bpid1._0000
			out.&file._ybase_&bpid2._0000
			out.&file._ybase_&bpid3._0000
			out.&file._ybase_&bpid4._0000
			out.&file._ybase_&bpid5._0000
			out.&file._ybase_&bpid6._0000
			out.&file._ybase_&bpid7._0000
			out.&file._ybase_&bpid8._0002 ;
		%end ;

		%else %do ;
			%if &file = exclusions %then %do;
				out.&file._&file2._&bpid1._0000
				out.&file._&file2._&bpid2._0000
				out.&file._&file2._&bpid3._0000
				out.&file._&file2._&bpid4._0000
				out.&file._&file2._&bpid5._0000
				out.&file._&file2._&bpid6._0000
				out.&file._&file2._&bpid7._0000
				out.&file._&file2._&bpid8._0002
			;
			%end;
			%else %do ;
			%if &file = timeframe_filter %then %do;
				out.&file._&bpid1._0000 (keep=EPI_ID_MILLIMAN timeframe_filter)
				out.&file._&bpid2._0000 (keep=EPI_ID_MILLIMAN timeframe_filter)
				out.&file._&bpid3._0000 (keep=EPI_ID_MILLIMAN timeframe_filter)
				out.&file._&bpid4._0000 (keep=EPI_ID_MILLIMAN timeframe_filter)
				out.&file._&bpid5._0000 (keep=EPI_ID_MILLIMAN timeframe_filter)
				out.&file._&bpid6._0000 (keep=EPI_ID_MILLIMAN timeframe_filter)
				out.&file._&bpid7._0000 (keep=EPI_ID_MILLIMAN timeframe_filter)
				out.&file._&bpid8._0002 (keep=EPI_ID_MILLIMAN timeframe_filter)
				out.epi_detail_&file2._&bpid1._0000(keep=EPI_ID_MILLIMAN timeframe_filter)
				out.epi_detail_&file2._&bpid2._0000(keep=EPI_ID_MILLIMAN timeframe_filter)
				out.epi_detail_&file2._&bpid3._0000(keep=EPI_ID_MILLIMAN timeframe_filter)
				out.epi_detail_&file2._&bpid4._0000(keep=EPI_ID_MILLIMAN timeframe_filter)
				out.epi_detail_&file2._&bpid5._0000(keep=EPI_ID_MILLIMAN timeframe_filter)
				out.epi_detail_&file2._&bpid6._0000(keep=EPI_ID_MILLIMAN timeframe_filter)
				out.epi_detail_&file2._&bpid7._0000(keep=EPI_ID_MILLIMAN timeframe_filter)
				out.epi_detail_&file2._&bpid8._0002(keep=EPI_ID_MILLIMAN timeframe_filter)
	run;
	
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
				out.&file._ybase_&bpid8._0002
				out.&file._&file2._&bpid1._0000
				out.&file._&file2._&bpid2._0000
				out.&file._&file2._&bpid3._0000
				out.&file._&file2._&bpid4._0000
				out.&file._&file2._&bpid5._0000
				out.&file._&file2._&bpid6._0000
				out.&file._&file2._&bpid7._0000
				out.&file._&file2._&bpid8._0002;
			%end;
		%end ;

		*20180610 Update - Overwrite BPID;
		if BPID ="&bpid1.-0000" then BPID = "1111-0000";
		else if BPID = "&bpid2.-0000" then BPID = "2222-0000";
		else if BPID = "&bpid3.-0000" then BPID = "3333-0000";
		else if BPID = "&bpid4.-0000" then BPID = "4444-0000";
		else if BPID = "&bpid5.-0000" then BPID = "5555-0000";
		else if BPID = "&bpid6.-0000" then BPID = "6666-0000";
		else if BPID = "&bpid7.-0000" then BPID = "7777-0000";
		else if BPID = "&bpid8.-0002" then BPID = "8888-0000";

	%if &file = epi_detail %then %do;
		/*	*20170821 Update: Mask identifiable variables;*/
/*		BENE_HIC_NUM = "123456789";*/
/*		anchor_med_rec_num = "123456789";*/
		BENE_SK = 123456789;
		MBI_ID="987654321";

		if BENE_GENDER="Female" then BENE_GENDER="F";
		else if BENE_GENDER="Male" then BENE_GENDER="M";

		BPID_ClinicalEp = strip(BPID)||" - "||strip(clinical_episode_abbr);
		BPID_ClinicalEp_ccn = strip(BPID)||" - "||strip(clinical_episode_abbr)||" - "||strip(anchor_ccn);

		format join_variable_recon $132.;
		join_variable_recon = strip(Measure_year)||"_"||strip(EPI_ID_Milliman);

				format ANCHOR_BEG_DT0 mmddyy10. ; 
		ANCHOR_BEG_DT0 = ANCHOR_BEG_DT;

		/*	*20200304 Update: Mask identifiable dates;*/
	 	 ANCHOR_BEG_DT = intnx('year',intnx('day', ANCHOR_BEG_DT, floor(ranuni(7)*60)),10,'sameday');	
	  	Anchor_Year = put(year(ANCHOR_BEG_DT), 4.);
	   	Anchor_YearQtr = put(year(ANCHOR_BEG_DT), 4.)||' Q'||strip(qtr(ANCHOR_BEG_DT));
	  	if month(ANCHOR_BEG_DT) < 10 then Anchor_YearMo = put(year(ANCHOR_BEG_DT), 4.)||' M0'||strip(month(ANCHOR_BEG_DT));
	  	else Anchor_YearMo = put(year(ANCHOR_BEG_DT), 4.)||' M'||strip(month(ANCHOR_BEG_DT));

	  increment = ANCHOR_BEG_DT - ANCHOR_BEG_DT0;

  	%macro date(date);

		format &date.0  mmddyy10.;
		 &date.0 = &date. ;
	 %if &date. = BENE_DOB %then %do ;
	&date. = &date.0 + (-3*increment);
	%end;
	%else %do ;
		&date. = &date.0 + increment;
	%end ; 

	%mend date;

	%date(ANCHOR_END_DT);
	%date(DOD);
	%date(BENE_DOB);
	%date(epi_end_date);

	%date(T0_IP_IDX_STARTDATE);
%date(T0_IP_IDX_ENDDATE);
%date(T1_IP_A_FAC_STARTDATE);
%date(T1_IP_A_FAC_ENDDATE);
%date(T1_IP_O_FAC_STARTDATE);
%date(T1_IP_O_FAC_ENDDATE);
%date(T1_LTAC_STARTDATE);
%date(T1_LTAC_ENDDATE);
%date(T1_IRF_STARTDATE);
%date(T1_IRF_ENDDATE);
%date(T1_HH_STARTDATE);
%date(T1_HH_ENDDATE);
%date(T1_SNF1_STARTDATE);
%date(T1_SNF1_ENDDATE);
%date(T1_SNF2_STARTDATE);
%date(T1_SNF2_ENDDATE);
%date(T2_IP_A_FAC_STARTDATE);
%date(T2_IP_A_FAC_ENDDATE);
%date(T2_IP_O_FAC_STARTDATE);
%date(T2_IP_O_FAC_ENDDATE);
%date(T2_LTAC_STARTDATE);
%date(T2_LTAC_ENDDATE);
%date(T2_IRF_STARTDATE);
%date(T2_IRF_ENDDATE);
%date(T2_HH_STARTDATE);
%date(T2_HH_ENDDATE);
%date(T2_SNF1_STARTDATE);
%date(T2_SNF1_ENDDATE);
%date(T2_SNF2_STARTDATE);
%date(T2_SNF2_ENDDATE);
%date(T3_IP_A_FAC_STARTDATE);
%date(T3_IP_A_FAC_ENDDATE);
%date(T3_IP_O_FAC_STARTDATE);
%date(T3_IP_O_FAC_ENDDATE);
%date(T3_LTAC_STARTDATE);
%date(T3_LTAC_ENDDATE);
%date(T3_IRF_STARTDATE);
%date(T3_IRF_ENDDATE);
%date(T3_HH_STARTDATE);
%date(T3_HH_ENDDATE);
%date(T3_SNF1_STARTDATE);
%date(T3_SNF1_ENDDATE);
%date(T3_SNF2_STARTDATE);
%date(T3_SNF2_ENDDATE);
%date(T4_IP_A_FAC_STARTDATE);
%date(T4_IP_A_FAC_ENDDATE);
%date(T4_IP_O_FAC_STARTDATE);
%date(T4_IP_O_FAC_ENDDATE);
%date(T4_LTAC_STARTDATE);
%date(T4_LTAC_ENDDATE);
%date(T4_IRF_STARTDATE);
%date(T4_IRF_ENDDATE);
%date(T4_HH_STARTDATE);
%date(T4_HH_ENDDATE);
%date(T4_SNF_STARTDATE);
%date(T4_SNF_ENDDATE);
%date(T4_ER_S_STARTDATE);
%date(T4_ER_S_ENDDATE);
%date(T4_ER_R_STARTDATE);
%date(T4_ER_R_ENDDATE);
%date(T4_HOSPICE_STARTDATE);
%date(T4_HOSPICE_ENDDATE);
%date(T12_IP_A_FAC_STARTDATE);
%date(T12_IP_A_FAC_ENDDATE);
%date(T12_IP_O_FAC_STARTDATE);
%date(T12_IP_O_FAC_ENDDATE);
%date(T12_LTAC_STARTDATE);
%date(T12_LTAC_ENDDATE);
%date(T12_IRF_STARTDATE);
%date(T12_IRF_ENDDATE);
%date(T12_HH_STARTDATE);
%date(T12_HH_ENDDATE);
%date(T12_SNF_STARTDATE);
%date(T12_SNF_ENDDATE);


	%end;
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
			else if substr(v_name[i],1,13)="Emergency - W" then v_name[i] = "Emergency - W/in 1 Day of Admit: Provider (123456): MM/DD/YY";
			else if substr(v_name[i],1,18)="Emergency Room - P" then v_name[i] = "Emergency Room - Preceding Admit: Provider (123456): MM/DD/YY";
			else if substr(v_name[i],1,9)="Operating" then v_name[i] = "Operating Physician Visit: Provider (123456): MM/DD/YY";
			else if substr(v_name[i],1,5)="Other" then v_name[i] = "Other Physician Visit: Provider (123456): MM/DD/YY";
			else if substr(v_name[i],1,7)="Therapy" then v_name[i] = "Therapy: Provider (123456): MM/DD/YY";
			else if substr(v_name[i],1,2)="HH" then v_name[i] = "HH: Provider (123456): MM/DD/YY";
			else if substr(v_name[i],1,8)="Deceased" then v_name[i] = "Deceased: MM/DD/YY";
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


		/* 20200304 */
		format startdate0 enddate0  er_startdate0 mmddyy10. ;
		readmit_med_rec_number = "123456789";
		fac_counter = _N_;
		startdate0 = startdate ;
		enddate0 = enddate ;
		er_startdate0 = er_startdate ;
		startdate = intnx('year',intnx('day', startdate0, floor(ranuni(7)*60)),10,'sameday');	
		increment = startdate - startdate0;

	%macro date(date);
	 %if &date. = BENE_DOB %then %do ;
	&date. = &date.0 + (-3*increment);
	%end;
	%else %do ;
		&date. = &date.0 + increment;
	%end ; 

	%mend date;
	%date(enddate);
	%date(er_startdate);

	%end;
	%if &file = exclusions %then %do;

		/*	*20181226 Update: mask bene sk;*/
		BENE_SK = "123456789";
		MBI_ID="987654321";

		if BENE_GENDER="Female" then BENE_GENDER="F";
		else if BENE_GENDER="Male" then BENE_GENDER="M";

		format ANCHOR_BEG_DT0 mmddyy10. ; 
		ANCHOR_BEG_DT0 = ANCHOR_BEG_DT;

		/*	*20200304 Update: Mask identifiable dates;*/
	 	 ANCHOR_BEG_DT = intnx('year',intnx('day', ANCHOR_BEG_DT, floor(ranuni(7)*60)),10,'sameday');	
	  	Anchor_Year = put(year(ANCHOR_BEG_DT), 4.);
	   	Anchor_YearQtr = put(year(ANCHOR_BEG_DT), 4.)||' Q'||strip(qtr(ANCHOR_BEG_DT));
	  	if month(ANCHOR_BEG_DT) < 10 then Anchor_YearMo = put(year(ANCHOR_BEG_DT), 4.)||' M0'||strip(month(ANCHOR_BEG_DT));
	  	else Anchor_YearMo = put(year(ANCHOR_BEG_DT), 4.)||' M'||strip(month(ANCHOR_BEG_DT));

	  	increment = ANCHOR_BEG_DT - ANCHOR_BEG_DT0;

  	%macro date(date);
format &date.0  mmddyy10.;
		 &date.0 = &date. ;

		&date. = &date.0 + increment;

	%mend date;
	%date(ANCHOR_END_DT);

	%end;

	%end;
	/* %if &file = provider %then %do; */
	%if &file = prov_detail %then %do;
		prov_counter= _N_;

	/* 20200304 */
		format service_date0   mmddyy10. ;
		service_date0 = service_date ;
		service_date = intnx('year',intnx('day', service_date0, floor(ranuni(7)*60)),10,'sameday');	

	%end;
	%if &file = bpid_member %then %do;
		BENE_SK = 123456789;
		BPID_Member = BPID || "_" || BENE_SK;
	%end;

	/*** 20200302 ***/
		%if &file = pat_detail %then %do;

		format begin_date0 end_date0  mmddyy10. ;
		begin_date0 = begin_date ;
		end_date0 = end_date ;
		begin_date = intnx('year',intnx('day', begin_date0, floor(ranuni(7)*60)),10,'sameday');	
		increment = begin_date - begin_date0;

	%macro date(date);

		&date. = &date.0 + increment;

	%mend date;
	%date(end_date);

	%end; 

	/* %if &file = complications %then %do; */
	 %if &file = comp %then %do; 

			format complication_startdate0 complication_enddate0  mmddyy10. ;
			complication_startdate0 = complication_startdate ;
			complication_enddate0 = complication_enddate ;
			complication_startdate = intnx('year',intnx('day', complication_startdate0, floor(ranuni(7)*60)),10,'sameday');	
			increment = complication_startdate - complication_startdate0;

	%macro date(date);
		&date. = &date.0 + increment;
	%mend date;
	%date(complication_enddate);

	%end; 

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
%stack_output_demo(comp,&label.);
%stack_output_demo(bpid_member,&label.);
%stack_output_demo(timeframe_filter,&label.);

*ONLY RUN EXCLUSIONS FOR MAIN DEMOS, NOT BASELINE;
%if &mode.^=base %then %do ;
%stack_output_demo(exclusions,&label.);
%end ;

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

*performance file (needs to be rerun outside of macro to incorporate PMR and baseline benchmark variables;
%if &mode.=base %then %do ;
data perf_demo ;
	set		out.perf_ybase_&bpid1._0000
			out.perf_ybase_&bpid2._0000
			out.perf_ybase_&bpid3._0000
			out.perf_ybase_&bpid4._0000
			out.perf_ybase_&bpid5._0000
			out.perf_ybase_&bpid6._0000
			out.perf_ybase_&bpid7._0000
			out.perf_ybase_&bpid8._0002 ;
run ;
*** PREMIER BENCHMARKS ******;
data benchmarks_pmr;
	set bench.benchmarks_bpcia_pmr_18;
	where fracture = "N/A";
run;

proc sql;
	create table p1 as
	select a.*
		,b.*
	from perf_demo as a
	left join benchmarks_pmr as b
	on a.Anchor_code = b.drg
	and timeframe_id = b._id 
	and client_type = 1
	order by epi_id_milliman, timeframe
;
quit;
*** BASELINE BENCHMARKS ******;
data benchmarks_base;
	set out.baseline_benchmark_:;
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

data out.all_perf_demo;
	set b1;
run;
%end ;

%else %do ;
data out.all_perf_demo;
	set out.all_perf;
	if BPID in ("&bpid1.-0000","&bpid2.-0000","&bpid3.-0000","&bpid4.-0000","&bpid5.-0000","&bpid6.-0000","&bpid7.-0000","&bpid8.-0002");

	*20180610 Update - Overwrite BPID;
	if BPID ="&bpid1.-0000" then BPID = "1111-0000";
	else if BPID = "&bpid2.-0000" then BPID = "2222-0000";
	else if BPID = "&bpid3.-0000" then BPID = "3333-0000";
	else if BPID = "&bpid4.-0000" then BPID = "4444-0000";
	else if BPID = "&bpid5.-0000" then BPID = "5555-0000";
	else if BPID = "&bpid6.-0000" then BPID = "6666-0000";
	else if BPID = "&bpid7.-0000" then BPID = "7777-0000";
	else if BPID = "&bpid8.-0002" then BPID = "8888-0000";

run;
%end ;


******* EXPORT QVW_FILES *******;
%sas_2_csv(out.all_epi_detail_demo,epi_detail_demo.csv);
%sas_2_csv(out.all_pjourney_demo,pjourney_demo.csv);
%sas_2_csv(out.all_pjourneyagg_demo,pjourneyagg_demo.csv);
%sas_2_csv(out.all_pat_detail_demo,patient_detail_demo.csv);
%sas_2_csv(out.all_prov_detail_demo, prov_detail_demo.csv);
%sas_2_csv(out.all_util_demo,utilization_demo.csv);
%sas_2_csv(out.all_perf_demo,performance_demo.csv);
%sas_2_csv(out.all_phys_summ_demo,phys_summary_demo.csv);
%sas_2_csv(out.all_comp_demo,comp_demo.csv);
%sas_2_csv(out.all_bpid_member_demo,bpid_member_demo.csv);

*ONLY EXPORT FOR MAIN INTERFACE DEMO;
%if &mode.^=base %then %do ;
%sas_2_csv(out.all_exclusions_demo,exclusions_demo.csv);
%end ;

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
		set out.all_&file.;
		%if &name = CCF %then %do;
		where BPID in (&CCF_lst.) ; 
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
%stack_output(bpid_member);
%stack_output(timeframe_filter);


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
%sas_2_csv(out.all_bpid_member_&name.,bpid_member.csv);
%sas_2_csv(out.all_timeframe_filter_&name.,timeframe_filter.csv);

%mend stacking_pre_other;

/*************;*/
/**/
*** FULL RUN ***;
/*%stacking(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles);*/

*** DEVELOPMENT RUN ***;
/*%stacking(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Development);*/

*** PREMIER RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Premier, PMR);

*** MILLIMAN RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Milliman, MIL);

*** CCF RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\CCF, CCF);

*** DEMO RUN ***;
/*%stackingdemo(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles,1148,1167,1343,1368,2379,2587,2607,5479);*/

*** BASELINE DEMO RUN ***;
/*%stackingdemo(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline Demo,1148,1167,1343,1368,2379,2587,2607,5479);*/


;

%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;

proc printto;run;

%put It took &_runtm minutes to run the program;
/*
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
