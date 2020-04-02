/*
************************************************************
Code is included and ran in the "200_BPCIA Processing" code.
Purpose is to store longer macros that are called.
%EXCLUSIONFILE: Perform additional Milliman exclusions.
%TRANS_EXC: Identify transfer episodes that we believe CMS incorrectly assigned.
%CLINEPI: Create a summary of the number of episodes in each distribution.
************************************************************
*/

%MACRO EXCLUSIONFILE;

proc sort data=epi0 ; by memberid ANCHOR_BEG_DT ANCHOR_TYPE ANCHOR_END_DT POST_DSCH_BEG_DT POST_DSCH_END_DT; run;

%if %substr(&label.,1,5)  ^= ybase and &mode. ^= base %then %do;
	*Create variables used to determine excluded episodes.;
	*prev_beg_date, prev_end_date, prev_id, and first_ep_mjrle track the first episodes.;
	*counter tracks the order number episode for MJRLE episodes.;
	*keep tracks which episodes are not readmissions or if the episode is MJRLE.;
	*epi_exclude keeps the previous epi_id_milliman for MJRLE episodes.;
	
	*Identify excluded episodes in participating performance episodes;
	*Output non-MJRLE episodes that occur within 90 days of another anchor discharge to a separate file;
	data epi0_1 excl_readm_&bpid1._&bpid2.;
		set epi0;
		by memberid;
		retain prev_beg_date prev_end_date prev_id first_ep_mjrle;
		format epi_exclude $32.;

		epi_exclude='';
		keep=0;
		if first.memberid then do;
			prev_beg_date = ANCHOR_BEG_DT;
			prev_end_date = POST_DSCH_END_DT;
			prev_id = EPI_ID_MILLIMAN;
			keep=1;
			if EPISODE_GROUP_NAME = 'Major joint replacement of the lower extremity' then first_ep_mjrle=1;
				else first_ep_mjrle=0;
		end;
		else do;
			if ANCHOR_BEG_DT > prev_end_date then do;
				prev_beg_date = ANCHOR_BEG_DT;
				prev_end_date = POST_DSCH_END_DT;
				prev_id = EPI_ID_MILLIMAN;
				keep=1;
				if EPISODE_GROUP_NAME = 'Major joint replacement of the lower extremity' then first_ep_mjrle=1;
					else first_ep_mjrle=0;
			end;
			else do;
				if first_ep_mjrle=1 and EPISODE_GROUP_NAME = 'Major joint replacement of the lower extremity' then do;
					epi_exclude = prev_id;
					prev_beg_date = ANCHOR_BEG_DT;
					prev_end_date = POST_DSCH_END_DT;
					prev_id = EPI_ID_MILLIMAN;
					keep=1;
				end;
			end;
		end; 
		if keep=0 then output excl_readm_&bpid1._&bpid2.;
		else output epi0_1;
	run;

	*****Join back MJRLE episodes to only keep the latest episode*****;
	proc sql;
		create table epi0_2 as
		select a.*, coalesce(b.epi_exclude,'.') as exclude_epi
		from epi0_1 as a left join epi0_1 as b
		on a.EPI_ID_MILLIMAN=b.epi_exclude;
/*		and A.MEASURE_YEAR = B.MEASURE_YEAR;*/
	quit;

	*Output MJRLE episodes that occur within 90 days prior to another MJRLE episode to a separate file;
	*exclude_epi=. represents no subsequent episode;
	data epi0_3 excl_mjrle_&bpid1._&bpid2.;
		set epi0_2;
		if exclude_epi ^= '.' then output excl_mjrle_&bpid1._&bpid2.;
		else output epi0_3;
	run;

	*Create a table with non-participating epis that are excluded due to occuring within 90 days prior to a participating epi;
	*These epis get flagged as 'Non participating';
	proc sql;
		create table perf_epis1_&bpid1._&bpid2. as 
		select a.*
		from perf_epis0 as a inner join epi0_3 as b
		on a.memberid=b.memberid 
			and a.POST_DSCH_END_DT >= b.ANCHOR_BEG_DT
			and a.ANCHOR_BEG_DT <= b.ANCHOR_BEG_DT;
/*			and A.MEASURE_YEAR = B.MEASURE_YEAR;*/
	quit;

	*Remove excluded epis from non-participating episodes;
	proc sql;
		create table perf_epis2 as
		select a.*
		from perf_epis0 as a
		where a.EPI_ID_MILLIMAN not in (select distinct EPI_ID_MILLIMAN from perf_epis1_&bpid1._&bpid2.);
	quit;

	*Create a table with non-participating epis that are excluded due to occuring within 90 days after a participating epi discharge;
	*These epis get flagged as 'Epi included in previous episode';
	proc sql;
		create table perf_epis3_&bpid1._&bpid2. as 
		select a.*
		from perf_epis2 as a inner join epi0_3 as b
		on a.memberid=b.memberid 
			and a.ANCHOR_BEG_DT <= b.POST_DSCH_END_DT
			and a.ANCHOR_BEG_DT >= b.ANCHOR_BEG_DT;
/*			and A.MEASURE_YEAR = B.MEASURE_YEAR;*/
	quit;

	*Remove excluded epis from non-participating;
	proc sql;
		create table perf_epis4 as
		select a.*
		from perf_epis2 as a
		where a.EPI_ID_MILLIMAN not in (select distinct EPI_ID_MILLIMAN from perf_epis3_&bpid1._&bpid2.);
	quit;

	proc sort data=perf_epis4 ; by memberid ANCHOR_BEG_DT ANCHOR_TYPE ANCHOR_END_DT POST_DSCH_BEG_DT POST_DSCH_END_DT; run;

	*Repeat Milliman exclusion logic for remaining non-participating episodes;
	data perfepi0_1 perfexcl_readm_&bpid1._&bpid2.;
		set perf_epis4;
		by memberid;
		retain prev_beg_date prev_end_date prev_id first_ep_mjrle;
		format epi_exclude $32.;

		epi_exclude='';
		keep=0;
		if first.memberid then do;
			prev_beg_date = ANCHOR_BEG_DT;
			prev_end_date = POST_DSCH_END_DT;
			prev_id = EPI_ID_MILLIMAN;
			keep=1;
			if EPISODE_GROUP_NAME = 'Major joint replacement of the lower extremity' then first_ep_mjrle=1;
				else first_ep_mjrle=0;
		end;
		else do;
			if ANCHOR_BEG_DT > prev_end_date then do;
				prev_beg_date = ANCHOR_BEG_DT;
				prev_end_date = POST_DSCH_END_DT;
				prev_id = EPI_ID_MILLIMAN;
				keep=1;
				if EPISODE_GROUP_NAME = 'Major joint replacement of the lower extremity' then first_ep_mjrle=1;
					else first_ep_mjrle=0;
			end;
			else do;
				if first_ep_mjrle=1 and EPISODE_GROUP_NAME = 'Major joint replacement of the lower extremity' then do;
					epi_exclude = prev_id;
					prev_beg_date = ANCHOR_BEG_DT;
					prev_end_date = POST_DSCH_END_DT;
					prev_id = EPI_ID_MILLIMAN;
					keep=1;
				end;
			end;
		end; 
		if keep=0 then output perfexcl_readm_&bpid1._&bpid2.;
		else output perfepi0_1;
	run;

	*****Join back MJRLE episodes to only keep the latest episode*****;
	proc sql;
		create table perfepi0_2 as
		select a.*, coalesce(b.epi_exclude,'.') as exclude_epi
		from perfepi0_1 as a left join perfepi0_1 as b
		on a.EPI_ID_MILLIMAN=b.epi_exclude;
/*		and A.MEASURE_YEAR = B.MEASURE_YEAR;*/
	quit;

	data perfepi0_3 perfexcl_mjrle_&bpid1._&bpid2.;
		set perfepi0_2;
		if exclude_epi ^= '.' then output perfexcl_mjrle_&bpid1._&bpid2.;
		else output perfepi0_3;
	run;

	*****Stack all episodes for interface;
	data epi1;
		set epi0_3
			perfepi0_3
			;
	run;
%end;
%else %do;
	data epi1;
		set epi0;
	run;
%end;
%MEND EXCLUSIONFILE;


%MACRO TRANS_EXC;
%if %substr(&label.,1,5)  ^= ybase and &mode. ^= base %then %do;
	*Only keep inpatient index admissions at an ACH;
	data ip_idx;
		set ip_&label._&bpid1._&bpid2.;
		where type = 'IP_Idx' and ANCHOR_TYPE='ip';
		if '3025'=< pv and pv <='3099' then delete;
		if pv2 in ('T','R') then delete;
		if '2000' <= pv and pv <= '2299' then delete;
		proc sort; by memberid EPI_ID_MILLIMAN STAY_ADMSN_DT STAY_dschrgdt;
	run;

	***CMS_drg and CMS_prov are merged from the episode file and assigned by CMS;
	***Mill_drg uses the last leg of the transfer and Mill_prov uses the first leg of the transfer;
	data t1;
		format cms_drg best12. cms_prov $6. mill_drg best12. mill_prov $6. ;
		set ip_idx;
		by memberid EPI_ID_MILLIMAN;
		retain mill_prov;

		cms_drg=0+ANCHOR_CODE;
		cms_prov=anc_ccn;
		if first.EPI_ID_MILLIMAN and last.EPI_ID_MILLIMAN then delete;
		if first.EPI_ID_MILLIMAN then mill_prov=PROVIDER;
		if last.EPI_ID_MILLIMAN then do;
			mill_drg=STAY_DRG_CD;
			output;
		end;
	run;

	***Check for mismatches;
	data t2;
		set t1;
		if cms_drg^=mill_drg or cms_prov^=mill_prov;
		if mill_drg^=.;
	run;

	proc sql;
		create table excl_trans_&bpid1._&bpid2. as
		select a.*
		from epi_pre as a
		where a.EPI_ID_MILLIMAN in (select distinct EPI_ID_MILLIMAN from t2);
	quit;
			
	*Stack episode exclusion files created from CMS exclusions and all Milliman exclusion files;
	data out.epiexc_perf_&label._&bpid1._&bpid2.;
		set out.epiexc_&label._&bpid1._&bpid2. (in=a)
			excl_readm_&bpid1._&bpid2. (in=b)
			excl_mjrle_&bpid1._&bpid2. (in=c)
			perfexcl_readm_&bpid1._&bpid2. (in=b)
			perfexcl_mjrle_&bpid1._&bpid2. (in=c)
			excl_trans_&bpid1._&bpid2. (in=d)
			perf_epis1_&bpid1._&bpid2. (in=e)
			perf_epis3_&bpid1._&bpid2. (in=b)
			;
		DROPFLAG_READMIT_EPI=0;
		DROPFLAG_MJRLE_EPI=0;
		DROPFLAG_TRANS_EPI=0;
		DROPFLAG_NOT_PERF_EP_MIL=0;
		*Create flags to identify exclusion reason;
		if b then DROPFLAG_READMIT_EPI=1;
		if c then DROPFLAG_MJRLE_EPI=1;
		if d then DROPFLAG_TRANS_EPI=1;
		if e then DROPFLAG_NOT_PERF_EP_MIL=1;

	proc sort nodupkey; by EPI_ID_MILLIMAN;
	run;

	proc sql;
		create table out.ip_&label._&bpid1._&bpid2. as
		select a.*
		from ip_&label._&bpid1._&bpid2. as a
		where a.EPI_ID_MILLIMAN not in (select distinct EPI_ID_MILLIMAN from excl_trans_&bpid1._&bpid2.);
	quit;
	proc sql;
		create table epi as
		select a.*
		from epi_pre as a
		where a.EPI_ID_MILLIMAN not in (select distinct EPI_ID_MILLIMAN from excl_trans_&bpid1._&bpid2.);
	quit;
	data epi_&label._&bpid1._&bpid2.;
		set epi;
	run;
%end;
%else %do;
	data out.ip_&label._&bpid1._&bpid2.;
		set ip_&label._&bpid1._&bpid2.;
	run;
	data epi;
		set epi_pre;
	run;
	data epi_&label._&bpid1._&bpid2.;
		set epi;
	run;
%end;
%MEND TRANS_EXC;


%MACRO CLINEPI;
%if %substr(&label.,1,5)  ^= ybase and &mode. ^= base and &mode. ^= recon %then %do;
	data clinepi1_&bpid1._&bpid2.;
		set out.epi_ybase_&bpid1._&bpid2. (in=a)
			out.epi_y201909_&bpid1._&bpid2. (in=b)
			out.epi_y201910_&bpid1._&bpid2. (in=c)
			out.epi_y201911_&bpid1._&bpid2. (in=d)
			out.epi_y201912_&bpid1._&bpid2. (in=e)
			out.epi_y202001_&bpid1._&bpid2. (in=f)
			out.epi_y202002_&bpid1._&bpid2. (in=g)
		;
		Epis_Baseline=0;
		Epis_201909=0;
		Epis_201910=0;
		Epis_201911=0;
		Epis_201912=0;
		Epis_202001=0;
		Epis_202002=0;
		if a then Epis_Baseline=1;
		if b then Epis_201909=1;
		if c then Epis_201910=1;
		if d then Epis_201911=1;
		if e then Epis_201912=1;
		if f then Epis_202001=1;
		if g then Epis_202002=1;
		Total_Episodes=0;
		if a or g then Total_Episodes=1;

		if EPISODE_GROUP_NAME = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPISODE_GROUP_NAME = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

		keep MEASURE_YEAR BPID ANCHOR_TYPE EPISODE_GROUP_NAME ANCHOR_CODE ANCHOR_END_DT Epis_: Total_Episodes ;
	run;

	proc sql;
		create table clinepi2_&bpid1._&bpid2. as
		select a.*, b.BPCI_Episode_Idx
		from clinepi1_&bpid1._&bpid2. as a left join bpcia_drg_mapping_combined as b
		on a.ANCHOR_CODE = b.code
		And A.MEASURE_YEAR = B.MEASURE_YEAR;
	quit;

	proc sql;
		create table clinepi3_&bpid1._&bpid2. as
		select a.*, b.Clinical_Episode
		from clinepi2_&bpid1._&bpid2. as a left join bpcia_clin_epi_names_combined as b
		on a.BPCI_Episode_Idx = b.BPCI_Episode_Index
		And A.MEASURE_YEAR = B.MEASURE_YEAR;
	quit;

	proc sql;
		create table clinepi4_&bpid1._&bpid2. as
		select a.*, (case when B.BPID IS NOT NULL THEN 'Yes' else 'No' END) as PERFORMANCE_PERIOD
		from clinepi3_&bpid1._&bpid2. as a left join bpcia_performance_episodes as b
		on a.BPID=b.BPID and a.ANCHOR_TYPE=b.ANCHOR_TYPE and a.EPISODE_GROUP_NAME=b.EPISODE_GROUP_NAME
		And A.MEASURE_YEAR = B.MEASURE_YEAR;
	quit;

	proc sql;
		create table clinepi5_&bpid1._&bpid2. as
		select a.*, b.Client, b.Health_system_name, b.Facility_or_PGP_name__to_be_used as Facility_PGP
		from clinepi4_&bpid1._&bpid2. as a left join bpcia_epi_initiator_combined as b
		on a.BPID=b.BPCI_Advanced_ID_Number_2
		;
	quit;

	proc sql;
		create table out.clinepi_&label._&bpid1._&bpid2. as
		select BPID, Clinical_Episode, PERFORMANCE_PERIOD, Client, Health_system_name, Facility_PGP,
			max(ANCHOR_END_DT) as MAX_ANCHOR_END_DT format=MMDDYY10.,
			sum(Total_Episodes) as Total_Episodes,
			sum(Epis_Baseline) as Epis_Baseline,
			sum(Epis_201909) as Epis_201909,
			sum(Epis_201910) as Epis_201910,
			sum(Epis_201911) as Epis_201911,
			sum(Epis_201912) as Epis_201912,
			sum(Epis_202001) as Epis_202001,
			sum(Epis_202002) as Epis_202002
		from clinepi5_&bpid1._&bpid2.
		group by BPID, Clinical_Episode, PERFORMANCE_PERIOD, Client, Health_system_name, Facility_PGP
		order by BPID, Clinical_Episode, PERFORMANCE_PERIOD, Client, Health_system_name, Facility_PGP;
	quit;	
%end;
%MEND CLINEPI;


