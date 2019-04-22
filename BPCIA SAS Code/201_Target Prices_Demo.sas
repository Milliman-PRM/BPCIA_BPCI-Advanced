%let  _sdtm=%sysfunc(datetime());
*********************************************************
*********************************************************
BPCIA: 201_Target Prices
Code to calculate target prices
*********************************************************
*********************************************************;
options mprint;


****** USER INPUTS ******************************************************************************************;
*%let label = ybase; *Turn on for baseline data, turn off for quarterly data;
*%let label = y201901; *Turn off for baseline data, turn on for quarterly data;


proc printto;run;
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\201_Demo - Target Prices_&sysdate..log" print=print new;
run;

****** REFERENCE PROGRAMS ***********************************************************************************;
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros.sas";
%include "H:\_HealthLibrary\SAS\000 - General SAS Macros_64bit.sas";

%let main = H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Code;
%include "&main.\000 - Formats - BPCIA.sas";


****** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
libname out "&dataDir.\07 - Processed Data\Output";
libname out2 "&dataDir.\07 - Processed Data\Output_Demo";
libname tp "&dataDir.\08 - Target Price Data";

libname ref "H:\Nonclient\Medicare Bundled Payment Reference\General\SAS Datasets" ;

proc format; value $masked_bpid
'1148-0000'='1111-0000'
'1167-0000'='2222-0000'
'1343-0000'='3333-0000'
'1368-0000'='4444-0000'
'2379-0000'='5555-0000'
'2587-0000'='6666-0000'
'2607-0000'='7777-0000'
'5084-0034'='8888-0000'
'5084-0064'='9999-0000'
'5479-0002'='1010-0000'
other='';
run;

********************
********************
Calculation of Adjusted Target Prices
********************
********************;
%macro Period(label);

%macro RunHosp(bpid1,bpid2);

data out2.tp_&label._&bpid1._&bpid2.;
	format BPID $9.;
	set out.tp_&label._&bpid1._&bpid2. (rename=(BPID=BPID_o));

	BPID = put(BPID_o,$masked_bpid.);
/*
	if BPID = "1032-0000" then do; BPID = "1111-0000"; end;
	if BPID = "1075-0000" then do; BPID = "2222-0000"; end;
	if BPID = "1125-0000" then do; BPID = "3333-0000"; end;
	if BPID = "1167-0000" then do; BPID = "4444-0000"; end;
	if BPID = "1148-0000" then do; BPID = "5555-0000"; end;
*/
	if ORIGDS='Yes' then ORIGDS='C';
	else ORIGDS='H';
	if LTI='Yes' then LTI='B';
	else LTI='E';
	if ANY_DUAL='Yes' then ANY_DUAL='I';
	else ANY_DUAL='A';

run;

%mend;

%runhosp(1148,0000);
%runhosp(1167,0000);
%runhosp(1343,0000);
%runhosp(1368,0000);
%runhosp(2379,0000);
%runhosp(2587,0000);
%runhosp(2607,0000);
%runhosp(5084,0034);
%runhosp(5084,0064);
%runhosp(5479,0002);

%mend;

%Period(ybase);
%Period(y201902);


data All_Target_Prices;
	set out2.tp_: ;
run;

proc export data= All_Target_Prices
            outfile= "R:\data\HIPAA\BPCIA_BPCI Advanced\08 - Target Price Data\Demo\Target Prices Demo_&sysdate..csv"
            dbms=csv replace; 
run;


proc printto;run;
%let _edtm=%sysfunc(datetime());
%let _runtm=%sysevalf(%sysfunc(putn(&_edtm - &_sdtm, 12.))/60.0);
%put It took &_runtm minutes to run the program;
