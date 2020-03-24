***** Read in BPCIA Quality Measures Complicaitons from Outside Data Sources (20181016 UPDATE)***** ;

%let location = R:\data\HIPAA\BPCIA_BPCI Advanced\11 - Outside Data Sources;
%let Episodes = H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Project Management ;
%let folder = Sources ;
%let fname=Complications and Deaths - Hospital;
%let fname1=Unplanned Hospital Visits - Hospital;
libname bpcia "H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets";

/* Importing Complications and Deaths - Hosptial File which include these measures: (Serious Complications, Mortality Rate (CABG Clinical Episode), 
																								Rate of Complication for Hip & Knee Replacements) */
%macro Comp(QM,code) ; 
PROC IMPORT
	OUT=BPCIA_Quality_Measure
	DATAFILE="&location.\&QM.\&folder.\&fname..xlsx"
	 DBMS=EXCEL
	REPLACE;
	SHEET="Complications and Deaths - Hosp"; 
	GETNAMES=YES;
RUN;

data bpcia.Quality_Measure_&QM. (drop = Measure_start_date Measure_end_date Provider_ID %if &code. = 1 %then%do ; Score rename=(Score1=score) %end; ); 
		set BPCIA_Quality_Measure ;
%if &code. = 1 %then%do ; 
		Measure_Period_Start = Measure_start_date ;
		Measure_Period_End = Measure_end_date ;
		Measure_Period = Measure_Period_Start||" "||"-"||" "||Measure_Period_End ; 
		CCN = Provider_ID;
		if score = 'Not Available' then Score1 = .;
		else Score1 = input(score,best.) ;
%end ;
%else %do ; 
		Measure_Period_Start = put(Measure_start_date,mmddyy10.) ;
		Measure_Period_End = put(Measure_end_date,mmddyy10.) ;
		Measure_Period = Measure_Period_Start||" "||"-"||" "||Measure_Period_End ; 
		CCN = put(Provider_ID,z6.);
%end ; 
run;

%mend Comp; 

%Comp (QM_20190730,0) ; 
/*%Comp (QM_20181008,0) ; */
/*%Comp (QM_20180523,0) ; */
/*%Comp (QM_201611,1) ; */
/*%Comp (QM_201605,1) ; */
/*%Comp (QM_201505,1) ; */


%macro Unplanned (QM,code) ; 

/* Importing Unplanned Readmissions -Hospital File which include these measures: (Unplanned Readmissions, Hospital Return Days for Heart Attack Patients */
																								
PROC IMPORT
	OUT=BPCIA_Quality_Measure_unplanned
	DATAFILE="&location.\&QM.\&folder.\&fname1..xlsx"
	 DBMS=EXCEL
	REPLACE;
	SHEET="Unplanned Hospital Visits - Hos";
	GETNAMES=YES;
RUN;

data bpcia.Measure_Unplanned_&QM. (drop = Measure_start_date Measure_end_date Provider_ID %if &code. = 1 %then%do ; Score rename=(Score1=score) %end;); 
		set BPCIA_Quality_Measure_unplanned ;
%if &code. = 1%then%do ; 
		Measure_Period_Start = Measure_start_date ;
		Measure_Period_End = Measure_end_date ;
		Measure_Period = Measure_Period_Start||" "||"-"||" "||Measure_Period_End ; 
		CCN = Provider_ID;
		if score = 'Not Available' then Score1 = .;
		else Score1 = input(score,best.) ;
%end ;
%else %do ; 
		Measure_Period_Start = put(Measure_start_date,mmddyy10.) ;
		Measure_Period_End = put(Measure_end_date,mmddyy10.) ;
		Measure_Period = Measure_Period_Start||" "||"-"||" "||Measure_Period_End ; 
		CCN = put(Provider_ID,z6.);
%end ; 
run;

%mend Unplanned ; 

%Unplanned (QM_20190730,0) ; 
/*%Unplanned (QM_20181008,0) ; */
/*%Unplanned (QM_20180523,0) ; */
/*%Unplanned (QM_201611,1) ; */
/*%Unplanned (QM_201605,1) ; */

/* Importing the unique Anchor CCN's from the BPCIA Target Price Summary Table */
/*PROC IMPORT*/
/*		OUT=bpcia.BPCIA_Quality_Measure_CCN*/
/*		DATAFILE="&location.\Unique anchor CCN's BPCIA.xls" */
/*		 DBMS=xls */
/*		 REPLACE;*/
/*		 SHEET = 'Unique Anchor CCNs' ;*/
/*		 GETNAMES= YES;*/
/*RUN;*/


