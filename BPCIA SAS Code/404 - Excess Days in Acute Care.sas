
/****************************************************************************************************************
Index Admission Requirements
	- Having a principal dischare diag of AMI (for BPCIA we are only looking at admisions with an episode 
		type of AMI)
	- Enrolled in FFS Part A and Part B for the 12 months prior to the admit date, Enrolled in Part A during the
		index admission
	- Aged 65 or over
	- Discharged alive from a non-federal short-term acute care hospital
	- Not transferred to another acute care facility (only the final acute care facility enters the measure 
		cohort)

Exclude:
	- admissions for patients without at least 30 days post-discharge enrollment in FFS
	- admissions for patients discharged against medical advice
	- admissions for patients who were admitted and discharged on the same calendar day
	- admissions for a condition within 30 days of discharge from an index admission for that same condition 
		are excluded as index admissions
	- admissions to non-short-term acute care facilities such as psychiatric facilities, rehabilitation 
		facilities, or long-term care hospitals
	- admissions for stays longer than one year
	- claims with overlapping dates
	- admissions with invalid provider IDs
****************************************************************************************************************/

/****************************************************************************************************************
All-Cause Days in Acute Care Measure Requirements
	Looking at the number of days the patient spends in acute care in the 30 days after discharge
	Days are defined as:
		- ED visits (count as .5 days)
		- Observation stays (If OP, count as 1 days on the first and last day of the span of the claim; otherwise count as .5 days)
		- Unplanned readmissions (measured as los=discharge date - admit date)
			- Exclude planned readmissions using the CMS planned readmission algorithm
			- Admissions that extend past the 30 day period are truncated on day 30
	When one event overlaps with another, only the most severe of the overlapping events is counted:
		- Readmission day > Observation stay > ED visit 
****************************************************************************************************************/

proc format; value $ICD9_AMI
'41000'='Y'
'41001'='Y'
'41010'='Y'
'41011'='Y'
'41020'='Y'
'41021'='Y'
'41030'='Y'
'41031'='Y'
'41040'='Y'
'41041'='Y'
'41050'='Y'
'41051'='Y'
'41060'='Y'
'41061'='Y'
'41070'='Y'
'41071'='Y'
'41080'='Y'
'41081'='Y'
'41090'='Y'
'41091'='Y'
other='N';
run;
proc format; value $ICD10_AMI
'I2101'='Y'
'I2102'='Y'
'I2109'='Y'
'I2111'='Y'
'I2119'='Y'
'I2121'='Y'
'I2129'='Y'
'I213'='Y'
'I214'='Y'
other='N';
run;


* flag the data set for index admissions, making all exclusions listed above. Keep latest stay in a transfer; 
proc sort data=ipr_&label._&bpid1._&bpid2. out=ipr_sorted_&label._&bpid1._&bpid2.; 
	by EPI_ID_MILLIMAN DESCENDING TRANSFER_STAY;
run;

* running this dedup to remove an pre-transfer ip stays:
	for example, if a patient is transfered from hosp A to hosp B, only hosp B is eligible for the measure;

proc sort data=ipr_sorted_&label._&bpid1._&bpid2. out=index_admissions_&bpid1._&bpid2._0_pre nodupkey dupout=pre_transfer_indx_&bpid1._&bpid2.;
	by EPI_ID_MILLIMAN;
run;

data index_admissions_&bpid1._&bpid2._0;
	set index_admissions_&bpid1._&bpid2._0_pre;
	if 
			EPISODE_GROUP_NAME='Acute myocardial infarction'
		and type='IP_Idx' /* grabs only index stays */
		and BENE_AGE>=65
		/*and DROPFLAG_DEATH_DUR_ANCHOR=0*/
		and ('0001' <= pv and pv <= '0899') /* keeps only short-term acute care hospitals */
		and stus_cd ne 7 /* stus_cd indicates that a patient was discharged against medical advice */
		and STAY_ADMSN_DT ne STAY_DSCHRGDT
		and STAY_DSCHRGDT - STAY_ADMSN_DT < 366
	;
run;

data index_admissions_&bpid1._&bpid2.;
	set index_admissions_&bpid1._&bpid2._0;
	if STAY_DSCHRGDT < '01OCT2015'd then do;
		if put(DGNSCD01,$ICD9_AMI.)='Y';
	end;
	else do;
		if put(DGNSCD01,$ICD10_AMI.)='Y';
	end;
run;

* create a line for each day after admission;
data index_datelines_&bpid1._&bpid2.;
	format post_dschrg_day mmddyy10.;
	set index_admissions_&bpid1._&bpid2.;
	do i=0 to 29;
		post_dschrg_day=STAY_DSCHRGDT+i;
		output;
	end;
run;

* sort ip file by epi_id_milliman;
proc sort data=ipr_&label._&bpid1._&bpid2.; by EPI_ID_MILLIMAN; run;

* create IP datelines;
data ipr_datelines_&bpid1._&bpid2.;
	format admit_date_line mmddyy10.;
	format ip_readmit_days best12.;
	set ipr_&label._&bpid1._&bpid2.
	    (where=(type ne 'IP_Idx' and UNPLANNED_READMIT_FLAG=1 and EPISODE_GROUP_NAME='Acute myocardial infarction'));
	do i=0 to util_day-1;
		admit_date_line=STAY_ADMSN_DT+i;
		ip_readmit_days=1;
		output;
	end;
run;

* sort op file by epi_id_milliman;
proc sort data=op_&label._&bpid1._&bpid2.; by EPI_ID_MILLIMAN; run;

* create op datelines;
data op_datelines_&bpid1._&bpid2._0;
	format op_date_line mmddyy10.;
	format ed_days obs_days prelim_days best12.;
	set op_&label._&bpid1._&bpid2.;
	if REV_CNTR in (762, 450, 451, 452, 459, 981) 
		or HCPCS_CD in ('G0378','99217','99234','99235','99236','99218','99219','99220');

	/* set up an ending point for the do loop*/
	prelim_days=THRU_DT - max(FROM_DT, REV_DT);

	/* ed days */
	if REV_CNTR in (450, 451, 452, 459, 981) then do;
		op_date_line=FROM_DT;
		ed_days=.5;
		output;
	end;
	/* obs days */
	else if REV_CNTR=762 or HCPCS_CD in ('G0378','99217','99234','99235','99236','99218','99219','99220') 
		then do i=0 to prelim_days;
			op_date_line=max(FROM_DT, REV_DT)+i;
			if i=0 or i=prelim_days then obs_days=.5;
			else obs_days=1;
			output;
	end;
run;

* remove duplicate op datelines, giving preference to ed visits over obs stays;
proc sort data=op_datelines_&bpid1._&bpid2._0 out=op_datelines_&bpid1._&bpid2._1;
	by BPID EPI_ID_MILLIMAN op_date_line descending ed_days descending obs_days;
run;
proc sort data=op_datelines_&bpid1._&bpid2._1 out=op_datelines_&bpid1._&bpid2. nodupkey;
	by BPID EPI_ID_MILLIMAN op_date_line;
run;

* sort pb file by epi_id_milliman;
proc sort data=pb2_&label._&bpid1._&bpid2. out=pb_&label._&bpid1._&bpid2.; by EPI_ID_MILLIMAN; run;

* create pb datelines;
data pb_datelines_&bpid1._&bpid2._0;
	format pb_date_line mmddyy10.;
	*format ed_days best12.;
	set pb_&label._&bpid1._&bpid2.;
	if HCPCS_CD in ('G0378','99217','99234','99235','99236','99218','99219','99220');

	/* obs days */
	pb_date_line=FROM_DT;
	obs_days=.5;
run;

* remove duplicate pb datelines;
proc sort data=pb_datelines_&bpid1._&bpid2._0 out=pb_datelines_&bpid1._&bpid2._1;
	by BPID EPI_ID_MILLIMAN pb_date_line descending obs_days;
run;
proc sort data=pb_datelines_&bpid1._&bpid2._1 out=pb_datelines_&bpid1._&bpid2. nodupkey;
	by BPID EPI_ID_MILLIMAN pb_date_line;
run;

* join edac datelines onto index datelines;
proc sql;
	create table outcome_datelines_&bpid1._&bpid2._0 as
	select a.BPID
		,  a.EPI_ID_MILLIMAN
		,  a.type
		,  a.post_dschrg_day
		,  b.ip_readmit_days
		,  c.ed_days as op_ed_days
		,  c.obs_days as op_obs_days
		,  d.obs_days as pb_obs_days
	from index_datelines_&bpid1._&bpid2. as a
	left join ipr_datelines_&bpid1._&bpid2. as b
		on  a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
		and a.post_dschrg_day=b.admit_date_line
	left join op_datelines_&bpid1._&bpid2. as c
		on  a.EPI_ID_MILLIMAN=c.EPI_ID_MILLIMAN
		and a.post_dschrg_day=c.op_date_line
	left join pb_datelines_&bpid1._&bpid2. as d
		on  a.EPI_ID_MILLIMAN=d.EPI_ID_MILLIMAN
		and a.post_dschrg_day=d.pb_date_line
	;
quit;

data outcome_datelines_&bpid1._&bpid2.;
	set outcome_datelines_&bpid1._&bpid2._0;
	format total_edac_days best12.;

	* When one event overlaps with another, only the most severe of the overlapping events is counted:
	  Readmission day > Observation stay > ED visit ;
		 if ip_readmit_days >0 then do; op_obs_days=0; pb_obs_days=0; op_ed_days=0;  end;
	else if op_obs_days		>0 then do; 			   pb_obs_days=0; op_ed_days=0;  end;
	else if pb_obs_days		>0 then do; 							  op_ed_days=0; end;

	total_edac_days=sum(ip_readmit_days, op_ed_days, op_obs_days, pb_obs_days);
run;

proc sql;
	create table outcome_&bpid1._&bpid2. as
	select BPID
		,  EPI_ID_MILLIMAN
		,  type
		,  'Y' as ami_edac_elig_index_yn
		,  coalesce(sum(ip_readmit_days),0) as excess_ip_readmit_days
		,  coalesce(sum(op_ed_days),0)		as excess_op_ed_days
		,  coalesce(sum(op_obs_days),0)		as excess_op_obs_days
		,  coalesce(sum(pb_obs_days),0)		as excess_pb_obs_days
		,  coalesce(sum(total_edac_days),0) as total_excess_days
	from outcome_datelines_&bpid1._&bpid2.
	group by BPID, EPI_ID_MILLIMAN, type
	;
quit;

proc sql;
	create table ipre_&label._&bpid1._&bpid2._0 as
	select a.*
		,  case when a.type='IP_Idx' and a.EPISODE_GROUP_NAME='Acute myocardial infarction' then
				coalescec(b.ami_edac_elig_index_yn, 'N') 
				else '' end as ami_edac_elig_index_yn
		,  b.excess_ip_readmit_days
		,  b.excess_op_ed_days
		,  b.excess_op_obs_days
		,  b.excess_pb_obs_days
		,  b.total_excess_days
	from ipr_&label._&bpid1._&bpid2. as a
	left join outcome_&bpid1._&bpid2. as b
		on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
		and a.type='IP_Idx' and a.EPISODE_GROUP_NAME='Acute myocardial infarction'
	;
quit;

* flag any unplanned readmit that might be used in the excess days calc;
proc sql;
	create table ipre_&label._&bpid1._&bpid2. as
	select a.*
		,  b.ami_edac_elig_epi_yn
		,  case when type ne 'IP_Idx' and UNPLANNED_READMIT_FLAG=1 and EPISODE_GROUP_NAME='Acute myocardial infarction'
		   then 1 else 0 end as used_for_acute_days
	from ipre_&label._&bpid1._&bpid2._0 as a
	left join (select distinct EPI_ID_MILLIMAN, ami_edac_elig_index_yn as ami_edac_elig_epi_yn 
			   from ipre_&label._&bpid1._&bpid2._0
			   where type='IP_Idx' and EPISODE_GROUP_NAME='Acute myocardial infarction') as b
	on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
	;
quit;
data out.ipr_&label._&bpid1._&bpid2. ;
	set ipre_&label._&bpid1._&bpid2. ;
	format edac_flag $3. ;
	if timeframe ^= 1 then do;
		ami_edac_elig_epi_yn = '' ;
		used_for_acute_days = . ;
	end;
	edac_flag = 'No' ;
	if ami_edac_elig_epi_yn = 'Y' and used_for_acute_days = 1 then edac_flag = 'Yes' ;
run;

* flag any op claims that might be used in the excess days calc;
proc sql;
	create table ope_&label._&bpid1._&bpid2. as
	select a.*
		,  b.ami_edac_elig_epi_yn
		,  case when EPISODE_GROUP_NAME='Acute myocardial infarction' 
		   		and (REV_CNTR in (762, 450, 451, 452, 459, 981) 
		   			 or HCPCS_CD in ('G0378','99217','99234','99235','99236','99218','99219','99220'))
		   then 1 else 0 end as used_for_acute_days
	from op_&label._&bpid1._&bpid2. as a
	left join (select distinct EPI_ID_MILLIMAN, ami_edac_elig_index_yn as ami_edac_elig_epi_yn 
			   from ipre_&label._&bpid1._&bpid2._0
			   where type='IP_Idx' and EPISODE_GROUP_NAME='Acute myocardial infarction') as b
	on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
	;
quit;
data out.op_&label._&bpid1._&bpid2. ;
	set ope_&label._&bpid1._&bpid2. ;
	format edac_flag $3. ;
	if timeframe ^= 1 then do;
		ami_edac_elig_epi_yn = '' ;
		used_for_acute_days = . ;
	end;
	edac_flag = 'No' ;
	if ami_edac_elig_epi_yn = 'Y' and used_for_acute_days = 1 then edac_flag = 'Yes' ;
run;

* flag any pb claims that might be used in the excess days calc;
proc sql;
	create table pbe2_&label._&bpid1._&bpid2. as
	select a.*
		,  b.ami_edac_elig_epi_yn
		,  case when EPISODE_GROUP_NAME='Acute myocardial infarction' 
		   		and HCPCS_CD in ('G0378','99217','99234','99235','99236','99218','99219','99220')
		   then 1 else 0 end as used_for_acute_days
	from pb2_&label._&bpid1._&bpid2. as a
	left join (select distinct EPI_ID_MILLIMAN, ami_edac_elig_index_yn as ami_edac_elig_epi_yn 
			   from ipre_&label._&bpid1._&bpid2._0
			   where type='IP_Idx' and EPISODE_GROUP_NAME='Acute myocardial infarction') as b
	on a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
	;
quit;
data out.pb2_&label._&bpid1._&bpid2. ;
	set pbe2_&label._&bpid1._&bpid2. ;
	format edac_flag $3. ;
	if timeframe ^= 1 then do;
		ami_edac_elig_epi_yn = '' ;
		used_for_acute_days = . ;
	end;
	edac_flag = 'No' ;
	if ami_edac_elig_epi_yn = 'Y' and used_for_acute_days = 1 then edac_flag = 'Yes' ;
run;

