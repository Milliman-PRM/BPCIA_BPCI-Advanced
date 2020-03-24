*****************************************************
*****************************************************
Bundled Payments for Care Improvement Advanced
BPCIA: 402_THA-TKA Complications Code
Code to create THA-TKA Complications Quality Measure nested in BPCIA 200 Code
*****************************************************
****************************************************;

%MACRO COMP(bpid1,bpid2);
*** THA/TKA Complication logic ***;


/*JL: Flag diagnosis and procedure codes for all claim lines, to be merged for identifying exclusions/complications in later steps*/
data dxpx;
	set out.ip_&label._&bpid1._&bpid2.;

	drop i;

	*flags for inclusion/exclusion criteria;
	tha_tka_num=0;
	pha_num=0;
	res_num=0;
	rev_num=0;
	rem_num=0;

	MC_EXCL=0;
	NEO_EXCL=0;

	Radm_rehab=0;
	Radm_psych=0;

	EVA=0;
	IND=0;
	REV=0;

	Arthropathy=0;

	*flags for complication outcomes criteria;
	*index admission flags (I);
	AMI_IA = 0;
	PN_IA = 0;
	SEP_IA = 0;
	SSB_IA = 0;
	SSB_IB = 0;
	PE_IA = 0;
	MC_IA = 0;
	PJI_IA = 0;
	PJI_IB = 0;

	*readmission flags (R);
	AMI_RA = 0;
	PN_RA = 0;
	SEP_RA = 0;
	SSB_RA = 0;
	SSB_RB = 0;
	PE_RA = 0;
	MC_RA = 0;
 	PJI_RA = 0;
	PJI_RB = 0;

	FRACTURE_COMPLICATION=0;
	
	array DIAG[*] DGNSCD01-DGNSCD25;
	array PROC[*] PRCDRCD01-PRCDRCD25;

	*********************************************** Proc Flags ***************************************************;

		if STAY_DSCHRGDT < '01OCT2015'd then do; /*SD Note: Using STAY_DSCHRGDT to indicate when to use ICD 9 or 10*/
			do i = 1 to 25;
				* Identify eligible THA/TKA procedures for THA/TKA cohort;
				if PUT(PROC[i],$ICD9_codeHKR.) = 'X' then THA_TKA_num + 1;

				* Identify exclusions that disqualify an admission from inclusion in THA/TKA cohort;
				/*E2*/else if put(PROC[i],$ICD9_D13code.) = 'X' then PHA_num + 1;
				/*E3*/else if put(PROC[i],$ICD9_D14code.) = 'X' then REV_num + 1; 
				/*E3*/else if put(PROC[i],$ICD9_D15code.) = 'X' then RES_num + 1;
				/*E3*/else if put(PROC[i],$ICD9_D18code.) = 'X' then REM_num + 1; 

				*Identify complications following THA/TKA (these two procedures can be in primary or secondary position for readmits);
				/*4_RB*/if PUT(PROC[i],$ICD9_codeD111_SSB_proc.) = 'X' then SSB_RB = 1;
				/*7_RB*/if PUT(PROC[i],$ICD9_codeD111_PJI_proc.) = 'X' then PJI_RB = 1;
			end;

			* Identify complications following THA/TKA (these two procedures must be in secondary position of index admits);
			do i = 2 to 25;
				*IND from CMS SAS code - IND not included in documentation but overlaps with PJI proc;
				/*4_IB*/if PUT(PROC[i],$ICD9_codeD111_SSB_proc.) = 'X' then SSB_IB=1; 
				/*7_IB*/if PUT(PROC[i],$ICD9_codeD111_PJI_proc.) = 'X' then PJI_IB=1;
						if PUT(PROC[i],$ICD9_INDcode.) = 'X'	then IND=1;
			end;

		end;

		else if STAY_DSCHRGDT >= '01OCT2015'd then do; /*SD Note: Using STAY_DSCHRGDT to indicate when to use ICD 9 or 10*/
			do i = 1 to 25;
				* Identify eligible THA/TKA procedures for THA/TKA cohort;
				if PUT(PROC[i],$ICD10_codeTHATKA_PROC.) = 'X' then THA_TKA_num + 1;
				* Identify exclusions that disqualify an admission from inclusion in THA/TKA cohort;
				/*E2*/else if put(PROC[i],$ICD10_CompXLIST_2_PROC.) = 'X' then PHA_num + 1;
				/*E3*/else if put(PROC[i],$ICD10_CompXLIST_3_PROC.) = 'X' then REV_num + 1; /*Rev/Res/Rem from ICD-9 are put in one flag here because there is only 1 ICD-10 code list for these procs*/

				*Identify complications following THA/TKA (for readmissions, these two procedures can be in primary
				or secondary position);
				/*4_RB*/if PUT(PROC[i],$ICD10_CompOUTCOME_9_PROC.) = 'X' then SSB_RB = 1;
				/*7_RB*/if PUT(PROC[i],$ICD10_CompOUTCOME_12_PROC.) = 'X' then PJI_RB = 1;
			end;

			do i = 2 to 25;
				* Identify complications following THA/TKA (for index admissions, these two procedures must be in secondary position);
					/*4_IB*/if PUT(PROC[i],$ICD10_CompOUTCOME_9_PROC.) = 'X' then SSB_IB = 1;
					/*7_IB*/if PUT(PROC[i],$ICD10_CompOUTCOME_12_PROC.) = 'X' then PJI_IB = 1;
			end;
		end;


	*********************************************** Diag Flags ************************************************;

			if STAY_DSCHRGDT < '01OCT2015'd then do; /*SD Note: Using STAY_DSCHRGDT to indicate when to use ICD 9 or 10*/

				* PRIMARY Requirement *;

					* Identify exclusions that disqualify an admission from inclusion in THA/TKA cohort;
					/*E4*/IF PUT(DGNSCD01,$ICD9_D16code.) = 'X' THEN MC_EXCL=1;
					/*E5*/IF PUT(DGNSCD01,$ICD9_D17code.) = 'X' then NEO_EXCL=1;
					* Codes from CMS SAS code - not included in documentation;
					/*??*/IF PUT(DGNSCD01,$ICD9_Arthcode.) = 'X' then Arthropathy=1;
					/*??*/IF upcase(DGNSCD01)=:'V57' then Radm_rehab=1;
					/*??*/IF (DGNSCD01=:'29' or DGNSCD01=:'30' or DGNSCD01=:'31') then Radm_psych=1;
					* Identify complications following THA/TKA (Readmissions must be in principal diagnosis field);
					/*1_RA*/IF PUT(DGNSCD01,$ICD9_codeD111_AMI.) = 'X' THEN AMI_RA=1;
					/*2_RA*/IF PUT(DGNSCD01,$ICD9_codeD111_PN.) = 'X' THEN PN_RA=1;

				* ANY Position *;
				do i = 1 to 25;
					* Identify complications following THA/TKA (Applies to index or readmissions that can be in any position);
					/*3_RA*/IF PUT(DIAG[i],$ICD9_codeD111_SSS.) = 'X' THEN SEP_RA=1;
					/*4_RA*/IF PUT(DIAG[i],$ICD9_codeD111_SSB_diag.) = 'X' THEN SSB_RA=1;
					/*5_RA*/IF PUT(DIAG[i],$ICD9_codeD111_PE.) = 'X' THEN PE_RA=1;
					/*6_RA*/IF PUT(DIAG[i],$ICD9_codeD111_MC.) = 'X' THEN MC_RA=1;
					/*7_RA*/IF PUT(DIAG[i],$ICD9_codeD111_PJI_diag.) = 'X' THEN PJI_RA=1;

					* ANY Position on an Anchor admission *;
					IF type = 'IP_Idx' THEN DO;
						* Identify fracture complications that disqualify admission from inclusion in THA/TKA cohort (any position);
						/*E1*/IF PUT(DIAG[i],$ICD9_D12code.) = 'X' THEN FRACTURE_COMPLICATION = 1;
					end;
				end;

				* Secondary - Unable to limit by POA variable due to lack of availability in IP file*;
				do i = 2 to 25;
				* Identify complications following THA/TKA;
					/*1_IA*/IF PUT(DIAG[i],$ICD9_codeD111_AMI.) = 'X' THEN AMI_IA=1;
					/*2_IA*/IF PUT(DIAG[i],$ICD9_codeD111_PN.) = 'X' THEN PN_IA=1;
					/*3_IA*/IF PUT(DIAG[i],$ICD9_codeD111_SSS.) = 'X' THEN SEP_IA=1;
					/*4_IA*/IF PUT(DIAG[i],$ICD9_codeD111_SSB_diag.) = 'X' THEN SSB_IA=1;
					/*5_IA*/IF PUT(DIAG[i],$ICD9_codeD111_PE.) = 'X' THEN PE_IA=1;
					/*6_IA*/IF PUT(DIAG[i],$ICD9_codeD111_MC.) = 'X' THEN MC_IA=1;
					/*7_IA*/IF PUT(DIAG[i],$ICD9_codeD111_PJI_diag.) = 'X' THEN PJI_IA=1;
				end;

			end;

			else if STAY_DSCHRGDT >= '01OCT2015'd then do; 

				* PRIMARY Requirement *;

					* Identify exclusions that disqualify an admission from inclusion in THA/TKA cohort (must be in primary diagnossi position);
					/*E4*/IF PUT(DGNSCD01,$ICD10_CompXLIST_4_CM.) = 'X' THEN MC_EXCL=1;
					/*E5*/IF PUT(DGNSCD01,$ICD10_CompXLIST_5_CM.) = 'X' then NEO_EXCL=1;


					* Identify complications following THA/TKA (Readmissions must be in principal diagnosis field);
					/*1_RA*/IF PUT(DGNSCD01,$ICD10_CompOUTCOME_6_CM.) = 'X' THEN AMI_RA=1;
					/*2_RA*/IF PUT(DGNSCD01,$ICD10_CompOUTCOME_7_CM.) = 'X' THEN PN_RA=1;


				* ANY Position *;
				do i = 1 to 25;
					* Identify complications following THA/TKA (Applies to index or readmissions that can be in any position);
					/*3_RA*/IF PUT(DIAG[i],$ICD10_CompOUTCOME_8_CM.) = 'X' THEN SEP_RA=1;
					/*4_RA*/IF PUT(DIAG[i],$ICD10_CompOUTCOME_9_CM.) = 'X' THEN SSB_RA=1;
					/*5_RA*/IF PUT(DIAG[i],$ICD10_CompOUTCOME_10_CM.) = 'X' THEN PE_RA=1;
					/*6_RA*/IF PUT(DIAG[i],$ICD10_CompOUTCOME_11_CM.) = 'X' THEN MC_RA=1;
					/*7_RA*/IF PUT(DIAG[i],$ICD10_CompOUTCOME_12_CM.) = 'X' THEN PJI_RA=1;

					* ANY Position on an Anchor admission *;
					IF type = 'IP_Idx' THEN DO;
						* Identify fracture complications that disqualify admission from inclusion in THA/TKA cohort (any position);
						/*E1*/IF PUT(DIAG[i],$ICD10_CompXLIST_1_CM.) = 'X' THEN FRACTURE_COMPLICATION = 1; 
					end;
				end;

				* Secondary - Unable to limit by POA variable due to lack of availability in IP file*;
				do i = 2 to 25;
					* Identify complications following THA/TKA;
					/*1_IA*/IF PUT(DIAG[i],$ICD10_CompOUTCOME_6_CM.) = 'X' THEN AMI_IA=1;
					/*2_IA*/IF PUT(DIAG[i],$ICD10_CompOUTCOME_7_CM.) = 'X' THEN PN_IA=1;
					/*3_IA*/IF PUT(DIAG[i],$ICD10_CompOUTCOME_8_CM.) = 'X' THEN SEP_IA=1;
					/*4_IA*/IF PUT(DIAG[i],$ICD10_CompOUTCOME_9_CM.) = 'X' THEN SSB_IA=1;
					/*5_IA*/IF PUT(DIAG[i],$ICD10_CompOUTCOME_10_CM.) = 'X' THEN PE_IA=1;
					/*6_IA*/IF PUT(DIAG[i],$ICD10_CompOUTCOME_11_CM.) = 'X' THEN MC_IA=1;
					/*7_IA*/IF PUT(DIAG[i],$ICD10_CompOUTCOME_12_CM.) = 'X' THEN PJI_IA=1;
				end;
			end;
	
	drop i;
run;


** Anchor admit information **;

*JL: Output a file of eligible index admissions with DJRLE/MJRLE participating in the performance period only;
data out.idx_&label._&bpid1._&bpid2.;
	set out.ip_&label._&bpid1._&bpid2.;
	%if &mode.=main %then %do;
	where type='IP_Idx' and PERFORMANCE_PERIOD='Yes' and EPISODE_GROUP_NAME in ('Double joint replacement of the lower extremity','Major joint replacement of the lower extremity');
	%end;
	%else %if &mode.=base %then %do;
	where type='IP_Idx' and EPISODE_GROUP_NAME in ('Double joint replacement of the lower extremity','Major joint replacement of the lower extremity');
	%end;
	keep 
		EPISODE_ID EPI_ID_MILLIMAN BENE_SK IP_STAY_ID STAY_ADMSN_DT TRANSFER_STAY AT_NPI OP_NPI BENE_AGE ANCHOR_BEG_DT STUS_CD ;
	rename STUS_CD=i_STUS_CD;
run;

*JL: Sort by transfer_stay so that the first admission is kept;
proc sort data=out.idx_&label._&bpid1._&bpid2.; by EPISODE_ID TRANSFER_STAY; run;

proc sort nodupkey data=out.idx_&label._&bpid1._&bpid2.; by EPISODE_ID; run;
proc sort data=out.idx_&label._&bpid1._&bpid2.; 
				by BENE_SK IP_STAY_ID STAY_ADMSN_DT;
					run;

*JL: Merge the index admits with their inclusion/exclusion flags for the same index admission claim;
proc sql;
	create table idx_adm2 as
	select distinct a.*
		,b.tha_tka_num
		,b.pha_num
		,b.res_num
		,b.rev_num
		,b.rem_num
		,b.MC_EXCL
		,b.NEO_EXCL
		,b.FRACTURE_COMPLICATION
	from out.idx_&label._&bpid1._&bpid2. as a
	left join dxpx as b
	on a.BENE_SK = b.BENE_SK 
	and a.IP_STAY_ID = b.IP_STAY_ID 
	and a.STAY_ADMSN_DT=b.STAY_ADMSN_DT 
	and a.EPI_ID_MILLIMAN=b.EPI_ID_MILLIMAN
;
quit;

** Calculate Complications **;
*JL: Create cohort of eligible THA/TKA procedures from which to identify complications;
data cc1;
	set idx_adm2;
	
	** Inclusion Criteria **;

	*identify patients over 64 *;
	over64 = 0;
	if BENE_AGE >= 65 then over64 = 1;

	*identify admits resulting from transfers *;
	trans = 0;
/*	if TRANSFER_STAY=1 then trans = 1;*/

	*identify admits discharged AMA *;
	AMA = 0;
	if i_STUS_CD = 7 then AMA = 1;

	* ELIGIBLE THA and/or TKA not accompanied by current revision, resurfacing, partial hip, or hardware removal codes *;
	INCLUDE=0;
	IF THA_TKA_num in (1,2) 
		AND (REV_num=0 AND PHA_num=0 AND RES_num=0 AND REM_num=0)
		AND MC_EXCL=0 AND NEO_EXCL=0
		AND FRACTURE_COMPLICATION=0
		AND over64=1
		AND trans=0
		AND AMA=0
		THEN INCLUDE=1; /* qualifying procedure */
run;

*JL: Merge the index admit inclusion/exclusion flags with all admissions for the same episode (admits are eligible for comp outcome based on inclusion criteria of the index admit);
proc sql;
	create table cc2 as
	select a.*
		,b.tha_tka_num
		,b.pha_num
		,b.res_num
		,b.rev_num
		,b.rem_num
		,b.MC_EXCL
		,b.NEO_EXCL
		,b.FRACTURE_COMPLICATION
	from out.ip_&label._&bpid1._&bpid2. as a
	left join idx_adm2 as b
	on a.EPI_ID_MILLIMAN = b.EPI_ID_MILLIMAN
;
quit;

/*------------------------------------------------------*/
*JL: Create list of all admissions with index cohort eligibility status and admit-specific outcome flags and DOS for subsequent admits;
proc sql;
	create table cc3 as 
		select distinct a.EPI_ID_MILLIMAN, a.episode_id,
			b.BENE_SK,  b.IP_STAY_ID,  b.STAY_ADMSN_DT,
			a.THA_TKA_NUM, a.REV_NUM, a.PHA_NUM, a.RES_NUM, a.REM_NUM, a.MC_EXCL, a.NEO_EXCL, a.FRACTURE_COMPLICATION, 
			a.INCLUDE, a.ANCHOR_BEG_DT,  a.i_STUS_CD, b.type, b.dos, b.provider  
			from cc1 as a
			left join cc2 as b
			on a.EPI_ID_MILLIMAN = b.EPI_ID_MILLIMAN
/*			where type not in ('IP_Idx'); */

	;
	quit;

/*------------------------------------------------------*/
*JL: Create list of all admissions with outcome flags from the corresponding claim;
proc sort data=cc3; by EPI_ID_MILLIMAN BENE_SK IP_STAY_ID STAY_ADMSN_DT; run;
proc sort data=dxpx; by EPI_ID_MILLIMAN BENE_SK IP_STAY_ID STAY_ADMSN_DT; run;

data cc4;
	merge
		cc3 (in=a)
		dxpx (in=b keep=EPI_ID_MILLIMAN BENE_SK IP_STAY_ID STAY_ADMSN_DT Radm_rehab -- PJI_RB);
	by EPI_ID_MILLIMAN BENE_SK IP_STAY_ID STAY_ADMSN_DT;
	if a;

	** Complications **;
	CC=0;
	interval = dos - ANCHOR_BEG_DT;
	if INCLUDE=1 then do;

   *SD: Complications are not output for index admissions because POA is not provided in the BPCIA CMS files;

		*identify complications on index admission - "I" criteria only *;
		if type = 'IP_Idx' then do;
			CC=0;
			CC_INF_idx=0;
			CC_SB_idx=0;
			CC_MC_idx=0;
			CC_PE_idx=0;
			CC_AMI_idx=0;
			CC_PN_idx=0;
			CC_SEP_idx=0;
		end;

		*excluded readmissions *;
		else if
			Radm_rehab>0
			OR (Radm_psych and interval in (0,1) and i_STUS_CD = 65)
			OR Arthropathy>0 then;

		*identify complications on readmissions - "R" criteria only*;
		else do;
			IF (PJI_RA>0 AND sum(IND,PJI_RB)>0 AND interval <= 90)
				OR (SSB_RA>0 AND SSB_RB>0 AND interval <= 30)
				OR (MC_RA>0 AND interval <= 90)
				OR (PE_RA>0 AND interval <= 30)
				OR (AMI_RA>0 AND interval <= 7)
				OR (PN_RA>0 AND interval <= 7)
				OR (SEP_RA>0 AND interval <= 7)
				THEN CC=1;

			if (PJI_RA>0 AND sum(IND,PJI_RB)>0 AND interval <=90) then CC_INF = 1;
			if (SSB_RA>0 AND SSB_RB>0 AND interval <= 30) then CC_SB = 1;
			if (MC_RA>0 AND interval <= 90) then CC_MC = 1;
			if (PE_RA>0 AND interval <= 30) then CC_PE = 1;
			if (AMI_RA>0 AND interval <= 7) then CC_AMI = 1;
			if (PN_RA>0 AND interval <= 7) then CC_PN = 1;
			if (SEP_RA>0 AND interval <= 7) then CC_SEP = 1;
		end;	
	end;

	array tmp1 (*) CC_INF_idx -- CC_SEP_idx;
	array tmp2 (*) CC_INF -- CC_SEP;

	do i=1 to dim(tmp1);
		if tmp1[i]=. then tmp1[i]=0;
	end;
	do i=1 to dim(tmp2);
		if tmp2[i]=. then tmp2[i]=0;
	end;
run;

*Add complication for death within 30 days of anchor begin date;
proc sql;
	create table cc4a as
	select distinct
	a.*,
	b.bene_death_dt,
	case when bene_death_dt<a.ANCHOR_BEG_DT +30 and bene_death_dt ne . and INCLUDE=1 and type in ('IP_Idx')then 1 else 0 end as CC_death,
	case when calculated CC_death=1 then 1 else cc end as cc2
	from cc4 as a
	left join data1_&label._&bpid1._&bpid2. as b
	on a.epi_id_milliman = b.epi_id_milliman

;
quit;


** Summarize detailed list of complications by episode - any complications on readmissions are assigned to the index admission by admission date**;
proc summary nway missing data=cc4a;
	class  EPI_ID_MILLIMAN EPISODE_ID PROVIDER STAY_ADMSN_DT INCLUDE;
	var STAY_ADMSN_DT CC_INF_idx -- CC_SEP_idx CC_INF -- CC_SEP CC_death;
	output out = cc5 (drop=_type_ _freq_) min= STAY_ADMSN_DT max=;
run;


*Output a list of index admissions with complications;
data out.cc_det_&label._&bpid1._&bpid2.;
	set cc5;

	format complication $255.;

	if CC_INF_idx = 1 then complication ='Periprosthetic Joint Infection / Wound Infection';
	if complication ne '' then output; complication = '';
	if CC_SB_idx = 1 then complication ='Surgical site bleeding';
	if complication ne '' then output; complication = '';
	if CC_MC_idx = 1 then complication ='Mechanical complications';
	if complication ne '' then output; complication = '';
	if CC_PE_idx = 1 then complication ='Pulmonary embolism';
	if complication ne '' then output; complication = '';
	if CC_AMI_idx = 1 then complication ='Acute myocardial infarction';
	if complication ne '' then output; complication = '';
	if CC_PN_idx = 1 then complication ='Pneumonia';
	if complication ne '' then output; complication = '';
	if CC_SEP_idx = 1 then complication ='Sepsis / septicemia / shock';
	if complication ne '' then output; complication = '';

	if CC_INF = 1 then complication ='Periprosthetic Joint Infection / Wound Infection';
	if complication ne '' then output; complication = '';
	if CC_SB = 1 then complication ='Surgical site bleeding';
	if complication ne '' then output; complication = '';
	if CC_MC = 1 then complication ='Mechanical complications';
	if complication ne '' then output; complication = '';
	if CC_PE = 1 then complication ='Pulmonary embolism';
	if complication ne '' then output; complication = '';
	if CC_AMI = 1 then complication ='Acute myocardial infarction';
	if complication ne '' then output; complication = '';
	if CC_PN = 1 then complication ='Pneumonia';
	if complication ne '' then output; complication = '';
	if CC_SEP = 1 then complication ='Sepsis / septicemia / shock';
	if complication ne '' then output; complication = '';

	if CC_death = 1 then complication ='Died within 30 days of index admission';
	if complication ne '' then output; complication = '';


	keep EPI_ID_MILLIMAN PROVIDER STAY_ADMSN_DT complication;
run;
*Output a total list of all episodes and whether they are eligible for the index chort (cc_denom) and if they have a complication (cc_numer);
proc summary nway missing data=cc4a;
	class EPI_ID_MILLIMAN;
	output out = out.cc_sum_&label._&bpid1._&bpid2. (drop=_type_ _freq_)
		min(include)=cc_denom
		max(cc2)=cc_numer;
run;

%MEND;
%COMP(&bpid1.,&bpid2.);
