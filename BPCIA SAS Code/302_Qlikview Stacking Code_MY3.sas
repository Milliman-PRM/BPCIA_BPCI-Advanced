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
%let label = ybase3; *Baseline/Performance data label;
*%let label = y201908;

%let mode=base; *Base=Baseline Interface, Main=Main Interface;

****** REFERENCE PROGRAMS ***********************************************************************************;
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";
%include "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code\000 - BPCIA_Interface_BPIDs.sas";

****** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;

%macro modesetup;
%if &mode.=main %then %do;
libname out "&dataDir.\07 - Processed Data";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\302 - Qlikview Stacking Code_&label._&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=base %then %do;
libname out "&dataDir.\07 - Processed Data\Baseline Interface";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\302 - Baseline Interface Qlikview Stacking Code_&label._&sysdate..log" print=print new;
run;
%end;
%else %if &mode.=dev %then %do;
libname out "&dataDir.\07 - Processed Data\Development";
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\302 - Dev Interface Qlikview Stacking Code_&label._&sysdate..log" print=print new;
run;
%end;
%mend modesetup;

%modesetup;

libname bench "R:\client work\CMS_PAC_Bundle_Processing\Benchmark Releases\v.201909\sasout";

****** EXPORT INFO *****************************************************************************************;
%let exportDir = R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline;

%macro stack_output(table);

	data out.all_&table. 
		 	out.all_&table._1 out.all_&table._pmr_exist out.all_&table._pmr_new
			out.all_&table._pmr out.all_&table._ccb out.all_&table._ccf out.all_&table._ghs out.all_&table._hal
			out.all_&table._hss out.all_&table._ics out.all_&table._musc out.all_&table._uspi out.all_&table._wsp;
		set out.&table._:;
		%if &table = ccn_enc %then %do;
			fac_counter = _N_;
		%end;
		%else %if &table = provider %then %do;
			prov_counter = _N_;
		%end;
		%else %if &table = bpid_member %then %do;
			proc sort nodupkey; by BPID_Member BPID BENE_SK;
		%end;

		output out.all_&table.;

		if BPID in (&MY3_lst.) then output out.all_&table._1;
		
		if BPID in (&PMR_3_EI_lst.) then do;
			output out.all_&table._pmr;
			if BPID in (&PMR_3_Exist_EI_lst.) then output out.all_&table._pmr_exist;
			else if BPID in (&PMR_3_New_EI_lst.) then output out.all_&table._pmr_new;
		end;
		else if BPID in (&CCB_3_EI_lst.) then output out.all_&table._ccb;
		else if BPID in (&CCF_3_EI_lst.) then output out.all_&table._ccf;
		else if BPID in (&GHS_3_EI_lst.) then output out.all_&table._ghs;
		else if BPID in (&HAL_3_EI_lst.) then output out.all_&table._hal;
		else if BPID in (&HSS_3_EI_lst.) then output out.all_&table._hss;
		else if BPID in (&ICS_3_EI_lst.) then output out.all_&table._ics;
		else if BPID in (&MUSC_3_EI_lst.) then output out.all_&table._musc;
		else if BPID in (&USPI_3_EI_lst.) then output out.all_&table._uspi;
		else if BPID in (&WSP_3_EI_lst.) then output out.all_&table._wsp;
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
/*
%sas_2_csv(out.all_epi_detail,epi_detail_all.csv);
%sas_2_csv(out.all_pjourney,pjourney_all.csv);
%sas_2_csv(out.all_pjourneyagg,pjourneyagg_all.csv);
%sas_2_csv(out.all_prov_detail,prov_detail_all.csv);
%sas_2_csv(out.all_util,utilization_all.csv);
%sas_2_csv(out.all_perf,performance_all.csv);
%sas_2_csv(out.all_phys_summ,phys_summary_all.csv);
%sas_2_csv(out.all_pat_detail,patient_detail_all.csv);
%sas_2_csv(out.all_comp,comp_all.csv);
%sas_2_csv(out.all_bpid_member,bpid_member_all.csv);
*/


%macro stacking_pre_other(exportDir,name);

*** PREMIER BENCHMARKS ******;
data benchmarks_pmr;
	set bench.benchmarks_bpcia_my3_pmr_18;
	where fracture = "N/A";
	pmr_fip_n=.; pmr_fip_freq=.; pmr_fip_avg_days=.; 
	pmr_snf_n=.; pmr_snf_freq=.; pmr_snf_avg_days=.; 
	pmr_irf_n=.; pmr_irf_freq=.; pmr_irf_avg_days=.; 
	pmr_hha_n=.; pmr_hha_freq=.; pmr_hha_avg_days=.; 
	pmr_anchor_n=.; 
	suppress_flag_fip_pmr=1; suppress_flag_snf_pmr=1; suppress_flag_irf_pmr=1; suppress_flag_hha_pmr=1;
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

data out.all_perf_&name.;
	set b1;
run;

******* EXPORT QVW_FILES *******;
%sas_2_csv(out.all_epi_detail_&name.,epi_detail.csv);
%sas_2_csv(out.all_pjourney_&name.,pjourney.csv);
%sas_2_csv(out.all_pjourneyagg_&name.,pjourneyagg.csv);
%sas_2_csv(out.all_prov_detail_&name.,prov_detail.csv);
%sas_2_csv(out.all_util_&name.,utilization.csv);
%sas_2_csv(out.all_perf_&name.,performance.csv);
%sas_2_csv(out.all_phys_summ_&name.,phys_summary.csv);
%sas_2_csv(out.all_pat_detail_&name.,patient_detail.csv);
%sas_2_csv(out.all_comp_&name.,comp.csv);
%sas_2_csv(out.all_bpid_member_&name.,bpid_member.csv);


%mend stacking_pre_other;


*** Dev RUN ***;
/*%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\Dev, 1);*/

*** CCB RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\CCB, CCB);

*** CCF RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\CCF, CCF);

*** GHS RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\GHS, GHS);

*** HALIFAX RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\Halifax, HAL);

*** HSS RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\HSS, HSS);

*** ICS RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\ICS, ICS);

*** MUSC RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\MUSC, MUSC);

*** USPI RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\USPI, USPI);

*** WELLSPAN RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\WellSpan, WSP);

*** PREMIER RUN ***;
%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\Premier, PMR);

/**** PREMIER EXISTING RUN ***;*/
/*%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\Premier_Existing, PMR_Exist);*/
/**/
/**** PREMIER NEW RUN ***;*/
/*%stacking_pre_other(R:\data\HIPAA\BPCIA_BPCI Advanced\80 - Qlikview\Outfiles\Baseline\Premier_New, PMR_New);*/



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
