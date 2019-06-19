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

proc sort data=epi0 ; by bene_sk ANCHOR_BEG_DT ANCHOR_TYPE ANCHOR_END_DT POST_DSCH_BEG_DT POST_DSCH_END_DT; run;

%if &label. ^= ybase %then %do;
	*Create variables used to determine excluded episodes.;
	*prev_beg_date, prev_end_date, prev_id, and first_ep_mjrle track the first episodes.;
	*counter tracks the order number episode for MJRLE episodes.;
	*keep tracks which episodes are not readmissions or if the episode is MJRLE.;
	*epi_exclude keeps the previous epi_id_milliman for MJRLE episodes.;
	
	*Identify excluded episodes in participating performance episodes;
	*Output non-MJRLE episodes that occur within 90 days of another anchor discharge to a separate file;
	data epi0_1 excl_readm_&bpid1._&bpid2.;
		set epi0;
		by bene_sk;
		retain prev_beg_date prev_end_date prev_id first_ep_mjrle;
		format epi_exclude $32.;

		epi_exclude='';
		keep=0;
		if first.bene_sk then do;
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
		on a.bene_sk=b.bene_sk 
			and a.POST_DSCH_END_DT >= b.ANCHOR_BEG_DT
			and a.ANCHOR_BEG_DT <= b.ANCHOR_BEG_DT;
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
		on a.bene_sk=b.bene_sk 
			and a.ANCHOR_BEG_DT <= b.POST_DSCH_END_DT
			and a.ANCHOR_BEG_DT >= b.ANCHOR_BEG_DT;
	quit;

	*Remove excluded epis from non-participating;
	proc sql;
		create table perf_epis4 as
		select a.*
		from perf_epis2 as a
		where a.EPI_ID_MILLIMAN not in (select distinct EPI_ID_MILLIMAN from perf_epis3_&bpid1._&bpid2.);
	quit;

	proc sort data=perf_epis4 ; by bene_sk ANCHOR_BEG_DT ANCHOR_TYPE ANCHOR_END_DT POST_DSCH_BEG_DT POST_DSCH_END_DT; run;

	*Repeat Milliman exclusion logic for remaining non-participating episodes;
	data perfepi0_1 perfexcl_readm_&bpid1._&bpid2.;
		set perf_epis4;
		by bene_sk;
		retain prev_beg_date prev_end_date prev_id first_ep_mjrle;
		format epi_exclude $32.;

		epi_exclude='';
		keep=0;
		if first.bene_sk then do;
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
%if &label. ^= ybase %then %do;
	*Only keep inpatient index admissions at an ACH;
	data ip_idx;
		set ip_&label._&bpid1._&bpid2.;
		where type = 'IP_Idx' and ANCHOR_TYPE='ip';
		if '3025'=< pv and pv <='3099' then delete;
		if pv2 in ('T','R') then delete;
		if '2000' <= pv and pv <= '2299' then delete;
		proc sort; by bene_sk EPI_ID_MILLIMAN STAY_ADMSN_DT STAY_dschrgdt;
	run;

	***CMS_drg and CMS_prov are merged from the episode file and assigned by CMS;
	***Mill_drg uses the last leg of the transfer and Mill_prov uses the first leg of the transfer;
	data t1;
		format cms_drg best12. cms_prov $6. mill_drg best12. mill_prov $6. ;
		set ip_idx;
		by bene_sk EPI_ID_MILLIMAN;
		retain mill_prov;

		cms_drg=0+ANCHOR_CODE;
		cms_prov=anc_ccn;
		if first.EPI_ID_MILLIMAN then mill_prov=PROVIDER;
		if last.EPI_ID_MILLIMAN then do;
			mill_drg=STAY_DRG_CD;
			output;
		end;
	run;

	***Check for mismatches;
	data excl_trans_&bpid1._&bpid2.;
		set t1;
		if cms_drg^=mill_drg or cms_prov^=mill_prov;
	run;
			
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
%if &label. ^= ybase %then %do;
	data clinepi1_&bpid1._&bpid2.;
		set out.epi_ybase_&bpid1._&bpid2. (in=a)
			out.epi_y201810_&bpid1._&bpid2. (in=b)
			out.epi_y201811_&bpid1._&bpid2. (in=c)
			out.epi_y201812_&bpid1._&bpid2. (in=d)
			out.epi_y201901_&bpid1._&bpid2. (in=e)
			out.epi_y201902_&bpid1._&bpid2. (in=f)
			out.epi_y201903_&bpid1._&bpid2. (in=g)
			out.epi_y201904_&bpid1._&bpid2. (in=h)
			out.epi_y201905_&bpid1._&bpid2. (in=i)
		;
		Epis_Baseline=0;
		Epis_201810=0;
		Epis_201811=0;
		Epis_201812=0;
		Epis_201901=0;
		Epis_201902=0;
		Epis_201903=0;
		Epis_201904=0;
		Epis_201905=0;
		if a then Epis_Baseline=1;
		if b then Epis_201810=1;
		if c then Epis_201811=1;
		if d then Epis_201812=1;
		if e then Epis_201901=1;
		if f then Epis_201902=1;
		if g then Epis_201903=1;
		if h then Epis_201904=1;
		if i then Epis_201905=1;

		Total_Episodes=0;
		if a or i then Total_Episodes=1;

		if EPISODE_GROUP_NAME = "Disorders Of Liver Except Malignancy, Cirrhosis Or Alcoholic Hepatitis" then
		EPISODE_GROUP_NAME = "Disorders of liver except malignancy, cirrhosis or alcoholic hepatitis" ;

		keep BPID ANCHOR_TYPE EPISODE_GROUP_NAME ANCHOR_CODE ANCHOR_END_DT Epis_: Total_Episodes ;
	run;

	proc sql;
		create table clinepi2_&bpid1._&bpid2. as
		select a.*, b.BPCI_Episode_Idx
		from clinepi1_&bpid1._&bpid2. as a left join bpcia.BPCIA_DRG_Mapping as b
		on a.ANCHOR_CODE = b.code;
	quit;

	proc sql;
		create table clinepi3_&bpid1._&bpid2. as
		select a.*, b.Clinical_Episode
		from clinepi2_&bpid1._&bpid2. as a left join bpcia.BPCIA_Clinical_Episode_Names as b
		on a.BPCI_Episode_Idx = b.BPCI_Episode_Index;
	quit;

	proc sql;
		create table clinepi4_&bpid1._&bpid2. as
		select a.*, coalesce(b.PERFORMANCE_PERIOD,'No') as PERFORMANCE_PERIOD
		from clinepi3_&bpid1._&bpid2. as a left join bpcia_performance_episodes as b
		on a.BPID=b.BPID and a.ANCHOR_TYPE=b.ANCHOR_TYPE and a.EPISODE_GROUP_NAME=b.EPISODE_GROUP_NAME;
	quit;

	proc sql;
		create table clinepi5_&bpid1._&bpid2. as
		select a.*, b.Client, b.Health_system_name, b.Facility_or_PGP_name__to_be_used as Facility_PGP
		from clinepi4_&bpid1._&bpid2. as a left join bpcia.BPCIA_episode_initiator_info as b
		on a.BPID=b.BPCI_Advanced_ID_Number_2;
	quit;

	proc sql;
		create table out.clinepi_&label._&bpid1._&bpid2. as
		select BPID, Clinical_Episode, PERFORMANCE_PERIOD, Client, Health_system_name, Facility_PGP,
			max(ANCHOR_END_DT) as MAX_ANCHOR_END_DT format=MMDDYY10.,
			sum(Total_Episodes) as Total_Episodes,
			sum(Epis_Baseline) as Epis_Baseline,
			sum(Epis_201810) as Epis_201810,
			sum(Epis_201811) as Epis_201811,
			sum(Epis_201812) as Epis_201812,
			sum(Epis_201901) as Epis_201901,
			sum(Epis_201902) as Epis_201902,
			sum(Epis_201903) as Epis_201903,
			sum(Epis_201904) as Epis_201904,
			sum(Epis_201905) as Epis_201905
		from clinepi5_&bpid1._&bpid2.
		group by BPID, Clinical_Episode, PERFORMANCE_PERIOD, Client, Health_system_name, Facility_PGP
		order by BPID, Clinical_Episode, PERFORMANCE_PERIOD, Client, Health_system_name, Facility_PGP;
	quit;	
%end;
%MEND CLINEPI;


