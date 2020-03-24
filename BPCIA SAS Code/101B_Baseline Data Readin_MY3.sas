proc printto;run;
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\101B_Baseline Data Readin_MY3_&sysdate..log" print=print new;
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
%let label = ybase3; *Turn on for baseline data, turn off for quarterly data;
%let pth =R:\data\HIPAA\BPCIA_BPCI Advanced\01 - Baseline Data\MY3 ;


****** REFERENCE PROGRAMS **********************************************************************************;
%let path = H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS;

*198;
%include "&path.\100B_Read Baseline Data_MY3.sas";
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
	%if %sysfunc(find(&&read&i,epi_,i))>0 %then %epi(&&read&i, &i);
	%if %sysfunc(find(&&read&i,ip_,i))>0 %then %ip(&&read&i, &i);
	%if %sysfunc(find(&&read&i,dm_,i))>0 %then %dme(&&read&i, &i);
	%if %sysfunc(find(&&read&i,hh_,i))>0 %then %hha(&&read&i, &i);
	%if %sysfunc(find(&&read&i,hs_,i))>0 %then %hs(&&read&i, &i);
	%if %sysfunc(find(&&read&i,opl_,i))>0 %then %op(&&read&i, &i);
	%if %sysfunc(find(&&read&i,pb_,i))>0 %then %pb(&&read&i, &i);
	%if %sysfunc(find(&&read&i,sn_,i))>0 %then %snf(&&read&i, &i);
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

%call(Other,1191-0001,1191_0001,&label.);
%call(Other,1209-0000,1209_0000,&label.);
%call(Other,1374-0001,1374_0001,&label.);
%call(Other,1505-0000,1505_0000,&label.);
%call(Other,1686-0001,1686_0001,&label.);
%call(Other,1688-0001,1688_0001,&label.);
%call(Other,1696-0001,1696_0001,&label.);
%call(Other,1710-0001,1710_0001,&label.);
%call(Other,1832-0000,1832_0000,&label.);
%call(Other,2586-0001,2586_0001,&label.);
%call(Other,2941-0001,2941_0001,&label.);
%call(Other,2942-0001,2942_0001,&label.);
%call(Other,2943-0001,2943_0001,&label.);
%call(Other,2944-0001,2944_0001,&label.);
%call(Other,2945-0001,2945_0001,&label.);
%call(Other,2946-0001,2946_0001,&label.);
%call(Other,2947-0001,2947_0001,&label.);
%call(Other,2948-0001,2948_0001,&label.);
%call(Other,2949-0001,2949_0001,&label.);
%call(Other,2950-0001,2950_0001,&label.);
%call(Other,2951-0001,2951_0001,&label.);
%call(Other,2952-0001,2952_0001,&label.);
%call(Other,2953-0001,2953_0001,&label.);
%call(Other,2954-0001,2954_0001,&label.);
%call(Other,2955-0001,2955_0001,&label.);
%call(Other,2956-0001,2956_0001,&label.);
%call(Other,2957-0001,2957_0001,&label.);
%call(Other,2958-0001,2958_0001,&label.);
%call(Other,2959-0001,2959_0001,&label.);
%call(Other,2974-0001,2974_0001,&label.);
%call(Other,6049-0001,6049_0001,&label.);
%call(Other,6050-0001,6050_0001,&label.);
%call(Other,6051-0001,6051_0001,&label.);
%call(Other,6052-0001,6052_0001,&label.);
%call(Other,6053-0001,6053_0001,&label.);
%call(Other,6054-0001,6054_0001,&label.);
%call(Other,6055-0001,6055_0001,&label.);
%call(Other,6056-0001,6056_0001,&label.);
%call(Other,6057-0001,6057_0001,&label.);
%call(Other,6058-0001,6058_0001,&label.);
%call(Other,6059-0001,6059_0001,&label.);
%call(Other,7309-0001,7309_0001,&label.);
%call(Other,7310-0001,7310_0001,&label.);
%call(Other,7311-0001,7311_0001,&label.);
%call(Other,7312-0001,7312_0001,&label.);

%call(Premier,1025-0000,1025_0000,&label.);
%call(Premier,1026-0000,1026_0000,&label.);
%call(Premier,1028-0000,1028_0000,&label.);
%call(Premier,1029-0000,1029_0000,&label.);
%call(Premier,1075-0000,1075_0000,&label.);
%call(Premier,1102-0000,1102_0000,&label.);
%call(Premier,1103-0000,1103_0000,&label.);
%call(Premier,1104-0000,1104_0000,&label.);
%call(Premier,1105-0000,1105_0000,&label.);
%call(Premier,1106-0000,1106_0000,&label.);
%call(Premier,1125-0000,1125_0000,&label.);
%call(Premier,1148-0000,1148_0000,&label.);
%call(Premier,1167-0000,1167_0000,&label.);
%call(Premier,1343-0000,1343_0000,&label.);
%call(Premier,1368-0000,1368_0000,&label.);
%call(Premier,1461-0000,1461_0000,&label.);
%call(Premier,1470-0000,1470_0000,&label.);
%call(Premier,1506-0000,1506_0000,&label.);
%call(Premier,1507-0000,1507_0000,&label.);
%call(Premier,1508-0000,1508_0000,&label.);
%call(Premier,1510-0000,1510_0000,&label.);
%call(Premier,1525-0000,1525_0000,&label.);
%call(Premier,1634-0000,1634_0000,&label.);
%call(Premier,1753-0000,1753_0000,&label.);
%call(Premier,1958-0000,1958_0000,&label.);
%call(Premier,2048-0000,2048_0000,&label.);
%call(Premier,2049-0000,2049_0000,&label.);
%call(Premier,2070-0000,2070_0000,&label.);
%call(Premier,2102-0000,2102_0000,&label.);
%call(Premier,2216-0000,2216_0000,&label.);
%call(Premier,2217-0000,2217_0000,&label.);
%call(Premier,2302-0000,2302_0000,&label.);
%call(Premier,2317-0000,2317_0000,&label.);
%call(Premier,2374-0000,2374_0000,&label.);
%call(Premier,2376-0000,2376_0000,&label.);
%call(Premier,2378-0000,2378_0000,&label.);
%call(Premier,2379-0000,2379_0000,&label.);
%call(Premier,2449-0000,2449_0000,&label.);
%call(Premier,2451-0000,2451_0000,&label.);
%call(Premier,2452-0000,2452_0000,&label.);
%call(Premier,2461-0000,2461_0000,&label.);
%call(Premier,2468-0000,2468_0000,&label.);
%call(Premier,2587-0000,2587_0000,&label.);
%call(Premier,2589-0000,2589_0000,&label.);
%call(Premier,2594-0000,2594_0000,&label.);
%call(Premier,2607-0000,2607_0000,&label.);
%call(Premier,2785-0000,2785_0000,&label.);
%call(Premier,2788-0001,2788_0001,&label.);
%call(Premier,2790-0001,2790_0001,&label.);
%call(Premier,2964-0001,2964_0001,&label.);
%call(Premier,2965-0001,2965_0001,&label.);
%call(Premier,2966-0001,2966_0001,&label.);
%call(Premier,2967-0001,2967_0001,&label.);
%call(Premier,2968-0001,2968_0001,&label.);
%call(Premier,2969-0001,2969_0001,&label.);
%call(Premier,2971-0001,2971_0001,&label.);
%call(Premier,2973-0001,2973_0001,&label.);
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
%call(Premier,5392-0001,5392_0001,&label.);
%call(Premier,5394-0000,5394_0000,&label.);
%call(Premier,5395-0000,5395_0000,&label.);
%call(Premier,5397-0001,5397_0001,&label.);
%call(Premier,5478-0001,5478_0001,&label.);
%call(Premier,5479-0001,5479_0001,&label.);
%call(Premier,5480-0001,5480_0001,&label.);
%call(Premier,5481-0001,5481_0001,&label.);
%call(Premier,5746-0001,5746_0001,&label.);
%call(Premier,6592-0001,6592_0001,&label.);
%call(Premier,8027-0001,8027_0001,&label.);
%call(Premier,8028-0001,8028_0001,&label.);
%call(Premier,8029-0001,8029_0001,&label.);
%call(Premier,8030-0001,8030_0001,&label.);
%call(Premier,8031-0001,8031_0001,&label.);
%call(Premier,8032-0001,8032_0001,&label.);


%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;

proc printto;run;

/************************************************************************************;*/
/***** END OF PROGRAM ***************************************************************;*/
/************************************************************************************;*/
