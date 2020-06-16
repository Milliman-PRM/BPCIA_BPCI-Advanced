
%let label_prev_quarterly = y202002; *Turn off for baseline data, turn on for quarterly data;

proc printto;run;
*proc printto log="H:\BPCIA_BPCI Advanced\50 - BPCI Advanced Ongoing Reporting - 2020\Work Papers\SAS\logs\199 - Initialize New quarterly BPID&label._&sysdate..log" print=print new;
run;


***** LIBRARY ASSIGNMENTS **********************************************************************************;
%let dataDir = R:\data\HIPAA\BPCIA_BPCI Advanced;
libname out "&dataDir.\07 - Processed Data";

%MACRO RunHosp(id1,id2,bpid1,bpid2,prov);

	%MACRO LOOP(timeper);
	data out.epi_&timeper._&bpid1._&bpid2.;
		set out.epi_&label_prev_quarterly._&bpid1._&bpid2.;
	run;

		data out.epi_idx_&timeper._&bpid1._&bpid2.;
		set out.epi_idx_&label_prev_quarterly._&bpid1._&bpid2.;
	run;

	%mend;

	%LOOP(y202003);


%mend;

%runhosp(1075_0000,1075_0000,1075,0000,360133);
%runhosp(2048_0000,2048_0000,2048,0000,360079);
%runhosp(2049_0000,2049_0000,2049,0000,360239);
%runhosp(2589_0000,2589_0000,2589,0000,360132);
%runhosp(5037_0000,5037_0000,5037,0000,360360);
