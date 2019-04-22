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
/*** Code to create Performance Benchmarks table  ********************************************/
/*********************************************************************************************/

data baseline (keep=epi_id_milliman anchor_code FRACTURE_FLAG frac_flag_filter BPID);
	set out.epi_&label._&bpid1._&bpid2.;
		 if FRACTURE_FLAG=1 then frac_flag_filter = "Yes" ;
			else frac_flag_filter = "No" ;  /*MB Code to create a chracter fracture variable */
/*		where type = ('IP_Idx');*/

run;

data baseline0a;
	set baseline(in=a)
		baseline(in=b)
		baseline(in=c)
		baseline(in=d)
		baseline(in=e);

		Count = 1;

		if a then timeframe = 1;
		else if b then timeframe = 2;
		else if c then timeframe = 3;
		else if d then timeframe = 4;
		else if e then timeframe = 5;


run;

data baseline1 (keep = BPID epi_id_milliman anchor_code timeframe IP_UTIL IP_DAYS IRF_UTIL IRF_DAYS LTAC_UTIL LTAC_DAYS SNF_UTIL SNF_DAYS HH_UTIL);
	set out.ip_&label._&bpid1._&bpid2. (in=d keep = BPID epi_id_milliman anchor_code type stay_admsn_dt stay_dschrgdt timeframe POST_DSCH_BEG_DT POST_DSCH_END_DT anchor_end_dt util_day days1 rename=(stay_admsn_dt=admsn_dt stay_dschrgdt=dschrgdt))
		out.snf_&label._&bpid1._&bpid2. (in=e keep = BPID epi_id_milliman anchor_code type admsn_dt dschrgdt timeframe POST_DSCH_BEG_DT POST_DSCH_END_DT anchor_end_dt from_dt thru_dt util_day)
		out.hha_&label._&bpid1._&bpid2. (in=f keep = BPID epi_id_milliman anchor_code type timeframe POST_DSCH_END_DT anchor_end_dt util_day); 
	
			if type in ('IP_d','IP_s') then do;
					IP_UTIL = 1;
					if post_dsch_end_dt < dschrgdt then IP_DAYS = sum(post_dsch_end_dt - max(post_dsch_beg_dt,admsn_dt),1);
					else if admsn_dt = dschrgdt then IP_DAYS = 1;
					else IP_DAYS = dschrgdt - max(post_dsch_beg_dt,admsn_dt);
			end;
			else if type in ('IP_Rehab') then do;
					IRF_UTIL = 1;
					if post_dsch_end_dt < dschrgdt then IRF_DAYS = sum(post_dsch_end_dt - max(post_dsch_beg_dt,admsn_dt),1);
					else if admsn_dt = dschrgdt then IRF_DAYS = 1;
					else IRF_DAYS = dschrgdt - max(post_dsch_beg_dt,admsn_dt);
			end;
			else if type in ('IP_LTAC') then do;
					LTAC_UTIL = 1;
					if post_dsch_end_dt < dschrgdt then LTAC_DAYS = sum(post_dsch_end_dt - max(post_dsch_beg_dt,admsn_dt),1);
					else if admsn_dt = dschrgdt then LTAC_DAYS = 1;
					else LTAC_DAYS = dschrgdt - max(post_dsch_beg_dt,admsn_dt);
			end;
			else if type in ('SNF') then do;
					SNF_UTIL = 1;
					SNF_DAYS =min(post_dsch_end_dt,dschrgdt)-max(post_dsch_beg_dt,admsn_dt)+1; 
/*					if post_dsch_end_dt < dschrgdt then SNF_DAYS = sum(post_dsch_end_dt - max(post_dsch_beg_dt,admsn_dt),1);*/
/*					else if admsn_dt = dschrgdt then SNF_DAYS = 1;*/
/*					else SNF_DAYS = dschrgdt - max(post_dsch_beg_dt,admsn_dt) ;*/
			end;
			else if type in ('HH') then do;
					HH_UTIL = 1;
			end;
run;

proc sql;
	create table baseline_UTIL as
		select epi_id_milliman, anchor_code,timeframe, BPID
			,case when sum(IP_UTIL) > 0 then 1 else 0 end as IP_UTIL
			,case when sum(IRF_UTIL) > 0 then 1 else 0 end as IRF_UTIL
			,case when sum(LTAC_UTIL) > 0 then 1 else 0 end as LTAC_UTIL
			,case when sum(SNF_UTIL) > 0 then 1 else 0 end as SNF_UTIL
			,case when sum(HH_UTIL) > 0 then 1 else 0 end as HH_UTIL

			,sum(IP_DAYS) as IP_DAYS
			,sum(IRF_DAYS) as IRF_DAYS
			,sum(LTAC_DAYS) as LTAC_DAYS
			,sum(SNF_DAYS) as SNF_DAYS



		from baseline1
		where timeframe ^=0
		group by epi_id_milliman, anchor_code,timeframe, BPID
		;
quit;

proc sql;
	create table baseline_UTIL2 as
		select epi_id_milliman, anchor_code, BPID
			,case when sum(IP_UTIL) > 0 then 1 else 0 end as IP_UTIL
			,case when sum(IRF_UTIL) > 0 then 1 else 0 end as IRF_UTIL
			,case when sum(LTAC_UTIL) > 0 then 1 else 0 end as LTAC_UTIL
			,case when sum(SNF_UTIL) > 0 then 1 else 0 end as SNF_UTIL
			,case when sum(HH_UTIL) > 0 then 1 else 0 end as HH_UTIL

			,sum(IP_DAYS) as IP_DAYS
			,sum(IRF_DAYS) as IRF_DAYS
			,sum(LTAC_DAYS) as LTAC_DAYS
			,sum(SNF_DAYS) as SNF_DAYS



		from baseline1
		where timeframe ^=0
		group by epi_id_milliman, anchor_code, BPID
		;
quit;

proc sql;
	create table baseline_UTIL3 as
		select epi_id_milliman, anchor_code, BPID
			,case when sum(IP_UTIL) > 0 then 1 else 0 end as IP_UTIL
			,case when sum(IRF_UTIL) > 0 then 1 else 0 end as IRF_UTIL
			,case when sum(LTAC_UTIL) > 0 then 1 else 0 end as LTAC_UTIL
			,case when sum(SNF_UTIL) > 0 then 1 else 0 end as SNF_UTIL
			,case when sum(HH_UTIL) > 0 then 1 else 0 end as HH_UTIL

			,sum(IP_DAYS) as IP_DAYS
			,sum(IRF_DAYS) as IRF_DAYS
			,sum(LTAC_DAYS) as LTAC_DAYS
			,sum(SNF_DAYS) as SNF_DAYS



		from baseline1
		where timeframe in (1,2)
		group by epi_id_milliman, anchor_code, BPID
		;
quit;

data baseline_util4;
	set baseline_util (in=a)
		baseline_util2 (in=b)
		baseline_util3 (in=c);

		if b then timeframe = 4;
		else if c then timeframe = 5;

run;

proc sql;
	create table baseline_util5 as
		select a.*
			,case when IP_UTIL = . then 0 else IP_UTIL end as IP_UTIL_base
			,case when IRF_UTIL = . then 0 else IRF_UTIL end as IRF_UTIL_base 
			,case when LTAC_UTIL = . then 0 else LTAC_UTIL end as LTAC_UTIL_base
			,case when SNF_UTIL = . then 0 else SNF_UTIL end as SNF_UTIL_base
			,case when HH_UTIL = . then 0 else HH_UTIL end as HH_UTIL_base
			,case when IP_DAYS = . then 0 else IP_DAYS end as IP_DAYS_base 
			,case when IRF_DAYS = . then 0 else IRF_DAYS end as IRF_DAYS_base
			,case when LTAC_DAYS = . then 0 else LTAC_DAYS end as LTAC_DAYS_base
			,case when SNF_DAYS = . then 0 else SNF_DAYS end as SNF_DAYS_base 
			,case when a.timeframe = 1 then '1 - 30 Days'
			when a.timeframe = 2 then '31 - 60 Days'
			when a.timeframe = 3 then '61 - 90 Days'
			when a.timeframe = 4 then '1 - 90 Days'
			when a.timeframe = 5 then '1 - 60 Days'
				end as timeframe2
			,case when a.timeframe = 1 then '0_30'
			when a.timeframe = 2 then '31_60'
			when a.timeframe = 3 then '61_90'
			when a.timeframe = 4 then '0_90'
			when a.timeframe = 5 then '0_60'
				end as timeframe_id
		from baseline0a as a
		left join baseline_util4 as b
		on a.epi_id_milliman = b.epi_id_milliman
		and a.timeframe = b.timeframe
		;
quit; 
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
		from	baseline_util5 as a
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
				FRACTURE_FLAG,
				frac_flag_filter,
				timeframe,
				timeframe2,
				timeframe_id,
				count(*) as epi_total,
				sum(IP_UTIL_base) as base_fip_n,
				sum(IRF_UTIL_base) as base_irf_n,
				sum(SNF_UTIL_base) as base_snf_n,
				sum(HH_UTIL_base) as base_hh_n,
				sum(IP_DAYS_base) as base_ip_days,
				sum(IRF_DAYS_base) as base_irf_days,
				sum(SNF_DAYS_base) as base_snf_days,
				sum(DOD_N_base) as base_dod_n
		from baseline_util6 as a
		group by BPID,
				anchor_code,
				FRACTURE_FLAG,
				frac_flag_filter,
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
				FRACTURE_FLAG,
				frac_flag_filter,
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
