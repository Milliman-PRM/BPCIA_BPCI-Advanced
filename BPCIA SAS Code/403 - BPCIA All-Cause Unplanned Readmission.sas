
*** Step 1: Identify index admissions *** ;
*** Remove if:  Discharged against medical advice, 
				Admitted for primary psychiatric diagnoses,
				Admitted for rehabilititation 
				Admitted to PPS-exempts cancer hospital*** ;
PROC SORT DATA=out.ip_&label._&bpid1._&bpid2. out=index1a; BY BENE_SK EPISODE_ID STAY_ADMSN_DT STAY_DSCHRGDT; run;

data index1b ;
	set index1a;

	BY BENE_SK EPISODE_ID STAY_ADMSN_DT STAY_DSCHRGDT;

	*** Assign case number *** ;

	FORMAT PREV_ADM  PREV_DIS MMDDYY10. ;

	IF STAY_DSCHRGDT = . THEN STAY_DSCHRGDT = STAY_THRU_DT ;
	IF FIRST.EPISODE_ID  THEN DO ;
		IP_CASE = 1 ;
		PREV_IP = IP_CASE ;
		PREV_ADM = STAY_ADMSN_DT ;
		PREV_DIS = STAY_DSCHRGDT ;
	END ;
	ELSE DO ;
		IF PREV_ADM LE STAY_ADMSN_DT LE PREV_DIS  and type not in ('IP_Rehab','IP_LTAC')THEN IP_CASE = PREV_IP ; *** nested/overlapping stays *** ;
		ELSE IF PREV_DIS = STAY_ADMSN_DT and type not in ('IP_Rehab','IP_LTAC') THEN IP_CASE = PREV_IP ; *** transfers *** ;
		ELSE IP_CASE=SUM(PREV_IP,1) ;
		PREV_IP = IP_CASE ;
		PREV_ADM = STAY_ADMSN_DT ;
		PREV_DIS = STAY_DSCHRGDT ;
	END ;

	RETAIN PREV_IP PREV_ADM PREV_DIS;

run;

data index1;
	set index1b;
	*** Identification of Short Term Acute and CAH stays for readmissions *** ;
	readm_cand = 0;
	if '0001' <= pv and pv <= '0899' then readm_cand = 1;
	else if '1300' <= pv and pv <= '1399' then readm_cand = 1;
	if readm_cand = 1;
	
	*** Identification of PPS-exempts cancer hospital admissions for readmissions *** ;
	ca_hosp=0;
	if provider in ('050146','050660','100079','100271','220162','330154','330354','360242','390196','450076','500138') then ca_hosp=1;  
	if ca_hosp = 1 then delete ;

	if stus_cd = 7 then delete ;  *** Discharged against medical advice. *** ;

	*identify patients over 64 *;
	over64 = 0;
	if BENE_AGE >= 65 then over64 = 1;
	if over64=0 then delete;

run;

*** Step 2: Keep the latest billed admission for a case *** ;
proc sort data=index1 ; by bene_sk EPISODE_ID IP_CASE  ; run;

proc means data=index1 noprint MIN max ; by bene_sk EPISODE_ID IP_CASE ;
	var STAY_FROM_DT STAY_DSCHRGDT ;
	output out=i1 (drop = _type_ _freq_)
		   MIN(STAY_FROM_DT) = CASE_FROM_DT
		   max(STAY_DSCHRGDT) = case_discharge;
run;

data index1a ;
	merge index1(in=a) i1(in=b) ; by bene_sk EPISODE_ID IP_CASE ;
	if a and b ;
	format case_discharge mmddyy10. ;
	if STAY_DSCHRGDT = case_discharge ;
run;
	
proc sql ;
	create table index2 as
	select distinct bene_sk, EPISODE_ID, IP_CASE, stus_cd, case_discharge, stay_from_dt, CASE_from_dt,
	DGNSCD01,	DGNSCD02,	DGNSCD03,	DGNSCD04,	DGNSCD05,
	DGNSCD06,	DGNSCD07,	DGNSCD08,	DGNSCD09,	DGNSCD10,
	DGNSCD11,	DGNSCD12,	DGNSCD13,	DGNSCD14,	DGNSCD15,
	DGNSCD16,	DGNSCD17,	DGNSCD18,	DGNSCD19,	DGNSCD20,
	DGNSCD21,  	DGNSCD22,  	DGNSCD23, 	DGNSCD24,  	DGNSCD25,
	PRCDRCD01, 	PRCDRCD02, 	PRCDRCD03, 	PRCDRCD04,	PRCDRCD05,
	PRCDRCD06, 	PRCDRCD07,	PRCDRCD08, 	PRCDRCD09, 	PRCDRCD10, 
	PRCDRCD11, 	PRCDRCD12, 	PRCDRCD13,	PRCDRCD14, 	PRCDRCD15,
	PRCDRCD16, 	PRCDRCD17, 	PRCDRCD18, 	PRCDRCD19, 	PRCDRCD20,
	PRCDRCD21, 	PRCDRCD22,	PRCDRCD23, 	PRCDRCD24, 	PRCDRCD25 
	from index1a ;
quit;

*** Accounts for cases with varying ICD codes - using latest *** ;
proc sort data=index2 ; by bene_sk EPISODE_ID IP_CASE stay_from_dt ; run;

data index2 ;
	set index2 ; by bene_sk EPISODE_ID IP_CASE stay_from_dt;
	if last.IP_CASE;
run;

*****separate icd 9 and 10 files for CCS assignment*****;
data index2_9 index2_0;
	set index2;

	if case_discharge < '01OCT2015'd then output index2_9;
	else output index2_0;
run;
******************************************** ;
**** For Baseline/ICD9 process *** ;
******************************************** ;


*** Step 3: Assign CCs  - outputs file index3 *** ;
%include "H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Data from Other Sources\AHRQ CC\ICD9\Sample_SingleCCS_Diagnosis_Load_Pgm.sas";

%include "H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Data from Other Sources\AHRQ CC\ICD9\Sample_SingleCCS_Procedures_Load_Pgm.sas";

*** Step 4: Remove admissions for psych or rehab *** ;
data index4_9 ;
	set index3_9 ;
	if case_discharge < '01OCT2015'd;
	psych_flag=0;


	if CCS1 in (650,651,652,654,655,656,657,658,659,662,670) then psych_flag=1 ; *** See Table D1 - psych discharges *** ;
	if CCS1 = 254 then delete ; *** See Table D1 Flow Diagram - rehab discharges *** ;
run;

*** Step 5: Flag admissions *** ;
data index5_9 /*INDEX_ADMISSIONS*/  ;
	set index4_9 ;
	SURGICAL_ADMISSION = 0 ;
	ONCOLOGY_ADMISSION = 0 ;
	CARDIORESP_ADMISSION = 0 ;
	CARDIOVASC_ADMISSION = 0 ;
	NEURO_ADMISSION = 0 ;
	MED_ADMISSION = 0 ;
	TRANSPLANT_ADMISSION = 0 ;
	MAINTENANCE_ADMISSION = 0 ;
	PPLANNED_PROC = 0 ;
	PPLANNED_PRINC = 0 ;
	PLANNED_ADMISSION = 0 ;
	INDEX_ADMISSION = 0 ;
	MISS_COHORT = 0 ;
	INDEX_ADMIT=0;


		*** See PR Tables IN *** ;
	array px (P) PRCDRCD: ;
	ARRAY PCC (P ) PRCCS: ;
	DO P = 1 TO DIM(PX) ;
		*** Surgical Procedure *** ;
		If PCC in (1, 2, 3, 9, 10, 12, 13, 14, 15, 16, 17, 20, 21, 22, 23, 24, 26, 28,
					  30, 33, 36, 42, 43, 44, 49, 51, 52, 53, 55, 56, 59, 60, 66, 67, 72,
					  73, 74, 75, 78, 79, 80, 84, 85, 86, 89, 90, 94, 96, 99, 101, 103, 
					  104, 105, 106, 109, 112, 113, 114, 118, 119, 120, 121, 123, 124, 
					  125, 129, 131, 132, 133, 141, 142, 144, 145, 146, 147, 148, 150,
					  152, 153, 154, 157, 158, 160, 161, 162, 164, 166, 167, 172, 175,
					  176) THEN SURGICAL_ADMISSION = 1 ; *Source: V7.0 Table D.2 -- ICD-10-PCS Codes ;
		IF PCC IN (64, 105, 176) THEN TRANSPLANT_ADMISSION = 1 ; *** Source: V7.0 Table PR.1 - Always planned. *** ;
		IF PCC IN (1,3,5,9,10,12,33,36,38,40,43,44,45,49,51,52,53,55,56,59,66,67,74,78,79,84,
					  85,86,99,104,106,107,109,112,113,114,119,120,124,129,132,142,152,153,154,
					  158,159,166,167,172,175) THEN PPLANNED_PROC = 1 ; *** Source: V7.0 Table PR.3 - Potentially planned procedures. ** ;
		if PX IN ('301','3029','303','304','3174','346','3818','5503','5504','9426','9427') then 
					 PPLANNED_PROC = 1 ; *** Source: V5.0 Table PR.3 - Potentially planned procedures. ** ;
	END ;

	IF CCS1 IN (45, 254) THEN MAINTENANCE_ADMISSION = 1 ; *** Source: V7.0 Table PR. 2 - Always planned. - Includes maintenance chemo *** ;
		
	IF SURGICAL_ADMISSION NE 1 THEN DO ;

		IF CCS1 IN (11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 
					   26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
					   41, 42, 43, 44, 45) THEN ONCOLOGY_ADMISSION = 1 ;  * Source: Table D.3 -- Oncology *** ;
		ELSE IF CCS1 IN (56, 103, 108, 122, 125, 127, 128, 131) THEN CARDIORESP_ADMISSION = 1 ;* Source: Table D.4 *** ;
		ELSE IF CCS1 IN (96, 97, 100, 101, 102, 104, 105, 106, 107, 114, 115, 116, 117,
							   213) THEN CARDIOVASC_ADMISSION = 1 ; * Source: Table D.5 *** ;
		ELSE IF CCS1 IN (78, 79, 80, 81, 82, 83, 85, 95, 109, 110, 111, 112, 113, 216, 227, 233)
									then NEURO_ADMISSION = 1 ;* Source: Table D.6 *** ;
		ELSE IF CCS1 IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 57,
							   58, 59, 60, 61, 62, 63, 64, 76, 77, 84, 86, 87, 88, 89, 90, 91, 92, 93,
							   94, 98, 99, 118, 119, 120, 121, 123, 124, 126, 129, 130, 132, 133, 134, 
							   135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 
							   149, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 
							   164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 175, 197, 198, 199, 200, 
							   201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 214, 215, 
							   217, 225, 226, 228, 229, 230, 231, 232, 234, 235, 236, 237, 238, 239,
							   240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 
							   255, 256, 257, 258, 259, 653, 660, 661, 663, 2617) THEN MED_ADMISSION = 1 ;* Source: Table D.7 *** ;
	END ;


	IF CCS1 IN (1,2,3,4,5,7,8,9,54,55,60,61,63,76,77,78,82,83,84,85,87,89,90,91,92,93,99,
					  102, 104, 107, 109, 112, 116, 118, 120, 122, 123, 124, 125, 126, 127, 
					  128, 129, 130, 131, 135, 137, 139, 140, 142, 145, 146, 148, 153, 154, 
					  157, 159, 165, 168, 172, 197, 198, 172, 197, 198, 226, 227, 229, 233,
					  234, 235, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 249, 250,
					  251, 252, 253, 259, 650, 651, 652, 653, 656, 658, 660, 661, 662, 663, 670)
			OR PUT(DGNSCD01,$ACUTE_ICD9_DIAGCD.) = "Y" THEN PPLANNED_PRINC = 1 ; 
			*Source: V7.0 Table PR.4 for CCs and V5.0 Table PR.4 for Acute ICD9 Codes ;

	IF TRANSPLANT_ADMISSION = 1 OR MAINTENANCE_ADMISSION = 1 OR
		(PPLANNED_PROC=1 AND PPLANNED_PRINC NE 1) THEN PLANNED_ADMISSION = 1 ;

	if stus_cd not in (7,20) and psych_flag=0  and ONCOLOGY_ADMISSION=0 then INDEX_ADMIT = 1 ;  *** removes patients who die in hospital from index contention *** ;

	IF SUM(SURGICAL_ADMISSION, ONCOLOGY_ADMISSION, CARDIORESP_ADMISSION, CARDIOVASC_ADMISSION,
		   NEURO_ADMISSION, MED_ADMISSION) = 0 THEN MISS_COHORT = 1 ;

	OUTPUT INDEX5_9 ;
	/*IF INDEX_ADMISSION = 1 THEN OUTPUT INDEX_ADMISSIONS*/ ;
	/*IF PLANNED_ADMISSION NE 1 THEN OUTPUT READMIT_CAND*/ ;

/*	PROC FREQ DATA=INDEX5_9;*/
/*		WHERE INDEX_ADMISSION = 1 AND MISS_COHORT = 1 ;*/
/*			TABLES ccs1*prccs1/list missing ;*/
/*	TITLE "RECORDS MARKED AS INDEX ADMISSIONS NOT BEING ASSIGNED TO A SPECIALTY COHORT BASED ON CCS" ;*/
/**/
/*run;*/
******************************************** ;
**** For ICD10 process *** ;
******************************************** ;

*** Step 3: Assign CCs  - outputs file index3 *** ;
%include "H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Data from Other Sources\AHRQ CC\ICD10\ICD10_Single_CCS_Load_Program.sas";

*Bring in additional formats (used in Step 5 below) ;

*** Step4: Remove admissions for psych or rehab or age over 64 *** ;
data index4_0 ;
	set index3_0 ;
	if case_discharge >= '01OCT2015'd;
	psych_flag=0;
	
	if I10_DXCCS1 in (650,651,652,654,655,656,657,658,659,662,670) then psych_flag=1 ; *** See Table D1 - psych discharges *** ;
	if I10_DXCCS1 = 254 then delete ; *** See Table D1 Flow Diagram - rehab discharges *** ;
run;
*** Step 5: Flag admissions *** ;
data index5_0 /*INDEX_ADMISSIONS*/  ;
	set index4_0 ;
	SURGICAL_ADMISSION = 0 ;
	ONCOLOGY_ADMISSION = 0 ;
	CARDIORESP_ADMISSION = 0 ;
	CARDIOVASC_ADMISSION = 0 ;
	NEURO_ADMISSION = 0 ;
	MED_ADMISSION = 0 ;
	TRANSPLANT_ADMISSION = 0 ;
	MAINTENANCE_ADMISSION = 0 ;
	PPLANNED_PROC = 0 ;
	PPLANNED_PRINC = 0 ;
	PLANNED_ADMISSION = 0 ;
	INDEX_ADMISSION = 0 ;
	MISS_COHORT = 0 ;
	INDEX_ADMIT=0;


		*** See PR Tables IN *** ;
	array px (P) PRCDRCD: ;
/*	array vx (P) ICD_PRCDR_VRSN_CD: ;*/
	ARRAY PCC (P ) I10_PRCCS: ;
	DO P = 1 TO DIM(PX) ;
		*** Surgical Procedure *** ;
		if PUT(PX,$SURG_ICD10_PRCCD.) = "Y" THEN SURGICAL_ADMISSION = 1 ; *Source: Table D.2 -- ICD-10-PCS Codes ;
		If PCC in (1, 2, 3, 9, 10, 12, 13, 14, 15, 16, 17, 20, 21, 22, 23, 24, 26, 28,
					  30, 33, 36, 42, 43, 44, 49, 51, 52, 53, 55, 56, 59, 60, 66, 67, 72,
					  73, 74, 75, 78, 79, 80, 84, 85, 86, 89, 90, 94, 96, 99, 101, 103, 
					  104, 105, 106, 109, 112, 113, 114, 118, 119, 120, 121, 123, 124, 
					  125, 129, 131, 132, 133, 141, 142, 144, 145, 146, 147, 148, 150,
					  152, 153, 154, 157, 158, 160, 161, 162, 164, 166, 167, 172, 175,
					  176) THEN SURGICAL_ADMISSION = 1 ; *Source: Table D.2 -- ICD-10-PCS Codes ;
		IF PCC IN (64, 105, 176) THEN TRANSPLANT_ADMISSION = 1 ; *** Source: Table PR.1 - Always planned. *** ;
		IF PCC IN (1,3,5,9,10,12,33,36,38,40,43,44,45,49,51,52,53,55,56,59,66,67,74,78,79,84,
					  85,86,99,104,106,107,109,112,113,114,119,120,124,129,132,142,152,153,154,
					  158,159,166,167,172,175) THEN PPLANNED_PROC = 1 ; *** Source: Table PR.3 - Potentially planned procedures. ** ;
		if put(PX,$PPLANNED_ICD10_PRCCD.) = "Y" then PPLANNED_PROC = 1 ; *** Source: Table PR.3 - Potentially planned procedures. ** ;
	END ;


	IF I10_DXCCS1 IN (45, 254) THEN MAINTENANCE_ADMISSION = 1 ; *** Source: Table PR. 2 - Always planned. - Includes maintenance chemo *** ;

	*** See "D" tables *** ;
	*TG changes here ;
		
	IF SURGICAL_ADMISSION NE 1 THEN DO ;

		IF I10_DXCCS1 IN (11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 
					   26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
					   41, 42, 43, 44, 45) THEN ONCOLOGY_ADMISSION = 1 ;  * Source: Table D.3 -- Oncology *** ;
		ELSE IF I10_DXCCS1 IN (56, 103, 108, 122, 125, 127, 128, 131) THEN CARDIORESP_ADMISSION = 1 ;* Source: Table D.4 *** ;
		ELSE IF I10_DXCCS1 IN (96, 97, 100, 101, 102, 104, 105, 106, 107, 114, 115, 116, 117,
							   213) THEN CARDIOVASC_ADMISSION = 1 ; * Source: Table D.5 *** ;
		ELSE IF I10_DXCCS1 IN (78, 79, 80, 81, 82, 83, 85, 95, 109, 110, 111, 112, 113, 216, 227, 233)
									then NEURO_ADMISSION = 1 ;* Source: Table D.6 *** ;
		ELSE IF I10_DXCCS1 IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 57,
							   58, 59, 60, 61, 62, 63, 64, 76, 77, 84, 86, 87, 88, 89, 90, 91, 92, 93,
							   94, 98, 99, 118, 119, 120, 121, 123, 124, 126, 129, 130, 132, 133, 134, 
							   135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 
							   149, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 
							   164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 175, 197, 198, 199, 200, 
							   201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 214, 215, 
							   217, 225, 226, 228, 229, 230, 231, 232, 234, 235, 236, 237, 238, 239,
							   240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 
							   255, 256, 257, 258, 259, 653, 660, 661, 663, 2617) THEN MED_ADMISSION = 1 ;* Source: Table D.7 *** ;
	END ;


	IF I10_DXCCS1 IN (1,2,3,4,5,7,8,9,54,55,60,61,63,76,77,78,82,83,84,85,87,89,90,91,92,93,99,
					  102, 104, 107, 109, 112, 116, 118, 120, 122, 123, 124, 125, 126, 127, 
					  128, 129, 130, 131, 135, 137, 139, 140, 142, 145, 146, 148, 153, 154, 
					  157, 159, 165, 168, 172, 197, 198, 226, 227, 229, 233,
					  234, 235, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 249, 250,
					  251, 252, 253, 259, 650, 651, 652, 653, 656, 658, 660, 661, 662, 663, 670)
			OR PUT(DGNSCD01,$ACUTE_ICD10_DIAGCD.) = "Y" THEN PPLANNED_PRINC = 1 ; *Source: Table PR.4 -- ICD-10-CM Codes ;

	IF TRANSPLANT_ADMISSION = 1 OR MAINTENANCE_ADMISSION = 1 OR
		(PPLANNED_PROC=1 AND PPLANNED_PRINC NE 1) THEN PLANNED_ADMISSION = 1 ;

	if stus_cd NOTIN (7,20)  and psych_flag=0 and ONCOLOGY_ADMISSION=0 then INDEX_ADMIT = 1 ;  *** removes patients who die in hospital from index contention *** ;

	IF SUM(SURGICAL_ADMISSION, ONCOLOGY_ADMISSION, CARDIORESP_ADMISSION, CARDIOVASC_ADMISSION,
		   NEURO_ADMISSION, MED_ADMISSION) = 0 THEN MISS_COHORT = 1 ;

	OUTPUT INDEX5_0 ;
	*IF INDEX_ADMISSION = 1 THEN OUTPUT INDEX_ADMISSIONS ;



run;

*****stack icd 9 and 10 files together*****;

data index5;
	set index5_9
		index5_0;
run;
*** Step 6: Identify index admits w unplanned readmit *** ;

*DATA INDEX_ADMISSIONS ; *SET INDEX_ADMISSIONS ;
DATA index5 ; SET index5;
	DAY30 = INTNX('DAY',case_discharge,30,'SAME') ;
run;

	*** As per 2.2.2 in 2018 methodology document, If the first readmission after discharge is planned, 
	any subsequent unplanned readmission is not considered in the outcome for that index admission
	because the unplanned readmission could be related to care provided during the intervening
	planned readmission rather than during the index admission. *** ;
	*** Only allows immediately following admission to be reviewed for an event. *** ;

*PROC SORT DATA=INDEX_ADMISSIONS ; 
PROC SORT DATA=INDEX5 ; BY BENE_SK EPISODE_ID stay_from_dt case_discharge ; run;

DATA INDEX_FINAL READ1(KEEP = BENE_SK EPISODE_ID READMIT_CASE) ;
	SET /*INDEX_ADMISSIONS*/ INDEX5 ; BY BENE_SK EPISODE_ID stay_from_dt case_discharge;
	
	IF FIRST.EPISODE_ID THEN DO ;
		PREV_CASE = IP_CASE ;
		PREV30 = DAY30 ;
		PREV_IDX = INDEX_ADMIT ;
		UNPLANNED_READMIT_FLAG =  0 ;
	END ;
	ELSE DO ;
		IF PREV_IDX = 1 AND STAY_FROM_DT LE PREV30 THEN DO ;
			IF PLANNED_ADMISSION NE 1 THEN DO ;
				UNPLANNED_READMIT_FLAG = 1 ;
				READMIT_CASE = PREV_CASE ;
			END ;
			ELSE UNPLANNED_READMIT_FLAG = 0 ;
		END ;
		ELSE DO ;
			UNPLANNED_READMIT_FLAG = 0 ;
		END ;
			PREV_CASE = IP_CASE ;
			PREV30 = DAY30 ;
			PREV_IDX = INDEX_ADMIT ;
	END ;

	RETAIN PREV_CASE PREV30 PREV_IDX ;	

	IF UNPLANNED_READMIT_FLAG = 1 THEN OUTPUT READ1 ;
	OUTPUT INDEX_FINAL ;
run;

PROC SQL ;
	CREATE TABLE out.IPR_FINAL_&label._&bpid1._&bpid2. AS 
	SELECT A.*, 
		   CASE WHEN B.READMIT_CASE IS NULL then 0 ELSE 1 end AS HAS_READMISSION 
	FROM INDEX_final AS A LEFT JOIN READ1 AS B
	ON A.BENE_SK=B.BENE_SK AND
	   A.EPISODE_ID=B.EPISODE_ID AND
	   A.IP_CASE = B.READMIT_CASE ;
QUIT ;

PROC SORT DATA=out.IPR_FINAL_&label._&bpid1._&bpid2. ; BY BENE_SK EPISODE_ID IP_CASE ; run;

DATA IPR_USE_&label._&bpid1._&bpid2.;
	set out.IPR_FINAL_&label._&bpid1._&bpid2.;
	drop DGNSCD: PRCDRCD: ;
run;

***Code for merging readmissions back into main inpatient file***;
PROC SORT DATA=index1b; BY BENE_SK EPISODE_ID IP_CASE STAY_ADMSN_DT STAY_DSCHRGDT; run;

DATA ip_combine ; 
      MERGE index1b(IN=A) IPR_USE_&label._&bpid1._&bpid2.(IN=B); by BENE_SK EPISODE_ID IP_CASE ;
      if a ;
      IF B=0 THEN DO ;
            INDEX_ADMIT = 0 ;
            UNPLANNED_READMIT_FLAG = 0 ;
      END ;

	 IP_CAH = 0;
	 if '0001' <= pv and pv <= '0899' then IP_CAH = 1;
	 else if '1300' <= pv and pv <= '1399' then IP_CAH = 1;

run;

DATA ipr_&label._&bpid1._&bpid2.;
      set ip_combine ;  BY BENE_SK EPISODE_ID IP_CASE ;


*** Only assigning latest claim of a case to HAS_READMISSION - all other lines in flagged case = 9 **** ;
      *** Only assigning earliest claim of a case to UNPLANNED_READMIT_FLAG - all other lines in flagged case = 9 **** ;
      IF FIRST.IP_CASE THEN DO ;
            READM_COUNT = UNPLANNED_READMIT_FLAG ;
            INDEX_COUNT = INDEX_ADMIT;

            IF TRANSFER_STAY=1 AND INDEX_ADMIT = 1 THEN DO ;
                  HAS_READMISSION = 9 ;
                  INDEX_ADMIT = 9 ;
            END ;
            FIRST_CASE = 1 ;
      END ;
      ELSE IF LAST.IP_CASE and IP_CAH = 1 THEN DO ;
            IF TRANSFER_STAY gt 1 THEN UNPLANNED_READMIT_FLAG = 9 ;
            LAST_CASE = 1 ;
      END ;

      ELSE DO ;
            IF INDEX_ADMIT = 1 and transfer_stay ne 0 THEN DO ;
                  HAS_READMISSION = 9 ;
                  INDEX_ADMIT = 9 ;
            END ;
			IF transfer_stay ne 0 THEN DO ;
            UNPLANNED_READMIT_FLAG = 9 ;
			END ;
      END ;

      IF INDEX_ADMIT NOTIN (1,9) THEN HAS_READMISSION = . ;
      IF IP_CAH NE 1 THEN DO ;
            HAS_READMISSION = . ;
            INDEX_ADMIT = . ;
            UNPLANNED_READMIT_FLAG = . ;
      END ;
run;

