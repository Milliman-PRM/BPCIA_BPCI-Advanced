proc printto;run;
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\101P - Performance Data Readin_&sysdate..log" print=print new;
run;
 
*********************************************************
*********************************************************
Generate Hospital Data from:
100P - Read Raw Data

*********************************************************
*********************************************************;

%let _sdtm=%sysfunc(datetime());
%put This program was run on %sysfunc(date(),worddate.).;

options mprint mlogic spool;

****** USER INPUTS **********************************************************************************;
%let dte = 202003;

%let label = y&dte.; 
/*
quarterly
Y if quarterly
N if not quarterly
next quarterly is month 202004
*/
%let quarterly = N; 
****** REFERENCE PROGRAMS **********************************************************************************;
%let path = H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS;

%include "&path.\100P_Read Performance Data.sas";
%include 'H:\_HealthLibrary\SAS\dirmemlist.sas' ;

****** LIBRARY ASSIGNMENT **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced ; 
libname in "&dataDir.\06 - Imported Raw Data";

data in.dirlist_master_&label.;
	set _null_;
run;

****** CALL MACROS *****************************************************************************************;
%macro call(sub1,id, BPID,sub2, MY_Category);

/***
MY_Category
12 - MY1 & MY2
123 MY1 & MY2 & MY3
3 MY3
****/

%if &MY_Category. = 12 OR &MY_Category. = 123  %then %do;

%let pth =R:\data\HIPAA\BPCIA_BPCI Advanced\02 - Performance Data\Data &dte. ;
%let folder = &pth.\&sub1.\&id.; 
%let MY = MY12;

TITLE1 'BPCI Advanced';
TITLE2 "CLIENT: &sub1.  BPID:&BPID." ;

*save out directory location;
filename DIRLIST pipe "dir ""&folder.\*.csv"" /b ";

*create dataset with all the file names in the dir above;
data dirlist;
	infile dirlist lrecl=200 truncover;
	input file_name $100.;
run;

data in.dirlist_master_&label.;
	set in.dirlist_master_&label. dirlist;
run;

*store the full file path of each file path in dir;
*store the number of files;
data _null_;
	set dirlist end=end;
	count+1;
	call symputx('read'||put(count,4.-l),cats("&folder.\",file_name));
	if end then call symputx('max',count);
run;

*loop through each of the files;
*use the file name to determine which macro to call;
%do i=1 %to &max;
	%put &&read&i;
	%if %sysfunc(find(&&read&i,epi_,i))>0 %then %epi(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,ip_,i))>0 %then %ip(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,dm_,i))>0 %then %dme(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,hh_,i))>0 %then %hha(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,hs_,i))>0 %then %hs(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,opl_,i))>0 %then %op(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,pb_,i))>0 %then %pb(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,sn_,i))>0 %then %snf(&&read&i, &i, &MY); 
%end;
%end;


%if &MY_Category. = 123 OR &MY_Category. = 3  %then %do;

%let pth =R:\data\HIPAA\BPCIA_BPCI Advanced\02 - Performance Data\Data &dte.\MY3;
%let folder = &pth.\&sub1.\&id.; 
%let MY = MY3;

TITLE1 'BPCI Advanced';
TITLE2 "CLIENT: &sub1.  BPID:&BPID." ;

*save out directory location;
filename DIRLIST pipe "dir ""&folder.\*.csv"" /b ";

*create dataset with all the file names in the dir above;
data dirlist;
	infile dirlist lrecl=200 truncover;
	input file_name $100.;
run;

data in.dirlist_master_&label.;
	set in.dirlist_master_&label. dirlist;
run;

*store the full file path of each file path in dir;
*store the number of files;
data _null_;
	set dirlist end=end;
	count+1;
	call symputx('read'||put(count,4.-l),cats("&folder.\",file_name));
	if end then call symputx('max',count);
run;

*loop through each of the files;
*use the file name to determine which macro to call;
%do i=1 %to &max;
	%put &&read&i;
	%if %sysfunc(find(&&read&i,epi_,i))>0 %then %epi(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,ip_,i))>0 %then %ip(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,dm_,i))>0 %then %dme(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,hh_,i))>0 %then %hha(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,hs_,i))>0 %then %hs(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,opl_,i))>0 %then %op(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,pb_,i))>0 %then %pb(&&read&i, &i, &MY);
	%if %sysfunc(find(&&read&i,sn_,i))>0 %then %snf(&&read&i, &i, &MY);
%end;
%end;


*stack like-named files;
data in.DME_&sub2._&BPID.;
	set DME_&sub2._&BPID._:;
run;
data in.HHA_&sub2._&BPID.;
	set HHA_&sub2._&BPID._:;
run;
data in.HS_&sub2._&BPID.;
	set HS_&sub2._&BPID._:;
run;
data in.IP_&sub2._&BPID.;
	set IP_&sub2._&BPID._:;
run;
data in.OP_&sub2._&BPID.;
	set OP_&sub2._&BPID._:;
run;
data in.PB_&sub2._&BPID.;
	set PB_&sub2._&BPID._:;
run;
data in.SNF_&sub2._&BPID.;
	set SNF_&sub2._&BPID._:;
run;
data in.EPI_&sub2._&BPID.;
	set EPI_&sub2._&BPID._:;
run;


*delete work datasets - Comment out to retain work files in session;
proc datasets lib=work memtype=data kill;

run;
quit;

%mend call;

*%call(Premier,1167-0000,1167_0000,&label.,123);
*%call(Premier,1075-0000,1075_0000,&label.,123);
*%call(Other,1374-0001,1374_0001,&label.,123);

********************************************************* ;
********************************************************* ;

%macro readin(datatype);

/* kettering hospitals are on quarterly reporting */
%if &quarterly. = Y %then %do;
%call(Premier,1075-0000,1075_0000,&label.,12);
%call(Premier,2048-0000,2048_0000,&label.,12);
%call(Premier,2049-0000,2049_0000,&label.,12);
%call(Premier,2589-0000,2589_0000,&label.,12);
%call(Premier,5037-0000,5037_0000,&label.,12);
%end;

%call(Other,1191-0001,1191_0001,&label.,12);
%call(Other,1209-0000,1209_0000,&label.,123);
%call(Other,1374-0001,1374_0001,&label.,123);
%call(Other,1686-0001,1686_0001,&label.,12);
%call(Other,1688-0001,1688_0001,&label.,123);
%call(Other,1696-0001,1696_0001,&label.,12);
%call(Other,1710-0001,1710_0001,&label.,123);
%call(Other,2586-0001,2586_0001,&label.,3);
%call(Other,2941-0001,2941_0001,&label.,3);
%call(Other,2956-0001,2956_0001,&label.,3);
%call(Other,2974-0001,2974_0001,&label.,3);
%call(Other,6049-0001,6049_0001,&label.,123);
%call(Other,6050-0001,6050_0001,&label.,12);
%call(Other,6051-0001,6051_0001,&label.,123);
%call(Other,6052-0001,6052_0001,&label.,123);
%call(Other,6053-0001,6053_0001,&label.,123);
%call(Other,6054-0001,6054_0001,&label.,123);
%call(Other,6055-0001,6055_0001,&label.,123);
%call(Other,6056-0001,6056_0001,&label.,123);
%call(Other,6057-0001,6057_0001,&label.,123);
%call(Other,6058-0001,6058_0001,&label.,123);
*%call(Other,6059-0001,6059_0001,&label.,123);
%call(Other,6059-0001,6059_0001,&label.,12);
%call(Other,7310-0001,7310_0001,&label.,3);
%call(Other,7312-0001,7312_0001,&label.,3);
%call(Premier,1028-0000,1028_0000,&label.,3);
%call(Premier,1102-0000,1102_0000,&label.,12);
%call(Premier,1103-0000,1103_0000,&label.,123);
%call(Premier,1104-0000,1104_0000,&label.,12);
%call(Premier,1105-0000,1105_0000,&label.,12);
%call(Premier,1106-0000,1106_0000,&label.,12);
%call(Premier,1148-0000,1148_0000,&label.,12);
%call(Premier,1167-0000,1167_0000,&label.,123);
%call(Premier,1343-0000,1343_0000,&label.,12);
%call(Premier,1368-0000,1368_0000,&label.,123);
%call(Premier,1461-0000,1461_0000,&label.,3);
%call(Premier,1634-0000,1634_0000,&label.,123);
*%call(Premier,1803-0000,1803_0000,&label.,3);
%call(Premier,1958-0000,1958_0000,&label.,123);
%call(Premier,2070-0000,2070_0000,&label.,123);
%call(Premier,2214-0000,2214_0000,&label.,3);
%call(Premier,2215-0000,2215_0000,&label.,3);
%call(Premier,2216-0000,2216_0000,&label.,3);
%call(Premier,2302-0000,2302_0000,&label.,123);
%call(Premier,2317-0000,2317_0000,&label.,3);
%call(Premier,2374-0000,2374_0000,&label.,123);
%call(Premier,2376-0000,2376_0000,&label.,123);
%call(Premier,2378-0000,2378_0000,&label.,123);
%call(Premier,2379-0000,2379_0000,&label.,123);
%call(Premier,2451-0000,2451_0000,&label.,3);
%call(Premier,2452-0000,2452_0000,&label.,3);
%call(Premier,2461-0000,2461_0000,&label.,3);
%call(Premier,2468-0000,2468_0000,&label.,3);
%call(Premier,2587-0000,2587_0000,&label.,123);
%call(Premier,2594-0000,2594_0000,&label.,123);
%call(Premier,2607-0000,2607_0000,&label.,12);
%call(Premier,5038-0000,5038_0000,&label.,123);
%call(Premier,5043-0000,5043_0000,&label.,123);
%call(Premier,5050-0000,5050_0000,&label.,123);
%call(Premier,5154-0000,5154_0000,&label.,123);
%call(Premier,5215-0001,5215_0001,&label.,123);
%call(Premier,5229-0000,5229_0000,&label.,12);
%call(Premier,5263-0000,5263_0000,&label.,123);
%call(Premier,5264-0000,5264_0000,&label.,123);
%call(Premier,5282-0000,5282_0000,&label.,123);
%call(Premier,5392-0001,5392_0001,&label.,12);
%call(Premier,5394-0000,5394_0000,&label.,123);
%call(Premier,5395-0000,5395_0000,&label.,12);
%call(Premier,5397-0001,5397_0001,&label.,123);
%call(Premier,5478-0001,5478_0001,&label.,123);
%call(Premier,5479-0001,5479_0001,&label.,123);
%call(Premier,5480-0001,5480_0001,&label.,123);
%call(Premier,5481-0001,5481_0001,&label.,123);
%call(Premier,5746-0001,5746_0001,&label.,123);

%mend readin;

%readin(P, N);
/************************************************************************************;*/
/***** END OF PROGRAM ***************************************************************;*/
/************************************************************************************;*/

%MACRO STACK(file);

data temp_&file. ;
	set in.&file._&label.: ;
run;
%if &file. = epi %then %do;
proc sql;
	create table summary_&file.a as
	select "&file.a" as Service, 
		min(ANCHOR_BEG_DT) as min_fromdt,
		max(ANCHOR_BEG_DT) as max_fromdt,
		min(ANCHOR_END_DT) as min_thrudt,
		max(ANCHOR_END_DT) as max_thrudt
	from temp_&file.;
quit;
proc sql;
	create table summary_&file.b as
	select "&file.b" as Service, 
		min(POST_DSCH_BEG_DT) as min_fromdt,
		max(POST_DSCH_BEG_DT) as max_fromdt,
		min(POST_DSCH_END_DT) as min_thrudt,
		max(POST_DSCH_END_DT) as max_thrudt
	from temp_&file.;
quit;
%end;
%else %if &file. = ip %then %do;
proc sql;
	create table summary_&file.a as
	select "&file.a" as Service, 
		min(stay_admsn_dt) as min_fromdt,
		max(stay_admsn_dt) as max_fromdt,
		min(stay_dschrgdt) as min_thrudt,
		max(stay_dschrgdt) as max_thrudt
	from temp_&file.;
quit;
proc sql;
	create table summary_&file.b as
	select "&file.b" as Service, 
		min(stay_from_dt) as min_fromdt,
		max(stay_from_dt) as max_fromdt,
		min(stay_thru_dt) as min_thrudt,
		max(stay_thru_dt) as max_thrudt
	from temp_&file.;
quit;
%end;
%else %do;
proc sql;
	create table summary_&file. as
	select "&file." as Service, 
		min(from_dt) as min_fromdt,
		max(from_dt) as max_fromdt,
		min(thru_dt) as min_thrudt,
		max(thru_dt) as max_thrudt
	from temp_&file.;
quit;
%end;

%MEND;

%STACK(epi);
%STACK(ip);
%STACK(dme);
%STACK(hha);
%STACK(hs);
%STACK(op);
%STACK(pb);
%STACK(snf);

data Summary;
	format Service $4. min_fromdt max_fromdt min_thrudt max_thrudt mmddyy10. ;
	set summary_: ;
run;

proc export data= Summary
            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\99 - Investigations\Performance Period Claims\sasout_Performance Claims Dates_&sysdate..xlsx"
            dbms=xlsx replace; 
run;


proc printto;run;

%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;

