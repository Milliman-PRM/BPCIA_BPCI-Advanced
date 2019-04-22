******** Send Email when SAS is complete ********;
*Enabling the SMTP e-mail interface;
options emailsys = SMTP;
*Specifying a single SMTP server;
options emailhost = smtp.milliman.com;
* Add to and from email addresses;
%let to_email = sumudu.dehipawala@milliman.com;
%let from_email = sumudu.dehipawala@milliman.com;

%let _sdtm=%sysfunc(datetime());
options minoperator mprint nospool;

%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";

libname out "R:\data\HIPAA\BPCIA_BPCI Advanced\07 - Processed Data\";
libname bench "R:\client work\CMS_PAC_Bundle_Processing\Benchmark Releases\v.201811";


%let label=ybase;
/*%let bpid1=1125;*/
/*%let bpid2=0000;*/
%macro baseline(bpid1,bpid2);


/*********************************************************************************************/
/*** Code to create Baseline Benchmarks table  ********************************************/
/*********************************************************************************************/


/*SD ADDITION START 20190304 - Mortality rates DURING episode*/

proc sql;
	create table epi_DOD_base as
	select	distinct
			epi_id_milliman
		,	bene_death_dt
		,	case when bene_death_dt=. then 0 
			  	 when bene_death_dt <= (ANCHOR_END_DT + 29) then 1
				 else 0
			end as DOD_1
		,	case when bene_death_dt=. then 0 
			  	 when (ANCHOR_END_DT + 30) <= bene_death_dt <= (ANCHOR_END_DT + 59) then 1
				 else 0
			end as DOD_2
		,	case when bene_death_dt=. then 0 
			  	 when (ANCHOR_END_DT + 60) <= bene_death_dt <= (ANCHOR_END_DT + 89) then 1
				 else 0
			end as DOD_3
		,	case when bene_death_dt=. then 0 
			  	 when bene_death_dt <= (ANCHOR_END_DT + 89) then 1
				 else 0
			end as DOD_4
		,	case when bene_death_dt=. then 0 
			  	 when bene_death_dt <= (ANCHOR_END_DT + 59) then 1
				 else 0
			end as DOD_5
	from	out.epi_detail_&label._&bpid1._&bpid2.
;
quit;

proc sql;
	create table baseline_util6 as 
		select	distinct
				a.*
			,	case when a.timeframe=1 then b.DOD_1
					 when a.timeframe=2 then b.DOD_2
					 when a.timeframe=3 then b.DOD_3
					 when a.timeframe=4 then b.DOD_4
					 when a.timeframe=5 then b.DOD_5
				else 0
				end as DOD_N_base
		from	out.perf_&label._&bpid1._&bpid2. as a
				left join
				epi_DOD_base as b
				on	a.epi_id_milliman = b.epi_id_milliman
		;
quit;

proc sql;
	create table baseline_util7  as 
		select distinct 	
 				BPID,
				anchor_code,
				timeframe,
				timeframe2,
				timeframe_id,
				count(*) as epi_total,
				sum(IP_UTIL) as base_fip_n,
				sum(IRF_UTIL) as base_irf_n,
				sum(SNF_UTIL) as base_snf_n,
				sum(HH_UTIL) as base_hh_n,
				sum(IP_DAYS) as base_ip_days,
				sum(IRF_DAYS) as base_irf_days,
				sum(SNF_DAYS) as base_snf_days,
				sum(DOD_N_base) as base_dod_n
		from baseline_util6 as a
		group by BPID,
				anchor_code,
				timeframe,
				timeframe2,
				timeframe_id
;
quit;

proc sql;
	create table out.baseline_benchmark_&bpid1._&bpid2.  as 
		select distinct 	
				*,
				base_fip_n/epi_total as base_fip_freq,
				base_irf_n/epi_total as base_irf_freq,
				base_snf_n/epi_total as base_snf_freq,
				base_hh_n/epi_total as base_hh_freq,
				base_dod_n/epi_total as base_dod_freq,
				base_ip_days/epi_total as base_fip_avg_days,
				base_irf_days/epi_total as base_irf_avg_days,
				base_snf_days/epi_total as base_snf_avg_days
		from baseline_util7 as a
		order by BPID,
				anchor_code,
				timeframe,
				timeframe2,
				timeframe_id
;
quit;

*MACRO RUNS;

%mend baseline;

%Baseline(1125,0000);
%Baseline(1148,0000);
%Baseline(1167,0000);
%Baseline(1209,0000);
%Baseline(1343,0000);
%Baseline(1368,0000);
%Baseline(1374,0004);
%Baseline(1374,0008);
%Baseline(1374,0009);
%Baseline(1686,0002);
%Baseline(1688,0002);
%Baseline(1696,0002);
%Baseline(1710,0002);
%Baseline(1958,0000);
%Baseline(2070,0000);
%Baseline(2374,0000);
%Baseline(2376,0000);
%Baseline(2378,0000);
%Baseline(2379,0000);
%Baseline(1075,0000);
%Baseline(2594,0000);
%Baseline(2048,0000);
%Baseline(2049,0000);
%Baseline(2607,0000);
%Baseline(5038,0000);
%Baseline(5050,0000);
%Baseline(5084,0034);
%Baseline(5084,0042);
%Baseline(5084,0064);
%Baseline(2587,0000);
%Baseline(2589,0000);
%Baseline(5154,0000);
%Baseline(5282,0000);
%Baseline(2631,0000);
%Baseline(5037,0000);
%Baseline(5478,0002);
%Baseline(5043,0000);
%Baseline(5479,0002);
%Baseline(5480,0002);
%Baseline(5215,0003);
%Baseline(5215,0002);
%Baseline(5229,0000);
%Baseline(5263,0000);
%Baseline(5264,0000);
%Baseline(5481,0002);
%Baseline(5394,0000);
%Baseline(5395,0000);
%Baseline(5397,0002);
%Baseline(5397,0005);
%Baseline(5397,0004);
%Baseline(5397,0008);
%Baseline(5397,0003);
%Baseline(5397,0006);
%Baseline(5397,0009);
%Baseline(5397,0010);
%Baseline(5916,0002);
%Baseline(6049,0002);
%Baseline(6050,0002);
%Baseline(6051,0002);
%Baseline(6052,0002);
%Baseline(6053,0002);
%Baseline(5397,0007);
%Baseline(1102,0000);
%Baseline(1105,0000);
%Baseline(1106,0000);
%Baseline(1103,0000);
%Baseline(1104,0000);
%Baseline(5392,0004);
%Baseline(6054,0002);
%Baseline(6055,0002);
%Baseline(6056,0002);
%Baseline(6057,0002);
%Baseline(6058,0002);
%Baseline(6059,0002);
%Baseline(5746,0002);

;

data out.baseline_final_benchmark;
	set out.baseline_benchmark:;
run;

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
