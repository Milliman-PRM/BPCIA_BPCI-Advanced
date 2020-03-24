
%let _sdtm=%sysfunc(datetime());
options mprint nospool;
**********************************************************;
**************** CHECKING SET UP *************************;
**********************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
libname in "&dataDir.\06 - Imported Raw Data";
*FULL;
libname out "&dataDir.\07 - Processed Data";
*DEV;
/*libname out "&dataDir.\07 - Processed Data\Development";*/

libname out2 "R:\data\HIPAA\BPCIA_BPCI Advanced\07 - Processed Data\Past files for checking\20200129";
libname check "R:\data\HIPAA\BPCIA_BPCI Advanced\07 - Processed Data\Past files for checking\20200226";


%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";
%let exportDir = R:\data\HIPAA\BPCIA_BPCI Advanced\90 - Sasout;

proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\999 - checks_&sysdate..log";
run;
**********************************************************;
**********************************************************;

* 1 COST CHECK - Patient Detail matches Episode Detail and data3 file;
data y;
	set out.data3_:;
run;

proc sql;
	create table y2 as
		select epi_id_milliman
		,sum (std_allowed_wage) as data3_sum
		from y
	group by epi_id_milliman
;
quit;

%macro one(num);
proc sql;
	create table check1a_&num. as
	select bpid,epi_id_milliman
		,sum(std_allowed_wage) as std_allowed_sum
	from out.all_pat_detail_&num.
	group by bpid,epi_id_milliman
;
	create table check1b_&num. as
	select a.bpid
		,a.epi_id_milliman
		,round(a.t4_total_allowed,0.01) as epi_sum
		,round(b.std_allowed_sum,0.01) as pd_sum
		,round(a.t4_total_allowed,0.01) - round(b.std_allowed_sum,0.01) as diff
		,round(c.data3_sum,0.01) as data3_sum
		,round(a.t4_total_allowed,0.01) - round(c.data3_sum,0.01) as data3_diff
	from out.all_epi_detail_&num. as a
	left join check1a_&num. as b
	on a.epi_id_milliman = b.epi_id_milliman
	left join y2 as c
	on a.epi_id_milliman = c.epi_id_milliman
;
quit;

data check.checkoutput1_&num.;
	set check1b_&num.;
	where diff ne 0 or data3_diff ne 0;
run;

%mend one;

/*proc sql;*/
/*	select distinct bpid from checkoutput1;quit;*/

* 2 EPISODE COUNT CHECK - episode counts match up everywhere;

proc sql;
	select count(*) as count_1 from out.all_epi_detail_1;
	select count(*) as count_2 from out.all_epi_detail_2;
quit;

%macro two(num);

%macro epi_check(file);
proc sql;
	create table check2a_&file._&num. as
	select bpid
		,count(distinct epi_id_milliman) as epi_count
	from out.all_&file._&num.
	group by bpid
;
quit;
%mend epi_check;

%epi_check(epi_detail);
%epi_check(pat_detail); *patient detail;
%epi_check(perf);
%epi_check(pjourney);
%epi_check(pjourneyagg);

proc sql;
	create table check2b_&num. as 
	select a.*
		,b.epi_count as pd_epi_count
		,c.epi_count as perf_epi_count
		,d.epi_count as pjourney_epi_count
		,e.epi_count as pjourneyagg_epi_count
	from check2a_epi_detail_&num. as a
		left join check2a_pat_detail_&num. as b
		on a.bpid = b.bpid
		left join check2a_perf_&num. as c
		on a.bpid = c.bpid
		left join check2a_pjourney_&num. as d
		on a.bpid = d.bpid
		left join check2a_pjourneyagg_&num. as e
		on a.bpid = e.bpid
;
quit;

data checkoutput2_&num.;
	set check2b_&num.;
	where epi_count ne pd_epi_count ne perf_epi_count ne pjourney_epi_count ne pjourneyagg_epi_count;
run;

%mend two;



*3 Compare old vs. new utilization and costs;
%macro three(num);

*compare old vs new epi_detail;
proc sql;
	create table check3a_&num. as
	select a.bpid
		,a.epi_id_milliman
		,a.ip_util
		,a.ip_days
		,a.irf_util
		,a.irf_days
		,a.snf_util
		,a.snf_days
		,b.ip_util as ip_util_new
		,b.ip_days as ip_days_new
		,b.irf_util as irf_util_new
		,b.irf_days as irf_days_new
		,b.snf_util as snf_util_new
		,b.snf_days as snf_days_new
		,b.ip_util - a.ip_util as ip_util_diff
		,b.ip_days - a.ip_days as ip_days_diff
		,b.irf_util - a.irf_util as irf_util_diff
		,b.irf_days - a.irf_days as irf_days_diff
		,b.snf_util - a.snf_util as snf_util_diff
		,b.snf_days - a.snf_days as snf_days_diff
		,a.t4_total_allowed
		,b.t4_total_allowed as t4_total_allowed_old
		,round(a.t4_total_allowed - b.t4_total_allowed,0.01) as t4_tot_diff
		,sum(min(a.t4_ip_a_fac_allowed,0),min(a.t4_ip_o_fac_allowed,0)) as t4_ip_allowed
		,sum(min(b.t4_ip_a_fac_allowed,0),min(b.t4_ip_o_fac_allowed,0)) as t4_ip_allowed_old
		,sum(min(a.t4_ip_a_fac_allowed,0),min(a.t4_ip_o_fac_allowed,0))-sum(min(b.t4_ip_a_fac_allowed,0),min(b.t4_ip_o_fac_allowed,0)) as t4_ip_diff
		,a.t0_ip_idx_allowed
		,b.t0_ip_idx_allowed as t0_ip_old
		,a.t0_ip_idx_allowed - b.t0_ip_idx_allowed as t0_ip_diff
		,a.t0_total_allowed
		,b.t0_total_allowed as t0_total_allowed_old
		,a.t0_total_allowed - b.t0_total_allowed as t0_total_diff
		,a.t1_total_allowed
		,b.t1_total_allowed as t1_total_allowed_old
		,a.t1_total_allowed - b.t1_total_allowed as t1_total_diff
		,a.t2_total_allowed
		,b.t2_total_allowed as t2_total_allowed_old
		,a.t2_total_allowed - b.t2_total_allowed as t2_total_diff
		,a.t3_total_allowed
		,b.t3_total_allowed as t3_total_allowed_old
		,a.t3_total_allowed - b.t3_total_allowed as t3_total_diff
	from out.all_epi_detail_&num. as a
	inner join out2.all_epi_detail_&num. as b
	on a.epi_id_milliman = b.epi_id_milliman
;
quit;

proc sql;
	create table check3b_&num. as
	select bpid
		,sum(t4_tot_diff) as diff
	from check3a_&num.
	group by bpid
;
quit;

data check.checkoutput3_&num.;
	set check3a_&num.;
	if t4_tot_diff ne 0 then t4_tot_flag = 1; else t4_tot_flag = 0;
	if t4_ip_diff ne 0 then t4_ip_flag = 1; else t4_ip_flag = 0;
	if t4_tot_flag ne t4_ip_flag then output;
run;

/**compare old vs. new episode counts;*/
/*proc sql;*/
/*	create table check3c_&num. as*/
/*	select bpid*/
/*		,count(epi_id_milliman) as epi_count*/
/*	from out.all_epi_detail_&num.*/
/*	group by bpid*/
/*;*/
/*	create table check3d_&num. as*/
/*	select bpid*/
/*		,count(epi_id_milliman) as epi_count*/
/*	from out2.all_epi_detail_&num.*/
/*	group by bpid*/
/*;*/
/*	create table check3e_&num. as*/
/*	select a.**/
/*		,b.epi_count as epi_count_old*/
/*	from check3c_&num. as a*/
/*	left join check3d_&num. as b*/
/*	on a.bpid=b.bpid*/
/*;*/
/*quit;*/
/**/
/*data checkoutput3_1_&num.;*/
/*	set check3e_&num.;*/
/*	where epi_count ne epi_count_old;*/
/*run;*/
/**/
/**compare old vs. new HH visits;*/
/*proc sql;*/
/*	create table check3f_&num. as*/
/*	select bpid*/
/*		,sum(util_day) as hh_sum*/
/*	from out.all_pat_detail_&num.*/
/*	where caretype = "Home Health"*/
/*	group by bpid*/
/*;*/
/*	create table check3g_&num. as*/
/*	select bpid*/
/*		,sum(util_day) as hh_sum*/
/*	from out2.all_pat_detail_&num.*/
/*	where caretype = "Home Health"*/
/*	group by bpid*/
/*;*/
/*	create table check3h_&num. as*/
/*	select a.**/
/*		,b.hh_sum as hh_sum_old*/
/*		,b.hh_sum - a.hh_sum as hh_diff*/
/*	from check3f_&num. as a*/
/*	left join check3g_&num. as b*/
/*	on a.bpid=b.bpid*/
/*;*/
/*quit;*/
/**/
/**compare old vs new non-HH visits;*/
/*proc sql;*/
/*	create table check3i_&num. as*/
/*	select bpid*/
/*		,sum(util_day) as los_sum*/
/*	from out.all_pat_detail_&num.*/
/*	where caretype ^= "Home Health"*/
/*	group by bpid*/
/*;*/
/*	create table check3j_&num. as*/
/*	select bpid*/
/*		,sum(util_day) as los_sum*/
/*	from out2.all_pat_detail_&num.*/
/*	where caretype ^= "Home Health"*/
/*	group by bpid*/
/*;*/
/*	create table check3k_&num. as*/
/*	select a.**/
/*		,b.los_sum as los_sum_old*/
/*		,b.los_sum - a.los_sum as los_diff*/
/*	from check3i_&num. as a*/
/*	left join check3j_&num. as b*/
/*	on a.bpid=b.bpid*/
/*;*/
/*quit;*/
/**/
/*data checkoutput3_2_&num.;*/
/*	set check3k_&num.;*/
/*	where los_diff ^= 0;*/
/*run;*/

%mend three;


/*%sas_2_csv(check3h_1,hh_1.csv);*/
/*%sas_2_csv(check3h_2,hh_2.csv);*/


* 4 Check LOS distribution of SNF and IP;

%macro four;
proc freq data = out.all_epi_detail noprint;
where snf_util = 1;
table snf_days/out=test4b;run;

proc freq data = out.all_epi_detail noprint;
where ip_util = 1;
table ip_days/out=test4d;run;

* Check LOS change in SNF;
proc sql;
	create table test4d as
	select a.bpid
		,a.epi_id_milliman
		,a.snf_days
		,b.snf_days as days_old
	from out.all_epi_detail as a
	inner join out2.all_epi_detail as b
	on a.epi_id_milliman = b.epi_id_milliman
	where a.snf_util = 1
;
quit;

data test4e;
	set test4d;
	where snf_days ne days_old;
	diff = snf_days - days_old;
run;

proc freq data = test4e;
table diff;run;

%mend four;

*5 - output baseline and performance episode counts by BPID;
%macro five;

proc sql;
	create table bpids as
	select distinct bpid,episode_initiator_use
	from out.all_epi_detail
;
	create table bpid_base as
	select distinct bpid
		,count(*) as epi_count
	from out.all_epi_detail
	where period = "BASE"
	group by bpid
;
	create table bpid_perf as
	select distinct bpid
		,count(*) as epi_count
	from out.all_epi_detail_1
	where period = "PERF"
	group by bpid
;
	create table checkoutput5 as
	select distinct a.bpid,a.episode_initiator_use
		,b.epi_count as epi_count_base
		,c.epi_count as epi_count_perf
	from bpids as a
	left join bpid_base as b
	on a.bpid=b.bpid
	left join bpid_perf as c
	on a.bpid=c.bpid
;
quit;

%mend five;

*6 - Check that Episode Index numbers are unique;
%macro six;

data epi_idx_check;
	set out.epi_idx_y201901_:;
run;

proc sql;
	create table epi_idx_check2 as
	select bpid
		,epi_id_milliman
		,episode_index
		,count(*) as count
	from epi_check
	group by bpid, epi_id_milliman, episode_index
;
quit;

data checkoutput6;
	set epi_idx_check2;
	where count > 1;
run;

%mend six;

*7 - check if BPID is ever missing;

%macro seven(file);
data test_&file.;
	set out.all_&file.;
	where bpid = "";
run;
%mend seven;


*8 - check number of episodes for each clinical episode type by BPID;
%macro eight(num);

proc sql;
	create table check8_&num. as
	select BPID
		,clinical_episode_abbr
		,count(*) as epi_count
	from out.all_epi_detail_&num.
	group by BPID,clinical_episode_abbr
;

*number of unique clinical episodes by BPID;

	create table checkoutput8_&num. as
	select BPID
		,count(*) as clinical_ep_count
	from check8_&num.
	group by BPID
	order by clinical_ep_count desc, BPID
;
quit;

%mend eight;


*9 - Compare Premier benchmarks;

%macro nine; 
data test2;
	set out.all_perf_1 (keep = anchor_yearmo anchor_yearqtr anchor_year anchor_code timeframe2 PMR_: client_type);
	where client_type = 1;
run;

proc sql;
	create table test2a as
	select distinct *
	from test2
	order by anchor_code, timeframe2
;quit;

data test3;
	set out2.all_perf_1 (keep = anchor_yearmo anchor_yearqtr anchor_year anchor_code timeframe2 PMR_: client_type);
	where client_type = 1;
run;

proc sql;
	create table test3a as
	select distinct *
	from test3
	order by anchor_code, timeframe2
;quit;

*all;
proc sql;
	create table test4 as
	select distinct  a.anchor_code
		,a.timeframe2
		,a.PMR_anchor_n_all
		,a.PMR_IP_UTIL_all
		,a.PMR_IP_DAYS_all
		,a.PMR_IRF_UTIL_all
		,a.PMR_IRF_DAYS_all
		,a.PMR_SNF_UTIL_all
		,a.PMR_SNF_DAYS_all
		,a.PMR_HH_UTIL_all
		,b.PMR_anchor_n_all as PMR_anchor_n_all_old
		,b.PMR_IP_UTIL_all as PMR_IP_UTIL_all_old
		,b.PMR_IP_DAYS_all as PMR_IP_DAYS_all_old
		,b.PMR_IRF_UTIL_all as PMR_IRF_UTIL_all_old
		,b.PMR_IRF_DAYS_all as PMR_IRF_DAYS_all_old
		,b.PMR_SNF_UTIL_all as PMR_SNF_UTIL_all_old
		,b.PMR_SNF_DAYS_all as PMR_SNF_DAYS_all_old
		,b.PMR_HH_UTIL_all as PMR_HH_UTIL_all_old
		,a.PMR_anchor_n_all - b.PMR_anchor_n_all as PMR_anchor_n_all_diff
		,a.PMR_IP_UTIL_all - b.PMR_IP_UTIL_all as PMR_IP_UTIL_all_diff
		,a.PMR_IP_DAYS_all - b.PMR_IP_DAYS_all as PMR_IP_DAYS_all_diff
		,a.PMR_IRF_UTIL_all - b.PMR_IRF_UTIL_all as PMR_IRF_UTIL_all_diff
		,a.PMR_IRF_DAYS_all - b.PMR_IRF_DAYS_all as PMR_IRF_DAYS_all_diff
		,a.PMR_SNF_UTIL_all - b.PMR_SNF_UTIL_all as PMR_SNF_UTIL_all_diff
		,a.PMR_SNF_DAYS_all - b.PMR_SNF_DAYS_all as PMR_SNF_DAYS_all_diff
		,a.PMR_HH_UTIL_all - b.PMR_HH_UTIL_all as PMR_HH_UTIL_all_diff
		,a.PMR_IP_UTIL_all/a.PMR_anchor_n_all as ip_util
		,a.PMR_IP_DAYS_all/a.PMR_anchor_n_all as ip_days
		,a.PMR_IRF_UTIL_all/a.PMR_anchor_n_all as irf_util
		,a.PMR_IRF_DAYS_all/a.PMR_anchor_n_all as irf_days
		,a.PMR_SNF_UTIL_all/a.PMR_anchor_n_all as snf_util
		,a.PMR_SNF_DAYS_all/a.PMR_anchor_n_all as snf_days
		,a.PMR_HH_UTIL_all/a.PMR_anchor_n_all as hh_util
		,b.PMR_IP_UTIL_all/b.PMR_anchor_n_all as ip_util_old
		,b.PMR_IP_DAYS_all/b.PMR_anchor_n_all as ip_days_old
		,b.PMR_IRF_UTIL_all/b.PMR_anchor_n_all as irf_util_old
		,b.PMR_IRF_DAYS_all/b.PMR_anchor_n_all as irf_days_old
		,b.PMR_SNF_UTIL_all/b.PMR_anchor_n_all as snf_util_old
		,b.PMR_SNF_DAYS_all/b.PMR_anchor_n_all as snf_days_old
		,b.PMR_HH_UTIL_all/b.PMR_anchor_n_all as hh_util_old
		,calculated ip_util - calculated ip_util_old as ip_util_diff
		,calculated ip_days - calculated ip_days_old as ip_days_diff
		,calculated irf_util - calculated irf_util_old as irf_util_diff
		,calculated irf_days - calculated irf_days_old as irf_days_diff
		,calculated snf_util - calculated snf_util_old as snf_util_diff
		,calculated snf_days - calculated snf_days_old as snf_days_diff
		,calculated hh_util - calculated hh_util_old as hh_util_diff
	from test2a as a
	left join test3a as b
	on a.anchor_code = b.anchor_code and a.timeframe2 = b.timeframe2
;quit;

%sas_2_csv(test4,pmr_all.csv);

*month;
proc sql;
	create table test4_yearmo as
	select distinct  a.anchor_yearmo
		,a.anchor_code
		,a.timeframe2
		,a.PMR_anchor_n_yearmo
		,a.PMR_IP_UTIL_yearmo
		,a.PMR_IP_DAYS_yearmo
		,a.PMR_IRF_UTIL_yearmo
		,a.PMR_IRF_DAYS_yearmo
		,a.PMR_SNF_UTIL_yearmo
		,a.PMR_SNF_DAYS_yearmo
		,a.PMR_HH_UTIL_yearmo
		,b.PMR_anchor_n_yearmo as PMR_anchor_n_yearmo_old
		,b.PMR_IP_UTIL_yearmo as PMR_IP_UTIL_yearmo_old
		,b.PMR_IP_DAYS_yearmo as PMR_IP_DAYS_yearmo_old
		,b.PMR_IRF_UTIL_yearmo as PMR_IRF_UTIL_yearmo_old
		,b.PMR_IRF_DAYS_yearmo as PMR_IRF_DAYS_yearmo_old
		,b.PMR_SNF_UTIL_yearmo as PMR_SNF_UTIL_yearmo_old
		,b.PMR_SNF_DAYS_yearmo as PMR_SNF_DAYS_yearmo_old
		,b.PMR_HH_UTIL_yearmo as PMR_HH_UTIL_yearmo_old
		,a.PMR_anchor_n_yearmo - b.PMR_anchor_n_yearmo as PMR_anchor_n_yearmo_diff
		,a.PMR_IP_UTIL_yearmo - b.PMR_IP_UTIL_yearmo as PMR_IP_UTIL_yearmo_diff
		,a.PMR_IP_DAYS_yearmo - b.PMR_IP_DAYS_yearmo as PMR_IP_DAYS_yearmo_diff
		,a.PMR_IRF_UTIL_yearmo - b.PMR_IRF_UTIL_yearmo as PMR_IRF_UTIL_yearmo_diff
		,a.PMR_IRF_DAYS_yearmo - b.PMR_IRF_DAYS_yearmo as PMR_IRF_DAYS_yearmo_diff
		,a.PMR_SNF_UTIL_yearmo - b.PMR_SNF_UTIL_yearmo as PMR_SNF_UTIL_yearmo_diff
		,a.PMR_SNF_DAYS_yearmo - b.PMR_SNF_DAYS_yearmo as PMR_SNF_DAYS_yearmo_diff
		,a.PMR_HH_UTIL_yearmo - b.PMR_HH_UTIL_yearmo as PMR_HH_UTIL_yearmo_diff
		,a.PMR_IP_UTIL_yearmo/a.PMR_anchor_n_yearmo as ip_util
		,a.PMR_IP_DAYS_yearmo/a.PMR_anchor_n_yearmo as ip_days
		,a.PMR_IRF_UTIL_yearmo/a.PMR_anchor_n_yearmo as irf_util
		,a.PMR_IRF_DAYS_yearmo/a.PMR_anchor_n_yearmo as irf_days
		,a.PMR_SNF_UTIL_yearmo/a.PMR_anchor_n_yearmo as snf_util
		,a.PMR_SNF_DAYS_yearmo/a.PMR_anchor_n_yearmo as snf_days
		,a.PMR_HH_UTIL_yearmo/a.PMR_anchor_n_yearmo as hh_util
		,b.PMR_IP_UTIL_yearmo/b.PMR_anchor_n_yearmo as ip_util_old
		,b.PMR_IP_DAYS_yearmo/b.PMR_anchor_n_yearmo as ip_days_old
		,b.PMR_IRF_UTIL_yearmo/b.PMR_anchor_n_yearmo as irf_util_old
		,b.PMR_IRF_DAYS_yearmo/b.PMR_anchor_n_yearmo as irf_days_old
		,b.PMR_SNF_UTIL_yearmo/b.PMR_anchor_n_yearmo as snf_util_old
		,b.PMR_SNF_DAYS_yearmo/b.PMR_anchor_n_yearmo as snf_days_old
		,b.PMR_HH_UTIL_yearmo/b.PMR_anchor_n_yearmo as hh_util_old
		,calculated ip_util - calculated ip_util_old as ip_util_diff
		,calculated ip_days - calculated ip_days_old as ip_days_diff
		,calculated irf_util - calculated irf_util_old as irf_util_diff
		,calculated irf_days - calculated irf_days_old as irf_days_diff
		,calculated snf_util - calculated snf_util_old as snf_util_diff
		,calculated snf_days - calculated snf_days_old as snf_days_diff
		,calculated hh_util - calculated hh_util_old as hh_util_diff
	from test2a as a
	left join test3a as b
	on a.anchor_yearmo = b.anchor_yearmo and a.anchor_code = b.anchor_code and a.timeframe2 = b.timeframe2
;quit;

%sas_2_csv(test4_yearmo,pmr_yearmo.csv);

%mend nine;

*10 - Correct wage adjustement of claims files matches episode cost from raw epi file where expected (some cost discrepancies are known);
%macro ten(num);

data all_ip;
set out.ip_:;
run;

data all_op;
set out.op_:;
run;

proc sql;
	create table ip_wf as
	select distinct episode_ID, epi_id_milliman, wage_index, tot_std_allowed
	from all_ip
;
quit;
proc sql;
	create table op_wf as
	select distinct episode_ID, epi_id_milliman, wage_index, tot_std_allowed
	from all_op
;
quit;

data ip_op_wf;
set ip_wf op_wf;
run;

proc sort data = ip_op_wf out=ip_op_wf_2 nodupkey; by epi_id_milliman wage_index tot_std_allowed;run;

proc sql;
	create table check10 as
	select a.BPID
	,a.EPISODE_ID
	,a.epi_id_milliman
	,a.period
	,b.wage_index
	,b.TOT_STD_ALLOWED
	,b.TOT_STD_ALLOWED*(0.7*b.wage_index+0.3) as TOT_STD_ALLOWED_WF
	,a.t4_total_allowed
	,round(calculated TOT_STD_ALLOWED_WF - a.t4_total_allowed,.01) as tot_diff
	from out.all_epi_detail_&num. as a
	inner join ip_op_wf_2 as b
	on a.epi_id_milliman=b.epi_id_milliman
;
quit;

data check.checkoutput10_&num.;
set check10;
where tot_diff ne 0;
run;

%mend ten;



***** RUNS ******;

/** 1 COST CHECK - Patient Detail matches Episode Detail and data3 file;*/
%one(mil);
%one(pmr);

* 2 EPISODE COUNT CHECK - episode counts match up everywhere;
%two(mil);
%two(pmr);

* 4 Check LOS distribution of SNF and IP;
%four;

*5 - output baseline and performance episode counts by BPID;
%five;
*file name = check5;

*6 - check episode index numbers are unique;
%six;

*7 - check if BPID is ever missing;
%seven(epi_detail);
%seven(pjourney);
%seven(pjourneyagg);
%seven(prov_detail);
%seven(util);
%seven(perf); 
%seven(phys_summ);
%seven(pat_detail);
%seven(exclusions);

*8 - check number of episodes for each clinical episode type by BPID;
*number of unique clinical episodes by BPID;
%eight(mil);
%eight(pmr);

** COMPARISONS WITH PREVIOUS FILE **;

*3 Compare old vs. new utilization and costs;
%three(mil);
%three(pmr);

*9 - Compare Premier benchmarks to previous distribution;
/*%nine;*/

*10 - Correct wage adjustement of claims files matches episode cost from raw epi file where expected (the obs in the output file should match the episodes with CMS-Milliman cost discrepancy);
%ten(mil);
%ten(pmr);
/*%sas_2_csv(checkoutput10_1,checkoutput10.csv);*/

**************;
%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;

proc printto;run;

%put It took &_runtm minutes to run the program;

