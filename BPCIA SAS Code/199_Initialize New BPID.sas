

***** USER INPUTS ******************************************************************************************;
*%let label = ybase; *Turn on for baseline data, turn off for quarterly data;
%let label = y201812; *Turn off for baseline data, turn on for quarterly data;


%let vers = P; *B for baseline, P for Performance;


proc printto;run;
proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2019\Work Papers\SAS\logs\199 - Initialize New BPID_&label._&sysdate..log" print=print new;
run;


***** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
libname in "&dataDir.\06 - Imported Raw Data";
libname out "&dataDir.\07 - Processed Data";

libname ref "H:\Nonclient\Medicare Bundled Payment Reference\General\SAS Datasets" ;
libname bpcia 'H:\Nonclient\Medicare Bundled Payment Reference\Program - BPCIA\SAS Datasets';


%MACRO RunHosp(id1,id2,bpid1,bpid2,prov);

	%MACRO LOOP(timeper);
	data out.epi_&timeper._&bpid1._&bpid2.;
		set _NULL_;
	run;
	%mend;
	%LOOP(y201810);
	%LOOP(y201811);

%mend;

%runhosp(1907_0000,5746_0001,5746,0002,100007);


