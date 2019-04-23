proc printto;run;
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\101B_Baseline Data Readin_&sysdate..log";
run;

*********************************************************
*********************************************************
Generate Hospital Data from:
100 - Read Raw Data

*********************************************************
*********************************************************;

%let _sdtm=%sysfunc(datetime());
%put This program was run on %sysfunc(date(),worddate.).;

options mprint mlogic spool;

****** USER INPUTS **********************************************************************************;
%let label = ybase; *Turn on for baseline data, turn off for quarterly data;
%let pth =R:\data\HIPAA\BPCIA_BPCI Advanced\01 - Baseline Data ;


****** REFERENCE PROGRAMS **********************************************************************************;
%let path = H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS;

*198;
%include "&path.\100B_Read Baseline Data.sas";
%include 'H:\_HealthLibrary\SAS\dirmemlist.sas' ;

****** LIBRARY ASSIGNMENT **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced ; 
libname in "&dataDir.\06 - Imported Raw Data";

data in.dirlist_master_&label.;
	set _null_;
run;

****** CALL MACROS *****************************************************************************************;
%macro call(sub1,id, BPID,sub2);

%let folder = &pth.\&sub1.\&id.; 

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
	%if %sysfunc(find(&&read&i,grouped_dme,i))>0 %then %dme(&&read&i, &i);
	%else %if %sysfunc(find(&&read&i,grouped_hha,i))>0 %then %hha(&&read&i, &i);
	%else %if %sysfunc(find(&&read&i,grouped_hs,i))>0 %then %hs(&&read&i, &i);
	%else %if %sysfunc(find(&&read&i,grouped_ip,i))>0 %then %ip(&&read&i, &i);
	%else %if %sysfunc(find(&&read&i,grouped_op,i))>0 %then %op(&&read&i, &i);
	%else %if %sysfunc(find(&&read&i,grouped_pb,i))>0 %then %pb(&&read&i, &i);
	%else %if %sysfunc(find(&&read&i,grouped_snf,i))>0 %then %snf(&&read&i, &i);
	%else %if %sysfunc(find(&&read&i,bpci_a_episodes,i))>0 %then %epi(&&read&i, &i);
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


********************************************************* ;
********************************************************* ;


%call(Other,1209-0000,1209_0000,&label.);
%call(Other,1374-0001,1374_0001,&label.);
%call(Other,1686-0001,1686_0001,&label.);
%call(Other,1688-0001,1688_0001,&label.);
%call(Other,1696-0001,1696_0001,&label.);
%call(Other,1710-0001,1710_0001,&label.);
%call(Other,2586-0001,2586_0001,&label.);
%call(Other,5105-0001,5105_0001,&label.);
%call(Other,5387-0001,5387_0001,&label.);
%call(Other,5424-0001,5424_0001,&label.);
%call(Premier,1032-0000,1032_0000,&label.);
%call(Premier,1075-0000,1075_0000,&label.);
%call(Premier,1102-0000,1102_0000,&label.);
%call(Premier,1103-0000,1103_0000,&label.);
%call(Premier,1104-0000,1104_0000,&label.);
%call(Premier,1105-0000,1105_0000,&label.);
%call(Premier,1106-0000,1106_0000,&label.);
%call(Premier,1125-0000,1125_0000,&label.);
%call(Premier,1148-0000,1148_0000,&label.);
%call(Premier,1167-0000,1167_0000,&label.);
%call(Premier,1234-0000,1234_0000,&label.);
%call(Premier,1252-0000,1252_0000,&label.);
%call(Premier,1343-0000,1343_0000,&label.);
%call(Premier,1368-0000,1368_0000,&label.);
%call(Premier,1635-0000,1635_0000,&label.);
%call(Premier,1791-0000,1791_0000,&label.);
%call(Premier,1907-0000,1907_0000,&label.);
%call(Premier,1931-0001,1931_0001,&label.);
%call(Premier,1958-0000,1958_0000,&label.);
%call(Premier,1971-0000,1971_0000,&label.);
%call(Premier,2048-0000,2048_0000,&label.);
%call(Premier,2049-0000,2049_0000,&label.);
%call(Premier,2070-0000,2070_0000,&label.);
%call(Premier,2374-0000,2374_0000,&label.);
%call(Premier,2376-0000,2376_0000,&label.);
%call(Premier,2378-0000,2378_0000,&label.);
%call(Premier,2379-0000,2379_0000,&label.);
%call(Premier,2579-0000,2579_0000,&label.);
%call(Premier,2587-0000,2587_0000,&label.);
%call(Premier,2589-0000,2589_0000,&label.);
%call(Premier,2594-0000,2594_0000,&label.);
%call(Premier,2607-0000,2607_0000,&label.);
%call(Premier,2631-0000,2631_0000,&label.);
%call(Premier,5037-0000,5037_0000,&label.);
%call(Premier,5038-0000,5038_0000,&label.);
%call(Premier,5043-0000,5043_0000,&label.);
%call(Premier,5050-0000,5050_0000,&label.);
%call(Premier,5154-0000,5154_0000,&label.);
%call(Premier,5215-0001,5215_0001,&label.);
%call(Premier,5229-0000,5229_0000,&label.);
%call(Premier,5263-0000,5263_0000,&label.);
%call(Premier,5264-0000,5264_0000,&label.);
%call(Premier,5282-0000,5282_0000,&label.);
%call(Premier,5394-0000,5394_0000,&label.);
%call(Premier,5395-0000,5395_0000,&label.);
%call(Premier,5397-0001,5397_0001,&label.);
%call(Premier,5398-0001,5398_0001,&label.);


%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;

proc printto;run;

/************************************************************************************;*/
/***** END OF PROGRAM ***************************************************************;*/
/************************************************************************************;*/
