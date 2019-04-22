**************************************************************************************************************** ;
************************************	200a - Patient Saftey Indicators	************************************ ;
**** Programmer: Alex Lutz																					**** ;
**** Checker: 																								**** ;
**** Project: BPCIA																							**** ;
**** Purpose: Patient Saftey Indicators 03, 05-08, 13, and 16-19											**** ;
**************************************************************************************************************** ; 
**************************************************************************************************************** ; 

/****************************************************************************************************************
Step 0 - Library assignment
****************************************************************************************************************/

libname in "R:\data\HIPAA\BPCIA_BPCI Advanced\99 - Investigations\PSI Tests";
%include "format file";

options obs=max compress=yes;

/****************************************************************************************************************
Step 1 - 
****************************************************************************************************************/

/* create all exclusion and inclusion fields */
data ip_ybase_1075_0000_1075_0000_pre;
	set in.ip_ybase_1075_0000_1075_0000;
	format surg med 1.;
	surg=0; med=0;
	if put(STAY_DRG_CD, $SURGI2R.)='Y' then surg=1;
	if put(STAY_DRG_CD, $MEDIC2R.)='Y'then med=1;

	* should length of stay use DSCHRG-ADMSN or THRU-FROM;
	* these are not always the same;
	format los best12.;
	los=0;
	los=STAY_DSCHRGDT-STAY_ADMSN_DT;
run;

/* create episode level numerator and denominator flags for each PSI */
data ip_ybase_1075_0000_1075_0000_flags;
	set ip_ybase_1075_0000_1075_0000_pre;

	* create an array to hold all ICD9 and ICD10 vars;
	array DGNSCD[*] DGNSCD:;

	* determine how many of the diagnosis codes for an episode fall into a given diag category;
	* determine how many of the secondary diagnosis codes for an episode fall into a given diag category;
	format allpos_decubvd			secondary_decubvd
	       allpos_burndx			secondary_burndx
	       allpos_exfoliatxd		secondary_exfoliatxd
	       allpos_foreiid			secondary_foreiid
	       1.;

		   allpos_decubvd=0;		secondary_decubvd=0;
	       allpos_burndx=0;			secondary_burndx=0;
	       allpos_exfoliatxd=0;		secondary_exfoliatxd=0;
	       allpos_foreiid=0;		secondary_foreiid=0;

	/************************************************************************************************************
	ICD 9 Code
	************************************************************************************************************/

		do i=1 to 25;
			/* DECUBVD */
			if put(DGNSCD[i], $DECUBVD9.)='Y' then allpos_decubvd=allpos_decubvd+1;
			if i>1 and put(DGNSCD[i], $DECUBVD9.)='Y' then secondary_decubvd=secondary_decubvd+1;
			/* BURNDX */
			if put(DGNSCD[i], $BURNDX9.)='Y' then allpos_burndx=allpos_burndx+1;
			if i>1 and put(DGNSCD[i], $BURNDX9.)='Y' then secondary_burndx=secondary_burndx+1;
			/* EXFOLIATXD */
			if put(DGNSCD[i], $EXFOLIATXD9.)='Y' then allpos_exfoliatxd=allpos_exfoliatxd+1;
			if i>1 and put(DGNSCD[i], $EXFOLIATXD9.)='Y' then secondary_exfoliatxd=secondary_exfoliatxd+1;
		end;

		format den03 		num03
			   1.;

			   den03=0; 	num03=0;

		/* Flag PSI 03 */
			* flag denominator for PSI 03 making all necescary exclusions;
			if 
				* must be a medical or surgical discharge;
				surg+med>0 
				* patient age must be 18 or older;
				and BENE_AGE>=18
				* exclude cases with length of stay less than 3 days;
				and los>=3 
				* exclude cases with a principal ICD10 for pressure ulcer;
				and put(DGNSCD01, $DECUBVD9.)='N' 
				* exclude cases that have all secondary ICD10 codes for pressure ulcer;
				and secondary_decubvd ne 24
				* exclude cases with any ICD 10 for severe burns or exfoliative disorders of the skin;
				and allpos_burndx=0 and allpos_exfoliatxd=0
				* exclude cases with a MDC code of 14 (see MSDRG tab in HCG codesets);
				and put(STAY_DRG_CD, $MDC14.)='N'
				* exclude cases with any of the following vars missing: SEX, AGE, DQTR, YEAR, DX1 -> no var for SEX, follow up on this;
				and sum(/* missing(SEX), */missing(BENE_AGE),missing(STAY_DSCHRGDT),missing(STAY_ADMSN_DT),missing(DGNSCD01))=0
			then den03=1;
			* flag numerator if the case is eligible for the denominator and has any secondary ICD for pressure ulcer;
			if den03=1 and secondary_decubvd>0 then num03=1;

		

	/************************************************************************************************************
	ICD 10 Code
	************************************************************************************************************/

		do i=1 to 25;
			/* DECUBVD */
			if put(DGNSCD[i], $DECUBVD10.)='Y' then allpos_decubvd=allpos_decubvd+1;
			if i>1 and put(DGNSCD[i], $DECUBVD10.)='Y' then secondary_decubvd=secondary_decubvd+1;
			/* BURNDX */
			if put(DGNSCD[i], $BURNDX10.)='Y' then allpos_burndx=allpos_burndx+1;
			if i>1 and put(DGNSCD[i], $BURNDX10.)='Y' then secondary_burndx=secondary_burndx+1;
			/* EXFOLIATXD */
			if put(DGNSCD[i], $EXFOLIATXD10.)='Y' then allpos_exfoliatxd=allpos_exfoliatxd+1;
			if i>1 and put(DGNSCD[i], $EXFOLIATXD10.)='Y' then secondary_exfoliatxd=secondary_exfoliatxd+1;
			/* FOREIID */
			if put(DGNSCD[i], $FOREIID10.)='Y' then allpos_foreiid=allpos_foreiid+1;
			if i>1 and put(DGNSCD[i], $FOREIID10.)='Y' then secondary_foreiid=secondary_foreiid+1;
		end;

		format den03 		num03
			   den05 		num05
			   1.;

			   den03=0; 	num03=0;
			   den05=0; 	num05=0;

		/* Flag PSI 03 */
			* flag denominator for PSI 03 making all necescary exclusions;
			if 
				* must be a medical or surgical discharge;
				surg+med>0 
				* patient age must be 18 or older;
				and BENE_AGE>=18
				* exclude cases with length of stay less than 3 days;
				and los>=3 
				* exclude cases with a principal ICD10 for pressure ulcer;
				and put(DGNSCD01, $DECUBVD10.)='N' 
				* exclude cases that have all secondary ICD10 codes for pressure ulcer;
				and secondary_decubvd ne 24
				* exclude cases with any ICD 10 for severe burns or exfoliative disorders of the skin;
				and allpos_burndx=0 and allpos_exfoliatxd=0
				* exclude cases with a MDC code of 14 (see MSDRG tab in HCG codesets);
				and put(STAY_DRG_CD, $MDC14.)='N'
				* exclude cases with any of the following vars missing: SEX, AGE, DQTR, YEAR, DX1 -> no var for SEX, follow up on this;
				and sum(/* missing(SEX), */missing(BENE_AGE),missing(STAY_DSCHRGDT),missing(STAY_ADMSN_DT),missing(DGNSCD01))=0
			then den03=1;
			* flag numerator if the case is eligible for the denominator and has any secondary ICD for pressure ulcer;
			if den03=1 and secondary_decubvd>0 then num03=1;

		/* Flag PSI 05 */
			* flag denominator for PSI 05 making all necescary exclusions;
			if
				* surgical and medical patients ages 18 years and older or obstetric patients;
				(surg+med>0 and BENE_AGE>=18) or put(STAY_DRG_CD, $MDC14.)='Y'
				* excludes cases with principal diagnosis of FOREIID;
				and put(DGNSCD01, $FOREIID10.)='N'
			then den05=1;
			* flag numerator if the case is eligible for the denominator and has any secondary ICD for for retained surg item;
			if den05=1 and secondary_foreiid>0 then num05=1;
							
run;