**************************************************************************************************************** ;
**************************************	 01 - Targe Price Read-In 	******************************************** ;
**** Programmer: Alex Lutz																					**** ;
**** Checker: Sumudu Dehipawala																				**** ;
**** Project: BPCIA																							**** ;
**** Purpose: Read in Target Price Reports																	**** ;
**************************************************************************************************************** ; 
**************************************************************************************************************** ; 

/****************************************************************************************************************
Step 0 - Library assignment
****************************************************************************************************************/
libname ref "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets";

/****************************************************************************************************************
Step 1 - Read in Target Price CSV files and adjust variables as needed
****************************************************************************************************************/
%macro read_in(in);

	libname tempdir "&in.";

	data TP_Components_1;
		infile "&in.\TP_Components.csv" dlm=',' dsd lrecl=4096 truncover firstobs=2;
		input
				INDEX :5.
				CONVENER_ID :$9.
				INITIATOR_BPID :$9.
				PGP_ACH :$3.
				CCN_TIN :$12.
				ASSOC_ACH_CCN :$12.
				EPI_TYPE :$3.
				EPI_CAT :$70.
				EPI_COUNT :$7.
				COUNT_GT_40 :$1.
				EPI_SPEND :$17.
				AMT :$15.
				ACH_EFF :$7.
				SBS :$15.
				PCMA :$7.
				PAT :$7.
				HBP :$15.
				PGP_EFF :$7.
				PGP_OFFSET :$7.
				PGP_OFFSET_ADJ :$7.
				PGP_ACH_PCMA :$7.
				CASE_MIX :$7.
				PGP_ACH_BNCHMRK :$15.
				TARGET_PRICE :$15.
				PAYMENT_RATIO :$7.
				TARGET_PRICE_REAL :$15.
		;
	run;

	* overwriting EPI_CAT so it can map;
	data TP_Components_2;
		set TP_Components_1;
		if EPI_CAT ne 'All';
		if INITIATOR_BPID not in (
								'1931-0006',
								'5397-0011','5397-0012','5397-0013','5397-0014','5397-0015',
								'5398-0001','5398-0002','5398-0003','5398-0005','5398-0006','5398-0007','5398-0008','5398-0009',
								'5105-0002', '5105-0003', '5105-0004', '5105-0005', '5105-0006', '5105-0007', '5105-0008', '5105-0012', '5105-0013', '5105-0014', '5105-0015', '5105-0145', '5105-0146', '5105-0147', '5105-0149', '5105-0150',
								'5128-0003'
								);
		length EPI_CAT_adj $100;
		EPI_CAT_adj=EPI_CAT;
		if EPI_CAT_adj='Chronic obstructive pulmonary disease, bronchitis, asthma' then EPI_CAT_adj='Chronic obstructive pulmonary disease, bronchitis/asthma';
		if EPI_CAT_adj='Coronary artery bypass graft' then EPI_CAT_adj='Coronary artery bypass graft surgery';
		if EPI_CAT_adj='Lower extremity and humerus procedure except hip, foot, femur' then EPI_CAT_adj='Lower extremity/humerus procedure except hip, foot, femur';
		if EPI_TYPE='OP' and EPI_CAT_adj='Back & neck except spinal fusion' then EPI_CAT_adj='Back or Neck except spinal fusion';
		if EPI_TYPE='OP' then EPI_CAT_adj='OP - '||EPI_CAT_adj;
	run;

	* map on short episode names;
	proc sql;
	  create table TP_Components_3 as
	  select a.*, b.Short_Name as EPI_CAT_Short
	  from TP_Components_2 as a
	  left join ref.bpcia_clinical_episode_names as b
	  on upper(a.EPI_CAT_adj)=upper(b.Clinical_Episode)
	  ;
	quit;

	* see what doesnt map;
	proc sql;
		title "&in.";
		select count(*) as count_rec
			  ,sum(case when EPI_CAT_Short="" and EPI_CAT_adj ne 'ALL' then 1 else 0 end) as count_blanks
			  ,sum(case when EPI_CAT_Short="" and EPI_CAT_adj ne 'ALL' then 1 else 0 end)/count(*) as percent_blank
		from TP_Components_3
		;	    
	quit;
	proc sql;
		title 'No Mapping - It is okay if EPI_CAT=ALL doesnt map';
		select *
		from TP_Components_3
		where EPI_CAT_Short=""
		;
		create table no_map_distinct as
		select distinct EPI_TYPE, EPI_CAT_adj
		from TP_Components_3
		where EPI_CAT_Short=""
		;
	quit; 

	* create numeric variables from text fields;
	data tempdir.TP_Components;
		length EPI_INDEX $50;
		set TP_Components_3 (rename= (EPI_SPEND=EPI_SPEND_o AMT=AMT_o ACH_EFF=ACH_EFF_o SBS=SBS_o 
									PCMA=PCMA_o PAT=PAT_o HBP=HBP_o PGP_EFF=PGP_EFF_o 
									PGP_OFFSET=PGP_OFFSET_o PGP_OFFSET_ADJ=PGP_OFFSET_ADJ_o PGP_ACH_PCMA=PGP_ACH_PCMA_o CASE_MIX=CASE_MIX_o
									PGP_ACH_BNCHMRK=PGP_ACH_BNCHMRK_o TARGET_PRICE=TARGET_PRICE_o PAYMENT_RATIO=PAYMENT_RATIO_o TARGET_PRICE_REAL=TARGET_PRICE_REAL_o))
									;
		length EPI_CAT_2 $100;

		if length(strip(CCN_TIN))=5 then CCN_TIN="0"||CCN_TIN;
		if length(strip(ASSOC_ACH_CCN))=5 then ASSOC_ACH_CCN="0"||ASSOC_ACH_CCN;

		EPI_CAT_2 = EPI_TYPE || "_" || EPI_CAT;
		EPI_INDEX=INITIATOR_BPID || " - " || strip(EPI_CAT_Short) || " - " || coalescec(ASSOC_ACH_CCN,CCN_TIN);
		EPI_INDEX_2=INITIATOR_BPID || " - " || strip(EPI_CAT_Short);
		

		format EPI_SPEND AMT ACH_EFF SBS PCMA PAT HBP PGP_EFF PGP_OFFSET PGP_OFFSET_ADJ PGP_ACH_PCMA CASE_MIX PGP_ACH_BNCHMRK TARGET_PRICE PAYMENT_RATIO TARGET_PRICE_REAL best12.;

		EPI_SPEND = compress(tranwrd(tranwrd(tranwrd(EPI_SPEND_o, "$",""),",","")," ",""));
		AMT = compress(tranwrd(tranwrd(tranwrd(AMT_o, "$",""),",","")," ",""));
		ACH_EFF = compress(tranwrd(tranwrd(tranwrd(ACH_EFF_o, "$",""),",","")," ",""));
		SBS = compress(tranwrd(tranwrd(tranwrd(SBS_o, "$",""),",","")," ",""));
		PCMA = compress(tranwrd(tranwrd(tranwrd(PCMA_o, "$",""),",","")," ",""));
		PAT = compress(tranwrd(tranwrd(tranwrd(PAT_o, "$",""),",","")," ",""));
		HBP = compress(tranwrd(tranwrd(tranwrd(HBP_o, "$",""),",","")," ",""));
		PGP_EFF = compress(tranwrd(tranwrd(tranwrd(PGP_EFF_o, "$",""),",","")," ",""));
		PGP_OFFSET = compress(tranwrd(tranwrd(tranwrd(PGP_OFFSET_o, "$",""),",","")," ",""));
		PGP_OFFSET_ADJ = compress(tranwrd(tranwrd(tranwrd(PGP_OFFSET_ADJ_o, "$",""),",","")," ",""));
		PGP_ACH_PCMA = compress(tranwrd(tranwrd(tranwrd(PGP_ACH_PCMA_o, "$",""),",","")," ",""));
		CASE_MIX = compress(tranwrd(tranwrd(tranwrd(CASE_MIX_o, "$",""),",","")," ",""));
		PGP_ACH_BNCHMRK = compress(tranwrd(tranwrd(tranwrd(PGP_ACH_BNCHMRK_o, "$",""),",","")," ",""));
		TARGET_PRICE = compress(tranwrd(tranwrd(tranwrd(TARGET_PRICE_o, "$",""),",","")," ",""));
		PAYMENT_RATIO = compress(tranwrd(tranwrd(tranwrd(PAYMENT_RATIO_o, "$",""),",","")," ",""));
		TARGET_PRICE_REAL = compress(tranwrd(tranwrd(tranwrd(TARGET_PRICE_REAL_o, "$",""),",","")," ",""));

		drop EPI_SPEND_o AMT_o ACH_EFF_o SBS_o PCMA_o PAT_o HBP_o PGP_EFF_o
			 PGP_OFFSET_o PGP_OFFSET_ADJ_o PGP_ACH_PCMA_o CASE_MIX_o PGP_ACH_BNCHMRK_o TARGET_PRICE_o PAYMENT_RATIO_o TARGET_PRICE_REAL_o;

	run;

	* test that ASSOC_ACH_CCN is always equal to CCN_TIN, when it isnt blank;
	proc sql;
		title "ASSOC_ACH_CCN vs CCN_TIN Check - &in.";
		select ASSOC_ACH_CCN, CCN_TIN
		from  tempdir.TP_Components
		where (ASSOC_ACH_CCN='' and length(CCN_TIN)>6) or (ASSOC_ACH_CCN ne CCN_TIN and ASSOC_ACH_CCN ne '' and length(CCN_TIN)=6)
		;
	quit;

	data tempdir.Peer_Group;
		infile "&in.\Peer_Group_Characteristics.csv" dlm=',' dsd lrecl=4096 truncover firstobs=2;
		input
				INDEX :5.
				CONVENER_ID :$9.
				INITIATOR_BPID :$9.
				CCN :$12.
				ACADEMIC :$1.
				URBAN_RURAL :$5.
				SAFETY_NET :$1.
				BED_SIZE :$11.
				CENSUS :$7.
		;
		if INITIATOR_BPID not in (
								'1931-0006',
								'5397-0011','5397-0012','5397-0013','5397-0014','5397-0015',
								'5398-0001','5398-0002','5398-0003','5398-0005','5398-0006','5398-0007','5398-0008','5398-0009',
								'5105-0002', '5105-0003', '5105-0004', '5105-0005', '5105-0006', '5105-0007', '5105-0008', '5105-0012', '5105-0013', '5105-0014', '5105-0015', '5105-0145', '5105-0146', '5105-0147', '5105-0149', '5105-0150',
								'5128-0003'
								);
		run;


%mend read_in;

%read_in(R:\data\HIPAA\BPCIA_BPCI Advanced\04 - Target Price Reports\Distributed Baseline\Other\Stacked Files);
%read_in(R:\data\HIPAA\BPCIA_BPCI Advanced\04 - Target Price Reports\Distributed Baseline\Premier\Stacked Files);

%read_in(R:\data\HIPAA\BPCIA_BPCI Advanced\04 - Target Price Reports\Distributed 20181001\Other\Stacked Files);
%read_in(R:\data\HIPAA\BPCIA_BPCI Advanced\04 - Target Price Reports\Distributed 20181001\Premier\Stacked Files);

%read_in(R:\data\HIPAA\BPCIA_BPCI Advanced\04 - Target Price Reports\Distributed 20181231\Other\Stacked Files);
%read_in(R:\data\HIPAA\BPCIA_BPCI Advanced\04 - Target Price Reports\Distributed 20181231\Premier\Stacked Files);

