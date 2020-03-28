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
libname out "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data";
libname Demo "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Demo";
%include "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code\000 - BPCIA_Interface_BPIDs.sas"; 


/****************************************************************************************************************
Step 1 - Map updated BPIDs onto archived versions of the TP_Component and Peer Group files
****************************************************************************************************************/
%macro BASELINE(client);

	libname arch "R:\data\HIPAA\BPCIA_BPCI Advanced\04 - Target Price Reports\Distributed Baseline MY3\&client.\Stacked Files";

	/* TP_Components */
	data arch_pre_&client._tp_comp;
		set arch.TP_Components(rename=(EPI_INDEX=EPI_INDEX_OLD CONVENER_ID=CONVENER_ID_OLD INITIATOR_BPID=INITIATOR_BPID_OLD));
		length EPI_INDEX $132. CONVENER_ID INITIATOR_BPID $9. time_period $32.;
		format BPID_change 1. time_period $32. epi_start epi_end MMDDYY10.;
		time_period='Baseline MY3';
		rel_dt=0;
		epi_start=mdy(10,1,2014);
		epi_end=mdy(9,30,2018);

		BPID_change=0; INITIATOR_BPID=INITIATOR_BPID_old; CONVENER_ID=CONVENER_ID_old; EPI_INDEX=EPI_INDEX_OLD;

		format ccn_join $6.;
		ccn_join = ASSOC_ACH_CCN;
		if ccn_join = '' then ccn_join = CCN_TIN;
		if length(compress(ccn_join)) = 5 then ccn_join = '0' || ccn_join;

	run;
		
	proc sql;
		create table arch_TP_Components_&client. as
		select a.*
		from arch_pre_&client._tp_comp as a
		inner join ref.bpcia_episode_initiator_info as b
		on a.initiator_bpid = b.BPCI_Advanced_ID_number_2
		;
		title "arch_bpids_&client."; select count(distinct initiator_bpid) as distinct_bpid from arch_TP_Components_&client.; 
		;
	quit;

	data arch_TP_Components_&client.;
		set arch_pre_&client._tp_comp;
	run;
	/* Peer Group */
/*	data arch_Peer_Group_&client.;*/
/*		set arch.Peer_Group(rename=(CONVENER_ID=CONVENER_ID_OLD INITIATOR_BPID=INITIATOR_BPID_OLD));*/
/*		length CONVENER_ID INITIATOR_BPID $9. time_period $32.;*/
/*		format BPID_change 1. time_period $32. epi_start epi_end MMDDYY10.;*/
/*		time_period='Baseline';*/
/*		rel_dt=0;*/
/*		epi_start=mdy(1,1,2013);*/
/*		epi_end=mdy(12,31,2016);*/
/**/
/*		* map on new convener_ids and BPIDs;*/
/*			 if INITIATOR_BPID_old='1681-0004' then do; BPID_change=1; INITIATOR_BPID='1374-0004'; CONVENER_ID='1374_0001'; end;*/
/*		else if INITIATOR_BPID_old='5211-0002' then do; BPID_change=1; INITIATOR_BPID='1374-0008'; CONVENER_ID='1374_0001'; end;*/
/*		else if INITIATOR_BPID_old='5211-0003' then do; BPID_change=1; INITIATOR_BPID='1374-0009'; CONVENER_ID='1374_0001'; end;*/
/*		else if INITIATOR_BPID_old='1234-0000' then do; BPID_change=1; INITIATOR_BPID='5084-0042'; CONVENER_ID='5084_0001'; end;*/
/*		else if INITIATOR_BPID_old='1971-0000' then do; BPID_change=1; INITIATOR_BPID='5084-0064'; CONVENER_ID='5084_0001'; end;*/
/*		else if INITIATOR_BPID_old='2579-0000' then do; BPID_change=1; INITIATOR_BPID='5084-0034'; CONVENER_ID='5084_0001'; end;*/
/*		else if INITIATOR_BPID_old='5398-0004' then do; BPID_change=1; INITIATOR_BPID='5398-0002'; CONVENER_ID='5398_0001'; end;*/
/*		else if INITIATOR_BPID_old='1931-0002' then do; BPID_change=1; INITIATOR_BPID='5478-0002'; CONVENER_ID='5478_0001'; end;*/
/*		else if INITIATOR_BPID_old='1931-0003' then do; BPID_change=1; INITIATOR_BPID='5479-0002'; CONVENER_ID='5479_0001'; end;*/
/*		else if INITIATOR_BPID_old='1931-0004' then do; BPID_change=1; INITIATOR_BPID='5480-0002'; CONVENER_ID='5480_0001'; end;*/
/*		else if INITIATOR_BPID_old='1931-0005' then do; BPID_change=1; INITIATOR_BPID='5481-0002'; CONVENER_ID='5481_0001'; end;*/
/*		else if INITIATOR_BPID_old='1907-0000' then do; BPID_change=1; INITIATOR_BPID='5746-0002'; CONVENER_ID='5746_0001'; end;*/
/*		else if INITIATOR_BPID_old='5105-0148' then do; BPID_change=1; INITIATOR_BPID='5916-0002'; CONVENER_ID='5916_0001'; end;*/
/*		else if INITIATOR_BPID_old='5387-0069' then do; BPID_change=1; INITIATOR_BPID='6049-0002'; CONVENER_ID='6049_0001'; end;*/
/*		else if INITIATOR_BPID_old='5387-0074' then do; BPID_change=1; INITIATOR_BPID='6050-0002'; CONVENER_ID='6050_0001'; end;*/
/*		else if INITIATOR_BPID_old='5387-0079' then do; BPID_change=1; INITIATOR_BPID='6051-0002'; CONVENER_ID='6051_0001'; end;*/
/*		else if INITIATOR_BPID_old='5387-0081' then do; BPID_change=1; INITIATOR_BPID='6052-0002'; CONVENER_ID='6052_0001'; end;*/
/*		else if INITIATOR_BPID_old='5387-0084' then do; BPID_change=1; INITIATOR_BPID='6053-0002'; CONVENER_ID='6053_0001'; end;*/
/*		else if INITIATOR_BPID_old='5424-0002' then do; BPID_change=1; INITIATOR_BPID='6054-0002'; CONVENER_ID='6054_0001'; end;*/
/*		else if INITIATOR_BPID_old='5424-0003' then do; BPID_change=1; INITIATOR_BPID='6055-0002'; CONVENER_ID='6055_0001'; end;*/
/*		else if INITIATOR_BPID_old='5424-0004' then do; BPID_change=1; INITIATOR_BPID='6056-0002'; CONVENER_ID='6056_0001'; end;*/
/*		else if INITIATOR_BPID_old='5424-0005' then do; BPID_change=1; INITIATOR_BPID='6057-0002'; CONVENER_ID='6057_0001'; end;*/
/*		else if INITIATOR_BPID_old='5424-0006' then do; BPID_change=1; INITIATOR_BPID='6058-0002'; CONVENER_ID='6058_0001'; end;*/
/*		else if INITIATOR_BPID_old='5424-0007' then do; BPID_change=1; INITIATOR_BPID='6059-0002'; CONVENER_ID='6059_0001'; end;*/
/*		else if INITIATOR_BPID_old='5128-0002' then do; BPID_change=1; INITIATOR_BPID='1191-0002'; CONVENER_ID='1191_0001'; end;*/
/*		else do; BPID_change=0; INITIATOR_BPID=INITIATOR_BPID_old; CONVENER_ID=CONVENER_ID_old; end;*/
/*	run;*/
%mend BASELINE;

%BASELINE(Other);
%BASELINE(Premier);


/****************************************************************************************************************
Step 2 - Stack current and archived versions of of the TP_Component and Peer Group files
****************************************************************************************************************/
%macro PERFORMANCE(client, rel_date, timeper, epi_start, epi_end);

	libname perf "R:\data\HIPAA\BPCIA_BPCI Advanced\04 - Target Price Reports\Distributed &rel_date.\&client.\Stacked Files";

	/* TP Components */
	* create _old versions of BPID and Convener ID so new data set will stack onto old;
	data tpcomp_comb_&client._pre;
		set perf.TP_Components(rename=(EPI_INDEX=EPI_INDEX_OLD CONVENER_ID=CONVENER_ID_OLD INITIATOR_BPID=INITIATOR_BPID_OLD));
		length EPI_INDEX $132 CONVENER_ID INITIATOR_BPID $9. time_period $32.;
		EPI_INDEX=EPI_INDEX_OLD; CONVENER_ID=CONVENER_ID_OLD; INITIATOR_BPID=INITIATOR_BPID_OLD;
		EPI_INDEX_OLD=''; CONVENER_ID_OLD=''; INITIATOR_BPID_OLD='';
		format BPID_change 1. time_period $32. epi_start epi_end MMDDYY10.;
		time_period=&timeper.;
		rel_dt=&rel_date.;
		epi_start=&epi_start.;
		epi_end=&epi_end.;
		
			 if INITIATOR_BPID='1374-0004' then BPID_change=1;
		else if INITIATOR_BPID='1374-0008' then BPID_change=1;
		else if INITIATOR_BPID='1374-0009' then BPID_change=1;
		else if INITIATOR_BPID='5084-0042' then BPID_change=1;
		else if INITIATOR_BPID='5084-0064' then BPID_change=1;
		else if INITIATOR_BPID='5084-0034' then BPID_change=1;
		else if INITIATOR_BPID='5392-0004' then BPID_change=1;
		else if INITIATOR_BPID='5478-0002' then BPID_change=1;
		else if INITIATOR_BPID='5479-0002' then BPID_change=1;
		else if INITIATOR_BPID='5480-0002' then BPID_change=1;
		else if INITIATOR_BPID='5481-0002' then BPID_change=1;
		else if INITIATOR_BPID='5746-0002' then BPID_change=1;
		else if INITIATOR_BPID='5916-0002' then BPID_change=1;
		else if INITIATOR_BPID='6049-0002' then BPID_change=1;
		else if INITIATOR_BPID='6050-0002' then BPID_change=1;
		else if INITIATOR_BPID='6051-0002' then BPID_change=1;
		else if INITIATOR_BPID='6052-0002' then BPID_change=1;
		else if INITIATOR_BPID='6053-0002' then BPID_change=1;
		else if INITIATOR_BPID='6054-0002' then BPID_change=1;
		else if INITIATOR_BPID='6055-0002' then BPID_change=1;
		else if INITIATOR_BPID='6056-0002' then BPID_change=1;
		else if INITIATOR_BPID='6057-0002' then BPID_change=1;
		else if INITIATOR_BPID='6058-0002' then BPID_change=1;
		else if INITIATOR_BPID='6059-0002' then BPID_change=1;
		else if INITIATOR_BPID='1191-0002' then BPID_change=1;
		else BPID_change=0;

		format ccn_join $6.;
		ccn_join = ASSOC_ACH_CCN;
		if ccn_join = '' then ccn_join = CCN_TIN;
		if length(compress(ccn_join)) = 5 then ccn_join = '0' || ccn_join;

	run;

	* limit the new TP data;
	proc sql;
		create table tp_com_&client._pre_lim_&rel_date. as
		select a.*
		from tpcomp_comb_&client._pre as a
		inner join ref.bpcia_episode_initiator_info as b
		on a.initiator_bpid = b.BPCI_Advanced_ID_number_2
		;
		title "current_bpids_&client."; select count(distinct initiator_bpid) as distinct_bpid from tp_com_&client._pre_lim_&rel_date.; 
		;
	quit;

	data tp_com_&client._pre_lim_&rel_date.;
		set tpcomp_comb_&client._pre;
	run;

	proc sql;
		create table active_epi_&client._&rel_date. as
		select distinct time_period, CONVENER_ID, INITIATOR_BPID, EPI_TYPE, EPI_CAT_adj, EPI_CAT_Short 
		from tp_com_&client._pre_lim_&rel_date.;
	quit;

	/* Peer Group *//*
	* create _old versions of BPID and Convener ID so new data set will stack onto old;
	data pg_comb_&client._pre_&rel_date.;
		set perf.Peer_Group(rename=(CONVENER_ID=CONVENER_ID_OLD INITIATOR_BPID=INITIATOR_BPID_OLD));
		length CONVENER_ID INITIATOR_BPID $9. time_period $32.;
		CONVENER_ID=CONVENER_ID_OLD; INITIATOR_BPID=INITIATOR_BPID_OLD;
		CONVENER_ID_OLD=''; INITIATOR_BPID_OLD='';
		format BPID_change 1. time_period $32. epi_start epi_end MMDDYY10.;
		time_period=&timeper.;
		rel_dt=&rel_date.;
		epi_start=&epi_start.;
		epi_end=&epi_end.;

			 if INITIATOR_BPID='1374-0004' then BPID_change=1;
		else if INITIATOR_BPID='1374-0008' then BPID_change=1;
		else if INITIATOR_BPID='1374-0009' then BPID_change=1;
		else if INITIATOR_BPID='5084-0042' then BPID_change=1;
		else if INITIATOR_BPID='5084-0064' then BPID_change=1;
		else if INITIATOR_BPID='5084-0034' then BPID_change=1;
		else if INITIATOR_BPID='5392-0004' then BPID_change=1;
		else if INITIATOR_BPID='5478-0002' then BPID_change=1;
		else if INITIATOR_BPID='5479-0002' then BPID_change=1;
		else if INITIATOR_BPID='5480-0002' then BPID_change=1;
		else if INITIATOR_BPID='5481-0002' then BPID_change=1;
		else if INITIATOR_BPID='5746-0002' then BPID_change=1;
		else if INITIATOR_BPID='5916-0002' then BPID_change=1;
		else if INITIATOR_BPID='6049-0002' then BPID_change=1;
		else if INITIATOR_BPID='6050-0002' then BPID_change=1;
		else if INITIATOR_BPID='6051-0002' then BPID_change=1;
		else if INITIATOR_BPID='6052-0002' then BPID_change=1;
		else if INITIATOR_BPID='6053-0002' then BPID_change=1;
		else if INITIATOR_BPID='6054-0002' then BPID_change=1;
		else if INITIATOR_BPID='6055-0002' then BPID_change=1;
		else if INITIATOR_BPID='6056-0002' then BPID_change=1;
		else if INITIATOR_BPID='6057-0002' then BPID_change=1;
		else if INITIATOR_BPID='6058-0002' then BPID_change=1;
		else if INITIATOR_BPID='6059-0002' then BPID_change=1;
		else if INITIATOR_BPID='1191-0002' then BPID_change=1;
		else BPID_change=0;

		format ccn_join $6.;
		ccn_join = CCN;
		if length(compress(ccn_join)) = 5 then ccn_join = '0' || ccn_join;

	run;*/
%mend PERFORMANCE;

%PERFORMANCE(Premier, 20200114, '01/01/2020 - 09/30/2020', mdy(1,1,2020), mdy(9,30,2020));
%PERFORMANCE(Other, 20200114, '01/01/2020 - 09/30/2020', mdy(1,1,2020), mdy(9,30,2020));
/*%PERFORMANCE(Premier, 20181001, '10/01/2018 - 12/31/2018', mdy(10,1,2018), mdy(12,31,2018));*/
/*%PERFORMANCE(Other, 20181001, '10/01/2018 - 12/31/2018', mdy(10,1,2018), mdy(12,31,2018));*/


/*data out.active_epis;*/
/*	set active_epi_:;*/
/*run;*/

%macro stack_w_archive();
	/* TP Components */
	data TP_Components_Combine;
		* stack new over old so new episodes are captured when duplicates exist in the archive file;
		* stack premier over other to capture switchers;
		set tp_com_Premier_pre_lim:	(in=a)		/* new premier */
			arch_TP_Components_Premier		(in=b)		/* archive premier */
			tp_com_Other_pre_lim:		(in=a)		/* new other */
			arch_TP_Components_Other		(in=b)		/* archive other */
		;

		format epi_dropped_flag 1. ;
		epi_dropped_flag=1;

		if a then do;
			epi_dropped_flag=0;
		end;

		proc sort; by INITIATOR_BPID EPI_CAT EPI_TYPE ccn_join descending rel_dt;
	run;

	data TP_Components;
		set TP_Components_Combine;
	run;

	proc sql;
		title "stack_bpids"; select count(distinct initiator_bpid) as distinct_bpid from TP_Components; 
		;
	quit;

	/* Peer Group */
/*	data Peer_Group_Combine;*/
/*		* stack new over old so new episodes are captured when duplicates exist in the archive file;*/
/*		* stack premier over other to capture switchers;*/
/*		set pg_comb_Premier_pre:		(in=a)		*/
/*			arch_Peer_Group_Premier		(in=b)		*/
/*			pg_comb_Other_pre:			(in=a)		*/
/*			arch_Peer_Group_Other		(in=b)		*/
/*		;*/
/**/
/*		format epi_dropped_flag 1. ;*/
/*		epi_dropped_flag=1;*/
/**/
/*		if a then do;*/
/*			epi_dropped_flag=0;*/
/*		end;*/
/**/
/*		proc sort; by ccn_join descending rel_dt;*/
/*	run;*/
/**/
/*	proc sort nodupkey*/
/*		data=Peer_Group_Combine*/
/*		out=Peer_Group_Combined_All*/
/*		dupout=dups;*/
/*		by CONVENER_ID INITIATOR_BPID CCN ACADEMIC URBAN_RURAL SAFETY_NET BED_SIZE CENSUS time_period;*/
/*	run;*/

%mend stack_w_archive;

%stack_w_archive();

/****************************************************************************************************************
Step 3 - out tables, limit TP_Components to BPIDs in the Data Tracker, and export to CSV
****************************************************************************************************************/
%macro out(table);
	%if &table.=TP_Components %then %do;
		proc sql;
			create table out.&table._MY3_all as
			select a.*
			from &table. as a
			inner join ref.bpcia_episode_initiator_info_MY3 as b
			on a.initiator_bpid = b.BPCI_Advanced_ID_number_2
			;
			title "&table."; select count(distinct initiator_bpid) as distinct_bpid from out.&table._MY3_all; 
		quit;
/*
		data out.&table._MY3_1 out.&table._MY3_pmr_exist out.&table._MY3_pmr_new
				out.&table._MY3_pmr out.&table._MY3_ccb out.&table._MY3_ccf out.&table._MY3_ghs out.&table._MY3_hal
				out.&table._MY3_hss out.&table._MY3_ics out.&table._MY3_musc out.&table._MY3_uspi out.&table._MY3_wsp ;
			set out.&table._MY3_all;

			if initiator_bpid in (&MY3_lst.) then output out.&table._MY3_1;

			if initiator_bpid in (&PMR_3_Exist_EI_lst.) then output out.&table._MY3_pmr_exist;
			else if initiator_bpid in (&PMR_3_New_EI_lst.) then output out.&table._MY3_pmr_new;

			if initiator_bpid in (&PMR_3_EI_lst.) then output out.&table._MY3_pmr;
			else if initiator_bpid in (&CCB_3_EI_lst.) then output out.&table._MY3_ccb;
			else if initiator_bpid in (&CCF_3_EI_lst.) then output out.&table._MY3_ccf;
			else if initiator_bpid in (&GHS_3_EI_lst.) then output out.&table._MY3_ghs;
			else if initiator_bpid in (&HAL_3_EI_lst.) then output out.&table._MY3_hal;
			else if initiator_bpid in (&HSS_3_EI_lst.) then output out.&table._MY3_hss;
			else if initiator_bpid in (&ICS_3_EI_lst.) then output out.&table._MY3_ics;
			else if initiator_bpid in (&MUSC_3_EI_lst.) then output out.&table._MY3_musc;
			else if initiator_bpid in (&USPI_3_EI_lst.) then output out.&table._MY3_uspi;
			else if initiator_bpid in (&WSP_3_EI_lst.) then output out.&table._MY3_wsp;
			
		run;
		*/
		data out.&table._MY3_Premier out.&table._MY3_NonPremier out.&table._MY3_CCF out.&table._MY3_Dev;
			set out.&table._MY3_all;

			if initiator_bpid in (&DEV_EI_lst.) then output out.&table._MY3_Dev;
			if initiator_bpid in (&PMR_EI_lst.) then output out.&table._MY3_Premier;
			else if initiator_bpid in (&NON_PMR_EI_lst.) then output out.&table._MY3_NonPremier;
			else if initiator_bpid in (&CCF_lst.) then output out.&table._MY3_CCF;

		run;

		/* Export partitions */
		%MACRO EXPRT(name);
			proc export
				data=out.&table._MY3_&name.
				outfile="R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\&table._MY3_&name..csv"
				dbms=CSV 
				replace;
			run;
		%MEND;
		/*
		%EXPRT(1);
		%EXPRT(pmr_exist);
		%EXPRT(pmr_new);
		%EXPRT(pmr);
		%EXPRT(ccb);
		%EXPRT(ccf);
		%EXPRT(ghs);
		%EXPRT(hal);
		%EXPRT(hss);
		%EXPRT(ics);
		%EXPRT(musc);
		%EXPRT(uspi);
		%EXPRT(wsp);
		*/
		%EXPRT(Premier);
		%EXPRT(NonPremier);
		%EXPRT(CCF);
		%EXPRT(Dev);
	%end;
	%else %if &table.=Peer_Group %then %do;
		data out.Peer_Group_All;
			set Peer_Group_Combined_All;
		run;
	%end;
	proc export
		data=out.&table._MY3_all
		outfile="R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\&table._MY3_all.csv"
		dbms=CSV 
		replace;
	run;
%mend out;

%out(TP_Components);
/*%out(Peer_Group);*/

/****************************************************************************************************************
Step 4 - Create de-identified DEMO version
****************************************************************************************************************/
%macro create_demo(bpid1,bpid2,bpid3,bpid4,bpid5,bpid6,bpid7,bpid8);

* create format to mask CCN and TIN;
proc format; value $masked_id
	'310008'='111111'
	'310014'='222222'
	'310022'='333333'
	'310044'='444444'
	'310047'='555555'
	'310051'='666666'
	'310060'='777777'
	'310064'='888888'
	'310086'='999999'
	'310092'='111110'
	'310110'='222221'
	'310111'='333332'
	'340001'='444443'
	'340113'='555554'
	'390012'='666665'
	'390049'='777776'
	'390115'='888887'
	'390123'='999998'
	'390127'='111109'
	'390139'='222220'
	'390153'='333331'
	'390173'='444442'
	'390174'='555553'
	'390195'='666664'
	'390203'='777775'
	'390204'='888886'
	'390222'='999997'
	'390231'='111108'
	'390258'='222219'
	'390322'='333330'
	'390324'='444441'
	'223700669'='111111110'
	'232856880'='222222221'
	other='';
run;

proc format; value $masked_bpid
	'1148-0000'='1111-0000'
	'1167-0000'='2222-0000'
	'1343-0000'='3333-0000'
	'1368-0000'='4444-0000'
	'2379-0000'='5555-0000'
	'2587-0000'='6666-0000'
	'2607-0000'='7777-0000'
	'5479-0002'='8888-0000'
	other='';
run;


data Demo.TP_Components_demo;
	set out.TP_Components_pmr (rename=(CCN_TIN=CCN_TIN_o ASSOC_ACH_CCN=ASSOC_ACH_CCN_o 
									   INITIATOR_BPID=INITIATOR_BPID_o CONVENER_ID=CONVENER_ID_o
									   EPI_INDEX=EPI_INDEX_o EPI_INDEX_2=EPI_INDEX_2_o));
	if INITIATOR_BPID_o in ("&bpid1.","&bpid2.","&bpid3.","&bpid4.","&bpid5.","&bpid6.","&bpid7.","&bpid8.");

	INITIATOR_BPID = put(INITIATOR_BPID_o, $MASKED_BPID.); 
	CONVENER_ID = TRANWRD(INITIATOR_BPID,"-","_");
	EPI_INDEX=TRANWRD(EPI_INDEX_o,INITIATOR_BPID_o,INITIATOR_BPID);
	EPI_INDEX_2=TRANWRD(EPI_INDEX_2_o,INITIATOR_BPID_o,INITIATOR_BPID);
	if EPI_INDEX_2 = EPI_INDEX_2_o then EPI_INDEX_2=TRANWRD(EPI_INDEX_2_o,INITIATOR_BPID_old,INITIATOR_BPID);

	* mask CCN and TIN;
	format CCN_TIN ASSOC_ACH_CCN $12.;
	CCN_TIN=put(CCN_TIN_o, $MASKED_ID.);
	if ASSOC_ACH_CCN_o='' then ASSOC_ACH_CCN='';
	else ASSOC_ACH_CCN=put(ASSOC_ACH_CCN_o, $MASKED_ID.);

	drop CCN_TIN_o ASSOC_ACH_CCN_o EPI_INDEX_OLD CONVENER_ID_OLD INITIATOR_BPID_OLD
		 INITIATOR_BPID_o CONVENER_ID_o EPI_INDEX_o EPI_INDEX_2_o;
run;

proc export
	data=Demo.TP_Components_demo
	outfile="R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Demo\TP_Components_DEMO.csv"
	dbms=CSV 
	replace;
run;

/*data Demo.TP_Components_Base_demo;*/
/*	set Demo.TP_Components_demo;*/
/*	if time_period='Baseline';*/
/*run; */
/**/
/*proc export*/
/*	data=Demo.TP_Components_Base_demo*/
/*	outfile="R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Demo\TP_Components_Base_DEMO.csv"*/
/*	dbms=CSV */
/*	replace;*/
/*run;*/

%mend create_demo;

*%create_demo(1148-0000,1167-0000,1343-0000,1368-0000,2379-0000,2587-0000,2607-0000,5479-0002);  


		data out.TP_Components_pmr_comb out.TP_Components_oth_comb out.TP_Components_ccf_comb out.TP_Components_dev_comb;
			set out.TP_Components_all out.TP_Components_all_my3;
			if initiator_bpid in (&PMR_EI_lst.) then output out.TP_Components_pmr_comb;
			else if initiator_bpid in (&NON_PMR_EI_lst.) then output out.TP_Components_oth_comb;
			else if initiator_bpid in (&CCF_lst.) then output out.TP_Components_ccf_comb;
			
			if initiator_bpid in (&DEV_EI_lst.) then output out.TP_Components_dev_comb;
		run;
		/* Export partitions */
		proc export
			data=out.TP_Components_pmr_comb
			outfile="R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\TP_Components_pmr_comb.csv"
			dbms=CSV 
			replace;
		run;
		proc export
			data=out.TP_Components_oth_comb
			outfile="R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\TP_Components_oth_comb.csv"
			dbms=CSV 
			replace;
		run;
		proc export
			data=out.TP_Components_dev_comb
			outfile="R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\TP_Components_dev_comb.csv"
			dbms=CSV 
			replace;
		run;
		proc export
			data=out.TP_Components_ccf_comb
			outfile="R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\TP_Components_ccf_comb.csv"
			dbms=CSV 
			replace;
		run;
